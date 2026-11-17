import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/ai/ai_settings_screen.dart';
import '../features/tenant/ui/case_detail_screen.dart';
import '../features/tenant/ui/cases_screen.dart';
import '../features/tenant/ui/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/cases',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _TenantShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cases',
              builder: (context, state) => const CasesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      CaseDetailScreen(caseId: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'ai',
                  builder: (context, state) => const AiSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _TenantShell extends StatelessWidget {
  const _TenantShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Actas',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

