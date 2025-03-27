import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth_service.dart';
import 'package:flutter/gestures.dart';
import '../models/email_verification_service.dart';
import './email_verification_screen.dart';

// At the top of your file, create a constant for the text
const String termsAndPrivacyText = '''
Eco Threads - Terms of Service and Privacy Policy

Terms of Service
Effective Date: February 5, 2025

Welcome to Eco Threads! By using our app, you agree to these Terms of Service. Please read them carefully.

...
1. Acceptance of Terms

By accessing or using Eco Threads, you agree to be bound by these terms. If you do not agree, please do not use the app.

2. Description of Service

Eco Threads is a platform that allows users to donate, receive, and upcycle clothing items. Users can create profiles, upload images of donated items, and interact with other users.

3. User Accounts
	•	You must be at least 13 years old to use Eco Threads.
	•	You are responsible for maintaining the confidentiality of your account information.
	•	We reserve the right to suspend or terminate accounts that violate our terms.

4. Donations and Transactions
	•	Items donated on Eco Threads should be in a usable condition.
	•	Users should ensure accurate descriptions of items before donating.
	•	Eco Threads is not responsible for any issues arising from donations or item conditions.

5. Content and Conduct
	•	Users must not post harmful, offensive, or illegal content.
	•	Spamming, harassment, or fraudulent activity is strictly prohibited.
	•	We reserve the right to remove any content that violates these terms.

6. Limitation of Liability

  Eco Threads is not responsible for:
	•	Any damage or loss related to donated items.
	•	User interactions or disputes.
	•	Technical issues or service interruptions.

7. Changes to the Terms

We may update these terms from time to time. Continued use of the app means you accept any changes.
...

Privacy Policy

Effective Date: February 5, 2025

At Eco Threads, we value your privacy. This policy explains how we collect, use, and protect your information.

1. Information We Collect

We collect the following types of data:
	•	Personal Information: Name, email, and profile details when you sign up.
	•	User Content: Images and descriptions of donated items.
	•	Usage Data: Interaction logs, device information, and analytics.

2. How We Use Your Information

We use your data to:
	•	Provide and improve the Eco Threads experience.
	•	Facilitate donations and user interactions.
	•	Communicate with users about updates and support.
	•	Monitor and enhance app security.

3. Sharing and Disclosure

We do not sell or rent your data. However, we may share it with:
	•	Service providers who help operate Eco Threads.
	•	Legal authorities if required by law.

4. Data Security

We take reasonable measures to protect your data from unauthorized access. However, no system is completely secure, and we cannot guarantee absolute protection.

5. Your Rights
    You have the right to:
      •	Access and update your personal data.
      •	Request data deletion.
      •	Opt out of certain data collection practices.

6. Changes to This Policy

We may update this Privacy Policy from time to time. Continued use of Eco Threads after changes means you accept the updated policy.

7. Contact Us

If you have any questions about these terms or our privacy policy, please contact us at info.ecothreads@gmail.com

...
By using Eco Threads, you acknowledge that you have read and agree to these Terms of Service and Privacy Policy.
''';

// Method to show the dialog
void _showTermsAndPrivacy(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500), // Set max height
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms & Privacy Policy',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    termsAndPrivacyText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String? errorMessage = '';
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _controllerFullName = TextEditingController();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _controllerFullName.dispose();
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        await _storeUserDataWithRetry(
          user,
          user.displayName ?? '',
          user.email?.split('@')[0] ?? '',
          user.email ?? '',
          isGoogleSignIn: true,
        );

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main',
            (route) => false,
            arguments: 4,
          );
        }
      } else {
        setState(() {
          errorMessage = 'Google sign in failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred during Google sign in.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    final fullName = _controllerFullName.text.trim();
    final username = _controllerUsername.text.trim();
    final email = _controllerEmail.text.trim();
    final password = _controllerPassword.text;

    // Basic validation
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
      // Check if email exists first
      bool emailExists = await _authService.checkIfEmailExists(email);

      if (emailExists) {
        setState(() {
          errorMessage =
              'This email is already registered. Please try logging in instead.';
          _isLoading = false;
        });
        return;
      }

      // Send OTP only if email doesn't exist
      final verificationService = EmailVerificationService();
      bool otpSent = await verificationService.sendOTP(email);

      if (!otpSent) {
        setState(() {
          errorMessage = 'Failed to send verification code. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // Navigate to verification screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: email,
              password: password,
              fullName: fullName,
              username: username,
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Registration Error: $e");
      setState(() {
        errorMessage =
            'An error occurred during registration. Please try again.';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add new method for error message display
  Widget _buildErrorMessage() {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update error message helper
  String _getSignUpErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email. Please try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Please choose a stronger password. Use at least 6 characters with a mix of letters and numbers.';
      default:
        return 'Sign up failed. Please check your information and try again.';
    }
  }

  // Update sign up method
  Future<void> _signUp() async {
    setState(() {
      errorMessage = '';
      _isLoading = true;
    });

    // Validation checks
    if (_controllerFullName.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Please enter your full name';
        _isLoading = false;
      });
      return;
    }

    if (!isValidEmail(_controllerEmail.text.trim())) {
      setState(() {
        errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    if (_controllerPassword.text.length < 6) {
      setState(() {
        errorMessage = 'Password must be at least 6 characters long';
        _isLoading = false;
      });
      return;
    }

    try {
      // Attempt signup
      User? user = await _authService.signUpWithEmailAndPassword(
        _controllerEmail.text.trim(),
        _controllerPassword.text,
        _controllerFullName.text.trim(),
      );

      if (user != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = _getSignUpErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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

  Future<bool> _storeUserDataWithRetry(
      User user, String fullName, String username, String email,
      {bool isGoogleSignIn = false}) async {
    final firestore = FirebaseFirestore.instance;
    int retryAttempts = 3;
    int delayMilliseconds = 1000;

    for (int i = 0; i < retryAttempts; i++) {
      try {
        await firestore.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'signInMethod': isGoogleSignIn ? 'google' : 'email',
          'photoURL': isGoogleSignIn ? user.photoURL : null,
        });
        return true;
      } catch (e) {
        if (i == retryAttempts - 1) {
          print('Final Firestore Error: $e');
          return false;
        }
        await Future.delayed(Duration(milliseconds: delayMilliseconds));
        delayMilliseconds *= 2;
      }
    }
    return false;
  }

  late final List<TapGestureRecognizer> _recognizers;

  @override
  void initState() {
    super.initState();
    _recognizers = List.generate(3, (_) => TapGestureRecognizer());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo
                Center(
                  child: Image.asset(
                    'assets/images/greeneco.png',
                    height: 60,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Welcome to EcoThreads',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  "Let's create your account.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildErrorMessage(),
                const SizedBox(height: 20),

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
                const SizedBox(height: 8),

                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    children: [
                      const TextSpan(text: 'By signing up you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showTermsAndPrivacy(context),
                      ),
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showTermsAndPrivacy(context),
                      ),
                      const TextSpan(text: ', and '),
                      TextSpan(
                        text: 'Cookie Use',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showTermsAndPrivacy(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                const SizedBox(height: 16),

                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                // Google Sign In Button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                  ),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
