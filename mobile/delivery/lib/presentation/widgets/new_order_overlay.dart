import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/voice_service.dart';

/// Widget overlay qui affiche une nouvelle commande en temps réel
/// avec animation d'apparition et compte à rebours
class NewOrderOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final Function(String orderId)? onAccept;
  final Function()? onDismiss;
  final Duration autoHideDuration;

  const NewOrderOverlay({
    super.key,
    required this.child,
    this.onAccept,
    this.onDismiss,
    this.autoHideDuration = const Duration(seconds: 30),
  });

  @override
  ConsumerState<NewOrderOverlay> createState() => _NewOrderOverlayState();
}

class _NewOrderOverlayState extends ConsumerState<NewOrderOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  NewOrderNotification? _currentOrder;
  Timer? _autoHideTimer;
  int _remainingSeconds = 30;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoHideTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showOrder(NewOrderNotification order) {
    setState(() {
      _currentOrder = order;
      _remainingSeconds = widget.autoHideDuration.inSeconds;
    });
    
    _animationController.forward();
    
    // 🔊 Annonce vocale de la nouvelle commande
    _announceNewOrder(order);
    
    // Démarrer le compte à rebours
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
    
    // Auto-hide timer
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(widget.autoHideDuration, _hideOrder);
  }

  /// Annonce vocale d'une nouvelle commande
  void _announceNewOrder(NewOrderNotification order) {
    try {
      final voiceService = ref.read(voiceServiceProvider.notifier);
      final earnings = order.estimatedEarnings?.toStringAsFixed(0) ?? '';
      final distance = order.distanceKm != null
          ? '${order.distanceKm!.toStringAsFixed(1)} kilomètres'
          : '';
      
      String message = 'Nouvelle livraison. ${order.pharmacyName}.';
      if (earnings.isNotEmpty) {
        message += ' Commission: $earnings francs.';
      }
      if (distance.isNotEmpty) {
        message += ' Distance: $distance.';
      }
      if (order.deliveryAddress.isNotEmpty) {
        message += ' Livrer à ${order.deliveryAddress}.';
      }
      
      voiceService.speak(message, type: VoiceAnnouncementType.newDelivery);
    } catch (e) {
      // VoiceService non disponible, ignorer silencieusement
    }
  }

  void _hideOrder() {
    // Arrêter l'annonce vocale en cours
    try {
      ref.read(voiceServiceProvider.notifier).stop();
    } catch (_) {}
    
    _animationController.reverse().then((_) {
      setState(() => _currentOrder = null);
      widget.onDismiss?.call();
    });
    _autoHideTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _acceptOrder() {
    if (_currentOrder != null) {
      // 🔊 Confirmer vocalement l'acceptation
      try {
        ref.read(voiceServiceProvider.notifier).speak(
          'Livraison acceptée. Dirigez-vous vers ${_currentOrder!.pharmacyName}.',
          type: VoiceAnnouncementType.deliveryAccepted,
        );
      } catch (_) {}
      widget.onAccept?.call(_currentOrder!.orderId);
      _hideOrder();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter le stream de nouvelles commandes
    ref.listen<AsyncValue<NewOrderNotification?>>(newOrderStreamProvider, (_, next) {
      next.whenData((order) {
        if (order != null && _currentOrder == null) {
          _showOrder(order);
        }
      });
    });

    return Stack(
      children: [
        widget.child,
        
        // Overlay de nouvelle commande
        if (_currentOrder != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 12,
            right: 12,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildOrderCard(_currentOrder!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderCard(NewOrderNotification order) {
    final currencyFormat = NumberFormat("#,##0", "fr_FR");
    
    return Material(
      elevation: 12,
      shadowColor: Colors.orange.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.orange.shade600, Colors.deepOrange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec timer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                children: [
                  // Icône pulsante
                  _PulsingIcon(),
                  const SizedBox(width: 12),
                  
                  // Titre
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚚 NOUVELLE COMMANDE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Commande à proximité',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Timer circulaire
                  _buildCircularTimer(),
                  
                  // Bouton fermer
                  IconButton(
                    onPressed: _hideOrder,
                    icon: const Icon(Icons.close, color: Colors.white70),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24, height: 20),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Pharmacie
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pharmacie',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            Text(
                              order.pharmacyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Destination
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Livrer à',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            Text(
                              order.deliveryAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats (Gains + Distance)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Montant commande
                        _buildStat(
                          icon: Icons.shopping_bag,
                          label: 'Commande',
                          value: '${currencyFormat.format(order.amount)} F',
                        ),
                        
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.white24,
                        ),
                        
                        // Gains estimés
                        _buildStat(
                          icon: Icons.monetization_on,
                          label: 'Vos gains',
                          value: order.estimatedEarnings != null
                              ? '${currencyFormat.format(order.estimatedEarnings)} F'
                              : '---',
                          valueColor: Colors.greenAccent,
                        ),
                        
                        if (order.distanceKm != null) ...[
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white24,
                          ),
                          
                          // Distance
                          _buildStat(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '${order.distanceKm!.toStringAsFixed(1)} km',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Refuser
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _hideOrder,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Ignorer'),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Accepter
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _acceptOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepOrange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ACCEPTER',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularTimer() {
    final progress = _remainingSeconds / widget.autoHideDuration.inSeconds;
    
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(
              _remainingSeconds <= 10 ? Colors.redAccent : Colors.white,
            ),
            strokeWidth: 3,
          ),
          Text(
            '$_remainingSeconds',
            style: TextStyle(
              color: _remainingSeconds <= 10 ? Colors.redAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Icône avec animation de pulsation
class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delivery_dining,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
