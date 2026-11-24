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
  final _studentIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  String? _selectedProgramme = AppConstants.programmes.first;
  String? _selectedLevel = AppConstants.academicLevels.first;

  @override
  void dispose() {
    _studentIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _studentIdController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    setState(() {
      _selectedProgramme = AppConstants.programmes.first;
      _selectedLevel = AppConstants.academicLevels.first;
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final student = Student(
      studentId: _studentIdController.text.trim().toUpperCase(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      programme: _selectedProgramme!,
      level: _selectedLevel!,
    );

    final added = ResultsService.instance.addStudent(student);
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
      'Student ${student.fullName} registered successfully!',
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
                  label: 'Student ID',
                  hint: 'e.g. BSEM1204F',
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.characters,
                  validator: Validators.studentId,
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
                const SizedBox(height: 22),
                AppButton(
                  label: 'Save Student',
                  icon: Icons.save,
                  onPressed: _submit,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Clear Form',
                  icon: Icons.refresh,
                  isOutlined: true,
                  onPressed: _clearForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}