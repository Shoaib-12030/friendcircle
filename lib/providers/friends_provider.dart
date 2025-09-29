import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';
import '../services/friends_service.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendsService _friendsService = FriendsService();

  List<User> _searchResults = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _sentRequests = [];
  List<User> _friendsList = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<User> get searchResults => _searchResults;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<User> get friendsList => _friendsList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Search users by nickname
  Future<void> searchUsers(String nickname) async {
    if (nickname.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _searchResults = await _friendsService.searchUsersByNickname(nickname);
    } catch (e) {
      _errorMessage = 'Failed to search users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  /// Send friend request
  Future<bool> sendFriendRequest({
    required String currentUserId,
    required String currentUserNickname,
    required String currentUserName,
    String? currentUserPhotoUrl,
    required String targetUserId,
    required String targetUserNickname,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _friendsService.sendFriendRequest(
        currentUserId: currentUserId,
        currentUserNickname: currentUserNickname,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
        targetUserId: targetUserId,
        targetUserNickname: targetUserNickname,
      );

      if (success) {
        // Refresh sent requests
        await getSentFriendRequests(currentUserId);
      } else {
        _errorMessage = 'Failed to send friend request';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to send friend request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get pending friend requests
  Future<void> getPendingFriendRequests(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _pendingRequests = await _friendsService.getPendingFriendRequests(userId);
    } catch (e) {
      _errorMessage = 'Failed to load friend requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get sent friend requests
  Future<void> getSentFriendRequests(String userId) async {
    try {
      _sentRequests = await _friendsService.getSentFriendRequests(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load sent requests: $e');
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId, String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _friendsService.acceptFriendRequest(requestId);

      if (success) {
        // Remove from pending requests
        _pendingRequests.removeWhere((request) => request.id == requestId);
        // Refresh friends list
        await getFriendsList(userId);
      } else {
        _errorMessage = 'Failed to accept friend request';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to accept friend request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _friendsService.declineFriendRequest(requestId);

      if (success) {
        // Remove from pending requests
        _pendingRequests.removeWhere((request) => request.id == requestId);
      } else {
        _errorMessage = 'Failed to decline friend request';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to decline friend request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get friends list
  Future<void> getFriendsList(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _friendsList = await _friendsService.getFriendsList(userId);
    } catch (e) {
      _errorMessage = 'Failed to load friends list: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String currentUserId, String friendId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success =
          await _friendsService.removeFriend(currentUserId, friendId);

      if (success) {
        // Remove from friends list
        _friendsList.removeWhere((friend) => friend.id == friendId);
      } else {
        _errorMessage = 'Failed to remove friend';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to remove friend: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Block user
  Future<bool> blockUser(String currentUserId, String targetUserId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success =
          await _friendsService.blockUser(currentUserId, targetUserId);

      if (success) {
        // Remove from friends list if present
        _friendsList.removeWhere((friend) => friend.id == targetUserId);
        // Remove from pending requests
        _pendingRequests.removeWhere((request) =>
            request.senderId == targetUserId ||
            request.receiverId == targetUserId);
        // Remove from sent requests
        _sentRequests.removeWhere((request) =>
            request.senderId == targetUserId ||
            request.receiverId == targetUserId);
      } else {
        _errorMessage = 'Failed to block user';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to block user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if nickname is available
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      return await _friendsService.isNicknameAvailable(nickname);
    } catch (e) {
      debugPrint('Error checking nickname availability: $e');
      return false;
    }
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      return await _friendsService.areFriends(userId1, userId2);
    } catch (e) {
      debugPrint('Error checking friendship status: $e');
      return false;
    }
  }

  /// Get mutual friends
  Future<List<User>> getMutualFriends(String userId1, String userId2) async {
    try {
      return await _friendsService.getMutualFriends(userId1, userId2);
    } catch (e) {
      debugPrint('Error getting mutual friends: $e');
      return [];
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all data for a user
  Future<void> refreshData(String userId) async {
    await Future.wait([
      getPendingFriendRequests(userId),
      getSentFriendRequests(userId),
      getFriendsList(userId),
    ]);
  }

  /// Listen to real-time updates for friend requests
  void startListeningToFriendRequests(String userId) {
    _friendsService.streamPendingFriendRequests(userId).listen(
      (requests) {
        _pendingRequests = requests;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in friend requests stream: $error');
        _errorMessage = 'Failed to load friend requests';
        notifyListeners();
      },
    );
  }

  /// Listen to real-time updates for friends list
  void startListeningToFriendsList(String userId) {
    _friendsService.streamFriendsList(userId).listen(
      (friends) {
        _friendsList = friends;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error in friends list stream: $error');
        _errorMessage = 'Failed to load friends list';
        notifyListeners();
      },
    );
  }

  /// Open chat with a friend
  void openChat(User friend) {
    // This method will be called from the UI to navigate to chat
    // The actual navigation will be handled in the UI component
    // This is just a placeholder for any additional logic needed
    debugPrint('Opening chat with ${friend.nickname}');
  }
}
