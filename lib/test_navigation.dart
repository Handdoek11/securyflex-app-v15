import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routing/app_router.dart';
import 'unified_theme_system.dart';

void main() {
  // Initialize the router
  AppRouter.initialize();
  
  runApp(TestNavigationApp());
}

class TestNavigationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SecuryFlex Navigation Test',
      theme: SecuryFlexTheme.getTheme(UserRole.guard),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}