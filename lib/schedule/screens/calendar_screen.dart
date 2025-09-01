import 'package:flutter/material.dart';
import '../widgets/calendar/shift_calendar_widget.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// ScheduleCalendarScreen - Calendar view of shifts
/// 
/// Provides calendar interface for viewing and managing shifts.
/// Supports month/week views and shift interactions.
class ScheduleCalendarScreen extends StatelessWidget {
  const ScheduleCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.guardBackground, // ✅ Guard achtergrond (hardcoded UserRole.guard op regel 24)
      appBar: AppBar(
        title: const Text('Planning Kalender'),
        backgroundColor: DesignTokens.guardPrimary, // ✅ Consistent met UserRole.guard
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ShiftCalendarWidget(
          userRole: UserRole.guard,
          initialDate: DateTime.now(),
          shifts: const [],
          timeEntries: const [],
        ),
      ),
    );
  }
}