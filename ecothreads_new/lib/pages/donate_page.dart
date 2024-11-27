import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class DonatePage extends StatefulWidget {
  const DonatePage({super.key});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  String selectedCondition = 'New';
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  int get conditionPoints {
    switch (selectedCondition) {
      case 'New':
        return 200;
      case 'Slightly Used':
        return 150;
      case 'Well-Worn':
        return 100;
      default:
        return 100;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _submitDonation() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create storage instance with correct bucket
      final storageInstance = FirebaseStorage.instanceFor(
          bucket: 'ecothreads-b1d6e.firebasestorage.app');

      // Create file reference in the images folder
      final fileRef = storageInstance
          .ref()
          .child('images')
          .child('donation_${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('Attempting to upload to: ${fileRef.fullPath}');

      // Upload the file
      final uploadTask = await fileRef.putFile(_image!);
      print('Upload completed with state: ${uploadTask.state}');

      if (uploadTask.state == TaskState.success) {
        // Get the download URL
        final imageUrl = await fileRef.getDownloadURL();
        print('Got download URL: $imageUrl');

        // Create donation document
        DocumentReference donationRef =
            await _firestore.collection('donations').add({
          'userId': user!.uid,
          'itemName': _nameController.text,
          'description': _descriptionController.text,
          'condition': selectedCondition,
          'imageUrl': imageUrl,
          'points': conditionPoints,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Created donation document');

        // Add to clothing collection with markup
        await _firestore.collection('clothing').add({
          'itemName': _nameController.text,
          'description': _descriptionController.text,
          'condition': selectedCondition,
          'imageUrl': imageUrl,
          'points': conditionPoints + 150, // Markup for selling
          'originalDonationId': donationRef.id,
          'donorId': user!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'available'
        });

        print('Created clothing document');

        // Update user's total points
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          int currentPoints = userData['points'] ?? 0;
          await _firestore.collection('users').doc(user!.uid).update({
            'points': currentPoints + conditionPoints,
          });
          print('Updated user points');
        } else {
          // If user document doesn't exist, create it with initial points
          await _firestore.collection('users').doc(user!.uid).set({
            'points': conditionPoints,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('Created new user document with initial points');
        }

        // Show success dialog with earned points
        if (mounted) {
          _showDonationDialog(conditionPoints);
          _clearForm();
        }
      } else {
        throw Exception('Upload failed with state: ${uploadTask.state}');
      }
    } catch (e) {
      print('Error submitting donation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit donation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    setState(() {
      _image = null;
      _nameController.clear();
      _descriptionController.clear();
      selectedCondition = 'New';
    });
  }

  void _showDonationDialog(int points) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: Color(0xFFFFD700),
                  size: 25,
                ),
                const SizedBox(height: 8),
                const Text('Your items will help make a difference.'),
                const SizedBox(height: 16),
                Text(
                  'Points earned: $points',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/main');
              },
              child: const Text('OK', style: TextStyle(color: Colors.black)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 85, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Donate Clothes',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload Photos',
                style: TextStyle(fontSize: 18, color: Color(0xFF808080)),
              ),
              const SizedBox(height: 16),
              Center(
                child: _image != null
                    ? Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.cloud_download,
                        size: 100,
                        color: Color(0xFFE2DFDF),
                      ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDonateButtons(
                        'Capture', () => _pickImage(ImageSource.camera)),
                    const SizedBox(width: 35),
                    _buildDonateButtons(
                        'Upload', () => _pickImage(ImageSource.gallery)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Condition',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildConditionButton('New'),
                      const SizedBox(width: 8),
                      _buildConditionButton('Slightly Used'),
                      const SizedBox(width: 8),
                      _buildConditionButton('Well-Worn'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Enter Item name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'eg. Blue t-shirt',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.black,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "eg. Bought from fashion nova but doesn't fit",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.black,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Points Earned: $conditionPoints',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Donation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonateButtons(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        backgroundColor: Colors.black,
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }

  Widget _buildConditionButton(String condition) {
    bool isSelected = selectedCondition == condition;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCondition = condition;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Text(
          condition,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
