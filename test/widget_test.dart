import 'package:flutter_test/flutter_test.dart';
import 'package:lsrms_app/models/student.dart';
import 'package:lsrms_app/utils/grade_calculator.dart';
import 'package:lsrms_app/utils/validators.dart';

void main() {
  group('GradeCalculator boundary tests', () {
    test('returns expected grades at exact boundaries', () {
      expect(GradeCalculator.calculateGrade(100), 'A');
      expect(GradeCalculator.calculateGrade(80), 'A');
      expect(GradeCalculator.calculateGrade(79), 'A-');
      expect(GradeCalculator.calculateGrade(75), 'A-');
      expect(GradeCalculator.calculateGrade(74), 'B+');
      expect(GradeCalculator.calculateGrade(70), 'B+');
      expect(GradeCalculator.calculateGrade(69), 'B');
      expect(GradeCalculator.calculateGrade(65), 'B');
      expect(GradeCalculator.calculateGrade(64), 'B-');
      expect(GradeCalculator.calculateGrade(60), 'B-');
      expect(GradeCalculator.calculateGrade(59), 'C+');
      expect(GradeCalculator.calculateGrade(55), 'C+');
      expect(GradeCalculator.calculateGrade(54), 'C');
      expect(GradeCalculator.calculateGrade(50), 'C');
      expect(GradeCalculator.calculateGrade(49), 'C-');
      expect(GradeCalculator.calculateGrade(45), 'C-');
      expect(GradeCalculator.calculateGrade(44), 'D');
      expect(GradeCalculator.calculateGrade(40), 'D');
      expect(GradeCalculator.calculateGrade(39), 'F');
      expect(GradeCalculator.calculateGrade(0), 'F');
    });
  });

  group('Validators mark validation tests', () {
    test('validates mark range 0 to 100', () {
      expect(Validators.mark('0'), isNull);
      expect(Validators.mark('76.5'), isNull);
      expect(Validators.mark('100'), isNull);
      expect(Validators.mark(''), 'Mark is required');
      expect(Validators.mark('abc'), 'Enter a valid number');
      expect(Validators.mark('-1'), 'Mark must be between 0 and 100');
      expect(Validators.mark('101'), 'Mark must be between 0 and 100');
    });
  });

  group('Student average and overall grade tests', () {
    test('calculates averageMark and overallGrade accurately', () {
      final student = Student(
        studentId: 'BSEM9999F',
        firstName: 'Test',
        lastName: 'Student',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        marks: {'PROG202': 80, 'DBSY201': 70},
      );

      expect(student.averageMark, 75.0);
      expect(student.overallGrade, 'A-');
    });

    test('handles student with no marks', () {
      final student = Student(
        studentId: 'BSEM9998F',
        firstName: 'Empty',
        lastName: 'Marks',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
      );

      expect(student.averageMark, 0.0);
      expect(student.overallGrade, 'N/A');
    });
  });
}