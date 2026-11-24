/// Represents one row in the Limkokwing grading scale.
class GradeScaleEntry {
  final int minMark;
  final int maxMark;
  final String grade;
  final String remark;

  const GradeScaleEntry({
    required this.minMark,
    required this.maxMark,
    required this.grade,
    required this.remark,
  });

  String get rangeLabel => '$minMark - $maxMark';
}

/// Core grading scale and grade calculation logic ported from Assignment 1.
class GradeCalculator {
  GradeCalculator._();

  static const List<GradeScaleEntry> scale = [
    GradeScaleEntry(minMark: 80, maxMark: 100, grade: 'A', remark: 'Excellent'),
    GradeScaleEntry(minMark: 75, maxMark: 79, grade: 'A-', remark: 'Very Good'),
    GradeScaleEntry(minMark: 70, maxMark: 74, grade: 'B+', remark: 'Good'),
    GradeScaleEntry(minMark: 65, maxMark: 69, grade: 'B', remark: 'Good'),
    GradeScaleEntry(
        minMark: 60, maxMark: 64, grade: 'B-', remark: 'Satisfactory'),
    GradeScaleEntry(
        minMark: 55, maxMark: 59, grade: 'C+', remark: 'Satisfactory'),
    GradeScaleEntry(minMark: 50, maxMark: 54, grade: 'C', remark: 'Pass'),
    GradeScaleEntry(minMark: 45, maxMark: 49, grade: 'C-', remark: 'Pass'),
    GradeScaleEntry(
        minMark: 40, maxMark: 44, grade: 'D', remark: 'Marginal Pass'),
    GradeScaleEntry(minMark: 0, maxMark: 39, grade: 'F', remark: 'Fail'),
  ];

  /// Calculates letter grade from a numeric mark (0 - 100).
  static String calculateGrade(double mark) {
    final rounded = mark.round();
    if (rounded >= 80) return 'A';
    if (rounded >= 75) return 'A-';
    if (rounded >= 70) return 'B+';
    if (rounded >= 65) return 'B';
    if (rounded >= 60) return 'B-';
    if (rounded >= 55) return 'C+';
    if (rounded >= 50) return 'C';
    if (rounded >= 45) return 'C-';
    if (rounded >= 40) return 'D';
    return 'F';
  }

  /// Calculates descriptive remark from a numeric mark (0 - 100).
  static String calculateRemark(double mark) {
    final rounded = mark.round();
    if (rounded >= 80) return 'Excellent';
    if (rounded >= 75) return 'Very Good';
    if (rounded >= 70) return 'Good';
    if (rounded >= 65) return 'Good';
    if (rounded >= 60) return 'Satisfactory';
    if (rounded >= 55) return 'Satisfactory';
    if (rounded >= 50) return 'Pass';
    if (rounded >= 45) return 'Pass';
    if (rounded >= 40) return 'Marginal Pass';
    return 'Fail';
  }

  /// Returns true if mark is considered a passing mark (>= 40).
  static bool isPass(double mark) => mark.round() >= 40;
}