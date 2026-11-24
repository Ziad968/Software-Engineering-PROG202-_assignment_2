import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../utils/grade_calculator.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_card.dart';
import '../widgets/grade_chip.dart';

/// Screen 12: Displays the complete Limkokwing grading scale table.
class GradingScaleScreen extends StatelessWidget {
  const GradingScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: 'Grading Scale'),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: GradeCalculator.scale.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final entry = GradeCalculator.scale[index];
          return AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    entry.rangeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.remark,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: AppColors.slate,
                    ),
                  ),
                ),
                GradeChip(grade: entry.grade),
              ],
            ),
          );
        },
      ),
    );
  }
}