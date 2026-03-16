import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/location_service.dart';
import '../../core/services/whatsapp_service.dart';
import '../../core/constants/map_constants.dart';
import '../../core/services/delivery_proof_service.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/delivery.dart';
import '../../data/models/route_info.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/support_repository.dart';
import '../widgets/common/delivery_photo_capture.dart';
import '../widgets/common/signature_pad.dart';
import '../widgets/common/eta_display.dart';
import '../widgets/delivery/qr_code_scanner.dart';
import '../widgets/scanner/document_scanner_widgets.dart';
import '../providers/delivery_providers.dart';
import '../../data/models/scanned_document.dart';
import '../../data/services/document_scanner_service.dart';
import 'wallet_screen.dart';
import 'rating_screen.dart';
import 'document_scanner_screen.dart';

class DeliveryDetailsScreen extends ConsumerStatefulWidget {
  final Delivery delivery;

  const DeliveryDetailsScreen({super.key, required this.delivery});

  @override
  ConsumerState<DeliveryDetailsScreen> createState() =>
      _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends ConsumerState<DeliveryDetailsScreen> {
  final Set<Marker> _staticMarkers = {};
  bool _isLoading = false;
  
  // Preuves de livraison
  File? _deliveryPhoto;
  Uint8List? _signatureBytes;
  
  // Route info pour ETA
  RouteInfo? _routeInfo;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _setupMarkers();
    _fetchRouteInfo();
  }

  @override
  void dispose() {
    _staticMarkers.clear();
    _deliveryPhoto = null;
    _signatureBytes = null;
    _routeInfo = null;
    super.dispose();
  }
  
  /// Récupère les informations de route (ETA, distance)
  Future<void> _fetchRouteInfo() async {
    // Déterminer l'origine et la destination
    LatLng? origin;
    LatLng? destination;
    
    try {
      // Position actuelle du livreur
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      origin = LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Utiliser la pharmacie comme origine si position non disponible
      if (widget.delivery.pharmacyLat != null && widget.delivery.pharmacyLng != null) {
        origin = LatLng(widget.delivery.pharmacyLat!, widget.delivery.pharmacyLng!);
      }
    }
    
    // Déterminer la destination selon le statut
    final status = widget.delivery.status;
    if (status == 'assigned' || status == 'accepted') {
      // En route vers la pharmacie
      if (widget.delivery.pharmacyLat != null && widget.delivery.pharmacyLng != null) {
        destination = LatLng(widget.delivery.pharmacyLat!, widget.delivery.pharmacyLng!);
      }
    } else {
      // En route vers le client
      if (widget.delivery.deliveryLat != null && widget.delivery.deliveryLng != null) {
        destination = LatLng(widget.delivery.deliveryLat!, widget.delivery.deliveryLng!);
      }
    }
    
    if (origin == null || destination == null) return;
    
    setState(() => _isLoadingRoute = true);
    
    try {
      final routeService = ref.read(routeServiceProvider);
      final routeInfo = await routeService.getRouteInfo(origin, destination);
      
      if (mounted && routeInfo != null) {
        setState(() {
          _routeInfo = routeInfo;
          _isLoadingRoute = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _setupMarkers() {
    // ...existing code...
    if (widget.delivery.pharmacyLat != null &&
        widget.delivery.pharmacyLng != null) {
      _staticMarkers.add(
        Marker(
          markerId: const MarkerId('pharmacy'),
          position: LatLng(
            widget.delivery.pharmacyLat!,
            widget.delivery.pharmacyLng!,
          ),
          infoWindow: InfoWindow(
            title: widget.delivery.pharmacyName,
            snippet: 'Pharmacie (Récupération)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    if (widget.delivery.deliveryLat != null &&
        widget.delivery.deliveryLng != null) {
      _staticMarkers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: LatLng(
            widget.delivery.deliveryLat!,
            widget.delivery.deliveryLng!,
          ),
          infoWindow: InfoWindow(
            title: widget.delivery.customerName,
            snippet: 'Client (Livraison)',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    final navApp = prefs.getString('navigation_app') ?? 'google_maps';
    
    Uri? uri;
    
    if (navApp == 'waze') {
      uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    } else if (navApp == 'apple_maps') {
      uri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    } else {
      // Google Maps (Default)
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    }

    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        launched = true;
      }
    } catch (e) {
      // Ignore initial launch errors
    }
    
    // Fallback logic if preferred app is not installed
    if (!launched) {
       // 1. Try Google Maps Universal Link (Web/App fallback)
       final googleWeb = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
       // 2. Try Apple Maps (iOS fallback)
       final appleMaps = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

       if (await canLaunchUrl(googleWeb)) {
         await launchUrl(googleWeb);
       } else if (await canLaunchUrl(appleMaps)) {
         await launchUrl(appleMaps);
       } else {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Impossible de lancer la navigation avec $navApp.')),
            );
         }
       }
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Numéro de téléphone non disponible')),
          );
        }
        return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de passer l\'appel.')),
        );
      }
    }
  }

  /// Ouvrir WhatsApp avec un message pré-rempli
  Future<void> _openWhatsApp(String? phoneNumber, {String? recipientName, bool isPharmacy = true}) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro WhatsApp non disponible')),
        );
      }
      return;
    }
    
    await WhatsAppService.openChatWithFeedback(
      context: context,
      phoneNumber: phoneNumber,
      recipientName: recipientName,
      isPharmacy: isPharmacy,
      orderReference: widget.delivery.reference,
    );
  }

  /// Vérifier le solde avant de permettre la livraison
  Future<bool> _checkBalanceForDelivery() async {
    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      final result = await walletRepo.canDeliver();
      
      final bool canDeliver = result['can_deliver'] ?? false;
      final double balance = (result['balance'] ?? 0).toDouble();
      final double required = (result['commission_amount'] ?? 200).toDouble();

      if (!canDeliver) {
        if (!mounted) return false;
        
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.orange.shade700,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Solde Insuffisant',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  'Votre solde actuel (${balance.toStringAsFixed(0)} FCFA) ne couvre pas la commission de ${required.toStringAsFixed(0)} FCFA.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.secondaryText, height: 1.4),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rechargez votre wallet pour continuer à livrer.',
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Plus tard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Naviguer vers l'écran wallet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Recharger'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        return false;
      }
      
      return true;
    } catch (e) {
      // En cas d'erreur de vérification, on montre un avertissement
      // mais on permet quand même de continuer (backend vérifiera)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Impossible de vérifier le solde, vérification côté serveur...'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
      return true; // On laisse le backend gérer
    }
  }

  Future<void> _updateStatus(String action) async {
    String? confirmationCode;

    // Si c'est pour livrer, vérifier le solde et capturer les preuves
    if (action == 'deliver') {
      // Vérifier le solde avant de permettre la livraison
      final canDeliverResult = await _checkBalanceForDelivery();
      if (!canDeliverResult) return;

      // Capturer la preuve de livraison (photo + optionnellement signature)
      final proofResult = await _showDeliveryProofDialog();
      if (proofResult == null) return; // Annulé
      
      _deliveryPhoto = proofResult['photo'] as File?;
      _signatureBytes = proofResult['signature'] as Uint8List?;

      confirmationCode = await _showConfirmationDialog();
      // Si pas de code, on annule l'action (retour)
      if (confirmationCode == null) return;
    }

    // Vérifier que le widget est toujours monté après les dialogs async
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      
      switch (action) {
        case 'accept':
          await repo.acceptDelivery(widget.delivery.id);
          // Mettre à jour Firestore : commande acceptée, début du tracking
          // Utiliser orderId comme clé Firestore (le client ne connaît que l'orderId)
          final locationService = ref.read(locationServiceProvider);
          locationService.currentOrderId = widget.delivery.orderId ?? widget.delivery.id;
          // Définir la destination (pharmacie d'abord, puis client après pickup)
          if (widget.delivery.pharmacyLat != null && widget.delivery.pharmacyLng != null) {
            locationService.setDestination(
              lat: widget.delivery.pharmacyLat!,
              lng: widget.delivery.pharmacyLng!,
            );
          }
          await locationService.updateDeliveryStatus(
            deliveryId: widget.delivery.orderId ?? widget.delivery.id,
            status: 'accepted',
          );
          break;
        case 'pickup':
          await repo.pickupDelivery(widget.delivery.id);
          // Mettre à jour Firestore : commande récupérée, en route vers le client
          // Changer la destination vers le client
          if (widget.delivery.deliveryLat != null && widget.delivery.deliveryLng != null) {
            ref.read(locationServiceProvider).setDestination(
              lat: widget.delivery.deliveryLat!,
              lng: widget.delivery.deliveryLng!,
            );
          }
          await ref.read(locationServiceProvider).updateDeliveryStatus(
            deliveryId: widget.delivery.orderId ?? widget.delivery.id,
            status: 'picked_up',
          );
          break;
        case 'deliver':
          await repo.completeDelivery(widget.delivery.id, confirmationCode!);
          
          // Upload preuve de livraison (en arrière-plan, ne bloque pas)
          if (_deliveryPhoto != null || _signatureBytes != null) {
            try {
              final proofService = ref.read(deliveryProofServiceProvider);
              await proofService.uploadProof(
                deliveryId: widget.delivery.id,
                proof: DeliveryProof(
                  photo: _deliveryPhoto,
                  signatureBytes: _signatureBytes,
                ),
              );
            } catch (_) {
              // Ne pas bloquer si l'upload échoue
            }
          }
          
          // Mettre à jour Firestore : livraison terminée
          final locService = ref.read(locationServiceProvider);
          await locService.updateDeliveryStatus(
            deliveryId: widget.delivery.orderId ?? widget.delivery.id,
            status: 'delivered',
          );
          locService.currentOrderId = null;
          locService.clearDestination();
          break;
        default:
          throw Exception('Action inconnue');
      }

        if (!mounted) return;

        if (action == 'deliver') {
          // Success Feedback
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: context.isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
                    ),
                    const SizedBox(height: 20),
                    Text('Livraison Terminée !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: context.isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 12),
                    Text(
                      'Excellent travail ! La commission de 200 FCFA a été déduite de votre wallet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.monetization_on, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Commission: -${widget.delivery.commission ?? 200} FCFA',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          // Navigate to rating screen instead of just going back
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatingScreen(
                                deliveryId: widget.delivery.id,
                                customerName: widget.delivery.customerName,
                                customerAddress: widget.delivery.deliveryAddress,
                              ),
                            ),
                          );
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('ÉVALUER LE CLIENT', style: TextStyle(fontWeight: FontWeight.bold))
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Close details
                      },
                      child: Text('Passer', style: TextStyle(color: context.isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    )
                ],
              ),
            )
          );
        } else {
           Navigator.pop(context);
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showConfirmationDialog() async {
    // Utilise le nouveau dialog avec option QR code
    return DeliveryConfirmationDialog.show(
      context,
      deliveryId: widget.delivery.id,
    );
  }

  /// Dialog pour capturer la preuve de livraison (photo + signature optionnelle)
  Future<Map<String, dynamic>?> _showDeliveryProofDialog() async {
    File? photo;
    Uint8List? signature;
    final notesController = TextEditingController();
    final isDark = context.isDark;

    try {
      return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                            Text(
                              'Client: ${widget.delivery.customerName}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Photo capture
                  Text(
                    '📷 Photo du colis livré',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DeliveryPhotoCapture(
                    initialPhoto: photo,
                    onPhotoChanged: (p) => setState(() => photo = p),
                    required: false,
                  ),
                  const SizedBox(height: 20),

                  // Signature (optionnel)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '✍️ Signature du client (optionnel)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (signature == null)
                        TextButton.icon(
                          onPressed: () async {
                            final sig = await SignatureDialog.show(
                              context,
                              title: 'Signature du client',
                              subtitle: widget.delivery.customerName,
                            );
                            if (sig != null) setState(() => signature = sig);
                          },
                          icon: const Icon(Icons.draw, size: 18),
                          label: const Text('Signer'),
                        ),
                    ],
                  ),
                  if (signature != null)
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.memory(signature!, fit: BoxFit.contain),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.red.shade700, size: 20),
                            onPressed: () => setState(() => signature = null),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Notes
                  Text(
                    '📝 Notes (optionnel)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ex: Colis laissé à la réception...',
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
                          onPressed: () => Navigator.pop(context, {
                            'photo': photo,
                            'signature': signature,
                            'notes': notesController.text.trim(),
                          }),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Continuer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
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
        },
      ),
    );
    } finally {
      notesController.dispose();
    }
  }

  Future<void> _cancelDelivery() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Motif d\'annulation'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Problème mécanique"),
            child: const Padding(padding: EdgeInsets.all(8.0), child: Text("Problème mécanique")),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, "Accident"),
            child: const Padding(padding: EdgeInsets.all(8.0), child: Text("Accident")),
          ),
          SimpleDialogOption(
             onPressed: () => Navigator.pop(context, "Client injoignable"),
            child: const Padding(padding: EdgeInsets.all(8.0), child: Text("Client injoignable")),
          ),
           SimpleDialogOption(
             onPressed: () => Navigator.pop(context, "Autre"),
            child: const Padding(padding: EdgeInsets.all(8.0), child: Text("Autre")),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      try {
        // Envoi via le repository (clean architecture)
        final supportRepo = ref.read(supportRepositoryProvider);
        await supportRepo.reportIncident(
          deliveryId: widget.delivery.id,
          reason: reason,
        );

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Incident signalé: $reason. Le support a été prévenu.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur envoi signalement: $e')),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    // Default to Abidjan if no coords
    final initialPos = (widget.delivery.pharmacyLat != null && widget.delivery.pharmacyLng != null)
        ? LatLng(widget.delivery.pharmacyLat!, widget.delivery.pharmacyLng!)
        : MapConstants.defaultLocation;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4)],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Full Screen Map
          StreamBuilder<Position>(
            stream: ref.watch(locationServiceProvider).locationStream,
            builder: (context, snapshot) {
              final Set<Marker> currentMarkers = Set.from(_staticMarkers);

              if (snapshot.hasData) {
                final position = snapshot.data!;
                currentMarkers.add(
                  Marker(
                    markerId: const MarkerId('courier'),
                    position: LatLng(position.latitude, position.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                    infoWindow: const InfoWindow(
                      title: 'Moi',
                      snippet: 'Position actuelle',
                    ),
                    rotation: position.heading,
                  ),
                );
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPos,
                  zoom: 14,
                ),
                markers: currentMarkers,
                onMapCreated: (controller) {},
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                padding: const EdgeInsets.only(bottom: 250), // Padding for bottom sheet
              );
            },
          ),

          // 2. Sliding Detail Panel
          DraggableScrollableSheet(
            initialChildSize: 0.50,
            minChildSize: 0.25,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.26),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Scrollable Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          // ETA Display
                          _buildETASection(),
                          const SizedBox(height: 20),
                          _buildTimeline(),
                          const SizedBox(height: 20),
                          _buildPaymentInfo(),
                          const SizedBox(height: 20),
                          // Document Scanner Section
                          _buildDocumentSection(),
                          const SizedBox(height: 24),
                          // Action Buttons INSIDE the scroll (not floating)
                          _buildActionButtons(),
                          const SizedBox(height: 30), // Bottom safe area
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commande #${widget.delivery.reference}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.delivery.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20), // Capsule shape
                  ),
                  child: Text(
                    _getStatusText(widget.delivery.status),
                    style: TextStyle(
                      color: _getStatusColor(widget.delivery.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 28),
            ),
          ],
        ),
      ],
    );
  }

  /// Section affichant l'ETA (temps et distance estimés)
  Widget _buildETASection() {
    final isDark = context.isDark;
    final status = widget.delivery.status;
    
    // Ne pas afficher si livraison terminée ou annulée
    if (status == 'delivered' || status == 'cancelled') {
      return const SizedBox.shrink();
    }
    
    // Afficher un loader pendant le chargement
    if (_isLoadingRoute) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Calcul du trajet...'),
          ],
        ),
      );
    }
    
    // Afficher l'ETA si disponible
    if (_routeInfo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Row(
            children: [
              Icon(
                status == 'assigned' || status == 'accepted'
                    ? Icons.store
                    : Icons.person_pin_circle,
                size: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                status == 'assigned' || status == 'accepted'
                    ? 'Vers la pharmacie'
                    : 'Vers le client',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Widget ETA
          ETADisplayWidget(
            duration: _routeInfo!.totalDuration,
            distance: _routeInfo!.totalDistance,
            isCompact: false,
            showArrivalTime: true,
          ),
        ],
      );
    }
    
    // Fallback: bouton pour rafraîchir
    return InkWell(
      onTap: _fetchRouteInfo,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Calculer le trajet',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final isDark = context.isDark;
    return Column(
      children: [
        // Pharmacy (Pickup)
        _buildTimelineItem(
          title: 'Pharmacie',
          name: widget.delivery.pharmacyName,
          address: widget.delivery.pharmacyAddress,
          icon: Icons.store_mall_directory_outlined,
          color: Colors.blue,
          isFirst: true,
          phone: widget.delivery.pharmacyPhone,
          lat: widget.delivery.pharmacyLat,
          lng: widget.delivery.pharmacyLng,
          isPharmacy: true,
          heroTag: DeliveryHeroTags.icon(widget.delivery.id),
        ),
        // Connector Line
        Container(
          height: 30,
          margin: const EdgeInsets.only(left: 24),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 2, style: BorderStyle.solid)),
          ),
        ),
        // Customer (Dropoff)
        _buildTimelineItem(
          title: 'Client',
          name: widget.delivery.customerName,
          address: widget.delivery.deliveryAddress,
          icon: Icons.person_outline,
          color: Colors.orange,
          isLast: true,
          phone: widget.delivery.customerPhone,
          lat: widget.delivery.deliveryLat,
          lng: widget.delivery.deliveryLng,
          isPharmacy: false,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String name,
    required String address,
    required IconData icon,
    required Color color,
    required double? lat,
    required double? lng,
    String? phone,
    bool isFirst = false,
    bool isLast = false,
    bool isPharmacy = false,
    String? heroTag,
  }) {
    final isDark = context.isDark;
    
    Widget iconWidget = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 24),
    );
    
    // Wrap in Hero if heroTag is provided
    if (heroTag != null) {
      iconWidget = Hero(
        tag: heroTag,
        child: iconWidget,
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            iconWidget,
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Text(address, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                   if (lat != null && lng != null)
                  _SmallActionButton(
                    icon: Icons.navigation_outlined,
                    label: 'Y aller',
                    color: Colors.blue.shade700,
                    onTap: () => _launchMaps(lat, lng),
                  ),
                  if (phone != null && phone.isNotEmpty)
                  _SmallActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Appeler',
                    color: Colors.green.shade700,
                    onTap: () => _makePhoneCall(phone),
                  ),
                  if (phone != null && phone.isNotEmpty)
                  _SmallActionButton(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366), // Couleur WhatsApp
                    onTap: () => _openWhatsApp(phone, recipientName: name, isPharmacy: isPharmacy),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    final isDark = context.isDark;
    final isPending = widget.delivery.status == 'pending';
    final deliveryFee = widget.delivery.deliveryFee ?? 500;
    final commission = widget.delivery.commission ?? 200;
    final estimatedEarnings = widget.delivery.estimatedEarnings ?? (deliveryFee - commission);
    final distanceKm = widget.delivery.distanceKm;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending
            ? (isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50)
            : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? (isDark ? Colors.green.shade700 : Colors.green.shade200)
              : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Montant total client
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total à la livraison:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
              Text(
                '${widget.delivery.totalAmount.toStringAsFixed(0)} FCFA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          
          // Afficher les gains estimés pour les courses en attente
          if (isPending) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.monetization_on, color: Colors.green.shade700, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vos gains estimés',
                              style: TextStyle(
                                color: context.secondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${estimatedEarnings.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                fontSize: context.r.sp(24),
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Détail du calcul
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildEarningsRow(
                          'Frais de livraison',
                          '+${deliveryFee.toStringAsFixed(0)} FCFA',
                          context.primaryText,
                        ),
                        const SizedBox(height: 6),
                        _buildEarningsRow(
                          'Commission plateforme',
                          '-${commission.toStringAsFixed(0)} FCFA',
                          Colors.red.shade600,
                        ),
                        if (distanceKm != null) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          _buildEarningsRow(
                            'Distance estimée',
                            '${distanceKm.toStringAsFixed(1)} km',
                            Colors.blue.shade700,
                            icon: Icons.straighten,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEarningsRow(String label, String value, Color valueColor, {IconData? icon}) {
    final isDark = context.isDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ],
        ),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }

  /// Section pour scanner et gérer les documents de livraison
  Widget _buildDocumentSection() {
    final isDark = context.isDark;
    final scannerState = ref.watch(documentScannerStateProvider);
    final deliveryDocuments = scannerState.scannedDocuments
        .where((d) => d.deliveryId == widget.delivery.id)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.document_scanner,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (deliveryDocuments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deliveryDocuments.length}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick scan buttons
          Row(
            children: [
              Expanded(
                child: _DocumentQuickButton(
                  icon: Icons.medical_services,
                  label: 'Ordonnance',
                  color: Colors.blue,
                  onTap: () => _openScanner(DocumentType.prescription),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentQuickButton(
                  icon: Icons.receipt_long,
                  label: 'Reçu',
                  color: Colors.green,
                  onTap: () => _openScanner(DocumentType.receipt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DocumentQuickButton(
                  icon: Icons.verified,
                  label: 'Preuve',
                  color: Colors.purple,
                  onTap: () => _openScanner(DocumentType.deliveryProof),
                ),
              ),
            ],
          ),

          // Scanned documents preview
          if (deliveryDocuments.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: deliveryDocuments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final doc = deliveryDocuments[index];
                  return _DocumentThumbnail(
                    document: doc,
                    onTap: () => _viewDocument(doc),
                  );
                },
              ),
            ),
          ],

          // View all button
          if (deliveryDocuments.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _viewAllDocuments,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir tous les documents',
                      style: TextStyle(color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16, color: Colors.blue.shade600),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Ouvre le scanner pour un type de document
  Future<void> _openScanner(DocumentType type) async {
    final result = await Navigator.push<ScannedDocument>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentScannerScreen(
          deliveryId: widget.delivery.id,
          preselectedType: type,
          autoStartCapture: true,
        ),
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.label} scanné avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Affiche un document en plein écran
  void _viewDocument(ScannedDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(doc.type.icon, color: doc.type.color),
                        const SizedBox(width: 8),
                        Text(
                          doc.type.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: doc.quality.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doc.quality.label,
                            style: TextStyle(
                              color: doc.quality.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(doc.displayImage),
                    ),
                    if (doc.ocrResult != null) ...[
                      const SizedBox(height: 16),
                      OcrResultsCard(
                        result: doc.ocrResult!,
                        documentType: doc.type,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Voir tous les documents de la livraison
  void _viewAllDocuments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliveryDocumentsScreen(
          deliveryId: widget.delivery.id,
          deliveryReference: widget.delivery.reference,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
       return const Padding(
         padding: EdgeInsets.symmetric(vertical: 16),
         child: Center(child: CircularProgressIndicator()),
       );
    }

    String label;
    Color color;
    IconData icon;
    String action;

    switch (widget.delivery.status) {
      case 'pending':
        label = 'Accepter la course';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        action = 'accept';
        break;
      case 'assigned':
        label = 'Confirmer récupération';
        color = Colors.blue;
        icon = Icons.store_mall_directory_outlined;
        action = 'pickup';
        break;
      case 'picked_up':
        label = 'Confirmer la livraison';
        color = Colors.orange.shade800;
        icon = Icons.local_shipping_outlined;
        action = 'deliver';
        break;
      default:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
              const SizedBox(width: 8),
              Text('Course terminée', style: TextStyle(fontWeight: FontWeight.w600, color: context.isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ],
          ),
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Action Button - compact height
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: Icon(icon, color: Colors.white, size: 20),
            label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            onPressed: () => _updateStatus(action),
          ),
        ),
        // Problem/Cancel - text button, minimal space
        if (widget.delivery.status != 'delivered')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: _cancelDelivery,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Signaler un problème / Annuler',
                    style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'assigned': return Colors.blue;
      case 'picked_up': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'En Attente';
      case 'assigned': return 'Assignée - En route Pharma';
      case 'picked_up': return 'En Livraison - Vers Client';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SmallActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08), // Softer background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton rapide pour scanner un type de document
class _DocumentQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DocumentQuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniature d'un document scanné
class _DocumentThumbnail extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback onTap;

  const _DocumentThumbnail({
    required this.document,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 70,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: document.type.color.withValues(alpha: 0.3)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  document.displayImage,
                  fit: BoxFit.cover,
                ),
              ),
              // Type indicator
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: document.type.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    document.type.icon,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
              // Upload status
              if (document.isUploaded)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_done,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
