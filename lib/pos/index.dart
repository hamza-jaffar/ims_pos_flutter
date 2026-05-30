import 'package:flutter/material.dart';

class POSWindow extends StatelessWidget {
  const POSWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'POS window opened in a separate desktop window.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
