<?php

namespace App\Services;

use App\Models\Product;
use App\Models\Pharmacy;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Service de matching des médicaments extraits avec le stock
 * Utilise une recherche floue pour tolérer les erreurs OCR
 */
class ProductMatchingService
{
    /**
     * Score minimum pour considérer un match valide
     */
    protected float $minMatchScore = 0.6;

    /**
     * Match les médicaments extraits avec les produits en stock
     * 
     * @param array $medications Liste des médicaments extraits par OCR
     * @param int|null $pharmacyId ID de la pharmacie (optionnel, pour filtrer)
     * @return array Résultats du matching
     */
    public function matchMedications(array $medications, ?int $pharmacyId = null): array
    {
        $results = [
            'matched' => [],
            'not_found' => [],
            'out_of_stock' => [],
            'alternatives' => [],
            'total_estimated_price' => 0,
        ];

        foreach ($medications as $medication) {
            $medName = $medication['name'] ?? '';
            
            if (empty($medName)) continue;

            // Rechercher le produit
            $matchResult = $this->findMatchingProduct($medName, $pharmacyId);

            if ($matchResult['found']) {
                $product = $matchResult['product'];
                
                if ($product->stock_quantity > 0 && $product->is_available) {
                    // Produit trouvé et en stock
                    $results['matched'][] = [
                        'medication' => $medName,
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'price' => $product->getCurrentPrice(),
                        'stock' => $product->stock_quantity,
                        'requires_prescription' => $product->requires_prescription,
                        'match_score' => $matchResult['score'],
                        'pharmacy_id' => $product->pharmacy_id,
                        'pharmacy_name' => $product->pharmacy?->name,
                    ];
                    $results['total_estimated_price'] += $product->getCurrentPrice();
                } else {
                    // Produit trouvé mais rupture de stock
                    $results['out_of_stock'][] = [
                        'medication' => $medName,
                        'product_id' => $product->id,
                        'product_name' => $product->name,
                        'stock' => $product->stock_quantity,
                        'pharmacy_id' => $product->pharmacy_id,
                    ];
                    
                    // Chercher des alternatives
                    $alternatives = $this->findAlternatives($product, $pharmacyId);
                    if (!empty($alternatives)) {
                        $results['alternatives'][$medName] = $alternatives;
                    }
                }
            } else {
                // Produit non trouvé
                $results['not_found'][] = [
                    'medication' => $medName,
                    'confidence' => $medication['confidence'] ?? 0,
                    'suggestions' => $matchResult['suggestions'] ?? [],
                ];
            }
        }

        // Calculer les statistiques
        $results['stats'] = [
            'total_medications' => count($medications),
            'matched_count' => count($results['matched']),
            'not_found_count' => count($results['not_found']),
            'out_of_stock_count' => count($results['out_of_stock']),
            'fulfillment_rate' => count($medications) > 0 
                ? round(count($results['matched']) / count($medications) * 100, 1) 
                : 0,
        ];

        return $results;
    }

    /**
     * Recherche un produit correspondant au médicament
     */
    protected function findMatchingProduct(string $medicationName, ?int $pharmacyId = null): array
    {
        $normalizedSearch = $this->normalizeText($medicationName);
        
        // Construction de la requête de base
        $query = Product::query()
            ->with('pharmacy')
            ->where('is_available', true);

        if ($pharmacyId) {
            $query->where('pharmacy_id', $pharmacyId);
        }

        // 1. Recherche exacte
        $exactMatch = (clone $query)
            ->where(function ($q) use ($medicationName, $normalizedSearch) {
                $q->whereRaw('LOWER(name) = ?', [strtolower($medicationName)])
                  ->orWhereRaw('LOWER(name) = ?', [$normalizedSearch]);
            })
            ->first();

        if ($exactMatch) {
            return [
                'found' => true,
                'product' => $exactMatch,
                'score' => 1.0,
            ];
        }

        // 2. Recherche par LIKE
        $likeMatch = (clone $query)
            ->where(function ($q) use ($normalizedSearch) {
                $q->whereRaw('LOWER(name) LIKE ?', ['%' . $normalizedSearch . '%'])
                  ->orWhereRaw('LOWER(active_ingredient) LIKE ?', ['%' . $normalizedSearch . '%']);
            })
            ->orderByRaw('stock_quantity > 0 DESC') // Prioriser les produits en stock
            ->first();

        if ($likeMatch) {
            $score = $this->calculateSimilarity($normalizedSearch, $this->normalizeText($likeMatch->name));
            if ($score >= $this->minMatchScore) {
                return [
                    'found' => true,
                    'product' => $likeMatch,
                    'score' => $score,
                ];
            }
        }

        // 3. Recherche floue (tous les produits)
        $allProducts = (clone $query)->get();
        $bestMatch = null;
        $bestScore = 0;

        foreach ($allProducts as $product) {
            $productNameNorm = $this->normalizeText($product->name);
            $score = $this->calculateSimilarity($normalizedSearch, $productNameNorm);
            
            // Vérifier aussi le principe actif
            if ($product->active_ingredient) {
                $ingredientScore = $this->calculateSimilarity(
                    $normalizedSearch, 
                    $this->normalizeText($product->active_ingredient)
                );
                $score = max($score, $ingredientScore);
            }

            if ($score > $bestScore) {
                $bestScore = $score;
                $bestMatch = $product;
            }
        }

        if ($bestMatch && $bestScore >= $this->minMatchScore) {
            return [
                'found' => true,
                'product' => $bestMatch,
                'score' => $bestScore,
            ];
        }

        // 4. Retourner des suggestions si pas de match
        $suggestions = $this->getSuggestions($normalizedSearch, $query->limit(5)->get());

        return [
            'found' => false,
            'suggestions' => $suggestions,
        ];
    }

    /**
     * Trouve des alternatives pour un produit en rupture
     */
    protected function findAlternatives(Product $product, ?int $pharmacyId = null): array
    {
        $alternatives = [];

        // Rechercher par principe actif
        if ($product->active_ingredient) {
            $query = Product::query()
                ->with('pharmacy')
                ->where('is_available', true)
                ->where('stock_quantity', '>', 0)
                ->where('id', '!=', $product->id)
                ->whereRaw('LOWER(active_ingredient) LIKE ?', ['%' . strtolower($product->active_ingredient) . '%']);

            if ($pharmacyId) {
                $query->where('pharmacy_id', $pharmacyId);
            }

            $alternatives = $query->take(3)->get()->map(function ($p) {
                return [
                    'product_id' => $p->id,
                    'name' => $p->name,
                    'price' => $p->getCurrentPrice(),
                    'stock' => $p->stock_quantity,
                    'pharmacy_id' => $p->pharmacy_id,
                    'pharmacy_name' => $p->pharmacy?->name,
                ];
            })->toArray();
        }

        // Rechercher dans la même catégorie si pas assez d'alternatives
        if (count($alternatives) < 3 && $product->category) {
            $existingIds = array_column($alternatives, 'product_id');
            $existingIds[] = $product->id;

            $query = Product::query()
                ->with('pharmacy')
                ->where('is_available', true)
                ->where('stock_quantity', '>', 0)
                ->where('category', $product->category)
                ->whereNotIn('id', $existingIds);

            if ($pharmacyId) {
                $query->where('pharmacy_id', $pharmacyId);
            }

            $categoryAlternatives = $query->take(3 - count($alternatives))->get()->map(function ($p) {
                return [
                    'product_id' => $p->id,
                    'name' => $p->name,
                    'price' => $p->getCurrentPrice(),
                    'stock' => $p->stock_quantity,
                    'pharmacy_id' => $p->pharmacy_id,
                    'pharmacy_name' => $p->pharmacy?->name,
                ];
            })->toArray();

            $alternatives = array_merge($alternatives, $categoryAlternatives);
        }

        return $alternatives;
    }

    /**
     * Normalise le texte pour la comparaison
     */
    protected function normalizeText(string $text): string
    {
        $text = mb_strtolower($text, 'UTF-8');
        
        // Supprimer les accents
        $text = Str::ascii($text);
        
        // Supprimer les caractères spéciaux sauf espaces et tirets
        $text = preg_replace('/[^a-z0-9\s\-]/', '', $text);
        
        // Supprimer les espaces multiples
        $text = preg_replace('/\s+/', ' ', $text);
        
        return trim($text);
    }

    /**
     * Calcule la similarité entre deux chaînes (Jaro-Winkler simplifié)
     */
    protected function calculateSimilarity(string $s1, string $s2): float
    {
        if ($s1 === $s2) return 1.0;
        if (empty($s1) || empty($s2)) return 0.0;

        // Similarité par containment (si l'un contient l'autre)
        if (str_contains($s1, $s2) || str_contains($s2, $s1)) {
            $ratio = min(strlen($s1), strlen($s2)) / max(strlen($s1), strlen($s2));
            return 0.7 + ($ratio * 0.3);
        }

        // Levenshtein normalisé
        $lev = levenshtein($s1, $s2);
        $maxLen = max(strlen($s1), strlen($s2));
        
        if ($maxLen === 0) return 1.0;
        
        $similarity = 1 - ($lev / $maxLen);

        // Bonus si même début (préfixe commun)
        $prefixLen = 0;
        $minLen = min(strlen($s1), strlen($s2), 4);
        for ($i = 0; $i < $minLen; $i++) {
            if ($s1[$i] === $s2[$i]) {
                $prefixLen++;
            } else {
                break;
            }
        }
        
        if ($prefixLen > 0) {
            $similarity += ($prefixLen * 0.1); // Bonus de 10% par caractère de préfixe
        }

        return min(1.0, $similarity);
    }

    /**
     * Génère des suggestions pour un médicament non trouvé
     */
    protected function getSuggestions(string $search, $products): array
    {
        $suggestions = [];

        foreach ($products as $product) {
            $score = $this->calculateSimilarity($search, $this->normalizeText($product->name));
            if ($score >= 0.4) {
                $suggestions[] = [
                    'product_id' => $product->id,
                    'name' => $product->name,
                    'score' => round($score, 2),
                ];
            }
        }

        // Trier par score décroissant
        usort($suggestions, fn($a, $b) => $b['score'] <=> $a['score']);

        return array_slice($suggestions, 0, 3);
    }

    /**
     * Vérifie la disponibilité globale pour une liste de médicaments
     */
    public function checkAvailability(array $medications, ?int $pharmacyId = null): array
    {
        $matchResult = $this->matchMedications($medications, $pharmacyId);
        
        $allAvailable = count($matchResult['not_found']) === 0 
            && count($matchResult['out_of_stock']) === 0;

        return [
            'all_available' => $allAvailable,
            'fulfillment_rate' => $matchResult['stats']['fulfillment_rate'],
            'matched_products' => $matchResult['matched'],
            'missing' => array_merge(
                $matchResult['not_found'],
                $matchResult['out_of_stock']
            ),
            'estimated_total' => $matchResult['total_estimated_price'],
            'alternatives' => $matchResult['alternatives'],
        ];
    }
}
