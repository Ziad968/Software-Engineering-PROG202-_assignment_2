import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/grade_calculator.dart';
import '../widgets/app_card.dart';
import '../widgets/grade_chip.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_card.dart';

/// Screen 6 (Tab 4): Summary screen showing personal academic summary & GPA for
/// Students, or class summary & grade distribution for Administrator/Lecturer.
class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (service.isStudent) {
          return _StudentPersonalSummary(service: service);
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: const TabBar(
                  labelColor: AppColors.primaryRed,
                  unselectedLabelColor: AppColors.slate,
                  indicatorColor: AppColors.primaryRed,
                  tabs: [
                    Tab(icon: Icon(Icons.insights), text: 'Overview'),
                    Tab(icon: Icon(Icons.bar_chart), text: 'Grade Distribution'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _OverviewTab(service: service),
                    _GradesDistributionTab(service: service),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentPersonalSummary extends StatelessWidget {
  final ResultsService service;

  const _StudentPersonalSummary({required this.service});

  double _estimatedGpa(double avg) {
    if (avg >= 80) return 4.0;
    if (avg >= 75) return 3.7;
    if (avg >= 70) return 3.3;
    if (avg >= 65) return 3.0;
    if (avg >= 60) return 2.7;
    if (avg >= 55) return 2.3;
    if (avg >= 50) return 2.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final student = service.currentStudentRecord;
    final hasMarks = student != null && student.hasMarks;
    final avg = hasMarks ? student.averageMark : 0.0;
    final gpa = hasMarks ? _estimatedGpa(avg) : 0.0;
    final grade = hasMarks ? student.overallGrade : 'N/A';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(title: 'My Academic Summary'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          children: [
            StatCard(
              title: 'My Average',
              value: hasMarks ? '${avg.toStringAsFixed(1)}%' : 'N/A',
              icon: Icons.percent,
              accentColor: AppColors.primaryRed,
            ),
            StatCard(
              title: 'Estimated GPA',
              value: hasMarks ? gpa.toStringAsFixed(2) : 'N/A',
              icon: Icons.school,
              accentColor: AppColors.gradeGreen,
            ),
            StatCard(
              title: 'Graded Modules',
              value: '${student?.marks.length ?? 0}',
              icon: Icons.menu_book,
              accentColor: AppColors.gradeBlue,
            ),
            StatCard(
              title: 'Overall Grade',
              value: grade,
              icon: Icons.grade,
              accentColor: AppColors.gradeOrange,
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student?.fullName ?? 'Student Summary',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasMarks
                          ? 'Standing: ${student.overallRemark}'
                          : 'No recorded results yet',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              GradeChip(grade: grade, isLarge: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ResultsService service;

  const _OverviewTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final classGrade = service.totalMarksRecorded > 0
        ? GradeCalculator.calculateGrade(service.classAverage)
        : 'N/A';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.15,
          children: [
            StatCard(
              title: 'Class Average',
              value: '${service.classAverage.toStringAsFixed(1)}%',
              icon: Icons.analytics,
              accentColor: AppColors.primaryRed,
            ),
            StatCard(
              title: 'Pass Rate',
              value: '${service.passRate.toStringAsFixed(0)}%',
              icon: Icons.check_circle_outline,
              accentColor: AppColors.gradeGreen,
            ),
            StatCard(
              title: 'Highest Student Avg',
              value: '${service.highestStudentAverage.toStringAsFixed(1)}%',
              icon: Icons.emoji_events_outlined,
              accentColor: AppColors.gradeBlue,
            ),
            StatCard(
              title: 'Lowest Student Avg',
              value: '${service.lowestStudentAverage.toStringAsFixed(1)}%',
              icon: Icons.trending_down,
              accentColor: AppColors.gradeOrange,
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Class Standing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: AppColors.charcoal,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Calculated across all students with recorded marks',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              GradeChip(grade: classGrade, isLarge: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradesDistributionTab extends StatelessWidget {
  final ResultsService service;

  const _GradesDistributionTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final dist = service.gradeDistribution;
    final totalGraded = dist.values.fold<int>(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(title: 'Student Grade Breakdown'),
        const SizedBox(height: 8),
        ...dist.entries.map((entry) {
          final count = entry.value;
          final ratio = totalGraded > 0 ? count / totalGraded : 0.0;
          final color = AppColors.gradeForeground(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: GradeChip(grade: entry.key),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: AppColors.border.withValues(alpha: 0.5),
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$count (${(ratio * 100).toStringAsFixed(0)}%)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: AppColors.charcoal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}