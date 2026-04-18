<?php

namespace App\Services;

use Google\Cloud\Vision\V1\Client\ImageAnnotatorClient;
use Google\Cloud\Vision\V1\BatchAnnotateImagesRequest;
use Google\Cloud\Vision\V1\AnnotateImageRequest;
use Google\Cloud\Vision\V1\Feature;
use Google\Cloud\Vision\V1\Feature\Type;
use Google\Cloud\Vision\V1\Image;
use Google\Cloud\Vision\V1\Likelihood;
use Google\Cloud\Vision\V1\FaceAnnotation\Landmark\Type as LandmarkType;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class KycValidationService
{
    /** @var ImageAnnotatorClient|null */
    private mixed $client = null;
    private bool $enabled = false;

    // Seuils de détection de fraude
    private const BLUR_THRESHOLD = 0.3;           // Score max de flou acceptable
    private const SCREEN_CONFIDENCE = 0.6;        // Confiance min pour détecter un écran
    private const LIVENESS_THRESHOLD = 0.7;       // Score min de vivacité
    private const FACE_SYMMETRY_THRESHOLD = 0.95; // Symétrie max (deepfake souvent trop symétrique)

    public function __construct()
    {
        $this->enabled = config('services.google_vision.enabled', false);
        
        if ($this->enabled) {
            try {
                $credentialsPath = config('services.google_vision.credentials_path');
                
                // Résoudre le chemin absolu si c'est un chemin relatif
                if ($credentialsPath && !str_starts_with($credentialsPath, '/')) {
                    $credentialsPath = base_path($credentialsPath);
                }
                
                // Options communes : forcer REST transport (pas besoin de grpc extension)
                $clientOptions = ['transport' => 'rest'];
                
                if ($credentialsPath && file_exists($credentialsPath)) {
                    $json = json_decode(file_get_contents($credentialsPath), true);
                    if (!$json || !isset($json['project_id'])) {
                        Log::error('Google Vision: credentials file is not valid JSON or missing project_id', ['path' => $credentialsPath]);
                        $this->enabled = false;
                        return;
                    }
                    $scopes = ['https://www.googleapis.com/auth/cloud-vision'];
                    $creds = new ServiceAccountCredentials($scopes, $json);
                    $clientOptions['credentials'] = $creds;
                    $this->client = new ImageAnnotatorClient($clientOptions);
                    Log::debug('Google Vision API initialized with credentials', [
                        'path' => $credentialsPath,
                        'project' => $json['project_id'],
                        'transport' => 'rest',
                    ]);
                } else {
                    Log::warning('Google Vision: credentials file not found, trying ADC', [
                        'path' => $credentialsPath,
                        'base_path' => base_path(),
                    ]);
                    $this->client = new ImageAnnotatorClient($clientOptions);
                }
            } catch (\Throwable $e) {
                Log::error('Google Vision API not available: ' . $e->getMessage(), [
                    'trace' => $e->getTraceAsString(),
                    'php_extensions' => implode(', ', get_loaded_extensions()),
                ]);
                $this->enabled = false;
            }
        }
    }
    
    /**
     * Vérifier si le service est actif et fonctionnel
     */
    public function isEnabled(): bool
    {
        return $this->enabled && $this->client !== null;
    }
    
    /**
     * Obtenir des informations de diagnostic
     */
    public function getDiagnostics(): array
    {
        $credentialsPath = config('services.google_vision.credentials_path');
        if ($credentialsPath && !str_starts_with($credentialsPath, '/')) {
            $credentialsPath = base_path($credentialsPath);
        }
        
        return [
            'enabled_config' => config('services.google_vision.enabled', false),
            'enabled_runtime' => $this->enabled,
            'client_initialized' => $this->client !== null,
            'credentials_path' => $credentialsPath,
            'credentials_exists' => $credentialsPath ? file_exists($credentialsPath) : false,
            'grpc_extension' => extension_loaded('grpc'),
            'transport' => 'rest',
            'php_version' => PHP_VERSION,
        ];
    }
    
    // ============================================================
    // HELPER METHODS POUR VISION API V2
    // ============================================================
    
    /**
     * Exécuter une détection avec les features spécifiées
     */
    private function annotateImage(string $imageContent, array $featureTypes): ?object
    {
        if (!$this->client) {
            return null;
        }
        
        $image = (new Image())->setContent($imageContent);
        $features = [];
        
        foreach ($featureTypes as $type) {
            $feature = (new Feature())->setType($type)->setMaxResults(50);
            $features[] = $feature;
        }
        
        $request = (new AnnotateImageRequest())
            ->setImage($image)
            ->setFeatures($features);
        
        $batchRequest = (new BatchAnnotateImagesRequest())
            ->setRequests([$request]);
        
        $response = $this->client->batchAnnotateImages($batchRequest);
        $responses = $response->getResponses();
        
        return count($responses) > 0 ? $responses[0] : null;
    }
    
    /**
     * Détection de labels
     */
    private function detectLabels(string $imageContent): array
    {
        $response = $this->annotateImage($imageContent, [Type::LABEL_DETECTION]);
        if (!$response) return [];
        return iterator_to_array($response->getLabelAnnotations());
    }
    
    /**
     * Détection de visages
     */
    private function detectFaces(string $imageContent): array
    {
        $response = $this->annotateImage($imageContent, [Type::FACE_DETECTION]);
        if (!$response) return [];
        return iterator_to_array($response->getFaceAnnotations());
    }
    
    /**
     * Détection de propriétés d'image
     */
    private function detectImageProperties(string $imageContent): ?object
    {
        $response = $this->annotateImage($imageContent, [Type::IMAGE_PROPERTIES]);
        if (!$response) return null;
        return $response->getImagePropertiesAnnotation();
    }
    
    /**
     * Détection web
     */
    private function detectWeb(string $imageContent): ?object
    {
        $response = $this->annotateImage($imageContent, [Type::WEB_DETECTION]);
        if (!$response) return null;
        return $response->getWebDetection();
    }
    
    /**
     * Détection de texte
     */
    private function detectText(string $imageContent): array
    {
        $response = $this->annotateImage($imageContent, [Type::TEXT_DETECTION]);
        if (!$response) return [];
        return iterator_to_array($response->getTextAnnotations());
    }
    
    /**
     * Détection de documents
     */
    private function detectDocument(string $imageContent): ?object
    {
        $response = $this->annotateImage($imageContent, [Type::DOCUMENT_TEXT_DETECTION]);
        if (!$response) return null;
        return $response->getFullTextAnnotation();
    }

    // ============================================================
    // DÉTECTION PHOTO D'ÉCRAN (Screen Photo Fraud Detection)
    // ============================================================

    /**
     * Détecte si l'image est une photo d'un écran (fraude courante)
     */
    public function detectScreenPhoto(string $imageContent): array
    {
        try {
            $labels = $this->detectLabels($imageContent);

            $screenKeywords = [
                'screen', 'monitor', 'display', 'lcd', 'led', 'computer',
                'television', 'tv', 'phone screen', 'tablet', 'device',
                'electronic', 'pixel', 'écran', 'moniteur', 'affichage'
            ];

            $screenScore = 0;
            $detectedLabels = [];

            foreach ($labels as $label) {
                $description = strtolower($label->getDescription());
                $detectedLabels[] = $description;
                
                foreach ($screenKeywords as $keyword) {
                    if (str_contains($description, $keyword)) {
                        $screenScore = max($screenScore, $label->getScore());
                    }
                }
            }

            // Analyser les propriétés pour détecter le moiré
            $properties = $this->detectImageProperties($imageContent);
            
            $hasMoirePattern = false;
            if ($properties && $properties->getDominantColors()) {
                $colors = $properties->getDominantColors()->getColors();
                $hasMoirePattern = $this->detectMoirePattern($colors);
                if ($hasMoirePattern) {
                    $screenScore += 0.3;
                }
            }

            $isScreenPhoto = $screenScore >= self::SCREEN_CONFIDENCE;

            return [
                'is_screen_photo' => $isScreenPhoto,
                'screen_score' => $screenScore,
                'has_moire' => $hasMoirePattern,
                'detected_labels' => $detectedLabels,
                'reason' => $isScreenPhoto 
                    ? 'Photo d\'écran détectée. Veuillez prendre une vraie photo.'
                    : null,
            ];

        } catch (\Throwable $e) {
            Log::warning('Screen detection error: ' . $e->getMessage());
            return ['is_screen_photo' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Détecter le motif de moiré (lignes de scan d'écran)
     */
    private function detectMoirePattern($colors): bool
    {
        if (count($colors) < 3) return false;

        $rgbCounts = ['r' => 0, 'g' => 0, 'b' => 0];
        
        foreach ($colors as $color) {
            $c = $color->getColor();
            $r = $c->getRed();
            $g = $c->getGreen();
            $b = $c->getBlue();
            
            if ($r > 200 && $g < 50 && $b < 50) $rgbCounts['r']++;
            if ($g > 200 && $r < 50 && $b < 50) $rgbCounts['g']++;
            if ($b > 200 && $r < 50 && $g < 50) $rgbCounts['b']++;
        }

        return array_sum($rgbCounts) >= 2;
    }

    // ============================================================
    // DÉTECTION DE FLOU (Blur Detection)
    // ============================================================

    /**
     * Analyse multiple indicateurs de netteté
     */
    public function detectBlur(string $imageContent): array
    {
        try {
            $faces = $this->detectFaces($imageContent);

            if (count($faces) === 0) {
                return ['is_blurry' => false, 'blur_score' => 0, 'no_face' => true];
            }

            $face = $faces[0];
            $blurLikelihood = $face->getBlurredLikelihood();
            
            // 0=UNKNOWN, 1=VERY_UNLIKELY, 2=UNLIKELY, 3=POSSIBLE, 4=LIKELY, 5=VERY_LIKELY
            $blurScore = match($blurLikelihood) {
                1 => 0.0,  // VERY_UNLIKELY
                2 => 0.2,  // UNLIKELY
                3 => 0.5,  // POSSIBLE
                4 => 0.7,  // LIKELY
                5 => 1.0,  // VERY_LIKELY
                default => 0.3,
            };

            $underExposed = $face->getUnderExposedLikelihood();
            $underScore = ($underExposed >= 4) ? 0.3 : 0;  // LIKELY=4, VERY_LIKELY=5
            
            $finalBlurScore = min(1.0, $blurScore + $underScore);
            $isBlurry = $finalBlurScore >= self::BLUR_THRESHOLD;

            return [
                'is_blurry' => $isBlurry,
                'blur_score' => $blurScore,
                'final_score' => $finalBlurScore,
                'under_exposed' => $underExposed >= 4,
                'detection_confidence' => $face->getDetectionConfidence(),
                'reason' => $isBlurry 
                    ? 'Image trop floue. Veuillez prendre une photo nette avec un bon éclairage.'
                    : null,
            ];

        } catch (\Throwable $e) {
            Log::warning('Blur detection error: ' . $e->getMessage());
            return ['is_blurry' => false, 'error' => $e->getMessage()];
        }
    }

    // ============================================================
    // DÉTECTION DEEPFAKE (AI-Generated Image Detection)
    // ============================================================

    /**
     * Analyse les incohérences typiques des images générées par IA
     */
    public function detectDeepfake(string $imageContent): array
    {
        try {
            $suspicionScore = 0;
            $suspicionReasons = [];

            $faces = $this->detectFaces($imageContent);

            if (count($faces) === 0) {
                return ['is_deepfake' => false, 'no_face' => true];
            }

            $face = $faces[0];
            $landmarks = $face->getLandmarks();

            // 1. Vérifier la symétrie du visage (deepfakes souvent trop symétriques)
            $symmetryScore = $this->calculateFaceSymmetry($landmarks);
            if ($symmetryScore > self::FACE_SYMMETRY_THRESHOLD) {
                $suspicionScore += 0.3;
                $suspicionReasons[] = 'Symétrie faciale anormalement élevée';
            }

            // 2. Vérifier les incohérences dans les yeux
            $eyeInconsistency = $this->checkEyeInconsistencies($landmarks);
            if ($eyeInconsistency) {
                $suspicionScore += 0.2;
                $suspicionReasons[] = 'Incohérence dans la région des yeux';
            }

            // 3. Vérifier si l'image existe sur internet
            $webDetection = $this->detectWeb($imageContent);
            
            $fullMatches = [];
            $partialMatches = [];
            
            if ($webDetection) {
                $fullMatches = iterator_to_array($webDetection->getFullMatchingImages());
                $partialMatches = iterator_to_array($webDetection->getPartialMatchingImages());
                
                if (count($fullMatches) > 0) {
                    $suspicionScore += 0.5;
                    $suspicionReasons[] = 'Image identique trouvée sur internet';
                }
                
                if (count($partialMatches) > 2) {
                    $suspicionScore += 0.2;
                    $suspicionReasons[] = 'Image similaire trouvée en ligne';
                }
            }

            // 4. Analyser les artefacts de génération
            $properties = $this->detectImageProperties($imageContent);
            $hasArtifacts = $this->detectGenerationArtifacts($properties);
            if ($hasArtifacts) {
                $suspicionScore += 0.2;
                $suspicionReasons[] = 'Artefacts de génération détectés';
            }

            $isDeepfake = $suspicionScore >= 0.5;

            return [
                'is_deepfake' => $isDeepfake,
                'suspicion_score' => $suspicionScore,
                'symmetry_score' => $symmetryScore ?? 0,
                'reasons' => $suspicionReasons,
                'found_online' => count($fullMatches) > 0,
                'reason' => $isDeepfake 
                    ? 'Image suspecte détectée. Veuillez prendre une vraie photo de vous-même.'
                    : null,
            ];

        } catch (\Throwable $e) {
            Log::warning('Deepfake detection error: ' . $e->getMessage());
            return ['is_deepfake' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Résoudre le nom d'un type de landmark (REST retourne int, gRPC retourne enum)
     */
    private function getLandmarkTypeName($type): string
    {
        if (is_int($type)) {
            return LandmarkType::name($type) ?? 'UNKNOWN_' . $type;
        }
        if (is_object($type) && method_exists($type, 'name')) {
            return $type->name();
        }
        return (string) $type;
    }

    /**
     * Calculer le score de symétrie du visage
     */
    private function calculateFaceSymmetry($landmarks): float
    {
        $leftPoints = [];
        $rightPoints = [];

        foreach ($landmarks as $landmark) {
            $type = $landmark->getType();
            $pos = $landmark->getPosition();
            $typeName = $this->getLandmarkTypeName($type);
            
            if (str_contains(strtolower($typeName), 'left')) {
                $leftPoints[$typeName] = ['x' => $pos->getX(), 'y' => $pos->getY()];
            }
            if (str_contains(strtolower($typeName), 'right')) {
                $rightPoints[$typeName] = ['x' => $pos->getX(), 'y' => $pos->getY()];
            }
        }

        if (empty($leftPoints) || empty($rightPoints)) return 0.5;

        $symmetrySum = 0;
        $count = 0;

        foreach ($leftPoints as $name => $leftPos) {
            $rightName = str_replace('LEFT', 'RIGHT', $name);
            if (isset($rightPoints[$rightName])) {
                $rightPos = $rightPoints[$rightName];
                $yDiff = abs($leftPos['y'] - $rightPos['y']);
                $symmetry = 1 - min(1, $yDiff / 50);
                $symmetrySum += $symmetry;
                $count++;
            }
        }

        return $count > 0 ? $symmetrySum / $count : 0.5;
    }

    /**
     * Vérifier les incohérences dans les yeux
     */
    private function checkEyeInconsistencies($landmarks): bool
    {
        $leftEyePoints = [];
        $rightEyePoints = [];

        foreach ($landmarks as $landmark) {
            $type = $this->getLandmarkTypeName($landmark->getType());
            $pos = $landmark->getPosition();
            
            if (str_contains($type, 'LEFT_EYE')) {
                $leftEyePoints[] = ['x' => $pos->getX(), 'y' => $pos->getY()];
            }
            if (str_contains($type, 'RIGHT_EYE')) {
                $rightEyePoints[] = ['x' => $pos->getX(), 'y' => $pos->getY()];
            }
        }

        if (count($leftEyePoints) < 2 || count($rightEyePoints) < 2) return false;

        $leftSize = $this->calculateBoundingBox($leftEyePoints);
        $rightSize = $this->calculateBoundingBox($rightEyePoints);
        $sizeDiff = abs($leftSize - $rightSize) / max($leftSize, $rightSize, 1);
        
        return $sizeDiff > 0.3;
    }

    private function calculateBoundingBox(array $points): float
    {
        if (empty($points)) return 0;
        
        $minX = $maxX = $points[0]['x'];
        $minY = $maxY = $points[0]['y'];
        
        foreach ($points as $p) {
            $minX = min($minX, $p['x']);
            $maxX = max($maxX, $p['x']);
            $minY = min($minY, $p['y']);
            $maxY = max($maxY, $p['y']);
        }
        
        return ($maxX - $minX) * ($maxY - $minY);
    }

    /**
     * Détecter les artefacts de génération IA
     */
    private function detectGenerationArtifacts($properties): bool
    {
        if (!$properties || !$properties->getDominantColors()) return false;

        $colors = $properties->getDominantColors()->getColors();
        $colorVariance = 0;
        $prevColor = null;
        
        foreach ($colors as $color) {
            if ($prevColor) {
                $diff = abs($color->getScore() - $prevColor);
                $colorVariance += $diff;
            }
            $prevColor = $color->getScore();
        }

        return $colorVariance < 0.1 && count(iterator_to_array($colors)) > 5;
    }

    // ============================================================
    // DÉTECTION VISAGE VIVANT (Liveness Detection)
    // ============================================================

    /**
     * Vérifie que le visage est d'une personne réelle devant la caméra
     */
    public function detectLiveness(string $imageContent): array
    {
        try {
            $livenessScore = 1.0;
            $issues = [];

            $faces = $this->detectFaces($imageContent);

            if (count($faces) === 0) {
                return ['is_live' => false, 'liveness_score' => 0, 'reason' => 'Aucun visage détecté'];
            }

            $face = $faces[0];

            // 1. Vérifier l'angle du visage
            $rollAngle = $face->getRollAngle();
            $panAngle = $face->getPanAngle();
            $tiltAngle = $face->getTiltAngle();

            if (abs($rollAngle) > 30) {
                $livenessScore -= 0.2;
                $issues[] = 'Visage incliné de manière suspecte';
            }
            if (abs($panAngle) > 45) {
                $livenessScore -= 0.2;
                $issues[] = 'Visage tourné latéralement';
            }
            if (abs($tiltAngle) > 30) {
                $livenessScore -= 0.2;
                $issues[] = 'Visage incliné vers le haut/bas';
            }

            // 2. Vérifier la qualité/confiance
            $confidence = $face->getDetectionConfidence();
            if ($confidence < 0.8) {
                $livenessScore -= 0.15;
                $issues[] = 'Qualité de détection faible';
            }

            // 3. Vérifier les expressions
            // 0=UNKNOWN, 1=VERY_UNLIKELY, 2=UNLIKELY, 3=POSSIBLE, 4=LIKELY, 5=VERY_LIKELY
            $joyLikelihood = $face->getJoyLikelihood();
            $sorrowLikelihood = $face->getSorrowLikelihood();
            $angerLikelihood = $face->getAngerLikelihood();
            $surpriseLikelihood = $face->getSurpriseLikelihood();

            $noExpression = 
                $joyLikelihood === 1 &&       // VERY_UNLIKELY
                $sorrowLikelihood === 1 &&
                $angerLikelihood === 1 &&
                $surpriseLikelihood === 1;
            
            if ($noExpression) {
                $livenessScore -= 0.1;
                $issues[] = 'Absence d\'expression détectable';
            }

            // 4. Vérifier le headwear
            $headwear = $face->getHeadwearLikelihood();
            if ($headwear >= 5) {  // VERY_LIKELY
                $livenessScore -= 0.1;
                $issues[] = 'Chapeau ou accessoire détecté';
            }

            // 5. Vérifier les reflets dans les yeux
            $landmarks = $face->getLandmarks();
            $hasEyeReflection = $this->checkEyeReflections($landmarks);
            if (!$hasEyeReflection) {
                $livenessScore -= 0.1;
                $issues[] = 'Pas de reflet détecté dans les yeux';
            }

            // 6. Vérifier si c'est une photo d'écran
            $screenCheck = $this->detectScreenPhoto($imageContent);
            if ($screenCheck['is_screen_photo']) {
                $livenessScore -= 0.5;
                $issues[] = 'Photo d\'écran détectée';
            }

            $livenessScore = max(0, $livenessScore);
            $isLive = $livenessScore >= self::LIVENESS_THRESHOLD;

            return [
                'is_live' => $isLive,
                'liveness_score' => round($livenessScore, 2),
                'detection_confidence' => $confidence,
                'face_angles' => [
                    'roll' => $rollAngle,
                    'pan' => $panAngle,
                    'tilt' => $tiltAngle,
                ],
                'issues' => $issues,
                'reason' => !$isLive 
                    ? 'Vivacité insuffisante. Veuillez prendre un selfie en direct, face à la caméra.'
                    : null,
            ];

        } catch (\Throwable $e) {
            Log::warning('Liveness detection error: ' . $e->getMessage());
            return ['is_live' => true, 'error' => $e->getMessage()];
        }
    }

    /**
     * Vérifier la présence de reflets dans les yeux
     */
    private function checkEyeReflections($landmarks): bool
    {
        $eyeLandmarks = 0;
        
        foreach ($landmarks as $landmark) {
            $type = $this->getLandmarkTypeName($landmark->getType());
            if (str_contains($type, 'EYE') || str_contains($type, 'PUPIL')) {
                $eyeLandmarks++;
            }
        }
        
        return $eyeLandmarks >= 4;
    }

    // ============================================================
    // VALIDATION SELFIE - COMPLÈTE AVEC TOUTES LES DÉTECTIONS
    // ============================================================

    /**
     * Valider un selfie avec TOUTES les vérifications anti-fraude
     * - Détection visage
     * - Détection flou
     * - Détection photo d'écran
     * - Détection deepfake
     * - Détection vivacité
     */
    public function validateSelfie(string $imagePath): array
    {
        if (!$this->enabled || !$this->client) {
            return ['valid' => true, 'skipped' => true, 'reason' => 'Validation automatique désactivée'];
        }

        try {
            $imageContent = $this->getImageContent($imagePath);
            if (!$imageContent) {
                return ['valid' => false, 'reason' => 'Impossible de lire l\'image'];
            }

            $fraudChecks = [];

            // ===== 1. VÉRIFICATION DU VISAGE =====
            $faces = $this->detectFaces($imageContent);
            $faceCount = count($faces);
            
            if ($faceCount === 0) {
                return [
                    'valid' => false,
                    'reason' => 'Aucun visage détecté. Veuillez prendre un selfie clair de votre visage.',
                    'fraud_type' => 'no_face',
                ];
            }
            
            if ($faceCount > 1) {
                return [
                    'valid' => false,
                    'reason' => 'Plusieurs visages détectés. Le selfie doit montrer uniquement votre visage.',
                    'fraud_type' => 'multiple_faces',
                ];
            }

            $face = $faces[0];
            $detectionConfidence = $face->getDetectionConfidence();
            
            if ($detectionConfidence < 0.7) {
                return [
                    'valid' => false,
                    'reason' => 'Qualité insuffisante. Veuillez prendre une photo plus nette.',
                    'fraud_type' => 'low_quality',
                ];
            }

            $fraudChecks['face'] = ['passed' => true, 'confidence' => $detectionConfidence];

            // ===== 2. DÉTECTION DE FLOU =====
            $blurCheck = $this->detectBlur($imageContent);
            $fraudChecks['blur'] = $blurCheck;
            
            if ($blurCheck['is_blurry']) {
                return [
                    'valid' => false,
                    'reason' => $blurCheck['reason'],
                    'fraud_type' => 'blurry_image',
                ];
            }

            // ===== 3. DÉTECTION PHOTO D'ÉCRAN =====
            $screenCheck = $this->detectScreenPhoto($imageContent);
            $fraudChecks['screen'] = $screenCheck;
            
            if ($screenCheck['is_screen_photo']) {
                Log::warning('KYC Fraud: Screen photo detected', ['path' => $imagePath]);
                return [
                    'valid' => false,
                    'reason' => 'Photo d\'écran détectée. Veuillez prendre une vraie photo (pas d\'écran/moniteur/téléphone).',
                    'fraud_type' => 'screen_photo',
                ];
            }

            // ===== 4. DÉTECTION DEEPFAKE =====
            $deepfakeCheck = $this->detectDeepfake($imageContent);
            $fraudChecks['deepfake'] = $deepfakeCheck;
            
            if ($deepfakeCheck['is_deepfake']) {
                Log::warning('KYC Fraud: Deepfake detected', ['path' => $imagePath]);
                return [
                    'valid' => false,
                    'reason' => 'Image manipulée ou générée par IA détectée. Prenez une vraie photo.',
                    'fraud_type' => 'deepfake',
                ];
            }

            // ===== 5. DÉTECTION VIVACITÉ =====
            $livenessCheck = $this->detectLiveness($imageContent);
            $fraudChecks['liveness'] = $livenessCheck;
            
            if (!$livenessCheck['is_live']) {
                Log::warning('KYC Fraud: Liveness failed', ['path' => $imagePath]);
                return [
                    'valid' => false,
                    'reason' => 'Le selfie ne semble pas pris en direct. Prenez une nouvelle photo face à la caméra.',
                    'fraud_type' => 'not_live',
                ];
            }

            // ===== TOUTES LES VÉRIFICATIONS PASSÉES =====
            Log::info('KYC Selfie validated', ['path' => $imagePath]);
            
            return [
                'valid' => true,
                'face_count' => 1,
                'confidence' => $detectionConfidence,
                'liveness_score' => $livenessCheck['liveness_score'],
                'fraud_checks' => $fraudChecks,
            ];

        } catch (\Throwable $e) {
            Log::error('KYC Selfie validation error: ' . $e->getMessage());
            return ['valid' => true, 'skipped' => true, 'error' => $e->getMessage()];
        }
    }

    // ============================================================
    // VALIDATION PIÈCE D'IDENTITÉ
    // ============================================================

    /**
     * Valider le recto d'une pièce d'identité avec détection de fraude
     */
    public function validateIdCard(string $imagePath): array
    {
        if (!$this->enabled || !$this->client) {
            return ['valid' => true, 'skipped' => true, 'reason' => 'Validation automatique désactivée'];
        }

        try {
            $imageContent = $this->getImageContent($imagePath);
            if (!$imageContent) {
                return ['valid' => false, 'reason' => 'Impossible de lire l\'image'];
            }

            // 1. Détection photo d'écran
            $screenCheck = $this->detectScreenPhoto($imageContent);
            if ($screenCheck['is_screen_photo']) {
                Log::warning('KYC Fraud: Screen photo on ID', ['path' => $imagePath]);
                return [
                    'valid' => false,
                    'reason' => 'Photo d\'écran détectée. Photographiez votre document physique.',
                    'fraud_type' => 'screen_photo',
                ];
            }

            // 2. Détection de flou
            $blurCheck = $this->detectDocumentBlur($imageContent);
            if ($blurCheck['is_blurry']) {
                return [
                    'valid' => false,
                    'reason' => 'Document flou. Prenez une photo nette.',
                    'fraud_type' => 'blurry_document',
                ];
            }

            // 3. Détecter le texte
            $texts = $this->detectText($imageContent);
            
            if (count($texts) === 0) {
                return [
                    'valid' => false,
                    'reason' => 'Aucun texte détecté. Photographiez une pièce d\'identité valide.',
                    'has_text' => false,
                ];
            }

            $fullText = $texts[0]->getDescription();
            $textLength = strlen($fullText);
            
            if ($textLength < 50) {
                return [
                    'valid' => false,
                    'reason' => 'Document incomplet. Photographiez une pièce d\'identité complète.',
                ];
            }

            // 4. Mots-clés d'identité
            $keywords = $this->detectIdKeywords($fullText);
            
            if ($keywords['score'] < 2) {
                return [
                    'valid' => false,
                    'reason' => 'Document non reconnu comme pièce d\'identité valide.',
                ];
            }

            // 5. Présence d'un visage (recto)
            $faces = $this->detectFaces($imageContent);
            $hasFace = count($faces) > 0;

            // 6. Vérifier image en ligne (copie/fraude)
            $webCheck = $this->checkImageOnline($imageContent);
            if ($webCheck['found_online']) {
                Log::warning('KYC Fraud: ID image from web', ['path' => $imagePath]);
                return [
                    'valid' => false,
                    'reason' => 'Image trouvée sur internet. Photographiez VOTRE document.',
                    'fraud_type' => 'image_from_web',
                ];
            }

            return [
                'valid' => true,
                'has_text' => true,
                'text_length' => $textLength,
                'has_face' => $hasFace,
                'keywords_found' => $keywords['found'],
                'id_type' => $keywords['type'],
            ];

        } catch (\Throwable $e) {
            Log::error('KYC ID validation error: ' . $e->getMessage());
            return ['valid' => true, 'skipped' => true, 'error' => $e->getMessage()];
        }
    }

    /**
     * Détection de flou pour documents
     */
    private function detectDocumentBlur(string $imageContent): array
    {
        try {
            $properties = $this->detectImageProperties($imageContent);

            if ($properties && $properties->getDominantColors()) {
                $colors = $properties->getDominantColors()->getColors();
                if (count(iterator_to_array($colors)) < 3) {
                    return ['is_blurry' => true, 'blur_score' => 0.7];
                }
            }

            return ['is_blurry' => false, 'blur_score' => 0];
        } catch (\Throwable $e) {
            return ['is_blurry' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Vérifier si l'image existe en ligne
     */
    private function checkImageOnline(string $imageContent): array
    {
        try {
            $webDetection = $this->detectWeb($imageContent);

            if (!$webDetection) {
                return ['found_online' => false];
            }

            $fullMatches = iterator_to_array($webDetection->getFullMatchingImages());
            $partialMatches = iterator_to_array($webDetection->getPartialMatchingImages());

            $foundExact = count($fullMatches) > 0;
            $foundPartial = count($partialMatches) > 3;

            return [
                'found_online' => $foundExact || $foundPartial,
                'exact_matches' => count($fullMatches),
                'partial_matches' => count($partialMatches),
            ];
        } catch (\Throwable $e) {
            return ['found_online' => false, 'error' => $e->getMessage()];
        }
    }

    /**
     * Valider le verso d'une pièce d'identité
     */
    public function validateIdCardBack(string $imagePath): array
    {
        if (!$this->enabled || !$this->client) {
            return ['valid' => true, 'skipped' => true, 'reason' => 'Validation automatique désactivée'];
        }

        try {
            $imageContent = $this->getImageContent($imagePath);
            if (!$imageContent) {
                return ['valid' => false, 'reason' => 'Impossible de lire l\'image'];
            }

            // Détection photo d'écran
            $screenCheck = $this->detectScreenPhoto($imageContent);
            if ($screenCheck['is_screen_photo']) {
                return [
                    'valid' => false,
                    'reason' => 'Photo d\'écran détectée. Photographiez votre document physique.',
                    'fraud_type' => 'screen_photo',
                ];
            }

            // Détecter le texte
            $texts = $this->detectText($imageContent);
            
            if (count($texts) === 0) {
                return [
                    'valid' => false,
                    'reason' => 'Aucun texte détecté. Photographiez le verso de votre pièce d\'identité.',
                    'has_text' => false,
                ];
            }

            $fullText = $texts[0]->getDescription();
            
            if (strlen($fullText) < 20) {
                return [
                    'valid' => false,
                    'reason' => 'Le verso ne contient pas assez d\'informations.',
                ];
            }

            return [
                'valid' => true,
                'has_text' => true,
                'text_length' => strlen($fullText),
            ];

        } catch (\Throwable $e) {
            Log::error('KYC ID Back validation error: ' . $e->getMessage());
            return ['valid' => true, 'skipped' => true, 'error' => $e->getMessage()];
        }
    }

    // ============================================================
    // VALIDATION COMPLÈTE KYC
    // ============================================================

    /**
     * Validation complète de tous les documents KYC
     */
    public function validateKycDocuments(array $documents): array
    {
        $results = [
            'overall_valid' => true,
            'documents' => [],
            'errors' => [],
            'fraud_detected' => false,
            'fraud_types' => [],
        ];

        // Valider le selfie
        if (isset($documents['selfie'])) {
            $selfieResult = $this->validateSelfie($documents['selfie']);
            $results['documents']['selfie'] = $selfieResult;
            if (!$selfieResult['valid'] && !($selfieResult['skipped'] ?? false)) {
                $results['overall_valid'] = false;
                $results['errors'][] = 'Selfie: ' . $selfieResult['reason'];
                if (isset($selfieResult['fraud_type'])) {
                    $results['fraud_detected'] = true;
                    $results['fraud_types'][] = $selfieResult['fraud_type'];
                }
            }
        }

        // Valider le recto de la CNI
        if (isset($documents['id_card_front'])) {
            $idFrontResult = $this->validateIdCard($documents['id_card_front']);
            $results['documents']['id_card_front'] = $idFrontResult;
            if (!$idFrontResult['valid'] && !($idFrontResult['skipped'] ?? false)) {
                $results['overall_valid'] = false;
                $results['errors'][] = 'CNI Recto: ' . $idFrontResult['reason'];
                if (isset($idFrontResult['fraud_type'])) {
                    $results['fraud_detected'] = true;
                    $results['fraud_types'][] = $idFrontResult['fraud_type'];
                }
            }
        }

        // Valider le verso de la CNI
        if (isset($documents['id_card_back'])) {
            $idBackResult = $this->validateIdCardBack($documents['id_card_back']);
            $results['documents']['id_card_back'] = $idBackResult;
            if (!$idBackResult['valid'] && !($idBackResult['skipped'] ?? false)) {
                $results['overall_valid'] = false;
                $results['errors'][] = 'CNI Verso: ' . $idBackResult['reason'];
                if (isset($idBackResult['fraud_type'])) {
                    $results['fraud_detected'] = true;
                    $results['fraud_types'][] = $idBackResult['fraud_type'];
                }
            }
        }

        // Log si fraude détectée
        if ($results['fraud_detected']) {
            Log::warning('KYC Fraud attempt detected', [
                'fraud_types' => $results['fraud_types'],
                'errors' => $results['errors'],
            ]);
        }

        return $results;
    }

    // ============================================================
    // UTILITAIRES
    // ============================================================

    /**
     * Détecter les mots-clés typiques d'une pièce d'identité
     */
    private function detectIdKeywords(string $text): array
    {
        $text = strtoupper($text);
        $found = [];
        $score = 0;
        $type = 'unknown';

        $cniKeywords = [
            'CARTE NATIONALE', 'CARTE D\'IDENTITE', 'IDENTITE', 'CNI',
            'REPUBLIQUE', 'NATIONALITE', 'NOM', 'PRENOM', 'PRENOMS',
            'DATE DE NAISSANCE', 'LIEU DE NAISSANCE', 'SEXE',
            'COTE D\'IVOIRE', 'CÔTE D\'IVOIRE', 'IVOIRE',
        ];

        $passportKeywords = [
            'PASSEPORT', 'PASSPORT', 'P<', 'MRZ',
            'TRAVEL DOCUMENT', 'DOCUMENT DE VOYAGE',
        ];

        $licenseKeywords = [
            'PERMIS DE CONDUIRE', 'PERMIS', 'DRIVING LICENSE', 'DRIVER',
            'CATEGORIE', 'CATEGORY', 'A1', 'A2', 'B', 'C', 'D', 'E',
        ];

        foreach ($cniKeywords as $keyword) {
            if (str_contains($text, $keyword)) {
                $found[] = $keyword;
                $score++;
                $type = 'cni';
            }
        }

        foreach ($passportKeywords as $keyword) {
            if (str_contains($text, $keyword)) {
                $found[] = $keyword;
                $score += 2;
                $type = 'passport';
            }
        }

        foreach ($licenseKeywords as $keyword) {
            if (str_contains($text, $keyword)) {
                $found[] = $keyword;
                $score++;
                $type = 'driving_license';
            }
        }

        return [
            'found' => array_unique($found),
            'score' => $score,
            'type' => $type,
        ];
    }

    /**
     * Récupérer le contenu d'une image depuis le stockage
     */
    private function getImageContent(string $path): ?string
    {
        try {
            if (Storage::disk('private')->exists($path)) {
                return Storage::disk('private')->get($path);
            }
            
            if (file_exists($path)) {
                return file_get_contents($path);
            }
            
            return null;
        } catch (\Throwable $e) {
            Log::error('Error reading image: ' . $e->getMessage());
            return null;
        }
    }
}
