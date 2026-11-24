import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/grade_calculator.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/grade_chip.dart';

/// Screen 5 (Tab 3): ListView of modules with average mark (or student's mark)
/// and overall grade badge.
class ModulesPage extends StatelessWidget {
  const ModulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final modules = service.modules;
        if (modules.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No Modules Registered',
            subtitle: 'Tap Add Module below to create a new academic course.',
          );
        }

        final studentMarks = service.currentStudentRecord?.marks;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
          itemCount: modules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final module = modules[index];
            final marks = service.getModuleMarks(module.code);
            final avg = service.getModuleAverage(module.code);
            final myMark = studentMarks?[module.code];

            final displayScore = service.isStudent ? myMark : avg;
            final grade = displayScore != null
                ? GradeCalculator.calculateGrade(displayScore)
                : 'N/A';

            final subtitleText = service.isStudent
                ? (myMark != null
                    ? 'Your Mark: ${myMark.toStringAsFixed(1)}%'
                    : 'No mark recorded for you yet')
                : (avg != null
                    ? 'Average: ${avg.toStringAsFixed(1)}% (${marks.length} students graded)'
                    : 'No marks recorded yet');

            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      size: 20,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${module.code} • ${module.credits} Credits',
                          style: const TextStyle(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          module.name,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitleText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GradeChip(grade: grade),
                ],
              ),
            );
          },
        );
      },
    );
  }
}