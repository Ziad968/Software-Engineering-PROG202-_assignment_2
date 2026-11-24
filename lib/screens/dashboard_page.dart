import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../widgets/action_tile.dart';
import '../widgets/app_logo.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_card.dart';
import '../widgets/student_tile.dart';

/// Screen 3 (Tab 1): Dashboard with welcome banner, compact stat cards,
/// role-aware quick actions, and student results preview.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final visibleList = service.visibleStudents;
        final recentStudents = visibleList.take(3).toList();
        final currentStudent = service.currentStudentRecord;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            // Welcome Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const AppLogo(size: 50, showBorder: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${service.currentUserRole}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          AppConstants.institution,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Overview Stats GridView (compact cards)
            const SectionTitle(title: 'Academic Overview'),
            const SizedBox(height: 8),
            if (service.isStudent) ...[
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.5,
                children: [
                  StatCard(
                    title: 'My Modules',
                    value: '${currentStudent?.marks.length ?? 0}',
                    icon: Icons.menu_book,
                    accentColor: AppColors.primaryRed,
                  ),
                  StatCard(
                    title: 'My Average',
                    value: currentStudent != null && currentStudent.hasMarks
                        ? '${currentStudent.averageMark.toStringAsFixed(1)}%'
                        : 'N/A',
                    icon: Icons.trending_up,
                    accentColor: AppColors.gradeGreen,
                  ),
                  StatCard(
                    title: 'Overall Grade',
                    value: currentStudent != null && currentStudent.hasMarks
                        ? currentStudent.overallGrade
                        : 'N/A',
                    icon: Icons.grade_outlined,
                    accentColor: AppColors.gradeBlue,
                  ),
                  StatCard(
                    title: 'Standing',
                    value: currentStudent != null && currentStudent.hasMarks
                        ? (currentStudent.averageMark >= 50
                            ? 'Passed'
                            : 'Needs Review')
                        : 'Pending',
                    icon: Icons.verified_outlined,
                    accentColor: AppColors.gradeOrange,
                  ),
                ],
              ),
            ] else ...[
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.55,
                children: [
                  StatCard(
                    title: 'Total Students',
                    value: '${service.totalStudents}',
                    icon: Icons.people,
                    accentColor: AppColors.primaryRed,
                  ),
                  StatCard(
                    title: 'Total Modules',
                    value: '${service.totalModules}',
                    icon: Icons.menu_book,
                    accentColor: AppColors.gradeBlue,
                  ),
                  StatCard(
                    title: 'Marks Recorded',
                    value: '${service.totalMarksRecorded}',
                    icon: Icons.assignment_turned_in,
                    accentColor: AppColors.gradeGreen,
                  ),
                  StatCard(
                    title: 'Class Average',
                    value: '${service.classAverage.toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    accentColor: AppColors.gradeOrange,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),

            // Quick Actions GridView (role-aware)
            if (!service.isStudent) ...[
              const SectionTitle(title: 'Quick Actions'),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.55,
                children: [
                  if (service.canRecordMarks)
                    ActionTile(
                      title: 'Record Mark',
                      subtitle: 'Enter or update grade',
                      icon: Icons.edit_note,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.recordMark),
                    ),
                  if (service.canManageStudentsAndModules)
                    ActionTile(
                      title: 'Register Student',
                      subtitle: 'Add new student profile',
                      icon: Icons.person_add_alt_1,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.registerStudent),
                    ),
                  if (service.canManageStudentsAndModules)
                    ActionTile(
                      title: 'Register Module',
                      subtitle: 'Create course module',
                      icon: Icons.library_add,
                      onTap: () =>
                          Navigator.pushNamed(context, Routes.registerModule),
                    ),
                  ActionTile(
                    title: 'Grade Calculator',
                    subtitle: 'Instant mark conversion',
                    icon: Icons.calculate,
                    onTap: () =>
                        Navigator.pushNamed(context, Routes.gradeCalculator),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],

            // Student Results / Recent Students
            SectionTitle(
              title: service.isStudent ? 'My Results Summary' : 'Recent Students',
            ),
            const SizedBox(height: 8),
            ...recentStudents.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StudentTile(
                  student: student,
                  onTap: () => Navigator.pushNamed(
                    context,
                    Routes.studentDetail,
                    arguments: student.studentId,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}