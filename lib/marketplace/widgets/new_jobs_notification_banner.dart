import 'dart:async';
import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';

/// Real-time notification banner for new job availability
/// Slides down from top with glassmorphic design and auto-dismiss functionality
class NewJobsNotificationBanner extends StatefulWidget {
  final int newJobsCount;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final UserRole userRole;
  final Duration autoHideDuration;
  final bool showPulseAnimation;
  
  const NewJobsNotificationBanner({
    super.key,
    required this.newJobsCount,
    required this.onTap,
    this.onDismiss,
    this.userRole = UserRole.guard,
    this.autoHideDuration = const Duration(seconds: 5),
    this.showPulseAnimation = true,
  });
  
  @override
  State<NewJobsNotificationBanner> createState() => _NewJobsNotificationBannerState();
}

class _NewJobsNotificationBannerState extends State<NewJobsNotificationBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  Timer? _autoHideTimer;
  bool _isVisible = false;
  
  @override
  void initState() {
    super.initState();
    
    // Slide animation controller
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Slide down animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // Pulse animation for attention
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Show banner
    _showBanner();
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }
  
  void _showBanner() {
    setState(() => _isVisible = true);
    
    // Slide in animation
    _slideController.forward();
    
    // Start pulse animation if enabled
    if (widget.showPulseAnimation) {
      _pulseController.repeat(reverse: true);
    }
    
    // Auto-hide timer
    _autoHideTimer = Timer(widget.autoHideDuration, () {
      _hideBanner();
    });
  }
  
  void _hideBanner() {
    if (!mounted) return;
    
    _pulseController.stop();
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
        widget.onDismiss?.call();
      }
    });
  }
  
  void _handleTap() {
    _autoHideTimer?.cancel();
    widget.onTap();
    _hideBanner();
  }
  
  void _handleDismiss() {
    _autoHideTimer?.cancel();
    _hideBanner();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.showPulseAnimation ? _pulseAnimation.value : 1.0,
                child: Container(
                  margin: const EdgeInsets.all(DesignTokens.spacingM),
                  child: PremiumGlassContainer(
                    intensity: GlassIntensity.premium,
                    elevation: GlassElevation.floating,
                    tintColor: DesignTokens.colorSuccess,
                    enableTrustBorder: true,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                      child: InkWell(
                        onTap: _handleTap,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.spacingM),
                          child: Row(
                            children: [
                              // Animated icon with glow effect
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: DesignTokens.colorSuccess.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                                  boxShadow: [
                                    BoxShadow(
                                      color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.work_outline,
                                  color: DesignTokens.colorSuccess,
                                  size: DesignTokens.iconSizeM,
                                ),
                              ),
                              
                              const SizedBox(width: DesignTokens.spacingM),
                              
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getNotificationTitle(),
                                      style: TextStyle(
                                        fontFamily: DesignTokens.fontFamily,
                                        fontWeight: DesignTokens.fontWeightBold,
                                        fontSize: DesignTokens.fontSizeBody,
                                        color: DesignTokens.colorSuccess,
                                      ),
                                    ),
                                    const SizedBox(height: DesignTokens.spacingXXS),
                                    Text(
                                      'Tik om te bekijken',
                                      style: TextStyle(
                                        fontFamily: DesignTokens.fontFamily,
                                        fontWeight: DesignTokens.fontWeightRegular,
                                        fontSize: DesignTokens.fontSizeCaption,
                                        color: DesignTokens.colorSuccess.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Dismiss button
                              InkWell(
                                onTap: _handleDismiss,
                                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                                child: Container(
                                  padding: const EdgeInsets.all(DesignTokens.spacingXS),
                                  child: Icon(
                                    Icons.close,
                                    color: DesignTokens.colorSuccess.withValues(alpha: 0.7),
                                    size: DesignTokens.iconSizeS,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  String _getNotificationTitle() {
    if (widget.newJobsCount == 1) {
      return '1 nieuwe opdracht beschikbaar';
    } else {
      return '${widget.newJobsCount} nieuwe opdrachten beschikbaar';
    }
  }
}

/// Real-time job updates service for managing notification state
class JobUpdateNotificationService {
  static JobUpdateNotificationService? _instance;
  static JobUpdateNotificationService get instance => _instance ??= JobUpdateNotificationService._();
  
  JobUpdateNotificationService._();
  
  final ValueNotifier<int> _newJobsCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> _hasNewJobs = ValueNotifier<bool>(false);
  
  DateTime? _lastViewedTime;
  Timer? _notificationTimer;
  int _totalJobsLastCount = 0;
  bool _isJobsPageVisible = false;
  
  /// Initialize the service with current job count
  void initialize(int currentJobCount) {
    _totalJobsLastCount = currentJobCount;
    _lastViewedTime = DateTime.now();
    _newJobsCount.value = 0;
    _hasNewJobs.value = false;
    
    debugPrint('🔔 JobUpdateNotificationService initialized with $currentJobCount jobs');
  }
  
  /// Update job count and trigger notifications if necessary
  void updateJobCount(int newJobCount) {
    if (!_isJobsPageVisible) {
      debugPrint('🔔 Jobs page not visible, skipping notification update');
      return;
    }
    
    if (newJobCount > _totalJobsLastCount) {
      final newJobsAdded = newJobCount - _totalJobsLastCount;
      
      debugPrint('🔔 Detected $newJobsAdded new jobs (was: $_totalJobsLastCount, now: $newJobCount)');
      
      // Only show notification if user has been on page for at least 30 seconds
      final timeSinceLastView = _lastViewedTime != null 
          ? DateTime.now().difference(_lastViewedTime!)
          : Duration.zero;
      
      if (timeSinceLastView.inSeconds >= 30) {
        _newJobsCount.value = newJobsAdded;
        _hasNewJobs.value = true;
        
        // Reset notification after showing
        _scheduleNotificationReset();
      } else {
        debugPrint('🔔 User viewed jobs recently (${timeSinceLastView.inSeconds}s ago), not showing notification');
      }
    }
    
    _totalJobsLastCount = newJobCount;
  }
  
  /// Mark jobs page as viewed (resets notification state)
  void markJobsAsViewed() {
    _lastViewedTime = DateTime.now();
    _newJobsCount.value = 0;
    _hasNewJobs.value = false;
    
    debugPrint('🔔 Jobs marked as viewed at ${_lastViewedTime}');
  }
  
  /// Set jobs page visibility
  void setJobsPageVisible(bool isVisible) {
    _isJobsPageVisible = isVisible;
    
    if (isVisible) {
      markJobsAsViewed();
    }
    
    debugPrint('🔔 Jobs page visibility: $isVisible');
  }
  
  /// Schedule notification reset
  void _scheduleNotificationReset() {
    _notificationTimer?.cancel();
    
    _notificationTimer = Timer(const Duration(minutes: 1), () {
      _newJobsCount.value = 0;
      _hasNewJobs.value = false;
      debugPrint('🔔 Notification auto-reset after 1 minute');
    });
  }
  
  /// Get current new jobs count
  ValueNotifier<int> get newJobsCount => _newJobsCount;
  
  /// Get notification visibility state
  ValueNotifier<bool> get hasNewJobs => _hasNewJobs;
  
  /// Dispose resources
  void dispose() {
    _notificationTimer?.cancel();
    _newJobsCount.dispose();
    _hasNewJobs.dispose();
  }
}

/// Widget that wraps job lists and manages real-time notifications
class JobListWithNotifications extends StatefulWidget {
  final Widget child;
  final List<dynamic> jobs;
  final UserRole userRole;
  final Function()? onNewJobsTapped;
  
  const JobListWithNotifications({
    super.key,
    required this.child,
    required this.jobs,
    this.userRole = UserRole.guard,
    this.onNewJobsTapped,
  });
  
  @override
  State<JobListWithNotifications> createState() => _JobListWithNotificationsState();
}

class _JobListWithNotificationsState extends State<JobListWithNotifications> {
  final JobUpdateNotificationService _notificationService = 
      JobUpdateNotificationService.instance;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.initialize(widget.jobs.length);
      _notificationService.setJobsPageVisible(true);
    });
  }
  
  @override
  void didUpdateWidget(JobListWithNotifications oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.jobs.length != oldWidget.jobs.length) {
      _notificationService.updateJobCount(widget.jobs.length);
    }
  }
  
  @override
  void dispose() {
    _notificationService.setJobsPageVisible(false);
    super.dispose();
  }
  
  void _handleNewJobsTapped() {
    _notificationService.markJobsAsViewed();
    widget.onNewJobsTapped?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // New jobs notification banner
        ValueListenableBuilder<bool>(
          valueListenable: _notificationService.hasNewJobs,
          builder: (context, hasNewJobs, child) {
            if (!hasNewJobs) return const SizedBox.shrink();
            
            return ValueListenableBuilder<int>(
              valueListenable: _notificationService.newJobsCount,
              builder: (context, newJobsCount, child) {
                return NewJobsNotificationBanner(
                  newJobsCount: newJobsCount,
                  userRole: widget.userRole,
                  onTap: _handleNewJobsTapped,
                  onDismiss: () {
                    _notificationService.markJobsAsViewed();
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Floating action button for new jobs with notification badge
class NewJobsFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final UserRole userRole;
  
  const NewJobsFloatingButton({
    super.key,
    required this.onPressed,
    this.userRole = UserRole.guard,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return ValueListenableBuilder<int>(
      valueListenable: JobUpdateNotificationService.instance.newJobsCount,
      builder: (context, newJobsCount, child) {
        return Stack(
          children: [
            FloatingActionButton.extended(
              onPressed: onPressed,
              backgroundColor: DesignTokens.colorSuccess,
              foregroundColor: DesignTokens.colorWhite,
              elevation: 8,
              label: Text(
                newJobsCount > 0
                    ? '$newJobsCount nieuwe jobs'
                    : 'Vernieuw jobs',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                ),
              ),
              icon: Icon(
                newJobsCount > 0 ? Icons.refresh : Icons.work_outline,
                size: DesignTokens.iconSizeM,
              ),
            ),
            
            // Notification badge
            if (newJobsCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DesignTokens.colorError,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DesignTokens.colorWhite,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    newJobsCount > 99 ? '99+' : newJobsCount.toString(),
                    style: TextStyle(
                      color: DesignTokens.colorWhite,
                      fontSize: 11,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Simple notification dot for indicating new content
class NewContentIndicator extends StatelessWidget {
  final bool hasNewContent;
  final double size;
  final Color? color;
  
  const NewContentIndicator({
    super.key,
    required this.hasNewContent,
    this.size = 8.0,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    if (!hasNewContent) return const SizedBox.shrink();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? DesignTokens.colorError,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? DesignTokens.colorError).withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}