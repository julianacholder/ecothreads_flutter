import 'package:flutter/material.dart';

class ConservationImpact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conservation Impact'),
      ),
      body: Center(
        child: Text(
          'Track your conservation efforts here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
