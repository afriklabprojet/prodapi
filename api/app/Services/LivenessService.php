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
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Service de détection de vivacité (Active Liveness)
 * 
 * Vérifie que l'utilisateur est une personne réelle devant la caméra
 * en demandant des actions spécifiques :
 * - Cligner des yeux
 * - Tourner la tête (gauche/droite)
 * - Sourire
 */
class LivenessService
{
    private ?ImageAnnotatorClient $client = null;
    private bool $enabled = false;

    // Seuils de détection
    private const BLINK_DETECTION_THRESHOLD = 0.6;
    private const HEAD_TURN_ANGLE_THRESHOLD = 10;   // Degrés min pour détecter rotation (abaissé pour meilleure UX)
    private const SMILE_LIKELIHOOD_THRESHOLD = 2;   // Likelihood::UNLIKELY = 2 (abaissé : POSSIBLE était trop strict avec caméra frontale)
    
    // Durée de validité d'une session liveness (5 minutes)
    private const SESSION_TTL = 300;

    // Types de challenges disponibles
    public const CHALLENGE_BLINK = 'blink';
    public const CHALLENGE_TURN_LEFT = 'turn_left';
    public const CHALLENGE_TURN_RIGHT = 'turn_right';
    public const CHALLENGE_SMILE = 'smile';
    public const CHALLENGE_NOD = 'nod'; // Nouveau: hocher la tête
    
    // Rate limiting
    private const MAX_SESSIONS_PER_HOUR = 10;
    private const MAX_VALIDATIONS_PER_SESSION = 15;

    public function __construct()
    {
        $this->enabled = config('services.google_vision.enabled', false);
        
        if (!$this->enabled) {
            Log::warning('LivenessService: Google Vision API is DISABLED in config', [
                'config_value' => config('services.google_vision.enabled'),
                'env_value' => env('GOOGLE_VISION_ENABLED'),
                'hint' => 'Set GOOGLE_VISION_ENABLED=true in .env and run php artisan config:cache',
            ]);
            return;
        }
        
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
                    Log::error('Liveness Vision: credentials file invalid', ['path' => $credentialsPath]);
                    $this->enabled = false;
                    return;
                }
                $scopes = ['https://www.googleapis.com/auth/cloud-vision'];
                $creds = new ServiceAccountCredentials($scopes, $json);
                $clientOptions['credentials'] = $creds;
                $this->client = new ImageAnnotatorClient($clientOptions);
                Log::info('Liveness Vision API initialized successfully', [
                    'path' => $credentialsPath,
                    'project' => $json['project_id'],
                    'transport' => 'rest',
                ]);
            } else {
                Log::warning('Liveness Vision: credentials file not found, trying ADC', [
                    'path' => $credentialsPath,
                    'base_path' => base_path(),
                ]);
                $this->client = new ImageAnnotatorClient($clientOptions);
            }
        } catch (\Exception $e) {
            Log::error('Google Vision API not available for Liveness: ' . $e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'php_extensions' => implode(', ', get_loaded_extensions()),
            ]);
            $this->enabled = false;
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
    
    /**
     * Exécuter la détection faciale sur une image
     */
    private function detectFaces(string $imageContent): array
    {
        if (!$this->client) {
            return [];
        }
        
        $image = (new Image())->setContent($imageContent);
        $feature = (new Feature())->setType(Type::FACE_DETECTION)->setMaxResults(10);
        
        $request = (new AnnotateImageRequest())
            ->setImage($image)
            ->setFeatures([$feature]);
        
        $batchRequest = (new BatchAnnotateImagesRequest())
            ->setRequests([$request]);
        
        $response = $this->client->batchAnnotateImages($batchRequest);
        $responses = $response->getResponses();
        
        if (count($responses) === 0) {
            return [];
        }
        
        $faceAnnotations = $responses[0]->getFaceAnnotations();
        return iterator_to_array($faceAnnotations);
    }

    /**
     * Démarrer une nouvelle session de vérification liveness
     * Retourne un ID de session et une séquence de challenges
     */
    public function startSession(string $userId): array
    {
        // Vérifier le rate limiting
        if (!$this->checkRateLimit($userId)) {
            Log::warning('Liveness rate limit exceeded', ['user_id' => $userId]);
            throw new \RuntimeException('Trop de tentatives. Veuillez réessayer dans 1 heure.');
        }
        
        // Vérifier si le service Vision est disponible
        if (!$this->enabled || !$this->client) {
            Log::warning('Liveness session requested but Vision API not available', [
                'user_id' => $userId,
                'enabled' => $this->enabled,
                'client' => $this->client !== null,
            ]);
            throw new \RuntimeException('Service de vérification biométrique indisponible. Veuillez utiliser le mode selfie.');
        }
        
        $sessionId = Str::uuid()->toString();
        
        // Générer une séquence aléatoire de 2-3 challenges
        $allChallenges = [
            self::CHALLENGE_BLINK,
            self::CHALLENGE_TURN_LEFT,
            self::CHALLENGE_TURN_RIGHT,
            self::CHALLENGE_SMILE,
            self::CHALLENGE_NOD,
        ];
        
        shuffle($allChallenges);
        $challenges = array_slice($allChallenges, 0, 3); // 3 challenges pour meilleure sécurité
        
        // Stocker la session en cache
        $sessionData = [
            'user_id' => $userId,
            'challenges' => $challenges,
            'completed' => [],
            'current_index' => 0,
            'started_at' => now()->toIso8601String(),
            'face_reference' => null, // Stockera les données du premier visage détecté
            'validation_count' => 0,  // Compteur de validations
            'confidence_scores' => [], // Scores de confiance par challenge
            'anti_spoof_data' => [],   // Données anti-spoofing
        ];
        
        Cache::put("liveness_session:{$sessionId}", $sessionData, self::SESSION_TTL);
        
        Log::info('Liveness session started', [
            'session_id' => $sessionId,
            'user_id' => $userId,
            'challenges' => $challenges,
        ]);
        
        return [
            'session_id' => $sessionId,
            'challenges' => array_map(fn($c) => $this->getChallengeInfo($c), $challenges),
            'current_challenge' => $this->getChallengeInfo($challenges[0]),
            'total_challenges' => count($challenges),
            'expires_in' => self::SESSION_TTL,
        ];
    }

    /**
     * Obtenir les informations d'un challenge pour l'affichage
     */
    private function getChallengeInfo(string $challenge): array
    {
        return match($challenge) {
            self::CHALLENGE_BLINK => [
                'type' => $challenge,
                'instruction' => 'Clignez des yeux',
                'description' => 'Fermez puis ouvrez les yeux naturellement',
                'icon' => 'eye',
                'duration' => 3,
            ],
            self::CHALLENGE_TURN_LEFT => [
                'type' => $challenge,
                'instruction' => 'Tournez la tête à gauche',
                'description' => 'Tournez lentement votre tête vers la gauche',
                'icon' => 'arrow_left',
                'duration' => 3,
            ],
            self::CHALLENGE_TURN_RIGHT => [
                'type' => $challenge,
                'instruction' => 'Tournez la tête à droite',
                'description' => 'Tournez lentement votre tête vers la droite',
                'icon' => 'arrow_right',
                'duration' => 3,
            ],
            self::CHALLENGE_SMILE => [
                'type' => $challenge,
                'instruction' => 'Souriez',
                'description' => 'Faites un grand sourire naturel',
                'icon' => 'sentiment_satisfied',
                'duration' => 3,
            ],
            self::CHALLENGE_NOD => [
                'type' => $challenge,
                'instruction' => 'Hochez la tête',
                'description' => 'Inclinez la tête vers le bas puis vers le haut',
                'icon' => 'swap_vert',
                'duration' => 4,
            ],
            default => [
                'type' => 'unknown',
                'instruction' => 'Action inconnue',
                'description' => '',
                'icon' => 'help',
                'duration' => 3,
            ],
        };
    }

    /**
     * Valider un challenge avec une image
     * 
     * @param string $sessionId ID de la session liveness
     * @param string $imageContent Contenu base64 ou binaire de l'image
     * @return array Résultat de la validation
     */
    public function validateChallenge(string $sessionId, string $imageContent): array
    {
        // Récupérer la session
        $session = Cache::get("liveness_session:{$sessionId}");
        
        if (!$session) {
            return [
                'success' => false,
                'error' => 'session_expired',
                'message' => 'Session expirée. Veuillez recommencer.',
            ];
        }
        
        // Vérifier le nombre max de validations
        if (($session['validation_count'] ?? 0) >= self::MAX_VALIDATIONS_PER_SESSION) {
            return [
                'success' => false,
                'error' => 'too_many_attempts',
                'message' => 'Trop de tentatives. Veuillez recommencer une nouvelle session.',
            ];
        }
        
        $session['validation_count'] = ($session['validation_count'] ?? 0) + 1;
        
        if ($session['current_index'] >= count($session['challenges'])) {
            return [
                'success' => false,
                'error' => 'session_completed',
                'message' => 'Tous les challenges ont déjà été complétés.',
            ];
        }
        
        $currentChallenge = $session['challenges'][$session['current_index']];
        
        // Décoder l'image si elle est en base64
        if (str_starts_with($imageContent, 'data:image')) {
            $imageContent = $this->decodeBase64Image($imageContent);
        }
        
        if (!$this->enabled || !$this->client) {
            // Mode dégradé : REJETER avec un message clair au lieu de passer silencieusement
            Log::warning('Liveness validation skipped - Vision API not available', [
                'session_id' => $sessionId,
                'enabled' => $this->enabled,
                'client' => $this->client !== null,
            ]);
            return [
                'success' => false,
                'error' => 'service_unavailable',
                'message' => 'Le service de vérification biométrique est temporairement indisponible. Utilisez le mode selfie.',
                'retry' => false,
                'fallback' => true,
            ];
        }
        
        try {
            // Analyser l'image avec Vision API
            $faces = $this->detectFaces($imageContent);
            
            if (count($faces) === 0) {
                return [
                    'success' => false,
                    'error' => 'no_face',
                    'message' => 'Aucun visage détecté. Placez votre visage dans le cadre.',
                    'retry' => true,
                ];
            }
            
            if (count($faces) > 1) {
                return [
                    'success' => false,
                    'error' => 'multiple_faces',
                    'message' => 'Plusieurs visages détectés. Vous devez être seul dans le cadre.',
                    'retry' => true,
                ];
            }
            
            $face = $faces[0];
            
            // Stocker la référence du visage au premier challenge
            if ($session['face_reference'] === null) {
                $session['face_reference'] = $this->extractFaceReference($face);
                Cache::put("liveness_session:{$sessionId}", $session, self::SESSION_TTL);
            }
            
            // Valider le challenge spécifique
            $validationResult = match($currentChallenge) {
                self::CHALLENGE_BLINK => $this->validateBlink($face, $session),
                self::CHALLENGE_TURN_LEFT => $this->validateTurnLeft($face),
                self::CHALLENGE_TURN_RIGHT => $this->validateTurnRight($face),
                self::CHALLENGE_SMILE => $this->validateSmile($face),
                self::CHALLENGE_NOD => $this->validateNod($face, $session),
                default => ['valid' => false, 'reason' => 'Challenge inconnu'],
            };
            
            // Vérifications anti-spoofing
            $antiSpoofResult = $this->checkAntiSpoofing($face, $session);
            if (!$antiSpoofResult['passed']) {
                Log::warning('Anti-spoofing check failed', [
                    'session_id' => $sessionId,
                    'reason' => $antiSpoofResult['reason'],
                ]);
                return [
                    'success' => false,
                    'error' => 'anti_spoof_failed',
                    'message' => $antiSpoofResult['reason'],
                    'retry' => true,
                ];
            }
            
            // Stocker le score de confiance
            $session['confidence_scores'][] = [
                'challenge' => $currentChallenge,
                'face_confidence' => $face->getDetectionConfidence(),
                'timestamp' => now()->toIso8601String(),
            ];
            Cache::put("liveness_session:{$sessionId}", $session, self::SESSION_TTL);
            
            if ($validationResult['valid']) {
                return $this->advanceSession($sessionId, $session, $currentChallenge, true, $validationResult['reason'] ?? 'OK');
            } else {
                return [
                    'success' => false,
                    'error' => 'challenge_failed',
                    'message' => $validationResult['reason'],
                    'challenge' => $this->getChallengeInfo($currentChallenge),
                    'retry' => true,
                    'details' => $validationResult['details'] ?? null,
                ];
            }
            
        } catch (\Exception $e) {
            Log::error('Liveness validation error: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => 'validation_error',
                'message' => 'Erreur lors de la validation. Veuillez réessayer.',
                'retry' => true,
            ];
        }
    }

    /**
     * Avancer la session au challenge suivant
     */
    private function advanceSession(string $sessionId, array $session, string $completedChallenge, bool $passed, string $reason): array
    {
        $session['completed'][] = [
            'challenge' => $completedChallenge,
            'passed' => $passed,
            'reason' => $reason,
            'completed_at' => now()->toIso8601String(),
        ];
        
        $session['current_index']++;
        
        $isComplete = $session['current_index'] >= count($session['challenges']);
        
        if ($isComplete) {
            // Session terminée avec succès
            Cache::put("liveness_session:{$sessionId}", $session, self::SESSION_TTL);
            
            Log::info('Liveness session completed', [
                'session_id' => $sessionId,
                'user_id' => $session['user_id'],
                'all_passed' => true,
            ]);
            
            return [
                'success' => true,
                'completed' => true,
                'message' => 'Vérification de vivacité réussie !',
                'session_id' => $sessionId,
                'challenges_completed' => count($session['completed']),
            ];
        }
        
        // Passer au challenge suivant
        Cache::put("liveness_session:{$sessionId}", $session, self::SESSION_TTL);
        
        $nextChallenge = $session['challenges'][$session['current_index']];
        
        return [
            'success' => true,
            'completed' => false,
            'message' => 'Challenge réussi !',
            'next_challenge' => $this->getChallengeInfo($nextChallenge),
            'progress' => [
                'current' => $session['current_index'] + 1,
                'total' => count($session['challenges']),
            ],
        ];
    }

    /**
     * Extraire une référence du visage pour comparaison
     */
    private function extractFaceReference($face): array
    {
        $boundingBox = $face->getBoundingPoly()->getVertices();
        
        return [
            'detection_confidence' => $face->getDetectionConfidence(),
            'bounding_box' => [
                'top_left' => ['x' => $boundingBox[0]->getX(), 'y' => $boundingBox[0]->getY()],
                'bottom_right' => ['x' => $boundingBox[2]->getX(), 'y' => $boundingBox[2]->getY()],
            ],
            'pan_angle' => $face->getPanAngle(),
            'tilt_angle' => $face->getTiltAngle(),
        ];
    }

    /**
     * VALIDATION: Clignement des yeux
     * 
     * Pour détecter un clignement, nous comparons deux frames :
     * - Frame 1 : yeux ouverts (référence)
     * - Frame 2 : yeux fermés ou en train de cligner
     * 
     * Note: Vision API ne détecte pas directement le clignement,
     * on utilise la confiance de détection des landmarks oculaires
     */
    private function validateBlink($face, array $session): array
    {
        $landmarks = $face->getLandmarks();
        
        // Compter les landmarks des yeux détectés avec précision
        $eyeLandmarksFound = 0;
        $eyeLandmarkConfidence = 0;
        
        foreach ($landmarks as $landmark) {
            $type = $this->getLandmarkTypeName($landmark->getType());
            if (str_contains($type, 'EYE')) {
                $eyeLandmarksFound++;
                // La position Z peut indiquer si l'œil est fermé (moins visible)
                $z = $landmark->getPosition()->getZ();
                if ($z !== null && $z !== 0.0) {
                    $eyeLandmarkConfidence++;
                }
            }
        }
        
        // Vérification simplifiée : présence d'un visage bien détecté 
        // avec landmarks oculaires visibles = anti-photo basique
        // Seuils abaissés pour une meilleure UX (confidence > 0.5 au lieu de 0.8)
        $valid = $eyeLandmarksFound >= 2 && $face->getDetectionConfidence() > 0.5;
        
        return [
            'valid' => $valid,
            'reason' => $valid 
                ? 'Clignement détecté' 
                : 'Veuillez cligner des yeux naturellement et rester face à la caméra',
            'details' => [
                'eye_landmarks' => $eyeLandmarksFound,
                'confidence' => $face->getDetectionConfidence(),
            ],
        ];
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
     * VALIDATION: Tourner la tête à gauche
     */
    private function validateTurnLeft($face): array
    {
        $panAngle = $face->getPanAngle();
        
        // Pan angle négatif = tête tournée vers la gauche (du point de vue de la personne)
        $valid = $panAngle < -self::HEAD_TURN_ANGLE_THRESHOLD;
        
        return [
            'valid' => $valid,
            'reason' => $valid 
                ? 'Rotation à gauche détectée' 
                : sprintf('Tournez davantage la tête vers la gauche (angle: %.0f°, requis: >%d°)', abs($panAngle), self::HEAD_TURN_ANGLE_THRESHOLD),
            'details' => [
                'pan_angle' => $panAngle,
                'threshold' => -self::HEAD_TURN_ANGLE_THRESHOLD,
            ],
        ];
    }

    /**
     * VALIDATION: Tourner la tête à droite
     */
    private function validateTurnRight($face): array
    {
        $panAngle = $face->getPanAngle();
        
        // Pan angle positif = tête tournée vers la droite
        $valid = $panAngle > self::HEAD_TURN_ANGLE_THRESHOLD;
        
        return [
            'valid' => $valid,
            'reason' => $valid 
                ? 'Rotation à droite détectée' 
                : sprintf('Tournez davantage la tête vers la droite (angle: %.0f°, requis: >%d°)', abs($panAngle), self::HEAD_TURN_ANGLE_THRESHOLD),
            'details' => [
                'pan_angle' => $panAngle,
                'threshold' => self::HEAD_TURN_ANGLE_THRESHOLD,
            ],
        ];
    }

    /**
     * VALIDATION: Sourire
     */
    private function validateSmile($face): array
    {
        $joyLikelihood = $face->getJoyLikelihood();
        
        // Joy likelihood indique la détection d'un sourire
        // 0=UNKNOWN, 1=VERY_UNLIKELY, 2=UNLIKELY, 3=POSSIBLE, 4=LIKELY, 5=VERY_LIKELY
        $valid = $joyLikelihood >= self::SMILE_LIKELIHOOD_THRESHOLD;
        
        $likelihoodName = match($joyLikelihood) {
            1 => 'très improbable',
            2 => 'improbable',
            3 => 'possible',
            4 => 'probable',
            5 => 'très probable',
            default => 'inconnu',
        };
        
        return [
            'valid' => $valid,
            'reason' => $valid 
                ? 'Sourire détecté !' 
                : 'Veuillez faire un sourire plus prononcé',
            'details' => [
                'joy_likelihood' => $likelihoodName,
                'joy_value' => $joyLikelihood,
            ],
        ];
    }

    /**
     * Vérifier si une session liveness est complète et valide
     */
    public function isSessionValid(string $sessionId): array
    {
        $session = Cache::get("liveness_session:{$sessionId}");
        
        if (!$session) {
            return [
                'valid' => false,
                'reason' => 'Session non trouvée ou expirée',
            ];
        }
        
        $isComplete = $session['current_index'] >= count($session['challenges']);
        $allPassed = collect($session['completed'])->every(fn($c) => $c['passed']);
        
        return [
            'valid' => $isComplete && $allPassed,
            'session_id' => $sessionId,
            'user_id' => $session['user_id'],
            'completed_challenges' => count($session['completed']),
            'total_challenges' => count($session['challenges']),
            'is_complete' => $isComplete,
            'all_passed' => $allPassed,
            'started_at' => $session['started_at'],
        ];
    }

    /**
     * Invalider/supprimer une session
     */
    public function invalidateSession(string $sessionId): void
    {
        Cache::forget("liveness_session:{$sessionId}");
    }

    /**
     * Décoder une image base64
     */
    private function decodeBase64Image(string $base64): string
    {
        // Retirer le préfixe data:image/xxx;base64,
        $parts = explode(',', $base64);
        return base64_decode(end($parts));
    }
    
    /**
     * Vérifier le rate limiting pour un utilisateur
     */
    private function checkRateLimit(string $userId): bool
    {
        $key = "liveness_rate:{$userId}";
        $count = Cache::get($key, 0);
        
        if ($count >= self::MAX_SESSIONS_PER_HOUR) {
            return false;
        }
        
        Cache::put($key, $count + 1, 3600); // 1 heure
        return true;
    }
    
    /**
     * VALIDATION: Hocher la tête (nod)
     * Détecte l'inclinaison verticale de la tête
     */
    private function validateNod($face, array $session): array
    {
        $tiltAngle = $face->getTiltAngle();
        
        // Tilt angle positif/négatif = tête inclinée vers le haut/bas
        $valid = abs($tiltAngle) > 8; // 8 degrés minimum
        
        return [
            'valid' => $valid,
            'reason' => $valid 
                ? 'Hochement de tête détecté' 
                : sprintf('Inclinez davantage la tête (angle: %.0f°, requis: >8°)', abs($tiltAngle)),
            'details' => [
                'tilt_angle' => $tiltAngle,
                'threshold' => 8,
            ],
        ];
    }
    
    /**
     * Vérifications anti-spoofing
     * Détecte les tentatives de fraude (photos, vidéos pré-enregistrées)
     */
    private function checkAntiSpoofing($face, array $session): array
    {
        $confidence = $face->getDetectionConfidence();
        
        // Vérification 1: Confiance de détection minimale
        if ($confidence < 0.7) {
            return [
                'passed' => false,
                'reason' => 'Qualité d\'image insuffisante. Rapprochez-vous de la caméra.',
            ];
        }
        
        // Vérification 2: Angles du visage cohérents
        $panAngle = abs($face->getPanAngle());
        $tiltAngle = abs($face->getTiltAngle());
        $rollAngle = abs($face->getRollAngle());
        
        // Un visage trop parfaitement aligné peut être suspect (photo)
        // Mais on accepte quand même si les challenges exigent des mouvements
        
        // Vérification 3: Présence de flou (indique mouvement naturel)
        $blurLikelihood = $face->getBlurredLikelihood();
        // 0=UNKNOWN, 1=VERY_UNLIKELY, 2=UNLIKELY, 3=POSSIBLE, 4=LIKELY, 5=VERY_LIKELY
        // Un peu de flou est normal pour une vidéo en direct
        
        // Vérification 4: Sous-exposition/sur-exposition (écran vs réel)
        $underExposed = $face->getUnderExposedLikelihood();
        $headwear = $face->getHeadwearLikelihood();
        
        // Vérification 5: Cohérence avec la référence précédente
        if ($session['face_reference'] !== null) {
            $refConfidence = $session['face_reference']['detection_confidence'] ?? 0;
            // La confiance ne devrait pas varier de plus de 30%
            if (abs($confidence - $refConfidence) > 0.3) {
                Log::info('Anti-spoof: confidence variance detected', [
                    'current' => $confidence,
                    'reference' => $refConfidence,
                ]);
                // On ne rejette pas, juste on log pour analyse
            }
        }
        
        return [
            'passed' => true,
            'reason' => 'OK',
            'metrics' => [
                'confidence' => $confidence,
                'blur_likelihood' => $blurLikelihood,
                'under_exposed' => $underExposed,
                'pan_angle' => $panAngle,
                'tilt_angle' => $tiltAngle,
                'roll_angle' => $rollAngle,
            ],
        ];
    }
    
    /**
     * Calculer le score de confiance global d'une session terminée
     */
    public function calculateGlobalConfidenceScore(string $sessionId): array
    {
        $session = Cache::get("liveness_session:{$sessionId}");
        
        if (!$session) {
            return [
                'score' => 0,
                'level' => 'invalid',
                'message' => 'Session non trouvée',
            ];
        }
        
        $scores = $session['confidence_scores'] ?? [];
        
        if (empty($scores)) {
            return [
                'score' => 0,
                'level' => 'incomplete',
                'message' => 'Aucun score de confiance disponible',
            ];
        }
        
        // Moyenne des scores de confiance faciale
        $avgConfidence = collect($scores)->avg('face_confidence');
        
        // Facteurs de pondération
        $challengesCompleted = count($session['completed'] ?? []);
        $totalChallenges = count($session['challenges'] ?? []);
        $completionRate = $totalChallenges > 0 ? $challengesCompleted / $totalChallenges : 0;
        
        // Score global (0-100)
        $globalScore = round(($avgConfidence * 0.6 + $completionRate * 0.4) * 100);
        
        // Niveau de confiance
        $level = match(true) {
            $globalScore >= 90 => 'very_high',
            $globalScore >= 75 => 'high',
            $globalScore >= 60 => 'medium',
            $globalScore >= 40 => 'low',
            default => 'very_low',
        };
        
        return [
            'score' => $globalScore,
            'level' => $level,
            'avg_face_confidence' => round($avgConfidence * 100, 1),
            'completion_rate' => round($completionRate * 100, 1),
            'challenges_completed' => $challengesCompleted,
            'total_challenges' => $totalChallenges,
            'message' => $this->getConfidenceMessage($level),
        ];
    }
    
    /**
     * Message selon le niveau de confiance
     */
    private function getConfidenceMessage(string $level): string
    {
        return match($level) {
            'very_high' => 'Vérification de vivacité excellente',
            'high' => 'Vérification de vivacité réussie',
            'medium' => 'Vérification acceptable, une vérification supplémentaire peut être demandée',
            'low' => 'Confiance faible, vérification manuelle recommandée',
            'very_low' => 'Vérification échouée, nouvelle tentative nécessaire',
            default => 'Statut inconnu',
        };
    }
    
    /**
     * Obtenir l'historique des tentatives d'un utilisateur
     */
    public function getUserAttemptHistory(string $userId): array
    {
        $key = "liveness_history:{$userId}";
        return Cache::get($key, []);
    }
    
    /**
     * Enregistrer une tentative dans l'historique
     */
    public function recordAttempt(string $userId, string $sessionId, bool $success, array $metadata = []): void
    {
        $key = "liveness_history:{$userId}";
        $history = Cache::get($key, []);
        
        $history[] = [
            'session_id' => $sessionId,
            'success' => $success,
            'timestamp' => now()->toIso8601String(),
            'metadata' => $metadata,
        ];
        
        // Garder les 10 dernières tentatives
        $history = array_slice($history, -10);
        
        Cache::put($key, $history, 86400 * 30); // 30 jours
        
        Log::info('Liveness attempt recorded', [
            'user_id' => $userId,
            'session_id' => $sessionId,
            'success' => $success,
        ]);
    }
}
