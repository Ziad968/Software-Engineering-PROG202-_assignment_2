import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Colour-coded grade badge in standard or large size.
class GradeChip extends StatelessWidget {
  final String grade;
  final bool isLarge;

  const GradeChip({
    super.key,
    required this.grade,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = grade == 'N/A' ? AppColors.slate : AppColors.gradeForeground(grade);
    final bg = grade == 'N/A' ? const Color(0xFFEEEEEE) : AppColors.gradeBackground(grade);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 16 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isLarge ? 10 : 8),
        border: Border.all(color: fg.withOpacity(0.35)),
      ),
      child: Text(
        grade,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: isLarge ? 18 : 13,
        ),
      ),
    );
  }
}