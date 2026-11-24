import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../services/results_service.dart';
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
    return Scaffold(
      appBar: buildAppBar(title: _titles[_currentIndex]),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: _buildContextualFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
  }
}