import 'package:ecothreads/pages/settings_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/editprofile_page.dart';
import 'pages/messagedonor.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'pages/checkout.dart';
import 'pages/donate_page.dart';
import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/usermessages.dart';
import 'pages/userprofile_page.dart';
import 'pages/notifications_page.dart';
import 'services/notification_service.dart';
import 'pages/onboarding_page.dart';
import 'constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widget_tree.dart';
import 'auth_service.dart';
import '../pages/card_provider.dart';
import 'package:provider/provider.dart';
import 'pages/messagedonor.dart';
import './pages/auth_check.dart'; // Import the AuthCheck widget
import './models/cart_item.dart'; // Add this import
import 'pages/notifications_page.dart';
import 'services/messaging_service.dart';

// Initialize Firebase and run the app
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Initialize App Check
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  }

  // Initialize Firebase Messaging
  await MessagingService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

// Main app widget defining theme and routes
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoThreads',
      // Set up app theme with Nunito Sans font
      theme: ThemeData(
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        primaryTextTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: const AuthCheck(), // Use AuthCheck as the home widget
      // Update the route generation to use safe navigation
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          final int? tabIndex = settings.arguments as int?;
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ChangeNotifierProvider.value(
              value: Provider.of<CartProvider>(context, listen: false),
              child: MainScreen(initialIndex: tabIndex ?? 0),
            ),
            transitionDuration: const Duration(milliseconds: 300),
          );
        }
        // Add safe navigation for other routes
        switch (settings.name) {
          case '/login':
            return _buildPageRoute(const LoginPage());
          case '/signup':
            return _buildPageRoute(const SignUpPage());
          case '/loading':
            return _buildPageRoute(const LoadingPage());
          case '/editprofile':
            return _buildPageRoute(const EditprofilePage());
          case '/onboarding':
            return _buildPageRoute(const OnboardingPage());
          case '/message':
            return _buildPageRoute(MessageDonor());
          case '/settings':
            return _buildPageRoute(SettingsPage());
          case '/checkout':
            return _buildPageRoute(CheckoutPage());
          default:
            return null;
        }
      },
    );
  }

  PageRouteBuilder _buildPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

// Widget for main screen with bottom navigation
class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    // Initialize notification service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initialize(context);
    });
  }

  @override
  void dispose() {
    NotificationService.dispose();
    super.dispose();
  }

  // List of main pages corresponding to bottom navigation items
  final List<Widget> _pages = [
    HomePage(),
    NotificationsPage(), // Replace CheckoutPage with NotificationsPage
    DonatePage(),
    UserMessages(),
    UserProfile(),
  ];

  // Handle bottom navigation item selection
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevent unnecessary rebuilds

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMessagesIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants',
              arrayContains: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = false;
        int unreadCount = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['hasUnreadMessages'] == true &&
                data['lastSenderId'] !=
                    FirebaseAuth.instance.currentUser?.uid) {
              hasUnread = true;
              unreadCount += (data['unreadCount'] ?? 0) as int;
            }
          }
        }

        return Stack(
          clipBehavior: Clip.none, // Allow badge to overflow
          children: [
            Icon(
              _selectedIndex == 3
                  ? Icons.chat_bubble
                  : Icons.chat_bubble_outline,
              size: 26,
            ),
            if (hasUnread)
              Positioned(
                right: -2,
                top: -4, // Changed from 0 to -8 to move badge up
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationsIcon() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Icon(Icons.notifications_none);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Icon(Icons.notifications_none);

        // Filter out message notifications from the count
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] as String?;

          // Exclude 'new_message' and 'chat_started' notifications from count
          return type != 'new_message' && type != 'chat_started';
        }).toList();

        final unreadCount = filteredDocs.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              unreadCount > 0 || _selectedIndex == 1
                  ? Icons.notifications
                  : Icons.notifications_none,
              size: 26,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                _selectedIndex == 0
                    ? Icons.grid_view
                    : Icons.grid_view_outlined,
                size: 28,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationsIcon(),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _selectedIndex == 2 ? Colors.black : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 28,
                  color: _selectedIndex == 2 ? Colors.white : Colors.black,
                ),
              ),
              label: 'Donate',
            ),
            BottomNavigationBarItem(
              icon: _buildMessagesIcon(), // Use the new method here
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: _selectedIndex == 4
                      ? Border.all(color: Colors.black, width: 1.5)
                      : null,
                ),
                child: ClipOval(
                  child: _getUserProfileImage(),
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getUserProfileImage() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data?.data() != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final profileImageUrl = userData['profileImageUrl'];

          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            return CachedNetworkImage(
              imageUrl: profileImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Icon(
                Icons.person_outline,
                size: 28,
                color: _selectedIndex == 4 ? Colors.black : Colors.grey,
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.person_outline,
                size: 28,
                color: _selectedIndex == 4 ? Colors.black : Colors.grey,
              ),
            );
          }
        }

        return Icon(
          Icons.person_outline,
          size: 28,
          color: _selectedIndex == 4 ? Colors.black : Colors.grey,
        );
      },
    );
  }
}
