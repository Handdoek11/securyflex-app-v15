import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import '../../core/shared_animation_controller.dart';

import '../models/enhanced_dashboard_data.dart';

/// Earnings Card Widget with real-time Dutch euro formatting
/// 
/// Features:
/// - Real-time earnings tracking during active shifts
/// - Dutch euro formatting (€1.234,56)
/// - CAO arbeidsrecht compliance indicators
/// - Overtime calculations (150% after 40h, 200% after 48h)
/// - Vakantiegeld (8% holiday allowance) display
/// - BTW calculations for freelance workers
/// - Visual indicators for real-time updates
/// - Responsive design for different screen sizes
class EarningsCardWidget extends StatefulWidget {
  final EnhancedEarningsData earnings;
  final bool isRealTime;

  const EarningsCardWidget({
    super.key,
    required this.earnings,
    this.isRealTime = false,
  });

  @override
  State<EarningsCardWidget> createState() => _EarningsCardWidgetState();
}

class _EarningsCardWidgetState extends State<EarningsCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countUpController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _countUpAnimation;

  double _displayedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Use shared animation controllers
    _pulseController = SharedAnimationController.instance.getController(
      'earnings_pulse',
      'earnings_card_$hashCode',
      this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _countUpController = SharedAnimationController.instance.getController(
      'earnings_count',
      'earnings_card_$hashCode',
      this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _countUpAnimation = Tween<double>(
      begin: 0.0,
      end: widget.earnings.totalToday,
    ).animate(CurvedAnimation(
      parent: _countUpController,
      curve: Curves.easeOut,
    ))..addListener(() {
      if (mounted) {
        setState(() {
          _displayedAmount = _countUpAnimation.value;
        });
      }
    });

    // Start animations
    _countUpController.forward();
    if (widget.isRealTime) {
      _pulseController.repeat(reverse: true);
    }
    
    debugPrint('🔧 EarningsCard: Using shared animation controllers');
  }

  @override
  void didUpdateWidget(EarningsCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update real-time animation
    if (widget.isRealTime != oldWidget.isRealTime) {
      if (widget.isRealTime) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }

    // Animate to new earnings value
    if (widget.earnings.totalToday != oldWidget.earnings.totalToday) {
      _countUpController.reset();
      
      // Create new animation with updated values
      _countUpAnimation = Tween<double>(
        begin: _displayedAmount,
        end: widget.earnings.totalToday,
      ).animate(CurvedAnimation(
        parent: _countUpController,
        curve: Curves.easeOut,
      ))..addListener(() {
        if (mounted) {
          setState(() {
            _displayedAmount = _countUpAnimation.value;
          });
        }
      });
      
      _countUpController.forward();
    }
  }

  @override
  void dispose() {
    // Release shared animation controllers
    SharedAnimationController.instance.releaseController('earnings_pulse', 'earnings_card_$hashCode');
    SharedAnimationController.instance.releaseController('earnings_count', 'earnings_card_$hashCode');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRealTime ? _pulseAnimation.value : 1.0,
          child: PremiumSecurityGlassCard(
            title: 'Verdiensten Vandaag',
            icon: Icons.euro_symbol,
            isHighPriority: widget.isRealTime,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main earnings display
                _buildMainEarnings(colorScheme),
                
                const SizedBox(height: DesignTokens.spacingL),
                
                // Additional earnings info
                _buildEarningsBreakdown(colorScheme),
                
                if (widget.earnings.overtimeHours > 0) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  _buildOvertimeInfo(colorScheme),
                ],
                
                if (widget.isRealTime) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  _buildRealTimeIndicator(colorScheme),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainEarnings(ColorScheme colorScheme) {
    final displayAmount = _formatDutchCurrency(_displayedAmount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              displayAmount,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                fontSize: DesignTokens.fontSizeDisplayLarge,
                color: colorScheme.primary,
                height: DesignTokens.lineHeightTight,
              ),
            ),
            if (widget.isRealTime) ...[
              const SizedBox(width: DesignTokens.spacingS),
              Icon(
                Icons.trending_up,
                color: DesignTokens.colorSuccess,
                size: DesignTokens.iconSizeL,
              ),
            ],
          ],
        ),
        
        const SizedBox(height: DesignTokens.spacingS),
        
        Text(
          '${widget.earnings.hoursWorkedToday.toStringAsFixed(1)} uur gewerkt',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightRegular,
            fontSize: DesignTokens.fontSizeBody,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsBreakdown(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildEarningsRow(
          'Deze week',
          widget.earnings.dutchFormattedWeek,
          '${widget.earnings.hoursWorkedWeek.toStringAsFixed(1)}u',
          colorScheme,
        ),
        const SizedBox(height: DesignTokens.spacingS),
        _buildEarningsRow(
          'Deze maand',
          widget.earnings.dutchFormattedMonth,
          null,
          colorScheme,
        ),
        
        if (widget.earnings.isFreelance) ...[
          const SizedBox(height: DesignTokens.spacingS),
          _buildEarningsRow(
            'Vakantiegeld (8%)',
            _formatDutchCurrency(widget.earnings.vakantiegeld),
            null,
            colorScheme,
            isHighlight: true,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _buildEarningsRow(
            'BTW (21%)',
            _formatDutchCurrency(widget.earnings.btwAmount),
            null,
            colorScheme,
            isWarning: true,
          ),
        ],
      ],
    );
  }

  Widget _buildEarningsRow(
    String label,
    String amount,
    String? hours,
    ColorScheme colorScheme, {
    bool isHighlight = false,
    bool isWarning = false,
  }) {
    final textColor = isWarning 
        ? DesignTokens.colorWarning
        : isHighlight 
            ? DesignTokens.colorSuccess
            : colorScheme.onSurfaceVariant;
            
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightRegular,
            fontSize: DesignTokens.fontSizeBody,
            color: textColor,
          ),
        ),
        Row(
          children: [
            Text(
              amount,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeBody,
                color: textColor,
              ),
            ),
            if (hours != null) ...[
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                '($hours)',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightRegular,
                  fontSize: DesignTokens.fontSizeCaption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildOvertimeInfo(ColorScheme colorScheme) {
    final isCompliant = widget.earnings.isOvertimeCompliant;
    final overtimeColor = isCompliant ? DesignTokens.colorSuccess : DesignTokens.colorError;
    
    return PremiumGlassContainer(
      intensity: GlassIntensity.standard,
      elevation: GlassElevation.raised,
      tintColor: overtimeColor,
      enableTrustBorder: true,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompliant ? Icons.check_circle : Icons.warning,
                color: overtimeColor,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Overwerk: ${widget.earnings.overtimeHours.toStringAsFixed(1)}u',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                  color: overtimeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            isCompliant 
                ? 'CAO arbeidsrecht: Conform (${(widget.earnings.overtimeRate / widget.earnings.hourlyRate * 100).toStringAsFixed(0)}% tarief)'
                : 'CAO arbeidsrecht: Niet conform - controleer overwerktarief',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeCaption,
              color: overtimeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeIndicator(ColorScheme colorScheme) {
    return PremiumGlassContainer(
      intensity: GlassIntensity.subtle,
      elevation: GlassElevation.raised,
      tintColor: DesignTokens.colorSuccess,
      enableTrustBorder: true,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: DesignTokens.colorSuccess,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Text(
            'Live bijgewerkt • ${_formatTime(widget.earnings.lastCalculated)}',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeCaption,
              color: DesignTokens.colorSuccess,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDutchCurrency(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    // Add thousand separators (Dutch uses dots)
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'zojuist';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}