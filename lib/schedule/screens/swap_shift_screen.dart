import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// SwapShiftScreen - Interface for managing shift swaps
/// 
/// Allows guards to request shift swaps with other guards.
/// Includes approval workflows and scheduling conflict resolution.
class SwapShiftScreen extends StatelessWidget {
  final String shiftId;
  final UserRole userRole;
  final String? guardId;

  const SwapShiftScreen({
    super.key,
    required this.shiftId,
    required this.userRole,
    this.guardId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(), // ✅ Rol-gebaseerde achtergrond
      appBar: AppBar(
        title: const Text('Dienst Ruilen'),
        backgroundColor: _getThemeColor(),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Swap Shift',
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