import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import 'app_logo.dart';

/// Navigation drawer providing role-aware actions, utility screens, and logout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            color: AppColors.primaryRed,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(size: 54, showBorder: false),
                const SizedBox(height: 12),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  service.currentUserEmail.isEmpty
                      ? AppConstants.adminEmail
                      : service.currentUserEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    service.currentUserRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (service.canManageAccounts)
                  ListTile(
                    leading: const Icon(
                      Icons.manage_accounts_outlined,
                      color: AppColors.primaryRed,
                    ),
                    title: const Text('Manage Accounts'),
                    subtitle: const Text(
                      'Add, edit, promote, or remove accounts',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.manageAccounts);
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.calculate_outlined,
                    color: AppColors.primaryRed,
                  ),
                  title: const Text('Grade Calculator'),
                  subtitle: const Text('Convert numeric mark to grade'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.gradeCalculator);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.table_chart_outlined,
                    color: AppColors.primaryRed,
                  ),
                  title: const Text('Grading Scale'),
                  subtitle: const Text('Official Limkokwing grade bands'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.gradingScale);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primaryRed,
                  ),
                  title: const Text('About LSRMS'),
                  subtitle: const Text('System info & features'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Routes.about);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppColors.gradeRed,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.gradeRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    service.clearSession();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}