import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(const FriendCircleWebDemo());
}

class FriendCircleWebDemo extends StatelessWidget {
  const FriendCircleWebDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FriendCircle - Web Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const WebDemoHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WebDemoHome extends StatefulWidget {
  const WebDemoHome({super.key});

  @override
  State<WebDemoHome> createState() => _WebDemoHomeState();
}

class _WebDemoHomeState extends State<WebDemoHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const GroupsTab(),
    const EventsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Home Tab
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FriendCircle'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to FriendCircle!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Connect with friends, plan events, and manage expenses together.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Activity Items
            _buildActivityCard(
              icon: Icons.group_add,
              title: 'John joined Weekend Trip group',
              time: '2 hours ago',
            ),
            _buildActivityCard(
              icon: Icons.event,
              title: 'New event: Beach Party on Saturday',
              time: '4 hours ago',
            ),
            _buildActivityCard(
              icon: Icons.payment,
              title: 'Bill split for dinner - \$25.50',
              time: '1 day ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.1),
          child: Icon(icon, color: const Color(0xFF6C63FF)),
        ),
        title: Text(title),
        subtitle: Text(time, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }
}

// Groups Tab
class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGroupCard('Weekend Trip', '5 members', Icons.travel_explore),
          _buildGroupCard('Study Group', '8 members', Icons.school),
          _buildGroupCard('Fitness Club', '12 members', Icons.fitness_center),
          _buildGroupCard('Book Club', '6 members', Icons.menu_book),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Get.snackbar('Demo', 'Create group feature coming soon!'),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupCard(String name, String members, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4CAF50),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(members),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.snackbar('Demo', 'Group details feature coming soon!'),
      ),
    );
  }
}

// Events Tab
class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildEventCard('Beach Party', 'Saturday, 2 PM', 'Weekend Trip',
              Icons.beach_access),
          _buildEventCard(
              'Study Session', 'Monday, 6 PM', 'Study Group', Icons.school),
          _buildEventCard('Morning Run', 'Daily, 7 AM', 'Fitness Club',
              Icons.directions_run),
          _buildEventCard(
              'Book Discussion', 'Friday, 8 PM', 'Book Club', Icons.forum),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Get.snackbar('Demo', 'Create event feature coming soon!'),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventCard(
      String title, String time, String group, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF9800),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time),
            Text(group,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.snackbar('Demo', 'Event details feature coming soon!'),
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF6C63FF),
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Demo User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'demo@friendcircle.com',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Options
            _buildProfileOption(Icons.edit, 'Edit Profile', () {}),
            _buildProfileOption(Icons.notifications, 'Notifications', () {}),
            _buildProfileOption(Icons.privacy_tip, 'Privacy Settings', () {}),
            _buildProfileOption(Icons.help, 'Help & Support', () {}),
            _buildProfileOption(Icons.info, 'About', () {
              Get.dialog(
                AlertDialog(
                  title: const Text('About FriendCircle'),
                  content: const Text(
                    'FriendCircle Web Demo\n\n'
                    'This is a demonstration version showing the UI design. '
                    'Full Firebase functionality is available in the mobile app.\n\n'
                    'Features:\n'
                    '• Friend Management\n'
                    '• Event Planning\n'
                    '• Group Chat\n'
                    '• Expense Tracking',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            // Web Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.web, color: Colors.orange[700], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Web Demo Version',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Download the mobile app for full functionality with Firebase backend.',
                    style: TextStyle(color: Colors.orange[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C63FF)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
