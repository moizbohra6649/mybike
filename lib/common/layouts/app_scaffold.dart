import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/extensions/context_extensions.dart';
import '../components/search_filters/global_search_modal.dart';
import 'app_app_bar.dart';
import 'app_sidebar.dart';
import 'app_bottom_navigation.dart';

/// Master Responsive Scaffold for MYBIKE ERP
class AppScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final String activeNavigationId;
  final ValueChanged<String>? onNavigationChanged;
  final Widget? floatingActionButton;
  final bool showBottomNavOnMobile;
  final bool showSidebarOnDesktop;
  final String currentShowroomName;
  final VoidCallback? onShowroomSwitchTap;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.activeNavigationId = 'dashboard',
    this.onNavigationChanged,
    this.floatingActionButton,
    this.showBottomNavOnMobile = true,
    this.showSidebarOnDesktop = true,
    this.currentShowroomName = 'Central Showroom',
    this.onShowroomSwitchTap,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _currentNavId;

  @override
  void initState() {
    super.initState();
    _currentNavId = widget.activeNavigationId;
  }

  @override
  void didUpdateWidget(covariant AppScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeNavigationId != oldWidget.activeNavigationId) {
      _currentNavId = widget.activeNavigationId;
    }
  }

  void _handleNavigation(String id) {
    setState(() {
      _currentNavId = id;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
    if (widget.onNavigationChanged != null) {
      widget.onNavigationChanged!(id);
    } else {
      switch (id) {
        case 'dashboard':
          context.goNamed(RouteNames.dashboard);
          break;
        case 'showrooms':
          context.goNamed(RouteNames.showrooms);
          break;
        case 'users':
          context.goNamed(RouteNames.users);
          break;
        case 'roles':
          context.goNamed(RouteNames.roles);
          break;
        case 'vehicles':
          context.goNamed(RouteNames.vehicles);
          break;
        case 'inventory':
          context.goNamed(RouteNames.inventory);
          break;
        case 'customers':
          context.goNamed(RouteNames.customers);
          break;
        case 'bookings':
          context.goNamed(RouteNames.bookings);
          break;
        case 'sales':
          context.goNamed(RouteNames.sales);
          break;
        case 'accounts':
          context.goNamed(RouteNames.accounting);
          break;
        case 'finance':
          context.goNamed(RouteNames.finance);
          break;
        case 'expenses':
          context.goNamed(RouteNames.expenses);
          break;
        case 'gst':
          context.goNamed(RouteNames.gstDashboard);
          break;
        case 'reports':
          context.goNamed(RouteNames.reports);
          break;
        case 'documents':
          context.goNamed(RouteNames.documents);
          break;
        case 'approvals':
          context.goNamed(RouteNames.approvals);
          break;
        case 'audit-logs':
          context.goNamed(RouteNames.auditLogs);
          break;
        case 'settings':
          context.goNamed(RouteNames.settings);
          break;
        case 'suppliers':
          context.goNamed(RouteNames.suppliers);
          break;
        case 'purchases':
          context.goNamed(RouteNames.purchases);
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;
    final isDark = context.isDarkMode;

    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final appBar = AppAppBar(
      title: widget.title,
      titleWidget: widget.titleWidget,
      actions: widget.actions,
      currentShowroomName: widget.currentShowroomName,
      onShowroomSwitchTap: widget.onShowroomSwitchTap,
      onMenuTap: !isDesktop ? () => _scaffoldKey.currentState?.openDrawer() : null,
    );

    Widget scaffoldContent;

    // Desktop Layout (Sidebar + Top App Bar + Main Content)
    if (isDesktop && widget.showSidebarOnDesktop) {
      scaffoldContent = Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              AppSidebar(
                activeItemId: _currentNavId,
                onItemTap: _handleNavigation,
              ),
              Expanded(
                child: Column(
                  children: [
                    appBar,
                    Expanded(child: widget.body),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    } else if (isTablet && widget.showSidebarOnDesktop) {
      scaffoldContent = Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Row(
            children: [
              AppSidebar(
                activeItemId: _currentNavId,
                onItemTap: _handleNavigation,
                initialCollapsed: true,
              ),
              Expanded(
                child: Column(
                  children: [
                    appBar,
                    Expanded(child: widget.body),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    } else {
      // Mobile Layout (Drawer + Top App Bar + Body + Bottom Nav)
      scaffoldContent = Scaffold(
        key: _scaffoldKey,
        backgroundColor: backgroundColor,
        appBar: appBar,
        drawer: Drawer(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: AppSidebar(
            activeItemId: _currentNavId,
            onItemTap: _handleNavigation,
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: widget.showBottomNavOnMobile ? false : true,
          left: true,
          right: true,
          child: widget.body,
        ),
        bottomNavigationBar: widget.showBottomNavOnMobile
            ? AppBottomNavigation(
                activeId: _currentNavId,
                onTabSelected: _handleNavigation,
              )
            : null,
        floatingActionButton: widget.floatingActionButton,
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          GlobalSearchModal.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          GlobalSearchModal.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: scaffoldContent,
      ),
    );
  }
}
