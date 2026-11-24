import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/student.dart';
import 'app_card.dart';
import 'grade_chip.dart';

/// Student list item showing avatar initials, ID, programme, average, and grade chip.
class StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onTap;

  const StudentTile({
    super.key,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              student.initials,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.studentId} • ${student.level}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.hasMarks
                      ? 'Avg: ${student.averageMark.toStringAsFixed(1)}% (${student.marks.length} modules)'
                      : 'No marks recorded yet',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GradeChip(grade: student.overallGrade),
        ],
      ),
    );
  }
}