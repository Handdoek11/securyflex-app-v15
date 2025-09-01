import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import '../../unified_design_tokens.dart';

/// Splash view component adapted from template for SecuryFlex authentication
class AuthSplashView extends StatelessWidget {
  final AnimationController animationController;
  const AuthSplashView({super.key, required this.animationController});

  // Helper method to get consistent color scheme
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);

  @override
  Widget build(BuildContext context) {
    final introImageAnimation =
        Tween<Offset>(begin: Offset(0, 0), end: Offset(0.0, -1.0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.0,
        0.2,
        curve: Curves.fastOutSlowIn,
      ),
    ));
    return SlideTransition(
      position: introImageAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _colorScheme.primary,
                      _colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.colorWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.colorBlack.withValues(alpha: 0.1),
                            spreadRadius: 10,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(DesignTokens.spacingXXL),
                      child: Icon(
                        Icons.security,
                        size: 120,
                        color: _colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXXL),
                    Text(
                      "SecuryFlex",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.colorWhite,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: DesignTokens.colorBlack.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    Text(
                      "Beveiligingsmarktplaats",
                      style: TextStyle(
                        fontSize: 20,
                        color: DesignTokens.colorWhite.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      "Verbind beveiligers met bedrijven",
                      style: TextStyle(
                        fontSize: 16,
                        color: DesignTokens.colorWhite.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
