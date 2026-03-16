import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/responsive.dart';

/// Widget pour capturer une photo de preuve de livraison
class DeliveryPhotoCapture extends StatefulWidget {
  final File? initialPhoto;
  final ValueChanged<File?> onPhotoChanged;
  final bool required;

  const DeliveryPhotoCapture({
    super.key,
    this.initialPhoto,
    required this.onPhotoChanged,
    this.required = false,
  });

  @override
  State<DeliveryPhotoCapture> createState() => _DeliveryPhotoCaptureState();
}

class _DeliveryPhotoCaptureState extends State<DeliveryPhotoCapture> {
  File? _photo;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        setState(() => _photo = File(image.path));
        widget.onPhotoChanged(_photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() => _photo = null);
    widget.onPhotoChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_photo != null) {
      return _buildPhotoPreview(isDark);
    }

    return _buildCaptureButton(isDark);
  }

  Widget _buildPhotoPreview(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _photo!,
              width: double.infinity,
              height: context.r.dp(200),
              fit: BoxFit.cover,
            ),
          ),
          // Badge de succès
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Photo capturée',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          // Boutons d'action
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _actionButton(
                  icon: Icons.refresh,
                  color: Colors.blue,
                  onTap: _capturePhoto,
                  tooltip: 'Reprendre',
                ),
                const SizedBox(width: 8),
                _actionButton(
                  icon: Icons.delete,
                  color: Colors.red,
                  onTap: _removePhoto,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildCaptureButton(bool isDark) {
    return Material(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _capturePhoto,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: context.r.dp(160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.required ? Colors.orange.shade300 : Colors.grey.shade300,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.required 
                      ? Colors.orange.shade50 
                      : (isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 32,
                  color: widget.required ? Colors.orange.shade700 : Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Prendre une photo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.required 
                    ? 'Preuve de livraison requise'
                    : 'Photo du colis livré (optionnel)',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.required ? Colors.orange.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog complet pour capturer la preuve de livraison
class DeliveryProofDialog extends StatefulWidget {
  final bool requirePhoto;
  final bool requireSignature;
  final String? customerName;

  const DeliveryProofDialog({
    super.key,
    this.requirePhoto = true,
    this.requireSignature = false,
    this.customerName,
  });

  /// Affiche le dialog et retourne les preuves
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    bool requirePhoto = true,
    bool requireSignature = false,
    String? customerName,
  }) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryProofDialog(
        requirePhoto: requirePhoto,
        requireSignature: requireSignature,
        customerName: customerName,
      ),
    );
  }

  @override
  State<DeliveryProofDialog> createState() => _DeliveryProofDialogState();
}

class _DeliveryProofDialogState extends State<DeliveryProofDialog> {
  File? _photo;
  final TextEditingController _notesController = TextEditingController();

  bool get _isValid => !widget.requirePhoto || _photo != null;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.verified_outlined, color: Colors.blue.shade700, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preuve de livraison',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (widget.customerName != null)
                        Text(
                          'Client: ${widget.customerName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Photo capture
            DeliveryPhotoCapture(
              initialPhoto: _photo,
              onPhotoChanged: (photo) => setState(() => _photo = photo),
              required: widget.requirePhoto,
            ),
            const SizedBox(height: 20),

            // Notes
            Text(
              'Notes (optionnel)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ex: Colis laissé à la réception, client absent...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isValid
                        ? () => Navigator.pop(context, {
                              'photo': _photo,
                              'notes': _notesController.text.trim(),
                            })
                        : null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }
}
