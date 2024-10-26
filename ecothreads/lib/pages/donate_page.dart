import 'package:flutter/material.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donate Clothes',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 4,
            ),
            const Text(
              'Upload Photos',
              style: TextStyle(fontSize: 18, color: Color(0xFF808080)),
            ),
            const SizedBox(
              height: 20,
            ),
            const Center(
              child: Icon(
                Icons.cloud_download,
                size: 100,
                color: Color(0xFFE2DFDF),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDonateButtons('Capture'),
                  const SizedBox(
                    width: 20,
                  ),
                  _buildDonateButtons('Upload from library'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonateButtons(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 40),
        backgroundColor: Colors.black,
        minimumSize: const Size(0, 45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}
