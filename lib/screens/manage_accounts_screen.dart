import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

/// Screen for Administrator to add, edit credentials, toggle Lecturer admin
/// status, and remove accounts.
class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdController = TextEditingController();
  String _selectedRole = 'Lecturer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  void _handleAddAccount() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final added = ResultsService.instance.addAccount(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      linkedStudentId:
          _selectedRole == 'Student' ? _studentIdController.text.trim() : null,
    );

    if (!added) {
      UIHelpers.showSnackBar(
        context,
        'Account email already exists or invalid role.',
        isError: true,
      );
      return;
    }

    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _studentIdController.clear();
    setState(() {});

    UIHelpers.showSnackBar(
      context,
      '$_selectedRole account added successfully.',
    );
  }

  void _showEditDialog(UserAccount account) {
    final emailCtrl = TextEditingController(text: account.email);
    final passCtrl = TextEditingController(text: account.password);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${account.role} Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = ResultsService.instance.updateAccountCredentials(
                currentEmail: account.email,
                newEmail: emailCtrl.text.trim(),
                newPassword: passCtrl.text,
              );
              Navigator.pop(ctx);
              if (updated) {
                setState(() {});
                UIHelpers.showSnackBar(context, 'Credentials updated.');
              } else {
                UIHelpers.showSnackBar(
                  context,
                  'Could not update credentials (check duplicate email).',
                  isError: true,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _handleToggleAdmin(UserAccount account, bool makeAdmin) {
    final ok = ResultsService.instance.setLecturerAdminStatus(
      email: account.email,
      makeAdmin: makeAdmin,
    );
    if (ok) {
      setState(() {});
      UIHelpers.showSnackBar(
        context,
        makeAdmin
            ? '${account.name} promoted to Administrator.'
            : '${account.name} switched back to Lecturer.',
      );
    }
  }

  void _handleRemoveAccount(UserAccount account) {
    final removed = ResultsService.instance.removeAccount(account.email);
    if (removed) {
      setState(() {});
      UIHelpers.showSnackBar(context, 'Account removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    if (!service.canManageAccounts) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Accounts')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only Administrator can manage accounts.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final managedAccounts = service.accounts
        .where(
          (a) =>
              a.email.toLowerCase() != AppConstants.adminEmail.toLowerCase(),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Accounts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Lecturer or Student Account',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Lecturer',
                          label: Text('Lecturer'),
                          icon: Icon(Icons.school_outlined),
                        ),
                        ButtonSegment(
                          value: 'Student',
                          label: Text('Student'),
                          icon: Icon(Icons.person_outline),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (selection) {
                        setState(() => _selectedRole = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter full name',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@lincolnqueen.education',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    if (_selectedRole == 'Student') ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _studentIdController,
                        label: 'Linked Student ID',
                        hint: 'e.g. BSEM1203F',
                        prefixIcon: Icons.numbers,
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter password',
                      prefixIcon: Icons.lock_outline,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Create Account',
                      icon: Icons.person_add_alt_1,
                      onPressed: _handleAddAccount,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Existing Accounts',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            ...managedAccounts.map(
              (acc) {
                final isStaff = acc.role == 'Lecturer' ||
                    acc.role == 'Administrator';
                final isPromotedAdmin = acc.role == 'Administrator';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${acc.name} (${acc.role})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.charcoal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                acc.email,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.slate,
                                ),
                              ),
                              Text(
                                'Password: ${acc.password}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isStaff)
                          Tooltip(
                            message: isPromotedAdmin
                                ? 'Administrator (Toggle to demote to Lecturer)'
                                : 'Promote Lecturer to Administrator',
                            child: Switch(
                              value: isPromotedAdmin,
                              activeThumbColor: Colors.white,
                              activeTrackColor: Colors.green,
                              onChanged: (val) =>
                                  _handleToggleAdmin(acc, val),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Edit Email / Password',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showEditDialog(acc),
                        ),
                        IconButton(
                          tooltip: 'Remove Account',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.gradeRed,
                          ),
                          onPressed: () => _handleRemoveAccount(acc),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}