import 'package:flutter/material.dart';
import 'package:ims_pos_system/app_routes.dart';
import 'package:ims_pos_system/const/app_colors.dart';
import 'package:ims_pos_system/widgets/app_header.dart';
import 'package:ims_pos_system/widgets/app_sidebar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String activeRoute;

  const MainLayout({super.key, required this.child, this.activeRoute = ''});

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
    _activeChild = widget.child;
    _activeRoute = widget.activeRoute;
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child ||
        oldWidget.activeRoute != widget.activeRoute) {
      setState(() {
        _activeChild = widget.child;
        _activeRoute = widget.activeRoute;
      });
    }
  }

  void _updateRoute(String route) {
    if (route == _activeRoute) return;
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
              width: 240,
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
                AppHeader(scaffoldKey: _scaffoldKey, isDesktop: isDesktop),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            child: _activeChild,
                          ),
                        ),
                      );
                    },
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
