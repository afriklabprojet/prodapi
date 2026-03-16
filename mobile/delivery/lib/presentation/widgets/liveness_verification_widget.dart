import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/responsive.dart';

/// Widget de vérification de vivacité (Active Liveness)
///
/// Fonctionnalités :
/// - Challenges interactifs (cligner, tourner, sourire)
/// - Retry automatique avec exponential backoff (3 tentatives)
/// - Mode dégradé : selfie simple si le service est indisponible
/// - Validation qualité image avant envoi (luminosité, taille)
/// - Messages d'erreur UX en français
class LivenessVerificationWidget extends StatefulWidget {
  final String apiBaseUrl;
  final String? authToken;
  final Function(String sessionId) onVerificationComplete;
  final Function(String error) onVerificationFailed;

  /// Callback quand le mode dégradé capture un selfie simple (service offline)
  final Function(Uint8List imageBytes)? onFallbackSelfie;
  final VoidCallback? onCancel;

  const LivenessVerificationWidget({
    super.key,
    required this.apiBaseUrl,
    this.authToken,
    required this.onVerificationComplete,
    required this.onVerificationFailed,
    this.onFallbackSelfie,
    this.onCancel,
  });

  @override
  State<LivenessVerificationWidget> createState() =>
      _LivenessVerificationWidgetState();
}

class _LivenessVerificationWidgetState
    extends State<LivenessVerificationWidget> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  // Dio client partagé
  late final Dio _dio;

  // Session liveness
  String? _sessionId;
  Map<String, dynamic>? _currentChallenge;
  int _currentIndex = 0;
  int _totalChallenges = 0;

  // État
  LivenessState _state = LivenessState.initializing;
  String _statusMessage = 'Initialisation...';

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Timer pour capture automatique
  Timer? _captureTimer;
  int _captureCountdown = 3;

  // Retry avec exponential backoff
  int _sessionRetryCount = 0;
  static const int _maxSessionRetries = 3;
  static const List<int> _backoffDelays = [2, 4, 8]; // secondes

  // Retry par challenge (max avant fallback)
  int _challengeRetryCount = 0;
  static const int _maxChallengeRetries = 3;

  // Mode dégradé (fallback selfie)
  bool _isFallbackMode = false;
  bool _showFallbackOption = false;

  // Qualité image
  String? _imageQualityWarning;

  @override
  void initState() {
    super.initState();
    _initDio();
    _initAnimation();
    _initCamera();
  }

  // ============================================================
  //  INITIALISATION
  // ============================================================

  void _initDio() {
    _dio = Dio(BaseOptions(
      baseUrl: widget.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (widget.authToken != null)
          'Authorization': 'Bearer ${widget.authToken}',
      },
      validateStatus: (status) => status != null && status < 500,
    ));
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // base64 images are huge
        responseBody: true,
        logPrint: (o) => debugPrint('[Liveness] $o'),
      ));
    }
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startLivenessSession();
      }
    } catch (e) {
      _log('Camera init error: $e');
      setState(() {
        _state = LivenessState.error;
        _statusMessage =
            'Impossible d\'accéder à la caméra.\nVérifiez les permissions.';
      });
    }
  }

  // ============================================================
  //  SESSION LIVENESS (avec exponential backoff)
  // ============================================================

  Future<void> _startLivenessSession() async {
    setState(() {
      _state = LivenessState.starting;
      _isFallbackMode = false;
      _showFallbackOption = false;
      _imageQualityWarning = null;
      if (_sessionRetryCount > 0) {
        _statusMessage =
            'Tentative ${_sessionRetryCount + 1}/$_maxSessionRetries...';
      } else {
        _statusMessage = 'Connexion au service de vérification...';
      }
    });

    try {
      final response = await _dio.post(ApiConstants.livenessStart);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        if (data['success'] == true) {
          _sessionRetryCount = 0;
          _challengeRetryCount = 0;
          setState(() {
            _sessionId = data['data']['session_id'];
            _currentChallenge = data['data']['current_challenge'];
            _totalChallenges = data['data']['total_challenges'];
            _currentIndex = 0;
            _state = LivenessState.ready;
            _statusMessage = 'Placez votre visage dans le cadre';
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startChallenge();
          });
          return;
        } else {
          throw _LivenessApiException(
            data['message'] ?? 'Erreur inconnue',
            response.statusCode,
          );
        }
      } else if (response.statusCode == 503) {
        // Service Vision API indisponible → basculer en mode selfie directement
        _log('Vision API unavailable (503), switching to fallback selfie mode');
        final data = _tryParseResponse(response);
        final hasFallback = data?['fallback'] == true;
        if (hasFallback && widget.onFallbackSelfie != null) {
          setState(() {
            _state = LivenessState.serviceUnavailable;
            _isFallbackMode = true;
            _showFallbackOption = true;
            _statusMessage =
                data?['message'] ?? 'Service de vérification indisponible. Utilisez le mode selfie.';
          });
          return;
        }
        throw _LivenessApiException(
          data?['message'] ?? 'Service temporairement indisponible',
          503,
        );
      } else {
        throw _LivenessApiException(
          'Erreur HTTP ${response.statusCode}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      _log('DioException: ${e.type} - ${e.message}');
      await _handleSessionRetry(_classifyDioError(e));
    } on _LivenessApiException catch (e) {
      _log('API Error: ${e.message} (${e.statusCode})');
      await _handleSessionRetry(e.message);
    } catch (e) {
      _log('Unexpected error: $e');
      await _handleSessionRetry('Une erreur inattendue est survenue.');
    }
  }

  /// Gère le retry avec exponential backoff ou bascule en mode dégradé
  Future<void> _handleSessionRetry(String errorMessage) async {
    if (_sessionRetryCount < _maxSessionRetries - 1) {
      _sessionRetryCount++;
      final delay = _backoffDelays[_sessionRetryCount - 1];
      _log('Retry $_sessionRetryCount/$_maxSessionRetries in ${delay}s');

      setState(() {
        _state = LivenessState.starting;
        _statusMessage = 'Nouvelle tentative dans ${delay}s...';
      });

      // Countdown visuel
      for (int i = delay; i > 0; i--) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Nouvelle tentative dans ${i - 1}s...';
        });
      }

      if (mounted) _startLivenessSession();
    } else {
      // Toutes les tentatives épuisées → proposer le mode dégradé
      _log('All retries exhausted, offering fallback mode');
      setState(() {
        _state = LivenessState.serviceUnavailable;
        _showFallbackOption = widget.onFallbackSelfie != null;
        _statusMessage = errorMessage;
      });
    }
  }

  /// Classifie une DioException en message français
  String _classifyDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La connexion a expiré.\nVérifiez votre connexion internet.';
      case DioExceptionType.connectionError:
        return 'Serveur injoignable.\nVérifiez votre connexion internet.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 404) return 'Service de vérification non disponible.';
        if (code == 429) {
          return 'Trop de tentatives.\nPatientez quelques minutes.';
        }
        if (code >= 500) return 'Le serveur rencontre un problème.';
        return 'Erreur de communication (code $code).';
      case DioExceptionType.cancel:
        return 'Requête annulée.';
      default:
        return 'Erreur de connexion inattendue.';
    }
  }

  // ============================================================
  //  CHALLENGES LIVENESS
  // ============================================================

  void _startChallenge() {
    if (_currentChallenge == null) {
      _log('_startChallenge called with null challenge');
      setState(() {
        _state = LivenessState.error;
        _statusMessage = 'Erreur de chargement du challenge. Veuillez recommencer.';
      });
      return;
    }

    setState(() {
      _state = LivenessState.challenge;
      _captureCountdown = (_currentChallenge!['duration'] ?? 3) + 1; // +1s pour laisser le temps de se préparer
      _imageQualityWarning = null;
    });

    _captureTimer?.cancel();
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_captureCountdown > 0) {
        setState(() => _captureCountdown--);
      } else {
        timer.cancel();
        _captureAndValidate();
      }
    });
  }

  Future<void> _captureAndValidate() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    // Sécurité : annuler le timer s'il tourne encore (capture manuelle)
    _captureTimer?.cancel();

    setState(() {
      _isProcessing = true;
      _state = LivenessState.validating;
      _statusMessage = 'Analyse en cours...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Validation qualité image (compte aussi comme retry)
      final qualityCheck = _validateImageQuality(bytes);
      if (!qualityCheck.isValid) {
        _challengeRetryCount++;
        if (_challengeRetryCount >= _maxChallengeRetries) {
          _log('Max retries reached on image quality');
          setState(() {
            _state = LivenessState.serviceUnavailable;
            _showFallbackOption = widget.onFallbackSelfie != null;
            _statusMessage =
                'Qualité d\'image insuffisante après $_maxChallengeRetries tentatives.\n${qualityCheck.warning}\nEssayez le mode selfie.';
          });
          return;
        }
        setState(() {
          _state = LivenessState.retry;
          _imageQualityWarning = qualityCheck.warning;
          _statusMessage = qualityCheck.warning!;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _startChallenge();
        });
        return;
      }

      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await _dio.post(
        ApiConstants.livenessValidate,
        data: {
          'session_id': _sessionId,
          'image': base64Image,
        },
      );

      // ── Gestion HTTP 4xx (backend retourne 400 pour success=false) ──
      if (response.statusCode != null && response.statusCode! >= 400) {
        final data = _tryParseResponse(response);

        // 410 → session expirée
        if (response.statusCode == 410) {
          setState(() {
            _state = LivenessState.error;
            _statusMessage = 'Session expirée. Veuillez recommencer.';
          });
          return;
        }

        // Backend propose un fallback selfie (Vision API indispo pendant validation)
        if (data != null && data['fallback'] == true && widget.onFallbackSelfie != null) {
          _log('Validation fallback requested by backend');
          setState(() {
            _state = LivenessState.serviceUnavailable;
            _isFallbackMode = true;
            _showFallbackOption = true;
            _statusMessage = data['message'] ?? 'Service indisponible. Utilisez le mode selfie.';
          });
          return;
        }

        // Challenge échoué avec possibilité de retry (no_face, challenge_failed, etc.)
        if (data != null && data['retry'] == true) {
          _challengeRetryCount++;
          if (_challengeRetryCount >= _maxChallengeRetries) {
            _log('Max challenge retries reached ($_maxChallengeRetries)');
            setState(() {
              _state = LivenessState.serviceUnavailable;
              _showFallbackOption = widget.onFallbackSelfie != null;
              _statusMessage =
                  'Vérification difficile après $_maxChallengeRetries tentatives.\nEssayez le mode selfie ou recommencez.';
            });
            return;
          }
          setState(() {
            _state = LivenessState.retry;
            _statusMessage = data['message'] ?? 'Veuillez réessayer';
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startChallenge();
          });
          return;
        }

        // Erreur non-retryable (422 validation, etc.)
        setState(() {
          _state = LivenessState.error;
          _statusMessage =
              data?['message'] ?? 'Erreur serveur. Veuillez recommencer.';
        });
        return;
      }

      // ── Gestion HTTP 200 (challenge réussi) ──
      final data = _parseResponse(response);

      if (data['success'] == true) {
        if (data['completed'] == true) {
          // Tous les challenges passés !
          setState(() {
            _state = LivenessState.success;
            _statusMessage = data['message'] ?? 'Vérification réussie !';
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) widget.onVerificationComplete(_sessionId!);
          });
        } else if (data['next_challenge'] != null) {
          // Challenge réussi → passer au suivant (reset retry counter)
          _challengeRetryCount = 0;
          setState(() {
            _currentChallenge = data['next_challenge'];
            _currentIndex =
                (data['progress']?['current'] ?? _currentIndex + 1) - 1;
            _state = LivenessState.ready;
            _statusMessage = 'Bien ! Préparation du suivant...';
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) _startChallenge();
          });
        } else {
          // Réponse inattendue : success mais pas de next_challenge et pas completed
          _log('Unexpected response: success=true but no next_challenge and completed=false');
          setState(() {
            _state = LivenessState.error;
            _statusMessage = 'Réponse serveur inattendue. Veuillez recommencer.';
          });
        }
      } else {
        // Sécurité : si le backend renvoie success=false en 200 (ne devrait pas arriver)
        _log('Unexpected: success=false with HTTP 200');
        final message = data['message'] as String? ?? 'Vérification échouée';
        if (data['fallback'] == true && widget.onFallbackSelfie != null) {
          setState(() {
            _state = LivenessState.serviceUnavailable;
            _isFallbackMode = true;
            _showFallbackOption = true;
            _statusMessage = message;
          });
        } else {
          setState(() {
            _state = LivenessState.error;
            _statusMessage = message;
          });
        }
      }
    } on DioException catch (e) {
      _log('Validate DioException: ${e.type}');
      setState(() {
        _state = LivenessState.error;
        _statusMessage = _classifyDioError(e);
      });
    } catch (e) {
      _log('Validate error: $e');
      setState(() {
        _state = LivenessState.error;
        _statusMessage = 'Erreur lors de la capture.\nVeuillez réessayer.';
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ============================================================
  //  MODE DÉGRADÉ : SELFIE SIMPLE
  // ============================================================

  Future<void> _captureFallbackSelfie() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _isFallbackMode = true;
      _state = LivenessState.validating;
      _statusMessage = 'Capture du selfie...';
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Validation qualité
      final qualityCheck = _validateImageQuality(bytes);
      if (!qualityCheck.isValid) {
        setState(() {
          _isProcessing = false;
          _state = LivenessState.serviceUnavailable;
          _showFallbackOption = true;
          _imageQualityWarning = qualityCheck.warning;
          _statusMessage = qualityCheck.warning!;
        });
        return;
      }

      setState(() {
        _state = LivenessState.success;
        _statusMessage = 'Selfie capturé avec succès !';
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) widget.onFallbackSelfie?.call(bytes);
      });
    } catch (e) {
      _log('Fallback selfie error: $e');
      setState(() {
        _state = LivenessState.error;
        _statusMessage = 'Impossible de capturer le selfie.';
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ============================================================
  //  VALIDATION QUALITÉ IMAGE
  // ============================================================

  _ImageQualityResult _validateImageQuality(Uint8List bytes) {
    // Taille minimale : une image JPEG valide fait au moins 5 KB
    if (bytes.length < 5 * 1024) {
      return const _ImageQualityResult(
        isValid: false,
        warning: 'Image trop petite. Rapprochez-vous de la caméra.',
      );
    }

    // Taille maximale : 10 MB (éviter surcharge réseau)
    if (bytes.length > 10 * 1024 * 1024) {
      return const _ImageQualityResult(
        isValid: false,
        warning: 'Image trop volumineuse.',
      );
    }

    // Vérifier que c'est bien un JPEG (magic bytes FF D8)
    if (bytes.length >= 2 && !(bytes[0] == 0xFF && bytes[1] == 0xD8)) {
      return const _ImageQualityResult(
        isValid: false,
        warning: 'Format d\'image non supporté.',
      );
    }

    // Estimation de luminosité via échantillonnage JPEG
    if (bytes.length > 1000) {
      final sampleSize = (bytes.length * 0.3).toInt().clamp(500, 10000);
      final startOffset = bytes.length ~/ 3;
      int sum = 0;
      for (int i = startOffset;
          i < startOffset + sampleSize && i < bytes.length;
          i++) {
        sum += bytes[i];
      }
      final avgBrightness = sum / sampleSize;

      if (avgBrightness < 40) {
        return const _ImageQualityResult(
          isValid: false,
          warning: 'Image trop sombre.\nAméliorez l\'éclairage.',
        );
      }
    }

    return const _ImageQualityResult(isValid: true);
  }

  // ============================================================
  //  UTILITAIRES
  // ============================================================

  Map<String, dynamic> _parseResponse(Response response) {
    if (response.data is String) return jsonDecode(response.data);
    if (response.data is Map) return Map<String, dynamic>.from(response.data);
    return {};
  }

  Map<String, dynamic>? _tryParseResponse(Response response) {
    try {
      return _parseResponse(response);
    } catch (_) {
      return null;
    }
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[Liveness] $message');
  }

  void _retry() {
    _captureTimer?.cancel();
    _sessionRetryCount = 0;
    _challengeRetryCount = 0;
    _startLivenessSession();
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _pulseController.dispose();
    _cameraController?.dispose();
    _dio.close();
    super.dispose();
  }

  // ============================================================
  //  BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera preview
                  if (_isCameraInitialized && _cameraController != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  else
                    const Center(
                        child:
                            CircularProgressIndicator(color: Colors.white)),

                  // Face overlay
                  _buildFaceOverlay(),

                  // Challenge instruction
                  if (!_isFallbackMode &&
                      _state != LivenessState.serviceUnavailable)
                    Positioned(
                      top: 20,
                      child: _buildChallengeInstruction(),
                    ),

                  // Countdown
                  if (_state == LivenessState.challenge) _buildCountdown(),

                  // Quality warning
                  if (_imageQualityWarning != null)
                    Positioned(
                      top: 20,
                      left: 20,
                      right: 20,
                      child: _buildQualityWarning(),
                    ),

                  // Status badge
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: _buildStatusBadge(),
                  ),
                ],
              ),
            ),
            _buildProgressBar(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              _captureTimer?.cancel();
              widget.onCancel?.call();
            },
          ),
          Expanded(
            child: Text(
              _isFallbackMode
                  ? 'Selfie de vérification'
                  : 'Vérification de vivacité',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildFaceOverlay() {
    Color overlayColor;
    switch (_state) {
      case LivenessState.success:
        overlayColor = Colors.green;
        break;
      case LivenessState.error:
      case LivenessState.retry:
        overlayColor = Colors.red;
        break;
      case LivenessState.validating:
        overlayColor = Colors.orange;
        break;
      case LivenessState.serviceUnavailable:
        overlayColor = Colors.amber;
        break;
      default:
        overlayColor = Colors.white;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(250, 320),
          painter: FaceOverlayPainter(
            color: overlayColor,
            scale: _state == LivenessState.challenge
                ? _pulseAnimation.value
                : 1.0,
          ),
        );
      },
    );
  }

  Widget _buildChallengeInstruction() {
    if (_currentChallenge == null) return const SizedBox.shrink();

    final instruction = _currentChallenge!['instruction'] ?? '';
    final description = _currentChallenge!['description'] ?? '';
    final type = _currentChallenge!['type'] ?? '';

    IconData icon;
    switch (type) {
      case 'blink':
        icon = Icons.remove_red_eye;
        break;
      case 'turn_left':
        icon = Icons.arrow_back;
        break;
      case 'turn_right':
        icon = Icons.arrow_forward;
        break;
      case 'smile':
        icon = Icons.sentiment_satisfied_alt;
        break;
      default:
        icon = Icons.face;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          Text(
            instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withValues(alpha: 0.8),
      ),
      child: Center(
        child: Text(
          _captureCountdown > 0 ? '$_captureCountdown' : '📸',
          style: TextStyle(
            color: Colors.white,
            fontSize: context.r.sp(40),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQualityWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _imageQualityWarning!,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    IconData icon;

    switch (_state) {
      case LivenessState.success:
        bgColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case LivenessState.error:
        bgColor = Colors.red;
        icon = Icons.error;
        break;
      case LivenessState.retry:
        bgColor = Colors.orange;
        icon = Icons.refresh;
        break;
      case LivenessState.validating:
        bgColor = Colors.blue;
        icon = Icons.hourglass_top;
        break;
      case LivenessState.serviceUnavailable:
        bgColor = Colors.orange.shade800;
        icon = Icons.cloud_off;
        break;
      case LivenessState.starting:
        bgColor = Colors.grey.shade700;
        icon = Icons.sync;
        break;
      default:
        bgColor = Colors.grey.shade800;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _totalChallenges > 0
        ? (_currentIndex + 1) / _totalChallenges
        : 0.0;

    // En mode dégradé, pas de barre de progression
    if (_isFallbackMode || _state == LivenessState.serviceUnavailable) {
      return const SizedBox(height: 16);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Challenge ${_currentIndex + 1}/$_totalChallenges',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade800,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // === Service indisponible → fallback + retry ===
          if (_state == LivenessState.serviceUnavailable) ...[
            if (_showFallbackOption)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureFallbackSelfie,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Prendre un selfie simple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            if (_showFallbackOption) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer la vérification'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          // === Erreur classique → recommencer ===
          if (_state == LivenessState.error)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Recommencer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          // === Challenge en cours → capture manuelle ===
          if (_state == LivenessState.challenge ||
              _state == LivenessState.ready)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _captureAndValidate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Capturer maintenant'),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
//  TYPES
// ============================================================

/// États possibles de la vérification
enum LivenessState {
  initializing,
  starting,
  ready,
  challenge,
  validating,
  retry,
  success,
  error,

  /// Service liveness indisponible (après tous les retries)
  serviceUnavailable,
}

/// Résultat de la validation qualité image
class _ImageQualityResult {
  final bool isValid;
  final String? warning;
  const _ImageQualityResult({required this.isValid, this.warning});
}

/// Exception API liveness interne
class _LivenessApiException implements Exception {
  final String message;
  final int? statusCode;
  const _LivenessApiException(this.message, this.statusCode);
}

/// Painter pour l'overlay du visage
class FaceOverlayPainter extends CustomPainter {
  final Color color;
  final double scale;

  FaceOverlayPainter({required this.color, this.scale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width * 0.8 * scale,
      height: size.height * 0.9 * scale,
    );

    canvas.drawOval(rect, paint);

    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 25.0;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + cornerLength),
        Offset(rect.left, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top),
        Offset(rect.left + cornerLength, rect.top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.top),
        Offset(rect.right, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLength),
        Offset(rect.left, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLength, rect.bottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.bottom),
        Offset(rect.right, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.scale != scale;
  }
}
