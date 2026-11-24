import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/grade_calculator.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';
import '../widgets/grade_chip.dart';

/// Screen 10: Record/update student mark with live grade preview and overwrite warning.
class RecordMarkScreen extends StatefulWidget {
  const RecordMarkScreen({super.key});

  @override
  State<RecordMarkScreen> createState() => _RecordMarkScreenState();
}

class _RecordMarkScreenState extends State<RecordMarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _markController = TextEditingController();

  String? _selectedStudentId;
  String? _selectedModuleCode;
  bool _initializedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String &&
          ResultsService.instance.findStudent(arg) != null) {
        _selectedStudentId = arg.toUpperCase();
      }
      _initializedArgs = true;
    }
  }

  @override
  void dispose() {
    _markController.dispose();
    super.dispose();
  }

  double? get _parsedValidMark {
    final val = double.tryParse(_markController.text.trim());
    if (val == null || val < 0 || val > 100) return null;
    return val;
  }

  double? get _existingMark {
    if (_selectedStudentId == null || _selectedModuleCode == null) {
      return null;
    }
    return ResultsService.instance
        .getExistingMark(_selectedStudentId!, _selectedModuleCode!);
  }

  void _saveMark() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final mark = double.parse(_markController.text.trim());
    final isUpdate = _existingMark != null;

    final saved = ResultsService.instance.recordMark(
      studentId: _selectedStudentId!,
      moduleCode: _selectedModuleCode!,
      mark: mark,
    );

    if (!saved) {
      UIHelpers.showSnackBar(
        context,
        'Unable to save mark. Check selected student and module.',
        isError: true,
      );
      return;
    }

    UIHelpers.showSnackBar(
      context,
      isUpdate
          ? 'Mark updated to ${mark.toStringAsFixed(1)} (${GradeCalculator.calculateGrade(mark)})'
          : 'Mark recorded: ${mark.toStringAsFixed(1)} (${GradeCalculator.calculateGrade(mark)})',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;
    final previewMark = _parsedValidMark;
    final existingMark = _existingMark;

    return Scaffold(
      appBar: buildAppBar(title: 'Record Mark'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AppCard(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<String>(
                  label: 'Student',
                  value: _selectedStudentId,
                  prefixIcon: Icons.person_outline,
                  items: service.students
                      .map((s) => DropdownMenuItem(
                            value: s.studentId,
                            child: Text('${s.studentId} - ${s.fullName}'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedStudentId = val),
                  validator: (v) => Validators.dropdown(v, 'a student'),
                ),
                const SizedBox(height: 14),
                AppDropdown<String>(
                  label: 'Module',
                  value: _selectedModuleCode,
                  prefixIcon: Icons.menu_book_outlined,
                  items: service.modules
                      .map((m) => DropdownMenuItem(
                            value: m.code,
                            child: Text('${m.code} - ${m.name}'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedModuleCode = val),
                  validator: (v) => Validators.dropdown(v, 'a module'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _markController,
                  label: 'Mark (0 - 100)',
                  hint: 'e.g. 76',
                  prefixIcon: Icons.score_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.mark,
                  onChanged: (_) => setState(() {}),
                ),

                // Warning banner if mark already exists
                if (existingMark != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gradeOrangeBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.gradeOrange.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.gradeOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Existing mark found (${existingMark.toStringAsFixed(1)}). Saving will update this result.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.charcoal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Live Grade Preview Card
                if (previewMark != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Live Grade Preview',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                GradeCalculator.calculateRemark(previewMark),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GradeChip(
                          grade: GradeCalculator.calculateGrade(previewMark),
                          isLarge: true,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 22),
                AppButton(
                  label: existingMark != null ? 'Update Mark' : 'Save Mark',
                  icon: Icons.save,
                  onPressed: _saveMark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}