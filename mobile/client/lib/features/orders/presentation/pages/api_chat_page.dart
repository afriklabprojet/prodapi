import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/models/chat_message.dart';

/// Chat page utilisant uniquement l'API HTTP (pas de Firestore)
/// Polling toutes les 2 secondes pour le temps réel
class ApiChatPage extends ConsumerStatefulWidget {
  final int orderId;
  final int? deliveryId;
  final int participantId;
  final String participantName;
  final String participantType; // 'courier' or 'pharmacy'
  final String? participantPhone;

  const ApiChatPage({
    super.key,
    required this.orderId,
    this.deliveryId,
    required this.participantId,
    required this.participantName,
    this.participantType = 'courier',
    this.participantPhone,
  });

  @override
  ConsumerState<ApiChatPage> createState() => _ApiChatPageState();
}

class _ApiChatPageState extends ConsumerState<ApiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadMessages(silent: true);
    });
    debugPrint('📡 [ApiChat] Started polling every 2s');
  }

  String get _target => widget.participantType == 'pharmacy' ? 'pharmacy' : 'courier';

  Future<void> _loadMessages({bool silent = false}) async {
    if (widget.deliveryId == null) {
      if (mounted && !silent) setState(() => _isLoading = false);
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/customer/deliveries/${widget.deliveryId}/chat',
      );

      if (!mounted) return;

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        final messages = data.map((e) => ChatMessage.fromJson(e)).toList();
        
        // Filter messages for this conversation
        final filteredMessages = messages.where((m) {
          // Show messages TO me (customer) or FROM me
          return m.target == 'customer' || 
                 m.target == 'all' || 
                 m.target == _target ||
                 m.senderType == 'customer';
        }).toList();

        setState(() {
          _messages = filteredMessages;
          _isLoading = false;
          _error = null;
        });

        if (!silent && _messages.isNotEmpty) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('❌ [ApiChat] Error: $e');
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = 'Erreur de chargement';
          _isLoading = false;
        });
      }
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
    if (message.isEmpty || _isSending || widget.deliveryId == null) return;

    setState(() => _isSending = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/customer/deliveries/${widget.deliveryId}/chat',
        data: {
          'message': message,
          'target': _target,
        },
      );

      if (response.data['success'] == true) {
        _controller.clear();
        await _loadMessages(); // Refresh immediately
        _scrollToBottom();
      } else {
        if (mounted) {
          AppSnackbar.error(context, 'Erreur d\'envoi');
        }
      }
    } catch (e) {
      debugPrint('❌ [ApiChat] Send error: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Erreur d\'envoi');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.participantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.participantType == 'courier' ? 'Livreur' : 'Pharmacie',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.participantPhone != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _callParticipant,
            ),
          // Indicateur de polling actif
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.wifi,
              size: 16,
              color: _pollingTimer?.isActive == true ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _buildMessagesList(),
          ),
          // Input
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyez un message pour démarrer la conversation',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        // Reverse order for display
        final message = _messages[_messages.length - 1 - index];
        final isMe = message.senderType == 'customer';
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
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
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              message.content,
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
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[500],
                  ),
                ),
                // Indicateur de lecture pour mes messages
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
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

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
