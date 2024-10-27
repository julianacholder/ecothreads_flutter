EcoThreads - Sustainable Fashion Exchange Platform
EcoThreads is a Flutter-based mobile application that promotes sustainable fashion through a gamified clothes exchange platform. Users can donate clothes, earn points, and acquire pre-loved items while tracking their environmental impact.
🚀 Features
Core Functionality
User Authentication: Secure login/signup via email, phone, or social media
AI-Powered Clothing Recognition: Automatic categorization and condition assessment
Points System: Earn and spend points for clothing exchange
Environmental Impact Tracking: Real-time metrics on sustainability impact
Gamification: Levels, achievements, and challenges
Educational Content: Resources about sustainable fashion
Community Features: User profiles, following system, and discussion forums
Technical Highlights
Firebase Authentication for secure user management
Firebase Realtime Database for real-time data synchronization
TensorFlow Lite for on-device image processing
Firebase Cloud Functions for server-side operations
Firebase Cloud Messaging for push notifications
Firebase Analytics for usage tracking
📋 Prerequisites
Flutter SDK (>=3.0.0)
Dart SDK (>=3.0.0)
Android Studio / VS Code with Flutter plugins
Firebase CLI
Git
A Firebase project
🛠️ Setup Instructions
1. Clone the Repository
bash
Copy
git clone https://github.com/yourusername/ecothreads.git
cd ecothreads
2. Firebase Setup
Create a new Firebase project at Firebase Console
Enable required services:
Authentication
Realtime Database
Cloud Functions
Cloud Storage
Analytics
Download google-services.json for Android and GoogleService-Info.plist for iOS
Place configuration files in their respective directories:
Android: android/app/google-services.json
iOS: ios/Runner/GoogleService-Info.plist
3. Environment Configuration
Create a .env file in the project root:
Copy
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
4. Install Dependencies
bash
Copy
flutter pub get
5. Configure Firebase CLI
bash
Copy
firebase login
firebase init
6. Run the App
bash
Copy
flutter run
📱 App Structure
Copy
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
🔧 Configuration
Firebase Configuration
Update Firebase configuration in lib/config/firebase_config.dart
Enable required authentication methods in Firebase Console
Set up Firebase Security Rules for Realtime Database
Image Recognition Setup
Download TensorFlow Lite model
Place model in assets/ml/
Update model configuration in lib/services/image_recognition_service.dart
🚦 Running Tests
bash
Copy
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
📦 Building for Production
Android
bash
Copy
flutter build apk --release
iOS
bash
Copy
flutter build ios --release
🤝 Contributing
Fork the repository
Create a feature branch
Commit changes
Push to the branch
Open a Pull Request
📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
📞 Support
For support, email support@ecothreads.com or join our Discord community.
🔄 Version History
1.0.0
Initial Release
Core features implementation
1.1.0
Added AI-powered image recognition
Enhanced gamification features
🔮 Roadmap
Implement AR try-on feature
Add social sharing capabilities
Integrate carbon footprint calculator
Add multi-language support
Implement in-app messaging
🙏 Acknowledgments
Firebase team for excellent documentation
Flutter community for valuable packages
Our beta testers for their feedback
⚠️ Important Notes
Ensure you have sufficient Firebase quota for your expected usage
Keep your API keys and sensitive information secure
Regular backups of the Firebase database are recommended
Monitor analytics for performance optimization
For detailed documentation about specific features, please refer to our Wiki.

