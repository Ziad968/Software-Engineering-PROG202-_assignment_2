import 'package:flutter/material.dart';
import '../models/module.dart';
import '../services/results_service.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_text_field.dart';

/// Screen 9: Form to register a new course module with duplicate-code check.
class RegisterModuleScreen extends StatefulWidget {
  const RegisterModuleScreen({super.key});

  @override
  State<RegisterModuleScreen> createState() => _RegisterModuleScreenState();
}

class _RegisterModuleScreenState extends State<RegisterModuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  int _credits = 3;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _codeController.clear();
    _nameController.clear();
    setState(() => _credits = 3);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final module = Module(
      code: _codeController.text.trim().toUpperCase(),
      name: _nameController.text.trim(),
      credits: _credits,
    );

    final added = ResultsService.instance.addModule(module);
    if (!added) {
      UIHelpers.showSnackBar(
        context,
        'Module code ${module.code} already exists!',
        isError: true,
      );
      return;
    }

    UIHelpers.showSnackBar(
      context,
      'Module ${module.code} registered successfully!',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(title: 'Register Module'),
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
                  controller: _codeController,
                  label: 'Module Code',
                  hint: 'e.g. PROG202',
                  prefixIcon: Icons.code,
                  textCapitalization: TextCapitalization.characters,
                  validator: Validators.moduleCode,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _nameController,
                  label: 'Module Name',
                  hint: 'e.g. Software Engineering',
                  prefixIcon: Icons.menu_book_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.moduleName,
                ),
                const SizedBox(height: 14),
                AppDropdown<int>(
                  label: 'Credit Hours',
                  value: _credits,
                  prefixIcon: Icons.stars_outlined,
                  items: const [2, 3, 4, 5, 6]
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c Credits'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _credits = val ?? 3),
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Save Module',
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