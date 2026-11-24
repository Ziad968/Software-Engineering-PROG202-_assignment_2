import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/app_logo.dart';
import '../widgets/info_row.dart';

/// Screen 13: Application metadata, architecture overview, and assignment details.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: 'About LSRMS'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: const [
                AppLogo(size: 80),
                SizedBox(height: 14),
                Text(
                  AppConstants.appFullName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version ${AppConstants.appVersion}',
                  style: TextStyle(
                    color: AppColors.slate,
                    fontSize: 13,
                  ),
                ),
                Divider(height: 28),
                InfoRow(
                  label: 'Institution',
                  value: AppConstants.institution,
                  icon: Icons.school_outlined,
                ),
                InfoRow(
                  label: 'Module',
                  value: AppConstants.moduleCode,
                  icon: Icons.book_outlined,
                ),
                InfoRow(
                  label: 'Architecture',
                  value: 'Layered Flutter (Material 3 + ChangeNotifier)',
                  icon: Icons.architecture,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppCard(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Features',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.charcoal,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Register students and course modules with duplicate prevention\n'
                  '• Record and update marks (0–100) with live grade preview\n'
                  '• Automatic calculation of student averages and overall grades\n'
                  '• Class-wide analytics with pass rate and grade distribution\n'
                  '• Clean separation of concerns ready for Supabase integration',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.slate,
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