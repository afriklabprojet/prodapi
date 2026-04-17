import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/liveness_repository.dart';

/// État du flux liveness
enum _LivenessPhase {
  initializing,
  ready,
  challenge,
  capturing,
  validating,
  success,
  failed,
}

/// Écran de vérification liveness (preuve de vie) pour KYC
class LivenessVerificationScreen extends ConsumerStatefulWidget {
  const LivenessVerificationScreen({super.key});

  @override
  ConsumerState<LivenessVerificationScreen> createState() =>
      _LivenessVerificationScreenState();
}

class _LivenessVerificationScreenState
    extends ConsumerState<LivenessVerificationScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  _LivenessPhase _phase = _LivenessPhase.initializing;
  LivenessSession? _session;
  String? _errorMessage;

  // Challenge tracking
  int _currentChallengeIndex = 0;
  List<String> _challenges = [];
  int _completedChallenges = 0;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  // Countdown
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _showCountdown = false;

  // Timeout
  Timer? _sessionTimer;
  int _remainingSeconds = 60;

  // Animations
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sessionTimer?.cancel();
    _cameraController?.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      await _startSession();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LivenessPhase.failed;
        _errorMessage =
            'Impossible d\'accéder à la caméra. Vérifiez les permissions.';
      });
    }
  }

  Future<void> _startSession() async {
    try {
      final session = await ref.read(livenessRepositoryProvider).startSession();
      if (!mounted) return;
      setState(() {
        _session = session;
        _challenges = session.challenges.isNotEmpty
            ? session.challenges
            : ['blink', 'smile', 'turn_left'];
        _currentChallengeIndex = 0;
        _completedChallenges = 0;
        _remainingSeconds = session.timeout > 0 ? session.timeout : 90;
        _phase = _LivenessPhase.ready;
      });
      _startSessionTimeout();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LivenessPhase.failed;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _startSessionTimeout() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onSessionExpired();
      }
    });
  }

  void _onSessionExpired() {
    if (_session != null) {
      ref.read(livenessRepositoryProvider).cancelSession(_session!.sessionId);
    }
    if (!mounted) return;
    setState(() {
      _phase = _LivenessPhase.failed;
      _errorMessage = 'Session expirée. Veuillez réessayer.';
    });
  }

  void _startChallenge() {
    setState(() {
      _phase = _LivenessPhase.challenge;
      _showCountdown = true;
      _countdown = 5;
      _errorMessage = null;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
          _showCountdown = false;
        });
        _captureImage();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    setState(() {
      _phase = _LivenessPhase.capturing;
      _showCountdown = false;
    });

    try {
      final xFile = await _cameraController!.takePicture();
      final file = File(xFile.path);
      await _validateChallenge(file);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LivenessPhase.challenge;
        _errorMessage = 'Erreur lors de la capture. Réessayez.';
      });
    }
  }

  Future<void> _validateChallenge(File imageFile) async {
    setState(() => _phase = _LivenessPhase.validating);

    try {
      final challenge = _challenges[_currentChallengeIndex];
      final result = await ref
          .read(livenessRepositoryProvider)
          .validateImage(
            sessionId: _session!.sessionId,
            imageFile: imageFile,
            challenge: challenge,
          );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _completedChallenges++;
          _retryCount = 0;
        });

        if (_completedChallenges >= _challenges.length) {
          // Tous les challenges complétés
          _sessionTimer?.cancel();
          _successController.forward();
          setState(() => _phase = _LivenessPhase.success);
        } else {
          // Passer au challenge suivant
          setState(() {
            _currentChallengeIndex++;
            _phase = _LivenessPhase.ready;
          });
        }
      } else {
        _retryCount++;
        if (_retryCount >= _maxRetries) {
          setState(() {
            _phase = _LivenessPhase.failed;
            _errorMessage =
                'Trop de tentatives échouées. Veuillez recommencer.';
          });
        } else {
          setState(() {
            _phase = _LivenessPhase.challenge;
            _errorMessage = result.error ?? 'Vérification échouée. Réessayez.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      _retryCount++;
      if (_retryCount >= _maxRetries) {
        setState(() {
          _phase = _LivenessPhase.failed;
          _errorMessage = 'Erreur de connexion. Veuillez recommencer.';
        });
      } else {
        setState(() {
          _phase = _LivenessPhase.challenge;
          _errorMessage = 'Erreur réseau. Réessayez.';
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _phase = _LivenessPhase.initializing;
      _errorMessage = null;
      _retryCount = 0;
      _currentChallengeIndex = 0;
      _completedChallenges = 0;
    });
    await _startSession();
  }

  String _getChallengeLabel(String challenge) {
    return switch (challenge) {
      'blink' => 'Clignez des yeux',
      'smile' => 'Souriez',
      'turn_left' => 'Tournez la tête à gauche',
      'turn_right' => 'Tournez la tête à droite',
      'nod' => 'Hochez la tête',
      'look_up' => 'Regardez vers le haut',
      'look_down' => 'Regardez vers le bas',
      _ => 'Suivez les instructions',
    };
  }

  IconData _getChallengeIcon(String challenge) {
    return switch (challenge) {
      'blink' => Icons.visibility_rounded,
      'smile' => Icons.sentiment_satisfied_alt_rounded,
      'turn_left' => Icons.turn_left_rounded,
      'turn_right' => Icons.turn_right_rounded,
      'nod' => Icons.swap_vert_rounded,
      'look_up' => Icons.arrow_upward_rounded,
      'look_down' => Icons.arrow_downward_rounded,
      _ => Icons.face_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            if (_cameraController != null &&
                _cameraController!.value.isInitialized)
              _buildCameraPreview(),

            // Dark overlay with oval cutout
            _buildOvalOverlay(isDark),

            // UI layer
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(isDark),
                  const Spacer(),
                  _buildBottomPanel(isDark),
                ],
              ),
            ),

            // Countdown overlay
            if (_showCountdown) _buildCountdownOverlay(),

            // Loading overlay
            if (_phase == _LivenessPhase.validating ||
                _phase == _LivenessPhase.capturing)
              _buildLoadingOverlay(),

            // Success overlay
            if (_phase == _LivenessPhase.success) _buildSuccessOverlay(isDark),

            // Failure overlay
            if (_phase == _LivenessPhase.failed) _buildFailureOverlay(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    final size = MediaQuery.of(context).size;
    final previewSize = controller.value.previewSize!;
    // previewSize est en orientation paysage (width > height)
    final cameraAspect = previewSize.height / previewSize.width;
    final screenAspect = size.width / size.height;
    // Scale pour remplir tout l'écran sans bandes noires
    final scale = 1 / (cameraAspect * screenAspect);

    return Transform.scale(
      scale: scale.clamp(1.0, 2.5),
      child: Center(child: CameraPreview(controller)),
    );
  }

  Widget _buildOvalOverlay(bool isDark) {
    return CustomPaint(
      painter: _OvalOverlayPainter(
        borderColor: switch (_phase) {
          _LivenessPhase.success => DesignTokens.success,
          _LivenessPhase.failed => DesignTokens.error,
          _LivenessPhase.challenge ||
          _LivenessPhase.capturing => DesignTokens.primary,
          _ => Colors.white.withValues(alpha: 0.6),
        },
        borderWidth: _phase == _LivenessPhase.challenge ? 3.0 : 2.0,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceMd,
        vertical: DesignTokens.spaceSm,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              if (_session != null) {
                ref
                    .read(livenessRepositoryProvider)
                    .cancelSession(_session!.sessionId);
              }
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Spacer(),
          // Timer
          if (_phase != _LivenessPhase.success &&
              _phase != _LivenessPhase.failed &&
              _remainingSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds <= 10
                    ? DesignTokens.error.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_remainingSeconds}s',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Progress indicator
          if (_challenges.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_completedChallenges/${_challenges.length}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots
          if (_challenges.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_challenges.length, (index) {
                final isCompleted = index < _completedChallenges;
                final isCurrent = index == _currentChallengeIndex;
                return Container(
                  width: isCurrent ? 28 : 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? DesignTokens.success
                        : isCurrent
                        ? DesignTokens.primary
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
          ],

          // Challenge instruction
          if (_phase == _LivenessPhase.initializing)
            _buildInfoRow(
              Icons.hourglass_top_rounded,
              'Initialisation de la caméra...',
              Colors.white70,
            )
          else if (_phase == _LivenessPhase.ready &&
              _currentChallengeIndex < _challenges.length)
            Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      _getChallengeIcon(_challenges[_currentChallengeIndex]),
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(
                  _getChallengeLabel(_challenges[_currentChallengeIndex]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceXs),
                Text(
                  'Centrez votre visage dans l\'ovale et appuyez',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: DesignTokens.fontSizeSm,
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                _buildActionButton(
                  'Commencer',
                  Icons.play_arrow_rounded,
                  _startChallenge,
                ),
              ],
            )
          else if (_phase == _LivenessPhase.challenge)
            Column(
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSm,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_rounded,
                          color: DesignTokens.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: DesignTokens.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _getChallengeLabel(_challenges[_currentChallengeIndex]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (_countdown > 0)
                  Text(
                    'Capture dans $_countdown secondes...',
                    style: GoogleFonts.inter(
                      color: DesignTokens.primaryLight,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  )
                else ...[
                  Text(
                    'Suivez les instructions',
                    style: GoogleFonts.inter(
                      color: DesignTokens.primaryLight,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildActionButton(
                      'Réessayer',
                      Icons.refresh_rounded,
                      _startChallenge,
                    ),
                  ],
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.inter(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [DesignTokens.primary, DesignTokens.primaryDark],
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$_countdown',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(DesignTokens.primaryLight),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _phase == _LivenessPhase.capturing
                  ? 'Capture en cours...'
                  : 'Vérification en cours...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: ScaleTransition(
          scale: _successAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.success,
                      DesignTokens.success.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.success.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Vérification réussie !',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre identité a été vérifiée avec succès',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildActionButton(
                'Continuer',
                Icons.arrow_forward_rounded,
                () => context.pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureOverlay(bool isDark) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: DesignTokens.error.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignTokens.error.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: DesignTokens.error,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Vérification échouée',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildActionButton('Réessayer', Icons.refresh_rounded, _retry),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.pop(false),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter pour l'ovale de découpe du visage
class _OvalOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderWidth;

  _OvalOverlayPainter({required this.borderColor, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = ovalWidth * 1.3;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Dark overlay avec découpe ovale
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Bordure ovale
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawOval(ovalRect, borderPaint);

    // Guides aux coins (petits arcs)
    _drawCornerGuides(canvas, ovalRect, borderColor);
  }

  void _drawCornerGuides(Canvas canvas, Rect ovalRect, Color color) {
    final guidePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    const arcLength = 0.25; // Quarter of the arc
    final angles = [
      -math.pi / 2 - arcLength / 2, // Top
      math.pi / 2 - arcLength / 2, // Bottom
      math.pi - arcLength / 2, // Left
      -arcLength / 2, // Right
    ];

    for (final startAngle in angles) {
      canvas.drawArc(ovalRect, startAngle, arcLength, false, guidePaint);
    }
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
