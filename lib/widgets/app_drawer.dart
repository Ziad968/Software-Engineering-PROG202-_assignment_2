import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../services/results_service.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import 'app_logo.dart';

/// Navigation drawer providing role-aware actions, utility screens, and logout.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _showChangePasswordDialog(
    BuildContext context,
    ResultsService service,
  ) {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                ),
                validator: (v) => Validators.requiredField(v, 'Current password'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Confirm your new password';
                  }
                  if (v != newCtrl.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final updated = service.changeCurrentUserPassword(
                currentPassword: currentCtrl.text,
                newPassword: newCtrl.text,
              );
              Navigator.pop(ctx);

              if (!context.mounted) return;
              if (updated) {
                UIHelpers.showSnackBar(
                  context,
                  'Password updated successfully.',
                );
              } else {
                UIHelpers.showSnackBar(
                  context,
                  'Current password is incorrect.',
                  isError: true,
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ResultsService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return Drawer(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                color: AppColors.primaryRed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 54, showBorder: false),
                    const SizedBox(height: 12),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.currentUserEmail.isEmpty
                          ? AppConstants.adminEmail
                          : service.currentUserEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service.currentUserRole,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (service.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Active: ${service.activeAccountsCount} • Inactive: ${service.inactiveAccountsCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (service.canManageAccounts)
                      ListTile(
                        leading: const Icon(
                          Icons.manage_accounts_outlined,
                          color: AppColors.primaryRed,
                        ),
                        title: const Text('Manage Accounts'),
                        subtitle: const Text(
                          'Add, edit, promote, or remove accounts',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, Routes.manageAccounts);
                        },
                      ),
                    ListTile(
                      leading: const Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.primaryRed,
                      ),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update current account password'),
                      onTap: () {
                        Navigator.pop(context);
                        _showChangePasswordDialog(context, service);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.calculate_outlined,
                        color: AppColors.primaryRed,
                      ),
                      title: const Text('Grade Calculator'),
                      subtitle: const Text('Convert numeric mark to grade'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, Routes.gradeCalculator);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.table_chart_outlined,
                        color: AppColors.primaryRed,
                      ),
                      title: const Text('Grading Scale'),
                      subtitle: const Text('Official Limkokwing grade bands'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, Routes.gradingScale);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: AppColors.primaryRed,
                      ),
                      title: const Text('About LSRMS'),
                      subtitle: const Text('System info & features'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, Routes.about);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: AppColors.gradeRed,
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.gradeRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        service.clearSession();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.login,
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}