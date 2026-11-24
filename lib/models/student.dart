import '../utils/grade_calculator.dart';

/// Represents a registered student and their module marks.
class Student {
  final String studentId;
  final String firstName;
  final String lastName;
  final String programme;
  final String level;
  final Map<String, double> marks; // moduleCode -> mark (0..100)

  Student({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    required this.programme,
    required this.level,
    Map<String, double>? marks,
  }) : marks = marks ?? {};

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final l = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$f$l';
  }

  bool get hasMarks => marks.isNotEmpty;

  double get averageMark {
    if (marks.isEmpty) return 0.0;
    final total = marks.values.fold<double>(0.0, (sum, m) => sum + m);
    return total / marks.length;
  }

  String get overallGrade {
    if (marks.isEmpty) return 'N/A';
    return GradeCalculator.calculateGrade(averageMark);
  }

  String get overallRemark {
    if (marks.isEmpty) return 'No Marks';
    return GradeCalculator.calculateRemark(averageMark);
  }
}