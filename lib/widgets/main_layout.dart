import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/pos/pos_window_launcher_stub.dart'
    if (dart.library.io) 'package:ims_pos_system/pos/pos_window_launcher.dart';
import 'package:ims_pos_system/widgets/app_header.dart';
import 'package:ims_pos_system/widgets/app_sidebar.dart';

class MainLayout extends StatefulWidget {
  final Widget? child;
  final String activeRoute;

  const MainLayout({super.key, this.child, this.activeRoute = AppRoutes.dashboard});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Widget _activeChild;
  late String _activeRoute;

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.activeRoute.isEmpty ? AppRoutes.dashboard : widget.activeRoute;
    if (widget.child != null) {
      _activeChild = widget.child!;
    } else {
      _activeChild = AppRoutes.getContent(_activeRoute, onRouteSelected: _updateRoute) ?? const SizedBox();
    }
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child ||
        oldWidget.activeRoute != widget.activeRoute) {
      setState(() {
        _activeRoute = widget.activeRoute.isEmpty ? AppRoutes.dashboard : widget.activeRoute;
        if (widget.child != null) {
          _activeChild = widget.child!;
        } else {
          _activeChild = AppRoutes.getContent(_activeRoute, onRouteSelected: _updateRoute) ?? const SizedBox();
        }
      });
    }
  }

  void _updateRoute(String route) {
    if (route == _activeRoute) return;
    if (route == AppRoutes.pos) {
      POSWindowLauncher.openWindow();
      return;
    }

    final routeWidget = AppRoutes.getContent(
      route,
      onRouteSelected: _updateRoute,
    );
    if (routeWidget == null) return;

    setState(() {
      _activeRoute = route;
      _activeChild = routeWidget;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: !isDesktop
          ? Drawer(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              child: AppSidebar(
                scaffoldKey: _scaffoldKey,
                isDesktop: isDesktop,
                activeRoute: _activeRoute,
                onRouteSelected: _updateRoute,
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 210,
              child: AppSidebar(
                scaffoldKey: _scaffoldKey,
                isDesktop: isDesktop,
                activeRoute: _activeRoute,
                onRouteSelected: _updateRoute,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  scaffoldKey: _scaffoldKey,
                  isDesktop: isDesktop,
                  onRouteSelected: _updateRoute,
                ),
                Expanded(
                  child: ScrollConfiguration(
                    // Push scrollbars to the very edge of the viewport
                    behavior: const ScrollBehavior().copyWith(
                      scrollbars: true,
                      overscroll: false,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: _activeChild,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
