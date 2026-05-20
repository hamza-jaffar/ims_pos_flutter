import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';

class AppHeader extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isDesktop;

  const AppHeader({
    super.key,
    required this.scaffoldKey,
    required this.isDesktop,
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
              icon: Icon(Icons.menu, color: AppColors.textMain),
              onPressed: () {
                widget.scaffoldKey.currentState?.openDrawer();
              },
            ),

          // Title / Brand
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
                style: TextStyle(fontSize: 14, color: AppColors.textMain),
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

          // Notification icon
          _iconButton(Icons.notifications_none_outlined),

          const SizedBox(width: 8),

          // Settings icon
          _iconButton(Icons.settings_outlined),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.textSecondary),
        onPressed: () {},
      ),
    );
  }
}
