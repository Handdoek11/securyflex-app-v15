import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// EditShiftScreen - Interface for editing existing shifts
/// 
/// Allows companies to modify shift details, requirements, and
/// compensation before or after publication.
class EditShiftScreen extends StatelessWidget {
  final String shiftId;
  final UserRole userRole;
  final String? companyId;

  const EditShiftScreen({
    super.key,
    required this.shiftId,
    required this.userRole,
    this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(), // ✅ Rol-gebaseerde achtergrond
      appBar: AppBar(
        title: const Text('Dienst Bewerken'),
        backgroundColor: _getThemeColor(),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Edit Shift',
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