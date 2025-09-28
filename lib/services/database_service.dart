import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../models/event_model.dart';
import '../models/expense_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Operations
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return User.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<List<User>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    
    final List<User> users = [];
    // Firestore 'in' queries are limited to 10 items
    const batchSize = 10;
    
    for (int i = 0; i < userIds.length; i += batchSize) {
      final batch = userIds.skip(i).take(batchSize).toList();
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      users.addAll(snapshot.docs.map((doc) => User.fromMap(doc.data())));
    }
    
    return users;
  }

  Future<List<User>> searchUsers(String query) async {
    final List<User> results = [];
    
    // Search by name
    final nameQuery = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .limit(20)
        .get();
    
    results.addAll(nameQuery.docs.map((doc) => User.fromMap(doc.data())));
    
    // Search by nickname
    final nicknameQuery = await _firestore
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: query)
        .where('nickname', isLessThan: '${query}z')
        .limit(20)
        .get();
    
    results.addAll(nicknameQuery.docs.map((doc) => User.fromMap(doc.data())));
    
    // Search by email
    if (query.contains('@')) {
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: query)
          .limit(20)
          .get();
      
      results.addAll(emailQuery.docs.map((doc) => User.fromMap(doc.data())));
    }
    
    // Remove duplicates
    final Map<String, User> uniqueUsers = {};
    for (final user in results) {
      uniqueUsers[user.id] = user;
    }
    
    return uniqueUsers.values.toList();
  }

  // Friend Operations
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _firestore.collection('friend_requests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<User>> getFriendRequests(String userId) async {
    final snapshot = await _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    final fromUserIds = snapshot.docs.map((doc) => doc.data()['fromUserId'] as String).toList();
    return getUsersByIds(fromUserIds);
  }

  Future<void> acceptFriendRequest(String userId, String friendId) async {
    // Update both users' friend lists
    await _firestore.runTransaction((transaction) async {
      final userDoc = _firestore.collection('users').doc(userId);
      final friendDoc = _firestore.collection('users').doc(friendId);
      
      transaction.update(userDoc, {
        'friendIds': FieldValue.arrayUnion([friendId])
      });
      
      transaction.update(friendDoc, {
        'friendIds': FieldValue.arrayUnion([userId])
      });
    });
    
    // Update friend request status
    final requestQuery = await _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: friendId)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    for (final doc in requestQuery.docs) {
      await doc.reference.update({'status': 'accepted'});
    }
  }

  Future<void> declineFriendRequest(String userId, String friendId) async {
    final requestQuery = await _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: friendId)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .get();
    
    for (final doc in requestQuery.docs) {
      await doc.reference.update({'status': 'declined'});
    }
  }

  Future<void> removeFriend(String userId, String friendId) async {
    await _firestore.runTransaction((transaction) async {
      final userDoc = _firestore.collection('users').doc(userId);
      final friendDoc = _firestore.collection('users').doc(friendId);
      
      transaction.update(userDoc, {
        'friendIds': FieldValue.arrayRemove([friendId])
      });
      
      transaction.update(friendDoc, {
        'friendIds': FieldValue.arrayRemove([userId])
      });
    });
  }

  // Group Operations
  Future<void> createGroup(Group group) async {
    await _firestore.collection('groups').doc(group.id).set(group.toMap());
    
    // Update all members' group lists
    for (final memberId in group.memberIds) {
      await _firestore.collection('users').doc(memberId).update({
        'groupIds': FieldValue.arrayUnion([group.id])
      });
    }
  }

  Future<Group?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (doc.exists) {
      return Group.fromMap(doc.data()!);
    }
    return null;
  }

  Future<Group?> getGroupByInviteCode(String inviteCode) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return Group.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Future<List<Group>> getUserGroups(String userId) async {
    final snapshot = await _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .get();
    
    return snapshot.docs.map((doc) => Group.fromMap(doc.data())).toList();
  }

  Future<void> updateGroup(Group group) async {
    await _firestore.collection('groups').doc(group.id).update(group.toMap());
  }

  Future<void> addGroupMember(String groupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final groupDoc = _firestore.collection('groups').doc(groupId);
      final userDoc = _firestore.collection('users').doc(userId);
      
      transaction.update(groupDoc, {
        'memberIds': FieldValue.arrayUnion([userId])
      });
      
      transaction.update(userDoc, {
        'groupIds': FieldValue.arrayUnion([groupId])
      });
    });
  }

  Future<void> removeGroupMember(String groupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final groupDoc = _firestore.collection('groups').doc(groupId);
      final userDoc = _firestore.collection('users').doc(userId);
      
      transaction.update(groupDoc, {
        'memberIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId])
      });
      
      transaction.update(userDoc, {
        'groupIds': FieldValue.arrayRemove([groupId])
      });
    });
  }

  // Event Operations
  Future<void> createEvent(Event event) async {
    await _firestore.collection('events').doc(event.id).set(event.toMap());
  }

  Future<Event?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (doc.exists) {
      return Event.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<Event>> getGroupEvents(String groupId) async {
    final snapshot = await _firestore
        .collection('events')
        .where('groupId', isEqualTo: groupId)
        .orderBy('startDate', descending: false)
        .get();
    
    return snapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
  }

  Future<void> updateEvent(Event event) async {
    await _firestore.collection('events').doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  // Expense Operations
  Future<void> createExpense(Expense expense) async {
    await _firestore.collection('expenses').doc(expense.id).set(expense.toMap());
  }

  Future<Expense?> getExpense(String expenseId) async {
    final doc = await _firestore.collection('expenses').doc(expenseId).get();
    if (doc.exists) {
      return Expense.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<Expense>> getGroupExpenses(String groupId) async {
    final snapshot = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList();
  }

  Future<void> updateExpense(Expense expense) async {
    await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  // Message Operations
  Future<void> sendMessage(Message message) async {
    await _firestore.collection('messages').doc(message.id).set(message.toMap());
  }

  Future<List<Message>> getGroupMessages(String groupId, {int limit = 50, DateTime? startAfter}) async {
    Query query = _firestore
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
  }

  Future<void> updateMessage(String messageId, String newContent) async {
    await _firestore.collection('messages').doc(messageId).update({
      'content': newContent,
      'isEdited': true,
    });
  }

  // Stream Operations for Real-time Updates
  Stream<List<Message>> getGroupMessagesStream(String groupId) {
    return _firestore
        .collection('messages')
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList()
        );
  }

  Stream<List<Group>> getUserGroupsStream(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Group.fromMap(doc.data())).toList()
        );
  }
}