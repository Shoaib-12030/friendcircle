import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatRoom> _chatRooms = [];
  List<Message> _currentChatMessages = [];
  ChatRoom? _currentChatRoom;
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  Map<String, bool> _typingUsers = {}; // userId -> isTyping
  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<List<ChatRoom>>? _chatRoomsSubscription;

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  List<Message> get currentChatMessages => _currentChatMessages;
  ChatRoom? get currentChatRoom => _currentChatRoom;
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get errorMessage => _errorMessage;
  Map<String, bool> get typingUsers => _typingUsers;

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _chatRoomsSubscription?.cancel();
    super.dispose();
  }

  /// Get or create private chat with a friend
  Future<ChatRoom?> openPrivateChat({
    required String currentUserId,
    required String currentUserNickname,
    required String friendId,
    required String friendNickname,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final chatRoom = await _chatService.createOrGetPrivateChat(
        currentUserId: currentUserId,
        currentUserNickname: currentUserNickname,
        friendId: friendId,
        friendNickname: friendNickname,
      );

      if (chatRoom != null) {
        _currentChatRoom = chatRoom;
        await _startListeningToMessages(chatRoom.id);
        await markMessagesAsRead(chatRoom.id, currentUserId);
      } else {
        _errorMessage = 'Failed to open chat';
      }

      return chatRoom;
    } catch (e) {
      _errorMessage = 'Failed to open chat: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a text message
  Future<bool> sendTextMessage({
    required String chatRoomId,
    required String senderId,
    required String senderNickname,
    required String message,
    Message? replyToMessage,
  }) async {
    if (message.trim().isEmpty) return false;

    try {
      _isSendingMessage = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        messageType: MessageType.text,
        textContent: message.trim(),
        replyToMessage: replyToMessage,
      );

      if (!success) {
        _errorMessage = 'Failed to send message';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to send message: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Send an image message
  Future<bool> sendImageMessage({
    required String chatRoomId,
    required String senderId,
    required String senderNickname,
    required String imageUrl,
    String? fileName,
    String? thumbnailUrl,
    Message? replyToMessage,
  }) async {
    try {
      _isSendingMessage = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        messageType: MessageType.image,
        mediaUrl: imageUrl,
        mediaFileName: fileName,
        thumbnailUrl: thumbnailUrl,
        replyToMessage: replyToMessage,
      );

      if (!success) {
        _errorMessage = 'Failed to send image';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to send image: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Send a voice message
  Future<bool> sendVoiceMessage({
    required String chatRoomId,
    required String senderId,
    required String senderNickname,
    required String voiceUrl,
    required double duration,
    String? fileName,
    Message? replyToMessage,
  }) async {
    try {
      _isSendingMessage = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        messageType: MessageType.voice,
        mediaUrl: voiceUrl,
        mediaFileName: fileName,
        mediaDuration: duration,
        replyToMessage: replyToMessage,
      );

      if (!success) {
        _errorMessage = 'Failed to send voice message';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to send voice message: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Send a location message
  Future<bool> sendLocationMessage({
    required String chatRoomId,
    required String senderId,
    required String senderNickname,
    required LocationData locationData,
    Message? replyToMessage,
  }) async {
    try {
      _isSendingMessage = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        messageType: MessageType.location,
        locationData: locationData,
        replyToMessage: replyToMessage,
      );

      if (!success) {
        _errorMessage = 'Failed to send location';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to send location: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Send a sticker message
  Future<bool> sendStickerMessage({
    required String chatRoomId,
    required String senderId,
    required String senderNickname,
    required String stickerPackId,
    required String stickerId,
    Message? replyToMessage,
  }) async {
    try {
      _isSendingMessage = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        messageType: MessageType.sticker,
        stickerPackId: stickerPackId,
        stickerId: stickerId,
        replyToMessage: replyToMessage,
      );

      if (!success) {
        _errorMessage = 'Failed to send sticker';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to send sticker: $e';
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Load user's chat rooms (alias method for compatibility)
  Future<void> loadUserChatRooms(String userId) async {
    await loadChatRooms(userId);
  }

  /// Load user's chat rooms
  Future<void> loadChatRooms(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _chatRooms = await _chatService.getUserChatRooms(userId);

      // Start listening to real-time updates
      _startListeningToChatRooms(userId);
    } catch (e) {
      _errorMessage = 'Failed to load chat rooms: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      await _chatService.markMessagesAsRead(chatRoomId, userId);

      // Update local chat room unread count
      final chatRoomIndex =
          _chatRooms.indexWhere((room) => room.id == chatRoomId);
      if (chatRoomIndex != -1) {
        final updatedUnreadCount =
            Map<String, int>.from(_chatRooms[chatRoomIndex].unreadCount);
        updatedUnreadCount[userId] = 0;

        _chatRooms[chatRoomIndex] = _chatRooms[chatRoomIndex].copyWith(
          unreadCount: updatedUnreadCount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String chatRoomId, String messageId) async {
    try {
      final success = await _chatService.deleteMessage(chatRoomId, messageId);

      if (!success) {
        _errorMessage = 'Failed to delete message';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      return false;
    }
  }

  /// Edit a message
  Future<bool> editMessage({
    required String chatRoomId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      final success = await _chatService.editMessage(
        chatRoomId: chatRoomId,
        messageId: messageId,
        newContent: newContent,
      );

      if (!success) {
        _errorMessage = 'Failed to edit message';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to edit message: $e';
      return false;
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _chatService.updateTypingStatus(
        chatRoomId: chatRoomId,
        userId: userId,
        isTyping: isTyping,
      );

      // Update local typing status
      if (isTyping) {
        _typingUsers[userId] = true;
      } else {
        _typingUsers.remove(userId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update typing status: $e');
    }
  }

  /// Search messages in current chat
  Future<List<Message>> searchMessages(String query) async {
    if (_currentChatRoom == null || query.trim().isEmpty) return [];

    try {
      return await _chatService.searchMessages(
        chatRoomId: _currentChatRoom!.id,
        searchQuery: query.trim(),
      );
    } catch (e) {
      debugPrint('Failed to search messages: $e');
      return [];
    }
  }

  /// Archive chat room
  Future<bool> archiveChatRoom(String chatRoomId) async {
    try {
      final success = await _chatService.archiveChatRoom(chatRoomId);

      if (success) {
        _chatRooms.removeWhere((room) => room.id == chatRoomId);
        notifyListeners();
      } else {
        _errorMessage = 'Failed to archive chat';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to archive chat: $e';
      return false;
    }
  }

  /// Leave current chat (for cleanup)
  void leaveCurrentChat() {
    _messagesSubscription?.cancel();
    _currentChatRoom = null;
    _currentChatMessages = [];
    _typingUsers.clear();
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Start listening to messages for the current chat room
  Future<void> _startListeningToMessages(String chatRoomId) async {
    _messagesSubscription?.cancel();

    _messagesSubscription = _chatService.streamMessages(chatRoomId).listen(
      (messages) {
        _currentChatMessages = messages;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in messages stream: $error');
        _errorMessage = 'Failed to load messages';
        notifyListeners();
      },
    );
  }

  /// Start listening to chat rooms updates
  void _startListeningToChatRooms(String userId) {
    _chatRoomsSubscription?.cancel();

    _chatRoomsSubscription = _chatService.streamUserChatRooms(userId).listen(
      (chatRooms) {
        _chatRooms = chatRooms;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in chat rooms stream: $error');
        _errorMessage = 'Failed to load chat rooms';
        notifyListeners();
      },
    );
  }

  /// Get total unread messages count
  int getTotalUnreadCount(String userId) {
    return _chatRooms.fold<int>(0, (total, room) {
      return total + (room.unreadCount[userId] ?? 0);
    });
  }

  /// Get chat room by friend ID
  ChatRoom? getChatRoomByFriendId(String currentUserId, String friendId) {
    try {
      return _chatRooms.firstWhere((room) =>
          room.type == 'private' &&
          room.participantIds.contains(currentUserId) &&
          room.participantIds.contains(friendId));
    } catch (e) {
      return null;
    }
  }
}
