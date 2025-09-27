import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../services/database_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final SocketService _socketService = SocketService();
  
  List<Message> _messages = [];
  String? _currentGroupId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isTyping = false;

  List<Message> get messages => _messages;
  String? get currentGroupId => _currentGroupId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;

  ChatProvider() {
    _socketService.initializeSocket();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.onMessageReceived((message) {
      if (message.groupId == _currentGroupId) {
        _messages.insert(0, message);
        notifyListeners();
      }
    });

    _socketService.onTypingUpdate((data) {
      if (data['groupId'] == _currentGroupId) {
        _isTyping = data['isTyping'];
        notifyListeners();
      }
    });
  }

  Future<void> joinGroupChat(String groupId) async {
    try {
      _isLoading = true;
      _currentGroupId = groupId;
      notifyListeners();

      await _socketService.joinGroup(groupId);
      await loadMessages(groupId);
    } catch (e) {
      _errorMessage = 'Failed to join group chat: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String groupId, {int limit = 50}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _messages = await _dbService.getGroupMessages(groupId, limit: limit);
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages({int limit = 20}) async {
    if (_currentGroupId == null || _messages.isEmpty) return;

    try {
      final lastMessage = _messages.last;
      final moreMessages = await _dbService.getGroupMessages(
        _currentGroupId!,
        limit: limit,
        startAfter: lastMessage.timestamp,
      );

      _messages.addAll(moreMessages);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load more messages: $e';
    }
  }

  Future<bool> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String content,
    MessageType type = MessageType.text,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: groupId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        type: type,
        timestamp: DateTime.now(),
        attachments: attachments,
        metadata: metadata,
        replyToId: replyToId,
      );

      // Add to local list immediately for better UX
      _messages.insert(0, message);
      notifyListeners();

      // Send to server
      await _dbService.sendMessage(message);
      await _socketService.sendMessage(message);
      
      return true;
    } catch (e) {
      // Remove from local list if send failed
      _messages.removeWhere((m) => m.id == _messages.first.id);
      _errorMessage = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendSystemMessage({
    required String groupId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = Message.createSystemMessage(
        groupId: groupId,
        content: content,
        metadata: metadata,
      );

      await _dbService.sendMessage(message);
      await _socketService.sendMessage(message);
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send system message: $e';
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      await _dbService.deleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete message: $e';
      return false;
    }
  }

  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      await _dbService.updateMessage(messageId, newContent);
      
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          content: newContent,
          isEdited: true,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Failed to edit message: $e';
      return false;
    }
  }

  void updateTypingStatus(String groupId, bool isTyping) {
    _socketService.updateTypingStatus(groupId, isTyping);
  }

  void leaveGroupChat() {
    if (_currentGroupId != null) {
      _socketService.leaveGroup(_currentGroupId!);
      _currentGroupId = null;
      _messages = [];
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
}