import 'package:ecothreads/pages/checkout.dart';
import 'package:ecothreads/pages/donate_page.dart';
import 'package:ecothreads/pages/home_page.dart';
import 'package:ecothreads/pages/loading_page.dart';
import 'package:ecothreads/pages/login_page.dart';
import 'package:ecothreads/pages/onboarding_page.dart';
import 'package:ecothreads/pages/usermessages.dart';
import 'package:ecothreads/pages/userprofile_page.dart';
import 'package:flutter/material.dart';
import 'constants/colors.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
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
        // This ensures even the primary theme text uses Nunito Sans
        primaryTextTheme: GoogleFonts.nunitoSansTextTheme(),
      ),
      home: const MainScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/loading': (context) => LoadingPage(),
        '/donate': (context) => const DonatePage(),
        '/usermessages': (context) => const UserMessages(),
        '/userprofile': (context) => const UserProfile(),
        '/checkout': (context) => CheckoutPage(),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

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


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Container(
//           decoration: BoxDecoration(
//             color: AppColors.primarylight,
//             borderRadius: BorderRadius.circular(30),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.grey.withOpacity(0.3),
//                 spreadRadius: 2,
//                 blurRadius: 10,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _buildNavItem(Icons.home_filled, 0),
//                 _buildNavItem(Icons.shopping_bag_outlined, 1),
//                 _buildNavItem(Icons.add, 2),
//                 _buildNavItem(Icons.message_outlined, 3),
//                 _buildNavItem(Icons.person_outlined, 4),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNavItem(IconData icon, int index) {
//     bool isSelected = _selectedIndex == index;

//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () => _onItemTapped(index),
//         customBorder: const CircleBorder(),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: isSelected ? AppColors.primary : Colors.white,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: isSelected
//                     ? AppColors.primary.withOpacity(0.3)
//                     : Colors.grey.withOpacity(0.1),
//                 spreadRadius: isSelected ? 2 : 1,
//                 blurRadius: isSelected ? 4 : 2,
//                 offset: isSelected ? const Offset(0, 2) : const Offset(0, 1),
//               ),
//             ],
//           ),
//           child: Icon(
//             icon,
//             color: isSelected ? Colors.white : Colors.grey,
//             size: 24,
//           ),
//         ),
//       ),
//     );
//   }
// }
