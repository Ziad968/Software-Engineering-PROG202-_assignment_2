import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/module.dart';
import '../models/student.dart';
import '../utils/grade_calculator.dart';
import 'supabase_db_service.dart';

/// Represents a user account in LSRMS.
class UserAccount {
  final String name;
  String email;
  String password;
  String role; // 'Administrator', 'Lecturer', 'Student'
  final String? linkedStudentId;
  bool isActive;

  UserAccount({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.linkedStudentId,
    this.isActive = true,
  });
}

/// Result of an authentication attempt.
class AuthResult {
  final UserAccount? account;
  final String? error;

  const AuthResult({this.account, this.error});
}

/// Singleton state & business logic layer holding students, modules, marks,
/// user accounts, role-based permissions, and Supabase persistence.
class ResultsService extends ChangeNotifier {
  ResultsService._internal() {
    _seedInitialData();
  }

  static final ResultsService instance = ResultsService._internal();

  final SupabaseDbService _db = SupabaseDbService.instance;

  final List<Student> _students = [];
  final List<Module> _modules = [];
  final List<UserAccount> _accounts = [];

  String _currentUserEmail = '';
  String _currentUserRole = AppConstants.roleAdministrator;
  bool _isSyncing = false;

  List<Student> get students => List.unmodifiable(_students);
  List<Module> get modules => List.unmodifiable(_modules);
  List<UserAccount> get accounts => List.unmodifiable(_accounts);
  String get currentUserEmail => _currentUserEmail;
  String get currentUserRole => _currentUserRole;
  bool get isSyncing => _isSyncing;

  bool get isAdmin => _currentUserRole == AppConstants.roleAdministrator;
  bool get isLecturer => _currentUserRole == AppConstants.roleLecturer;
  bool get isStudent => _currentUserRole == AppConstants.roleStudent;

  bool get canManageAccounts => isAdmin;
  bool get canManageStudentsAndModules => isAdmin;
  bool get canRecordMarks => isAdmin || isLecturer;
  bool get canViewAllStudents => isAdmin || isLecturer;

  int get activeAccountsCount => _accounts.where((a) => a.isActive).length;
  int get inactiveAccountsCount => _accounts.where((a) => !a.isActive).length;

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

  Student? get currentStudentRecord {
    if (!isStudent) return null;

    final acc = currentAccount;
    if (acc?.linkedStudentId != null &&
        acc!.linkedStudentId!.trim().isNotEmpty) {
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
    _currentUserRole = AppConstants.roleAdministrator;
    notifyListeners();
  }

  bool _hasAllowedDomain(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith(AppConstants.allowedEmailDomain.toLowerCase());
  }

  UserAccount? authenticate(String email, String password) {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_hasAllowedDomain(normalizedEmail)) return null;

    for (final acc in _accounts) {
      if (acc.email.toLowerCase() == normalizedEmail &&
          acc.password == password &&
          acc.isActive) {
        return acc;
      }
    }
    return null;
  }

  Future<AuthResult> authenticateAsync(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_hasAllowedDomain(normalizedEmail)) {
      return AuthResult(
        error: 'Only ${AppConstants.allowedEmailDomain} accounts are allowed.',
      );
    }

    final remoteResult = await _db.authenticateAccount(
      email: normalizedEmail,
      password: password,
    );

    if (remoteResult.error != null) {
      return AuthResult(error: remoteResult.error);
    }

    if (remoteResult.account != null) {
      final remote = remoteResult.account!;
      final existingIndex = _accounts.indexWhere(
        (a) => a.email.toLowerCase() == normalizedEmail,
      );
      final syncedAccount = UserAccount(
        name: remote.name,
        email: remote.email,
        password: password,
        role: remote.role,
        linkedStudentId: remote.linkedStudentId,
        isActive: remote.isActive,
      );
      if (existingIndex != -1) {
        _accounts[existingIndex] = syncedAccount;
      } else {
        _accounts.add(syncedAccount);
      }
      notifyListeners();
      return AuthResult(account: syncedAccount);
    }

    final local = authenticate(normalizedEmail, password);
    if (local != null) {
      return AuthResult(account: local);
    }

    final disabledMatch = _accounts.cast<UserAccount?>().firstWhere(
          (a) =>
              a?.email.toLowerCase() == normalizedEmail &&
              a?.password == password &&
              !(a?.isActive ?? true),
          orElse: () => null,
        );
    if (disabledMatch != null) {
      return const AuthResult(
        error: 'This account is disabled. Contact the Administrator.',
      );
    }

    return const AuthResult(error: 'Invalid email or password.');
  }

  Future<void> syncFromSupabase() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final snapshot = await _db.fetchAllData();
      if (snapshot == null) return;

      if (snapshot.modules.isNotEmpty) {
        _modules
          ..clear()
          ..addAll(snapshot.modules);
      }

      if (snapshot.students.isNotEmpty) {
        _students
          ..clear()
          ..addAll(snapshot.students);
      }

      if (snapshot.accounts.isNotEmpty) {
        final merged = <UserAccount>[];
        for (final remoteAcc in snapshot.accounts) {
          final existing = _accounts.cast<UserAccount?>().firstWhere(
                (a) => a?.email.toLowerCase() == remoteAcc.email.toLowerCase(),
                orElse: () => null,
              );
          merged.add(
            UserAccount(
              name: remoteAcc.name,
              email: remoteAcc.email,
              password: remoteAcc.password.isNotEmpty
                  ? remoteAcc.password
                  : (existing?.password ?? ''),
              role: remoteAcc.role,
              linkedStudentId:
                  remoteAcc.linkedStudentId ?? existing?.linkedStudentId,
              isActive: remoteAcc.isActive,
            ),
          );
        }

        final hasPrimaryAdmin = merged.any(
          (a) => a.email.toLowerCase() == AppConstants.adminEmail.toLowerCase(),
        );
        if (!hasPrimaryAdmin) {
          final localAdmin = _accounts.cast<UserAccount?>().firstWhere(
                (a) =>
                    a?.email.toLowerCase() ==
                    AppConstants.adminEmail.toLowerCase(),
                orElse: () => null,
              );
          if (localAdmin != null) {
            merged.insert(0, localAdmin);
          }
        }

        _accounts
          ..clear()
          ..addAll(merged);
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  bool addAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    String? linkedStudentId,
    bool isActive = true,
  }) {
    if (!canManageAccounts) return false;
    if (role != AppConstants.roleLecturer && role != AppConstants.roleStudent) {
      return false;
    }
    if (!_hasAllowedDomain(email)) return false;

    final normalized = email.trim().toLowerCase();
    final exists = _accounts.any((a) => a.email.toLowerCase() == normalized);
    if (exists) return false;

    final account = UserAccount(
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: role,
      linkedStudentId: role == AppConstants.roleStudent &&
              linkedStudentId != null &&
              linkedStudentId.trim().isNotEmpty
          ? linkedStudentId.trim().toUpperCase()
          : null,
      isActive: isActive,
    );

    _accounts.add(account);
    notifyListeners();

    _db.upsertAccount(
      name: account.name,
      email: account.email,
      password: account.password,
      role: account.role,
      linkedStudentId: account.linkedStudentId,
      isActive: account.isActive,
    );
    return true;
  }

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
    if (acc.role == AppConstants.roleAdministrator) return false;

    final previousEmail = acc.email;

    if (newEmail != null && newEmail.trim().isNotEmpty) {
      if (!_hasAllowedDomain(newEmail)) return false;
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

    _db.updateAccount(
      previousEmail: previousEmail,
      name: acc.name,
      email: acc.email,
      password: acc.password,
      role: acc.role,
      linkedStudentId: acc.linkedStudentId,
      isActive: acc.isActive,
    );
    return true;
  }

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
    if (acc.role == AppConstants.roleStudent) return false;

    acc.role = makeAdmin
        ? AppConstants.roleAdministrator
        : AppConstants.roleLecturer;
    notifyListeners();

    _db.upsertAccount(
      name: acc.name,
      email: acc.email,
      password: acc.password,
      role: acc.role,
      linkedStudentId: acc.linkedStudentId,
      isActive: acc.isActive,
    );
    return true;
  }

  bool promoteLecturerToAdmin(String email) {
    return setLecturerAdminStatus(email: email, makeAdmin: true);
  }

  bool setAccountActiveStatus({
    required String email,
    required bool isActive,
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

    acc.isActive = isActive;
    notifyListeners();

    _db.setAccountActiveStatus(
      email: acc.email,
      isActive: acc.isActive,
    );
    return true;
  }

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

    _db.deleteAccount(acc.email);
    return true;
  }

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

    _db.upsertAccount(
      name: acc.name,
      email: acc.email,
      password: acc.password,
      role: acc.role,
      linkedStudentId: acc.linkedStudentId,
      isActive: acc.isActive,
    );
    return true;
  }

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
        studentId: '905000001',
        firstName: 'Aminata',
        lastName: 'Kamara',
        email: 'aminata.kamara@limkokwing.edu.sl',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        classCode: '12O1',
        marks: {
          'PROG202': 84,
          'DBSY201': 78,
          'NETW203': 81,
          'WEBD204': 88,
          'MATH102': 76,
        },
      ),
      Student(
        studentId: '905000002',
        firstName: 'Mohamed',
        lastName: 'Sesay',
        email: 'mohamed.sesay@limkokwing.edu.sl',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        classCode: '12O2',
        marks: {
          'PROG202': 72,
          'DBSY201': 68,
          'NETW203': 74,
          'WEBD204': 70,
        },
      ),
      Student(
        studentId: '905000003',
        firstName: 'Zeyad',
        lastName: 'Elgabry',
        email: 'zeyad.elgabry@limkokwing.edu.sl',
        programme: 'BSc (Hons) Software Engineering',
        level: 'Year 2 - Semester 1',
        classCode: '12O3',
        marks: {
          'PROG202': 91,
          'DBSY201': 86,
          'NETW203': 83,
          'WEBD204': 89,
          'MATH102': 80,
        },
      ),
      Student(
        studentId: '905000004',
        firstName: 'Fatmata',
        lastName: 'Koroma',
        email: 'fatmata.koroma@limkokwing.edu.sl',
        programme: 'BSc (Hons) Information Technology',
        level: 'Year 2 - Semester 1',
        classCode: '12O4',
        marks: {
          'PROG202': 61,
          'DBSY201': 58,
          'NETW203': 64,
        },
      ),
      Student(
        studentId: '905000005',
        firstName: 'Ibrahim',
        lastName: 'Bangura',
        email: 'ibrahim.bangura@limkokwing.edu.sl',
        programme: 'BSc (Hons) Information Technology',
        level: 'Year 1 - Semester 2',
        classCode: '21O2',
        marks: {
          'PROG202': 47,
          'DBSY201': 52,
          'MATH102': 43,
        },
      ),
      Student(
        studentId: '905000006',
        firstName: 'Mariama',
        lastName: 'Conteh',
        email: 'mariama.conteh@limkokwing.edu.sl',
        programme: 'BSc (Hons) Business Information Technology',
        level: 'Year 2 - Semester 2',
        classCode: '22O5',
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
        role: AppConstants.roleAdministrator,
      ),
      UserAccount(
        name: 'Course Lecturer',
        email: AppConstants.lecturerEmail,
        password: AppConstants.lecturerPassword,
        role: AppConstants.roleLecturer,
      ),
      for (final s in _students)
        UserAccount(
          name: s.fullName,
          email: s.resolvedEmail,
          password: AppConstants.studentPassword,
          role: AppConstants.roleStudent,
          linkedStudentId: s.studentId,
        ),
    ]);
  }

  Student? findStudent(String studentId) {
    final normalized = studentId.trim().toUpperCase();
    for (final student in _students) {
      if (student.studentId.toUpperCase() == normalized) {
        return student;
      }
    }
    return null;
  }

  Module? findModule(String code) {
    final normalized = code.trim().toUpperCase();
    for (final module in _modules) {
      if (module.code.toUpperCase() == normalized) {
        return module;
      }
    }
    return null;
  }

  bool addStudent(Student student) {
    if (!canManageStudentsAndModules) return false;
    if (findStudent(student.studentId) != null) {
      return false;
    }

    final resolvedEmail = student.resolvedEmail;
    final normalizedStudent = Student(
      studentId: student.studentId.trim().toUpperCase(),
      firstName: student.firstName.trim(),
      lastName: student.lastName.trim(),
      email: resolvedEmail,
      programme: student.programme,
      level: student.level,
      classCode: student.classCode.trim().toUpperCase(),
      marks: Map<String, double>.from(student.marks),
    );

    _students.add(normalizedStudent);

    final emailNormalized = resolvedEmail.toLowerCase();
    final hasAccount =
        _accounts.any((a) => a.email.toLowerCase() == emailNormalized);
    if (!hasAccount && _hasAllowedDomain(emailNormalized)) {
      final newAcc = UserAccount(
        name: normalizedStudent.fullName,
        email: resolvedEmail,
        password: AppConstants.studentPassword,
        role: AppConstants.roleStudent,
        linkedStudentId: normalizedStudent.studentId,
        isActive: true,
      );
      _accounts.add(newAcc);
      _db.upsertAccount(
        name: newAcc.name,
        email: newAcc.email,
        password: newAcc.password,
        role: newAcc.role,
        linkedStudentId: newAcc.linkedStudentId,
        isActive: newAcc.isActive,
      );
    }

    notifyListeners();

    _db.upsertStudent(normalizedStudent, emailOverride: resolvedEmail);
    return true;
  }

    bool deleteStudent(String studentId) {
    if (!canManageStudentsAndModules) return false;
    final normalizedId = studentId.trim().toUpperCase();
    final initialLen = _students.length;
    _students.removeWhere((s) => s.studentId.toUpperCase() == normalizedId);
    if (_students.length != initialLen) {
      notifyListeners();
      _db.deleteStudent(normalizedId);
      return true;
    }
    return false;
  }

  bool updateStudentClassAndLevel({
    required String studentId,
    required String newClassCode,
    required String newLevel,
  }) {
    if (!canRecordMarks) return false;

    final student = findStudent(studentId);
    if (student == null) return false;

    final code = newClassCode.trim().toUpperCase();
    if (!Student.isValidClassCode(code)) return false;

    student.classCode = code;
    student.level = newLevel.trim();
    notifyListeners();

    _db.upsertStudent(student);
    return true;
  }
  

  bool addModule(Module module) {
    if (!canManageStudentsAndModules) return false;
    if (findModule(module.code) != null) {
      return false;
    }

    final normalizedModule = Module(
      code: module.code.trim().toUpperCase(),
      name: module.name.trim(),
      credits: module.credits,
    );

    _modules.add(normalizedModule);
    notifyListeners();

    _db.upsertModule(normalizedModule);
    return true;
  }

  double? getExistingMark(String studentId, String moduleCode) {
    final student = findStudent(studentId);
    if (student == null) return null;
    return student.marks[moduleCode.trim().toUpperCase()];
  }

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

    _db.upsertMark(
      studentId: student.studentId,
      moduleCode: module.code,
      score: mark,
    );
    return true;
  }

  List<Student> searchStudents(String query) {
    final source = visibleStudents;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((s) {
      return s.fullName.toLowerCase().contains(q) ||
          s.studentId.toLowerCase().contains(q) ||
          s.classCode.toLowerCase().contains(q) ||
          s.programme.toLowerCase().contains(q);
    }).toList();
  }

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

  double? getModuleAverage(String moduleCode) {
    final values = getModuleMarks(moduleCode);
    if (values.isEmpty) return null;
    final sum = values.fold<double>(0.0, (a, b) => a + b);
    return sum / values.length;
  }

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