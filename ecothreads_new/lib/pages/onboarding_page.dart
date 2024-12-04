import 'package:flutter/material.dart';

// StatelessWidget for the onboarding/welcome screen
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Make container fill the entire screen
        width: double.infinity,
        height: double.infinity,
        // Set background image with full cover
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/hanging.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        // Wrap content in SafeArea to avoid system UI overlap
        child: SafeArea(
          child: Padding(
            // Add padding for content layout
            padding: const EdgeInsets.only(left: 24.0, right: 24, top: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main headline text
                const Text(
                  'The\nsustainable\nway to\nrefresh your\nwardrobe.',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 0.9, // Reduce space between lines
                  ),
                ),
                const SizedBox(height: 25),
                // Subtitle/tagline
                const Text(
                  'EcoThreads: Donate, earn, renew.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                // Push buttons to bottom of screen
                const Spacer(),
                // Get Started Button - White background
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Login Button - Dark background
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom padding
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
