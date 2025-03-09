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
  String selectedSize = 'N/A';
  String selectedMaterial = 'Cotton';
  String customMaterial = '';
  String selectedCategory = 'Basics';
  String selectedSubcategory = '';

  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> clothingSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  final List<List<String>> materialRows = [
    ['Cotton', 'Polyester', 'Leather', 'Denim'], // First row
    ['Wool', 'Silk', 'Linen', 'Nylon'], // Second row
    ['Other'], // Last row
  ];

  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;

  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Updated category items with icons
  final Map<String, List<Map<String, dynamic>>> categoryItems = {
    'Basics': [
      {'name': 'T-shirts', 'icon': Icons.style},
      {'name': 'Trousers', 'icon': Icons.straighten},
      {'name': 'Dresses', 'icon': Icons.checkroom},
    ],
    'Shoes/Bags': [
      {'name': 'Shoes', 'icon': Icons.wallet},
      {'name': 'Bags', 'icon': Icons.shopping_bag},
      {'name': 'Accessories', 'icon': Icons.watch},
    ],
    'Outerwear': [
      {'name': 'Jackets', 'icon': Icons.layers},
      {'name': 'Hoodies', 'icon': Icons.dry_cleaning},
      {'name': 'Coats', 'icon': Icons.accessibility_new},
    ],
  };

  // Points system for donations
  Map<String, Map<String, int>> donationPoints = {
    'Basics': {
      'Well-Worn': 100,
      'Slightly Used': 150,
      'New': 200,
    },
    'Shoes/Bags': {
      'Well-Worn': 150,
      'Slightly Used': 200,
      'New': 250,
    },
    'Outerwear': {
      'Well-Worn': 200,
      'Slightly Used': 350,
      'New': 400,
    },
  };

  // Points system for marketplace
  Map<String, Map<String, int>> marketplacePoints = {
    'Basics': {
      'Well-Worn': 120,
      'Slightly Used': 180,
      'New': 250,
    },
    'Shoes/Bags': {
      'Well-Worn': 200,
      'Slightly Used': 300,
      'New': 350,
    },
    'Outerwear': {
      'Well-Worn': 300,
      'Slightly Used': 450,
      'New': 500,
    },
  };

  // Update the points calculation
  int get conditionPoints {
    return donationPoints[selectedCategory]?[selectedCondition] ?? 100;
  }

  int get marketPrice {
    return marketplacePoints[selectedCategory]?[selectedCondition] ?? 120;
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

  Future<bool> _checkUserRestriction() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return userDoc.data()?['isRestricted'] ?? false;
    } catch (e) {
      print('Error checking restriction: $e');
      return false;
    }
  }

  Future<void> _submitDonation() async {
    // Check for restriction before allowing donation
    bool isRestricted = await _checkUserRestriction();
    if (isRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Your account is currently restricted. Please contact support@ecothreads.com'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {},
            textColor: Colors.white,
          ),
        ),
      );
      return;
    }

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

    if (selectedSubcategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item type')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First get the user data
      final userDoc = await _firestore.collection('users').doc(user!.uid).get();
      final userData = userDoc.data() ?? {};
      final userFullName = userData['fullName'] ?? 'Anonymous';
      final userProfileImage = userData['profileImageUrl'];

      // Create storage instance with correct bucket
      final storageInstance = FirebaseStorage.instanceFor(
          bucket: 'ecothreads-b1d6e.firebasestorage.app');

      final fileRef = storageInstance
          .ref()
          .child('images')
          .child('donation_${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('Attempting to upload to: ${fileRef.fullPath}');

      final uploadTask = await fileRef.putFile(_image!);
      print('Upload completed with state: ${uploadTask.state}');

      if (uploadTask.state == TaskState.success) {
        final imageUrl = await fileRef.getDownloadURL();
        print('Got download URL: $imageUrl');

        // Use custom material if "Other" is selected
        final materialToUse =
            selectedMaterial == 'Other' ? customMaterial : selectedMaterial;

        // Create donation document with user info
        DocumentReference donationRef =
            await _firestore.collection('donations').add({
          'userId': user!.uid,
          'userFullName': userFullName,
          'userProfileImage': userProfileImage,
          'itemName': _nameController.text,
          'description': _descriptionController.text,
          'condition': selectedCondition,
          'size': selectedSize,
          'material': materialToUse,
          'imageUrl': imageUrl,
          'points': marketPrice,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'available',
          'category': selectedCategory,
          'subcategory': selectedSubcategory,
        });

        print('Created donation document');

        // Add to clothing collection with user info
        await _firestore.collection('clothing').add({
          'itemName': _nameController.text,
          'description': _descriptionController.text,
          'condition': selectedCondition,
          'size': selectedSize,
          'material': materialToUse,
          'imageUrl': imageUrl,
          'points': conditionPoints + 150,
          'originalDonationId': donationRef.id,
          'donorId': user!.uid,
          'donorName': userFullName,
          'donorProfileImage': userProfileImage,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'available',
          'category': selectedCategory,
          'subcategory': selectedSubcategory,
        });

        print('Created clothing document');

        // Update user points
        if (userDoc.exists) {
          int currentPoints = userData['points'] ?? 0;
          await _firestore.collection('users').doc(user!.uid).update({
            'points': currentPoints + conditionPoints,
          });
          print('Updated user points');
        } else {
          await _firestore.collection('users').doc(user!.uid).set({
            'points': conditionPoints,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('Created new user document with initial points');
        }

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
      selectedSize = 'N/A';
      selectedMaterial = 'Cotton';
      customMaterial = '';
      _materialController.clear();
      selectedSubcategory = '';
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
                    : Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_rounded,
                              size: 60,
                              color: Color(0xFFE2DFDF),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Upload your item photo',
                              style: TextStyle(
                                color: Color(0xFF808080),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDonateButtons(
                        'Capture', () => _pickImage(ImageSource.camera)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDonateButtons(
                        'Gallery', () => _pickImage(ImageSource.gallery)),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildCategorySelection(),
              const SizedBox(height: 32),
              const Text(
                'Item Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildConditionSelection(),
              const SizedBox(height: 24),
              _buildSizeSelection(),
              const SizedBox(height: 24),
              _buildMaterialSelection(),
              const SizedBox(height: 24),
              _buildItemNameField(),
              const SizedBox(height: 24),
              _buildDescriptionField(),
              const SizedBox(height: 40), // Increased from 24 to 40
              _buildPointsInfo(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
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
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            text == 'Capture' ? Icons.camera_alt : Icons.photo_library,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Category',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Categories in horizontal scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categoryItems.keys.map((category) {
              bool isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                      selectedSubcategory =
                          ''; // Reset subcategory when changing category
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        // Subcategories in grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: (categoryItems[selectedCategory] ?? []).map((item) {
            bool isSelected = selectedSubcategory == item['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedSubcategory = item['name'];
                });
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'],
                      size: 20,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConditionSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Condition',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildConditionButton('New')),
            const SizedBox(width: 8),
            Expanded(child: _buildConditionButton('Slightly Used')),
            const SizedBox(width: 8),
            Expanded(child: _buildConditionButton('Well-Worn')),
          ],
        ),
      ],
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
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          condition,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSizeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // First row with all sizes
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSizeButton('XS'),
              const SizedBox(width: 8),
              ...clothingSizes.map((size) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildSizeButton(size),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Second row with just N/A
        Row(
          children: [
            _buildSizeButton('N/A'),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeButton(String size) {
    bool isSelected = selectedSize == size;

    return GestureDetector(
      // Wrap with GestureDetector
      onTap: () {
        setState(() {
          selectedSize = size;
        });
      },
      child: Container(
        width: 48, // Fixed width for consistency
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          size,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMaterialSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        // Build material rows using materialRows
        ...materialRows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: row.length < 4
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                children: row
                    .map((material) => _buildMaterialButton(material))
                    .toList(),
              ),
            )),
        if (selectedMaterial == 'Other') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _materialController,
            decoration: InputDecoration(
              hintText: 'Enter material type',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
            onChanged: (value) {
              setState(() {
                customMaterial = value;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildMaterialButton(String material) {
    bool isSelected = selectedMaterial == material;

    return Container(
      width:
          (MediaQuery.of(context).size.width - 56) / 4, // Keep consistent width
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMaterial = material;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade300,
            ),
          ),
          child: Text(
            material,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildItemNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Name',
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
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildPointsInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Points Summary',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('You will receive:'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '$conditionPoints points',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Market price:'),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '$marketPrice points',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitDonation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Submit Donation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
