import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Top back skip view component adapted from template for SecuryFlex authentication
class AuthTopBackSkipView extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onBackClick;
  final VoidCallback onSkipClick;

  const AuthTopBackSkipView({
    super.key,
    required this.animationController,
    required this.onBackClick,
    required this.onSkipClick,
  });

  // Helper method to get consistent color scheme
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);

  @override
  Widget build(BuildContext context) {
    final topMoveAnimation =
        Tween<Offset>(begin: Offset(0, -1), end: Offset(0, 0))
            .animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.0,
        0.2,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    final backButtonAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.0,
        0.2,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    final skipButtonAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.0,
        0.8,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      child: SlideTransition(
        position: topMoveAnimation,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button
              FadeTransition(
                opacity: backButtonAnimation,
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return animationController.value > 0.0
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: onBackClick,
                              child: Container(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: _colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(width: 48);
                  },
                ),
              ),
              
              // Skip button
              FadeTransition(
                opacity: skipButtonAnimation,
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return animationController.value < 0.8
                        ? Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: onSkipClick,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _colorScheme.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'Overslaan',
                                  style: TextStyle(
                                    color: _colorScheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SizedBox(width: 48);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
