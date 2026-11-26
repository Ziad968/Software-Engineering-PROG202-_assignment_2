import '../utils/grade_calculator.dart';

/// Represents a registered student and their module marks.
class Student {
  final String studentId;
  final String firstName;
  final String lastName;
  final String email;
  final String programme;
   String level;
   String classCode;
  final Map<String, double> marks;

  Student({
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.email = '',
    required this.programme,
    required this.level,
    this.classCode = '12O1',
    Map<String, double>? marks,
  }) : marks = marks ?? {};

  factory Student.fromSupabaseRows({
    required Map<String, dynamic> studentRow,
    List<Map<String, dynamic>> markRows = const [],
  }) {
    final fullName = (studentRow['full_name'] ?? '').toString().trim();
    final parts =
        fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstName = parts.isNotEmpty ? parts.first : fullName;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    final marksMap = <String, double>{};
    for (final row in markRows) {
      final modCode =
          (row['module_code'] ?? '').toString().trim().toUpperCase();
      final scoreVal = (row['score'] as num?)?.toDouble();
      if (modCode.isNotEmpty && scoreVal != null) {
        marksMap[modCode] = scoreVal;
      }
    }

    final rawId =
        (studentRow['student_id'] ?? '').toString().trim().toUpperCase();
    final rawEmail =
        (studentRow['email'] ?? '').toString().trim().toLowerCase();
    final rawClass =
        (studentRow['class_group'] ?? studentRow['class_code'] ?? '12O1')
            .toString()
            .trim()
            .toUpperCase();

    return Student(
      studentId: rawId,
      firstName: firstName,
      lastName: lastName,
      email: rawEmail.isNotEmpty
          ? rawEmail
          : buildDefaultEmail(firstName, lastName),
      programme: (studentRow['programme'] ?? '').toString().trim(),
      level: (studentRow['academic_level'] ?? '').toString().trim(),
      classCode: rawClass.isNotEmpty ? rawClass : '12O1',
      marks: marksMap,
    );
  }

  static String buildDefaultEmail(String first, String last) {
    final f = first.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final l = last.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (f.isEmpty && l.isEmpty) return '';
    if (l.isEmpty) return '$f@limkokwing.edu.sl';
    return '$f.$l@limkokwing.edu.sl';
  }

  static bool isValidStudentId(String id) {
    return RegExp(r'^90500\d{4}$').hasMatch(id.trim());
  }

  static bool isValidClassCode(String code) {
    return RegExp(r'^[12][1-9]O[1-5]$').hasMatch(code.trim().toUpperCase());
  }

  Map<String, dynamic> toSupabaseMap({String? email, String? emailOverride}) {
    final resolved = (emailOverride ?? email ?? this.email).trim().toLowerCase();
    return {
      'student_id': studentId.trim().toUpperCase(),
      'full_name': fullName.trim(),
      if (resolved.isNotEmpty) 'email': resolved,
      'programme': programme.trim(),
      'academic_level': level.trim(),
      'class_group': classCode.trim().toUpperCase(),
      'is_active': true,
    };
  }

  String get fullName => '$firstName $lastName'.trim();

  String get resolvedEmail => email.trim().isNotEmpty
      ? email.trim()
      : buildDefaultEmail(firstName, lastName);

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