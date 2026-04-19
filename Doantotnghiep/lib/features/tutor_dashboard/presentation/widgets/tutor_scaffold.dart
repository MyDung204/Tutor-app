import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TutorScaffold extends StatelessWidget {
  final Widget navigationShell;

  const TutorScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Tìm lớp',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Lịch dạy',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/tutor-dashboard')) {
      if (location.endsWith('/find-students')) return 1;
      if (location.endsWith('/schedule')) return 2;
      if (location.endsWith('/messages')) return 3;
      if (location.endsWith('/profile')) return 4;
      return 0;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/tutor-dashboard');
        break;
      case 1:
        context.go('/tutor-dashboard/find-students');
        break;
      case 2:
        context.go('/tutor-dashboard/schedule');
        break;
      case 3:
        context.go('/tutor-dashboard/messages');
        break;
      case 4:
        context.go('/tutor-dashboard/profile');
        break;
    }
  }
}
