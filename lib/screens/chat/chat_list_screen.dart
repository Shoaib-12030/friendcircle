import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_models.dart';
import '../../core/app_theme.dart';
import '../../core/routes.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await chatProvider.loadUserChatRooms(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archived Chats'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Chat Settings'),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading && chatProvider.chatRooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.chatRooms.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadChatRooms,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chatProvider.chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = chatProvider.chatRooms[index];
                return _buildChatTile(chatRoom);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to friends screen to start new chat
          Get.toNamed('/friends');
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation with your friends',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Get.toNamed('/friends');
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Find Friends'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(ChatRoom chatRoom) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser!.id;

    // Get friend info for private chats
    String friendId = '';
    String friendName = 'Unknown';
    String friendNickname = '';

    if (chatRoom.type == 'private') {
      friendId = chatRoom.participantIds.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );

      if (chatRoom.participantNicknames.containsKey(friendId)) {
        friendNickname = chatRoom.participantNicknames[friendId]!;
        friendName = friendNickname; // Use nickname as display name for now
      }
    } else {
      friendName = chatRoom.groupName ?? 'Group Chat';
    }

    final hasUnreadMessages = (chatRoom.unreadCount[currentUserId] ?? 0) > 0;
    final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              backgroundImage: chatRoom.type == 'group'
                  ? null
                  : null, // TODO: Add profile image support
              child: Text(
                chatRoom.type == 'group'
                    ? friendName.isNotEmpty
                        ? friendName[0].toUpperCase()
                        : 'G'
                    : friendName.isNotEmpty
                        ? friendName[0].toUpperCase()
                        : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            if (hasUnreadMessages)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                friendName,
                style: TextStyle(
                  fontWeight:
                      hasUnreadMessages ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chatRoom.lastMessage != null)
              Text(
                _formatMessageTime(chatRoom.lastMessage!.sentAt),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      hasUnreadMessages ? AppTheme.primaryColor : Colors.grey,
                  fontWeight:
                      hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chatRoom.type == 'private' && friendNickname.isNotEmpty) ...[
              Text(
                '@$friendNickname',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
            ],
            if (chatRoom.lastMessage != null)
              Row(
                children: [
                  if (chatRoom.lastMessage!.senderId == currentUserId)
                    Icon(
                      _getMessageStatusIcon(chatRoom.lastMessage!.status),
                      size: 14,
                      color: Colors.grey,
                    ),
                  if (chatRoom.lastMessage!.senderId == currentUserId)
                    const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _getLastMessagePreview(chatRoom.lastMessage!),
                      style: TextStyle(
                        fontSize: 14,
                        color: hasUnreadMessages ? Colors.black87 : Colors.grey,
                        fontWeight: hasUnreadMessages
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              const Text(
                'No messages yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
        onTap: () => _openChat(chatRoom, friendId, friendName, friendNickname),
        onLongPress: () => _showChatOptions(chatRoom),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getLastMessagePreview(Message message) {
    if (message.isDeleted) {
      return 'This message was deleted';
    }

    switch (message.type) {
      case MessageType.text:
        return message.textContent ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.voice:
        return '🎙️ Voice message';
      case MessageType.location:
        return '📍 Location';
      case MessageType.sticker:
        return '😊 Sticker';
      case MessageType.document:
        return '📄 Document';
      default:
        return 'Message';
    }
  }

  IconData _getMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  void _openChat(ChatRoom chatRoom, String friendId, String friendName,
      String friendNickname) {
    Get.toNamed(
      AppRoutes.chat,
      arguments: {
        'chatRoomId': chatRoom.id,
        'friendId': friendId,
        'friendName': friendName,
        'friendNickname': friendNickname,
        'friendPhotoUrl': null, // TODO: Add profile photo support
      },
    );
  }

  void _showChatOptions(ChatRoom chatRoom) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_off),
              title: const Text('Mute notifications'),
              onTap: () {
                Get.back();
                _muteChat(chatRoom);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: const Text('Archive chat'),
              onTap: () {
                Get.back();
                _archiveChat(chatRoom);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete chat'),
              onTap: () {
                Get.back();
                _deleteChat(chatRoom);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Search Chats'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            // TODO: Implement chat search
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'archived':
        // TODO: Show archived chats
        Get.snackbar(
          'Feature Coming Soon',
          'Archived chats will be available in the next update',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        break;
      case 'settings':
        // TODO: Show chat settings
        Get.snackbar(
          'Feature Coming Soon',
          'Chat settings will be available in the next update',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        break;
    }
  }

  Future<void> _muteChat(ChatRoom chatRoom) async {
    // TODO: Implement mute functionality
    Get.snackbar(
      'Chat Muted',
      'You will not receive notifications for this chat',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  Future<void> _archiveChat(ChatRoom chatRoom) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Archive Chat'),
            content: const Text('Are you sure you want to archive this chat?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Archive',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      final success = await chatProvider.archiveChatRoom(chatRoom.id);
      if (success) {
        Get.snackbar(
          'Chat Archived',
          'Chat has been archived',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _deleteChat(ChatRoom chatRoom) async {
    final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text(
              'Are you sure you want to delete this chat? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child:
                    const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      // TODO: Implement delete chat functionality
      Get.snackbar(
        'Feature Coming Soon',
        'Delete chat functionality will be available in the next update',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
