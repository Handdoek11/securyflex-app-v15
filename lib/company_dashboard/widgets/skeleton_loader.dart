import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Skeleton loader component for Company dashboard
/// Provides consistent loading states across all widgets
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final UserRole userRole;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.userRole = UserRole.company,
  });

  /// Create a skeleton for text lines
  factory SkeletonLoader.text({
    double? width,
    double height = 16,
    UserRole userRole = UserRole.company,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      userRole: userRole,
    );
  }

  /// Create a skeleton for cards
  factory SkeletonLoader.card({
    double? width,
    double height = 120,
    UserRole userRole = UserRole.company,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      userRole: userRole,
    );
  }

  /// Create a skeleton for circular elements (avatars, icons)
  factory SkeletonLoader.circle({
    double size = 40,
    UserRole userRole = UserRole.company,
  }) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      userRole: userRole,
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800), // Faster animation for better perceived performance
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate( // Reduced contrast for subtler effect
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(DesignTokens.radiusS),
          ),
        );
      },
    );
  }
}

/// Skeleton loader for job cards
class JobCardSkeleton extends StatelessWidget {
  final UserRole userRole;

  const JobCardSkeleton({
    super.key,
    this.userRole = UserRole.company,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: SecuryFlexTheme.getColorScheme(userRole).surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: SecuryFlexTheme.getColorScheme(userRole).outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and status row
            Row(
              children: [
                Expanded(
                  child: SkeletonLoader.text(
                    width: 150,
                    userRole: userRole,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingS),
                SkeletonLoader.text(
                  width: 60,
                  height: 20,
                  userRole: userRole,
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingS),
            // Location and rate row
            Row(
              children: [
                SkeletonLoader.circle(size: 16, userRole: userRole),
                SizedBox(width: DesignTokens.spacingXS),
                SkeletonLoader.text(width: 100, userRole: userRole),
                SizedBox(width: DesignTokens.spacingM),
                SkeletonLoader.circle(size: 16, userRole: userRole),
                SizedBox(width: DesignTokens.spacingXS),
                SkeletonLoader.text(width: 80, userRole: userRole),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for stat cards
class StatCardSkeleton extends StatelessWidget {
  final UserRole userRole;

  const StatCardSkeleton({
    super.key,
    this.userRole = UserRole.company,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: SecuryFlexTheme.getColorScheme(userRole).surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: SecuryFlexTheme.getColorScheme(userRole).outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SkeletonLoader.circle(size: 24, userRole: userRole),
          SizedBox(height: DesignTokens.spacingXS),
          SkeletonLoader.text(width: 40, height: 20, userRole: userRole),
          SizedBox(height: DesignTokens.spacingXS),
          SkeletonLoader.text(width: 60, height: 12, userRole: userRole),
        ],
      ),
    );
  }
}

/// Skeleton loader for company profile
class CompanyProfileSkeleton extends StatelessWidget {
  final UserRole userRole;

  const CompanyProfileSkeleton({
    super.key,
    this.userRole = UserRole.company,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              SkeletonLoader.circle(size: 24, userRole: userRole),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: SkeletonLoader.text(width: 120, userRole: userRole),
              ),
              SkeletonLoader.text(width: 60, height: 32, userRole: userRole),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          // Company info
          SkeletonLoader.text(width: 200, userRole: userRole),
          SizedBox(height: DesignTokens.spacingXS),
          SkeletonLoader.text(width: 150, userRole: userRole),
          SizedBox(height: DesignTokens.spacingXS),
          SkeletonLoader.text(width: 180, userRole: userRole),
          SizedBox(height: DesignTokens.spacingM),
          // Stats row
          Row(
            children: [
              Expanded(child: StatCardSkeleton(userRole: userRole)),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(child: StatCardSkeleton(userRole: userRole)),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(child: StatCardSkeleton(userRole: userRole)),
            ],
          ),
        ],
      ),
    );
  }
}
