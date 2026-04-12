import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../l10n/app_localizations.dart';
import '../../services/voice_search_service.dart';

/// Widget de bouton de recherche vocale
class VoiceSearchButton extends StatefulWidget {
  /// Callback appelé quand le texte est reconnu
  final Function(String) onResult;
  
  /// Callback optionnel pour les résultats partiels
  final Function(String)? onPartialResult;
  
  /// Taille du bouton
  final double size;
  
  /// Couleur du bouton
  final Color? color;
  
  /// Couleur active (pendant l'écoute)
  final Color? activeColor;

  const VoiceSearchButton({
    super.key,
    required this.onResult,
    this.onPartialResult,
    this.size = 48,
    this.color,
    this.activeColor,
  });

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  final VoiceSearchService _voiceService = VoiceSearchService();
  bool _isListening = false;
  bool _isInitializing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() => _isInitializing = true);
    await _voiceService.initialize();
    if (!mounted) return;
    setState(() => _isInitializing = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    
    if (_isListening) {
      await _voiceService.stopListening();
      _pulseController.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      
      await _voiceService.startListening(
        onResult: (text) {
          _pulseController.stop();
          setState(() => _isListening = false);
          widget.onResult(text);
        },
        onPartialResult: widget.onPartialResult,
      );
      
      _voiceService.onListeningStopped = () {
        if (mounted) {
          _pulseController.stop();
          setState(() => _isListening = false);
        }
      };
      
      _voiceService.onError = (error) {
        if (mounted) {
          _pulseController.stop();
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final activeColorValue = widget.activeColor ?? Colors.red;

    if (_isInitializing) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening 
                  ? activeColorValue.withValues(alpha: 0.1) 
                  : primaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: _isListening ? activeColorValue : primaryColor,
                width: 2,
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: activeColorValue.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: _voiceService.isAvailable ? _toggleListening : null,
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? activeColorValue : primaryColor,
                size: widget.size * 0.5,
              ),
              tooltip: _isListening ? 'Arrêter' : 'Recherche vocale',
            ),
          ),
        );
      },
    );
  }
}

/// Widget modal de recherche vocale avec animation
class VoiceSearchModal extends StatefulWidget {
  final Function(String) onResult;
  final String? hintText;

  const VoiceSearchModal({
    super.key,
    required this.onResult,
    this.hintText,
  });

  /// Affiche le modal de recherche vocale
  static Future<String?> show(BuildContext context, {String? hintText}) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceSearchModal(
        onResult: (text) => Navigator.of(context).pop(text),
        hintText: hintText,
      ),
    );
  }

  @override
  State<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends State<VoiceSearchModal>
    with TickerProviderStateMixin {
  final VoiceSearchService _voiceService = VoiceSearchService();
  final TextEditingController _manualInputController = TextEditingController();
  String _recognizedText = '';
  String _partialText = '';
  bool _isListening = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isWebPlatform = false;
  
  late AnimationController _waveController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isWebPlatform = kIsWeb;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();
    
    if (_isWebPlatform) {
      // Sur le web, afficher un message d'erreur
      setState(() {
        _hasError = true;
        _errorMessage = 'La recherche vocale n\'est pas disponible sur le navigateur web. Veuillez utiliser l\'application mobile.';
      });
    } else {
      _startListening();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fadeController.dispose();
    _manualInputController.dispose();
    _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_isWebPlatform) return;
    
    final initialized = await _voiceService.initialize();
    if (!initialized) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Service vocal non disponible';
      });
      return;
    }

    setState(() {
      _isListening = true;
      _hasError = false;
    });
    _waveController.repeat();

    await _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _recognizedText = text;
          _isListening = false;
        });
        _waveController.stop();
        
        // Attendre un peu puis retourner le résultat
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && text.isNotEmpty) {
            widget.onResult(text);
          }
        });
      },
      onPartialResult: (text) {
        setState(() => _partialText = text);
      },
    );

    _voiceService.onListeningStopped = () {
      if (mounted) {
        _waveController.stop();
        setState(() => _isListening = false);
      }
    };

    _voiceService.onError = (error) {
      if (mounted) {
        _waveController.stop();
        setState(() {
          _isListening = false;
          _hasError = true;
          _errorMessage = error;
        });
      }
    };
  }

  void _retryListening() {
    if (_isWebPlatform) return;
    setState(() {
      _recognizedText = '';
      _partialText = '';
      _hasError = false;
    });
    _startListening();
  }

  void _submitManualInput() {
    final text = _manualInputController.text.trim();
    if (text.isNotEmpty) {
      widget.onResult(text);
    }
  }

  Widget _buildManualInput() {
    return TextField(
      controller: _manualInputController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Tapez le nom du produit...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: _submitManualInput,
          icon: Icon(
            Icons.send,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Envoyer',
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      onSubmitted: (value) => _submitManualInput(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              
              // Titre
              Text(
                widget.hintText ?? 'Parlez maintenant...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dites le nom du produit à rechercher',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Animation microphone
              _buildMicrophoneAnimation(),
              const SizedBox(height: 24),
              
              // Texte reconnu
              if (_partialText.isNotEmpty || _recognizedText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _recognizedText.isNotEmpty ? _recognizedText : _partialText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _recognizedText.isNotEmpty 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Message d'erreur
              if (_hasError && !_isWebPlatform) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Champ de saisie manuelle pour le web
              if (_isWebPlatform) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recherche vocale non disponible sur le web.\nUtilisez la saisie ci-dessous.',
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildManualInput(),
              ],
              
              const SizedBox(height: 24),
              
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isWebPlatform 
                          ? _submitManualInput
                          : (_hasError || !_isListening ? _retryListening : null),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_hasError ? 'Réessayer' : 'Écoute...'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicrophoneAnimation() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Cercles d'onde
            if (_isListening) ...[
              _buildWaveCircle(0, 100),
              _buildWaveCircle(0.3, 80),
              _buildWaveCircle(0.6, 60),
            ],
            // Cercle central avec micro
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasError 
                    ? Colors.red 
                    : _isListening 
                        ? Colors.red 
                        : Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: (_hasError ? Colors.red : Colors.red).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _hasError 
                    ? Icons.mic_off 
                    : _isListening 
                        ? Icons.mic 
                        : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaveCircle(double delay, double maxSize) {
    final progress = (_waveController.value + delay) % 1.0;
    final size = 80 + (maxSize - 80) * progress;
    final opacity = (1 - progress) * 0.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.withValues(alpha: opacity),
          width: 2,
        ),
      ),
    );
  }
}
