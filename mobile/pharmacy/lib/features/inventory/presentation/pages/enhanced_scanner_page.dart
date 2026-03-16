import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/presentation/widgets/widgets.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/inventory_di_providers.dart';

/// Scanner amélioré avec recherche rapide et historique des scans
class EnhancedScannerPage extends ConsumerStatefulWidget {
  /// Mode du scanner: 'search' pour rechercher un produit, 'add' pour ajouter au stock
  final String mode;
  
  const EnhancedScannerPage({
    super.key,
    this.mode = 'search',
  });

  @override
  ConsumerState<EnhancedScannerPage> createState() => _EnhancedScannerPageState();
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
        _showProductResult(code);
      }
    }
  }

  void _showProductResult(String code) {
    setState(() => _isPaused = true);
    _controller.stop();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductResultSheet(
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
      _showProductResult(code);
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
      // Fermer le scanner et retourner le résultat vocal
      Navigator.of(context).pop(result);
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
          _showProductResult(code);
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
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          
          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanWindow: Rect.fromCenter(
                center: Offset(screenSize.width / 2, screenSize.height / 2 - 50),
                width: scanWindowWidth,
                height: scanWindowHeight,
              ),
              borderColor: _isPaused ? Colors.orange : Theme.of(context).colorScheme.primary,
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
                    color: _isPaused ? Colors.orange : Theme.of(context).colorScheme.primary,
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
                              top: _scanAnimation.value * (scanWindowHeight - 4),
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                  _isPaused ? 'Code scanné !' : 'Placez le code-barres dans le cadre',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPaused ? 'Traitement en cours...' : 'Le scan se fait automatiquement',
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
          
          // Recent Scans Quick Access
          if (_recentScans.isNotEmpty && !_showManualInput)
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
      ),
      title: Text(
        widget.mode == 'add' ? 'Ajouter un produit' : 'Scanner un produit',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      centerTitle: true,
      actions: [
        // Flash toggle
        IconButton(
          icon: Icon(
            _isFlashOn ? Icons.flash_on : Icons.flash_off,
            color: _isFlashOn ? Colors.amber : Colors.white,
          ),
          onPressed: _toggleFlash,
        ),
        // Camera switch
        IconButton(
          icon: const Icon(Icons.cameraswitch, color: Colors.white),
          onPressed: _toggleCamera,
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
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Manual Input Button
            _ControlButton(
              icon: Icons.keyboard,
              label: 'Saisir',
              onTap: _showManualInputDialog,
            ),
            
            // Voice Search Button
            _ControlButton(
              icon: Icons.mic,
              label: 'Vocal',
              onTap: _startVoiceSearch,
            ),
            
            // Gallery Button (for QR codes from images)
            _ControlButton(
              icon: Icons.photo_library,
              label: 'Galerie',
              onTap: _scanFromGallery,
            ),
            
            // History Button
            _ControlButton(
              icon: Icons.history,
              label: 'Historique',
              badge: _recentScans.isNotEmpty ? _recentScans.length.toString() : null,
              onTap: _showHistorySheet,
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _showManualInput = false),
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
                child: const Text(
                  'Rechercher',
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
                avatar: const Icon(Icons.history, size: 16, color: Colors.white),
                label: Text(
                  code.length > 12 ? '${code.substring(0, 12)}...' : code,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
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
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.primary),
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
    final color = _isPaused ? Colors.orange : Theme.of(context).colorScheme.primary;
    
    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(size: cornerSize, width: cornerWidth, color: color, position: _CornerPosition.topLeft),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(size: cornerSize, width: cornerWidth, color: color, position: _CornerPosition.topRight),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(size: cornerSize, width: cornerWidth, color: color, position: _CornerPosition.bottomLeft),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(size: cornerSize, width: cornerWidth, color: color, position: _CornerPosition.bottomRight),
      ),
    ];
  }
}

/// Résultat du scan
class _ProductResultSheet extends ConsumerStatefulWidget {
  final String code;
  final String mode;
  final VoidCallback onConfirm;
  final VoidCallback onScanAgain;
  final VoidCallback onCancel;

  const _ProductResultSheet({
    required this.code,
    required this.mode,
    required this.onConfirm,
    required this.onScanAgain,
    required this.onCancel,
  });

  @override
  ConsumerState<_ProductResultSheet> createState() => _ProductResultSheetState();
}

class _ProductResultSheetState extends ConsumerState<_ProductResultSheet> {
  bool _isLoading = true;
  ProductEntity? _product;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lookupProduct();
  }

  Future<void> _lookupProduct() async {
    try {
      final result = await ref.read(inventoryRepositoryProvider).getProducts();
      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _error = 'Impossible de vérifier le produit';
            });
          }
        },
        (products) {
          final match = products.where(
            (p) => p.barcode != null && p.barcode == widget.code,
          );
          if (mounted) {
            setState(() {
              _isLoading = false;
              _product = match.isNotEmpty ? match.first : null;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur lors de la recherche';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 24),
          
          // Success Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Code détecté !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Code display
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, color: Colors.grey),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copié !'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Product info from inventory lookup
          _buildProductInfo(),
          const SizedBox(height: 24),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onScanAgain,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Scanner à nouveau'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.mode == 'add' ? 'Ajouter' : 'Sélectionner',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recherche du produit...', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Vérification dans la base de données', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_error!, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
    }

    if (_product == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.grey, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Produit non trouvé', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Ce code-barres ne correspond à aucun produit en stock', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final product = _product!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.green.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CachedNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover, width: 60, height: 60),
                      )
                    : const Icon(Icons.medication, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    if (product.brand != null) ...[
                      const SizedBox(height: 2),
                      Text(product.brand!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                    const SizedBox(height: 4),
                    Text(product.category, style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoChip('Prix', '${product.price.toStringAsFixed(0)} FCFA'),
              _buildInfoChip('Stock', '${product.stockQuantity}'),
              _buildInfoChip('Ordonnance', product.requiresPrescription ? 'Oui' : 'Non'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      ],
    );
  }
}

/// Control button at bottom
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Corner position enum
enum _CornerPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Corner decoration widget
class _Corner extends StatelessWidget {
  final double size;
  final double width;
  final Color color;
  final _CornerPosition position;

  const _Corner({
    required this.size,
    required this.width,
    required this.color,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          width: width,
          position: position,
        ),
      ),
    );
  }
}

/// Paints corner decorations
class _CornerPainter extends CustomPainter {
  final Color color;
  final double width;
  final _CornerPosition position;

  _CornerPainter({
    required this.color,
    required this.width,
    required this.position,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    switch (position) {
      case _CornerPosition.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case _CornerPosition.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case _CornerPosition.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case _CornerPosition.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return color != oldDelegate.color || 
           width != oldDelegate.width || 
           position != oldDelegate.position;
  }
}

/// Scanner overlay painter
class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanWindowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(16)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      scanWindowPath,
    );

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return scanWindow != oldDelegate.scanWindow ||
           borderColor != oldDelegate.borderColor;
  }
}
