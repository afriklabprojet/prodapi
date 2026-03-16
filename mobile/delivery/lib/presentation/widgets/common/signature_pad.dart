import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/utils/responsive.dart';

/// Widget de signature électronique
///
/// Permet au client de signer avec le doigt pour les livraisons sensibles.
class SignaturePad extends StatefulWidget {
  final double width;
  final double height;
  final Color penColor;
  final double penWidth;
  final Color backgroundColor;
  final ValueChanged<Uint8List?>? onChanged;

  const SignaturePad({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.penColor = Colors.black,
    this.penWidth = 3.0,
    this.backgroundColor = Colors.white,
    this.onChanged,
  });

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];
  bool _isEmpty = true;

  /// Vérifie si le pad est vide
  bool get isEmpty => _isEmpty;

  /// Efface la signature
  void clear() {
    setState(() {
      _points.clear();
      _isEmpty = true;
    });
    widget.onChanged?.call(null);
  }

  /// Récupère les points de la signature
  List<Offset?> get points => List.unmodifiable(_points);

  /// Convertit la signature en image PNG
  Future<Uint8List?> toImage() async {
    if (_isEmpty) return null;

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(widget.width == double.infinity ? 400 : widget.width, widget.height);

      // Fond
      final bgPaint = Paint()
        ..color = widget.backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

      // Ligne de signature
      final signaturePaint = Paint()
        ..color = widget.penColor
        ..strokeWidth = widget.penWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, signaturePaint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Stack(
        children: [
          // Zone de dessin
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _points.add(details.localPosition);
                  _isEmpty = false;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                });
              },
              onPanEnd: (details) {
                setState(() {
                  _points.add(null); // Marqueur de fin de trait
                });
                // Notifier le parent que la signature a changé
                toImage().then((bytes) => widget.onChanged?.call(bytes));
              },
              child: CustomPaint(
                painter: _SignaturePainter(
                  points: _points,
                  penColor: widget.penColor,
                  penWidth: widget.penWidth,
                ),
                size: Size(widget.width, widget.height),
              ),
            ),
          ),

          // Placeholder quand vide
          if (_isEmpty)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.draw_outlined, size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Signez ici',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Bouton effacer
          if (!_isEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: clear,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.clear, size: 18, color: Colors.red.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color penColor;
  final double penWidth;

  _SignaturePainter({
    required this.points,
    required this.penColor,
    required this.penWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = penColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = penWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}

/// Dialog pour capturer une signature
class SignatureDialog extends StatefulWidget {
  final String title;
  final String? subtitle;

  const SignatureDialog({
    super.key,
    this.title = 'Signature du client',
    this.subtitle,
  });

  /// Affiche le dialog et retourne la signature en bytes
  static Future<Uint8List?> show(BuildContext context, {
    String title = 'Signature du client',
    String? subtitle,
  }) async {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SignatureDialog(title: title, subtitle: subtitle),
    );
  }

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final GlobalKey<SignaturePadState> _signatureKey = GlobalKey();
  Uint8List? _signatureBytes;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.draw_outlined, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SignaturePad(
              key: _signatureKey,
              height: context.r.dp(180),
              backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
              penColor: isDark ? Colors.white : Colors.black,
              onChanged: (bytes) {
                setState(() => _signatureBytes = bytes);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Demandez au client de signer avec le doigt',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
        ),
        TextButton(
          onPressed: () {
            _signatureKey.currentState?.clear();
            setState(() => _signatureBytes = null);
          },
          child: const Text('Effacer'),
        ),
        ElevatedButton(
          onPressed: _signatureBytes != null
              ? () => Navigator.pop(context, _signatureBytes)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
