import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<User> _friends = [];
  List<User> _friendRequests = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get friends => _friends;
  List<User> get friendRequests => _friendRequests;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFriends(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _dbService.getUser(userId);
      if (user != null) {
        _friends = await _dbService.getUsersByIds(user.friendIds);
      }
    } catch (e) {
      _errorMessage = 'Failed to load friends: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFriendRequests(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _friendRequests = await _dbService.getFriendRequests(userId);
    } catch (e) {
      _errorMessage = 'Failed to load friend requests: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      _searchResults = await _dbService.searchUsers(query);
    } catch (e) {
      _errorMessage = 'Failed to search users: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.sendFriendRequest(fromUserId, toUserId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send friend request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptFriendRequest(String userId, String friendId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.acceptFriendRequest(userId, friendId);
      await loadFriends(userId);
      await loadFriendRequests(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to accept friend request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> declineFriendRequest(String userId, String friendId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.declineFriendRequest(userId, friendId);
      await loadFriendRequests(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to decline friend request: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.removeFriend(userId, friendId);
      await loadFriends(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove friend: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}