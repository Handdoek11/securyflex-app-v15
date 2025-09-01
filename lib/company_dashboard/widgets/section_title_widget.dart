import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// Section title widget for Company dashboard
/// Shows section titles outside of containers, following beveiliger dashboard pattern
class CompanySectionTitleWidget extends StatelessWidget {
  final String titleTxt;
  final String? subTxt;
  final VoidCallback? onTap;

  const CompanySectionTitleWidget({
    super.key,
    required this.titleTxt,
    this.subTxt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.spacingL,
        right: DesignTokens.spacingL,
        bottom: DesignTokens.spacingS,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              titleTxt,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSection,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          if (onTap != null && subTxt != null)
            Semantics(
              button: true,
              label: 'Bekijk meer details voor $titleTxt',
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingXS),
                  child: Row(
                    children: <Widget>[
                      Text(
                        subTxt!,
                        textAlign: TextAlign.left,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: companyColors.primary,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingXS),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: companyColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
