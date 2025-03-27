import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';

class EmailVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final AuthService _authService = AuthService();

  Future<bool> sendOTP(String email) async {
    try {
      // Check if email exists using AuthService
      final emailExists = await _authService.checkIfEmailExists(email);
      if (emailExists) {
        print('Email already exists: $email');
        return false;
      }

      // Generate new OTP
      String otp =
          (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

      // Store OTP in Firestore with transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // Delete any existing OTP first
        final otpRef =
            _firestore.collection('pending_registrations').doc(email);
        transaction.delete(otpRef);

        // Create new OTP document
        transaction.set(otpRef, {
          'otp': otp,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt':
              Timestamp.fromDate(DateTime.now().add(Duration(minutes: 5))),
          'attempts': 0
        });
      });

      // Send OTP email
      final result = await _functions.httpsCallable('sendOTPEmail').call({
        'email': email,
        'otp': otp,
      });

      if (result.data['success'] != true) {
        // Clean up if email failed to send
        await _firestore
            .collection('pending_registrations')
            .doc(email)
            .delete();
        return false;
      }

      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
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
          // Use the new method
          final userCredential =
              await _authService.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            // Create initial user document with referral code
            final referralCode =
                userCredential.user!.uid.substring(0, 8).toUpperCase();

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
              'referralCode': referralCode,
              'points': 0,
              'hasSeenReferral': false,
            });

            // Create referral prompt notification
            await _firestore.collection('notifications').add({
              'userId': userCredential.user!.uid,
              'type': 'referral_request',
              'title': 'Welcome to EcoThreads!',
              'message':
                  'Were you invited by a friend? Enter their referral code to earn points!',
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
              'needsAction': true,
              'points': 10,
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
