import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import 'package:securyflex_app/unified_buttons.dart';

class EmptyStateWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.animationController,
    this.animation,
    required this.title,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - animation!.value),
              0.0,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 18,
              ),
              child: PremiumGlassContainer(
                intensity: GlassIntensity.standard,
                elevation: GlassElevation.floating,
                tintColor: SecuryFlexTheme.getColorScheme(UserRole.guard).surfaceContainerHighest,
                enableTrustBorder: true,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  bottomLeft: Radius.circular(8.0),
                  bottomRight: Radius.circular(8.0),
                  topRight: Radius.circular(68.0),
                ),
                padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 64,
                        color: DesignTokens.colorGray500.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontSize: DesignTokens.fontSizeTitle,
                          color: DesignTokens.guardTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        message,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightRegular,
                          fontSize: DesignTokens.fontSizeBody,
                          color: DesignTokens.colorGray500.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (actionText != null && onAction != null) ...[
                        SizedBox(height: DesignTokens.spacingL),
                        UnifiedButton.primary(
                          text: actionText!,
                          onPressed: onAction!,
                          size: UnifiedButtonSize.medium,
                        ),
                      ],
                    ],
                  ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Factory constructors for common empty states
  factory EmptyStateWidget.noActiveJobs({
    required AnimationController animationController,
    required Animation<double> animation,
    VoidCallback? onRefresh,
  }) {
    return EmptyStateWidget(
      animationController: animationController,
      animation: animation,
      title: 'Geen actieve opdrachten',
      message:
          'Er zijn momenteel geen actieve beveiligingsopdrachten beschikbaar.',
      icon: Icons.work_off_outlined,
      actionText: 'Vernieuwen',
      onAction: onRefresh,
    );
  }

  factory EmptyStateWidget.noRecentShifts({
    required AnimationController animationController,
    required Animation<double> animation,
    VoidCallback? onViewJobs,
  }) {
    return EmptyStateWidget(
      animationController: animationController,
      animation: animation,
      title: 'Nog geen shifts voltooid',
      message:
          'Je hebt nog geen beveiligingsshifts voltooid. Begin met je eerste opdracht!',
      icon: Icons.history_outlined,
      actionText: 'Bekijk opdrachten',
      onAction: onViewJobs,
    );
  }

  factory EmptyStateWidget.noEarnings({
    required AnimationController animationController,
    required Animation<double> animation,
  }) {
    return EmptyStateWidget(
      animationController: animationController,
      animation: animation,
      title: 'Nog geen verdiensten',
      message: 'Voltooi je eerste shift om je verdiensten te zien.',
      icon: Icons.euro_outlined,
    );
  }
}
