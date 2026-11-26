import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

/// Screen for Administrator to add, search, filter, edit credentials,
/// toggle Lecturer admin status, and remove accounts.
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
  final _searchController = TextEditingController();

  String _roleFilter = 'All'; // 'All', 'Student', 'Lecturer'
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
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
      role: AppConstants.roleLecturer,
    );

    if (!added) {
      UIHelpers.showSnackBar(
        context,
        'Account already exists or email is not ${AppConstants.allowedEmailDomain}.',
        isError: true,
      );
      return;
    }

    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {});

    UIHelpers.showSnackBar(
      context,
      'Lecturer account added successfully.',
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
                  'Could not update credentials (check ${AppConstants.allowedEmailDomain} or duplicate email).',
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

  Future<void> _handleRefresh() async {
    await ResultsService.instance.syncFromSupabase();
    if (mounted) {
      setState(() {});
      UIHelpers.showSnackBar(context, 'Accounts synced with Supabase.');
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

    final query = _searchQuery.trim().toLowerCase();
    final filteredAccounts = service.accounts.where((a) {
      if (a.email.toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
        return false;
      }

      if (_roleFilter == AppConstants.roleStudent &&
          a.role != AppConstants.roleStudent) {
        return false;
      }

      if (_roleFilter == AppConstants.roleLecturer &&
          a.role != AppConstants.roleLecturer &&
          a.role != AppConstants.roleAdministrator) {
        return false;
      }

      if (query.isEmpty) return true;
      return a.name.toLowerCase().contains(query) ||
          a.email.toLowerCase().contains(query) ||
          (a.linkedStudentId?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Accounts'),
        actions: [
          IconButton(
            tooltip: 'Sync with Supabase',
            icon: service.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: service.isSyncing ? null : _handleRefresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${service.activeAccountsCount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'Active / Connected',
                        style: TextStyle(fontSize: 12, color: AppColors.slate),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${service.inactiveAccountsCount}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gradeRed,
                        ),
                      ),
                      const Text(
                        'Inactive / Disconnected',
                        style: TextStyle(fontSize: 12, color: AppColors.slate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add Lecturer Account',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter lecturer full name',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'first.last@limkokwing.edu.sl',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
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
                      label: 'Create Lecturer Account',
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
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or Student ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(
                  value: AppConstants.roleStudent,
                  label: Text('Students'),
                ),
                ButtonSegment(
                  value: AppConstants.roleLecturer,
                  label: Text('Lecturers'),
                ),
              ],
              selected: {_roleFilter},
              onSelectionChanged: (selection) {
                setState(() => _roleFilter = selection.first);
              },
            ),
            const SizedBox(height: 10),
            if (filteredAccounts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No matching accounts found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate),
                ),
              )
            else
              ...filteredAccounts.map((acc) {
                final isStaff = acc.role == AppConstants.roleLecturer ||
                    acc.role == AppConstants.roleAdministrator;
                final isPromotedAdmin =
                    acc.role == AppConstants.roleAdministrator;

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
                              if (acc.linkedStudentId != null &&
                                  acc.linkedStudentId!.isNotEmpty)
                                Text(
                                  'Student ID: ${acc.linkedStudentId}',
                                  style: const TextStyle(
                                    fontSize: 12,
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
              }),
          ],
        ),
      ),
    );
  }
}