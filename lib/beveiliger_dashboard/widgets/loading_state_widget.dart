import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import '../../core/shared_animation_controller.dart';

class LoadingStateWidget extends StatefulWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;

  const LoadingStateWidget({super.key, this.animationController, this.animation});

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with TickerProviderStateMixin {
  AnimationController? _shimmerController;

  @override
  void initState() {
    super.initState();
    // Use SharedAnimationController instance directly
    final subscriberId = '${widget.runtimeType}_$hashCode';
    _shimmerController = SharedAnimationController.instance.getController(
      'shimmer_effect',
      subscriberId,
      this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _shimmerController?.repeat();
    
    debugPrint('🔧 LoadingState: Using shared shimmer animation controller');
  }

  @override
  void dispose() {
    // Release shared controller
    final subscriberId = '${widget.runtimeType}_$hashCode';
    SharedAnimationController.instance.releaseController('shimmer_effect', subscriberId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 30 * (1.0 - widget.animation!.value), 0.0),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 16, bottom: 18),
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
                padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildShimmerLine(width: 120, height: 16),
                      SizedBox(height: 12),
                      _buildShimmerLine(width: double.infinity, height: 12),
                      SizedBox(height: 8),
                      _buildShimmerLine(width: 200, height: 12),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildShimmerLine(width: 60, height: 40)),
                          SizedBox(width: 16),
                          Expanded(child: _buildShimmerLine(width: 60, height: 40)),
                          SizedBox(width: 16),
                          Expanded(child: _buildShimmerLine(width: 60, height: 40)),
                        ],
                      ),
                    ],
                  ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLine({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerController!,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [
                DesignTokens.guardSurface,
                DesignTokens.guardSurface.withValues(alpha: 0.5),
                DesignTokens.guardSurface,
              ],
              stops: [
                _shimmerController!.value - 0.3,
                _shimmerController!.value,
                _shimmerController!.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
