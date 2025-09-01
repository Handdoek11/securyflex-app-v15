import 'package:flutter/material.dart';
import '../screens/company_dashboard_main.dart';
import '../screens/responsive_company_dashboard.dart';
import '../utils/company_responsive_breakpoints.dart';
import '../../unified_design_tokens.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';

/// Wrapper widget that switches between responsive and traditional dashboard
/// based on screen size. This avoids the MediaQuery issue in initState.
class ResponsiveDashboardWrapper extends StatelessWidget {
  final AnimationController? animationController;

  const ResponsiveDashboardWrapper({
    super.key,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    // Use cached responsive data for performance
    final screenWidth = context.screenWidth;
    final deviceType = context.deviceType;
    
    // Debug info - uncomment for debugging
    // print('🖥️ Screen width: $screenWidth px');
    // print('📱 Device type: $deviceType');
    // print('🎯 Using: ${screenWidth >= 768 ? "Responsive" : "Traditional"} Dashboard');
    
    // ALWAYS use responsive dashboard for tablets and up
    // This ensures desktop users get the optimized experience
    if (context.isTablet || context.isDesktop || context.isLargeDesktop) {
      // Add debug banner for development
      return Stack(
        children: [
          ResponsiveCompanyDashboard(
            animationController: animationController,
          ),
          // Debug banner (remove in production)  
          if (context.isDesktop)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: DesignTokens.colorSuccess.withValues(alpha: 0.9),
                child: Text(
                  'DESKTOP MODE (${screenWidth.toInt()}px)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    
    // Only use traditional dashboard for true mobile (< 768px)
    return CompanyDashboardMain(
      animationController: animationController,
    );
  }
}