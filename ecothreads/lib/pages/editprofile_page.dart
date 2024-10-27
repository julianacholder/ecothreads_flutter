
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Page Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProfilePage(),
    );
  }
}


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});


  @override
  _ProfilePageState createState() => _ProfilePageState();
}


class _ProfilePageState extends State<ProfilePage> {
  String name = "Crystal Holder";
  String email = "@fashionlover29";
  String bio = "";
  final List<String> listings = [];
  int donations = 0;
  int points = 50;
  int items = 0;


  void _showBioDialog(BuildContext context) {
    final TextEditingController bioController = TextEditingController(text: bio);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Bio"),
          content: TextField(
            controller: bioController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Enter your bio here"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  bio = bioController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }


  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController emailController = TextEditingController(text: email);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Enter your name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: "Enter your email"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  name = nameController.text;
                  email = emailController.text;
                });
                Navigator.of(context).pop();
                _showToast("Profile updated");
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }


  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: double.infinity,
                  color: Colors.grey,
                ),
                Positioned(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Add a cover photo",
                        style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.black, size: 40),
                        onPressed: () {
                          _showToast("Add cover photo tapped");
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.3 - 26.25,
                  left: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 52.5,
                        backgroundColor: Colors.grey[800],
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: () {
                            _showToast("Change profile picture tapped");
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                bio.isEmpty ? "No bio available" : bio,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: 79, // Fixed width
                height: 25, // Fixed height
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8), // Background color
                  border: Border.all(color: const Color(0xFFDFDEDE), width: 1), // Border
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _showBioDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // No padding
                    backgroundColor: Colors.transparent, // No background for elevated button
                    elevation: 0, // No shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Uniform rounded corners
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Add Bio",
                      style: TextStyle(color: Colors.black, fontSize: 14), // Black text color
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionButton("Donate", () => _showToast("Donate button pressed")),
                  const SizedBox(width: 8),
                  _actionButton("Redeem", () => _showToast("Redeem button pressed")),
                  const SizedBox(width: 8),
                  _actionButton("Explore", () => _showToast("Explore button pressed")),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(top: 14.0, left: 16.0), // Adjusting position
              child: SizedBox(
                width: 334, // Fixed width
                height: 26, // Fixed height
                child: ElevatedButton(
                  onPressed: () {
                    _showEditProfileDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 84), // Custom padding
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Rounded on all sides
                    ),
                    elevation: 0, // No shadow
                  ),
                  child: const Text(
                    "Edit Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14, // You can adjust the font size as needed
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _statItem(Icons.volunteer_activism, donations, "Donations"),
                  const SizedBox(width: 24),
                  _statItem(Icons.monetization_on, points, "Points"),
                  const SizedBox(width: 24),
                  _statItem(Icons.inventory, items, "Items"),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "My Listings",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (listings.isEmpty)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.camera_alt, size: 40, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text("No Listings Available", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _actionButton(String label, VoidCallback onPressed) {
    return Container(
      width: 54,
      height: 17,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 0),
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded on all sides
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }


  Widget _statItem(IconData icon, int count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Adjust to minimize space
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24), // Reduced icon size
            const SizedBox(width: 4), // Space between icon and number
            Text(count.toString(), style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 2), // Space between count and label
        Text(label, style: const TextStyle(fontSize: 14)), // Label below the icon and number
      ],
    );
  }
}
