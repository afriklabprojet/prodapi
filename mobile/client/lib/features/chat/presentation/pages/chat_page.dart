import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_providers.dart';
import '../providers/chat_state.dart';

class ChatPage extends ConsumerStatefulWidget {
  final int orderId;
  final int? deliveryId;
  final int participantId;
  final String participantName;
  final String participantType;
  final String? participantPhone;

  const ChatPage({
    super.key,
    required this.orderId,
    this.deliveryId,
    required this.participantId,
    required this.participantName,
    required this.participantType,
    this.participantPhone,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatParams _params;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _params = ChatParams(
      deliveryId: widget.deliveryId,
      orderId: widget.orderId,
      participantType: widget.participantType,
      participantId: widget.participantId,
      participantName: widget.participantName,
      participantPhone: widget.participantPhone,
    );
  }

  @override
  void deactivate() {
    WidgetsBinding.instance.removeObserver(this);
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatNotifierProvider(_params).notifier).loadMessages();
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
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ref.read(chatNotifierProvider(_params).notifier).sendMessage(text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _controller.text = text;
        AppSnackbar.error(context, 'Erreur d\'envoi');
      }
    }
  }

  Future<void> _callParticipant() async {
    if (widget.participantPhone == null) return;
    final uri = Uri.parse('tel:${widget.participantPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.participantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (chatState.isRemoteTyping)
              const Text('en train d\'écrire...', style: TextStyle(fontSize: 12, color: Colors.green))
            else
              Text(
                widget.participantType == 'courier' ? 'Livreur' : 'Pharmacie',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
          ],
        ),
        actions: [
          if (widget.participantPhone != null)
            IconButton(icon: const Icon(Icons.phone), onPressed: _callParticipant),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              chatState.isConnected ? Icons.wifi : Icons.wifi_off,
              size: 16,
              color: chatState.isConnected ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(chatState)),
          if (chatState.canSend) _buildInputBar(chatState),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(chatState.error!, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(chatNotifierProvider(_params).notifier).loadMessages(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (chatState.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Aucun message', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Envoyez un message pour démarrer', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final reversedIndex = chatState.messages.length - 1 - index;
        final message = chatState.messages[reversedIndex];
        return _buildMessageBubble(message, chatState);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ChatState chatState) {
    final isMe = message.isMine;
    final effectiveStatus = chatState.effectiveStatus(message);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: effectiveStatus == MessageStatus.failed
            ? () => ref.read(chatNotifierProvider(_params).notifier).retryFailed(message)
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe
                ? (effectiveStatus == MessageStatus.failed ? Colors.red[100] : AppColors.primary)
                : Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderType == 'courier' ? 'Livreur' : 'Pharmacie',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ),
              Text(
                message.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.grey[500]),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(effectiveStatus),
                  ],
                ],
              ),
              if (effectiveStatus == MessageStatus.failed)
                Text('Appuyez pour réessayer', style: TextStyle(fontSize: 10, color: Colors.red[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70));
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Color(0xFF4ADE80)); // Vert pour lu
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
    }
  }

  Widget _buildInputBar(ChatState chatState) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 8, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              onChanged: (_) => ref.read(chatNotifierProvider(_params).notifier).onTypingInput(),
              decoration: InputDecoration(
                hintText: 'Votre message...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: chatState.isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: chatState.isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
