# Friend Circle 🎉

An all-in-one private app for your group with registration, group creation, events, expenses, chat, and more.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 🌟 Features

### 🔑 Core Flow
- **User Registration & Login**: Email + Password, Google Sign-in, Phone OTP (Firebase Auth)
- **Profile Management**: Name, Nickname, Photo, Status
- **Friend System**: Search friends, send/accept friend requests
- **Group Management**: Create groups, invite friends, join via invite codes
- **Event Planner**: Create events, RSVP system, free date tracker
- **Expense Tracker**: Add expenses, auto-split bills, track balances
- **Group Chat**: Real-time messaging with text, images, and system messages

### 🎡 Unique Features
- **Spin-the-Wheel**: Random decision maker for groups
- **Memory Capsule**: Auto-generated monthly scrapbooks with photos and events  
- **Challenges & Leaderboards**: Group fitness, study streaks, competitions
- **Mood Board**: Anonymous emoji sharing for group support

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Authentication, Firestore, Storage, Cloud Functions)
- **State Management**: Provider + GetX
- **Real-time Communication**: Socket.io
- **UI Components**: Custom Material Design components
- **Charts**: FL Chart for expense analytics

## 📦 Dependencies

Key dependencies include:
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase integration
- `provider`, `get` - State management and navigation
- `socket_io_client` - Real-time messaging
- `image_picker`, `cached_network_image` - Image handling
- `fl_chart` - Expense charts
- `flutter_fortune_wheel` - Spin wheel feature
- `qr_code_scanner`, `qr_flutter` - QR code functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Firebase project setup
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/friend_circle.git
   cd friend_circle
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email, Google, Phone)
   - Create Firestore database
   - Enable Storage
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place them in respective platform folders

4. **Configure Firebase**
   ```bash
   # Initialize Firebase (if you have Firebase CLI)
   firebase init
   
   # Deploy Firestore rules and indexes
   firebase deploy --only firestore
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Screenshots

> Screenshots will be added once the app UI is complete

## 🏗 Project Structure

```
lib/
├── core/
│   ├── app_theme.dart          # App-wide theming
│   └── routes.dart             # Navigation routes
├── models/
│   ├── user_model.dart         # User data model
│   ├── group_model.dart        # Group data model
│   ├── event_model.dart        # Event data model
│   ├── expense_model.dart      # Expense data model
│   └── message_model.dart      # Chat message model
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   ├── user_provider.dart      # User management
│   ├── group_provider.dart     # Group management
│   └── chat_provider.dart      # Chat functionality
├── screens/
│   ├── auth/                   # Login, register, phone auth
│   ├── home/                   # Main navigation screen
│   ├── profile/                # Profile management
│   ├── friends/                # Friend management
│   ├── groups/                 # Group screens
│   ├── events/                 # Event planning
│   ├── expenses/               # Expense tracking
│   └── features/               # Unique features (spin wheel, etc.)
├── services/
│   ├── database_service.dart   # Firestore operations
│   └── socket_service.dart     # Real-time messaging
├── widgets/
│   ├── custom_button.dart      # Reusable button component
│   └── custom_text_field.dart  # Reusable input component
└── main.dart                   # App entry point
```

## 🔥 Firebase Configuration

### Firestore Collections Structure
```
users/
  - id, email, name, nickname, photoUrl, status, friendIds, groupIds

groups/
  - id, name, description, photoUrl, adminIds, memberIds, inviteCode

messages/
  - id, groupId, senderId, content, type, timestamp, attachments

events/
  - id, title, description, location, startDate, groupId, attendeeIds

expenses/
  - id, title, amount, groupId, paidBy, splitBetween, category, date

friend_requests/
  - fromUserId, toUserId, status, createdAt
```

### Security Rules
Firestore security rules are configured to:
- Allow users to read/write their own data
- Restrict group data to group members only
- Secure chat messages to group participants

## 🌐 API Integration

The app uses Firebase for most backend operations, but you can extend it with:
- Custom Cloud Functions for complex logic
- Third-party APIs for location services
- Payment gateways for expense settlements

## 🧪 Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📱 Building for Production

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- Your Name - [@yourusername](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for seamless backend integration
- Material Design for UI components
- Open source contributors

## 📞 Support

If you have any questions or run into issues, please:
1. Check the [Issues](https://github.com/yourusername/friend_circle/issues) page
2. Create a new issue with detailed description
3. Join our community discussions

---

Made with ❤️ using Flutter