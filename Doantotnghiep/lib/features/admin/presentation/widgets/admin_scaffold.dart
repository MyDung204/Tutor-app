import 'package:doantotnghiep/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminScaffold extends StatelessWidget {
  final Widget navigationShell;

  const AdminScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800; // Breakpoint for admin panel

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.white,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onItemTapped(context, index),
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              unselectedLabelTextStyle: const TextStyle(color: AppTheme.textSecondary),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
                  label: Text('Tổng quan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outlined),
                  selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
                  label: Text('Người dùng'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.verified_user_outlined),
                  selectedIcon: Icon(Icons.verified_user, color: AppTheme.primaryColor),
                  label: Text('Kiểm duyệt'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.report_outlined),
                  selectedIcon: Icon(Icons.report, color: AppTheme.primaryColor),
                  label: Text('Báo cáo'),
                ),
              ],
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: const Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppTheme.dividerColor),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryColor.withOpacity(0.1),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people, color: AppTheme.primaryColor),
            label: 'Người dùng',
          ),
           NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user, color: AppTheme.primaryColor),
            label: 'Kiểm duyệt',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report, color: AppTheme.primaryColor),
            label: 'Báo cáo',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin')) {
      if (location.endsWith('/users') || location.contains('/users/')) return 1;
      if (location.endsWith('/tutors') || location.endsWith('/approve')) return 2;
      if (location.endsWith('/reports')) return 3;
      return 0; // Dashboard
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/users');
        break;
      case 2:
        context.go('/admin/tutors');
        break;
      case 3:
        context.go('/admin/reports');
        break;
    }
  }
}
