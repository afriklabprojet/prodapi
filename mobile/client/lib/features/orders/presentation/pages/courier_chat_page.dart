import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/messaging/messaging.dart';
import '../../data/models/chat_message.dart';

class CourierChatPage extends ConsumerStatefulWidget {
  final int orderId;
  final int deliveryId;
  final int participantId;
  final String participantName;
  final String participantType; // 'courier' or 'pharmacy'
  final String? participantPhone;

  const CourierChatPage({
    super.key,
    required this.orderId,
    required this.deliveryId,
    required this.participantId,
    required this.participantName,
    this.participantType = 'courier',
    this.participantPhone,
  });

  /// Convenience constructor for courier chat (backwards-compatible)
  const CourierChatPage.courier({
    super.key,
    required this.orderId,
    required this.deliveryId,
    required int courierId,
    required String courierName,
    String? courierPhone,
  })  : participantId = courierId,
        participantName = courierName,
        participantType = 'courier',
        participantPhone = courierPhone;

  @override
  ConsumerState<CourierChatPage> createState() => _CourierChatPageState();
}

class _CourierChatPageState extends ConsumerState<CourierChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ensureFirebaseAuthAndListen();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// S'assurer que Firebase Auth est actif avant d'écouter Firestore
  Future<void> _ensureFirebaseAuthAndListen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (FirebaseAuth.instance.currentUser == null) {
      // Pas d'auth Firebase → récupérer un nouveau token via l'API
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get(ApiConstants.firebaseToken);
        final token = response.data['firebase_token'] as String?;
        if (token != null) {
          await FirebaseAuth.instance.signInWithCustomToken(token);
          debugPrint('🔥 [Chat] Firebase Auth restauré');
        }
      } catch (e) {
        debugPrint('⚠️ [Chat] Impossible de restaurer Firebase Auth: $e');
      }
    }

    _listenToMessages();
  }

  /// Le target Firestore correspondant au participant (pour envoyer des messages)
  String get _firestoreTarget => widget.participantType == 'pharmacy' ? 'pharmacy' : 'courier';

  void _listenToMessages() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId.toString())
        .collection('messages')
        .where('target', whereIn: [_firestoreTarget, 'customer', 'all'])
        .orderBy('created_at', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            final messages = snapshot.docs
                .map((doc) => ChatMessage.fromFirestore(doc.data(), doc.id))
                .toList();
            setState(() {
              _messages = messages;
              _isLoading = false;
            });
            _scrollToBottom();
          },
          onError: (error) {
            if (!mounted) return;
            // Fallback to HTTP if Firestore fails
            _loadMessagesHttp();
          },
        );
  }

  /// HTTP fallback for loading messages
  Future<void> _loadMessagesHttp() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiConstants.deliveryChat(widget.deliveryId),
        queryParameters: {
          'participant_type': widget.participantType,
          'participant_id': widget.participantId.toString(),
        },
      );

      final messages = (response.data['messages'] as List? ?? [])
          .map((e) => ChatMessage.fromJson(e))
          .toList();

      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les messages';
        _isLoading = false;
      });
    }
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

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        ApiConstants.deliveryChat(widget.deliveryId),
        data: {
          'receiver_type': widget.participantType,
          'receiver_id': widget.participantId,
          'message': message,
        },
      );

      // Écrire aussi dans Firestore pour que le destinataire voie le message en temps réel
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId.toString())
            .collection('messages')
            .add({
          'content': message,
          'sender_type': 'customer',
          'sender_id': user?.uid ?? 'customer_${widget.orderId}',
          'sender_name': 'Client',
          'target': _firestoreTarget,
          'status': 'sent',
          'type': 'text',
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Firestore sync is best-effort — API message is already saved
      }

      if (!mounted) return;
      _controller.clear();
      HapticFeedback.lightImpact();

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Impossible d\'envoyer le message. Réessayez.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _makePhoneCall() async {
    if (widget.participantPhone == null) return;
    final uri = Uri.parse('tel:${widget.participantPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    if (widget.participantPhone == null) return;
    final messaging = ref.read(messagingServiceProvider);
    await MessagingUiHelper.sendWithFeedback(
      context: context,
      action: () => messaging.contactCourier(
        courierPhone: widget.participantPhone!,
        courierName: widget.participantName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              radius: 18,
              child: Icon(
                widget.participantType == 'pharmacy'
                    ? Icons.local_pharmacy
                    : Icons.delivery_dining,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.participantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.participantType == 'pharmacy' ? 'Pharmacie' : 'Livreur',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.participantPhone != null) ...[
            IconButton(
              onPressed: _makePhoneCall,
              icon: const Icon(Icons.phone, color: Colors.white),
              tooltip: 'Appeler',
            ),
            IconButton(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.message, color: Colors.white),
              tooltip: 'WhatsApp',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(_error ?? 'Erreur inconnue'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _listenToMessages,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                          semanticLabel: 'Aucun message',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.participantType == 'pharmacy'
                              ? 'Envoyez un message à votre pharmacie'
                              : 'Envoyez un message à votre livreur',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      final isMe = msg.isMine;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.primary
                                : (isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(16),
                            ),
                            boxShadow: [
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
                                msg.message,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white
                                            : Colors.black87),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(msg.createdAt),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : (isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade500),
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isMe && msg.readAt != null) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 16,
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2C)
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: _isSending ? null : _sendMessage,
                  backgroundColor: _isSending ? Colors.grey : AppColors.primary,
                  elevation: 2,
                  child: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                          semanticLabel: 'Envoyer',
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
