import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../models/shift_data.dart';
import '../utils/date_utils.dart';

/// Material 3 compliant Next Shift Card with premium glass morphism
class NextShiftCard extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final ShiftData? nextShift;
  final VoidCallback? onTap;

  const NextShiftCard({
    super.key,
    this.animationController,
    this.animation,
    this.nextShift,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (nextShift == null) {
      return _buildNoShiftCard();
    }

    // If no animation controller or animation is provided, show static card
    if (animationController == null || animation == null) {
      return _buildStaticShiftCard();
    }

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
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: PremiumGlassContainer(
                intensity: GlassIntensity.premium,
                elevation: GlassElevation.raised,
                tintColor: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
                enableTrustBorder: true,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(DesignTokens.radiusM),
                  bottomLeft: Radius.circular(DesignTokens.radiusM),
                  bottomRight: Radius.circular(DesignTokens.radiusM),
                  topRight: Radius.circular(DesignTokens.radiusXXXL + DesignTokens.radiusXXXL),
                ),
                onTap: onTap,
                padding: EdgeInsets.all(DesignTokens.spacingM),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Text(
                          'Volgende Dienst',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightRegular,
                            fontSize: DesignTokens.fontSizeBody,
                            letterSpacing: 0.0,
                            color: DesignTokens.colorBlack,
                          ),
                        ),
                        const Spacer(),
                        if (nextShift!.isUrgent)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.statusCancelled,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                            ),
                            child: Text(
                              'URGENT',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: DesignTokens.fontWeightBold,
                                fontSize: DesignTokens.fontSizeCaption,
                                color: DesignTokens.colorBlack,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      nextShift!.title,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontSize: DesignTokens.fontSizeTitle,
                        letterSpacing: 0.0,
                        color: DesignTokens.colorBlack,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      nextShift!.location,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeBody,
                        letterSpacing: 0.0,
                        color: DesignTokens.colorBlack.withValues(alpha: 0.8),
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    _buildShiftDetails(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Static shift card without animation
  Widget _buildStaticShiftCard() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: PremiumGlassContainer(
        intensity: GlassIntensity.premium,
        elevation: GlassElevation.raised,
        tintColor: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
        enableTrustBorder: true,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusM),
          bottomLeft: Radius.circular(DesignTokens.radiusM),
          bottomRight: Radius.circular(DesignTokens.radiusM),
          topRight: Radius.circular(DesignTokens.radiusXXXL + DesignTokens.radiusXXXL),
        ),
        onTap: onTap,
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Text(
                  'Volgende Dienst',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeBody,
                    letterSpacing: 0.0,
                    color: DesignTokens.colorBlack,
                  ),
                ),
                const Spacer(),
                if (nextShift!.isUrgent)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.statusCancelled,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    child: Text(
                      'URGENT',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.fontWeightBold,
                        fontSize: DesignTokens.fontSizeCaption,
                        color: DesignTokens.colorBlack,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              nextShift!.title,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeTitle,
                letterSpacing: 0.0,
                color: DesignTokens.colorBlack,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              nextShift!.location,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeBody,
                letterSpacing: 0.0,
                color: DesignTokens.colorBlack.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildShiftDetails(),
          ],
        ),
      ),
    );
  }

  /// Material 3 compliant no shift card
  Widget _buildNoShiftCard() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Card(
        elevation: DesignTokens.elevationNone,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusM),
            bottomLeft: Radius.circular(DesignTokens.radiusM),
            bottomRight: Radius.circular(DesignTokens.radiusM),
            topRight: Radius.circular(DesignTokens.radiusXXXL + DesignTokens.radiusXXXL),
          ),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Geen Geplande Diensten',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeSubtitle,
                  letterSpacing: 0.0,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                'Zoek naar beschikbare opdrachten in de marketplace',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightRegular,
                  fontSize: DesignTokens.fontSizeBody,
                  letterSpacing: 0.0,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              Row(
                children: [
                  Icon(
                    Icons.search,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeM,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'Bekijk Jobs',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: DesignTokens.colorBlack,
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    SafeDateUtils.formatTimeRange(
                      nextShift!.startTime,
                      nextShift!.endTime,
                    ),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: DesignTokens.fontSizeBody,
                      letterSpacing: 0.0,
                      color: DesignTokens.colorBlack,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: DesignTokens.colorBlack,
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    SafeDateUtils.formatDayMonth(nextShift!.startTime),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: DesignTokens.fontSizeBody,
                      letterSpacing: 0.0,
                      color: DesignTokens.colorBlack,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.euro, 
                    color: DesignTokens.colorBlack, 
                    size: DesignTokens.iconSizeS,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    '€${nextShift!.hourlyRate.toStringAsFixed(2)}/uur',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      fontSize: DesignTokens.fontSizeBody,
                      letterSpacing: 0.0,
                      color: DesignTokens.colorBlack,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                offset: Offset(0, DesignTokens.elevationMedium),
                blurRadius: DesignTokens.elevationHigh,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            child: Icon(
              Icons.arrow_forward,
              color: _getGradientStartColor(),
              size: DesignTokens.iconSizeL,
            ),
          ),
        ),
      ],
    );
  }

  Color _getGradientStartColor() {
    if (nextShift == null) return DesignTokens.guardPrimary;

    switch (nextShift!.shiftType) {
      case ShiftType.office:
        return DesignTokens.colorPrimaryBlue;
      case ShiftType.retail:
        return DesignTokens.colorSuccess;
      case ShiftType.event:
        return DesignTokens.colorWarning;
      case ShiftType.night:
        return DesignTokens.guardTextPrimary;
      case ShiftType.patrol:
        return DesignTokens.guardAccent;
      case ShiftType.emergency:
        return DesignTokens.colorError;
    }
  }
}