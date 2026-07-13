/// Tspace Main Shell — Bottom Navigation Container
///
/// Wraps the four primary dashboard tabs (Grid Editor, Analytics, Inbox, Settings)
/// in a persistent bottom navigation bar using the design system tokens.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// The persistent shell widget rendered by [ShellRoute].
///
/// Maintains the bottom navigation state and swaps the child
/// route content without rebuilding the navigation bar.
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(RoutePaths.editor)) return 0;
    if (location.startsWith(RoutePaths.analytics)) return 1;
    if (location.startsWith(RoutePaths.inbox)) return 2;
    if (location.startsWith(RoutePaths.settings)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.editor);
      case 1:
        context.go(RoutePaths.analytics);
      case 2:
        context.go(RoutePaths.inbox);
      case 3:
        context.go(RoutePaths.settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (i) => _onTap(context, i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Grid',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mail_outline_rounded),
              activeIcon: Icon(Icons.mail_rounded),
              label: 'Inbox',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
