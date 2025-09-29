import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_models.dart';
import '../../core/app_theme.dart';
import '../../widgets/media_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Map<String, dynamic> chatData;
  Message? _replyToMessage;

  @override
  void initState() {
    super.initState();
    chatData = Get.arguments as Map<String, dynamic>;
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Leave current chat when screen is disposed
    Provider.of<ChatProvider>(context, listen: false).leaveCurrentChat();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;

    await chatProvider.openPrivateChat(
      currentUserId: currentUser.id,
      currentUserNickname: currentUser.nickname,
      friendId: chatData['friendId'],
      friendNickname: chatData['friendNickname'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: chatData['friendPhotoUrl'] != null
                  ? NetworkImage(chatData['friendPhotoUrl'])
                  : null,
              child: chatData['friendPhotoUrl'] == null
                  ? Text(
                      chatData['friendName']?.isNotEmpty == true
                          ? chatData['friendName'][0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatData['friendName'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '@${chatData['friendNickname']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement voice call
            },
            icon: const Icon(Icons.phone),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement video call
            },
            icon: const Icon(Icons.videocam),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Search Messages'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive),
                    SizedBox(width: 8),
                    Text('Archive Chat'),
                  ],
                ),
              ),
            ],
            onSelected: _handleMenuAction,
          ),
        ],
      ),
      body: Column(
        children: [
          // Reply to message bar
          if (_replyToMessage != null) _buildReplyBar(),

          // Messages list
          Expanded(child: _buildMessagesList()),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyToMessage!.senderNickname}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _replyToMessage!.textContent ?? 'Media message',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyToMessage = null;
              });
            },
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading &&
            chatProvider.currentChatMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.currentChatMessages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start the conversation!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: chatProvider.currentChatMessages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.currentChatMessages[index];
            final isCurrentUser = message.senderId ==
                Provider.of<AuthProvider>(context, listen: false)
                    .currentUser!
                    .id;

            return _buildMessageBubble(message, isCurrentUser);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isCurrentUser),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryColor,
                backgroundImage: chatData['friendPhotoUrl'] != null
                    ? NetworkImage(chatData['friendPhotoUrl'])
                    : null,
                child: chatData['friendPhotoUrl'] == null
                    ? Text(
                        message.senderNickname.isNotEmpty
                            ? message.senderNickname[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Reply message if any
                  if (message.replyToMessage != null)
                    _buildReplyPreview(message.replyToMessage!),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(message, isCurrentUser),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.sentAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getMessageStatusIcon(message.status),
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'edited',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrentUser) const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(Message replyMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMessage.senderNickname,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            replyMessage.textContent ?? 'Media message',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isCurrentUser) {
    if (message.isDeleted) {
      return Text(
        'This message was deleted',
        style: TextStyle(
          color: isCurrentUser ? Colors.white70 : Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.textContent ?? '',
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.mediaUrl ?? '',
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
            if (message.textContent?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                message.textContent!,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ],
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: isCurrentUser ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              '${(message.mediaDuration ?? 0).toInt()}s',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        );
      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: isCurrentUser ? Colors.white : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              'Location shared',
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
              ),
            ),
          ],
        );
      default:
        return Text(
          'Unsupported message type',
          style: TextStyle(
            color: isCurrentUser ? Colors.white70 : Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              onPressed: _showAttachmentOptions,
              icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return IconButton(
                  onPressed:
                      chatProvider.isSendingMessage ? null : _sendMessage,
                  icon: chatProvider.isSendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: AppTheme.primaryColor),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;
    final currentChatRoom = chatProvider.currentChatRoom;

    if (currentChatRoom == null) return;

    _messageController.clear();

    final success = await chatProvider.sendTextMessage(
      chatRoomId: currentChatRoom.id,
      senderId: currentUser.id,
      senderNickname: currentUser.nickname,
      message: message,
      replyToMessage: _replyToMessage,
    );

    if (success) {
      // Clear reply
      setState(() {
        _replyToMessage = null;
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      Get.snackbar(
        'Error',
        chatProvider.errorMessage ?? 'Failed to send message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showAttachmentOptions() async {
    final result = await showMediaPicker();
    if (result != null) {
      await _handleMediaAttachment(result);
    }
  }

  Future<void> _handleMediaAttachment(Map<String, dynamic> result) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;
    final currentChatRoom = chatProvider.currentChatRoom;

    if (currentChatRoom == null) return;

    final type = result['type'] as String;

    switch (type) {
      case 'image':
        final file = result['file'];
        if (file != null) {
          // TODO: Implement image message sending
          Get.snackbar(
            'Feature Coming Soon',
            'Image sending will be available in the next update',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
        break;
      case 'video':
        final file = result['file'];
        if (file != null) {
          // TODO: Implement video message sending
          Get.snackbar(
            'Feature Coming Soon',
            'Video sending will be available in the next update',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
        break;
      case 'voice':
        // TODO: Implement voice recording
        Get.snackbar(
          'Feature Coming Soon',
          'Voice messages will be available in the next update',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        break;
      case 'location':
        final latitude = result['latitude'] as double;
        final longitude = result['longitude'] as double;

        final locationData = LocationData(
          latitude: latitude,
          longitude: longitude,
          address: 'Current Location', // TODO: Get actual address
        );

        final success = await chatProvider.sendLocationMessage(
          chatRoomId: currentChatRoom.id,
          senderId: currentUser.id,
          senderNickname: currentUser.nickname,
          locationData: locationData,
        );

        if (!success) {
          Get.snackbar(
            'Error',
            chatProvider.errorMessage ?? 'Failed to send location',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
        break;
      case 'sticker':
        // TODO: Implement sticker picker
        Get.snackbar(
          'Feature Coming Soon',
          'Stickers will be available in the next update',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        break;
      case 'document':
        final file = result['file'];
        if (file != null) {
          // TODO: Implement document message sending
          Get.snackbar(
            'Feature Coming Soon',
            'Document sending will be available in the next update',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
        break;
      case 'contact':
        // TODO: Implement contact sharing
        Get.snackbar(
          'Feature Coming Soon',
          'Contact sharing will be available in the next update',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        break;
    }
  }

  void _showMessageOptions(Message message, bool isCurrentUser) {
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
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Get.back();
                setState(() {
                  _replyToMessage = message;
                });
              },
            ),
            if (isCurrentUser && message.type == MessageType.text) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Get.back();
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Get.back();
                  _deleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editMessage(Message message) {
    _messageController.text = message.textContent ?? '';
    // TODO: Implement message editing
  }

  Future<void> _deleteMessage(Message message) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentChatRoom = chatProvider.currentChatRoom;

    if (currentChatRoom == null) return;

    final success = await chatProvider.deleteMessage(
      currentChatRoom.id,
      message.id,
    );

    if (success) {
      Get.snackbar(
        'Message Deleted',
        'Message has been deleted',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        chatProvider.errorMessage ?? 'Failed to delete message',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        // TODO: Implement message search
        break;
      case 'archive':
        _archiveChat();
        break;
    }
  }

  Future<void> _archiveChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentChatRoom = chatProvider.currentChatRoom;

    if (currentChatRoom == null) return;

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
      final success = await chatProvider.archiveChatRoom(currentChatRoom.id);
      if (success) {
        Get.back(); // Go back to friends screen
        Get.snackbar(
          'Chat Archived',
          'Chat has been archived',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }
}
