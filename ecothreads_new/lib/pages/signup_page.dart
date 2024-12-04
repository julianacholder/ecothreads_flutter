// Import necessary packages for Firebase authentication, database, and UI
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';

// StatefulWidget for user registration
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // State variables for form management
  String? errorMessage = ''; // Store error messages
  bool _obscurePassword = true; // Toggle password visibility
  bool _isLoading = false; // Track registration progress

  // Controllers for form input fields
  final TextEditingController _controllerFullName = TextEditingController();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final AuthService _authService = AuthService();

  // Clean up controllers when widget is disposed
  @override
  void dispose() {
    _controllerFullName.dispose();
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  // Validate email format using RegExp
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Handle user registration
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    // Get form values
    final fullName = _controllerFullName.text.trim();
    final username = _controllerUsername.text.trim();
    final email = _controllerEmail.text.trim();
    final password = _controllerPassword.text;

    // Validate input fields
    if (fullName.isEmpty ||
        username.isEmpty ||
        !isValidEmail(email) ||
        password.isEmpty ||
        password.length < 6) {
      setState(() {
        errorMessage =
            getValidationErrorMessage(fullName, username, email, password);
        _isLoading = false;
      });
      return;
    }

    try {
      // Create user account in Firebase Auth
      User? user =
          await _authService.registerWithEmailPassword(email, password);

      if (user != null) {
        // Store additional user data in Firestore
        bool firestoreSuccess = await _storeUserDataWithRetry(
          user,
          fullName,
          username,
          email,
        );

        if (firestoreSuccess) {
          // Navigate to main screen on success
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
              (route) => false,
              arguments: 4,
            );
          }
        } else {
          // Clean up if Firestore storage fails
          await user.delete();
          setState(() {
            errorMessage = 'Failed to create account. Please try again later.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase authentication errors
      setState(() {
        errorMessage = _getFirebaseAuthErrorMessage(e);
      });
    } catch (e) {
      // Handle general errors
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Convert Firebase error codes to user-friendly messages
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return e.message ?? 'An error occurred during registration.';
    }
  }

  // Get validation error messages for form fields
  String getValidationErrorMessage(
      String fullName, String username, String email, String password) {
    if (fullName.isEmpty) return 'Full name cannot be empty';
    if (username.isEmpty) return 'Username cannot be empty';
    if (!isValidEmail(email)) return 'Invalid email address';
    if (password.isEmpty) return 'Password cannot be empty';
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return '';
  }

  // Store user data in Firestore with retry mechanism
  Future<bool> _storeUserDataWithRetry(
      User user, String fullName, String username, String email) async {
    final firestore = FirebaseFirestore.instance;
    int retryAttempts = 3;
    int delayMilliseconds = 1000; // Start with 1 second delay

    // Retry loop for handling temporary failures
    for (int i = 0; i < retryAttempts; i++) {
      try {
        await firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      } catch (e) {
        if (i == retryAttempts - 1) {
          print('Final Firestore Error: $e');
          return false;
        }
        // Exponential backoff between retries
        await Future.delayed(Duration(milliseconds: delayMilliseconds));
        delayMilliseconds *= 2;
      }
    }
    return false;
  }

  // Widget to display error messages
  Widget _errorMessage() {
    return Text(
      errorMessage == '' ? '' : 'Error: $errorMessage',
      style: const TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo
                Center(
                  child: Image.asset(
                    'assets/images/green logo.jpg',
                    height: 60,
                  ),
                ),
                const SizedBox(height: 16),

                // Welcome title
                const Text(
                  'Welcome to EcoThreads',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Let's create your account.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                // Error message display
                _errorMessage(),
                const SizedBox(height: 16),

                // Full Name input field
                TextField(
                  controller: _controllerFullName,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Username input field
                TextField(
                  controller: _controllerUsername,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Email input field
                TextField(
                  controller: _controllerEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),

                // Password input field with visibility toggle
                TextField(
                  controller: _controllerPassword,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Terms and conditions text
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      TextSpan(text: 'By signing up you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(text: ', '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(text: ', and '),
                      TextSpan(
                        text: 'Cookie Use',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Create Account button with loading state
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black87),
                          ),
                        )
                      : const Text(
                          'Create an Account',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                const SizedBox(height: 24),

                // Login link for existing users
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
