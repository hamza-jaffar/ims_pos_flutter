import 'package:flutter/material.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/const/sidebar_links.dart';
import 'package:ims_pos_system/widgets/app_logo.dart';
import 'package:ims_pos_system/models/app_sidebar_link.dart';

class AppSidebar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool isDesktop;
  final String activeRoute;
  final ValueChanged<String> onRouteSelected;

  const AppSidebar({
    super.key,
    required this.scaffoldKey,
    required this.isDesktop,
    required this.activeRoute,
    required this.onRouteSelected,
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
            child: Container(
              padding: EdgeInsets.only(top: 20),
              child: ListView(
                // padding: const EdgeInsets.symmetric(vertical: ),
                children: sidebarLinks.map(_buildItemAtIndex).toList(),
              ),
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
      selected: item.route == widget.activeRoute,
      onTap: () {
        if (item.route != null) {
          widget.onRouteSelected(item.route!);
          if (!widget.isDesktop) {
            widget.scaffoldKey.currentState?.closeDrawer();
          }
        }
      },
    );
  }

  Widget _buildGroupSection(AppSidebarLink item) {
    return Padding(
      padding: const EdgeInsets.only(left: 15),
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

  bool _itemHasActiveRoute(AppSidebarLink item) {
    if (item.route != null && item.route == widget.activeRoute) {
      return true;
    }
    if (item.children != null) {
      return item.children!.any(_itemHasActiveRoute);
    }
    return false;
  }

  Widget _buildDropdownItem(AppSidebarLink item) {
    final activeInSubtree = _itemHasActiveRoute(item);
    final expanded = _expanded[item.name] ?? activeInSubtree;
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
                    color: activeInSubtree
                        ? AppColors.primary
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: activeInSubtree
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: activeInSubtree
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
    final bool selected = child.route == widget.activeRoute;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          if (child.route != null) {
            widget.onRouteSelected(child.route!);
            if (!widget.isDesktop) {
              widget.scaffoldKey.currentState?.closeDrawer();
            }
          }
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  child.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? AppColors.primary : AppColors.textMain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (selected)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                const SizedBox(width: 4),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 14,
                color: selected ? AppColors.primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? AppColors.primary : Colors.grey.shade800,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
