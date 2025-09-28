import 'package:get/get.dart';
import '../screens/auth/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';

import '../screens/home/main_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/groups/groups_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/placeholder_screens.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';

  static const String main = '/main';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String friends = '/friends';
  static const String addFriend = '/add-friend';
  static const String groups = '/groups';
  static const String createGroup = '/create-group';
  static const String groupDetail = '/group-detail';
  static const String events = '/events';
  static const String createEvent = '/create-event';
  static const String eventDetail = '/event-detail';
  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String chat = '/chat';
  static const String spinWheel = '/spin-wheel';
  static const String memoryCapsule = '/memory-capsule';
  static const String challenges = '/challenges';
  static const String moodBoard = '/mood-board';

  static List<GetPage> routes = [
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(
        name: emailVerification, page: () => const EmailVerificationScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: main, page: () => const MainScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: editProfile, page: () => const EditProfileScreen()),
    GetPage(name: friends, page: () => const FriendsScreen()),
    GetPage(name: addFriend, page: () => const AddFriendScreen()),
    GetPage(name: groups, page: () => const GroupsScreen()),
    GetPage(name: createGroup, page: () => const CreateGroupScreen()),
    GetPage(
      name: groupDetail,
      page: () => const GroupDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(name: events, page: () => const EventsScreen()),
    GetPage(name: createEvent, page: () => const CreateEventScreen()),
    GetPage(
      name: eventDetail,
      page: () => const EventDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(name: expenses, page: () => const ExpensesScreen()),
    GetPage(name: addExpense, page: () => const AddExpenseScreen()),
    GetPage(
      name: chat,
      page: () => const ChatScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(name: spinWheel, page: () => const SpinWheelScreen()),
    GetPage(name: memoryCapsule, page: () => const MemoryCapsuleScreen()),
    GetPage(name: challenges, page: () => const ChallengesScreen()),
    GetPage(name: moodBoard, page: () => const MoodBoardScreen()),
  ];
}
