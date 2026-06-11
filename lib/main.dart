import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:printing/printing.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/models/user.dart';
import 'package:ims_pos_system/pos/index.dart';
import 'package:ims_pos_system/pos/pos_window_launcher_stub.dart'
    if (dart.library.io) 'package:ims_pos_system/pos/pos_window_launcher.dart';
import 'package:ims_pos_system/screens/home_screen.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Load platform settings before starting the app
  await PlatformSettingsService.instance.init();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    final windowArguments = await POSWindowLauncher.currentWindowArguments();
    if (POSWindowLauncher.isPosWindow(windowArguments)) {
      runApp(const POSApp());
      return;
    }
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    final windowController = await WindowController.fromCurrentEngine();
    windowController.setWindowMethodHandler((call) async {
      if (call.method == 'printPdf') {
        final bytes = call.arguments as List<dynamic>;
        await Printing.layoutPdf(
          onLayout: (format) async => Uint8List.fromList(bytes.cast<int>()),
        );
        return 'success';
      }
      return 'not_implemented';
    });
  }

  runApp(const MyApp());
}

class POSApp extends StatelessWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: PlatformSettingsService.instance.settings.platformName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
      ),
      home: const POSWindow(),
    );
  }
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
      home: HomeScreen(
        user: User(
          id: null,
          name: 'Administrator',
          email: 'admin@example.com',
          password: 'password123',
        ),
      ),
    );
  }
}
