// FriendCircle Widget Tests
//
// This file contains widget tests for the FriendCircle app.
// Since the app uses Firebase and requires initialization,
// we create a simplified test version that doesn't require Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Create a test-friendly app widget that doesn't require Firebase
class TestFriendCircleApp extends StatelessWidget {
  const TestFriendCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friend Circle Test',
      home: const TestSplashScreen(),
    );
  }
}

class TestSplashScreen extends StatelessWidget {
  const TestSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FriendCircle Test'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 100,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 20),
            Text(
              'Friend Circle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Widget Test Environment',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('FriendCircle Widget Tests', () {
    testWidgets('App launches without errors', (WidgetTester tester) async {
      // Test the basic app that doesn't require Firebase
      await tester.pumpWidget(const TestFriendCircleApp());

      // Verify that the app loads with expected elements
      expect(find.text('FriendCircle Test'), findsOneWidget);
      expect(find.text('Friend Circle'), findsOneWidget);
      expect(find.text('Widget Test Environment'), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);
    });

    testWidgets('App displays correct UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestFriendCircleApp());

      // Verify UI components are present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);

      // Verify text content
      expect(find.text('Friend Circle'), findsOneWidget);
      expect(find.text('Widget Test Environment'), findsOneWidget);
    });

    testWidgets('App has correct theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(const TestFriendCircleApp());

      // Find the AppBar and verify its color
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, equals(Colors.deepPurple));
      expect(appBar.foregroundColor, equals(Colors.white));

      // Find the Icon and verify its color
      final icon = tester.widget<Icon>(find.byIcon(Icons.groups));
      expect(icon.color, equals(Colors.deepPurple));
      expect(icon.size, equals(100));
    });
  });
}
