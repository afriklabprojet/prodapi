import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/messaging/messaging.dart';
import '../../data/models/chat_message.dart';

class CourierChatPage extends ConsumerStatefulWidget {
  final int orderId;
  final int deliveryId;
  final int courierId;
  final String courierName;
  final String? courierPhone;

  const CourierChatPage({
    super.key,
    required this.orderId,
    required this.deliveryId,
    required this.courierId,
    required this.courierName,
    this.courierPhone,
  });

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
    _listenToMessages();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToMessages() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    _chatSubscription = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId.toString())
        .collection('messages')
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
          'participant_type': 'courier',
          'participant_id': widget.courierId.toString(),
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
          'receiver_type': 'courier',
          'receiver_id': widget.courierId,
          'message': message,
        },
      );

      if (!mounted) return;
      _controller.clear();
      HapticFeedback.lightImpact();

      // Firestore stream handles message updates automatically — no reload needed
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'envoyer le message. Réessayez.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _makePhoneCall() async {
    if (widget.courierPhone == null) return;
    final uri = Uri.parse('tel:${widget.courierPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    if (widget.courierPhone == null) return;
    final messaging = ref.read(messagingServiceProvider);
    await MessagingUiHelper.sendWithFeedback(
      context: context,
      action: () => messaging.contactCourier(
        courierPhone: widget.courierPhone!,
        courierName: widget.courierName,
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
              child: const Icon(
                Icons.delivery_dining,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courierName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Livreur',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.courierPhone != null) ...[
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
                          'Envoyez un message à votre livreur',
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
