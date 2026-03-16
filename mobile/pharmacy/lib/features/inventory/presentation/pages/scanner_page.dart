import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(seconds: 2), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the size of the scan window relative to screen size
    final scanWindowWidth = MediaQuery.of(context).size.width * 0.8;
    final scanWindowHeight = 250.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Semi-transparent or transparent
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scanner le code-barres',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Camera Layer
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                 final code = barcodes.first.rawValue;
                 if (code != null) {
                   HapticFeedback.mediumImpact();
                   controller.stop();
                   Navigator.of(context).pop(code);
                 }
              }
            },
          ),

          // 2. Overlay Layer (Dark background with hole)
          CustomPaint(
            painter: ScannerOverlayPainter(
              scanWindow: Rect.fromCenter(
                center: Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
                width: scanWindowWidth,
                height: scanWindowHeight,
              ),
            ),
            child: Container(),
          ),

          // 3. UI Elements Layer
          Positioned.fill(
             child: Column(
               children: [
                 const Spacer(), // Pushes content to center
                 // Center Area where scan happens
                 Container(
                   height: scanWindowHeight,
                   width: scanWindowWidth,
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.greenAccent, width: 2.0),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: AnimatedBuilder(
                     animation: _animation,
                     builder: (context, child) {
                       return Stack(
                         children: [
                           Positioned(
                             top: _animation.value * (scanWindowHeight - 20),
                             left: 0,
                             right: 0,
                             child: Container(
                               height: 2,
                               decoration: BoxDecoration(
                                 color: Colors.redAccent.withValues(alpha: 0.8),
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.redAccent.withValues(alpha: 0.5),
                                     blurRadius: 10,
                                     spreadRadius: 2,
                                   )
                                 ],
                               ),
                             ),
                           ),
                         ],
                       );
                     },
                   ),
                 ),
                 const SizedBox(height: 20),
                 const Text(
                   "Placez le code-barres dans le cadre",
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     color: Colors.white70,
                     fontSize: 16,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
                 const Text(
                   "Le scan se fait automatiquement",
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     color: Colors.white54,
                     fontSize: 14,
                   ),
                 ),
                 const Spacer(),
                 
                 // Bottom Actions
                 Container(
                   margin: const EdgeInsets.only(bottom: 40),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       // Flash Button
                       FloatingActionButton(
                         heroTag: "flash",
                         backgroundColor: Colors.black45,
                         elevation: 0,
                         onPressed: () {
                           controller.toggleTorch();
                           setState(() {
                             isFlashOn = !isFlashOn;
                           });
                         },
                         child: Icon(
                           isFlashOn ? Icons.flash_on : Icons.flash_off,
                           color: Colors.white,
                         ),
                       ),
                       const SizedBox(width: 30),
                       // Manual Entry Button
                       FloatingActionButton(
                         heroTag: "manual",
                         backgroundColor: Colors.black45,
                         elevation: 0,
                         onPressed: _showManualEntryDialog,
                         child: const Icon(Icons.keyboard, color: Colors.white),
                       ),
                     ],
                   ),
                 )
               ],
             ),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisie manuelle'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.text, // Alphanumeric for some barcodes
          decoration: const InputDecoration(
            hintText: 'Entrez le code-barres',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(value.trim()); // Return value to caller
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = textController.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(value); // Return value
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    ).whenComplete(() => textController.dispose());
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(12)));

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7) // Dark overlay
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(backgroundWithCutout, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
