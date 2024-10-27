# EcoThreads - Sustainable Fashion Exchange Platform

EcoThreads is a Flutter-based mobile application that promotes sustainable fashion through a gamified clothes exchange platform. Users can donate clothes, earn points, and acquire pre-loved items while tracking their environmental impact.

## 🚀 Features

### Core Functionality
- **User Authentication**: Secure login/signup via email, phone, or social media
- **AI-Powered Clothing Recognition**: Automatic categorization and condition assessment
- **Points System**: Earn and spend points for clothing exchange
- **Environmental Impact Tracking**: Real-time metrics on sustainability impact
- **Gamification**: Levels, achievements, and challenges
- **Educational Content**: Resources about sustainable fashion
- **Community Features**: User profiles, following system, and discussion forums

### Technical Highlights
- Firebase Authentication for secure user management
- Firebase Realtime Database for real-time data synchronization
- TensorFlow Lite for on-device image processing
- Firebase Cloud Functions for server-side operations
- Firebase Cloud Messaging for push notifications
- Firebase Analytics for usage tracking

## 📋 Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code with Flutter plugins
- Firebase CLI
- Git
- A Firebase project

## 🛠️ Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/julianacholder/ecothreads_flutter
cd ecothreads
```

### 2. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable required services:
   - Authentication
   - Realtime Database
   - Cloud Functions
   - Cloud Storage
   - Analytics
3. Download `google-services.json` for Android and `GoogleService-Info.plist` for iOS
4. Place configuration files in their respective directories:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### 3. Environment Configuration
1. Create a `.env` file in the project root:
```
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Configure Firebase CLI
```bash
firebase login
firebase init
```

### 6. Run the App
```bash
flutter run
```

## 📱 App Structure

```
lib/
├── main.dart
├── config/
├── models/
├── services/
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── image_recognition_service.dart
│   └── notification_service.dart
├── screens/
├── widgets/
└── utils/
```

## 🔧 Configuration

### Firebase Configuration
1. Update Firebase configuration in `lib/config/firebase_config.dart`
2. Enable required authentication methods in Firebase Console
3. Set up Firebase Security Rules for Realtime Database

### Image Recognition Setup
1. Download TensorFlow Lite model
2. Place model in `assets/ml/`
3. Update model configuration in `lib/services/image_recognition_service.dart`

## 🚦 Running Tests

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contributers
- Juliana Holder
- Ngum Dieudonne
- Ajok Atem Biar
- Philippa Giibwa
- Ayen Athiak Guech

For support, email support@ecothreads.com or join our [Discord community](https://discord.gg/ecothreads).

## 🔄 Version History

- 1.0.0
  - Initial Release
  - Core features implementation
- 1.1.0
  - Added AI-powered image recognition
  - Enhanced gamification features

## 🔮 Roadmap

- [ ] Implement AR try-on feature
- [ ] Add social sharing capabilities
- [ ] Integrate carbon footprint calculator
- [ ] Add multi-language support
- [ ] Implement in-app messaging

## 🙏 Acknowledgments

- Firebase team for excellent documentation
- Flutter community for valuable packages
- Our beta testers for their feedback

## ⚠️ Important Notes

- Ensure you have sufficient Firebase quota for your expected usage
- Keep your API keys and sensitive information secure
- Regular backups of the Firebase database are recommended
- Monitor analytics for performance optimization

For detailed documentation about specific features, please refer to our upcoming [Wiki](https://github.com/yourusername/ecothreads/wiki).
