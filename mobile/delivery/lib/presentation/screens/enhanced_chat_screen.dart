import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/enhanced_chat_service.dart';
import '../../data/models/enhanced_chat_message.dart';
import '../widgets/chat/enhanced_chat_widgets.dart';
import '../widgets/common/common_widgets.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ÉCRAN DE CHAT ENRICHI
// ══════════════════════════════════════════════════════════════════════════════

class EnhancedChatScreen extends ConsumerStatefulWidget {
  final int orderId;
  final String target; // 'pharmacy' ou 'customer'
  final String targetName;
  final String? targetAvatar;
  final String? targetPhone;

  const EnhancedChatScreen({
    super.key,
    required this.orderId,
    required this.target,
    required this.targetName,
    this.targetAvatar,
    this.targetPhone,
  });

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  bool _isFirstLoad = true;
  int? _courierId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    // Arrêter l'indicateur de saisie quand on quitte
    // Wrap dans try-catch car le ProviderContainer peut être en cours de destruction
    try {
      ref.read(enhancedChatServiceProvider).stopTyping(widget.orderId, widget.target);
    } catch (_) {
      // Ignorer les erreurs de ref.read() pendant le dispose
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await ref.read(enhancedChatServiceProvider).markMessagesAsRead(
            widget.orderId,
            widget.target,
          );
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // La liste est inversée, donc 0 = bas
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final messagesAsync = ref.watch(
      enhancedMessagesProvider((orderId: widget.orderId, target: widget.target)),
    );
    final typingAsync = ref.watch(
      typingStatusProvider((orderId: widget.orderId, target: widget.target)),
    );

    // Obtenir l'ID du livreur depuis le profil
    // Pour simplifier, on utilise une valeur fictive ici
    _courierId ??= 1;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (_isFirstLoad && messages.isNotEmpty) {
                  _isFirstLoad = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                if (messages.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final previousMessage =
                              index < messages.length - 1 ? messages[index + 1] : null;
                          final showDateSeparator = _shouldShowDateSeparator(
                            message,
                            previousMessage,
                          );

                          return Column(
                            children: [
                              if (showDateSeparator)
                                _DateSeparator(date: message.createdAt),
                              EnhancedMessageBubble(
                                message: message,
                                courierId: _courierId ?? 1,
                                onLongPress: () =>
                                    _showMessageOptions(context, message),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Indicateur de saisie
                    typingAsync.when(
                      data: (typingStatus) {
                        if (typingStatus != null) {
                          return TypingIndicator(name: typingStatus.senderName);
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const AppLoadingWidget(),
              error: (e, _) => AppErrorWidget(
                message: 'Erreur: $e',
                onRetry: () => ref.invalidate(
                  enhancedMessagesProvider(
                      (orderId: widget.orderId, target: widget.target)),
                ),
              ),
            ),
          ),

          // Zone de saisie
          EnhancedChatInput(
            orderId: widget.orderId,
            target: widget.target,
            onSendText: (text) => _sendTextMessage(text),
            onSendLocation: () => _sendLocation(),
            onTypingStart: () => ref
                .read(enhancedChatServiceProvider)
                .startTyping(widget.orderId, widget.target),
            onTypingStop: () => ref
                .read(enhancedChatServiceProvider)
                .stopTyping(widget.orderId, widget.target),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isDark ? Colors.white : Colors.black,
      elevation: 1,
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor:
                (widget.target == 'customer' ? Colors.green : Colors.orange)
                    .withValues(alpha: 0.2),
            backgroundImage: widget.targetAvatar != null
                ? CachedNetworkImageProvider(widget.targetAvatar!)
                : null,
            child: widget.targetAvatar == null
                ? Icon(
                    widget.target == 'customer'
                        ? Icons.person
                        : Icons.local_pharmacy,
                    size: 18,
                    color: widget.target == 'customer'
                        ? Colors.green
                        : Colors.orange,
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.target == 'customer' ? 'Client' : 'Pharmacie',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Appel
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _makeCall(),
          tooltip: 'Appeler',
        ),
        // Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _confirmClearChat();
                break;
              case 'report':
                _reportConversation();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Effacer la conversation'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.flag_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Signaler'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF54AB70).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Color(0xFF54AB70),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez un message pour commencer la conversation',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Suggestions de messages rapides
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _QuickStartChip(
                text: 'Bonjour! 👋',
                onTap: () => _sendTextMessage('Bonjour! 👋'),
              ),
              _QuickStartChip(
                text: 'Je suis en route',
                onTap: () => _sendTextMessage('Je suis en route !'),
              ),
              _QuickStartChip(
                text: 'Je suis arrivé',
                onTap: () => _sendTextMessage('Je suis arrivé'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(
    EnhancedChatMessage current,
    EnhancedChatMessage? previous,
  ) {
    if (previous == null) return true;

    final currentDate = DateTime(
      current.createdAt.year,
      current.createdAt.month,
      current.createdAt.day,
    );
    final previousDate = DateTime(
      previous.createdAt.year,
      previous.createdAt.month,
      previous.createdAt.day,
    );

    return currentDate != previousDate;
  }

  Future<void> _sendTextMessage(String text) async {
    try {
      await ref.read(enhancedChatServiceProvider).sendTextMessage(
            orderId: widget.orderId,
            content: text,
            target: widget.target,
          );
      if (mounted) _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendLocation() async {
    try {
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition();

      await ref.read(enhancedChatServiceProvider).sendLocationMessage(
            orderId: widget.orderId,
            latitude: position.latitude,
            longitude: position.longitude,
            target: widget.target,
            address: 'Ma position actuelle',
          );
      if (mounted) _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur localisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageOptions(BuildContext context, EnhancedChatMessage message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copier'),
                onTap: () {
                  Navigator.pop(context);
                  _copyToClipboard(message.content);
                },
              ),
              if (message.isFromCourier(_courierId ?? 1))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Copier le contenu dans le presse-papier
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copié dans le presse-papier'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Supprimer un message
  Future<void> _deleteMessage(EnhancedChatMessage message) async {
    try {
      await ref.read(enhancedChatServiceProvider).deleteMessage(
        widget.orderId,
        widget.target,
        message.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message supprimé'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _makeCall() async {
    final phone = widget.targetPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone non disponible'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de passer l\'appel'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer la conversation ?'),
        content: const Text(
            'Cette action supprimera tous les messages de cette conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearConversation();
            },
            child: const Text('Effacer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearConversation() async {
    try {
      await ref.read(enhancedChatServiceProvider).clearConversation(
        widget.orderId,
        widget.target,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation effacée'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _reportConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler cette conversation'),
        content: const Text(
            'Êtes-vous sûr de vouloir signaler cette conversation pour comportement inapproprié ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReport();
            },
            child: const Text('Signaler', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    try {
      await ref.read(enhancedChatServiceProvider).reportConversation(
        widget.orderId,
        widget.target,
        widget.targetName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé. Merci pour votre retour.'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signalement envoyé'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIAIRES
// ══════════════════════════════════════════════════════════════════════════════

/// Séparateur de date
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  String get _label {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Aujourd\'hui';
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Chip de démarrage rapide
class _QuickStartChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickStartChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onTap,
      backgroundColor: const Color(0xFF54AB70).withValues(alpha: 0.1),
      side: BorderSide(
        color: const Color(0xFF54AB70).withValues(alpha: 0.3),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// LISTE DES CONVERSATIONS
// ══════════════════════════════════════════════════════════════════════════════

/// Écran listant toutes les conversations actives
class ConversationsListScreen extends ConsumerWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final conversationsAsync = ref.watch(activeConversationsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnhancedChatScreen(
                        orderId: conversation.orderId,
                        target: conversation.target,
                        targetName: conversation.targetName,
                        targetAvatar: conversation.targetAvatar,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (e, _) => AppErrorWidget(
          message: 'Erreur: $e',
          onRetry: () => ref.invalidate(activeConversationsProvider),
        ),
      ),
    );
  }
}

/// Tuile de conversation
class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCustomer = conversation.target == 'customer';

    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                (isCustomer ? Colors.green : Colors.orange).withValues(alpha: 0.2),
            backgroundImage: conversation.targetAvatar != null
                ? CachedNetworkImageProvider(conversation.targetAvatar!)
                : null,
            child: conversation.targetAvatar == null
                ? Icon(
                    isCustomer ? Icons.person : Icons.local_pharmacy,
                    color: isCustomer ? Colors.green : Colors.orange,
                  )
                : null,
          ),
          if (conversation.isTyping)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.targetName,
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            _formatTime(conversation.updatedAt),
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0
                  ? const Color(0xFF54AB70)
                  : Colors.grey,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              'Commande #${conversation.orderId}',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF54AB70),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${time.day}/${time.month}';
  }
}
