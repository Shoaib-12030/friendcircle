import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/friend_request_model.dart';

class FriendsService {
  static const String _usersCollection = 'users';
  static const String _friendRequestsCollection = 'friend_requests';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Search users by nickname (case-insensitive)
  Future<List<User>> searchUsersByNickname(String nickname) async {
    try {
      if (nickname.trim().isEmpty) return [];

      final query = await _firestore
          .collection(_usersCollection)
          .where('nickname', isGreaterThanOrEqualTo: nickname.toLowerCase())
          .where('nickname',
              isLessThanOrEqualTo: '${nickname.toLowerCase()}\uf8ff')
          .limit(20)
          .get();

      return query.docs.map((doc) => User.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error searching users by nickname: $e');
      return [];
    }
  }

  /// Check if nickname is available during registration
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('nickname', isEqualTo: nickname.toLowerCase())
          .limit(1)
          .get();

      return query.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking nickname availability: $e');
      return false;
    }
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
      // Check if users are already friends
      final currentUser = await _firestore
          .collection(_usersCollection)
          .doc(currentUserId)
          .get();

      if (currentUser.exists) {
        final userData = User.fromMap(currentUser.data()!);
        if (userData.friendIds.contains(targetUserId)) {
          debugPrint('Users are already friends');
          return false;
        }
      }

      // Check if there's already a pending request
      final existingRequest = await _firestore
          .collection(_friendRequestsCollection)
          .where('senderId', isEqualTo: currentUserId)
          .where('receiverId', isEqualTo: targetUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        debugPrint('Friend request already exists');
        return false;
      }

      // Create friend request
      final requestId = _uuid.v4();
      final friendRequest = FriendRequest(
        id: requestId,
        senderId: currentUserId,
        senderNickname: currentUserNickname,
        senderName: currentUserName,
        senderPhotoUrl: currentUserPhotoUrl,
        receiverId: targetUserId,
        receiverNickname: targetUserNickname,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_friendRequestsCollection)
          .doc(requestId)
          .set(friendRequest.toMap());

      debugPrint('Friend request sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending friend request: $e');
      return false;
    }
  }

  /// Get pending friend requests for a user (received)
  Future<List<FriendRequest>> getPendingFriendRequests(String userId) async {
    try {
      final query = await _firestore
          .collection(_friendRequestsCollection)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FriendRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending friend requests: $e');
      return [];
    }
  }

  /// Get sent friend requests for a user
  Future<List<FriendRequest>> getSentFriendRequests(String userId) async {
    try {
      final query = await _firestore
          .collection(_friendRequestsCollection)
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => FriendRequest.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting sent friend requests: $e');
      return [];
    }
  }

  /// Accept friend request
  Future<bool> acceptFriendRequest(String requestId) async {
    try {
      final requestDoc = await _firestore
          .collection(_friendRequestsCollection)
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        debugPrint('Friend request not found');
        return false;
      }

      final request = FriendRequest.fromMap(requestDoc.data()!);

      // Update friend request status
      await _firestore
          .collection(_friendRequestsCollection)
          .doc(requestId)
          .update({
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Add each user to the other's friend list
      final batch = _firestore.batch();

      // Add receiver to sender's friends
      final senderRef =
          _firestore.collection(_usersCollection).doc(request.senderId);
      batch.update(senderRef, {
        'friendIds': FieldValue.arrayUnion([request.receiverId])
      });

      // Add sender to receiver's friends
      final receiverRef =
          _firestore.collection(_usersCollection).doc(request.receiverId);
      batch.update(receiverRef, {
        'friendIds': FieldValue.arrayUnion([request.senderId])
      });

      await batch.commit();
      debugPrint('Friend request accepted successfully');
      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      await _firestore
          .collection(_friendRequestsCollection)
          .doc(requestId)
          .update({
        'status': 'declined',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Friend request declined successfully');
      return true;
    } catch (e) {
      debugPrint('Error declining friend request: $e');
      return false;
    }
  }

  /// Block user
  Future<bool> blockUser(String currentUserId, String targetUserId) async {
    try {
      // Remove from friends if they are friends
      await removeFriend(currentUserId, targetUserId);

      // Decline any pending requests
      final pendingRequests = await _firestore
          .collection(_friendRequestsCollection)
          .where('senderId', whereIn: [currentUserId, targetUserId])
          .where('receiverId', whereIn: [currentUserId, targetUserId])
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (final doc in pendingRequests.docs) {
        batch.update(doc.reference, {
          'status': 'blocked',
          'respondedAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();

      debugPrint('User blocked successfully');
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  /// Remove friend
  Future<bool> removeFriend(String currentUserId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Remove friend from current user's friend list
      final currentUserRef =
          _firestore.collection(_usersCollection).doc(currentUserId);
      batch.update(currentUserRef, {
        'friendIds': FieldValue.arrayRemove([friendId])
      });

      // Remove current user from friend's friend list
      final friendRef = _firestore.collection(_usersCollection).doc(friendId);
      batch.update(friendRef, {
        'friendIds': FieldValue.arrayRemove([currentUserId])
      });

      await batch.commit();
      debugPrint('Friend removed successfully');
      return true;
    } catch (e) {
      debugPrint('Error removing friend: $e');
      return false;
    }
  }

  /// Get user's friends list
  Future<List<User>> getFriendsList(String userId) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!userDoc.exists) return [];

      final userData = User.fromMap(userDoc.data()!);
      if (userData.friendIds.isEmpty) return [];

      // Get friends data in chunks (Firestore has a limit of 10 items for 'in' queries)
      final List<User> friends = [];
      final friendIds = userData.friendIds;

      for (int i = 0; i < friendIds.length; i += 10) {
        final chunk = friendIds.skip(i).take(10).toList();
        final friendsQuery = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        friends.addAll(
            friendsQuery.docs.map((doc) => User.fromMap(doc.data())).toList());
      }

      return friends;
    } catch (e) {
      debugPrint('Error getting friends list: $e');
      return [];
    }
  }

  /// Get mutual friends between two users
  Future<List<User>> getMutualFriends(String userId1, String userId2) async {
    try {
      final user1Friends = await getFriendsList(userId1);
      final user2Friends = await getFriendsList(userId2);

      final user2FriendIds = user2Friends.map((u) => u.id).toSet();

      return user1Friends
          .where((friend) => user2FriendIds.contains(friend.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting mutual friends: $e');
      return [];
    }
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId1).get();

      if (!userDoc.exists) return false;

      final userData = User.fromMap(userDoc.data()!);
      return userData.friendIds.contains(userId2);
    } catch (e) {
      debugPrint('Error checking friendship status: $e');
      return false;
    }
  }

  /// Stream of friend requests (for real-time updates)
  Stream<List<FriendRequest>> streamPendingFriendRequests(String userId) {
    return _firestore
        .collection(_friendRequestsCollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FriendRequest.fromMap(doc.data()))
            .toList());
  }

  /// Stream of friends list (for real-time updates)
  Stream<List<User>> streamFriendsList(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return <User>[];

      final userData = User.fromMap(doc.data()!);
      if (userData.friendIds.isEmpty) return <User>[];

      return await getFriendsList(userId);
    });
  }
}
