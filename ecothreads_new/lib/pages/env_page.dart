import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EnvironmentalImpactPage extends StatefulWidget {
  const EnvironmentalImpactPage({Key? key}) : super(key: key);

  @override
  _EnvironmentalImpactPageState createState() =>
      _EnvironmentalImpactPageState();
}

class _EnvironmentalImpactPageState extends State<EnvironmentalImpactPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late String _userName = 'User';
  late String _userHandle = '@username';
  String _userProfileUrl = '';
  int _donations = 0;
  int _leaderboardRank = 2;
  double _impactPercentage = 50.0;
  String _userStatus = 'Bronze';
  int _currentPoints = 0;
  int _pointsToNextLevel = 500;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['fullName'] ?? 'User';
            _userHandle = '@${userDoc['username']}';
            _userProfileUrl = userDoc['profileImageUrl'] ?? '';
            _donations = userDoc['donations'] ?? 0;
            _leaderboardRank = userDoc['leaderboardRank'] ?? 0;
            _impactPercentage =
                (userDoc['impactPercentage'] ?? 20.0).toDouble();
            _userStatus = _calculateUserStatus(_impactPercentage);
            _currentPoints = userDoc['points'] ?? 70;
            _pointsToNextLevel = _calculatePointsToNextLevel(_currentPoints);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> pickAndUploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      // Pick an image from the gallery
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      // Create a reference to the location you want to store the image
      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');

      // Upload the image
      await storageRef.putFile(imageFile);

      // Get the download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Update the user's document with the new profile image URL
      await _firestore.collection('users').doc(currentUser.uid).update({
        'profileImageUrl': downloadURL,
      });

      // Update the local state
      setState(() {
        _userProfileUrl = downloadURL;
        _isLoading = false;
      });

      _showSuccessSnackBar('Profile image updated successfully');
    } catch (e) {
      print('Error uploading profile image: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to upload profile image');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _calculateUserStatus(double impactPercentage) {
    if (impactPercentage >= 75) return 'Platinum';
    if (impactPercentage >= 50) return 'Gold';
    if (impactPercentage >= 25) return 'Silver';
    return 'Bronze';
  }

  int _calculatePointsToNextLevel(int currentPoints) {
    int currentLevel = (currentPoints ~/ 1000) + 1;
    return (currentLevel * 1000) - currentPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    children: [
                      // Back Button and Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade100,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Text(
                              'Environmental Impact',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Profile Section
                      Column(
                        children: [
                          GestureDetector(
                            onTap: pickAndUploadProfileImage,
                            child: Stack(
                              children: [
                                _userProfileUrl.isNotEmpty
                                    ? Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.green.shade400,
                                            width: 3,
                                          ),
                                          image: DecorationImage(
                                            image:
                                                NetworkImage(_userProfileUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade300,
                                          border: Border.all(
                                            color: Colors.green.shade400,
                                            width: 3,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: [
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _userHandle,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Navigation Tabs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'STATS',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'ACHIEVEMENTS',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14),
                            ),
                            Text(
                              'ACTIVITY',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // First Row Stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.local_fire_department,
                                iconColor: Colors.orange,
                                value: _donations.toString(),
                                label: 'Donations',
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.bar_chart,
                                iconColor: Colors.blue,
                                value: '#$_leaderboardRank',
                                label: 'Leaderboard',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Second Row Stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.bolt,
                                iconColor: Colors.orange,
                                value:
                                    '${_impactPercentage.toStringAsFixed(0)}%',
                                label: 'Impact',
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.star,
                                iconColor: Colors.amber,
                                value: _userStatus,
                                label: _currentPoints.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Level Progress
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade400,
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.speed,
                                          color: Colors.black, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Level ${(_currentPoints ~/ 1000) + 1}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '$_pointsToNextLevel Points to next level',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildLevelProgressBar(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            offset: const Offset(0, 4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressBar() {
    double progressFactor = (_currentPoints % 1000) / 1000;
    return Stack(
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progressFactor,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
