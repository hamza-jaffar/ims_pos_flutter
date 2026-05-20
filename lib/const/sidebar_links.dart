import 'package:flutter/material.dart';
import 'package:ims_pos_system/enums/sidebar_link_types.dart';
import 'package:ims_pos_system/models/app_sidebar_link.dart';

const sidebarLinks = [
  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Main',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(icon: Icons.supervisor_account_outlined, name: 'Admin'),
    ],
  ),

  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Inventory',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(
        icon: Icons.inventory_2_outlined,
        name: 'Products',
        route: "/products",
      ),
      AppSidebarLink(
        icon: Icons.add,
        name: 'Create Product',
        route: "/products/create",
      ),
      AppSidebarLink(icon: Icons.warning_amber, name: 'Expired Products'),
      AppSidebarLink(icon: Icons.trending_down, name: 'Low Stocks'),
      AppSidebarLink(icon: Icons.category, name: 'Category'),
      AppSidebarLink(icon: Icons.account_tree_outlined, name: 'Sub Category'),
      AppSidebarLink(icon: Icons.branding_watermark, name: 'Brands'),
      AppSidebarLink(icon: Icons.straighten, name: 'Units'),
    ],
  ),
];
