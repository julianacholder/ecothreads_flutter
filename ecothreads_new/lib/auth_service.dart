import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper method to save user data to Firestore
  Future<void> _saveUserToFirestore(User user,
      {String? displayName, String? username}) async {
    try {
      // Create a reference to the users collection
      final userRef = _firestore.collection('users').doc(user.uid);

      // Check if user document already exists
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        // Update only if new information is provided
        Map<String, dynamic> updateData = {};

        if (displayName != null) {
          updateData['fullName'] = displayName;
        }

        if (username != null) {
          updateData['username'] = username;
        }

        if (updateData.isNotEmpty) {
          await userRef.update(updateData);
        }
      } else {
        // Create new user document with the custom profile image field
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'fullName': displayName ?? user.displayName ?? '',
          'username': username ?? '',
          'profileImageUrl': user.photoURL, // Custom field name
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      print('User data saved to Firestore successfully');
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      throw e;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Update last login timestamp
      if (userCredential.user != null) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Email/Password Sign In Error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  Future<bool> checkIfEmailExists(String email) async {
    try {
      // First check Firebase Auth
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        return true;
      }

      // Then check Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // Check pending registrations
      final pendingDoc =
          await _firestore.collection('pending_registrations').doc(email).get();

      return userQuery.docs.isNotEmpty || pendingDoc.exists;
    } catch (e) {
      print('Error checking email existence: $e');
      rethrow;
    }
  }

  Future<User?> registerWithEmailPassword(
    String email,
    String password, {
    String? fullName,
    String? username,
  }) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (fullName != null) {
        await userCredential.user!.updateDisplayName(fullName);
      }

      await _saveUserToFirestore(
        userCredential.user!,
        displayName: fullName,
        username: username,
      );

      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In was cancelled by user');
        return null;
      }

      // Access the user's full name from the displayName property
      final String? fullName = googleUser.displayName;

      // Generate a username based on email (you can modify this logic)
      final String? email = googleUser.email;
      final String username = email != null
          ? email.split('@')[0]
          : ''; // Simple username generation

      print('User Full Name: $fullName');
      print('Generated Username: $username');

      // Obtain auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Generate referral code
        final referralCode =
            userCredential.user!.uid.substring(0, 8).toUpperCase();

        // Save user data with referral code
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'fullName': fullName,
          'username': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'signInMethod': 'google',
          'photoURL': userCredential.user!.photoURL,
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
      }

      return userCredential.user;
    } catch (e) {
      print('Google Sign In Error: $e');
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Password Reset Error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      print('Password Update Error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.updateEmail(newEmail);

      // Also update email in Firestore
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'email': newEmail});
      }
    } on FirebaseAuthException catch (e) {
      print('Email Update Error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  // Update user profile with a custom profile image field name
  Future<void> updateUserProfile(
      {String? fullName, String? username, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Update Firebase Auth displayName if provided
      if (fullName != null) {
        await user.updateDisplayName(fullName);
      }

      // Update Firestore user data with custom field name for profile image
      Map<String, dynamic> updateData = {};

      if (fullName != null) updateData['fullName'] = fullName;
      if (username != null) updateData['username'] = username;
      if (photoURL != null) updateData['profileImageUrl'] = photoURL;

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
      }
    } catch (e) {
      print('Profile Update Error: $e');
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Sign Out Error: $e');
      throw e;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore first
        await _firestore.collection('users').doc(user.uid).delete();

        // Then delete the auth account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      print('Account Deletion Error: ${e.code} - ${e.message}');
      throw e;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }

      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmailAndPassword(
      String email, String password, String fullName) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Generate referral code from first 8 characters of user ID
        final referralCode = credential.user!.uid.substring(0, 8).toUpperCase();

        // Create user document
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'fullName': fullName,
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'referralCode': referralCode, // Store the referral code
        });

        // Create referral notification
        await _firestore.collection('notifications').add({
          'userId': credential.user!.uid,
          'type': 'referral_request',
          'title': 'Welcome to EcoThreads!',
          'message':
              'Were you invited by a friend? Enter their referral code to earn points!',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'needsAction': true,
          'points': 10,
        });

        return credential.user;
      }
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
    return null;
  }

  // Only keep this version of submitReferralCode and remove the other one
  Future<bool> submitReferralCode(
      String referralCode, String currentUserId) async {
    try {
      // Check if user has already used a referral code
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      if (currentUserDoc.data()?['hasUsedReferralCode'] == true) {
        print('User has already used a referral code');
        return false;
      }

      // Find user with this referral code
      final referrerQuery = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .limit(1)
          .get();

      if (referrerQuery.docs.isEmpty) {
        print('Invalid referral code');
        return false;
      }

      final referrerId = referrerQuery.docs.first.id;

      // Don't allow self-referral
      if (referrerId == currentUserId) {
        print('Cannot use own referral code');
        return false;
      }

      final batch = _firestore.batch();

      // Update referrer's points
      final referrerRef = _firestore.collection('users').doc(referrerId);
      batch.update(referrerRef, {
        'points': FieldValue.increment(10),
      });

      // Update new user's points and mark as referred
      final newUserRef = _firestore.collection('users').doc(currentUserId);
      batch.update(newUserRef, {
        'points': FieldValue.increment(10),
        'referredBy': referrerId,
        'hasUsedReferralCode': true,
        'hasSeenReferral': true,
      });

      // Create notification for referrer
      final referrerNotificationRef =
          _firestore.collection('notifications').doc();
      batch.set(referrerNotificationRef, {
        'userId': referrerId,
        'type': 'referral_bonus',
        'title': 'Referral Bonus!',
        'message': 'Someone used your referral code! You earned 10 points!',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'points': 10,
      });

      // Create notification for new user
      final userNotificationRef = _firestore.collection('notifications').doc();
      batch.set(userNotificationRef, {
        'userId': currentUserId,
        'type': 'referral_bonus',
        'title': 'Welcome Bonus!',
        'message': 'You earned 10 points for using a referral code!',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'points': 10,
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Error processing referral: $e');
      return false;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }
}
