import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Consistent card layout for job/assignment items
/// Ensures uniform height and responsive design across list and grid views
class ConsistentJobCard extends StatelessWidget {
  final Widget child;
  final UserRole userRole;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? minHeight;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const ConsistentJobCard({
    super.key,
    required this.child,
    required this.userRole,
    this.onTap,
    this.isSelected = false,
    this.minHeight,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return Container(
      margin: margin ?? EdgeInsets.only(
        left: DesignTokens.spacingL,
        right: DesignTokens.spacingL,
        bottom: DesignTokens.spacingM,
      ),
      constraints: BoxConstraints(
        minHeight: minHeight ?? 120, // Consistent minimum height
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: UnifiedCard.standard(
          userRole: userRole,
          isClickable: onTap != null,
          onTap: onTap,
          padding: padding ?? EdgeInsets.all(DesignTokens.spacingM),
          backgroundColor: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive layout builder for job cards
/// Adapts between list and grid view modes
class ResponsiveJobLayout extends StatelessWidget {
  final List<Widget> children;
  final bool isGridView;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const ResponsiveJobLayout({
    super.key,
    required this.children,
    this.isGridView = false,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return Padding(
        padding: padding ?? EdgeInsets.all(DesignTokens.spacingM),
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: DesignTokens.spacingM,
          mainAxisSpacing: DesignTokens.spacingM,
          children: children,
        ),
      );
    }

    return Column(
      children: children,
    );
  }
}

/// Job card header with consistent layout
class JobCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? statusBadge;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final int maxTitleLines;
  final int maxSubtitleLines;

  const JobCardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.statusBadge,
    this.titleStyle,
    this.subtitleStyle,
    this.maxTitleLines = 2,
    this.maxSubtitleLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: maxTitleLines,
                overflow: TextOverflow.ellipsis,
                style: titleStyle ?? Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  subtitle,
                  maxLines: maxSubtitleLines,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (statusBadge != null) ...[
          SizedBox(width: DesignTokens.spacingS),
          statusBadge!,
        ],
      ],
    );
  }
}

/// Job card footer with action buttons
class JobCardFooter extends StatelessWidget {
  final List<Widget> actions;
  final MainAxisAlignment alignment;

  const JobCardFooter({
    super.key,
    required this.actions,
    this.alignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: alignment,
      children: actions.map((action) {
        final index = actions.indexOf(action);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < actions.length - 1 ? DesignTokens.spacingS : 0,
            ),
            child: action,
          ),
        );
      }).toList(),
    );
  }
}

/// Utility class for consistent spacing in job cards
class JobCardSpacing {
  static const double headerToContent = DesignTokens.spacingM;
  static const double contentToFooter = DesignTokens.spacingM;
  static const double betweenContentItems = DesignTokens.spacingS;
  static const double betweenActions = DesignTokens.spacingS;
}

/// Layout builder that adapts to available space
class AdaptiveJobCardLayout extends StatelessWidget {
  final Widget child;
  final double breakpoint;

  const AdaptiveJobCardLayout({
    super.key,
    required this.child,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > breakpoint;
        
        return Container(
          constraints: BoxConstraints(
            minHeight: isWideScreen ? 140 : 120,
            maxHeight: isWideScreen ? 200 : 180,
          ),
          child: child,
        );
      },
    );
  }
}
