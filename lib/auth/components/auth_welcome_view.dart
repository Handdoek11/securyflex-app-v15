import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import '../../unified_design_tokens.dart';

/// Welcome view component adapted from template for SecuryFlex authentication
class AuthWelcomeView extends StatelessWidget {
  final AnimationController animationController;
  const AuthWelcomeView({super.key, required this.animationController});

  // Helper method to get consistent color scheme
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);

  @override
  Widget build(BuildContext context) {
    final firstHalfAnimation =
        Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          0.6,
          0.8,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );
    final secondHalfAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(-1, 0)).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          0.8,
          1.0,
          curve: Curves.fastOutSlowIn,
        ),
      ),
    );

    final welcomeFirstHalfAnimation =
        Tween<Offset>(begin: Offset(2, 0), end: Offset(0, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    final welcomeImageAnimation =
        Tween<Offset>(begin: Offset(4, 0), end: Offset(0, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.6,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    return SlideTransition(
      position: firstHalfAnimation,
      child: SlideTransition(
        position: secondHalfAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: welcomeImageAnimation,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(DesignTokens.spacingXXL),
                        child: Icon(
                          Icons.handshake,
                          size: 100,
                          color: _colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: DesignTokens.spacingXL),
              SlideTransition(
                position: welcomeFirstHalfAnimation,
                child: Text(
                  "Welkom bij SecuryFlex",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _colorScheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 64, right: 64, top: 16, bottom: 16),
                child: Text(
                  "De moderne beveiligingsmarktplaats waar beveiligers en bedrijven elkaar vinden. Veilig, betrouwbaar en efficiënt.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: DesignTokens.colorGray600,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: DesignTokens.spacingL - 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeatureItem(
                      Icons.security,
                      "Veilig",
                      "Geverifieerde beveiligers",
                    ),
                    _buildFeatureItem(
                      Icons.business,
                      "Betrouwbaar",
                      "Erkende bedrijven",
                    ),
                    _buildFeatureItem(
                      Icons.speed,
                      "Snel",
                      "Directe matching",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS + 4),
          decoration: BoxDecoration(
            color: _colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: _colorScheme.primary,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _colorScheme.primary,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: DesignTokens.colorGray600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
