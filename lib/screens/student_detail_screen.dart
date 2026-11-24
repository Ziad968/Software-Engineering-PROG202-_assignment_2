import 'package:flutter/material.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/grade_calculator.dart';
import '../utils/ui_helpers.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/grade_chip.dart';
import '../widgets/info_row.dart';
import '../widgets/section_title.dart';

/// Screen 7: Student profile, module results, average, and overall grade.
/// Students have read-only access to their own record.
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentId =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final student = service.findStudent(studentId);
        if (student == null) {
          return Scaffold(
            appBar: buildAppBar(title: 'Student Details'),
            body: const EmptyState(
              icon: Icons.error_outline,
              title: 'Student Not Found',
              subtitle: 'The requested student record could not be located.',
            ),
          );
        }

        return Scaffold(
          appBar: buildAppBar(
            title: student.fullName,
            actions: [
              if (service.canManageStudentsAndModules)
                IconButton(
                  tooltip: 'Delete Student',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await UIHelpers.showConfirmDialog(
                      context,
                      title: 'Delete Student',
                      content:
                          'Remove ${student.fullName} (${student.studentId}) and all recorded marks?',
                      confirmText: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed && context.mounted) {
                      service.deleteStudent(student.studentId);
                      UIHelpers.showSnackBar(
                        context,
                        'Student ${student.studentId} deleted',
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            student.initials,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              Text(
                                student.studentId,
                                style: const TextStyle(
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GradeChip(grade: student.overallGrade, isLarge: true),
                      ],
                    ),
                    const Divider(height: 20),
                    InfoRow(
                      label: 'Programme',
                      value: student.programme,
                      icon: Icons.school_outlined,
                    ),
                    InfoRow(
                      label: 'Level',
                      value: student.level,
                      icon: Icons.layers_outlined,
                    ),
                    InfoRow(
                      label: 'Average Mark',
                      value: student.hasMarks
                          ? '${student.averageMark.toStringAsFixed(2)}% (${student.overallRemark})'
                          : 'No marks yet',
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SectionTitle(
                title: 'Module Results (${student.marks.length})',
              ),
              const SizedBox(height: 8),

              if (!student.hasMarks)
                const AppCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'No marks recorded for this student yet.',
                        style: TextStyle(color: AppColors.slate),
                      ),
                    ),
                  ),
                )
              else
                ...student.marks.entries.map((entry) {
                  final module = service.findModule(entry.key);
                  final mark = entry.value;
                  final grade = GradeCalculator.calculateGrade(mark);
                  final remark = GradeCalculator.calculateRemark(mark);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: AppColors.primaryRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  module?.name ?? 'Registered Module',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Score: ${mark.toStringAsFixed(1)} / 100 • $remark',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GradeChip(grade: grade),
                        ],
                      ),
                    ),
                  );
                }),

              if (service.canRecordMarks) ...[
                const SizedBox(height: 16),
                AppButton(
                  label: 'Record / Update Mark',
                  icon: Icons.edit_note,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.recordMark,
                    arguments: student.studentId,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}