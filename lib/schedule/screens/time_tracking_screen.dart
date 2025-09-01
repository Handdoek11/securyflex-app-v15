import 'package:flutter/material.dart';
import '../widgets/time_clock_widget.dart';
import '../../unified_design_tokens.dart';

/// TimeTrackingScreen - Dedicated time tracking interface
/// 
/// Provides full-screen time tracking functionality for guards.
/// Features GPS verification, break management, and CAO compliance.
class TimeTrackingScreen extends StatelessWidget {
  const TimeTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.guardBackground, // ✅ Guard achtergrond (consistent met AppBar)
      appBar: AppBar(
        title: const Text('Tijd Registratie'),
        backgroundColor: DesignTokens.guardPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: UnifiedTimeClockWidget(
          userRole: UserRole.guard,
        ),
      ),
    );
  }
}