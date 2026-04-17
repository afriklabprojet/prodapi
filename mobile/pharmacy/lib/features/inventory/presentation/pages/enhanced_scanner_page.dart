import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/scanner_overlay_widgets.dart';
import '../widgets/scanner_product_result_sheet.dart';

/// Scanner amélioré avec recherche rapide et historique des scans
class EnhancedScannerPage extends ConsumerStatefulWidget {
  /// Mode du scanner: 'search' pour rechercher un produit, 'add' pour ajouter au stock
  final String mode;

  /// Mode scan continu: scanne plusieurs codes sans s'arrêter (pour réception livraison)
  final bool continuousMode;

  const EnhancedScannerPage({
    super.key,
    this.mode = 'search',
    this.continuousMode = false,
  });

  @override
  ConsumerState<EnhancedScannerPage> createState() =>
      _EnhancedScannerPageState();
}

class _EnhancedScannerPageState extends ConsumerState<EnhancedScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  bool _isFlashOn = false;
  bool _isPaused = false;
  bool _showManualInput = false;
  final TextEditingController _manualCodeController = TextEditingController();
  final List<String> _recentScans = [];
  String? _lastScannedCode;

  /// Liste des codes scannés en mode continu
  final List<String> _continuousScans = [];

  /// Timestamp du dernier scan pour éviter les doublons rapides
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isPaused) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code != _lastScannedCode) {
        // Anti-doublon temporel (500ms minimum entre scans identiques)
        final now = DateTime.now();
        if (_lastScanTime != null &&
            now.difference(_lastScanTime!).inMilliseconds < 500) {
          return;
        }
        _lastScanTime = now;

        HapticFeedback.mediumImpact();
        setState(() {
          _lastScannedCode = code;
          if (!_recentScans.contains(code)) {
            _recentScans.insert(0, code);
            if (_recentScans.length > 10) {
              _recentScans.removeLast();
            }
          }
        });

        // Mode continu: ajouter à la liste sans arrêter
        if (widget.continuousMode) {
          _addToContinuousList(code);
        } else {
          _showProductResult(code);
        }
      }
    }
  }

  /// Ajoute un code à la liste continue avec feedback visuel
  void _addToContinuousList(String code) {
    if (_continuousScans.contains(code)) {
      // Code déjà scanné - warning
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 8),
              Text('Code déjà scanné: $code'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _continuousScans.add(code);
    });

    // Feedback visuel de succès
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Scanné: $code',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_continuousScans.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  /// Termine le scan continu et retourne la liste
  void _finishContinuousScan() {
    if (_continuousScans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun produit scanné'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Retourne la liste des codes séparés par des virgules
    Navigator.of(context).pop(_continuousScans.join(','));
  }

  /// Affiche la liste des scans continus pour review
  void _showContinuousScansSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Produits scannés (${_continuousScans.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_continuousScans.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _continuousScans.clear());
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Tout effacer'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _continuousScans.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun produit scanné',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _continuousScans.length,
                        itemBuilder: (context, index) {
                          final code = _continuousScans[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(code),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                setState(
                                  () => _continuousScans.removeAt(index),
                                );
                                Navigator.pop(context);
                                if (_continuousScans.isNotEmpty) {
                                  _showContinuousScansSheet();
                                }
                              },
                              tooltip: 'Retirer',
                            ),
                          );
                        },
                      ),
              ),
              if (_continuousScans.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _finishContinuousScan();
                        },
                        icon: const Icon(Icons.check),
                        label: Text(
                          'Valider ${_continuousScans.length} produits',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductResult(String code) {
    setState(() => _isPaused = true);
    _controller.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScannerProductResultSheet(
        code: code,
        mode: widget.mode,
        onConfirm: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(code);
        },
        onScanAgain: () {
          Navigator.of(context).pop();
          setState(() => _isPaused = false);
          _controller.start();
        },
        onCancel: () {
          Navigator.of(context).pop();
          setState(() => _isPaused = false);
          _controller.start();
        },
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    _controller.toggleTorch();
    HapticFeedback.lightImpact();
  }

  void _toggleCamera() {
    _controller.switchCamera();
    HapticFeedback.lightImpact();
  }

  void _showManualInputDialog() {
    setState(() => _showManualInput = true);
  }

  void _submitManualCode() {
    final code = _manualCodeController.text.trim();
    if (code.isNotEmpty) {
      _manualCodeController.clear();
      setState(() => _showManualInput = false);

      if (widget.continuousMode) {
        _addToContinuousList(code);
      } else {
        _showProductResult(code);
      }
    }
  }

  /// Démarre la recherche vocale
  Future<void> _startVoiceSearch() async {
    // Pause le scanner pendant la recherche vocale
    setState(() => _isPaused = true);
    _controller.stop();

    final result = await VoiceSearchModal.show(
      context,
      hintText: 'Dites le nom du produit',
    );

    if (result != null && result.isNotEmpty && mounted) {
      // Préfixer pour distinguer d'un code-barres
      Navigator.of(context).pop('voice:$result');
    } else {
      // Reprendre le scanner si annulé
      setState(() => _isPaused = false);
      _controller.start();
    }
  }

  /// Scanner un code-barres depuis une image de la galerie
  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      // Pause le scanner pendant l'analyse
      setState(() => _isPaused = true);
      _controller.stop();

      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Analyse de l\'image...'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Utiliser MobileScannerController pour analyser l'image
      final BarcodeCapture? result = await _controller.analyzeImage(image.path);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (result != null && result.barcodes.isNotEmpty) {
        final code = result.barcodes.first.rawValue;
        if (code != null && mounted) {
          HapticFeedback.mediumImpact();
          setState(() {
            _lastScannedCode = code;
            if (!_recentScans.contains(code)) {
              _recentScans.insert(0, code);
              if (_recentScans.length > 10) {
                _recentScans.removeLast();
              }
            }
          });

          if (widget.continuousMode) {
            _addToContinuousList(code);
            // Reprendre le scanner en mode continu
            setState(() => _isPaused = false);
            _controller.start();
          } else {
            _showProductResult(code);
          }
          return;
        }
      }

      // Aucun code-barres trouvé
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Aucun code-barres détecté dans l\'image'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _scanFromGallery,
            ),
          ),
        );

        // Reprendre le scanner
        setState(() => _isPaused = false);
        _controller.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erreur: ${e.toString()}')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );

        // Reprendre le scanner
        setState(() => _isPaused = false);
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanWindowWidth = screenSize.width * 0.8;
    const scanWindowHeight = 200.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Camera
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetected),

          // Overlay
          CustomPaint(
            painter: ScannerOverlayPainter(
              scanWindow: Rect.fromCenter(
                center: Offset(
                  screenSize.width / 2,
                  screenSize.height / 2 - 50,
                ),
                width: scanWindowWidth,
                height: scanWindowHeight,
              ),
              borderColor: _isPaused
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary,
            ),
            child: const SizedBox.expand(),
          ),

          // Scan Window Frame & Animation
          Center(
            child: Transform.translate(
              offset: const Offset(0, -50),
              child: Container(
                width: scanWindowWidth,
                height: scanWindowHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isPaused
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      // Scanning line animation
                      if (!_isPaused)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top:
                                  _scanAnimation.value * (scanWindowHeight - 4),
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.8),
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Corner decorations
                      ..._buildCorners(scanWindowWidth, scanWindowHeight),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Instructions Text
          Positioned(
            left: 20,
            right: 20,
            bottom: screenSize.height * 0.35,
            child: Column(
              children: [
                Text(
                  widget.continuousMode
                      ? 'Mode scan continu'
                      : (_isPaused
                            ? 'Code scanné !'
                            : 'Placez le code-barres dans le cadre'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.continuousMode
                      ? 'Scannez tous les produits puis validez'
                      : (_isPaused
                            ? 'Traitement en cours...'
                            : 'Le scan se fait automatiquement'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          _buildBottomControls(),

          // Manual Input Panel
          if (_showManualInput) _buildManualInputPanel(),

          // Recent Scans Quick Access (pas en mode continu)
          if (_recentScans.isNotEmpty &&
              !_showManualInput &&
              !widget.continuousMode)
            _buildRecentScansChips(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black54,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Fermer le scanner',
      ),
      title: Text(
        widget.continuousMode
            ? 'Scan continu'
            : (widget.mode == 'add'
                  ? 'Ajouter un produit'
                  : 'Scanner un produit'),
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        // Compteur en mode continu
        if (widget.continuousMode && _continuousScans.isNotEmpty)
          GestureDetector(
            onTap: _showContinuousScansSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_continuousScans.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Flash toggle
        IconButton(
          icon: Icon(
            _isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: _isFlashOn ? Colors.amber : Colors.white,
          ),
          onPressed: _toggleFlash,
          tooltip: 'Flash',
        ),
        // Camera switch
        IconButton(
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          onPressed: _toggleCamera,
          tooltip: 'Changer de caméra',
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Valider en mode continu
            if (widget.continuousMode) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _continuousScans.isEmpty
                      ? null
                      : _finishContinuousScan,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    _continuousScans.isEmpty
                        ? 'Scannez des produits'
                        : 'Valider ${_continuousScans.length} produit${_continuousScans.length > 1 ? 's' : ''}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade700,
                    disabledForegroundColor: Colors.grey.shade400,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Manual Input Button
                ScannerControlButton(
                  icon: Icons.keyboard,
                  label: 'Saisir',
                  onTap: _showManualInputDialog,
                ),

                // Voice Search Button (pas en mode continu)
                if (!widget.continuousMode)
                  ScannerControlButton(
                    icon: Icons.mic,
                    label: 'Vocal',
                    onTap: _startVoiceSearch,
                  ),

                // Gallery Button (for QR codes from images)
                ScannerControlButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: _scanFromGallery,
                ),

                // History/Liste Button
                ScannerControlButton(
                  icon: widget.continuousMode ? Icons.list_alt : Icons.history,
                  label: widget.continuousMode ? 'Liste' : 'Historique',
                  badge: widget.continuousMode
                      ? (_continuousScans.isNotEmpty
                            ? _continuousScans.length.toString()
                            : null)
                      : (_recentScans.isNotEmpty
                            ? _recentScans.length.toString()
                            : null),
                  onTap: widget.continuousMode
                      ? _showContinuousScansSheet
                      : _showHistorySheet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Saisie manuelle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showManualInput = false),
                  tooltip: AppLocalizations.of(context).close,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualCodeController,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Entrez le code-barres ou le nom du produit',
                prefixIcon: const Icon(Icons.qr_code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _submitManualCode,
                  tooltip: AppLocalizations.of(context).search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onSubmitted: (_) => _submitManualCode(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitManualCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).search,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansChips() {
    return Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _recentScans.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final code = _recentScans[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(
                  Icons.history,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  code.length > 12 ? '${code.substring(0, 12)}...' : code,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
                backgroundColor: Colors.black54,
                onPressed: () => _showProductResult(code),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Historique des scans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (_recentScans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucun scan récent',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentScans.length,
                itemBuilder: (context, index) {
                  final code = _recentScans[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.qr_code_2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(code),
                    subtitle: Text('Scan #${index + 1}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showProductResult(code);
                    },
                  );
                },
              ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners(double width, double height) {
    const cornerSize = 20.0;
    const cornerWidth = 4.0;
    final color = _isPaused
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: ScannerCorner(
          size: cornerSize,
          width: cornerWidth,
          color: color,
          position: CornerPosition.topLeft,
        ),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: ScannerCorner(
          size: cornerSize,
          width: cornerWidth,
          color: color,
          position: CornerPosition.topRight,
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: ScannerCorner(
          size: cornerSize,
          width: cornerWidth,
          color: color,
          position: CornerPosition.bottomLeft,
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: ScannerCorner(
          size: cornerSize,
          width: cornerWidth,
          color: color,
          position: CornerPosition.bottomRight,
        ),
      ),
    ];
  }
}
