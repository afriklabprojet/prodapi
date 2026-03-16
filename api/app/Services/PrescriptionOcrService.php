<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;
use Google\Service\CloudVision;

/**
 * Service OCR pour analyser les ordonnances
 * Utilise Google Cloud Vision API pour extraire le texte
 */
class PrescriptionOcrService
{
    protected ?string $apiKey;
    protected ?string $accessToken = null;
    protected array $medicationPatterns = [];

    public function __construct()
    {
        $this->apiKey = config('services.google_cloud.vision_api_key');
        $this->loadMedicationPatterns();
    }

    /**
     * Get access token using service account credentials
     */
    protected function getAccessToken(): ?string
    {
        if ($this->accessToken) {
            return $this->accessToken;
        }

        $credentialsPath = storage_path('app/firebase-credentials.json');
        
        if (!file_exists($credentialsPath)) {
            Log::warning('[OCR] Firebase credentials not found at: ' . $credentialsPath);
            return null;
        }

        try {
            $client = new GoogleClient();
            $client->setAuthConfig($credentialsPath);
            $client->addScope('https://www.googleapis.com/auth/cloud-vision');
            
            $token = $client->fetchAccessTokenWithAssertion();
            
            if (isset($token['access_token'])) {
                $this->accessToken = $token['access_token'];
                return $this->accessToken;
            }
        } catch (\Exception $e) {
            Log::error('[OCR] Failed to get access token', ['error' => $e->getMessage()]);
        }

        return null;
    }

    /**
     * Charge les patterns de médicaments courants
     */
    protected function loadMedicationPatterns(): void
    {
        // Patterns pour identifier les médicaments dans le texte
        $this->medicationPatterns = [
            // Formes galéniques communes
            'comprimé', 'comprimés', 'cp', 'cpr',
            'gélule', 'gélules', 'gel',
            'sirop', 'suspension', 'solution',
            'pommade', 'crème', 'gel',
            'gouttes', 'collyre',
            'suppositoire', 'suppo',
            'injection', 'injectable', 'inj',
            'sachet', 'poudre',
            'capsule', 'caps',
            'ampoule', 'amp',
            
            // Dosages courants
            'mg', 'g', 'ml', 'mcg', 'µg',
            '100mg', '200mg', '250mg', '500mg', '1000mg',
            '1g', '2g', '5g',
            
            // Posologies
            'x/j', '/jour', 'fois par jour',
            'matin', 'midi', 'soir',
            'avant repas', 'après repas',
            'pendant', 'jours',
        ];
    }

    /**
     * Analyse une image d'ordonnance via OCR
     * 
     * @param string $imagePath Chemin de l'image (relatif au storage)
     * @return array Résultat de l'analyse
     */
    public function analyzeImage(string $imagePath): array
    {
        try {
            // Récupérer le contenu de l'image
            $imageContent = $this->getImageContent($imagePath);
            
            if (!$imageContent) {
                return $this->errorResult('Impossible de lire l\'image');
            }

            // Essayer d'abord avec le service account
            $accessToken = $this->getAccessToken();
            
            if ($accessToken) {
                Log::info('[OCR] Using service account authentication');
                return $this->callVisionApiWithToken($imageContent, $accessToken);
            }

            // Sinon utiliser l'API key
            if (!empty($this->apiKey)) {
                Log::info('[OCR] Using API key authentication');
                return $this->callVisionApiWithKey($imageContent, $this->apiKey);
            }

            // Fallback: analyse locale basique
            Log::info('[OCR] No authentication available, using basic analysis');
            return $this->basicTextAnalysis($imagePath);

        } catch (\Exception $e) {
            Log::error('[OCR] Exception during analysis', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            return $this->errorResult($e->getMessage());
        }
    }

    /**
     * Call Vision API with OAuth2 access token (service account)
     */
    protected function callVisionApiWithToken(string $imageContent, string $accessToken): array
    {
        $response = Http::withToken($accessToken)
            ->post('https://vision.googleapis.com/v1/images:annotate', [
                'requests' => [
                    [
                        'image' => [
                            'content' => base64_encode($imageContent),
                        ],
                        'features' => [
                            ['type' => 'TEXT_DETECTION'],
                            ['type' => 'DOCUMENT_TEXT_DETECTION'],
                        ],
                    ],
                ],
            ]);

        if ($response->failed()) {
            Log::error('[OCR] Google Vision API error', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return $this->errorResult('Erreur API Vision: ' . $response->status());
        }

        return $this->parseGoogleVisionResponse($response->json());
    }

    /**
     * Call Vision API with API key
     */
    protected function callVisionApiWithKey(string $imageContent, string $apiKey): array
    {
        $response = Http::post('https://vision.googleapis.com/v1/images:annotate?key=' . $apiKey, [
            'requests' => [
                [
                    'image' => [
                        'content' => base64_encode($imageContent),
                    ],
                    'features' => [
                        ['type' => 'TEXT_DETECTION'],
                        ['type' => 'DOCUMENT_TEXT_DETECTION'],
                    ],
                ],
            ],
        ]);

        if ($response->failed()) {
            Log::error('[OCR] Google Vision API error', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return $this->errorResult('Erreur API Vision: ' . $response->status());
        }

        return $this->parseGoogleVisionResponse($response->json());
    }

    /**
     * Récupère le contenu de l'image
     */
    protected function getImageContent(string $imagePath): ?string
    {
        // Essayer différents chemins
        if (Storage::disk('public')->exists($imagePath)) {
            return Storage::disk('public')->get($imagePath);
        }
        
        if (Storage::exists($imagePath)) {
            return Storage::get($imagePath);
        }
        
        // Chemin absolu
        if (file_exists($imagePath)) {
            return file_get_contents($imagePath);
        }

        // Chemin dans storage/app/public
        $fullPath = storage_path('app/public/' . $imagePath);
        if (file_exists($fullPath)) {
            return file_get_contents($fullPath);
        }

        return null;
    }

    /**
     * Parse la réponse de Google Vision API
     */
    protected function parseGoogleVisionResponse(array $data): array
    {
        $responses = $data['responses'] ?? [];
        
        if (empty($responses)) {
            return $this->errorResult('Aucune réponse de l\'API');
        }

        $response = $responses[0];
        
        // Vérifier les erreurs
        if (isset($response['error'])) {
            return $this->errorResult($response['error']['message'] ?? 'Erreur inconnue');
        }

        // Récupérer le texte complet
        $fullText = $response['fullTextAnnotation']['text'] ?? 
                    $response['textAnnotations'][0]['description'] ?? '';

        if (empty($fullText)) {
            return [
                'success' => true,
                'raw_text' => '',
                'medications' => [],
                'confidence' => 0,
                'is_prescription' => false,
                'message' => 'Aucun texte détecté dans l\'image',
            ];
        }

        // Analyser le texte pour extraire les médicaments
        $analysis = $this->extractMedicationsFromText($fullText);

        // Calculer la confiance globale
        $confidence = $this->calculateConfidence($response, $analysis);

        return [
            'success' => true,
            'raw_text' => $fullText,
            'medications' => $analysis['medications'],
            'dosages' => $analysis['dosages'],
            'confidence' => $confidence,
            'is_prescription' => $analysis['is_prescription'],
            'doctor_info' => $analysis['doctor_info'],
            'patient_info' => $analysis['patient_info'],
        ];
    }

    /**
     * Extrait les médicaments du texte OCR
     */
    public function extractMedicationsFromText(string $text): array
    {
        $medications = [];
        $dosages = [];
        $isPrescription = false;
        $doctorInfo = null;
        $patientInfo = null;

        // Normaliser le texte
        $text = mb_strtolower($text, 'UTF-8');
        $lines = explode("\n", $text);

        // Patterns pour identifier une ordonnance
        $prescriptionIndicators = [
            'ordonnance', 'prescription', 'dr.', 'docteur', 
            'médecin', 'cabinet', 'clinique', 'hôpital',
            'patient', 'le ', 'à prendre', 'posologie',
        ];

        foreach ($prescriptionIndicators as $indicator) {
            if (str_contains($text, $indicator)) {
                $isPrescription = true;
                break;
            }
        }

        // Base de données de médicaments courants en Côte d'Ivoire
        $commonMedications = $this->getCommonMedicationsDatabase();

        // Rechercher les médicaments dans le texte
        foreach ($commonMedications as $medName => $aliases) {
            foreach ($aliases as $alias) {
                if (str_contains($text, mb_strtolower($alias))) {
                    $medications[] = [
                        'name' => $medName,
                        'matched_text' => $alias,
                        'confidence' => 0.9,
                    ];
                    
                    // Essayer d'extraire le dosage associé
                    $dosage = $this->extractDosageNearMedication($text, $alias);
                    if ($dosage) {
                        $dosages[$medName] = $dosage;
                    }
                    break; // Éviter les doublons
                }
            }
        }

        // Recherche par patterns regex pour médicaments non reconnus
        $unknownMeds = $this->findUnknownMedications($text, $medications);
        $medications = array_merge($medications, $unknownMeds);

        // Extraire info docteur
        if (preg_match('/dr\.?\s*([a-zéèêëàâäùûüôöîïç\s]+)/i', $text, $matches)) {
            $doctorInfo = trim($matches[1]);
        }

        return [
            'medications' => $medications,
            'dosages' => $dosages,
            'is_prescription' => $isPrescription,
            'doctor_info' => $doctorInfo,
            'patient_info' => $patientInfo,
        ];
    }

    /**
     * Base de données des médicaments courants
     */
    protected function getCommonMedicationsDatabase(): array
    {
        return [
            // Antalgiques / Antipyrétiques
            'Paracétamol' => ['paracétamol', 'paracetamol', 'doliprane', 'efferalgan', 'dafalgan'],
            'Ibuprofène' => ['ibuprofène', 'ibuprofene', 'advil', 'nurofen', 'brufen'],
            'Aspirine' => ['aspirine', 'aspegic', 'aspro'],
            'Tramadol' => ['tramadol', 'topalgic', 'contramal'],
            
            // Antibiotiques
            'Amoxicilline' => ['amoxicilline', 'amoxicillin', 'clamoxyl', 'augmentin', 'amoxil'],
            'Azithromycine' => ['azithromycine', 'azithromycin', 'zithromax'],
            'Ciprofloxacine' => ['ciprofloxacine', 'ciprofloxacin', 'ciflox'],
            'Métronidazole' => ['métronidazole', 'metronidazole', 'flagyl'],
            'Cotrimoxazole' => ['cotrimoxazole', 'bactrim'],
            'Doxycycline' => ['doxycycline', 'vibramycine'],
            
            // Antipaludéens
            'Artéméther-Luméfantrine' => ['coartem', 'riamet', 'artéméther', 'artemether'],
            'Quinine' => ['quinine', 'quinimax'],
            'Artésunate' => ['artésunate', 'artesunate'],
            
            // Antihypertenseurs
            'Amlodipine' => ['amlodipine', 'amlor', 'norvasc'],
            'Captopril' => ['captopril', 'lopril'],
            'Losartan' => ['losartan', 'cozaar'],
            'Hydrochlorothiazide' => ['hydrochlorothiazide', 'esidrex'],
            
            // Antidiabétiques
            'Metformine' => ['metformine', 'metformin', 'glucophage', 'stagid'],
            'Glibenclamide' => ['glibenclamide', 'daonil'],
            
            // Gastro-entérologie
            'Oméprazole' => ['oméprazole', 'omeprazole', 'mopral'],
            'Métoclopramide' => ['métoclopramide', 'metoclopramide', 'primpéran'],
            'Lopéramide' => ['lopéramide', 'loperamide', 'imodium'],
            
            // Allergies / Antihistaminiques
            'Cétirizine' => ['cétirizine', 'cetirizine', 'zyrtec', 'virlix'],
            'Loratadine' => ['loratadine', 'clarityne'],
            'Desloratadine' => ['desloratadine', 'aerius'],
            
            // Vitamines / Suppléments
            'Vitamine C' => ['vitamine c', 'vitamin c', 'ascorbique'],
            'Fer' => ['fer', 'tardyferon', 'fumafer'],
            'Acide folique' => ['acide folique', 'folic acid', 'speciafoldine'],
            'Vitamine D' => ['vitamine d', 'vitamin d', 'uvedose'],
            
            // Anti-inflammatoires
            'Diclofénac' => ['diclofénac', 'diclofenac', 'voltarène', 'voltaren'],
            'Kétoprofène' => ['kétoprofène', 'ketoprofene', 'profénid'],
            
            // Respiratoire
            'Salbutamol' => ['salbutamol', 'ventoline'],
            'Ambroxol' => ['ambroxol', 'mucosolvan'],
            
            // Dermatologie
            'Bétaméthasone' => ['bétaméthasone', 'betamethasone', 'diprosone'],
            'Clotrimazole' => ['clotrimazole', 'canesten'],
        ];
    }

    /**
     * Extrait le dosage près d'un médicament
     */
    protected function extractDosageNearMedication(string $text, string $medication): ?array
    {
        $position = strpos($text, mb_strtolower($medication));
        if ($position === false) return null;

        // Extraire le contexte autour du médicament (100 caractères avant/après)
        $start = max(0, $position - 50);
        $length = strlen($medication) + 100;
        $context = substr($text, $start, $length);

        // Patterns de dosage
        $dosage = null;
        
        // Dosage (ex: 500mg, 1g)
        if (preg_match('/(\d+)\s*(mg|g|ml|mcg)/i', $context, $matches)) {
            $dosage['strength'] = $matches[1] . $matches[2];
        }

        // Posologie (ex: 3x/j, 2 fois par jour)
        if (preg_match('/(\d+)\s*(x\s*\/\s*j|fois\s*par\s*jour|cp\s*\/\s*j)/i', $context, $matches)) {
            $dosage['frequency'] = $matches[1] . ' fois/jour';
        }

        // Durée (ex: pendant 7 jours)
        if (preg_match('/(\d+)\s*jours?/i', $context, $matches)) {
            $dosage['duration'] = $matches[1] . ' jours';
        }

        return $dosage;
    }

    /**
     * Trouve des médicaments non reconnus via patterns
     */
    protected function findUnknownMedications(string $text, array $alreadyFound): array
    {
        $found = [];
        $foundNames = array_column($alreadyFound, 'name');

        // Pattern générique pour médicaments (mot + dosage)
        // Ex: "Médicament 500mg" ou "Nom-Med 1g"
        preg_match_all('/([A-Za-zéèêëàâäùûüôöîïçÉÈÊËÀÂÄÙÛÜÔÖÎÏÇ][A-Za-zéèêëàâäùûüôöîïçÉÈÊËÀÂÄÙÛÜÔÖÎÏÇ\-]+)\s*(\d+)\s*(mg|g|ml)/i', $text, $matches, PREG_SET_ORDER);

        foreach ($matches as $match) {
            $name = ucfirst(trim($match[1]));
            
            // Ignorer les mots courts ou déjà trouvés
            if (strlen($name) < 4 || in_array($name, $foundNames)) {
                continue;
            }
            
            // Ignorer les mots communs qui ne sont pas des médicaments
            $skipWords = ['pour', 'dans', 'avec', 'sans', 'avant', 'après', 'pendant', 'fois', 'jour', 'matin', 'soir'];
            if (in_array(mb_strtolower($name), $skipWords)) {
                continue;
            }

            $found[] = [
                'name' => $name . ' ' . $match[2] . $match[3],
                'matched_text' => $match[0],
                'confidence' => 0.6, // Moins confiant car non reconnu
            ];
            $foundNames[] = $name;
        }

        return $found;
    }

    /**
     * Calcule le score de confiance global
     */
    protected function calculateConfidence(array $response, array $analysis): float
    {
        $confidence = 0.5; // Base

        // Bonus si c'est identifié comme ordonnance
        if ($analysis['is_prescription']) {
            $confidence += 0.2;
        }

        // Bonus basé sur le nombre de médicaments trouvés
        $medCount = count($analysis['medications']);
        if ($medCount > 0) {
            $confidence += min(0.2, $medCount * 0.05);
        }

        // Bonus si info docteur trouvée
        if (!empty($analysis['doctor_info'])) {
            $confidence += 0.1;
        }

        return min(1.0, round($confidence, 2));
    }

    /**
     * Analyse basique sans API (fallback)
     */
    protected function basicTextAnalysis(string $imagePath): array
    {
        return [
            'success' => true,
            'raw_text' => '',
            'medications' => [],
            'dosages' => [],
            'confidence' => 0,
            'is_prescription' => false,
            'message' => 'Analyse OCR non disponible (clé API non configurée). Validation manuelle requise.',
            'requires_manual_review' => true,
        ];
    }

    /**
     * Retourne un résultat d'erreur
     */
    protected function errorResult(string $message): array
    {
        return [
            'success' => false,
            'error' => $message,
            'medications' => [],
            'confidence' => 0,
        ];
    }
}
