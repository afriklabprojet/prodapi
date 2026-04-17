import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

/// Modèle simple de message chat
class SimpleChatMessage {
  final String id;
  final String content;
  final String senderType;
  final String senderId;
  final bool isMine;
  final DateTime timestamp;
  final bool isRead;

  SimpleChatMessage({
    required this.id,
    required this.content,
    required this.senderType,
    required this.senderId,
    required this.isMine,
    required this.timestamp,
    this.isRead = false,
  });

  factory SimpleChatMessage.fromJson(Map<String, dynamic> json) {
    // Supporte le format avec sender.type ou sender_type
    final senderType = json['sender'] is Map
        ? json['sender']['type']?.toString() ?? ''
        : json['sender_type']?.toString() ?? '';
    final senderId = json['sender'] is Map
        ? json['sender']['id']?.toString() ?? ''
        : json['sender_id']?.toString() ?? '';
    return SimpleChatMessage(
      id: json['id']?.toString() ?? '',
      content: json['message'] ?? json['content'] ?? '',
      senderType: senderType,
      senderId: senderId,
      isMine: json['is_mine'] == true,
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] == true,
    );
  }
}

/// Chat page utilisant uniquement l'API HTTP (pas de Firestore)
/// Polling toutes les 2 secondes pour le temps réel
class ApiChatScreen extends ConsumerStatefulWidget {
  final int orderId;
  final int? deliveryId;
  final String target; // 'pharmacy' ou 'customer'
  final String targetName;
  final String? targetPhone;

  const ApiChatScreen({
    super.key,
    required this.orderId,
    this.deliveryId,
    required this.target,
    required this.targetName,
    this.targetPhone,
  });

  @override
  ConsumerState<ApiChatScreen> createState() => _ApiChatScreenState();
}

class _ApiChatScreenState extends ConsumerState<ApiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  List<SimpleChatMessage> _messages = [];
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
    debugPrint('📡 [ApiChat] Started polling every 2s for order ${widget.orderId}');
  }

  Future<void> _loadMessages({bool silent = false}) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(
        '/courier/orders/${widget.deliveryId ?? widget.orderId}/messages',
        queryParameters: {'target': widget.target},
      );

      if (!mounted) return;

      final List<dynamic> data = response.data?['data'] ?? response.data?['messages'] ?? [];
      final messages = data.map((e) => SimpleChatMessage.fromJson(e)).toList();

      // Trier par date
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _messages = messages;
        _isLoading = false;
        _error = null;
      });

      if (!silent && _messages.isNotEmpty) {
        _scrollToBottom();
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
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post(
        '/courier/orders/${widget.deliveryId ?? widget.orderId}/messages',
        data: {
          'message': message,
          'target': widget.target,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _controller.clear();
        await _loadMessages();
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur d\'envoi')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [ApiChat] Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur d\'envoi')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _callParticipant() async {
    if (widget.targetPhone == null) return;
    final uri = Uri.parse('tel:${widget.targetPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.targetName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.target == 'customer' ? 'Client' : 'Pharmacie',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.targetPhone != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _callParticipant,
            ),
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
          Expanded(child: _buildMessagesList(isDark)),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
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
            Text('Aucun message', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Envoyez un message pour démarrer',
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
        final message = _messages[_messages.length - 1 - index];
        final isMe = message.isMine;
        return _buildMessageBubble(message, isMe, isDark);
      },
    );
  }

  Widget _buildMessageBubble(SimpleChatMessage message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.brandPrimary
              : isDark
                  ? Colors.grey[800]
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
                  message.senderType == 'customer' ? 'Client' : 'Pharmacie',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : isDark
                        ? Colors.white
                        : Colors.black87,
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
                    color: isMe
                        ? Colors.white70
                        : isDark
                            ? Colors.grey[500]
                            : Colors.grey[500],
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

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
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
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
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
              color: AppColors.brandPrimary,
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
