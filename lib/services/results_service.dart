import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/module.dart';
import '../models/student.dart';
import '../utils/grade_calculator.dart';

/// Represents a prototype user account stored in memory.
class UserAccount {
  final String name;
  String email;
  String password;
  String role; // 'Administrator', 'Lecturer', 'Student'
  final String? linkedStudentId;

  UserAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.linkedStudentId,
  });
}

/// Singleton state & business logic layer holding students, modules, marks,
/// prototype user accounts, and role-based permissions.
class ResultsService extends ChangeNotifier {
  ResultsService._internal() {
    _seedInitialData();
  }

  static final ResultsService instance = ResultsService._internal();

  final List<Student> _students = [];
  final List<Module> _modules = [];
  final List<UserAccount> _accounts = [];

  String _currentUserEmail = '';
  String _currentUserRole = 'Administrator';

  List<Student> get students => List.unmodifiable(_students);
  List<Module> get modules => List.unmodifiable(_modules);
  List<UserAccount> get accounts => List.unmodifiable(_accounts);
  String get currentUserEmail => _currentUserEmail;
  String get currentUserRole => _currentUserRole;

  // Role helpers
  bool get isAdmin => _currentUserRole == 'Administrator';
  bool get isLecturer => _currentUserRole == 'Lecturer';
  bool get isStudent => _currentUserRole == 'Student';

  // Permission helpers
  bool get canManageAccounts => isAdmin;
  bool get canManageStudentsAndModules => isAdmin;
  bool get canRecordMarks => isAdmin || isLecturer;
  bool get canViewAllStudents => isAdmin || isLecturer;

  /// Returns the currently logged-in account if found.
  UserAccount? get currentAccount {
    if (_currentUserEmail.isEmpty) return null;
    final normalized = _currentUserEmail.trim().toLowerCase();
    for (final acc in _accounts) {
      if (acc.email.toLowerCase() == normalized) {
        return acc;
      }
    }
    return null;
  }

  /// Resolves the student record linked to the current account (if any).
  Student? get currentStudentRecord {
    if (!isStudent) return null;

    final acc = currentAccount;
    if (acc?.linkedStudentId != null && acc!.linkedStudentId!.trim().isNotEmpty) {
      final linked = findStudent(acc.linkedStudentId!);
      if (linked != null) return linked;
    }

    if (_currentUserEmail.isNotEmpty) {
      final prefix = _currentUserEmail.split('@').first.trim().toUpperCase();
      final byId = findStudent(prefix);
      if (byId != null) return byId;

      for (final s in _students) {
        final fullNameSlug =
            '${s.firstName}.${s.lastName}'.toLowerCase().replaceAll(' ', '');
        if (_currentUserEmail.toLowerCase().startsWith(fullNameSlug)) {
          return s;
        }
      }
    }

    return _students.isNotEmpty ? _students.first : null;
  }

  /// Returns students visible to the active role.
  List<Student> get visibleStudents {
    if (canViewAllStudents) return students;
    final self = currentStudentRecord;
    return self != null ? [self] : const [];
  }

  void setSession({required String email, required String role}) {
    _currentUserEmail = email.trim();
    _currentUserRole = role;
    notifyListeners();
  }

  void clearSession() {
    _currentUserEmail = '';
    _currentUserRole = 'Administrator';
    notifyListeners();
  }

  /// Authenticates email and password against in-memory accounts.
  UserAccount? authenticate(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final acc in _accounts) {
      if (acc.email.toLowerCase() == normalizedEmail &&
          acc.password == password) {
        return acc;
      }
    }
    return null;
  }

  /// Administrator can add Lecturer or Student accounts.
  bool addAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    String? linkedStudentId,
  }) {
    if (!canManageAccounts) return false;
    if (role != 'Lecturer' && role != 'Student') return false;

    final normalized = email.trim().toLowerCase();
    final exists = _accounts.any((a) => a.email.toLowerCase() == normalized);
    if (exists) return false;

    _accounts.add(
      UserAccount(
        name: name.trim(),
        email: email.trim(),
        password: password,
        role: role,
        linkedStudentId: role == 'Student' &&
                linkedStudentId != null &&
                linkedStudentId.trim().isNotEmpty
            ? linkedStudentId.trim().toUpperCase()
            : null,
      ),
    );
    notifyListeners();
    return true;
  }

  /// Administrator can update email or password for Lecturer or Student accounts.
  bool updateAccountCredentials({
    required String currentEmail,
    String? newEmail,
    String? newPassword,
  }) {
    if (!canManageAccounts) return false;

    final targetIndex = _accounts.indexWhere(
      (a) => a.email.toLowerCase() == currentEmail.trim().toLowerCase(),
    );
    if (targetIndex == -1) return false;

    final acc = _accounts[targetIndex];
    if (acc.role == 'Administrator') return false;

    if (newEmail != null && newEmail.trim().isNotEmpty) {
      final candidate = newEmail.trim().toLowerCase();
      final conflict = _accounts.asMap().entries.any(
            (e) =>
                e.key != targetIndex && e.value.email.toLowerCase() == candidate,
          );
      if (conflict) return false;
      acc.email = newEmail.trim();
    }

    if (newPassword != null && newPassword.isNotEmpty) {
      acc.password = newPassword;
    }

    notifyListeners();
    return true;
  }

  /// Administrator can promote a Lecturer to Administrator or demote back to
  /// Lecturer (excluding the primary seeded Administrator account).
  bool setLecturerAdminStatus({
    required String email,
    required bool makeAdmin,
  }) {
    if (!canManageAccounts) return false;
    if (email.trim().toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
      return false;
    }

    final acc = _accounts.cast<UserAccount?>().firstWhere(
          (a) => a?.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => null,
        );
    if (acc == null) return false;
    if (acc.role == 'Student') return false;

    acc.role = makeAdmin ? 'Administrator' : 'Lecturer';
    notifyListeners();
    return true;
  }

  /// Administrator can promote an existing Lecturer to Administrator.
  bool promoteLecturerToAdmin(String email) {
    return setLecturerAdminStatus(email: email, makeAdmin: true);
  }

  /// Administrator can remove Lecturer or Student accounts.
  bool removeAccount(String email) {
    if (!canManageAccounts) return false;
    if (email.trim().toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
      return false;
    }

    final acc = _accounts.cast<UserAccount?>().firstWhere(
          (a) => a?.email.toLowerCase() == email.trim().toLowerCase(),
          orElse: () => null,
        );
    if (acc == null) return false;

    _accounts.remove(acc);
    notifyListeners();
    return true;
  }

  /// Allows the currently logged-in user (including Administrator) to change
  /// their own password after verifying their current password.
  bool changeCurrentUserPassword({
    required String currentPassword,
    required String newPassword,
  }) {
    final acc = currentAccount;
    if (acc == null) return false;
    if (acc.password != currentPassword) return false;
    if (newPassword.isEmpty) return false;

    acc.password = newPassword;
    notifyListeners();
    return true;
  }

  /// Resets data to initial sample set (useful for testing).
  void resetToSampleData() {
    _students.clear();
    _modules.clear();
    _accounts.clear();
    _seedInitialData();
    notifyListeners();
  }

  void _seedInitialData() {
    _modules.clear();
    _modules.addAll([
      const Module(code: 'PROG202', name: 'Software Engineering', credits: 4),
      const Module(
          code: 'DBSY201', name: 'Database Management Systems', credits: 3),
      const Module(code: 'NETW203', name: 'Computer Networks', credits: 3),
      const Module(
          code: 'WEBD204', name: 'Web Application Development', credits: 3),
      const Module(code: 'MATH102', name: 'Discrete Mathematics', credits: 3),
    ]);

    _students.clear();
    _students.addAll([
      Student(
        studentId: 'BSEM1201F',
        firstName: 'Aminata',
        lastName: 'Kamara',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        marks: {
          'PROG202': 84,
          'DBSY201': 78,
          'NETW203': 81,
          'WEBD204': 88,
          'MATH102': 76,
        },
      ),
      Student(
        studentId: 'BSEM1202F',
        firstName: 'Mohamed',
        lastName: 'Sesay',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        marks: {
          'PROG202': 72,
          'DBSY201': 68,
          'NETW203': 74,
          'WEBD204': 70,
        },
      ),
      Student(
        studentId: 'BSEM1203F',
        firstName: 'Zeyad',
        lastName: 'Elgabry',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        marks: {
          'PROG202': 91,
          'DBSY201': 86,
          'NETW203': 83,
          'WEBD204': 89,
          'MATH102': 80,
        },
      ),
      Student(
        studentId: 'BSIT1104F',
        firstName: 'Fatmata',
        lastName: 'Koroma',
        programme: 'BSc (Hons) Information Technology',
        level: 'Year 2 - Semester 1',
        marks: {
          'PROG202': 61,
          'DBSY201': 58,
          'NETW203': 64,
        },
      ),
      Student(
        studentId: 'BSIT1105F',
        firstName: 'Ibrahim',
        lastName: 'Bangura',
        programme: 'BSc (Hons) Information Technology',
        level: 'Year 1 - Semester 2',
        marks: {
          'PROG202': 47,
          'DBSY201': 52,
          'MATH102': 43,
        },
      ),
      Student(
        studentId: 'BBIT1098F',
        firstName: 'Mariama',
        lastName: 'Conteh',
        programme: 'BSc (Hons) Business Information Technology',
        level: 'Year 2 - Semester 2',
        marks: {
          'PROG202': 36,
          'WEBD204': 44,
        },
      ),
    ]);

    _accounts.clear();
    _accounts.addAll([
      UserAccount(
        name: 'System Administrator',
        email: AppConstants.adminEmail,
        password: AppConstants.adminPassword,
        role: 'Administrator',
      ),
      UserAccount(
        name: 'Course Lecturer',
        email: AppConstants.lecturerEmail,
        password: AppConstants.lecturerPassword,
        role: 'Lecturer',
      ),
      UserAccount(
        name: 'Student Account',
        email: AppConstants.studentEmail,
        password: AppConstants.studentPassword,
        role: 'Student',
        linkedStudentId: 'BSEM1203F',
      ),
      // Seeded accounts for the 6 students
      UserAccount(
        name: 'Aminata Kamara',
        email: 'aminata.kamara@lincolnqueen.education',
        password: 'Student@1201',
        role: 'Student',
        linkedStudentId: 'BSEM1201F',
      ),
      UserAccount(
        name: 'Mohamed Sesay',
        email: 'mohamed.sesay@lincolnqueen.education',
        password: 'Student@1202',
        role: 'Student',
        linkedStudentId: 'BSEM1202F',
      ),
      UserAccount(
        name: 'Zeyad Elgabry',
        email: 'zeyad.elgabry@lincolnqueen.education',
        password: 'Student@1203',
        role: 'Student',
        linkedStudentId: 'BSEM1203F',
      ),
      UserAccount(
        name: 'Fatmata Koroma',
        email: 'fatmata.koroma@lincolnqueen.education',
        password: 'Student@1104',
        role: 'Student',
        linkedStudentId: 'BSIT1104F',
      ),
      UserAccount(
        name: 'Ibrahim Bangura',
        email: 'ibrahim.bangura@lincolnqueen.education',
        password: 'Student@1105',
        role: 'Student',
        linkedStudentId: 'BSIT1105F',
      ),
      UserAccount(
        name: 'Mariama Conteh',
        email: 'mariama.conteh@lincolnqueen.education',
        password: 'Student@1098',
        role: 'Student',
        linkedStudentId: 'BBIT1098F',
      ),
    ]);
  }

  /// Finds a student by exact ID (case-insensitive).
  Student? findStudent(String studentId) {
    final normalized = studentId.trim().toUpperCase();
    for (final student in _students) {
      if (student.studentId.toUpperCase() == normalized) {
        return student;
      }
    }
    return null;
  }

  /// Finds a module by exact code (case-insensitive).
  Module? findModule(String code) {
    final normalized = code.trim().toUpperCase();
    for (final module in _modules) {
      if (module.code.toUpperCase() == normalized) {
        return module;
      }
    }
    return null;
  }

  /// Registers a new student. Returns false if studentId already exists or
  /// caller lacks permission.
  bool addStudent(Student student) {
    if (!canManageStudentsAndModules) return false;
    if (findStudent(student.studentId) != null) {
      return false;
    }
    _students.add(
      Student(
        studentId: student.studentId.trim().toUpperCase(),
        firstName: student.firstName.trim(),
        lastName: student.lastName.trim(),
        programme: student.programme,
        level: student.level,
        marks: Map<String, double>.from(student.marks),
      ),
    );
    notifyListeners();
    return true;
  }

  /// Deletes a student record by ID.
  bool deleteStudent(String studentId) {
    if (!canManageStudentsAndModules) return false;
    final initialLen = _students.length;
    _students.removeWhere(
      (s) => s.studentId.toUpperCase() == studentId.trim().toUpperCase(),
    );
    if (_students.length != initialLen) {
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Registers a new module. Returns false if code already exists or caller
  /// lacks permission.
  bool addModule(Module module) {
    if (!canManageStudentsAndModules) return false;
    if (findModule(module.code) != null) {
      return false;
    }
    _modules.add(
      Module(
        code: module.code.trim().toUpperCase(),
        name: module.name.trim(),
        credits: module.credits,
      ),
    );
    notifyListeners();
    return true;
  }

  /// Checks whether a mark already exists for a given student and module.
  double? getExistingMark(String studentId, String moduleCode) {
    final student = findStudent(studentId);
    if (student == null) return null;
    return student.marks[moduleCode.trim().toUpperCase()];
  }

  /// Records or updates a mark (0..100) for a student and module.
  bool recordMark({
    required String studentId,
    required String moduleCode,
    required double mark,
  }) {
    if (!canRecordMarks) return false;
    if (mark < 0 || mark > 100) return false;
    final student = findStudent(studentId);
    final module = findModule(moduleCode);
    if (student == null || module == null) return false;

    student.marks[module.code] = mark;
    notifyListeners();
    return true;
  }

  /// Searches visible students by name, ID, or programme.
  List<Student> searchStudents(String query) {
    final source = visibleStudents;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.studentId.toLowerCase().contains(q) ||
          s.programme.toLowerCase().contains(q);
    }).toList();
  }

  /// Returns all marks recorded for a specific module across students.
  List<double> getModuleMarks(String moduleCode) {
    final code = moduleCode.trim().toUpperCase();
    final values = <double>[];
    for (final s in _students) {
      if (s.marks.containsKey(code)) {
        values.add(s.marks[code]!);
      }
    }
    return values;
  }

  /// Average mark for a specific module (or null if no marks recorded).
  double? getModuleAverage(String moduleCode) {
    final values = getModuleMarks(moduleCode);
    if (values.isEmpty) return null;
    final sum = values.fold<double>(0.0, (a, b) => a + b);
    return sum / values.length;
  }

  // Class-wide summary metrics
  int get totalStudents => _students.length;
  int get totalModules => _modules.length;

  int get totalMarksRecorded {
    return _students.fold<int>(0, (sum, s) => sum + s.marks.length);
  }

  double get classAverage {
    final gradedStudents = _students.where((s) => s.hasMarks).toList();
    if (gradedStudents.isEmpty) return 0.0;
    final sum = gradedStudents.fold<double>(0.0, (a, s) => a + s.averageMark);
    return sum / gradedStudents.length;
  }

  double get highestStudentAverage {
    final graded = _students.where((s) => s.hasMarks).toList();
    if (graded.isEmpty) return 0.0;
    graded.sort((a, b) => b.averageMark.compareTo(a.averageMark));
    return graded.first.averageMark;
  }

  double get lowestStudentAverage {
    final graded = _students.where((s) => s.hasMarks).toList();
    if (graded.isEmpty) return 0.0;
    graded.sort((a, b) => a.averageMark.compareTo(b.averageMark));
    return graded.first.averageMark;
  }

  double get passRate {
    final graded = _students.where((s) => s.hasMarks).toList();
    if (graded.isEmpty) return 0.0;
    final passed =
        graded.where((s) => GradeCalculator.isPass(s.averageMark)).length;
    return (passed / graded.length) * 100.0;
  }

  /// Distribution of overall grades across all students with marks.
  Map<String, int> get gradeDistribution {
    final dist = <String, int>{
      'A': 0,
      'A-': 0,
      'B+': 0,
      'B': 0,
      'B-': 0,
      'C+': 0,
      'C': 0,
      'C-': 0,
      'D': 0,
      'F': 0,
    };
    for (final s in _students) {
      if (s.hasMarks) {
        final g = s.overallGrade;
        if (dist.containsKey(g)) {
          dist[g] = dist[g]! + 1;
        }
      }
    }
    return dist;
  }
}