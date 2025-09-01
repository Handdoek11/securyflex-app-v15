import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/auth/enhanced_glassmorphic_login_screen.dart';
import 'package:securyflex_app/marketplace/jobs_home_screen.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'components/auth_splash_view.dart';
import 'components/auth_welcome_view.dart';
import 'components/auth_center_next_button.dart';
import 'components/auth_top_back_skip_view.dart';

/// Introduction animation screen adapted from template for authentication
/// Shows onboarding flow that leads to login or main app
class IntroductionAnimationScreen extends StatefulWidget {
  const IntroductionAnimationScreen({super.key});

  @override
  State<IntroductionAnimationScreen> createState() =>
      _IntroductionAnimationScreenState();
}

class _IntroductionAnimationScreenState
    extends State<IntroductionAnimationScreen> with TickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 6));
    _animationController?.animateTo(0.0);
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SecuryFlexTheme.getColorScheme(UserRole.guard).surface,
      body: ClipRect(
        child: Stack(
          children: [
            AuthSplashView(
              animationController: _animationController!,
            ),
            AuthWelcomeView(
              animationController: _animationController!,
            ),
            AuthTopBackSkipView(
              onBackClick: _onBackClick,
              onSkipClick: _onSkipClick,
              animationController: _animationController!,
            ),
            AuthCenterNextButton(
              animationController: _animationController!,
              onNextClick: _onNextClick,
            ),
          ],
        ),
      ),
    );
  }

  void _onSkipClick() {
    _animationController?.animateTo(0.8,
        duration: Duration(milliseconds: 1200));
  }

  void _onBackClick() {
    if (_animationController!.value >= 0 &&
        _animationController!.value <= 0.2) {
      _animationController?.animateTo(0.0);
    } else if (_animationController!.value > 0.2 &&
        _animationController!.value <= 0.4) {
      _animationController?.animateTo(0.2);
    } else if (_animationController!.value > 0.4 &&
        _animationController!.value <= 0.6) {
      _animationController?.animateTo(0.4);
    } else if (_animationController!.value > 0.6 &&
        _animationController!.value <= 0.8) {
      _animationController?.animateTo(0.6);
    } else if (_animationController!.value > 0.8 &&
        _animationController!.value <= 1.0) {
      _animationController?.animateTo(0.8);
    }
  }

  void _onNextClick() {
    if (_animationController!.value >= 0 &&
        _animationController!.value <= 0.2) {
      _animationController?.animateTo(0.4);
    } else if (_animationController!.value > 0.2 &&
        _animationController!.value <= 0.4) {
      _animationController?.animateTo(0.6);
    } else if (_animationController!.value > 0.4 &&
        _animationController!.value <= 0.6) {
      _animationController?.animateTo(0.8);
    } else if (_animationController!.value > 0.6 &&
        _animationController!.value <= 0.8) {
      _signUpClick();
    }
  }

  void _signUpClick() {
    // Check if user is already logged in
    if (AuthService.isLoggedIn) {
      // Navigate to main app - determine user type and navigate
      // TODO: Check actual user type from AuthService
      context.go('/beveiliger/dashboard');
    } else {
      // Navigate to login screen
      context.go('/login');
    }
  }
}
