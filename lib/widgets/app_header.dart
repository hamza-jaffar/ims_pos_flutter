import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/screens/login_screen.dart';

class AppHeader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isDesktop;
  final ValueChanged<String>? onRouteSelected;

  const AppHeader({
    super.key,
    required this.scaffoldKey,
    required this.isDesktop,
    this.onRouteSelected,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu button (mobile/tablet)
          if (!widget.isDesktop)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textMain),
              onPressed: () {
                widget.scaffoldKey.currentState?.openDrawer();
              },
            ),

          // Search bar (desktop)
          if (widget.isDesktop)
            Container(
              width: 320,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withOpacity(0.6)),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                decoration: InputDecoration(
                  hintText: 'Search products, invoices...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
            ),

          const Spacer(),

          if (widget.isDesktop) const SizedBox(width: 20),

          TextButton.icon(
            onPressed: () {
              widget.onRouteSelected?.call(AppRoutes.pos);
            },
            icon: const Icon(Icons.point_of_sale_outlined, size: 20),
            label: const Text("POS"),
          ),

          const SizedBox(width: 8),

          // Settings icon → navigates to platform settings
          _iconButton(
            Icons.settings_outlined,
            tooltip: 'Platform Settings',
            onPressed: () {
              widget.onRouteSelected?.call(AppRoutes.platformSettings);
            },
          ),

          const SizedBox(width: 8),

          // User avatar
          _userAvatarButton(),
        ],
      ),
    );
  }

  Widget _iconButton(
    IconData icon, {
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: AppColors.textSecondary),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _userAvatarButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        if (value == 'logout') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: AppColors.danger)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'A',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
