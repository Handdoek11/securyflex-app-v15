import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// CreateShiftScreen - Interface for creating new shifts
/// 
/// Allows companies to create and publish new shift opportunities.
/// Includes shift requirements, location, and compensation details.
class CreateShiftScreen extends StatelessWidget {
  final UserRole userRole;
  final String? companyId;

  const CreateShiftScreen({
    super.key,
    required this.userRole,
    this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(), // ✅ Rol-gebaseerde achtergrond
      appBar: AppBar(
        title: const Text('Nieuwe Dienst'),
        backgroundColor: _getThemeColor(),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Create Shift',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Under Construction'),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  Color _getBackgroundColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardBackground;
      case UserRole.company:
        return DesignTokens.companyBackground;
      case UserRole.admin:
        return DesignTokens.adminBackground;
    }
  }
}