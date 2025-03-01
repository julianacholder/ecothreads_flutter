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

  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password,
      {String? fullName, String? username}) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update user profile with displayName if provided
      if (fullName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
      }

      // Save user data to Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!,
            displayName: fullName, username: username);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Registration Error: ${e.code} - ${e.message}');
      throw e;
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

      // Save user data to Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!,
            displayName: fullName, username: username);
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
}
