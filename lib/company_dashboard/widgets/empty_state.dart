import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';

/// Empty state component for Company dashboard
/// Provides consistent empty states with Dutch messaging
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;
  final UserRole userRole;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
    this.userRole = UserRole.company,
    this.iconColor,
  });

  /// Empty state for no active jobs
  factory EmptyState.noActiveJobs({
    required VoidCallback onCreateJob,
    UserRole userRole = UserRole.company,
  }) {
    return EmptyState(
      icon: Icons.work_off_outlined,
      title: 'Geen actieve opdrachten',
      description: 'Je hebt momenteel geen actieve beveiligingsopdrachten. Plaats je eerste opdracht om beveiligers te vinden.',
      actionText: 'Plaats Nieuwe Opdracht',
      onAction: onCreateJob,
      userRole: userRole,
    );
  }

  /// Empty state for no applications
  factory EmptyState.noApplications({
    VoidCallback? onViewJobs,
    UserRole userRole = UserRole.company,
  }) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'Geen sollicitaties',
      description: 'Er zijn nog geen sollicitaties binnengekomen. Zorg ervoor dat je opdrachten zichtbaar zijn voor beveiligers.',
      actionText: onViewJobs != null ? 'Bekijk Opdrachten' : null,
      onAction: onViewJobs,
      userRole: userRole,
    );
  }

  /// Empty state for no revenue data
  factory EmptyState.noRevenueData({
    VoidCallback? onRefresh,
    UserRole userRole = UserRole.company,
  }) {
    return EmptyState(
      icon: Icons.analytics_outlined,
      title: 'Geen financiële gegevens',
      description: 'Er zijn nog geen financiële gegevens beschikbaar. Dit komt beschikbaar zodra je eerste opdracht is voltooid.',
      actionText: onRefresh != null ? 'Vernieuwen' : null,
      onAction: onRefresh,
      userRole: userRole,
    );
  }

  /// Empty state for search results
  factory EmptyState.noSearchResults({
    required String searchTerm,
    VoidCallback? onClearSearch,
    UserRole userRole = UserRole.company,
  }) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'Geen resultaten gevonden',
      description: 'Er zijn geen resultaten gevonden voor "$searchTerm". Probeer andere zoektermen.',
      actionText: onClearSearch != null ? 'Wis Zoekopdracht' : null,
      onAction: onClearSearch,
      userRole: userRole,
    );
  }

  /// Empty state for network error
  factory EmptyState.networkError({
    required VoidCallback onRetry,
    UserRole userRole = UserRole.company,
  }) {
    return EmptyState(
      icon: Icons.wifi_off_outlined,
      title: 'Verbindingsprobleem',
      description: 'Er is een probleem met de internetverbinding. Controleer je verbinding en probeer opnieuw.',
      actionText: 'Probeer Opnieuw',
      onAction: onRetry,
      userRole: userRole,
      iconColor: DesignTokens.colorError,
    );
  }

  /// Empty state for maintenance
  factory EmptyState.maintenance({
    UserRole userRole = UserRole.company,
  }) {
    return EmptyState(
      icon: Icons.build_outlined,
      title: 'Onderhoud',
      description: 'Deze functie is tijdelijk niet beschikbaar vanwege onderhoud. Probeer het later opnieuw.',
      userRole: userRole,
      iconColor: DesignTokens.colorWarning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    final effectiveIconColor = iconColor ?? colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          UnifiedCard.standard(
            userRole: userRole,
            backgroundColor: effectiveIconColor.withValues(alpha: 0.1),
            child: SizedBox(
              width: DesignTokens.spacingXXL * 2, // 80px equivalent
              height: DesignTokens.spacingXXL * 2, // 80px equivalent
              child: Icon(
                icon,
                size: DesignTokens.iconSizeXL,
                color: effectiveIconColor,
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingL),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
          
          // Action button
          if (actionText != null && onAction != null) ...[
            SizedBox(height: DesignTokens.spacingL),
            UnifiedButton.primary(
              text: actionText!,
              onPressed: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact empty state for smaller spaces
class CompactEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final UserRole userRole;

  const CompactEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionText,
    this.onAction,
    this.userRole = UserRole.company,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            SizedBox(height: DesignTokens.spacingS),
            UnifiedButton.secondary(
              text: actionText!,
              onPressed: onAction!,
              size: UnifiedButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state component
class ErrorState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onRetry;
  final UserRole userRole;

  const ErrorState({
    super.key,
    this.title = 'Er is iets misgegaan',
    this.description = 'Er is een onverwachte fout opgetreden. Probeer het opnieuw.',
    required this.onRetry,
    this.userRole = UserRole.company,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);

    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UnifiedCard.standard(
            userRole: UserRole.company,
            backgroundColor: DesignTokens.colorError.withValues(alpha: 0.1),
            child: SizedBox(
              width: DesignTokens.spacingXXL * 2, // 80px equivalent
              height: DesignTokens.spacingXXL * 2, // 80px equivalent
              child: Icon(
                Icons.error_outline,
                size: DesignTokens.iconSizeXL,
                color: DesignTokens.colorError,
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingL),
          
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: DesignTokens.spacingL),
          
          UnifiedButton.primary(
            text: 'Probeer Opnieuw',
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
