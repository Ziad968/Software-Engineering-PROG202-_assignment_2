import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/module.dart';
import '../models/student.dart';
import '../utils/grade_calculator.dart';

/// Represents a user profile stored in Supabase `public.profiles`.
class SupabaseAccountRecord {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'Administrator', 'Lecturer', 'Student'
  final String? linkedStudentId;
  final bool isActive;

  const SupabaseAccountRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.linkedStudentId,
    required this.isActive,
  });

  factory SupabaseAccountRecord.fromMap(Map<String, dynamic> map) {
    final rawLinked = map['linked_student_id']?.toString().trim();
    return SupabaseAccountRecord(
      id: (map['id'] ?? '').toString(),
      name: (map['full_name'] ?? map['name'] ?? '').toString().trim(),
      email: (map['email'] ?? '').toString().trim().toLowerCase(),
      password: (map['password'] ?? '').toString(),
      role: (map['role'] ?? 'Student').toString().trim(),
      linkedStudentId: (rawLinked != null && rawLinked.isNotEmpty)
          ? rawLinked.toUpperCase()
          : null,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }
}

class DbSnapshot {
  final List<Module> modules;
  final List<Student> students;
  final List<SupabaseAccountRecord> accounts;

  const DbSnapshot({
    required this.modules,
    required this.students,
    required this.accounts,
  });
}

class DbAuthResult {
  final SupabaseAccountRecord? account;
  final String? error;

  const DbAuthResult({this.account, this.error});
}

/// Direct PostgreSQL data access layer via Supabase client.
class SupabaseDbService {
  SupabaseDbService._();
  static final SupabaseDbService instance = SupabaseDbService._();

  SupabaseClient get _client => SuperBaseConfiguration.client;

  static bool isValidEduSlEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized.endsWith('.edu.sl') && normalized.contains('@');
  }

  Future<DbAuthResult> authenticateAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isValidEduSlEmail(normalizedEmail)) {
      return const DbAuthResult(
        error: 'Only @limkokwing.edu.sl institutional emails are allowed.',
      );
    }

    try {
      final res = await _client
          .from('profiles')
          .select()
          .ilike('email', normalizedEmail)
          .maybeSingle();

      if (res == null) return const DbAuthResult();

      final row = Map<String, dynamic>.from(res);
      if (!((row['is_active'] as bool?) ?? true)) {
        return const DbAuthResult(
          error: 'This account is disabled. Contact the Administrator.',
        );
      }

      final storedPassword = (row['password'] ?? '').toString();
      if (storedPassword.isNotEmpty && storedPassword != password) {
        return const DbAuthResult(error: 'Invalid email or password.');
      }

      return DbAuthResult(account: SupabaseAccountRecord.fromMap(row));
    } catch (_) {
      return const DbAuthResult();
    }
  }

  Future<DbSnapshot?> fetchAllData() async {
    try {
      final results = await Future.wait([
        fetchModules(),
        fetchStudentsWithMarks(),
        fetchProfiles(),
      ]);
      return DbSnapshot(
        modules: results[0] as List<Module>,
        students: results[1] as List<Student>,
        accounts: results[2] as List<SupabaseAccountRecord>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<Module>> fetchModules() async {
    final rows = await _client
        .from('modules')
        .select()
        .order('module_code', ascending: true);
    return (rows as List)
        .map((r) => Module.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> upsertModule(Module module) async {
    try {
      await _client
          .from('modules')
          .upsert(module.toMap(), onConflict: 'module_code');
    } catch (_) {}
  }

  Future<List<Student>> fetchStudentsWithMarks() async {
    final studentRows = await _client
        .from('students')
        .select()
        .order('student_id', ascending: true);
    final markRows = await _client.from('marks').select();

    final marksByStudent = <String, List<Map<String, dynamic>>>{};
    for (final raw in (markRows as List)) {
      final row = Map<String, dynamic>.from(raw as Map);
      final sid = (row['student_id'] ?? '').toString().trim().toUpperCase();
      marksByStudent.putIfAbsent(sid, () => []).add(row);
    }

    return (studentRows as List).map((raw) {
      final sRow = Map<String, dynamic>.from(raw as Map);
      final sid = (sRow['student_id'] ?? '').toString().trim().toUpperCase();
      return Student.fromSupabaseRows(
        studentRow: sRow,
        markRows: marksByStudent[sid] ?? const [],
      );
    }).toList();
  }

  Future<void> upsertStudent(
    Student student, {
    String? email,
    String? emailOverride,
  }) async {
    try {
      await _client.from('students').upsert(
            student.toSupabaseMap(email: email, emailOverride: emailOverride),
            onConflict: 'student_id',
          );
    } catch (_) {}
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      await _client
          .from('students')
          .delete()
          .eq('student_id', studentId.trim().toUpperCase());
    } catch (_) {}
  }

  Future<void> upsertMark({
    required String studentId,
    required String moduleCode,
    required double score,
  }) async {
    try {
      final grade = GradeCalculator.calculateGrade(score);
      await _client.from('marks').upsert(
        {
          'student_id': studentId.trim().toUpperCase(),
          'module_code': moduleCode.trim().toUpperCase(),
          'score': score,
          'grade': grade,
        },
        onConflict: 'student_id,module_code',
      );
    } catch (_) {}
  }

  Future<List<SupabaseAccountRecord>> fetchProfiles() async {
    final rows = await _client
        .from('profiles')
        .select()
        .order('full_name', ascending: true);
    return (rows as List)
        .map((r) =>
            SupabaseAccountRecord.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> upsertAccount({
    required String name,
    required String email,
    required String password,
    required String role,
    String? linkedStudentId,
    required bool isActive,
  }) async {
    try {
      await _client.from('profiles').upsert(
        {
          'full_name': name.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role,
          'linked_student_id': (role == 'Student' &&
                  linkedStudentId != null &&
                  linkedStudentId.trim().isNotEmpty)
              ? linkedStudentId.trim().toUpperCase()
              : null,
          'is_active': isActive,
        },
        onConflict: 'email',
      );
    } catch (_) {}
  }

  Future<void> setAccountActiveStatus({
    required String email,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive})
          .ilike('email', email.trim().toLowerCase());
    } catch (_) {}
  }

  Future<void> updateAccount({
    required String previousEmail,
    required String name,
    required String email,
    required String password,
    required String role,
    String? linkedStudentId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({
            'full_name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'role': role,
            'linked_student_id': (role == 'Student' &&
                    linkedStudentId != null &&
                    linkedStudentId.trim().isNotEmpty)
                ? linkedStudentId.trim().toUpperCase()
                : null,
            'is_active': isActive,
          })
          .ilike('email', previousEmail.trim().toLowerCase());
    } catch (_) {}
  }

  Future<void> deleteAccount(String email) async {
    try {
      await _client
          .from('profiles')
          .delete()
          .ilike('email', email.trim().toLowerCase());
    } catch (_) {}
  }
}