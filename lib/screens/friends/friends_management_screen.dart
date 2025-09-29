import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../providers/friends_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/user_model.dart';
import '../../models/friend_request_model.dart';
import '../../core/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      friendsProvider.refreshData(authProvider.currentUser!.id);
      // Start real-time listeners
      friendsProvider
          .startListeningToFriendRequests(authProvider.currentUser!.id);
      friendsProvider.startListeningToFriendsList(authProvider.currentUser!.id);
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        Provider.of<FriendsProvider>(context, listen: false)
            .clearSearchResults();
      }
    });
  }

  void _onSearchChanged(String query) {
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);
    if (query.trim().isNotEmpty) {
      friendsProvider.searchUsers(query.trim());
    } else {
      friendsProvider.clearSearchResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by nickname...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
              )
            : const Text('Friends'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
        ],
        bottom: _isSearching
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'Friends'),
                  Tab(text: 'Requests'),
                  Tab(text: 'Sent'),
                ],
              ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildTabContent(),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton(
              onPressed: _toggleSearch,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.person_add, color: Colors.white),
            ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        if (friendsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendsProvider.searchResults.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Try searching with a different nickname',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friendsProvider.searchResults.length,
          itemBuilder: (context, index) {
            final user = friendsProvider.searchResults[index];
            return _buildUserSearchTile(user);
          },
        );
      },
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFriendsTab(),
        _buildRequestsTab(),
        _buildSentRequestsTab(),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        if (friendsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendsProvider.friendsList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No friends yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Start by searching for users to add as friends',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friendsProvider.friendsList.length,
          itemBuilder: (context, index) {
            final friend = friendsProvider.friendsList[index];
            return _buildFriendTile(friend);
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        if (friendsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendsProvider.pendingRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Friend requests will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friendsProvider.pendingRequests.length,
          itemBuilder: (context, index) {
            final request = friendsProvider.pendingRequests[index];
            return _buildRequestTile(request);
          },
        );
      },
    );
  }

  Widget _buildSentRequestsTab() {
    return Consumer<FriendsProvider>(
      builder: (context, friendsProvider, child) {
        if (friendsProvider.sentRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No sent requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Requests you send will appear here',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friendsProvider.sentRequests.length,
          itemBuilder: (context, index) {
            final request = friendsProvider.sentRequests[index];
            return _buildSentRequestTile(request);
          },
        );
      },
    );
  }

  Widget _buildUserSearchTile(User user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;

    // Don't show current user in search results
    if (user.id == currentUser.id) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('@${user.nickname}'),
        trailing: Consumer<FriendsProvider>(
          builder: (context, friendsProvider, child) {
            return ElevatedButton(
              onPressed: friendsProvider.isLoading
                  ? null
                  : () => _sendFriendRequest(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
              ),
              child: friendsProvider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add', style: TextStyle(fontSize: 12)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFriendTile(User friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          backgroundImage:
              friend.photoUrl != null ? NetworkImage(friend.photoUrl!) : null,
          child: friend.photoUrl == null
              ? Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${friend.nickname}'),
            if (friend.status?.isNotEmpty == true)
              Text(
                friend.status!,
                style:
                    const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _openChat(friend),
              icon: const Icon(Icons.chat, color: AppTheme.primaryColor),
              tooltip: 'Chat',
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove Friend'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Block User'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) =>
                  _handleFriendAction(value.toString(), friend),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTile(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          backgroundImage: request.senderPhotoUrl != null
              ? NetworkImage(request.senderPhotoUrl!)
              : null,
          child: request.senderPhotoUrl == null
              ? Text(
                  request.senderName.isNotEmpty
                      ? request.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Text(
          request.senderName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${request.senderNickname}'),
            Text(
              'Sent ${_formatDate(request.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<FriendsProvider>(
              builder: (context, friendsProvider, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: friendsProvider.isLoading
                          ? null
                          : () => _acceptRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                      ),
                      child:
                          const Text('Accept', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: friendsProvider.isLoading
                          ? null
                          : () => _declineRequest(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 32),
                      ),
                      child:
                          const Text('Decline', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestTile(FriendRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            request.receiverNickname.isNotEmpty
                ? request.receiverNickname[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('@${request.receiverNickname}'),
        subtitle: Text(
          'Sent ${_formatDate(request.createdAt)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Chip(
          label: Text('Pending', style: TextStyle(fontSize: 11)),
          backgroundColor: Colors.orange,
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  Future<void> _sendFriendRequest(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;

    final success = await friendsProvider.sendFriendRequest(
      currentUserId: currentUser.id,
      currentUserNickname: currentUser.nickname,
      currentUserName: currentUser.name,
      currentUserPhotoUrl: currentUser.photoUrl,
      targetUserId: user.id,
      targetUserNickname: user.nickname,
    );

    if (success) {
      Get.snackbar(
        'Request Sent',
        'Friend request sent to ${user.name}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        friendsProvider.errorMessage ?? 'Failed to send friend request',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);

    final success = await friendsProvider.acceptFriendRequest(
      request.id,
      authProvider.currentUser!.id,
    );

    if (success) {
      Get.snackbar(
        'Request Accepted',
        'You are now friends with ${request.senderName}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        friendsProvider.errorMessage ?? 'Failed to accept request',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _declineRequest(FriendRequest request) async {
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);

    final success = await friendsProvider.declineFriendRequest(request.id);

    if (success) {
      Get.snackbar(
        'Request Declined',
        'Friend request declined',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        friendsProvider.errorMessage ?? 'Failed to decline request',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openChat(User friend) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;

    // Navigate to chat screen
    Get.toNamed('/chat', arguments: {
      'friendId': friend.id,
      'friendNickname': friend.nickname,
      'friendName': friend.name,
      'friendPhotoUrl': friend.photoUrl,
    });

    // Open the chat room
    await chatProvider.openPrivateChat(
      currentUserId: currentUser.id,
      currentUserNickname: currentUser.nickname,
      friendId: friend.id,
      friendNickname: friend.nickname,
    );
  }

  Future<void> _handleFriendAction(String action, User friend) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final friendsProvider =
        Provider.of<FriendsProvider>(context, listen: false);
    final currentUser = authProvider.currentUser!;

    switch (action) {
      case 'remove':
        final confirmed = await _showConfirmDialog(
          'Remove Friend',
          'Are you sure you want to remove ${friend.name} from your friends?',
        );
        if (confirmed) {
          final success =
              await friendsProvider.removeFriend(currentUser.id, friend.id);
          if (success) {
            Get.snackbar(
              'Friend Removed',
              '${friend.name} has been removed from your friends',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        }
        break;
      case 'block':
        final confirmed = await _showConfirmDialog(
          'Block User',
          'Are you sure you want to block ${friend.name}? This will remove them from your friends and prevent future contact.',
        );
        if (confirmed) {
          final success =
              await friendsProvider.blockUser(currentUser.id, friend.id);
          if (success) {
            Get.snackbar(
              'User Blocked',
              '${friend.name} has been blocked',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
        break;
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
