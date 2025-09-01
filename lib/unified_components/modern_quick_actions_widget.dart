import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';

import 'unified_dashboard_card.dart';

/// Modern, performance-optimized quick actions widget
/// 
/// This replaces the legacy quick_actions_widget.dart with:
/// - Maximum 3 nesting levels (vs 6+ in legacy)
/// - Consolidated styling via UnifiedDashboardCard
/// - Clean action button layout
/// - Material 3 compliance
/// - Performance-first design
class ModernQuickActionsWidget extends StatefulWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final List<QuickAction>? customActions;

  const ModernQuickActionsWidget({
    super.key,
    this.animationController,
    this.animation,
    this.customActions,
  });

  @override
  State<ModernQuickActionsWidget> createState() => _ModernQuickActionsWidgetState();
}

class _ModernQuickActionsWidgetState extends State<ModernQuickActionsWidget> {
  final Set<String> _loadingActions = {};

  @override
  Widget build(BuildContext context) {
    final actions = widget.customActions ?? _getDefaultActions();
    
    return AnimatedBuilder(
      animation: widget.animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final animationValue = widget.animation?.value ?? 1.0;
        return FadeTransition(
          opacity: widget.animation ?? const AlwaysStoppedAnimation(1.0),
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              20 * (1.0 - animationValue), // Reduced translation distance
              0.0
            ),
            child: UnifiedDashboardCard(
              title: 'Snelle Acties',
              subtitle: 'Veelgebruikte functies',
              userRole: UserRole.guard,
              variant: DashboardCardVariant.standard,
              child: Column(
                children: [
                  // Primary actions (top row)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          actions.firstWhere((a) => a.id == 'incident_report'),
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildActionButton(
                          actions.firstWhere((a) => a.id == 'check_in'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  // Secondary actions (bottom row)
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          actions.firstWhere((a) => a.id == 'applications'),
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: _buildActionButton(
                          actions.firstWhere((a) => a.id == 'schedule'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(QuickAction action) {
    final isLoading = _loadingActions.contains(action.id);

    return ElevatedButton(
      onPressed: isLoading ? null : () => _handleAction(action),
      child: isLoading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(action.title),
    );
  }

  Future<void> _handleAction(QuickAction action) async {
    if (_loadingActions.contains(action.id)) return;

    setState(() => _loadingActions.add(action.id));
    HapticFeedback.mediumImpact();

    try {
      await action.onPressed();
    } catch (e) {
      if (mounted) {
        _showErrorMessage(action.title);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingActions.remove(action.id));
      }
    }
  }

  void _showErrorMessage(String actionTitle) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fout bij uitvoeren van $actionTitle'),
        backgroundColor: DesignTokens.colorError,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }

  List<QuickAction> _getDefaultActions() {
    return [
      QuickAction(
        id: 'incident_report',
        title: 'Incident Melden',
        icon: Icons.report_problem,
        onPressed: _reportIncident,
      ),
      QuickAction(
        id: 'check_in',
        title: 'Locatie Check-in',
        icon: Icons.location_on,
        onPressed: _checkIn,
      ),
      QuickAction(
        id: 'applications',
        title: 'Mijn Sollicitaties',
        icon: Icons.work,
        onPressed: _viewApplications,
      ),
      QuickAction(
        id: 'schedule',
        title: 'Planning',
        icon: Icons.schedule,
        onPressed: _viewSchedule,
      ),
    ];
  }

  Future<void> _reportIncident() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _showComingSoonMessage('Incident rapportage');
    }
  }

  Future<void> _checkIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _showComingSoonMessage('Locatie check-in');
    }
  }

  Future<void> _viewApplications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      // TODO: Navigate to applications screen
      _showComingSoonMessage('Sollicitaties overzicht');
    }
  }

  Future<void> _viewSchedule() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      // TODO: Navigate to schedule screen
      _showComingSoonMessage('Planning overzicht');
    }
  }

  void _showComingSoonMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature komt binnenkort beschikbaar'),
        backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }
}

/// Data model for quick actions
class QuickAction {
  final String id;
  final String title;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool isEnabled;

  const QuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isEnabled = true,
  });
}

/// Factory methods for common quick actions
extension QuickActionFactory on QuickAction {
  /// Create incident reporting action
  static QuickAction incidentReport({
    required Future<void> Function() onPressed,
  }) {
    return QuickAction(
      id: 'incident_report',
      title: 'Incident Melden',
      icon: Icons.report_problem,
      onPressed: onPressed,
    );
  }

  /// Create check-in action
  static QuickAction checkIn({
    required Future<void> Function() onPressed,
  }) {
    return QuickAction(
      id: 'check_in',
      title: 'Locatie Check-in',
      icon: Icons.location_on,
      onPressed: onPressed,
    );
  }

  /// Create applications action
  static QuickAction applications({
    required Future<void> Function() onPressed,
  }) {
    return QuickAction(
      id: 'applications',
      title: 'Mijn Sollicitaties',
      icon: Icons.work,
      onPressed: onPressed,
    );
  }

  /// Create schedule action
  static QuickAction schedule({
    required Future<void> Function() onPressed,
  }) {
    return QuickAction(
      id: 'schedule',
      title: 'Planning',
      icon: Icons.schedule,
      onPressed: onPressed,
    );
  }
}
