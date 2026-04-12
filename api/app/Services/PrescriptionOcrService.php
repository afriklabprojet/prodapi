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
        $this->apiKey = config('services.google_vision.api_key') ?? config('services.google_maps.key');
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

            // Fallback: pas d'authentification disponible
            Log::error('[OCR] No authentication available - neither service account nor API key configured');
            return $this->errorResult('Service OCR non configuré. Veuillez configurer les credentials Google Cloud Vision.');

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
     * Utilise plusieurs features pour améliorer la détection du manuscrit
     */
    protected function callVisionApiWithToken(string $imageContent, string $accessToken): array
    {
        $response = Http::withToken($accessToken)
            ->timeout(60)
            ->post('https://vision.googleapis.com/v1/images:annotate', [
                'requests' => [
                    [
                        'image' => [
                            'content' => base64_encode($imageContent),
                        ],
                        'features' => [
                            // TEXT_DETECTION est meilleur pour le texte manuscrit
                            ['type' => 'TEXT_DETECTION', 'maxResults' => 50],
                            // DOCUMENT_TEXT_DETECTION pour la structure
                            ['type' => 'DOCUMENT_TEXT_DETECTION'],
                        ],
                        'imageContext' => [
                            'languageHints' => ['fr', 'fr-FR', 'en'],
                            // Améliorer la détection de l'écriture manuscrite
                            'textDetectionParams' => [
                                'enableTextDetectionConfidenceScore' => true,
                                // Mode avancé pour le manuscrit
                                'advancedOcrOptions' => ['enable_handwriting'],
                            ],
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

        return $this->parseGoogleVisionResponse($response->json(), true);
    }

    /**
     * Call Vision API with API key
     * Utilise plusieurs features pour améliorer la détection du manuscrit
     */
    protected function callVisionApiWithKey(string $imageContent, string $apiKey): array
    {
        $response = Http::timeout(60)
            ->post('https://vision.googleapis.com/v1/images:annotate?key=' . $apiKey, [
            'requests' => [
                [
                    'image' => [
                        'content' => base64_encode($imageContent),
                    ],
                    'features' => [
                        // TEXT_DETECTION est meilleur pour le texte manuscrit
                        ['type' => 'TEXT_DETECTION', 'maxResults' => 50],
                        // DOCUMENT_TEXT_DETECTION pour la structure
                        ['type' => 'DOCUMENT_TEXT_DETECTION'],
                    ],
                    'imageContext' => [
                        'languageHints' => ['fr', 'fr-FR', 'en'],
                        // Améliorer la détection de l'écriture manuscrite
                        'textDetectionParams' => [
                            'enableTextDetectionConfidenceScore' => true,
                            'advancedOcrOptions' => ['enable_handwriting'],
                        ],
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

        return $this->parseGoogleVisionResponse($response->json(), true);
    }

    /**
     * Récupère le contenu de l'image
     */
    protected function getImageContent(string $imagePath): ?string
    {
        // Essayer le disque private (Laravel 11 - stockage sécurisé)
        if (Storage::disk('private')->exists($imagePath)) {
            return Storage::disk('private')->get($imagePath);
        }

        // Essayer le disque local (par défaut)
        if (Storage::exists($imagePath)) {
            return Storage::get($imagePath);
        }

        // Essayer le disque public
        if (Storage::disk('public')->exists($imagePath)) {
            return Storage::disk('public')->get($imagePath);
        }
        
        // Chemin absolu
        if (file_exists($imagePath)) {
            return file_get_contents($imagePath);
        }

        // Chemin dans storage/app/private
        $fullPath = storage_path('app/private/' . $imagePath);
        if (file_exists($fullPath)) {
            return file_get_contents($fullPath);
        }

        Log::warning('[OCR] Image not found', ['path' => $imagePath]);
        return null;
    }

    /**
     * Parse la réponse de Google Vision API
     * Combine TEXT_DETECTION et DOCUMENT_TEXT_DETECTION pour couvrir manuscrit + imprimé
     * 
     * @param array $data Réponse JSON de l'API
     * @param bool $isHandwritingMode Si true, ajuste les seuils pour le manuscrit
     */
    protected function parseGoogleVisionResponse(array $data, bool $isHandwritingMode = false): array
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

        // Récupérer le texte complet - combiner les deux sources
        $fullTextAnnotation = $response['fullTextAnnotation'] ?? null;
        $textAnnotations = $response['textAnnotations'] ?? [];
        
        // Préférer fullTextAnnotation, sinon textAnnotations
        $fullText = $fullTextAnnotation['text'] ?? 
                    ($textAnnotations[0]['description'] ?? '');

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
        
        // Détecter si l'image contient du texte manuscrit
        $hasHandwriting = $this->detectHandwriting($fullTextAnnotation, $textAnnotations);
        
        Log::info('[OCR] Text detection completed', [
            'text_length' => mb_strlen($fullText),
            'has_handwriting' => $hasHandwriting,
            'fulltext_available' => !empty($fullTextAnnotation),
            'annotations_count' => count($textAnnotations),
        ]);

        // Extraire les mots avec leur confiance - passer les deux sources
        $wordConfidences = $this->extractWordConfidences($fullTextAnnotation, $textAnnotations);
        
        Log::info('[OCR] Word confidences extracted', [
            'total_words' => count($wordConfidences),
            'handwritten_words' => count(array_filter($wordConfidences, fn($w) => $w['is_likely_handwritten'] ?? false)),
            'sample' => array_slice($wordConfidences, 0, 10),
        ]);

        // Analyser le texte pour extraire les médicaments
        // Passer le flag manuscrit pour ajuster les seuils
        $analysis = $this->extractMedicationsFromText($fullText, $wordConfidences, $hasHandwriting);

        // Calculer la confiance globale
        $confidence = $this->calculateConfidence($response, $analysis, $hasHandwriting);

        return [
            'success' => true,
            'raw_text' => $fullText,
            'medications' => $analysis['medications'],
            'medical_exams' => $analysis['medical_exams'] ?? [],
            'dosages' => $analysis['dosages'],
            'confidence' => $confidence,
            'is_prescription' => $analysis['is_prescription'],
            'doctor_info' => $analysis['doctor_info'],
            'patient_info' => $analysis['patient_info'],
            'has_handwriting' => $hasHandwriting,
        ];
    }

    /**
     * Détecte si l'image contient du texte manuscrit
     * Basé sur les confiances moyennes et la variabilité des confiances
     */
    protected function detectHandwriting(?array $fullTextAnnotation, array $textAnnotations): bool
    {
        if (!$fullTextAnnotation || !isset($fullTextAnnotation['pages'])) {
            // Si pas de fullTextAnnotation, suppose manuscrit si textAnnotations existe
            return !empty($textAnnotations);
        }
        
        $confidences = [];
        
        foreach ($fullTextAnnotation['pages'] as $page) {
            foreach ($page['blocks'] ?? [] as $block) {
                $blockConf = $block['confidence'] ?? 0;
                $confidences[] = $blockConf;
                
                foreach ($block['paragraphs'] ?? [] as $paragraph) {
                    foreach ($paragraph['words'] ?? [] as $word) {
                        $wordConf = $word['confidence'] ?? $blockConf;
                        $confidences[] = $wordConf;
                    }
                }
            }
        }
        
        if (empty($confidences)) {
            return true; // Assume manuscrit si pas de données de confiance
        }
        
        $avgConfidence = array_sum($confidences) / count($confidences);
        
        // Calcul de la variance pour détecter le manuscrit
        // Le manuscrit a généralement une variance plus élevée (certains mots lisibles, d'autres non)
        $variance = 0;
        foreach ($confidences as $conf) {
            $variance += pow($conf - $avgConfidence, 2);
        }
        $variance = $variance / count($confidences);
        
        // Critères de détection manuscrit:
        // 1. Confiance moyenne < 0.85 (texte imprimé = généralement > 0.95)
        // 2. OU variance élevée (> 0.05) indiquant un mélange lisible/illisible
        $isHandwriting = $avgConfidence < 0.85 || $variance > 0.05;
        
        Log::debug('[OCR] Handwriting detection', [
            'avg_confidence' => round($avgConfidence, 3),
            'variance' => round($variance, 4),
            'is_handwriting' => $isHandwriting,
            'samples' => count($confidences),
        ]);
        
        return $isHandwriting;
    }

    /**
     * Extraire les mots et leur confiance depuis fullTextAnnotation ET textAnnotations
     * Combine les deux sources pour mieux détecter le manuscrit
     * 
     * Les mots avec une confiance faible sont souvent du texte manuscrit mal lu
     * Les mots avec une confiance élevée sont souvent du texte imprimé
     */
    protected function extractWordConfidences(?array $fullTextAnnotation, ?array $textAnnotations = null): array
    {
        $wordConfidences = [];
        
        // Source 1: fullTextAnnotation (structure hiérarchique, meilleur pour texte imprimé)
        if ($fullTextAnnotation && isset($fullTextAnnotation['pages'])) {
            foreach ($fullTextAnnotation['pages'] as $page) {
                foreach ($page['blocks'] ?? [] as $block) {
                    $blockConfidence = $block['confidence'] ?? 0;
                    $blockType = $block['blockType'] ?? 'TEXT';
                    
                    // Pour le texte manuscrit, la confiance de bloc est souvent plus basse
                    $isLikelyHandwritten = $blockConfidence < 0.85;
                    
                    foreach ($block['paragraphs'] ?? [] as $paragraph) {
                        foreach ($paragraph['words'] ?? [] as $word) {
                            $wordText = '';
                            foreach ($word['symbols'] ?? [] as $symbol) {
                                $wordText .= $symbol['text'] ?? '';
                            }
                            $wordConfidence = $word['confidence'] ?? $blockConfidence;
                            
                            $key = mb_strtolower($wordText);
                            $wordConfidences[$key] = [
                                'text' => $wordText,
                                'confidence' => $wordConfidence,
                                'block_confidence' => $blockConfidence,
                                'is_likely_handwritten' => $isLikelyHandwritten || $wordConfidence < 0.85,
                            ];
                        }
                    }
                }
            }
        }
        
        // Source 2: textAnnotations (liste plate, souvent meilleur pour manuscrit)
        // Ajoute les mots non trouvés dans fullTextAnnotation
        if ($textAnnotations && count($textAnnotations) > 1) {
            // Première annotation = texte complet, les suivantes = mots individuels
            foreach (array_slice($textAnnotations, 1) as $annotation) {
                $wordText = $annotation['description'] ?? '';
                $key = mb_strtolower($wordText);
                
                // Ne pas écraser si déjà trouvé avec fullTextAnnotation
                if (!isset($wordConfidences[$key]) && mb_strlen($wordText) >= 2) {
                    // textAnnotations n'a pas de score de confiance, 
                    // on estime basé sur la taille et le contexte
                    $estimatedConfidence = 0.6; // Confiance modérée par défaut
                    
                    $wordConfidences[$key] = [
                        'text' => $wordText,
                        'confidence' => $estimatedConfidence,
                        'block_confidence' => $estimatedConfidence,
                        'is_likely_handwritten' => true, // Assume manuscrit si pas dans fullText
                        'source' => 'text_detection',
                    ];
                }
            }
        }

        return $wordConfidences;
    }

    /**
     * Détermine si un mot est probablement du texte imprimé (formulaire)
     * basé sur sa confiance OCR. Le texte imprimé a généralement une confiance > 0.95
     * Le texte manuscrit a une confiance plus basse (0.3-0.85 typiquement)
     */
    protected function isLikelyPrintedFormText(string $word, array $wordConfidences): bool
    {
        $lower = mb_strtolower($word);
        if (isset($wordConfidences[$lower])) {
            // Confiance très haute = texte imprimé typiquement
            return $wordConfidences[$lower]['confidence'] >= 0.95;
        }
        return false;
    }

    /**
     * Extrait les médicaments du texte OCR
     * @param string $text Le texte brut extrait
     * @param array $wordConfidences Confiances par mot (optionnel)
     * @param bool $isHandwriting Si true, ajuste les seuils pour le manuscrit
     */
    public function extractMedicationsFromText(string $text, array $wordConfidences = [], bool $isHandwriting = false): array
    {
        $medications = [];
        $dosages = [];
        $isPrescription = false;
        $doctorInfo = null;
        $patientInfo = null;

        // Garder le texte original pour la détection par patterns (casse importante)
        $originalText = $text;
        // Normaliser le texte pour la recherche de médicaments connus
        $text = mb_strtolower($text, 'UTF-8');
        $lines = explode("\n", $text);

        // Patterns pour identifier une ordonnance (élargi pour manuscrit)
        $prescriptionIndicators = [
            'ordonnance', 'prescription', 'dr.', 'docteur', 
            'médecin', 'cabinet', 'clinique', 'hôpital',
            'patient', 'le ', 'à prendre', 'posologie',
            // Ajouts pour manuscrit (variations d'écriture)
            'ordo', 'rx', 'med', 'traitement', 'medicament',
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
        // Utiliser fuzzy matching si manuscrit détecté
        foreach ($commonMedications as $medName => $aliases) {
            $matched = false;
            $matchedAlias = null;
            $matchConfidence = 0.9;
            
            foreach ($aliases as $alias) {
                // Match exact
                if (str_contains($text, mb_strtolower($alias))) {
                    $matched = true;
                    $matchedAlias = $alias;
                    break;
                }
                
                // Fuzzy match pour manuscrit (similarité > 80%)
                if ($isHandwriting && mb_strlen($alias) >= 4) {
                    $fuzzyMatch = $this->fuzzyMatchInText($text, $alias);
                    if ($fuzzyMatch) {
                        $matched = true;
                        $matchedAlias = $fuzzyMatch['matched'];
                        $matchConfidence = $fuzzyMatch['confidence'];
                        break;
                    }
                }
            }
            
            if ($matched && $matchedAlias) {
                $medications[] = [
                    'name' => $medName,
                    'matched_text' => $matchedAlias,
                    'confidence' => $matchConfidence,
                ];
                
                // Essayer d'extraire le dosage associé
                $dosage = $this->extractDosageNearMedication($text, $matchedAlias);
                if ($dosage) {
                    $dosages[$medName] = $dosage;
                }
            }
        }

        // Recherche par patterns regex pour médicaments non reconnus
        // Utiliser le texte ORIGINAL (avec majuscules) pour Pattern 2
        $unknownMeds = $this->findUnknownMedications($originalText, $medications, $wordConfidences, $isHandwriting);
        $medications = array_merge($medications, $unknownMeds);

        // Extraire les examens médicaux demandés (pour bulletins d'examen)
        $medicalExams = $this->extractMedicalExams($text, $isHandwriting);

        // Extraire info docteur
        if (preg_match('/dr\.?\s*([a-zéèêëàâäùûüôöîïç\s]+)/i', $text, $matches)) {
            $doctorInfo = trim($matches[1]);
        }

        return [
            'medications' => $medications,
            'dosages' => $dosages,
            'medical_exams' => $medicalExams,
            'is_prescription' => $isPrescription,
            'doctor_info' => $doctorInfo,
            'patient_info' => $patientInfo,
        ];
    }

    /**
     * Extrait les examens médicaux demandés
     */
    protected function extractMedicalExams(string $text, bool $isHandwriting = false): array
    {
        $exams = [];
        $textLower = mb_strtolower($text);
        
        // Base de données des examens médicaux courants
        $examDatabase = [
            // Imagerie
            'Radiographie' => ['radiographie', 'radio', 'rx', 'radiographle', 'radiografle', 'radlo'],
            'Scanner' => ['scanner', 'tomodensitométrie', 'tdm', 'ct scan', 'scaner'],
            'IRM' => ['irm', 'imagerie par résonance', 'remnance magnétique'],
            'Échographie' => ['échographie', 'echographie', 'écho', 'echo', 'echographle'],
            'Mammographie' => ['mammographie', 'mammographle'],
            'Panoramique dentaire' => ['panoramique', 'orthopantomogramme'],
            'Scintigraphie' => ['scintigraphie', 'scintigraphle'],
            
            // Biologie / Analyses
            'Bilan sanguin' => ['bilan sanguin', 'prise de sang', 'analyse sanguine', 'hémogramme', 'hemogramme', 'nfs'],
            'Glycémie' => ['glycémie', 'glycemie', 'glycemle', 'taux de sucre'],
            'Créatinine' => ['créatinine', 'creatinine', 'creatinlne', 'fonction rénale'],
            'Bilan hépatique' => ['bilan hépatique', 'transaminases', 'asat', 'alat', 'got', 'gpt'],
            'Bilan lipidique' => ['bilan lipidique', 'cholestérol', 'cholesterol', 'triglycérides', 'triglycerides'],
            'Analyse urine' => ['analyse urine', 'ecbu', 'examen urinaire', 'urocult'],
            'Sérologie' => ['sérologie', 'serologie', 'sérologique'],
            'Groupe sanguin' => ['groupe sanguin', 'rhésus', 'rhesus', 'groupage'],
            
            // Cardiologie
            'ECG' => ['ecg', 'électrocardiogramme', 'electrocardiogramme'],
            'Écho cardiaque' => ['écho cardiaque', 'échographie cardiaque', 'echocardiographie'],
            'Holter' => ['holter', 'monitoring cardiaque'],
            'Test d\'effort' => ['test d\'effort', 'épreuve d\'effort', 'epreuve d\'effort'],
            
            // Neurologie
            'EEG' => ['eeg', 'électroencéphalogramme', 'electroencephalogramme'],
            'EMG' => ['emg', 'électromyogramme', 'electromyogramme'],
            'Ponction lombaire' => ['ponction lombaire', 'pl'],
            
            // Pneumologie
            'EFR' => ['efr', 'exploration fonctionnelle respiratoire', 'spirométrie', 'spirometrie'],
            'Gaz du sang' => ['gaz du sang', 'gazométrie', 'gazometrie'],
            
            // Gastro
            'Fibroscopie' => ['fibroscopie', 'fogd', 'gastroscopie', 'endoscopie'],
            'Coloscopie' => ['coloscopie', 'colonoscopie'],
            
            // Orthopédie / Rhumatologie
            'Densitométrie' => ['densitométrie', 'densitometrie', 'ostéodensitométrie'],
            'Arthrographie' => ['arthrographie', 'arthographie'],
            
            // Kinésithérapie / Rééducation
            'Kinésithérapie' => ['kinésithérapie', 'kinesitherapie', 'kine', 'kiné', 'kinesitheraple', 'mobilisation'],
            'Rééducation' => ['rééducation', 'reeducation', 'réeducation'],
        ];
        
        foreach ($examDatabase as $examName => $variants) {
            foreach ($variants as $variant) {
                // Match exact
                if (str_contains($textLower, $variant)) {
                    $exams[] = [
                        'name' => $examName,
                        'matched_text' => $variant,
                        'confidence' => 0.85,
                    ];
                    break;
                }
                
                // Fuzzy match pour manuscrit
                if ($isHandwriting && mb_strlen($variant) >= 4) {
                    $fuzzy = $this->fuzzyMatchInText($textLower, $variant);
                    if ($fuzzy) {
                        $exams[] = [
                            'name' => $examName,
                            'matched_text' => $fuzzy['matched'],
                            'confidence' => $fuzzy['confidence'],
                        ];
                        break;
                    }
                }
            }
        }
        
        // Extraire les zones anatomiques mentionnées
        $anatomyZones = $this->extractAnatomyZones($textLower);
        
        // Associer zones aux examens si possible
        foreach ($exams as &$exam) {
            if (!empty($anatomyZones)) {
                $exam['zones'] = $anatomyZones;
            }
        }
        
        return $exams;
    }

    /**
     * Extrait les zones anatomiques mentionnées
     */
    protected function extractAnatomyZones(string $text): array
    {
        $zones = [];
        
        $anatomyDatabase = [
            'Tête' => ['tête', 'tete', 'crâne', 'crane', 'cérébral', 'cerebral'],
            'Cou' => ['cou', 'cervical', 'cervicale', 'thyroïde', 'thyroide'],
            'Thorax' => ['thorax', 'thoracique', 'poumon', 'pulmonaire', 'poitrine'],
            'Abdomen' => ['abdomen', 'abdominal', 'ventre', 'foie', 'vésicule', 'rate'],
            'Bassin' => ['bassin', 'pelvien', 'hanche', 'sacrum'],
            'Colonne vertébrale' => ['colonne', 'vertèbre', 'vertebre', 'lombaire', 'dorsale', 'rachis', 'rachidien'],
            'Épaule' => ['épaule', 'epaule', 'scapulaire'],
            'Bras' => ['bras', 'humérus', 'humerus', 'coude', 'avant-bras'],
            'Main' => ['main', 'poignet', 'carpe', 'métacarpe', 'doigt'],
            'Jambe' => ['jambe', 'fémur', 'femur', 'tibia', 'péroné', 'perone'],
            'Genou' => ['genou', 'rotule', 'ménisque', 'menisque'],
            'Pied' => ['pied', 'cheville', 'tarse', 'métatarse', 'orteil'],
            'Articulation' => ['articulation', 'articulaire', 'articulations'],
        ];
        
        foreach ($anatomyDatabase as $zoneName => $variants) {
            foreach ($variants as $variant) {
                if (str_contains($text, $variant)) {
                    $zones[] = $zoneName;
                    break;
                }
            }
        }
        
        return array_unique($zones);
    }

    /**
     * Base de données des médicaments courants
     * Inclut des variations ortho pour manuscrit (ex: Paracetanol pour Paracétamol)
     */
    protected function getCommonMedicationsDatabase(): array
    {
        return [
            // Antalgiques / Antipyrétiques
            'Paracétamol' => ['paracétamol', 'paracetamol', 'doliprane', 'efferalgan', 'dafalgan', 'paracetanol', 'parcetamol', 'paracetamo1'],
            'Ibuprofène' => ['ibuprofène', 'ibuprofene', 'advil', 'nurofen', 'brufen', 'ibuprofen', 'ibuprofne', 'ibuprofèn'],
            'Aspirine' => ['aspirine', 'aspegic', 'aspro', 'aspirin', 'aspirne', 'asperine'],
            'Tramadol' => ['tramadol', 'topalgic', 'contramal', 'tramado1', 'tramadoll', 'tramado'],
            'Codéine' => ['codéine', 'codeine', 'codoliprane', 'dafalgan codeine'],
            
            // Antibiotiques
            'Amoxicilline' => ['amoxicilline', 'amoxicillin', 'clamoxyl', 'augmentin', 'amoxil', 'amoxiciline', 'amoxicilin', 'amoxycilline', 'amoxi'],
            'Azithromycine' => ['azithromycine', 'azithromycin', 'zithromax', 'azithro', 'azitromycine'],
            'Ciprofloxacine' => ['ciprofloxacine', 'ciprofloxacin', 'ciflox', 'cipro', 'ciproflox'],
            'Métronidazole' => ['métronidazole', 'metronidazole', 'flagyl', 'metronidazo1e', 'metronldazole'],
            'Cotrimoxazole' => ['cotrimoxazole', 'bactrim', 'cotrimox', 'cotrimoxazo1e'],
            'Doxycycline' => ['doxycycline', 'vibramycine', 'doxycy', 'doxycyclin', 'doxycycl', 'doxycyline'],
            'Amoxicilline-Acide clavulanique' => ['amoxicilline acide clavulanique', 'augmentin', 'clavulin', 'amoclav'],
            'Érythromycine' => ['érythromycine', 'erythromycine', 'erythromycin', 'ery'],
            'Céfixime' => ['céfixime', 'cefixime', 'oroken', 'suprax'],
            'Céftriaxone' => ['céftriaxone', 'ceftriaxone', 'rocephine', 'ceftriaxon'],
            
            // Antipaludéens
            'Artéméther-Luméfantrine' => ['coartem', 'riamet', 'artéméther', 'artemether', 'lumefantrine', 'coartem'],
            'Quinine' => ['quinine', 'quinimax', 'quinlne'],
            'Artésunate' => ['artésunate', 'artesunate', 'artesunat', 'artesun'],
            'ACT' => ['act', 'artemisinine', 'falcimon'],
            
            // Antihypertenseurs
            'Amlodipine' => ['amlodipine', 'amlor', 'norvasc', 'amlodip', 'amlodipln'],
            'Captopril' => ['captopril', 'lopril', 'captopri1', 'capoten'],
            'Losartan' => ['losartan', 'cozaar', 'lozap'],
            'Hydrochlorothiazide' => ['hydrochlorothiazide', 'esidrex', 'hctz', 'hct'],
            'Atenolol' => ['atenolol', 'tenormine', 'atenolo1'],
            'Enalapril' => ['enalapril', 'renitec', 'enalapri1'],
            'Nifédipine' => ['nifédipine', 'nifedipine', 'adalate'],
            
            // Antidiabétiques
            'Metformine' => ['metformine', 'metformin', 'glucophage', 'stagid', 'metfor', 'metformlne'],
            'Glibenclamide' => ['glibenclamide', 'daonil', 'glibenclam', 'glibenclamlde'],
            'Gliclazide' => ['gliclazide', 'diamicron', 'gllclazide'],
            'Insuline' => ['insuline', 'insulin', 'lantus', 'novorapid', 'humalog'],
            
            // Gastro-entérologie
            'Oméprazole' => ['oméprazole', 'omeprazole', 'mopral', 'omeprazo1e', 'omepraz'],
            'Métoclopramide' => ['métoclopramide', 'metoclopramide', 'primpéran', 'primperan'],
            'Lopéramide' => ['lopéramide', 'loperamide', 'imodium', 'loperamid'],
            'Ranitidine' => ['ranitidine', 'azantac', 'ranltidine'],
            'Pantoprazole' => ['pantoprazole', 'inipomp', 'eupantol'],
            'Lansoprazole' => ['lansoprazole', 'lanzor', 'ogast'],
            'Smecta' => ['smecta', 'diosmectite'],
            
            // Allergies / Antihistaminiques
            'Cétirizine' => ['cétirizine', 'cetirizine', 'zyrtec', 'virlix', 'cetlrizine'],
            'Loratadine' => ['loratadine', 'clarityne', 'loratadin', 'loratadln'],
            'Desloratadine' => ['desloratadine', 'aerius', 'desloratadin'],
            'Chlorphéniramine' => ['chlorphéniramine', 'chlorpheniramine', 'polaramine'],
            'Dexchlorphéniramine' => ['dexchlorphéniramine', 'polaramine'],
            
            // Vitamines / Suppléments
            'Vitamine C' => ['vitamine c', 'vitamin c', 'ascorbique', 'vit c', 'vitc'],
            'Fer' => ['fer', 'tardyferon', 'fumafer', 'fero', 'ferol'],
            'Acide folique' => ['acide folique', 'folic acid', 'speciafoldine', 'folate', 'ac folique'],
            'Vitamine D' => ['vitamine d', 'vitamin d', 'uvedose', 'vit d', 'vitd'],
            'Vitamine B12' => ['vitamine b12', 'cyanocobalamine', 'vit b12'],
            'Calcium' => ['calcium', 'cacit', 'orocal'],
            'Magnésium' => ['magnésium', 'magnesium', 'magne b6', 'mag2'],
            'Zinc' => ['zinc', 'zn', 'rubozinc'],
            
            // Anti-inflammatoires
            'Diclofénac' => ['diclofénac', 'diclofenac', 'voltarène', 'voltaren', 'diclo', 'dic1ofenac'],
            'Kétoprofène' => ['kétoprofène', 'ketoprofene', 'profénid', 'ketoprofèn'],
            'Indométacine' => ['indométacine', 'indometacine', 'indocid'],
            'Prednisolone' => ['prednisolone', 'solupred', 'predniso1one'],
            'Prednisone' => ['prednisone', 'cortancyl', 'prednlsone'],
            'Dexaméthasone' => ['dexaméthasone', 'dexamethasone', 'dexa'],
            
            // Respiratoire
            'Salbutamol' => ['salbutamol', 'ventoline', 'ventolin', 'sa1butamol'],
            'Ambroxol' => ['ambroxol', 'mucosolvan', 'ambroxo1'],
            'Acétylcystéine' => ['acétylcystéine', 'acetylcysteine', 'fluimucil', 'mucomyst'],
            'Carbocistéine' => ['carbocistéine', 'carbocisteine', 'bronchokod'],
            'Terbutaline' => ['terbutaline', 'bricanyl'],
            
            // Dermatologie
            'Bétaméthasone' => ['bétaméthasone', 'betamethasone', 'diprosone', 'celestoderm'],
            'Clotrimazole' => ['clotrimazole', 'canesten', 'clotrimazo1e'],
            'Miconazole' => ['miconazole', 'daktarin', 'monistat'],
            'Hydrocortisone' => ['hydrocortisone', 'cortisedermyl', 'hydrocort'],
            
            // Anxiolytiques / Sédatifs
            'Diazépam' => ['diazépam', 'diazepam', 'valium'],
            'Alprazolam' => ['alprazolam', 'xanax', 'a1prazo1am'],
            'Bromazépam' => ['bromazépam', 'bromazepam', 'lexomil'],
            'Hydroxyzine' => ['hydroxyzine', 'atarax'],
            
            // Antidépresseurs
            'Amitriptyline' => ['amitriptyline', 'laroxyl', 'amitriptylin'],
            'Fluoxétine' => ['fluoxétine', 'fluoxetine', 'prozac'],
            'Sertraline' => ['sertraline', 'zoloft'],
            
            // Autres
            'Méthotrexate' => ['méthotrexate', 'methotrexate', 'mtx'],
            'Acide acétylsalicylique' => ['acide acétylsalicylique', 'aspirine', 'aspirin'],
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
     * Fuzzy match in text - cherche une correspondance approximative pour manuscrit
     * Gère les erreurs OCR courantes (l/1, o/0, a/e, etc.)
     */
    protected function fuzzyMatchInText(string $text, string $target): ?array
    {
        $targetLower = mb_strtolower($target);
        $targetLen = mb_strlen($targetLower);
        
        // Minimum 4 caractères pour fuzzy match
        if ($targetLen < 4) return null;
        
        // Substitutions courantes OCR manuscrit
        $ocrVariants = [
            'l' => ['1', 'i', 'I'],
            '1' => ['l', 'i'],
            'o' => ['0', 'O', 'a'],
            '0' => ['o', 'O'],
            'i' => ['1', 'l', 'j'],
            'e' => ['a', 'é', 'è', 'ê'],
            'a' => ['o', 'e', 'à', 'â'],
            'n' => ['m', 'u', 'r'],
            'm' => ['n', 'rn', 'nn'],
            'u' => ['v', 'n'],
            'c' => ['e', 'o'],
            's' => ['z', '5'],
            'z' => ['s', '2'],
        ];
        
        // Parcourir le texte par morceaux de même longueur
        $textLen = mb_strlen($text);
        
        for ($i = 0; $i <= $textLen - $targetLen; $i++) {
            $chunk = mb_substr($text, $i, $targetLen + 2); // +2 pour tolérer 1-2 chars supplémentaires
            $chunkClean = preg_replace('/[^a-zéèêëàâäùûüôöîïç0-9]/ui', '', $chunk);
            $chunkLower = mb_strtolower($chunkClean);
            
            // Calculer similarité
            similar_text($targetLower, $chunkLower, $percent);
            $similarity = $percent / 100;
            
            // Aussi calculer Levenshtein pour les petites variations
            $lev = 999;
            if (mb_strlen($chunkLower) <= 50 && mb_strlen($targetLower) <= 50) {
                $lev = levenshtein($targetLower, $chunkLower);
            }
            
            // Accepter si:
            // - Similarité > 80% 
            // - OU seulement 1-2 caractères de différence pour mots de 5+ lettres
            $maxLev = $targetLen >= 6 ? 2 : 1;
            
            if ($similarity >= 0.80 || $lev <= $maxLev) {
                // Ajuster la confiance basée sur la qualité du match
                $confidence = max(0.6, min(0.85, $similarity));
                
                return [
                    'matched' => trim($chunk),
                    'confidence' => $confidence,
                    'similarity' => $similarity,
                ];
            }
        }
        
        return null;
    }

    /**
     * Trouve des médicaments non reconnus via patterns
     * Utilise les confiances par mot pour filtrer le texte imprimé du formulaire
     * 
     * @param string $text Texte original (avec casse)
     * @param array $alreadyFound Médicaments déjà trouvés dans la base
     * @param array $wordConfidences Confiances par mot du OCR (optionnel)
     * @param bool $isHandwriting Mode manuscrit (seuils plus souples)
     */
    protected function findUnknownMedications(string $text, array $alreadyFound, array $wordConfidences = [], bool $isHandwriting = false): array
    {
        $found = [];
        $foundNames = array_map(fn($m) => mb_strtolower($m), array_column($alreadyFound, 'name'));

        // Mots à ignorer : étiquettes de formulaire imprimé, mots courants
        // Ces labels ne sont PAS du contenu manuscrit pertinent
        $skipWords = [
            // Mots courants français
            'pour', 'dans', 'avec', 'sans', 'avant', 'après', 'pendant', 'fois', 'jour', 'matin', 'soir',
            'aussi', 'autre', 'cette', 'entre', 'faire', 'comme', 'votre', 'notre', 'toute', 'suite',
            'chez', 'plus', 'très', 'bien', 'tout', 'tous', 'elle', 'nous', 'vous', 'leur', 'selon',
            
            // Labels de formulaires médicaux (imprimés)
            'bulletin', 'examen', 'pièce', 'piece', 'npiece', 'fiche',
            'nom', 'prénoms', 'prenoms', 'prénom', 'prenom', 'noms',
            'date', 'naissance', 'lieu', 'sexe', 'masculin', 'féminin', 'feminin',
            'adresse', 'telephone', 'téléphone', 'tel', 'fax', 'email', 'mail',
            'site', 'web', 'www', 'standard', 'administration',
            'indication', 'demandé', 'demande', 'demandeur',
            'médecin', 'medecin', 'docteur', 'prescripteur', 'traitant',
            'patient', 'patiente', 'malade', 'hospitalisé', 'hospitalise',
            'service', 'groupe', 'groupenovamed', 'novamed',
            'polyclinique', 'clinique', 'hôpital', 'hopital', 'centre', 'hospitalier',
            'internationale', 'indénié', 'indenie', 'l\'indénié',
            'abidjan', 'cocody', 'plateau', 'treichville', 'yopougon', 'marcory',
            'bouaké', 'bouake', 'yamoussoukro', 'daloa', 'korhogo', 'san-pédro',
            
            // Termes administratifs
            'numéro', 'numero', 'matricule', 'code', 'référence', 'reference', 'dossier',
            'assurance', 'mutuelle', 'sécurité', 'sociale', 'carte', 'vitale',
            'profession', 'nationalité', 'nationalite', 'identité', 'identite',
            'signature', 'cachet', 'tampon', 'date', 'heure',
            'original', 'copie', 'duplicata', 'renouvellement',
            
            // Termes médicaux généraux (pas des médicaments)
            'ordonnance', 'prescription', 'traitement', 'thérapie', 'therapie',
            'consultation', 'hospitalisation', 'ambulatoire', 'urgences',
            'diagnostic', 'résultat', 'resultat', 'observation', 'antécédent', 'antecedent',
            'allergie', 'chirurgie', 'anesthésie', 'anesthesie',
            'radiologie', 'imagerie', 'laboratoire', 'biologie',
            'neurologie', 'cardiologie', 'pédiatrie', 'pediatrie', 'gynécologie',
            'kinésithérapie', 'kinesitherapie', 'rééducation', 'reeducation',
            
            // Formes posologiques (pas des médicaments eux-mêmes)
            'comprimé', 'comprime', 'gélule', 'gelule', 'sirop', 'cachet',
            'boite', 'boîte', 'flacon', 'tube', 'ampoule', 'injection',
            'pommade', 'crème', 'creme', 'gel', 'goutte', 'suppositoire',
            'prendre', 'appliquer', 'injecter', 'avaler',
            
            // Mesures et durées
            'mois', 'semaine', 'jours', 'heures', 'minutes',
            'matin', 'midi', 'soir', 'nuit', 'repas',
            'poids', 'taille', 'temperature', 'température', 'tension', 'pouls',
            'montant', 'prix', 'tarif', 'total', 'nombre',
            
            // Spécialités médicales
            'médecine', 'medecine', 'générale', 'generale', 'spécialité', 'specialite',
            'interne', 'externe', 'résidente', 'resident', 'stagiaire', 'chirurgien',
            'pavillon', 'bâtiment', 'batiment', 'étage', 'etage', 'chambre',
        ];

        // Helper: vérifie si un mot candidat est probablement du texte imprimé de formulaire
        $isPrintedFormWord = function(string $word) use ($wordConfidences, $skipWords, $isHandwriting) {
            $lower = mb_strtolower($word);
            
            // Toujours exclure les skipWords
            if (in_array($lower, $skipWords)) return true;
            
            // Si on a les confiances OCR, utiliser pour filtrer
            if (!empty($wordConfidences) && isset($wordConfidences[$lower])) {
                $conf = $wordConfidences[$lower]['confidence'];
                // En mode manuscrit, on est plus souple (on ne filtre que confiance >= 0.98)
                // Sinon, texte imprimé = confiance >= 0.95 = à ignorer
                $printedThreshold = $isHandwriting ? 0.98 : 0.95;
                if ($conf >= $printedThreshold) {
                    Log::debug('[OCR] Skipping high-confidence printed word', ['word' => $word, 'confidence' => $conf, 'threshold' => $printedThreshold]);
                    return true;
                }
            }
            
            return false;
        };

        // Pattern 1: mot + dosage standard (ex: "Médicament 500mg")
        // C'est le pattern le plus fiable car le dosage confirme que c'est un médicament
        preg_match_all('/([A-Za-zéèêëàâäùûüôöîïçÉÈÊËÀÂÄÙÛÜÔÖÎÏÇ][A-Za-zéèêëàâäùûüôöîïçÉÈÊËÀÂÄÙÛÜÔÖÎÏÇ\-]+)\s*(\d+)\s*(mg|g|ml)/i', $text, $matches, PREG_SET_ORDER);

        foreach ($matches as $match) {
            $name = ucfirst(trim($match[1]));
            
            if (mb_strlen($name) < 4 || in_array(mb_strtolower($name), $foundNames)) {
                continue;
            }
            
            if (in_array(mb_strtolower($name), $skipWords)) {
                continue;
            }

            $found[] = [
                'name' => $name . ' ' . $match[2] . $match[3],
                'matched_text' => $match[0],
                'confidence' => 0.7,
            ];
            $foundNames[] = mb_strtolower($name);
        }

        // Pattern 2: Lignes contenant un mot + contexte de dosage/posologie
        // Beaucoup plus restrictif — exige un contexte médical (dosage, fréquence, etc.)
        $lines = explode("\n", $text);
        foreach ($lines as $line) {
            $line = trim($line);
            if (empty($line) || mb_strlen($line) > 60 || mb_strlen($line) < 4) continue;
            
            // La ligne doit contenir un indice de dosage/posologie
            if (!preg_match('/\d+\s*(mg|g|ml|cp|cpr|gel|comp|suppo|amp|sach|x\s*\/\s*j|fois|matin|soir|midi|\/jour)/i', $line)) {
                continue;
            }
            
            // Extraire le premier mot capitalisé qui pourrait être le nom du médicament
            if (preg_match('/([A-ZÉÈÊËÀÂÙÛÔÎÇ][a-zéèêëàâäùûüôöîïç]{3,}(?:[A-Za-zéèêëàâäùûüôöîïç\-]*)?)/u', $line, $match)) {
                $name = trim($match[1]);
                
                if (in_array(mb_strtolower($name), $skipWords) || in_array(mb_strtolower($name), $foundNames) || mb_strlen($name) < 4) {
                    continue;
                }
                
                // Vérifier si c'est un mot de formulaire imprimé via les confiances OCR
                if ($isPrintedFormWord($name)) {
                    continue;
                }
                
                $found[] = [
                    'name' => $name,
                    'matched_text' => $line,
                    'confidence' => 0.55,
                ];
                $foundNames[] = mb_strtolower($name);
            }
        }

        // Pattern 3: Mots avec confiance OCR basse (= manuscrit) proches de contexte médical
        // Seulement si on a les confiances par mot
        if (!empty($wordConfidences)) {
            // En mode manuscrit, élargir les seuils de confiance
            $minConf = $isHandwriting ? 0.15 : 0.3;
            $maxConf = $isHandwriting ? 0.92 : 0.90;
            $minLen = $isHandwriting ? 4 : 5;
            
            foreach ($wordConfidences as $lower => $info) {
                $conf = $info['confidence'];
                $word = $info['text'];
                
                // On cherche des mots manuscrits avec confiance basse
                // En mode manuscrit: plus souple (4+ lettres, confiance 0.15-0.92)
                if ($conf >= $minConf && $conf < $maxConf && mb_strlen($word) >= $minLen 
                    && preg_match('/^[A-ZÉÈÊËÀÂÙÛÔÎÇ]/u', $word)) {
                    
                    if (in_array($lower, $skipWords) || in_array($lower, $foundNames)) {
                        continue;
                    }
                    
                    // Vérifier le contexte : le mot doit être près d'un dosage/posologie dans le texte
                    $wordPos = mb_strpos($text, $word);
                    if ($wordPos !== false) {
                        $context = mb_substr($text, max(0, $wordPos - 20), mb_strlen($word) + 50);
                        if (preg_match('/\d+\s*(mg|g|ml|cp|cpr|gel|comp|suppo|amp|sach|x|fois|\/j)/i', $context)) {
                            $found[] = [
                                'name' => $word,
                                'matched_text' => trim(mb_substr($text, $wordPos, mb_strlen($word) + 30)),
                                'confidence' => round(min(0.6, $conf), 2),
                            ];
                            $foundNames[] = $lower;
                        }
                    }
                }
            }
        }

        return $found;
    }

    /**
     * Calcule le score de confiance global
     * 
     * @param array $response Réponse brute de l'API Vision
     * @param array $analysis Analyse extraite
     * @param bool $hasHandwriting Si texte manuscrit détecté
     */
    protected function calculateConfidence(array $response, array $analysis, bool $hasHandwriting = false): float
    {
        // Base différente selon manuscrit ou imprimé
        // Manuscrit = on part de 0.4 (plus incertain)
        // Imprimé = on part de 0.5
        $confidence = $hasHandwriting ? 0.4 : 0.5;

        // Bonus si c'est identifié comme ordonnance
        if ($analysis['is_prescription']) {
            $confidence += 0.2;
        }

        // Bonus basé sur le nombre de médicaments trouvés
        $medCount = count($analysis['medications']);
        if ($medCount > 0) {
            // En mode manuscrit, chaque médicament trouvé est plus significatif
            $bonusPerMed = $hasHandwriting ? 0.08 : 0.05;
            $confidence += min(0.25, $medCount * $bonusPerMed);
        }
        
        // Bonus basé sur les examens médicaux trouvés (bulletins d'examen)
        $examCount = count($analysis['medical_exams'] ?? []);
        if ($examCount > 0) {
            $bonusPerExam = $hasHandwriting ? 0.10 : 0.08;
            $confidence += min(0.25, $examCount * $bonusPerExam);
        }

        // Bonus si info docteur trouvée
        if (!empty($analysis['doctor_info'])) {
            $confidence += 0.1;
        }
        
        // En mode manuscrit avec contenu médical trouvé, c'est une bonne détection
        if ($hasHandwriting && ($medCount > 0 || $examCount > 0)) {
            $confidence += 0.05;
            Log::info('[OCR] Handwriting detection successful', [
                'medications_found' => $medCount,
                'exams_found' => $examCount,
                'confidence' => $confidence,
            ]);
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
            'medical_exams' => [],
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
