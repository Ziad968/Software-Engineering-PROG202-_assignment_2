import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/routes.dart';
import 'core/theme.dart';
/// Root widget configuring Material 3 theme and named routing for LSRMS.
class LSRMSApp extends StatelessWidget {
  const LSRMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: Routes.splash,
      routes: AppRouter.routes,
    );
  }
}
