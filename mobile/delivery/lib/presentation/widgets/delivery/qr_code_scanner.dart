import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../../../core/utils/responsive.dart';

/// Widget pour scanner le QR code du client et confirmer la livraison
class QRCodeScannerWidget extends StatelessWidget {
  final Function(String code) onCodeScanned;
  final VoidCallback? onCancel;

  const QRCodeScannerWidget({
    super.key,
    required this.onCodeScanned,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.qr_code_scanner, size: 40, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Scanner le QR Code',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            'Demandez au client d\'afficher son QR code de livraison dans l\'application',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          // Scan button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _startScanning(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ouvrir la caméra', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Cancel
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
        ],
      ),
    );
  }

  Future<void> _startScanning(BuildContext context) async {
    final result = await SimpleBarcodeScanner.scanBarcode(
      context,
      lineColor: '#007AFF',
      cancelButtonText: 'Annuler',
      isShowFlashIcon: true,
    );

    if (result != null && result != '-1' && result.isNotEmpty) {
      // Parse le résultat - format attendu: DRPH-{orderId}-{code}
      final code = _parseQRCode(result);
      if (code != null) {
        onCodeScanned(code);
      } else {
        // QR invalide
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('QR code invalide'),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Parse un QR code DR-PHARMA
  /// Format attendu: DRPH-{orderId}-{code} ou juste le code à 4 chiffres
  String? _parseQRCode(String rawData) {
    // Format complet: DRPH-123-4567
    if (rawData.startsWith('DRPH-')) {
      final parts = rawData.split('-');
      if (parts.length >= 3) {
        return parts.last; // Le code est la dernière partie
      }
    }
    
    // Format simple: juste le code à 4 chiffres
    if (rawData.length == 4 && int.tryParse(rawData) != null) {
      return rawData;
    }
    
    // Essayer d'extraire 4 chiffres consécutifs
    final match = RegExp(r'\d{4}').firstMatch(rawData);
    if (match != null) {
      return match.group(0);
    }
    
    return null;
  }
}

/// Dialog complet avec option scanner ou saisie manuelle
class DeliveryConfirmationDialog extends StatefulWidget {
  final int deliveryId;
  
  const DeliveryConfirmationDialog({
    super.key,
    required this.deliveryId,
  });

  /// Affiche le dialog et retourne le code de confirmation
  static Future<String?> show(BuildContext context, {required int deliveryId}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryConfirmationDialog(deliveryId: deliveryId),
    );
  }

  @override
  State<DeliveryConfirmationDialog> createState() => _DeliveryConfirmationDialogState();
}

class _DeliveryConfirmationDialogState extends State<DeliveryConfirmationDialog> {
  final _codeController = TextEditingController();
  bool _showManualInput = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showManualInput 
                    ? _buildManualInput(isDark) 
                    : _buildScannerOption(isDark),
              ),
              
              // Toggle option
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton.icon(
                  onPressed: () => setState(() => _showManualInput = !_showManualInput),
                  icon: Icon(
                    _showManualInput ? Icons.qr_code_scanner : Icons.keyboard,
                    size: 20,
                  ),
                  label: Text(
                    _showManualInput ? 'Scanner un QR code' : 'Saisir le code manuellement',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOption(bool isDark) {
    return QRCodeScannerWidget(
      key: const ValueKey('scanner'),
      onCodeScanned: (code) {
        Navigator.pop(context, code);
      },
      onCancel: () => Navigator.pop(context, null),
    );
  }

  Widget _buildManualInput(bool isDark) {
    return Container(
      key: const ValueKey('manual'),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.password, size: 40, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Code de confirmation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            'Demandez le code à 4 chiffres au client',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Code input
          SizedBox(
            width: context.r.dp(200),
            child: TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              style: TextStyle(
                fontSize: context.r.sp(32),
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: '• • • •',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  letterSpacing: 8,
                ),
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              ),
              onChanged: (value) {
                if (value.length == 4) {
                  // Auto-submit quand 4 chiffres sont entrés
                  Navigator.pop(context, value);
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Validate button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                if (_codeController.text.length == 4) {
                  Navigator.pop(context, _codeController.text);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Valider', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
