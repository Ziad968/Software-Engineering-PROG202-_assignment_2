import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/student.dart';
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
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  bool _isDeleting = false;

  Future<void> _showEditClassAndSemesterDialog(
    BuildContext context,
    ResultsService service,
    Student student,
  ) async {
    final current = student.classCode.toUpperCase();
    String semester =
        current.length >= 4 && AppConstants.semesters.contains(current[0])
            ? current[0]
            : '1';
    String year =
        current.length >= 4 && AppConstants.studyYears.contains(current[1])
            ? current[1]
            : '2';
    final rawSection = current.length >= 4 ? current.substring(2) : 'O1';
    String section = AppConstants.classSections.contains(rawSection)
        ? rawSection
        : 'O1';

    String selectedLevel = AppConstants.academicLevels.contains(student.level)
        ? student.level
        : 'Year $year - Semester $semester';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final previewClass = '$semester$year$section';
          return AlertDialog(
            title: const Text('Update Class & Semester'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student: ${student.fullName} (${student.studentId})',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: AppConstants.semesters
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text('Semester $s'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          semester = val;
                          final candidateLevel = 'Year $year - Semester $semester';
                          if (AppConstants.academicLevels
                              .contains(candidateLevel)) {
                            selectedLevel = candidateLevel;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: year,
                    decoration: const InputDecoration(labelText: 'Study Year'),
                    items: AppConstants.studyYears
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text('Year $y'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          year = val;
                          final candidateLevel = 'Year $year - Semester $semester';
                          if (AppConstants.academicLevels
                              .contains(candidateLevel)) {
                            selectedLevel = candidateLevel;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: section,
                    decoration: const InputDecoration(labelText: 'Class Section'),
                    items: AppConstants.classSections
                        .map((sec) => DropdownMenuItem(
                              value: sec,
                              child: Text(sec),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => section = val);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration:
                        const InputDecoration(labelText: 'Academic Level'),
                    items: AppConstants.academicLevels
                        .map((lvl) => DropdownMenuItem(
                              value: lvl,
                              child: Text(lvl),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedLevel = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Class Code: $previewClass',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, {
                  'classCode': previewClass,
                  'level': selectedLevel,
                }),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || !context.mounted) return;

    final updated = await service.updateStudentClassAndLevel(
  studentId: student.studentId,
  newClassCode: result['classCode']!,
  newLevel: result['level']!,
);

    if (!context.mounted) return;
    if (updated) {
      UIHelpers.showSnackBar(
        context,
        'Updated to ${result['classCode']} (${result['level']})',
      );
    } else {
      UIHelpers.showSnackBar(
        context,
        'Unable to update class and semester.',
        isError: true,
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    ResultsService service,
    String studentId,
    String fullName,
  ) async {
    if (_isDeleting) return;

    final confirmed = await UIHelpers.showConfirmDialog(
      context,
      title: 'Delete Student',
      content: 'Remove $fullName ($studentId) and all recorded marks?',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) return;

    setState(() => _isDeleting = true);
    final deleted = service.deleteStudent(studentId);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!context.mounted) return;
    setState(() => _isDeleting = false);

    if (deleted) {
      UIHelpers.showSnackBar(
        context,
        'Student $studentId deleted',
      );
      Navigator.pop(context);
    } else {
      UIHelpers.showSnackBar(
        context,
        'Unable to delete student.',
        isError: true,
      );
    }
  }

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
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  onPressed: _isDeleting
                      ? null
                      : () => _handleDelete(
                            context,
                            service,
                            student.studentId,
                            student.fullName,
                          ),
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
                      label: 'Email',
                      value: student.resolvedEmail,
                      icon: Icons.email_outlined,
                    ),
                    InfoRow(
                      label: 'Programme',
                      value: student.programme,
                      icon: Icons.school_outlined,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: InfoRow(
                            label: 'Class',
                            value: student.classCode,
                            icon: Icons.class_outlined,
                          ),
                        ),
                        if (service.canRecordMarks)
                          IconButton(
                            tooltip: 'Edit Class & Semester',
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primaryRed,
                            ),
                            onPressed: () => _showEditClassAndSemesterDialog(
                              context,
                              service,
                              student,
                            ),
                          ),
                      ],
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