import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../services/results_service.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_drawer.dart';
import 'dashboard_page.dart';
import 'modules_page.dart';
import 'students_page.dart';
import 'summary_page.dart';

/// Main navigation shell hosting the 4 bottom tabs via IndexedStack and
/// role-aware contextual FAB actions.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'LSRMS Dashboard',
    'Students',
    'Modules',
    'Class Summary',
  ];

  final List<Widget> _pages = const [
    DashboardPage(),
    StudentsPage(),
    ModulesPage(),
    SummaryPage(),
  ];

  Future<void> _handleSync() async {
    final service = ResultsService.instance;
    if (service.isSyncing) return;
    await service.syncFromSupabase();
    if (!mounted) return;
    UIHelpers.showSnackBar(context, 'Data synced with Supabase.');
  }

  Widget? _buildContextualFab() {
    final service = ResultsService.instance;

    // Student is read-only: no record mark, add student, or add module FABs.
    if (service.isStudent) {
      return null;
    }

    switch (_currentIndex) {
      case 0:
        if (!service.canRecordMarks) return null;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, Routes.recordMark),
          icon: const Icon(Icons.edit_note),
          label: const Text('Record Mark'),
        );
      case 1:
        if (!service.canManageStudentsAndModules) return null;
        return FloatingActionButton.extended(
          onPressed: () =>
              Navigator.pushNamed(context, Routes.registerStudent),
          icon: const Icon(Icons.person_add),
          label: const Text('Add Student'),
        );
      case 2:
        if (!service.canManageStudentsAndModules) return null;
        return FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, Routes.registerModule),
          icon: const Icon(Icons.library_add),
          label: const Text('Add Module'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return Scaffold(
          appBar: buildAppBar(
            title: _titles[_currentIndex],
            actions: [
              if (service.isAdmin)
                Tooltip(
                  message:
                      'Active: ${service.activeAccountsCount} • Inactive: ${service.inactiveAccountsCount}',
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${service.activeAccountsCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Sync with Supabase',
                icon: service.isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                onPressed: service.isSyncing ? null : _handleSync,
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          floatingActionButton: _buildContextualFab(),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) =>
                setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Modules',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Summary',
              ),
            ],
          ),
        );
      },
    );
  }
}