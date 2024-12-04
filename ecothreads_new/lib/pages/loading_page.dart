import 'package:flutter/material.dart';

// StatefulWidget for displaying a loading screen with logo and progress indicator
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the widget is fully built
    // before starting navigation timer. This prevents potential
    // issues with context usage during widget initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToOnboarding();
    });
  }

  // Delayed navigation to onboarding screen
  Future<void> _navigateToOnboarding() async {
    // Wait for 3 seconds to show loading animation
    await Future.delayed(const Duration(seconds: 3));
    // Check if widget is still mounted to prevent navigation
    // after widget disposal
    if (!mounted) return;

    // Replace current route with onboarding page
    // using pushReplacementNamed to prevent back navigation
    Navigator.of(context).pushReplacementNamed('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set background color to brand green
      backgroundColor: const Color(0xFF16A637),
      body: Stack(
        children: [
          // Center logo in the middle of the screen
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display app logo with fixed dimensions
                Image.asset(
                  'assets/images/loadinglogo.png',
                  height: 250,
                  width: 350,
                ),
              ],
            ),
          ),
          // Position loading indicator at bottom of screen
          const Positioned(
            bottom: 40, // Distance from bottom
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: CircularProgressIndicator(
                    // White color for progress indicator
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 5, // Thickness of progress indicator
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
