import 'package:ecothreads/pages/settings_page.dart';
import 'pages/editprofile_page.dart';
import 'pages/messagedonor.dart';
import 'package:flutter/material.dart';
import 'pages/checkout.dart';
import 'pages/donate_page.dart';
import 'pages/home_page.dart';
import 'pages/loading_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/usermessages.dart';
import 'pages/userprofile_page.dart';
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

// Initialize Firebase and run the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

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
      // Handle dynamic route generation for main screen with tab index
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          final int? tabIndex = settings.arguments as int?;
          return MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: Provider.of<CartProvider>(context, listen: false),
              child: MainScreen(initialIndex: tabIndex ?? 0),
            ),
          );
        }
        return null;
      },
      // Define static routes for navigation
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/loading': (context) => const LoadingPage(),
        '/editprofile': (context) => const EditprofilePage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/message': (context) => MessageDonor(),
        '/settings': (context) => SettingsPage(),
        '/checkout': (context) => CheckoutPage(),
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
  }

  // List of main pages corresponding to bottom navigation items
  final List<Widget> _pages = [
    HomePage(),
    CheckoutPage(),
    DonatePage(),
    UserMessages(),
    UserProfile(),
  ];

  // Handle bottom navigation item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      extendBody: true,
      // Custom styled bottom navigation bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(44),
          child: BottomNavigationBar(
            backgroundColor: AppColors.primarylight,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
            // Define navigation items with custom icons
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.home, _selectedIndex == 0),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(
                    Icons.shopping_bag_outlined, _selectedIndex == 1),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.add, _selectedIndex == 2),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.message_outlined, _selectedIndex == 3),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.person, _selectedIndex == 4),
                label: '',
              ),
            ],
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.5),
            showUnselectedLabels: false,
            showSelectedLabels: false,
          ),
        ),
      ),
    );
  }

  // Helper method to build custom navigation icons with selection indicators
  Widget _buildIcon(IconData icon, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.05),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 26.0,
                  color: Colors.white,
                ),
                const SizedBox(height: 2.0),
                // Show dot indicator for selected items
                if (isSelected)
                  Container(
                    width: 6.0,
                    height: 5.0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(height: 2.0),
                const SizedBox(height: 2.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
