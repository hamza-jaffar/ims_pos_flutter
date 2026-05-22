import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/services/platform_settings_service.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = PlatformSettingsService.instance.settings;
    
    return Row(
      children: [
        if (settings.logoPath != null && settings.logoPath!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(settings.logoPath!),
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.storefront, color: AppColors.primary, size: 28),
            ),
          )
        else
          const Icon(Icons.storefront, color: AppColors.primary, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            settings.platformName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
