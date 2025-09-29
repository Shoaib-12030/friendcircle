import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static const String _keyPrefix = 'chat_key_';
  static const String _masterKeyName = 'master_encryption_key';

  static EncryptionService? _instance;
  static EncryptionService get instance => _instance ??= EncryptionService._();

  EncryptionService._();

  /// Initialize encryption service with master key
  Future<void> initialize() async {
    try {
      await _getMasterKey();
      debugPrint('Encryption service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize encryption service: $e');
      rethrow;
    }
  }

  /// Get or create master encryption key
  Future<String> _getMasterKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? masterKey = prefs.getString(_masterKeyName);

    if (masterKey == null) {
      // Generate new master key
      final key = encrypt.Key.fromSecureRandom(32);
      masterKey = key.base64;
      await prefs.setString(_masterKeyName, masterKey);
      debugPrint('Generated new master encryption key');
    }

    return masterKey;
  }

  /// Generate encryption key for a chat room
  Future<String> generateChatRoomKey(String chatRoomId) async {
    try {
      final key = encrypt.Key.fromSecureRandom(32);
      final keyId = '${_keyPrefix}$chatRoomId';

      // Store the key locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyId, key.base64);

      debugPrint('Generated encryption key for chat room: $chatRoomId');
      return key.base64;
    } catch (e) {
      debugPrint('Failed to generate chat room key: $e');
      rethrow;
    }
  }

  /// Get encryption key for a chat room
  Future<encrypt.Key?> getChatRoomKey(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyId = '${_keyPrefix}$chatRoomId';
      final keyString = prefs.getString(keyId);

      if (keyString != null) {
        return encrypt.Key.fromBase64(keyString);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get chat room key: $e');
      return null;
    }
  }

  /// Encrypt message content
  Future<Map<String, String>> encryptMessage({
    required String content,
    required String chatRoomId,
  }) async {
    try {
      encrypt.Key? chatKey = await getChatRoomKey(chatRoomId);

      // If no key exists for this chat room, generate one
      if (chatKey == null) {
        final keyString = await generateChatRoomKey(chatRoomId);
        chatKey = encrypt.Key.fromBase64(keyString);
      }

      // Create encrypter with chat-specific key
      final chatEncrypter = encrypt.Encrypter(encrypt.AES(chatKey));
      final iv = encrypt.IV.fromSecureRandom(16);

      // Encrypt the content
      final encrypted = chatEncrypter.encrypt(content, iv: iv);

      return {
        'encryptedContent': encrypted.base64,
        'iv': iv.base64,
        'keyId': chatRoomId,
      };
    } catch (e) {
      debugPrint('Failed to encrypt message: $e');
      rethrow;
    }
  }

  /// Decrypt message content
  Future<String?> decryptMessage({
    required String encryptedContent,
    required String ivString,
    required String chatRoomId,
  }) async {
    try {
      final chatKey = await getChatRoomKey(chatRoomId);
      if (chatKey == null) {
        debugPrint('No encryption key found for chat room: $chatRoomId');
        return null;
      }

      // Create encrypter with chat-specific key
      final chatEncrypter = encrypt.Encrypter(encrypt.AES(chatKey));
      final iv = encrypt.IV.fromBase64(ivString);
      final encrypted = encrypt.Encrypted.fromBase64(encryptedContent);

      // Decrypt the content
      final decrypted = chatEncrypter.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      debugPrint('Failed to decrypt message: $e');
      return null;
    }
  }

  /// Generate key for sharing with new chat participants
  /// This would typically be done through a secure key exchange protocol
  Future<String> generateSharedKey(
      String chatRoomId, List<String> participantIds) async {
    try {
      // In a real implementation, you would use a proper key exchange protocol
      // like Diffie-Hellman or Signal Protocol
      // For now, we'll generate a shared key and store it locally

      final key = encrypt.Key.fromSecureRandom(32);
      final keyId = '${_keyPrefix}$chatRoomId';

      // Store the key locally for this user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyId, key.base64);

      // In a real app, you would securely share this key with other participants
      // through their public keys or a key server

      debugPrint('Generated shared key for chat room: $chatRoomId');
      return key.base64;
    } catch (e) {
      debugPrint('Failed to generate shared key: $e');
      rethrow;
    }
  }

  /// Delete encryption key for a chat room (when leaving chat)
  Future<void> deleteChatRoomKey(String chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyId = '${_keyPrefix}$chatRoomId';
      await prefs.remove(keyId);
      debugPrint('Deleted encryption key for chat room: $chatRoomId');
    } catch (e) {
      debugPrint('Failed to delete chat room key: $e');
    }
  }

  /// Generate hash for message integrity verification
  String generateMessageHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify message integrity
  bool verifyMessageHash(String content, String hash) {
    final generatedHash = generateMessageHash(content);
    return generatedHash == hash;
  }

  /// Clear all encryption keys (for logout/reset)
  Future<void> clearAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      // Also remove master key
      await prefs.remove(_masterKeyName);
      debugPrint('Cleared all encryption keys');
    } catch (e) {
      debugPrint('Failed to clear encryption keys: $e');
    }
  }
}
