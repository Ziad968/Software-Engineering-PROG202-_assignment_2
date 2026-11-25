/// Application-wide constants and static lookup lists.
class AppConstants {
  AppConstants._();

  static const String appName = 'LSRMS';
  static const String appFullName =
      'Limkokwing Student Results Management System';
  static const String institution =
      'Limkokwing University of Creative Technology, Sierra Leone';
  static const String moduleCode = 'PROG 202 - Software Engineering';
  static const String appVersion = '1.0.2+3';
  static const String logoAssetPath = 'assets/app_icon.png';

  // Default prototype accounts (also documented in README.md)
  static const String adminEmail = 'admin@limkokwing.edu.sl';
  static const String adminPassword = 'admin123';

  static const String lecturerEmail = 'lecturer@limkokwing.edu.sl';
  static const String lecturerPassword = 'lec123';

  static const String studentEmail = 'student@limkokwing.edu.sl';
  static const String studentPassword = 'stu123';

  // Roles
  static const List<String> userRoles = [
    'Administrator',
    'Lecturer',
    'Student',
  ];

  static const List<String> programmes = [
    'BSc (Hons) Software Engineering',
    'BSc (Hons) Information Technology',
    'BSc (Hons) Business Information Technology',
    'Associate Degree in Information Technology',
  ];

  static const List<String> academicLevels = [
    'Year 1 - Semester 1',
    'Year 1 - Semester 2',
    'Year 2 - Semester 1',
    'Year 2 - Semester 2',
    'Year 3 - Semester 1',
    'Year 3 - Semester 2',
    'Year 4 - Semester 1',
    'Year 4 - Semester 2',
  ];
}