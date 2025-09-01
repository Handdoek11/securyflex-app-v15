import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Section title widget for jobs marketplace
/// Creates a clean title outside the container, similar to company dashboard style
class JobsSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int jobCount;
  final bool isSearching;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final VoidCallback? onViewAll;

  const JobsSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.jobCount,
    this.isSearching = false,
    this.animationController,
    this.animation,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return AnimatedBuilder(
      animation: animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation ?? const AlwaysStoppedAnimation(1.0),
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - (animation?.value ?? 1.0)),
              0.0,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: DesignTokens.spacingL,
                right: DesignTokens.spacingL,
                top: DesignTokens.spacingM,
                bottom: DesignTokens.spacingS,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main title row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: DesignTokens.fontSizeTitle,       // Moderater size
                                fontWeight: DesignTokens.fontWeightSemiBold, // Moderate weight
                                fontFamily: DesignTokens.fontFamily,
                              ),
                            ),
                            if (subtitle != null) ...[
                              SizedBox(height: DesignTokens.spacingXS),
                              Text(
                                subtitle!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: DesignTokens.guardTextSecondary,
                                      fontWeight:
                                          DesignTokens.fontWeightRegular,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onViewAll != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onViewAll,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusS,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingS,
                                vertical: DesignTokens.spacingXS,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Bekijk alle',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight:
                                              DesignTokens.fontWeightMedium,
                                        ),
                                  ),
                                  SizedBox(width: DesignTokens.spacingXS),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Job count indicator
                  SizedBox(height: DesignTokens.spacingXS),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      border: Border.all(
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSearching ? Icons.search : Icons.work_outline,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: DesignTokens.spacingXS),
                        Text(
                          isSearching
                              ? '$jobCount ${jobCount == 1 ? 'resultaat' : 'resultaten'} gevonden'
                              : '$jobCount ${jobCount == 1 ? 'beschikbare job' : 'beschikbare jobs'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: DesignTokens.fontWeightMedium,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced job container widget that works with the section title
class JobsContainer extends StatelessWidget {
  final Widget child;
  final AnimationController? animationController;
  final Animation<double>? animation;

  const JobsContainer({
    super.key,
    required this.child,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    // Safety check for null animation controller
    if (animationController == null) {
      return Container(child: child);
    }

    return AnimatedBuilder(
      animation: animationController ?? const AlwaysStoppedAnimation(1.0),
      builder: (BuildContext context, Widget? child) {
        // Double safety check during build
        try {
          // Test if controller is still valid by accessing a safe property
          animationController!.value;
        } catch (e) {
          return Container(child: this.child);
        }
        
        return FadeTransition(
          opacity: animation ?? const AlwaysStoppedAnimation(1.0),
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - (animation?.value ?? 1.0)),
              0.0,
            ),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingL,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,  // Remove white background
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                // Remove shadow as well since there's no background
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                child: this.child,
              ),
            ),
          ),
        );
      },
    );
  }
}
