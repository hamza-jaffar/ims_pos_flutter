import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
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
        route: AppRoutes.products,
      ),
      AppSidebarLink(
        icon: Icons.add_circle_outline,
        name: 'Create Product',
        route: AppRoutes.createProduct,
      ),
      AppSidebarLink(
        icon: Icons.trending_down,
        name: 'Low Stocks',
        route: AppRoutes.lowStocks,
      ),
      AppSidebarLink(
        icon: Icons.meeting_room_outlined,
        name: 'Rooms',
        route: AppRoutes.rooms,
      ),
      AppSidebarLink(
        icon: Icons.category_outlined,
        name: 'Category',
        route: AppRoutes.categories,
      ),
      AppSidebarLink(
        icon: Icons.branding_watermark_outlined,
        name: 'Brands',
        route: AppRoutes.brands,
      ),
    ],
  ),

  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Stocks',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(
        icon: Icons.inventory_2_outlined,
        name: 'Stock Management',
        route: AppRoutes.stocks,
      ),
      AppSidebarLink(
        icon: Icons.history,
        name: 'Stock History',
        route: AppRoutes.stockHistory,
      ),
    ],
  ),

  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Purchases',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(
        icon: Icons.shopping_bag_outlined,
        name: 'Purchases',
        route: AppRoutes.purchases,
      ),
      AppSidebarLink(
        icon: Icons.keyboard_return_outlined,
        name: 'Purchase Returns',
        route: AppRoutes.purchaseReturns,
      ),
    ],
  ),

  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Peoples',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(
        icon: Icons.local_shipping_outlined,
        name: 'Suppliers',
        route: AppRoutes.suppliers,
      ),
      AppSidebarLink(
        icon: Icons.people_alt_outlined,
        name: 'Customers',
        route: AppRoutes.customers,
      ),
    ],
  ),

  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Reports',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(
        icon: Icons.assessment_outlined,
        name: 'Purchase Report',
        route: AppRoutes.purchaseReport,
      ),
    ],
  ),

  AppSidebarLink(
    icon: Icons.layers_outlined,
    name: 'Settings',
    type: SidebarLinkType.group,
    children: [
      AppSidebarLink(
        icon: Icons.tune_rounded,
        name: 'Platform Settings',
        route: AppRoutes.platformSettings,
      ),
      AppSidebarLink(
        icon: Icons.manage_accounts_outlined,
        name: 'User Management',
        route: AppRoutes.userManagement,
      ),
    ],
  ),
];
