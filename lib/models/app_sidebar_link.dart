import 'package:flutter/material.dart';
import 'package:ims_pos_system/enums/sidebar_link_types.dart';

class AppSidebarLink {
  final IconData icon;
  final String name;
  final String? route;
  final List<AppSidebarLink>? children;
  final SidebarLinkType type;

  const AppSidebarLink({
    required this.icon,
    required this.name,
    this.route,
    this.children,
    this.type = SidebarLinkType.item,
  });

  bool get isGroup => type == SidebarLinkType.group;

  bool get isCollapsible => children != null && children!.isNotEmpty;
}
