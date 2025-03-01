// lib/screens/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/email_verification_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String fullName;
  final String username;
  final String password;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.fullName,
    required this.username,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  String _errorMessage = '';
  int _resendTimeout = 60;
  Timer? _resendTimer;
  final _verificationService = EmailVerificationService();

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  void startResendTimer() {
    setState(() {
      _resendTimeout = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeout == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendTimeout--;
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> verifyOTP() async {
    final otp = _controllers.map((e) => e.text).join();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = await _verificationService.verifyOTPAndRegister(
        widget.email,
        otp,
        widget
            .password, // Add password as a required parameter to EmailVerificationScreen
        widget.fullName,
        widget.username,
      );

      if (user != null) {
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
          _errorMessage = 'Failed to create account. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> resendOTP() async {
    if (_resendTimeout > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _verificationService.sendOTP(widget.email);
      startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New verification code sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/greeneco.png',
                height: 60,
              ),
              const SizedBox(height: 40),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification code to:\n${widget.email}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (index == 5 && value.isNotEmpty) {
                          verifyOTP();
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                    : const Text('Verify Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _resendTimeout == 0 ? resendOTP : null,
                child: Text(
                  _resendTimeout > 0
                      ? 'Resend code in ${_resendTimeout}s'
                      : 'Resend code',
                  style: TextStyle(
                    color: _resendTimeout == 0 ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
