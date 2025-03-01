import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _profileImageUrl;
  String? _coverImageUrl;
  bool _isPrivate = false;

  final int _maxBioWords = 50; // Maximum allowed words in bio

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _bioController.addListener(_onBioChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onBioChanged() {
    // Force refresh to update word count
    setState(() {});
  }

  int _getWordCount(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
  }

  Future<void> _loadUserData() async {
    try {
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user!.uid).get();
        if (userData.exists) {
          setState(() {
            _nameController.text = userData.data()?['fullName'] ?? '';
            _usernameController.text = userData.data()?['username'] ?? '';
            _bioController.text = userData.data()?['bio'] ?? '';
            _locationController.text = userData.data()?['location'] ?? '';
            _profileImageUrl = userData.data()?['profileImageUrl'];
            _coverImageUrl = userData.data()?['coverImageUrl'];
            _isPrivate = userData.data()?['isPrivate'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _uploadImage(bool isProfileImage) async {
    try {
      setState(() => _isLoading = true);

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      final File imageFile = File(pickedFile.path);
      final String imageType = isProfileImage ? 'profile' : 'cover';

      final storageInstance = FirebaseStorage.instanceFor(
          bucket: 'ecothreads-b1d6e.firebasestorage.app');

      final fileRef = storageInstance
          .ref()
          .child('images')
          .child('${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('Attempting upload to: ${fileRef.fullPath}');

      final uploadTask = await fileRef.putFile(imageFile);
      print('Upload completed with state: ${uploadTask.state}');

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await fileRef.getDownloadURL();
        print('Got download URL: $downloadUrl');

        await _firestore.collection('users').doc(user!.uid).set({
          isProfileImage ? 'profileImageUrl' : 'coverImageUrl': downloadUrl,
        }, SetOptions(merge: true));

        setState(() {
          if (isProfileImage) {
            _profileImageUrl = downloadUrl;
          } else {
            _coverImageUrl = downloadUrl;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${isProfileImage ? 'Profile' : 'Cover'} picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
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

  Future<void> _saveProfile() async {
    try {
      setState(() => _isLoading = true);

      if (_getWordCount(_bioController.text) > _maxBioWords) {
        throw Exception('Bio exceeds maximum word limit');
      }

      await _firestore.collection('users').doc(user!.uid).update({
        'fullName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'isPrivate': _isPrivate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Profile Photo Section
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => _uploadImage(true),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            image: _profileImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 24,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile Information Section
                _buildTextField(
                  'Name',
                  'Enter your name',
                  _nameController,
                ),
                _buildTextField(
                  'Username',
                  'Username',
                  _usernameController,
                ),
                _buildTextField(
                  'Biography',
                  'Add Bio',
                  _bioController,
                  maxWords: _maxBioWords,
                  currentWords: _getWordCount(_bioController.text),
                ),
                _buildTextField('Location', 'Location', _locationController),
                const Divider(height: 32),

                // Settings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSettingsSwitch(
                        title: 'Private',
                        value: _isPrivate,
                        onChanged: (value) {
                          setState(() => _isPrivate = value);
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.recycling,
                        title: 'Environmental Impact',
                        showArrow: true,
                      ),
                      _buildSettingsItem(
                        icon: Icons.headphones,
                        title: 'Help Center',
                        showArrow: true,
                      ),
                      _buildSettingsItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool enabled = true,
    int? maxWords,
    int? currentWords,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (maxWords != null)
                Text(
                  '$currentWords/$maxWords words',
                  style: TextStyle(
                    fontSize: 12,
                    color: currentWords! > maxWords ? Colors.red : Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: label == 'Biography' ? 3 : 1,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: const UnderlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              errorText: maxWords != null && currentWords! > maxWords
                  ? 'Bio cannot exceed $maxWords words'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    bool showArrow = false,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black54,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Yes, Logout'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'No, Cancel',
                      style: TextStyle(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
