import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';

class POSWindowLauncher {
  static const String windowType = 'pos';

  static Future<void> openWindow() async {
    final controller = await WindowController.create(
      WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: jsonEncode({'type': windowType}),
      ),
    );

    await controller.show();
  }

  static Future<String?> currentWindowArguments() async {
    final windowController = await WindowController.fromCurrentEngine();
    return windowController.arguments;
  }

  static bool isPosWindow(String? arguments) {
    if (arguments == null || arguments.isEmpty) return false;

    try {
      final parsed = jsonDecode(arguments);
      return parsed is Map<String, dynamic> && parsed['type'] == windowType;
    } catch (_) {
      return false;
    }
  }
}
