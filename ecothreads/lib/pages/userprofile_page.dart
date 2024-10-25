import 'package:ecothreads/constants/colors.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover Image Container with a fixed height
              Container(
                height: 230,
                width: double.infinity, // Full width
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/cover.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Profile image positioned to overlap
              Positioned(
                bottom: -45, // Negative value makes it overlap
                left: 20,
                child: Container(
                  height: 105,
                  width: 105,
                  decoration: BoxDecoration(
                    image: const DecorationImage(
                      image: AssetImage('assets/images/profile.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
              height: 55), // Space for the overlapped profile picture
          // Add your username and other content here

          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Crystal Holder',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '@fashionlover29',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),
          const Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20),
            child: Text(
              'I love all things fashion and colorful. Excited to swap on ecothreads, hit me up if you see anything you like',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ),

          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Container(
                  width: 83,
                  height: 28,
                  padding: EdgeInsets.only(left: 8.0, right: 8),
                  decoration: BoxDecoration(
                      color: AppColors.primarylight,
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                    child: Text(
                      "Donate",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 10),
                child: Container(
                  width: 83,
                  height: 28,
                  padding: EdgeInsets.only(left: 8.0, right: 8),
                  decoration: BoxDecoration(
                      color: AppColors.primarylight,
                      borderRadius: BorderRadius.circular(20)),
                  child: Center(
                    child: Text(
                      "Donate",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
