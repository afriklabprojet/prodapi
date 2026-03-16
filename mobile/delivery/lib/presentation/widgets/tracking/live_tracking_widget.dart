import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/live_tracking_service.dart';
import '../../../core/theme/theme_provider.dart';

/// Widget pour afficher et partager le lien de suivi en temps réel
class LiveTrackingWidget extends ConsumerStatefulWidget {
  final int deliveryId;
  final int courierId;
  final bool autoStart;
  
  const LiveTrackingWidget({
    super.key,
    required this.deliveryId,
    required this.courierId,
    this.autoStart = false,
  });

  @override
  ConsumerState<LiveTrackingWidget> createState() => _LiveTrackingWidgetState();
}

class _LiveTrackingWidgetState extends ConsumerState<LiveTrackingWidget> {
  String? _trackingUrl;
  bool _isLoading = false;
  bool _isActive = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _startTracking();
    } else {
      _checkExistingTracking();
    }
  }
  
  void _checkExistingTracking() {
    final service = ref.read(liveTrackingServiceProvider);
    if (service.isTrackingActive) {
      setState(() {
        _trackingUrl = service.getActiveTrackingLink();
        _isActive = true;
      });
    }
  }
  
  Future<void> _startTracking() async {
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(liveTrackingServiceProvider);
      final url = await service.generateTrackingLink(
        widget.deliveryId,
        widget.courierId,
      );
      await service.startLiveTracking(widget.deliveryId, widget.courierId);
      
      setState(() {
        _trackingUrl = url;
        _isActive = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _stopTracking() async {
    final service = ref.read(liveTrackingServiceProvider);
    await service.completeTracking();
    
    if (!mounted) return;
    setState(() {
      _trackingUrl = null;
      _isActive = false;
    });
  }
  
  Future<void> _shareLink() async {
    if (_trackingUrl == null) return;
    
    final service = ref.read(liveTrackingServiceProvider);
    await service.shareTrackingLink(_trackingUrl!);
  }
  
  Future<void> _copyLink() async {
    if (_trackingUrl == null) return;
    
    await Clipboard.setData(ClipboardData(text: _trackingUrl!));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien copié !'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isActive 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isActive ? Icons.share_location : Icons.location_off,
                  color: _isActive ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partage de position',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      _isActive 
                        ? 'Le client peut suivre votre position'
                        : 'Partagez votre position avec le client',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isActive)
                _PulsingDot(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lien de tracking ou bouton démarrer
          if (_trackingUrl != null) ...[
            // Afficher le lien
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _trackingUrl!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: _copyLink,
                    tooltip: 'Copier',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareLink,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Partager'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _stopTracking,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Arrêter'),
                ),
              ],
            ),
          ] else ...[
            // Bouton démarrer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startTracking,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow),
                label: Text(_isLoading ? 'Création...' : 'Activer le suivi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Point clignotant indiquant que le tracking est actif
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: _animation.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: _animation.value * 0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton compact pour partager la position
class ShareLocationButton extends ConsumerWidget {
  final int deliveryId;
  final int courierId;
  
  const ShareLocationButton({
    super.key,
    required this.deliveryId,
    required this.courierId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(liveTrackingServiceProvider);
    final isActive = service.isTrackingActive;
    
    return IconButton(
      icon: Icon(
        isActive ? Icons.share_location : Icons.location_off_outlined,
        color: isActive ? Colors.green : Colors.grey,
      ),
      tooltip: isActive ? 'Suivi actif' : 'Partager position',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: LiveTrackingWidget(
              deliveryId: deliveryId,
              courierId: courierId,
            ),
          ),
        );
      },
    );
  }
}
