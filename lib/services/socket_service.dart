import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message_model.dart';

class SocketService {
  io.Socket? _socket;
  String? _currentUserId;

  // Socket Events
  static const String messageReceived = 'message_received';
  static const String messageSent = 'send_message';
  static const String joinGroupEvent = 'join_group';
  static const String leaveGroupEvent = 'leave_group';
  static const String typingUpdate = 'typing_update';
  static const String userOnline = 'user_online';
  static const String userOffline = 'user_offline';

  void initializeSocket({String? userId}) {
    _currentUserId = userId;

    // Initialize socket connection
    _socket = io.io(
      'http://localhost:3000', // Replace with your backend URL
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to socket server');
      if (_currentUserId != null) {
        _socket!.emit(userOnline, {'userId': _currentUserId});
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from socket server');
    });

    _socket!.onConnectError((data) {
      debugPrint('Socket connection error: $data');
    });
  }

  void disconnect() {
    if (_currentUserId != null) {
      _socket?.emit(userOffline, {'userId': _currentUserId});
    }
    _socket?.disconnect();
    _socket?.dispose();
  }

  // Group Chat Operations
  Future<void> joinGroup(String groupId) async {
    _socket?.emit(joinGroupEvent, {
      'groupId': groupId,
      'userId': _currentUserId,
    });
  }

  Future<void> leaveGroup(String groupId) async {
    _socket?.emit(leaveGroupEvent, {
      'groupId': groupId,
      'userId': _currentUserId,
    });
  }

  // Message Operations
  Future<void> sendMessage(Message message) async {
    _socket?.emit(messageSent, message.toMap());
  }

  void onMessageReceived(Function(Message) callback) {
    _socket?.on(messageReceived, (data) {
      final message = Message.fromMap(Map<String, dynamic>.from(data));
      callback(message);
    });
  }

  // Typing Indicators
  void updateTypingStatus(String groupId, bool isTyping) {
    _socket?.emit(typingUpdate, {
      'groupId': groupId,
      'userId': _currentUserId,
      'isTyping': isTyping,
    });
  }

  void onTypingUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on(typingUpdate, (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  // User Status
  void onUserStatusUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on(userOnline, (data) {
      callback(Map<String, dynamic>.from(data));
    });
    _socket?.on(userOffline, (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  // Connection Status
  bool get isConnected => _socket?.connected ?? false;

  void dispose() {
    disconnect();
  }
}
