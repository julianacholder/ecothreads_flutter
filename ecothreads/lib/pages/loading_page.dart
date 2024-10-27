import 'package:flutter/material.dart';

void main() {
  runApp(LoadingPage());
}

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF16A637),
        body: Stack(
          children: [
            // logo
            Center(
              child: Image.asset(
                'assets/images/loadinglogo.png',
                height: 250,
                width: 350,
              ),
            ),
            // loading ...
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
