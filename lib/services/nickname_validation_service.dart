import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NicknameValidationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if a nickname is available by searching ALL user documents
  /// Documents in 'users' collection are named by mobile number
  /// Each document has a 'nickname' field (stored in lowercase) that we check for uniqueness
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final normalizedNickname = _normalizeNickname(nickname);
      debugPrint('Checking availability for normalized nickname: $normalizedNickname');

      if (normalizedNickname.isEmpty) {
        debugPrint('Normalized nickname is empty, returning false');
        return false;
      }

      debugPrint('Executing Firestore query for nickname: $normalizedNickname');
      final query = await _firestore
          .collection('users')
          .where('nickname', isEqualTo: normalizedNickname)
          .limit(1)
          .get();

      final isAvailable = query.docs.isEmpty;
      debugPrint('Query result: ${query.docs.length} docs found, available: $isAvailable');
      
      return isAvailable;
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase error checking nickname availability: ${e.code} - ${e.message}');

      // Handle specific permission errors
      if (e.code == 'permission-denied') {
        debugPrint(
            'Permission denied - this is normal during registration before authentication');
        // For registration flow, we'll do client-side format validation only
        // and validate uniqueness server-side during actual registration
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking nickname availability: $e');
      return false;
    }
  }

  /// Generate professional nickname suggestions when the desired nickname is taken
  Future<List<String>> generateNicknameSuggestions(String baseNickname,
      {String? fullName}) async {
    final normalizedBase = _normalizeNickname(baseNickname);
    if (normalizedBase.isEmpty) return [];

    List<String> suggestions = [];

    // Strategy 1: Add numbers (professional style)
    for (int i = 1; i <= 99; i++) {
      final suggestion = '${normalizedBase}$i';
      if (await isNicknameAvailable(suggestion)) {
        suggestions.add(suggestion);
        if (suggestions.length >= 3) break;
      }
    }

    // Strategy 2: Add year (professional)
    final currentYear = DateTime.now().year;
    for (int year = currentYear; year >= currentYear - 5; year--) {
      final suggestion = '${normalizedBase}$year';
      if (await isNicknameAvailable(suggestion)) {
        suggestions.add(suggestion);
        if (suggestions.length >= 6) break;
      }
    }

    // Strategy 3: Add professional suffixes
    final professionalSuffixes = ['pro', 'dev', 'tech', 'official', 'real'];
    for (String suffix in professionalSuffixes) {
      final suggestion = '${normalizedBase}_$suffix';
      if (await isNicknameAvailable(suggestion)) {
        suggestions.add(suggestion);
        if (suggestions.length >= 9) break;
      }
    }

    // Strategy 4: Use initials + base nickname if full name is provided
    if (fullName != null && fullName.isNotEmpty) {
      final nameParts = fullName.trim().split(' ');
      if (nameParts.length >= 2) {
        // First name initial + base nickname
        final firstInitial = nameParts[0][0].toLowerCase();
        final suggestion1 = '${firstInitial}_$normalizedBase';
        if (await isNicknameAvailable(suggestion1)) {
          suggestions.add(suggestion1);
        }

        // Base nickname + last name initial
        final lastInitial = nameParts.last[0].toLowerCase();
        final suggestion2 = '${normalizedBase}_$lastInitial';
        if (await isNicknameAvailable(suggestion2)) {
          suggestions.add(suggestion2);
        }

        // First and last initials + base
        final suggestion3 = '${firstInitial}${lastInitial}_$normalizedBase';
        if (await isNicknameAvailable(suggestion3)) {
          suggestions.add(suggestion3);
        }
      }
    }

    // Strategy 5: Add common professional prefixes
    final professionalPrefixes = ['the', 'mr', 'ms'];
    for (String prefix in professionalPrefixes) {
      final suggestion = '${prefix}_$normalizedBase';
      if (await isNicknameAvailable(suggestion)) {
        suggestions.add(suggestion);
        if (suggestions.length >= 15) break;
      }
    }

    // Strategy 6: Character variations (professional)
    final variations = [
      '${normalizedBase}_',
      '_$normalizedBase',
      '${normalizedBase}x',
      'x$normalizedBase',
    ];

    for (String variation in variations) {
      if (await isNicknameAvailable(variation)) {
        suggestions.add(variation);
        if (suggestions.length >= 18) break;
      }
    }

    // Remove duplicates and return up to 10 best suggestions
    return suggestions.toSet().take(10).toList();
  }

  /// Get real-time nickname suggestions as user types
  Future<List<String>> getInstantSuggestions(String partialNickname,
      {String? fullName}) async {
    final normalized = _normalizeNickname(partialNickname);
    if (normalized.length < 2) return [];

    // For instant suggestions, we'll provide quick variations
    List<String> quickSuggestions = [];

    // Add numbers to current input
    for (int i = 1; i <= 5; i++) {
      final suggestion = '${normalized}$i';
      quickSuggestions.add(suggestion);
    }

    // Add current year
    final currentYear = DateTime.now().year;
    quickSuggestions.add('${normalized}$currentYear');

    // Add underscore variations
    quickSuggestions.add('${normalized}_');
    quickSuggestions.add('_$normalized');

    // Add professional suffix
    quickSuggestions.add('${normalized}_pro');

    return quickSuggestions.take(5).toList();
  }

  /// Validate nickname format and rules
  Map<String, dynamic> validateNicknameFormat(String nickname) {
    final trimmed = nickname.trim();

    if (trimmed.isEmpty) {
      return {
        'isValid': false,
        'error': 'Nickname cannot be empty',
      };
    }

    if (trimmed.length < 3) {
      return {
        'isValid': false,
        'error': 'Nickname must be at least 3 characters long',
      };
    }

    if (trimmed.length > 20) {
      return {
        'isValid': false,
        'error': 'Nickname must be less than 20 characters',
      };
    }

    // Allow letters, numbers, underscores, and hyphens only
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return {
        'isValid': false,
        'error':
            'Nickname can only contain letters, numbers, underscores, and hyphens',
      };
    }

    // Must start with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(trimmed)) {
      return {
        'isValid': false,
        'error': 'Nickname must start with a letter',
      };
    }

    // Check for reserved words
    final reservedWords = [
      'admin',
      'administrator',
      'root',
      'system',
      'support',
      'help',
      'api',
      'www',
      'mail',
      'email',
      'info',
      'contact',
      'about',
      'null',
      'undefined',
      'delete',
      'test',
      'demo'
    ];

    if (reservedWords.contains(trimmed.toLowerCase())) {
      return {
        'isValid': false,
        'error': 'This nickname is reserved and cannot be used',
      };
    }

    return {
      'isValid': true,
      'error': null,
    };
  }

  /// Normalize nickname for consistent storage and comparison
  String _normalizeNickname(String nickname) {
    return nickname.trim().toLowerCase();
  }

  /// Check if similar nicknames exist and warn user
  Future<List<String>> findSimilarNicknames(String nickname) async {
    try {
      final normalized = _normalizeNickname(nickname);
      if (normalized.length < 3) return [];

      // Search for nicknames that start with the same prefix
      final query = await _firestore
          .collection('users')
          .where('nickname', isGreaterThanOrEqualTo: normalized)
          .where('nickname', isLessThan: normalized + 'z')
          .limit(5)
          .get();

      return query.docs
          .map((doc) => doc['nickname'] as String? ?? '')
          .where((nick) => nick.isNotEmpty && nick != nickname)
          .toList();
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase error finding similar nicknames: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        debugPrint(
            'Permission denied for similar nicknames - returning empty list');
        return [];
      }
      return [];
    } catch (e) {
      debugPrint('Error finding similar nicknames: $e');
      return [];
    }
  }
}
