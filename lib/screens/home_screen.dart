import 'package:flutter/material.dart';
import 'package:ims_pos_system/models/user.dart';
import 'package:ims_pos_system/widgets/main_layout.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Center(
        child: Text(
          'Your Active Screen Content Loaded Here!',
          style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
