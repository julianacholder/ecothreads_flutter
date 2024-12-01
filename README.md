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



## ecothreads Backend with Firebase
This document outlines how Firebase integrates with the various screens of the ecothreads app, providing functionalities like authentication, database management, and image storage.
Firebase is  seamlessly integrated into the ecothreads app to provide a secure, scalable backend for user authentication, data management, and image storage. Each screen interacts with Firebase services to deliver a smooth and efficient user experience.

## Firebase Services Overview
Authentication:
ecothreads app uses Email/Password Authentication,  this authentication method allows users to sign up or log in to our application using their email address and a secure password.This will ensure that  only authenticated users can read/write their profile and donation data.

## Firestore Database:

Our app is implement to use a firestore an NOSQL database to manage  structured data for screens such  as user profiles, donations, and environmental impact statistics
Firebase Storages:Our app have screens that will require images to be store and uploaded to the database and due to that we chose firebasebase storage   for storing and retrieving large files, such as images, securely and efficientlyStores images, sample screens that include user profile photos and donation item images.The authentication ensure Users can only upload and view images associated with their account.


 ## Firebase Integration in different screens
### Loading Screen:
 The firebase verifies the user's authentication state,Redirects authenticated users to their profile or unauthenticated users to the onboarding screen.

 ### Onboarding Screen:
This screen Introduces the app and its core features.and the firebase does not directly interact with it but Users proceed to login or sign-up.

### Sign-Up Screen:
This  allows users to create a new account.
The Firebase ensures that  authentication is used to register users with their email and password.once the user is registered the firestore store their basic profile information e.g name,email


### Login Screen:
It  enables users to log into their accounts.The Firebase Role is Authentication: Firebase Authentication validates the email and password. It also handles secure sessions.

### Profile Screen:
Displays the user's profile details and their donation listings.Firestore fetches user profile details (e.g., name, bio, username from the users collection.Retrieves donation listings associated with the user from the donation collection.Firebase Storage:Loads the user's profile photo from Firebase Storage using the stored URL.

### Real-Time Chat (Messages):

The Firebase ensure that the conversation between two users is store
Message Subcollection: Each conversation document has a subcollection of messages, each message with details like sender, timestamp, and text content.


### Edit Profile Screen:
Allows users to update their profile details.Firestore updates user details e.g name, bio, username, location ,Firebase Storage upload the updated profile photo to Firebase Storage and update the corresponding URL in Firestore.

### Donation Screen:
Lets users donate clothes by uploading images and providing item details  e.g item name, description
Firebase Storage Upload donation item images and stores the URL in the Firestore document.


### Settings Screen:
Allows users to manage account settings.
Authentication Provides functionality for logging out users securely.
Firestore updates privacy settings or other preferences

### Environmental Impact Screen:
Displays user stats, achievements, and activity related to their donations.Firebase Role is to fetch user-specific environmental impact data e.g., total donations, carbon savings from the database and also retrieves leaderboard data to show the user's rank compared to others.

