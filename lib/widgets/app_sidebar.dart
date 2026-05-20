import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/const/sidebar_links.dart';
import 'package:ims_pos_system/widgets/app_logo.dart';
import 'package:ims_pos_system/models/app_sidebar_link.dart';

class AppSidebar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isDesktop;

  const AppSidebar({
    super.key,
    required this.scaffoldKey,
    required this.isDesktop,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final Map<String, bool> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: AppLogo()),

                if (!widget.isDesktop)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textMain),
                    onPressed: () {
                      widget.scaffoldKey.currentState?.closeDrawer();
                    },
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          Expanded(
            child: ListView(
              // padding: const EdgeInsets.symmetric(vertical: ),
              children: sidebarLinks.map(_buildItemAtIndex).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemAtIndex(AppSidebarLink item) {
    if (item.isGroup) {
      return _buildGroupSection(item);
    }

    if (item.isCollapsible) {
      return _buildDropdownItem(item);
    }

    return _menuItem(
      icon: item.icon,
      title: item.name,
      onTap: () {
        if (item.route != null) {
          Navigator.pushNamed(context, item.route!);
        }
      },
    );
  }

  Widget _buildGroupSection(AppSidebarLink item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 10),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...item.children!.map((child) => _buildItemAtIndex(child)),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(AppSidebarLink item) {
    final expanded = _expanded[item.name] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              setState(() {
                _expanded[item.name] = !expanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: expanded
                    ? AppColors.primary.withAlpha(36)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 15,
                    color: expanded ? AppColors.primary : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: expanded
                            ? AppColors.primary
                            : AppColors.textMain,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(500),
                      color: expanded
                          ? AppColors.primary.withOpacity(.1)
                          : AppColors.textMain.withOpacity(.1),
                    ),
                    child: Icon(
                      size: 22,
                      expanded
                          ? Icons.keyboard_arrow_down_outlined
                          : Icons.keyboard_arrow_right_outlined,
                      color: expanded
                          ? AppColors.primary
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 20, top: 10, right: 4),
              child: Column(
                children: item.children!
                    .map((child) => _buildDropdownChild(child))
                    .toList(),
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownChild(AppSidebarLink child) {
    return InkWell(
      onTap: () {
        if (child.route != null) Navigator.pushNamed(context, child.route!);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                child.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
