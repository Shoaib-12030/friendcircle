import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'core/routes.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/group_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (conditionally for web compatibility)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    if (kIsWeb) {
      debugPrint('Running in web mode - some Firebase features may be limited');
    }
  }

  runApp(const FriendCircleApp());
}

class FriendCircleApp extends StatelessWidget {
  const FriendCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: GetMaterialApp(
        title: 'Friend Circle',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        getPages: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
