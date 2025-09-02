import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import '../../core/shared_animation_controller.dart';

import '../models/enhanced_dashboard_data.dart';
import '../models/api_models.dart';
import '../services/dashboard_api_service.dart';
import '../../auth/auth_service.dart';

/// Earnings Card Widget with real-time Dutch euro formatting and API integration
/// 
/// Features:
/// - Real-time earnings tracking during active shifts via API
/// - WebSocket integration for live updates
/// - Dutch euro formatting (€1.234,56)
/// - CAO arbeidsrecht compliance indicators
/// - Overtime calculations (150% after 40h, 200% after 48h)
/// - Vakantiegeld (8% holiday allowance) display
/// - BTW calculations for freelance workers
/// - Visual indicators for real-time updates
/// - Offline-first with Firestore fallback
/// - Responsive design for different screen sizes
class EarningsCardWidget extends StatefulWidget {
  final EnhancedEarningsData? earnings; // Made nullable for API integration
  final bool isRealTime;
  final bool useApi; // New parameter for API integration

  const EarningsCardWidget({
    super.key,
    this.earnings,
    this.isRealTime = false,
    this.useApi = true, // Default to using API
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
  
  // API integration
  EarningsApiModel? _apiEarningsData;
  bool _isLoadingApi = false;
  String? _apiError;

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

    final initialAmount = widget.useApi ? 0.0 : (widget.earnings?.totalToday ?? 0.0);
    _countUpAnimation = Tween<double>(
      begin: 0.0,
      end: initialAmount,
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

    // Initialize API integration if enabled
    if (widget.useApi) {
      _initializeApiIntegration();
    } else {
      // Start animations for legacy mode
      _countUpController.forward();
      if (widget.isRealTime) {
        _pulseController.repeat(reverse: true);
      }
    }
    
    debugPrint('🔧 EarningsCard: Using shared animation controllers with API: ${widget.useApi}');
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

    // Handle API mode changes
    if (widget.useApi != oldWidget.useApi) {
      if (widget.useApi) {
        _initializeApiIntegration();
      }
    }

    // Animate to new earnings value (legacy mode)
    if (!widget.useApi && widget.earnings != null && oldWidget.earnings != null) {
      if (widget.earnings!.totalToday != oldWidget.earnings!.totalToday) {
        _animateToNewValue(widget.earnings!.totalToday);
      }
    }
  }

  @override
  void dispose() {
    // Release shared animation controllers
    SharedAnimationController.instance.releaseController('earnings_pulse', 'earnings_card_$hashCode');
    SharedAnimationController.instance.releaseController('earnings_count', 'earnings_card_$hashCode');
    super.dispose();
  }

  /// Initialize API integration and real-time streams
  Future<void> _initializeApiIntegration() async {
    final guardId = AuthService.currentUserId;
    if (guardId.isEmpty) return;
    
    setState(() {
      _isLoadingApi = true;
      _apiError = null;
    });
    
    try {
      // Initialize API service
      await DashboardApiService.instance.initialize();
      
      // Load initial data
      final initialData = await DashboardApiService.instance.getEarningsData(guardId);
      
      if (mounted) {
        setState(() {
          _apiEarningsData = initialData;
          _isLoadingApi = false;
        });
        
        // Animate to API data
        _animateToNewValue(initialData.todayEarnings);
      }
      
      // Start real-time animations if enabled
      if (widget.isRealTime) {
        _pulseController.repeat(reverse: true);
      }
      
      // Listen to real-time updates
      DashboardApiService.instance.earningsStream.listen(
        (earningsData) {
          if (mounted) {
            setState(() {
              _apiEarningsData = earningsData;
            });
            
            // Animate to new value
            _animateToNewValue(earningsData.todayEarnings);
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _apiError = error.toString();
            });
          }
        },
      );
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingApi = false;
          _apiError = e.toString();
        });
      }
    }
  }
  
  /// Animate to new earnings value
  void _animateToNewValue(double newValue) {
    _countUpController.reset();
    
    // Create new animation with updated values
    _countUpAnimation = Tween<double>(
      begin: _displayedAmount,
      end: newValue,
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
  
  /// Get current earnings data (API or legacy)
  EarningsData? get _currentEarningsData {
    if (widget.useApi) {
      if (_apiEarningsData != null) {
        // Convert API model to legacy format for compatibility
        return EarningsData(
          todayEarnings: _apiEarningsData!.todayEarnings,
          weeklyEarnings: _apiEarningsData!.weeklyEarnings,
          monthlyEarnings: _apiEarningsData!.monthlyEarnings,
          hoursWorkedToday: _apiEarningsData!.hoursWorkedToday,
          averageHourlyRate: _apiEarningsData!.averageHourlyRate,
        );
      }
      return null;
    }
    return widget.earnings != null ? EarningsData.fromEnhanced(widget.earnings!) : null;
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    // Show loading state for API
    if (widget.useApi && _isLoadingApi) {
      return _buildLoadingState(colorScheme);
    }
    
    // Show error state for API
    if (widget.useApi && _apiError != null) {
      return _buildErrorState(colorScheme);
    }
    
    // Get current data
    final currentData = _currentEarningsData;
    if (currentData == null) {
      return _buildEmptyState(colorScheme);
    }
    
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
                _buildMainEarnings(colorScheme, currentData),
                
                const SizedBox(height: DesignTokens.spacingL),
                
                // Additional earnings info
                _buildEarningsBreakdown(colorScheme, currentData),
                
                if (!widget.useApi && widget.earnings?.overtimeHours != null && widget.earnings!.overtimeHours > 0) ...[
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

  Widget _buildMainEarnings(ColorScheme colorScheme, EarningsData currentData) {
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
          '${currentData.hoursWorkedToday.toStringAsFixed(1)} uur gewerkt',
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

  Widget _buildEarningsBreakdown(ColorScheme colorScheme, EarningsData currentData) {
    return Column(
      children: [
        _buildEarningsRow(
          'Deze week',
          _formatDutchCurrency(currentData.weeklyEarnings),
          null, // Hours not available in simplified API model
          colorScheme,
        ),
        const SizedBox(height: DesignTokens.spacingS),
        _buildEarningsRow(
          'Deze maand',
          _formatDutchCurrency(currentData.monthlyEarnings),
          null,
          colorScheme,
        ),
        
        // For API mode, we'll show basic info without freelance calculations
        if (!widget.useApi && widget.earnings?.isFreelance == true) ...[
          const SizedBox(height: DesignTokens.spacingS),
          _buildEarningsRow(
            'Vakantiegeld (8%)',
            _formatDutchCurrency(widget.earnings!.vakantiegeld),
            null,
            colorScheme,
            isHighlight: true,
          ),
          const SizedBox(height: DesignTokens.spacingS),
          _buildEarningsRow(
            'BTW (21%)',
            _formatDutchCurrency(widget.earnings!.btwAmount),
            null,
            colorScheme,
            isWarning: true,
          ),
        ],
        
        // Show average hourly rate for API mode
        if (widget.useApi && currentData.averageHourlyRate > 0) ...[
          const SizedBox(height: DesignTokens.spacingS),
          _buildEarningsRow(
            'Gemiddeld uurtarief',
            _formatDutchCurrency(currentData.averageHourlyRate),
            null,
            colorScheme,
            isHighlight: true,
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
    final isCompliant = widget.earnings?.isOvertimeCompliant ?? true;
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
                'Overwerk: ${widget.earnings?.overtimeHours.toStringAsFixed(1) ?? '0.0'}u',
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
                ? 'CAO arbeidsrecht: Conform (${((widget.earnings?.overtimeRate ?? 0) / (widget.earnings?.hourlyRate ?? 1) * 100).toStringAsFixed(0)}% tarief)'
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
            'Live bijgewerkt • ${_formatTime(widget.earnings?.lastCalculated ?? DateTime.now())}',
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
  
  /// Build loading state for API data
  Widget _buildLoadingState(ColorScheme colorScheme) {
    return PremiumSecurityGlassCard(
      title: 'Verdiensten Vandaag',
      icon: Icons.euro_symbol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Text(
                'Verdiensten laden...',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontSize: DesignTokens.fontSizeBody,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build error state for API data
  Widget _buildErrorState(ColorScheme colorScheme) {
    return PremiumSecurityGlassCard(
      title: 'Verdiensten Vandaag',
      icon: Icons.euro_symbol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: DesignTokens.colorError,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Text(
                  'Fout bij laden verdiensten',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: DesignTokens.fontSizeBody,
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            _apiError ?? 'Onbekende fout',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build empty state when no data is available
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return PremiumSecurityGlassCard(
      title: 'Verdiensten Vandaag',
      icon: Icons.euro_symbol,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '€0,00',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeDisplayLarge,
              color: colorScheme.onSurfaceVariant,
              height: DesignTokens.lineHeightTight,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Geen diensten vandaag',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for earnings data compatibility
class EarningsData {
  final double todayEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final double hoursWorkedToday;
  final double averageHourlyRate;
  
  const EarningsData({
    required this.todayEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.hoursWorkedToday,
    required this.averageHourlyRate,
  });
  
  factory EarningsData.fromEnhanced(EnhancedEarningsData enhanced) {
    return EarningsData(
      todayEarnings: enhanced.totalToday,
      weeklyEarnings: enhanced.totalWeek,
      monthlyEarnings: enhanced.totalMonth,
      hoursWorkedToday: enhanced.hoursWorkedToday,
      averageHourlyRate: enhanced.hourlyRate,
    );
  }
}