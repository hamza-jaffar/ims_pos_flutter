import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/const/meta_data.dart';
import 'package:ims_pos_system/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
