import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Company welcome widget - Clean mobile-first header
/// Simple company name, welcome text, and time/date display
class CompanyWelcomeView extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const CompanyWelcomeView({
    super.key,
    this.animationController,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                      // Welcome greeting
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.business,
                            color: companyColors.primary,
                            size: 28,
                          ),
                          SizedBox(width: DesignTokens.spacingS),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Welkom terug',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: companyColors.onSurface,
                                    fontWeight: DesignTokens.fontWeightSemiBold,
                                  ),
                                ),
                                Text(
                                  'Amsterdam Security Partners',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: companyColors.primary,
                                    fontWeight: DesignTokens.fontWeightBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: companyColors.primaryContainer,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                            ),
                            child: Text(
                              'Actief',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: companyColors.onPrimaryContainer,
                                fontWeight: DesignTokens.fontWeightSemiBold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Date and time info
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.calendar_today,
                            color: companyColors.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: DesignTokens.spacingXS),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'nl_NL').format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: companyColors.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            color: companyColors.onSurfaceVariant,
                            size: 16,
                          ),
                          SizedBox(width: DesignTokens.spacingXS),
                          Text(
                            DateFormat('HH:mm').format(DateTime.now()),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: companyColors.onSurfaceVariant,
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
}
