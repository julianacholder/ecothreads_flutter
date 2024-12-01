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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: 'AIzaSyAuWA5wOuYtgUj7oAl0uBc5ziCDqy3zwhc',
    appId: '1:688046774938:android:51d354f0ff844ca47e1d23',
    messagingSenderId: '688046774938',
    projectId: 'ecothreads-b1d6e',
    storageBucket: 'ecothreads-b1d6e.appspot.com',
    authDomain: 'ecothreads-b1d6e.firebaseapp.com',
    measurementId: 'G-PFVCYKNXBD',
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoThreads',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        textTheme: GoogleFonts.nunitoSansTextTheme(),
        primaryTextTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: const LoadingPage(),
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

  final List<Widget> _pages = [
    HomePage(),
    CheckoutPage(),
    DonatePage(),
    UserMessages(),
    UserProfile(),
  ];

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
