import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../data/models/enhanced_chat_message.dart';
import '../../../core/services/enhanced_chat_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/snackbar_extension.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BULLE DE MESSAGE ENRICHIE
// ══════════════════════════════════════════════════════════════════════════════

/// Bulle de message avec support pour tous les types
class EnhancedMessageBubble extends StatelessWidget {
  final EnhancedChatMessage message;
  final int courierId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(EnhancedChatMessage)? onReply;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.courierId,
    this.onTap,
    this.onLongPress,
    this.onReply,
  });

  bool get isMe => message.isFromCourier(courierId);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Message système
    if (message.type == MessageType.system) {
      return _SystemMessageBubble(message: message);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar (pour les autres)
          if (!isMe) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],

          // Bulle
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: () {
                HapticFeedback.mediumImpact();
                onLongPress?.call();
              },
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Réponse citée
                  if (message.replyToContent != null)
                    _buildReplyQuote(isDark),

                  // Contenu principal
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF54AB70)
                          : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildContent(context, isDark),
                  ),

                  // Statut et heure
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.status.icon,
                            size: 14,
                            color: message.status.color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: message.senderRole.color.withValues(alpha: 0.2),
      backgroundImage: message.senderAvatar != null
          ? CachedNetworkImageProvider(message.senderAvatar!)
          : null,
      child: message.senderAvatar == null
          ? Icon(
              message.senderRole.icon,
              size: 16,
              color: message.senderRole.color,
            )
          : null,
    );
  }

  Widget _buildReplyQuote(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white54 : const Color(0xFF54AB70),
            width: 3,
          ),
        ),
      ),
      child: Text(
        message.replyToContent!,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white54 : Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    switch (message.type) {
      case MessageType.text:
      case MessageType.quickReply:
        return _TextMessageContent(message: message, isMe: isMe, isDark: isDark);
      case MessageType.image:
        return _ImageMessageContent(message: message, isMe: isMe);
      case MessageType.voice:
        return _VoiceMessageContent(message: message, isMe: isMe, isDark: isDark);
      case MessageType.location:
        return _LocationMessageContent(message: message, isMe: isMe, isDark: isDark);
      case MessageType.system:
        return const SizedBox.shrink();
    }
  }
}

/// Contenu texte
class _TextMessageContent extends StatelessWidget {
  final EnhancedChatMessage message;
  final bool isMe;
  final bool isDark;

  const _TextMessageContent({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Contenu image
class _ImageMessageContent extends StatelessWidget {
  final EnhancedChatMessage message;
  final bool isMe;

  const _ImageMessageContent({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
      ),
      child: Stack(
        children: [
          if (message.imageUrl != null)
            CachedNetworkImage(
              imageUrl: message.thumbnailUrl ?? message.imageUrl!,
              width: context.r.w(55),
              height: context.r.w(55),
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, progress) {
                return Container(
                  width: context.r.w(55),
                  height: context.r.w(55),
                  color: Colors.grey.shade300,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  width: context.r.w(55),
                  height: context.r.w(55),
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 48),
                );
              },
            ),
          if (message.content.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  message.content,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Contenu message vocal
class _VoiceMessageContent extends StatefulWidget {
  final EnhancedChatMessage message;
  final bool isMe;
  final bool isDark;

  const _VoiceMessageContent({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  State<_VoiceMessageContent> createState() => _VoiceMessageContentState();
}

class _VoiceMessageContentState extends State<_VoiceMessageContent> {
  bool _isPlaying = false;
  double _progress = 0.0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
        if (state == PlayerState.completed) {
          setState(() => _progress = 0.0);
        }
      }
    });
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && widget.message.audioDuration != null) {
        setState(() {
          _progress = position.inMilliseconds /
              widget.message.audioDuration!.inMilliseconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      final url = widget.message.audioUrl;
      if (url != null && url.isNotEmpty) {
        if (_progress > 0) {
          await _audioPlayer.resume();
        } else {
          await _audioPlayer.play(UrlSource(url));
        }
      }
    }
  }

  String get _durationText {
    if (widget.message.audioDuration == null) return '0:00';
    final duration = widget.message.audioDuration!;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton play/pause
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFF54AB70).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: widget.isMe ? Colors.white : const Color(0xFF54AB70),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform et durée
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform simplifiée
                SizedBox(
                  height: 30,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      progress: _progress,
                      activeColor: widget.isMe ? Colors.white : const Color(0xFF54AB70),
                      inactiveColor: widget.isMe
                          ? Colors.white.withValues(alpha: 0.3)
                          : const Color(0xFF54AB70).withValues(alpha: 0.3),
                    ),
                    size: const Size(double.infinity, 30),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _durationText,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isMe
                        ? Colors.white70
                        : (widget.isDark ? Colors.white54 : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour la waveform
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 3.0;
    final gap = 2.0;
    final totalBars = (size.width / (barWidth + gap)).floor();
    final activeBars = (totalBars * progress).floor();

    final activePaint = Paint()
      ..color = activeColor
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeCap = StrokeCap.round;

    // Générer des hauteurs pseudo-aléatoires mais cohérentes
    final heights = List.generate(totalBars, (i) {
      return 0.3 + (((i * 7) % 10) / 10) * 0.7;
    });

    for (int i = 0; i < totalBars; i++) {
      final x = i * (barWidth + gap) + barWidth / 2;
      final height = heights[i] * size.height;
      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        i < activeBars ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Contenu localisation
class _LocationMessageContent extends StatelessWidget {
  final EnhancedChatMessage message;
  final bool isMe;
  final bool isDark;

  const _LocationMessageContent({
    required this.message,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mini carte (placeholder)
        Container(
          width: context.r.w(55),
          height: context.r.w(33),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Stack(
            children: [
              // Placeholder de carte
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 40,
                      color: isMe ? const Color(0xFF54AB70) : Colors.red,
                    ),
                    const Text(
                      'Voir sur la carte',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Adresse
        if (message.locationAddress != null)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              message.locationAddress!,
              style: TextStyle(
                fontSize: 13,
                color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
      ],
    );
  }
}

/// Message système
class _SystemMessageBubble extends StatelessWidget {
  final EnhancedChatMessage message;

  const _SystemMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INDICATEUR DE SAISIE
// ══════════════════════════════════════════════════════════════════════════════

/// Widget d'indicateur de saisie animé
class TypingIndicator extends StatefulWidget {
  final String name;

  const TypingIndicator({super.key, required this.name});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.name} écrit',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final value = (_controller.value + delay) % 1.0;
                        final scale = 0.5 + (value < 0.5 ? value : 1.0 - value);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6 * scale,
                          height: 6 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFF54AB70),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RÉPONSES RAPIDES
// ══════════════════════════════════════════════════════════════════════════════

/// Widget de réponses rapides
class QuickRepliesWidget extends StatelessWidget {
  final Function(QuickReply) onSelect;

  const QuickRepliesWidget({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: QuickReply.defaults.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: reply.icon != null
                    ? Icon(reply.icon, size: 16, color: const Color(0xFF54AB70))
                    : null,
                label: Text(
                  reply.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFF54AB70).withValues(alpha: 0.1),
                side: BorderSide(
                  color: const Color(0xFF54AB70).withValues(alpha: 0.3),
                ),
                onPressed: () => onSelect(reply),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ZONE DE SAISIE ENRICHIE
// ══════════════════════════════════════════════════════════════════════════════

/// Zone de saisie avec support pour texte, images, vocaux, localisation
class EnhancedChatInput extends ConsumerStatefulWidget {
  final int orderId;
  final String target;
  final Function(String text)? onSendText;
  final Function(File image)? onSendImage;
  final Function(File audio, Duration duration)? onSendVoice;
  final Function()? onSendLocation;
  final VoidCallback? onTypingStart;
  final VoidCallback? onTypingStop;

  const EnhancedChatInput({
    super.key,
    required this.orderId,
    required this.target,
    this.onSendText,
    this.onSendImage,
    this.onSendVoice,
    this.onSendLocation,
    this.onTypingStart,
    this.onTypingStop,
  });

  @override
  ConsumerState<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends ConsumerState<EnhancedChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;
  bool _showQuickReplies = false;
  bool _hasText = false;
  Timer? _typingTimer;
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Gestion de l'indicateur de saisie
    if (hasText) {
      widget.onTypingStart?.call();
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        widget.onTypingStop?.call();
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendText?.call(text);
    _controller.clear();
    widget.onTypingStop?.call();
  }

  void _toggleQuickReplies() {
    setState(() => _showQuickReplies = !_showQuickReplies);
  }

  void _selectQuickReply(QuickReply reply) {
    widget.onSendText?.call(reply.text);
    setState(() => _showQuickReplies = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Column(
      children: [
        // Réponses rapides
        if (_showQuickReplies)
          QuickRepliesWidget(onSelect: _selectQuickReply),

        // Zone de saisie principale
        Container(
          padding: EdgeInsets.fromLTRB(
            8,
            8,
            8,
            MediaQuery.of(context).padding.bottom + 8,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Bouton pièces jointes
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF54AB70),
                  onPressed: _showAttachmentOptions,
                ),

                // Bouton réponses rapides
                IconButton(
                  icon: Icon(
                    _showQuickReplies ? Icons.keyboard : Icons.flash_on,
                    color: _showQuickReplies
                        ? const Color(0xFF54AB70)
                        : Colors.grey,
                  ),
                  onPressed: _toggleQuickReplies,
                ),

                // Champ texte
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Votre message...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Bouton envoi ou vocal
                _hasText
                    ? FloatingActionButton.small(
                        onPressed: _sendMessage,
                        backgroundColor: const Color(0xFF54AB70),
                        elevation: 0,
                        child: const Icon(Icons.send, color: Colors.white),
                      )
                    : GestureDetector(
                        onLongPressStart: (_) => _startRecording(),
                        onLongPressEnd: (_) => _stopRecording(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? Colors.red
                                : const Color(0xFF54AB70),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: _isRecording ? 28 : 20,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAttachmentOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttachmentOption(
                      icon: Icons.image,
                      label: 'Photo',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.camera_alt,
                      label: 'Caméra',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                    ),
                    _AttachmentOption(
                      icon: Icons.location_on,
                      label: 'Position',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSendLocation?.call();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (image != null) {
        widget.onSendImage?.call(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorMessage('Erreur lors de la sélection de l\'image');
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (photo != null) {
        widget.onSendImage?.call(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        context.showErrorMessage('Erreur lors de la prise de photo');
      }
    }
  }

  Future<void> _startRecording() async {
    HapticFeedback.heavyImpact();
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        _recordingStartTime = DateTime.now();
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission micro requise pour enregistrer')),
          );
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'enregistrement audio')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
    try {
      final path = await _audioRecorder.stop();
      if (path != null && _recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        // Ignorer les enregistrements de moins d'1 seconde (appui accidentel)
        if (duration.inMilliseconds > 1000) {
          widget.onSendVoice?.call(File(path), duration);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorMessage('Erreur lors de l\'arrêt de l\'enregistrement');
      }
    }
  }
}

/// Option d'attachement
class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BADGE DE CHAT NON LU
// ══════════════════════════════════════════════════════════════════════════════

/// Badge indiquant les messages non lus
class ChatUnreadBadge extends ConsumerWidget {
  final int? count;
  final double size;

  const ChatUnreadBadge({super.key, this.count, this.size = 18});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(totalUnreadCountProvider);
    final unreadValue = count ?? unreadAsync.maybeWhen(data: (d) => d, orElse: () => 0) ?? 0;

    if (unreadValue == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      child: Center(
        child: Text(
          unreadValue > 99 ? '99+' : '$unreadValue',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
