import 'package:flutter/material.dart';
import '../screens/about_screen.dart';
import '../screens/grade_calculator_screen.dart';
import '../screens/grading_scale_screen.dart';
import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../screens/manage_accounts_screen.dart';
import '../screens/record_mark_screen.dart';
import '../screens/register_module_screen.dart';
import '../screens/register_student_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/student_detail_screen.dart';

/// Named route constants across LSRMS.
class Routes {
  Routes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String studentDetail = '/student-detail';
  static const String registerStudent = '/register-student';
  static const String registerModule = '/register-module';
  static const String recordMark = '/record-mark';
  static const String gradeCalculator = '/grade-calculator';
  static const String gradingScale = '/grading-scale';
  static const String about = '/about';
  static const String manageAccounts = '/manage-accounts';
}

/// Maps route names to screen builders.
class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> get routes => {
        Routes.splash: (_) => const SplashScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.home: (_) => const HomeShell(),
        Routes.studentDetail: (_) => const StudentDetailScreen(),
        Routes.registerStudent: (_) => const RegisterStudentScreen(),
        Routes.registerModule: (_) => const RegisterModuleScreen(),
        Routes.recordMark: (_) => const RecordMarkScreen(),
        Routes.gradeCalculator: (_) => const GradeCalculatorScreen(),
        Routes.gradingScale: (_) => const GradingScaleScreen(),
        Routes.about: (_) => const AboutScreen(),
        Routes.manageAccounts: (_) => const ManageAccountsScreen(),
      };
}