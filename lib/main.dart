import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/screens/login_screen.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Load platform settings before starting the app
  await PlatformSettingsService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: PlatformSettingsService.instance.settings.platformName,
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      onGenerateRoute: (settings) {
        final widget = AppRoutes.getContent(settings.name ?? '');
        if (widget != null) {
          return MaterialPageRoute(builder: (context) => widget);
        }
        return null;
      },
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
