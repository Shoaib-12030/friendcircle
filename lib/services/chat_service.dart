import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../services/encryption_service.dart';

class ChatService {
  static const String _chatRoomsCollection = 'chat_rooms';
  static const String _messagesCollection = 'messages';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final EncryptionService _encryptionService = EncryptionService.instance;

  /// Create or get existing private chat room between two users
  Future<ChatRoom?> createOrGetPrivateChat({
    required String currentUserId,
    required String currentUserNickname,
    required String friendId,
    required String friendNickname,
  }) async {
    try {
      // Generate consistent chat room ID for private chats
      final participantIds = [currentUserId, friendId]..sort();
      final chatRoomId = 'private_${participantIds[0]}_${participantIds[1]}';

      // Check if chat room already exists
      final existingChat = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (existingChat.exists) {
        return ChatRoom.fromMap(existingChat.data()!);
      }

      // Create new chat room
      final chatRoom = ChatRoom(
        id: chatRoomId,
        type: 'private',
        participantIds: participantIds,
        participantNicknames: {
          currentUserId: currentUserNickname,
          friendId: friendNickname,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastReadAt: {
          currentUserId: DateTime.now(),
          friendId: DateTime.now(),
        },
        unreadCount: {
          currentUserId: 0,
          friendId: 0,
        },
      );

      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .set(chatRoom.toMap());

      // Generate encryption key for this chat room
      await _encryptionService.generateChatRoomKey(chatRoomId);

      debugPrint('Created new private chat room: $chatRoomId');
      return chatRoom;
    } catch (e) {
      debugPrint('Error creating private chat: $e');
      return null;
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderNickname,
    required MessageType messageType,
    String? textContent,
    String? mediaUrl,
    String? mediaFileName,
    String? thumbnailUrl,
    double? mediaDuration,
    LocationData? locationData,
    String? stickerPackId,
    String? stickerId,
    Message? replyToMessage,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Prepare content for encryption
      String contentToEncrypt = '';
      if (textContent != null) {
        contentToEncrypt = textContent;
      } else if (mediaUrl != null) {
        contentToEncrypt = mediaUrl;
      } else if (locationData != null) {
        contentToEncrypt = '${locationData.latitude},${locationData.longitude}';
      }

      // Encrypt the message content
      final encryptionData = await _encryptionService.encryptMessage(
        content: contentToEncrypt,
        chatRoomId: chatRoomId,
      );

      final message = Message(
        id: messageId,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderNickname: senderNickname,
        type: messageType,
        textContent: textContent,
        mediaUrl: mediaUrl,
        mediaFileName: mediaFileName,
        thumbnailUrl: thumbnailUrl,
        mediaDuration: mediaDuration,
        locationData: locationData,
        stickerPackId: stickerPackId,
        stickerId: stickerId,
        replyToMessage: replyToMessage,
        encryptedContent: encryptionData['encryptedContent']!,
        encryptionKeyId: encryptionData['keyId']!,
        status: MessageStatus.sent,
        sentAt: now,
      );

      // Store message in subcollection
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      // Update chat room with last message and timestamp
      await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
        'lastMessage': message.toMap(),
        'updatedAt': now.toIso8601String(),
      });

      // Update unread count for other participants
      await _updateUnreadCounts(chatRoomId, senderId);

      debugPrint('Message sent successfully: $messageId');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Get messages for a chat room with pagination
  Future<List<Message>> getMessages({
    required String chatRoomId,
    int limit = 50,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .orderBy('sentAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.get();

      final messages = <Message>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final message = Message.fromMap(data);

        // Decrypt message content
        final decryptedContent = await _encryptionService.decryptMessage(
          encryptedContent: message.encryptedContent,
          ivString: data['iv'] ?? '',
          chatRoomId: chatRoomId,
        );

        // Update message with decrypted content
        final decryptedMessage = message.type == MessageType.text
            ? Message.fromMap(
                {...message.toMap(), 'textContent': decryptedContent})
            : message;

        messages.add(decryptedMessage);
      }

      return messages.reversed.toList(); // Return in chronological order
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  /// Stream messages for real-time updates
  Stream<List<Message>> streamMessages(String chatRoomId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .doc(chatRoomId)
        .collection(_messagesCollection)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = <Message>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final message = Message.fromMap(data);

        // Decrypt message content
        final decryptedContent = await _encryptionService.decryptMessage(
          encryptedContent: message.encryptedContent,
          ivString: data['iv'] ?? '',
          chatRoomId: chatRoomId,
        );

        // Update message with decrypted content
        final decryptedMessage = message.type == MessageType.text
            ? Message.fromMap(
                {...message.toMap(), 'textContent': decryptedContent})
            : message;

        messages.add(decryptedMessage);
      }

      return messages.reversed.toList();
    });
  }

  /// Get user's chat rooms
  Future<List<ChatRoom>> getUserChatRooms(String userId) async {
    try {
      final query = await _firestore
          .collection(_chatRoomsCollection)
          .where('participantIds', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();

      return query.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting user chat rooms: $e');
      return [];
    }
  }

  /// Stream user's chat rooms for real-time updates
  Stream<List<ChatRoom>> streamUserChatRooms(String userId) {
    return _firestore
        .collection(_chatRoomsCollection)
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromMap(doc.data())).toList());
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
        'lastReadAt.$userId': DateTime.now().toIso8601String(),
        'unreadCount.$userId': 0,
      });

      debugPrint('Messages marked as read for user: $userId');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Update message status (delivered/read)
  Future<void> updateMessageStatus({
    required String chatRoomId,
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      final timestamp = DateTime.now().toIso8601String();

      switch (status) {
        case MessageStatus.delivered:
          updateData['deliveredAt'] = timestamp;
          updateData['status'] = 'delivered';
          break;
        case MessageStatus.read:
          updateData['readAt'] = timestamp;
          updateData['status'] = 'read';
          break;
        case MessageStatus.failed:
          updateData['status'] = 'failed';
          break;
        default:
          break;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoomId)
            .collection(_messagesCollection)
            .doc(messageId)
            .update(updateData);
      }
    } catch (e) {
      debugPrint('Error updating message status: $e');
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'textContent': null,
        'mediaUrl': null,
        'encryptedContent': '', // Clear encrypted content
      });

      debugPrint('Message deleted successfully: $messageId');
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Edit message
  Future<bool> editMessage({
    required String chatRoomId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      // Encrypt new content
      final encryptionData = await _encryptionService.encryptMessage(
        content: newContent,
        chatRoomId: chatRoomId,
      );

      await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .doc(messageId)
          .update({
        'textContent': newContent,
        'encryptedContent': encryptionData['encryptedContent'],
        'isEdited': true,
        'editedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Message edited successfully: $messageId');
      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
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
      await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
        'typingUsers.$userId':
            isTyping ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Get chat room by ID
  Future<ChatRoom?> getChatRoom(String chatRoomId) async {
    try {
      final doc = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .get();

      if (doc.exists) {
        return ChatRoom.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting chat room: $e');
      return null;
    }
  }

  /// Update unread counts for participants (except sender)
  Future<void> _updateUnreadCounts(String chatRoomId, String senderId) async {
    try {
      final chatRoom = await getChatRoom(chatRoomId);
      if (chatRoom == null) return;

      final batch = _firestore.batch();
      final chatRoomRef =
          _firestore.collection(_chatRoomsCollection).doc(chatRoomId);

      for (final participantId in chatRoom.participantIds) {
        if (participantId != senderId) {
          final currentCount = chatRoom.unreadCount[participantId] ?? 0;
          batch.update(chatRoomRef, {
            'unreadCount.$participantId': currentCount + 1,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating unread counts: $e');
    }
  }

  /// Archive chat room
  Future<bool> archiveChatRoom(String chatRoomId) async {
    try {
      await _firestore.collection(_chatRoomsCollection).doc(chatRoomId).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Chat room archived: $chatRoomId');
      return true;
    } catch (e) {
      debugPrint('Error archiving chat room: $e');
      return false;
    }
  }

  /// Search messages in a chat room
  Future<List<Message>> searchMessages({
    required String chatRoomId,
    required String searchQuery,
    int limit = 20,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search on arrays
      // In a production app, you'd use Algolia or Elasticsearch
      final query = await _firestore
          .collection(_chatRoomsCollection)
          .doc(chatRoomId)
          .collection(_messagesCollection)
          .where('textContent',
              isGreaterThanOrEqualTo: searchQuery.toLowerCase())
          .where('textContent',
              isLessThanOrEqualTo: '${searchQuery.toLowerCase()}\uf8ff')
          .limit(limit)
          .get();

      final messages = <Message>[];
      for (final doc in query.docs) {
        final data = doc.data();
        final message = Message.fromMap(data);

        // Decrypt message content
        final decryptedContent = await _encryptionService.decryptMessage(
          encryptedContent: message.encryptedContent,
          ivString: data['iv'] ?? '',
          chatRoomId: chatRoomId,
        );

        if (decryptedContent
                ?.toLowerCase()
                .contains(searchQuery.toLowerCase()) ==
            true) {
          final decryptedMessage = Message.fromMap(
              {...message.toMap(), 'textContent': decryptedContent});
          messages.add(decryptedMessage);
        }
      }

      return messages;
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }
}
