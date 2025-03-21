// lib/auth_check.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';
import 'login_page.dart';
import 'loading_page.dart';
import 'package:ecothreads/main.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<bool> _hasSeenOnboarding() async {
    // Add artificial delay to ensure minimum loading time
    await Future.delayed(const Duration(milliseconds: 1000));
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (snapshot.hasData && snapshot.data == false) {
          return const OnboardingPage();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Use Future.delayed to ensure minimum loading time
            if (snapshot.connectionState == ConnectionState.waiting) {
              return FutureBuilder(
                future: Future.delayed(const Duration(milliseconds: 500)),
                builder: (context, _) => const LoadingPage(),
              );
            }

            final user = snapshot.data;
            if (user == null) {
              return const LoginPage();
            } else {
              return const MainScreen();
            }
          },
        );
      },
    );
  }
}
