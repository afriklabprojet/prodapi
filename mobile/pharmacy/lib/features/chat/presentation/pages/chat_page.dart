import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/realtime_event_bus.dart';
import '../../../../core/services/chat_websocket_service.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int deliveryId;
  final String participantType; // 'courier' ou 'client'
  final int participantId;
  final String participantName;

  const ChatPage({
    super.key,
    required this.deliveryId,
    required this.participantType,
    required this.participantId,
    required this.participantName,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _fallbackTimer;
  StreamSubscription<RealtimeEvent>? _chatSubscription;
  StreamSubscription<ChatWebSocketMessage>? _wsMessageSubscription;
  StreamSubscription<WebSocketState>? _wsStateSubscription;
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  bool _wsConnected = false;

  // Firestore-backed messages (primary source for courier chat)
  List<_FirestoreChatMsg> _firestoreMessages = [];
  bool _firestoreActive = false;
  bool _firestoreLoading = true;

  // Indicateur de frappe
  bool _otherIsTyping = false;
  Timer? _typingTimer;
  Timer? _typingResetTimer;
  static const _typingDebounce = Duration(milliseconds: 500);
  static const _typingTimeout = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    // Marquer les messages comme lus à l'ouverture
    _markAsRead();

    // Utiliser Firestore comme source primaire pour courier ET client
    if (widget.participantType == 'courier' || widget.participantType == 'client') {
      _ensureFirebaseAuthAndListen();
    }

    // Tenter la connexion WebSocket (backup)
    _initWebSocket();

    // Écouter les messages chat en temps réel via FCM (backup)
    _chatSubscription = RealtimeEventBus()
        .on(RealtimeEventType.chatMessage)
        .listen((_) {
          if (!_firestoreActive) {
            ref.invalidate(chatMessagesProvider(_params));
          }
          _markAsRead();
        });
  }

  // ============================================================
  // FIRESTORE (source primaire pour chat courier)
  // ============================================================

  /// Authentifier Firebase puis écouter les messages Firestore
  Future<void> _ensureFirebaseAuthAndListen() async {
    if (!mounted) return;
    setState(() => _firestoreLoading = true);

    // S'assurer que Firebase Auth est actif
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get('/auth/firebase-token');
        final data = response.data;
        final token = (data is Map ? data['firebase_token'] : null) as String?;
        if (token != null) {
          await FirebaseAuth.instance.signInWithCustomToken(token);
          debugPrint('🔥 [PharmacyChat] Firebase Auth restauré');
        }
      } catch (e) {
        debugPrint('⚠️ [PharmacyChat] Firebase Auth échoué: $e');
        // Fallback: on garde le mode HTTP
        if (mounted) setState(() => _firestoreLoading = false);
        return;
      }
    }

    _listenToFirestore();
  }

  /// Firestore target basé sur le type de participant
  String get _firestoreTarget {
    if (widget.participantType == 'courier') return 'courier';
    if (widget.participantType == 'client') return 'customer';
    return 'all';
  }

  /// Écouter les messages Firestore en temps réel (filtrés par conversation)
  void _listenToFirestore() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.deliveryId.toString())
        .collection('messages')
        .where('target', whereIn: [_firestoreTarget, 'pharmacy', 'all'])
        .orderBy('created_at', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            final messages = snapshot.docs.map((doc) {
              final d = doc.data();
              return _FirestoreChatMsg(
                id: doc.id,
                content: d['content'] as String? ?? '',
                senderType: d['sender_type'] as String? ?? '',
                senderId: d['sender_id'] as String? ?? '',
                senderName: d['sender_name'] as String? ?? '',
                target: d['target'] as String? ?? '',
                createdAt: _parseTimestamp(d['created_at']),
              );
            }).toList();
            setState(() {
              _firestoreMessages = messages;
              _firestoreActive = true;
              _firestoreLoading = false;
            });
            _scrollToBottom();
          },
          onError: (error) {
            debugPrint('⚠️ [PharmacyChat] Firestore error: $error');
            if (!mounted) return;
            // Fallback au mode HTTP
            setState(() {
              _firestoreActive = false;
              _firestoreLoading = false;
            });
          },
        );
  }

  DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initWebSocket() async {
    final ws = ChatWebSocketService.instance;

    // Écouter l'état de connexion
    _wsStateSubscription = ws.stateStream.listen((state) {
      final wasConnected = _wsConnected;
      _wsConnected = state == WebSocketState.connected;

      if (_wsConnected && !wasConnected) {
        // Connexion établie: arrêter le polling fallback
        _fallbackTimer?.cancel();
        _fallbackTimer = null;
        ws.subscribe(deliveryId: widget.deliveryId);
      } else if (!_wsConnected && wasConnected) {
        // Connexion perdue: démarrer le polling fallback
        _startFallbackPolling();
      }
    });

    // Écouter les messages WebSocket
    _wsMessageSubscription = ws.messageStream.listen((message) {
      if (message.deliveryId == widget.deliveryId) {
        if (message.type == 'typing') {
          // L'autre personne est en train d'écrire
          if (mounted) {
            setState(() => _otherIsTyping = true);
            _typingResetTimer?.cancel();
            _typingResetTimer = Timer(_typingTimeout, () {
              if (mounted) setState(() => _otherIsTyping = false);
            });
          }
        } else if (message.type == 'message') {
          ref.invalidate(chatMessagesProvider(_params));
          _markAsRead();
          // Arrêter l'indicateur de frappe à réception d'un message
          if (mounted) setState(() => _otherIsTyping = false);
        } else {
          ref.invalidate(chatMessagesProvider(_params));
        }
      }
    });

    // Tenter la connexion
    final connected = await ws.connect();
    if (connected) {
      ws.subscribe(deliveryId: widget.deliveryId);
    } else {
      // Fallback au polling si WebSocket échoue
      _startFallbackPolling();
    }
  }

  void _startFallbackPolling() {
    // Polling toutes les 60s comme filet de sécurité (réduit la batterie vs 15s)
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      ref.invalidate(chatMessagesProvider(_params));
      _markAsRead();
    });
  }

  ChatMessagesParams get _params => ChatMessagesParams(
    deliveryId: widget.deliveryId,
    participantType: widget.participantType,
    participantId: widget.participantId,
  );

  @override
  void dispose() {
    // Unsubscribe from WebSocket
    if (_wsConnected) {
      ChatWebSocketService.instance.unsubscribe(deliveryId: widget.deliveryId);
    }
    _firestoreSubscription?.cancel();
    _wsMessageSubscription?.cancel();
    _wsStateSubscription?.cancel();
    _chatSubscription?.cancel();
    _fallbackTimer?.cancel();
    _typingTimer?.cancel();
    _typingResetTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Envoie un indicateur de frappe (avec debounce)
  void _onTyping() {
    if (!_wsConnected) return;

    _typingTimer?.cancel();
    _typingTimer = Timer(_typingDebounce, () {
      ChatWebSocketService.instance.sendTyping(deliveryId: widget.deliveryId);
    });
  }

  void _markAsRead() {
    // Préférer WebSocket si connecté
    if (_wsConnected) {
      ChatWebSocketService.instance.sendRead(
        deliveryId: widget.deliveryId,
        participantType: widget.participantType,
        participantId: widget.participantId,
      );
    }
    // Toujours notifier le provider aussi (pour la synchro locale)
    ref
        .read(chatNotifierProvider.notifier)
        .markAsRead(
          deliveryId: widget.deliveryId,
          participantType: widget.participantType,
          participantId: widget.participantId,
        );
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // 1) Envoyer via API (persiste en MySQL)
    final success = await ref
        .read(chatNotifierProvider.notifier)
        .sendMessage(
          deliveryId: widget.deliveryId,
          receiverType: widget.participantType,
          receiverId: widget.participantId,
          message: message,
        );

    if (success) {
      _controller.clear();
      HapticFeedback.lightImpact();

      // 2) Écrire aussi dans Firestore pour que le destinataire voie en temps réel
      if (widget.participantType == 'courier' || widget.participantType == 'client') {
        try {
          final user = FirebaseAuth.instance.currentUser;
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.deliveryId.toString())
              .collection('messages')
              .add({
            'content': message,
            'sender_type': 'pharmacy',
            'sender_id': user?.uid ?? 'pharmacy_${widget.deliveryId}',
            'sender_name': 'Pharmacie',
            'target': _firestoreTarget,
            'status': 'sent',
            'type': 'text',
            'created_at': FieldValue.serverTimestamp(),
          });
        } catch (_) {
          // Firestore sync is best-effort — API message is already saved
        }
      }

      if (!_firestoreActive) {
        ref.invalidate(chatMessagesProvider(_params));
      }
      _scrollToBottom();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Échec de l\'envoi. Veuillez réessayer.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final isSending = chatState.isLoading;
    final isDark = AppColors.isDark(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: isDark ? 0 : 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.participantType == 'courier'
                  ? (isDark ? Colors.orange.shade900 : Colors.orange.shade100)
                  : (isDark ? Colors.blue.shade900 : Colors.blue.shade100),
              radius: 18,
              child: Icon(
                widget.participantType == 'courier'
                    ? Icons.delivery_dining
                    : Icons.person,
                color: widget.participantType == 'courier'
                    ? Colors.orange
                    : Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participantName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  widget.participantType == 'courier' ? 'Livreur' : 'Client',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _firestoreActive
                ? _buildFirestoreMessages(isDark)
                : _firestoreLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildHttpMessages(isDark),
          ),

          // Indicateur de frappe
          if (_otherIsTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TypingDots(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.participantName} écrit...',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !isSending,
                    onChanged: (_) => _onTyping(),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkCard
                          : Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: isSending ? null : _sendMessage,
                  backgroundColor: isSending ? Colors.grey : AppColors.success,
                  elevation: isDark ? 0 : 2,
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE LIST BUILDERS
  // ============================================================

  Widget _buildFirestoreMessages(bool isDark) {
    if (_firestoreMessages.isEmpty) {
      return AppEmptyState.chat();
    }
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _firestoreMessages.length,
      itemBuilder: (context, index) {
        final msg = _firestoreMessages[_firestoreMessages.length - 1 - index];
        final isMe = msg.senderType == 'pharmacy';

        return _buildBubble(
          content: msg.content,
          isMe: isMe,
          time: msg.createdAt,
          isDark: isDark,
          isRead: false, // Firestore: statut lu à implémenter
        );
      },
    );
  }

  Widget _buildHttpMessages(bool isDark) {
    final messagesAsync = ref.watch(chatMessagesProvider(_params));
    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) return AppEmptyState.chat();
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[messages.length - 1 - index];
            return _buildBubble(
              content: msg.message,
              isMe: msg.isMine,
              time: msg.createdAt,
              isDark: isDark,
              isRead: msg.readAt != null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text('Erreur: $e', style: TextStyle(color: Colors.red.shade400)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(chatMessagesProvider(_params)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble({
    required String content,
    required bool isMe,
    required DateTime time,
    required bool isDark,
    bool isRead = false,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.success
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white70
                        : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500),
                    fontSize: 11,
                  ),
                ),
                // Indicateur de lecture pour mes messages
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead
                        ? const Color(0xFF4ADE80) // Vert pour lu
                        : Colors.white70,         // Gris pour envoyé
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Firestore chat message model (local to this file)
// ============================================================
class _FirestoreChatMsg {
  final String id;
  final String content;
  final String senderType;
  final String senderId;
  final String senderName;
  final String target;
  final DateTime createdAt;

  _FirestoreChatMsg({
    required this.id,
    required this.content,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.target,
    required this.createdAt,
  });
}

/// Widget animé de points pour l'indicateur de frappe
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = (_controller.value * 3 - index).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (progress - 0.5).abs() * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
