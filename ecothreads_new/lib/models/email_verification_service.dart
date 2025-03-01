import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Send OTP only if the email is NOT registered
  Future<bool> sendOTP(String email) async {
    try {
      // 🚨 Deprecated API - Consider replacing with Identity Platform solution
      final List<String> methods =
          await _auth.fetchSignInMethodsForEmail(email);

      if (methods.isNotEmpty) {
        throw 'Email is already registered. Please use a different email.';
      }

      // ✅ Generate a 6-digit OTP
      String otp =
          (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

      // ✅ Store OTP in Firestore before sending email
      await _firestore.collection('pending_registrations').doc(email).set({
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      });

      // ✅ Send email
      final result = await _functions.httpsCallable('sendOTPEmail').call({
        'email': email,
        'otp': otp,
      });

      if (result.data['success'] != true) {
        // Cleanup Firestore if email fails
        await _firestore
            .collection('pending_registrations')
            .doc(email)
            .delete();
        throw 'Failed to send verification email.';
      }

      print("✅ OTP sent successfully to $email");
      return true; // ✅ OTP sent successfully
    } catch (e) {
      print("❌ sendOTP Error: $e");
      return false; // ✅ OTP sending failed
    }
  }

  // ✅ Verify OTP and complete registration
  Future<User?> verifyOTPAndRegister(String email, String otp, String password,
      String fullName, String username) async {
    try {
      final otpDoc =
          await _firestore.collection('pending_registrations').doc(email).get();

      if (!otpDoc.exists) {
        throw 'Verification code not found. Please request a new OTP.';
      }

      final data = otpDoc.data()!;
      final storedOTP = data['otp'] as String;
      final expiresAt = data['expiresAt'] as Timestamp;

      // ✅ Check if OTP is expired
      if (DateTime.now().isAfter(expiresAt.toDate())) {
        await _firestore
            .collection('pending_registrations')
            .doc(email)
            .delete();
        throw 'Verification code has expired. Please request a new one.';
      }

      // ✅ Check if OTP is correct
      if (otp == storedOTP) {
        // Delete OTP from Firestore before creating the account
        await _firestore
            .collection('pending_registrations')
            .doc(email)
            .delete();

        try {
          // ✅ Create Firebase Auth User
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            // ✅ Store user data in Firestore
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'fullName': fullName,
              'username': username,
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'signInMethod': 'email',
              'emailVerified': true,
              'verifiedAt': FieldValue.serverTimestamp(),
            });

            return userCredential.user;
          }
        } catch (e) {
          print('❌ User Creation Error: $e');
          throw 'Failed to create account: ${e.toString()}';
        }
      } else {
        throw 'Invalid verification code. Please try again.';
      }
    } catch (e) {
      print('❌ VerifyOTP Error: $e');
      throw 'Verification failed: ${e.toString()}';
    }

    return null;
  }
}
