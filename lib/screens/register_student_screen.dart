import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/student.dart';
import '../services/results_service.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';

/// Screen 8: Form to register a new student with validation and duplicate ID check.
class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController(text: '90500');
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedProgramme = AppConstants.programmes.first;
  String? _selectedLevel = AppConstants.academicLevels.first;
  String _selectedSemester = AppConstants.semesters.first;
  String _selectedYear = '2';
  String _selectedSection = 'O3';
  bool _emailManuallyEdited = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_syncGeneratedEmail);
    _lastNameController.addListener(_syncGeneratedEmail);
  }

  void _syncGeneratedEmail() {
    if (_emailManuallyEdited) return;
    final generated = Student.buildDefaultEmail(
      _firstNameController.text,
      _lastNameController.text,
    );
    if (_emailController.text != generated) {
      _emailController.text = generated;
    }
  }

  String get _computedClassCode =>
      '$_selectedSemester$_selectedYear$_selectedSection';

  @override
  void dispose() {
    _firstNameController.removeListener(_syncGeneratedEmail);
    _lastNameController.removeListener(_syncGeneratedEmail);
    _studentIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _clearForm() {
    if (_isSaving) return;
    _emailManuallyEdited = false;
    _formKey.currentState?.reset();
    _studentIdController.text = '90500';
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    setState(() {
      _selectedProgramme = AppConstants.programmes.first;
      _selectedLevel = AppConstants.academicLevels.first;
      _selectedSemester = AppConstants.semesters.first;
      _selectedYear = '2';
      _selectedSection = 'O3';
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!ResultsService.instance.canManageStudentsAndModules) {
      UIHelpers.showSnackBar(
        context,
        'Only Administrator can register students.',
        isError: true,
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    final resolvedEmail = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim().toLowerCase()
        : Student.buildDefaultEmail(
            _firstNameController.text,
            _lastNameController.text,
          );

    final student = Student(
      studentId: _studentIdController.text.trim().toUpperCase(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: resolvedEmail,
      programme: _selectedProgramme!,
      level: _selectedLevel!,
      classCode: _computedClassCode,
    );

    final added = ResultsService.instance.addStudent(student);

    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!added) {
      UIHelpers.showSnackBar(
        context,
        'Student ID ${student.studentId} is already registered!',
        isError: true,
      );
      return;
    }

    UIHelpers.showSnackBar(
      context,
      'Student ${student.fullName} ($_computedClassCode) registered successfully!',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: 'Register Student'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _studentIdController,
                  label: 'Student ID (90500 + 4 digits)',
                  hint: 'e.g. 905000007',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) {
                    if (v == null || !Student.isValidStudentId(v)) {
                      return 'ID must start with 90500 followed by 4 digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  hint: 'e.g. Aminata',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.personName(v, 'First name'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  hint: 'e.g. Kamara',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.personName(v, 'Last name'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailController,
                  label: 'Institutional Email',
                  hint: 'first.last@limkokwing.edu.sl',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _emailManuallyEdited = true,
                  validator: (v) {
                    final email = (v ?? '').trim().toLowerCase();
                    if (!email.contains('@') ||
                        !email.endsWith(AppConstants.allowedEmailDomain)) {
                      return 'Must end with ${AppConstants.allowedEmailDomain}.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'Programme',
                  value: _selectedProgramme,
                  prefixIcon: Icons.school_outlined,
                  items: AppConstants.programmes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedProgramme = val),
                  validator: (v) => Validators.dropdown(v, 'a programme'),
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'Academic Level',
                  value: _selectedLevel,
                  prefixIcon: Icons.layers_outlined,
                  items: AppConstants.academicLevels
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedLevel = val),
                  validator: (v) => Validators.dropdown(v, 'an academic level'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Semester',
                        value: _selectedSemester,
                        items: AppConstants.semesters
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text('Sem $s'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSemester = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Year',
                        value: _selectedYear,
                        items: AppConstants.studyYears
                            .map((y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('Yr $y'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedYear = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Class',
                        value: _selectedSection,
                        items: AppConstants.classSections
                            .map((sec) => DropdownMenuItem(
                                  value: sec,
                                  child: Text(sec),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSection = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Class Code: $_computedClassCode',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: _isSaving ? 'Saving...' : 'Save Student',
                  icon: Icons.save,
                  onPressed: _isSaving ? null : _submit,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Clear Form',
                  icon: Icons.refresh,
                  isOutlined: true,
                  onPressed: _isSaving ? null : _clearForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}