import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../unified_design_tokens.dart';
import 'premium_color_system.dart';
import 'premium_micro_interactions.dart';

/// **Contextual Micro-Moments System - 2025 Intelligent UX**
/// 
/// Advanced contextual awareness system for security industry applications:
/// - Predictive user assistance based on behavior patterns
/// - Context-aware micro-interactions that anticipate user needs
/// - Smart notification timing based on user attention patterns
/// - Intelligent content prioritization for security professionals
/// - Trust-building through helpful, non-intrusive assistance
/// 
/// This system elevates user experience from reactive to proactive,
/// building trust through intelligent, helpful interactions.

class ContextualMicroMomentsSystem {
  static final ContextualMicroMomentsSystem _instance = ContextualMicroMomentsSystem._internal();
  factory ContextualMicroMomentsSystem() => _instance;
  ContextualMicroMomentsSystem._internal();

  // User context tracking
  Map<String, dynamic> _userContext = {};
  Timer? _contextUpdateTimer;
  final List<StreamController<MicroMoment>> _momentControllers = [];

  /// Initialize the contextual system
  void initialize() {
    _startContextTracking();
    debugPrint('🧠 Contextual Micro-Moments System initialized');
  }

  /// Start tracking user context
  void _startContextTracking() {
    _contextUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateUserContext();
      _generateContextualMoments();
    });
  }

  /// Update user context based on current state
  void _updateUserContext() {
    final now = DateTime.now();
    _userContext.addAll({
      'currentTime': now,
      'timeOfDay': _getTimeOfDay(now),
      'dayOfWeek': now.weekday,
      'isWorkingHours': _isWorkingHours(now),
      'lastActivity': DateTime.now(),
    });
  }

  String _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  bool _isWorkingHours(DateTime time) {
    return time.weekday <= 5 && time.hour >= 8 && time.hour < 18;
  }

  /// Generate contextual micro-moments based on user context
  void _generateContextualMoments() {
    final timeOfDay = _userContext['timeOfDay'] as String;
    final isWorkingHours = _userContext['isWorkingHours'] as bool;
    
    // Morning motivation moment
    if (timeOfDay == 'morning' && isWorkingHours) {
      _triggerMicroMoment(MicroMoment(
        type: MicroMomentType.motivation,
        message: 'Goedemorgen! Klaar voor een productieve dag in de beveiliging?',
        priority: MicroMomentPriority.low,
        action: MicroMomentAction.showGreeting,
        contextData: {'timeOfDay': timeOfDay},
      ));
    }
    
    // End of day wrap-up
    if (timeOfDay == 'evening' && isWorkingHours) {
      _triggerMicroMoment(MicroMoment(
        type: MicroMomentType.summary,
        message: 'Dag bijna voorbij! Bekijk je verdiensten van vandaag.',
        priority: MicroMomentPriority.medium,
        action: MicroMomentAction.showEarnings,
        contextData: {'timeOfDay': timeOfDay},
      ));
    }
  }

  /// Trigger a micro-moment
  void _triggerMicroMoment(MicroMoment moment) {
    for (final controller in _momentControllers) {
      if (!controller.isClosed) {
        controller.add(moment);
      }
    }
  }

  /// Subscribe to micro-moments
  Stream<MicroMoment> subscribeTo() {
    final controller = StreamController<MicroMoment>();
    _momentControllers.add(controller);
    return controller.stream;
  }

  /// Record user interaction for context learning
  void recordInteraction(String interaction, Map<String, dynamic> data) {
    _userContext['lastInteraction'] = interaction;
    _userContext['interactionData'] = data;
    _userContext['interactionTime'] = DateTime.now();
  }

  void dispose() {
    _contextUpdateTimer?.cancel();
    for (final controller in _momentControllers) {
      controller.close();
    }
    _momentControllers.clear();
  }
}

/// **Smart Contextual Card** - Adapts based on user context
class SmartContextualCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget content;
  final VoidCallback? onTap;
  final SmartCardContext context;

  const SmartContextualCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    this.onTap,
    this.context = SmartCardContext.neutral,
  });

  @override
  State<SmartContextualCard> createState() => _SmartContextualCardState();
}

class _SmartContextualCardState extends State<SmartContextualCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _attentionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  StreamSubscription<MicroMoment>? _momentSubscription;
  bool _hasAttentionMoment = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _attentionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _attentionController,
      curve: Curves.easeInOut,
    ));

    // Subscribe to contextual moments
    _momentSubscription = ContextualMicroMomentsSystem().subscribeTo().listen(_handleMicroMoment);
  }

  void _handleMicroMoment(MicroMoment moment) {
    if (_shouldRespondToMoment(moment)) {
      setState(() {
        _hasAttentionMoment = true;
      });
      _attentionController.repeat(reverse: true);
      
      // Auto-dismiss after 10 seconds
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _hasAttentionMoment = false;
          });
          _attentionController.stop();
          _attentionController.reset();
        }
      });
    }
  }

  bool _shouldRespondToMoment(MicroMoment moment) {
    // Logic to determine if this card should respond to the moment
    switch (widget.context) {
      case SmartCardContext.earnings:
        return moment.action == MicroMomentAction.showEarnings;
      case SmartCardContext.shifts:
        return moment.action == MicroMomentAction.showShifts;
      case SmartCardContext.profile:
        return moment.action == MicroMomentAction.showProfile;
      case SmartCardContext.neutral:
        return moment.priority == MicroMomentPriority.high;
    }
  }

  @override
  void dispose() {
    _momentSubscription?.cancel();
    _pulseController.dispose();
    _attentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Record interaction for context learning
        ContextualMicroMomentsSystem().recordInteraction('card_tap', {
          'cardContext': widget.context.name,
          'title': widget.title,
        });
        
        if (_hasAttentionMoment) {
          setState(() {
            _hasAttentionMoment = false;
          });
          _attentionController.stop();
          _attentionController.reset();
        }
        
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                boxShadow: [
                  if (_hasAttentionMoment) ...[
                    BoxShadow(
                      color: _getContextColor().withValues(alpha: 0.3 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      offset: const Offset(0, 4),
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.1),
                          _getContextColor().withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: _hasAttentionMoment 
                          ? _getContextColor().withValues(alpha: 0.4)
                          : DesignTokens.guardPrimary.withValues(alpha: 0.1),
                        width: _hasAttentionMoment ? 2.0 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: TextStyle(
                                        fontFamily: DesignTokens.fontFamily,
                                        fontSize: DesignTokens.fontSizeTitle,
                                        fontWeight: DesignTokens.fontWeightSemiBold,
                                        color: DesignTokens.guardTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.subtitle,
                                      style: TextStyle(
                                        fontFamily: DesignTokens.fontFamily,
                                        fontSize: DesignTokens.fontSizeBody,
                                        color: DesignTokens.guardTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_hasAttentionMoment)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getContextColor(),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getContextColor().withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          widget.content,
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
    );
  }

  Color _getContextColor() {
    switch (widget.context) {
      case SmartCardContext.earnings:
        return DesignTokens.colorSuccess;
      case SmartCardContext.shifts:
        return DesignTokens.guardPrimary;
      case SmartCardContext.profile:
        return DesignTokens.colorInfo;
      case SmartCardContext.neutral:
        return DesignTokens.guardPrimary;
    }
  }
}

/// **Predictive Action Suggestion** - Proactive user assistance
class PredictiveActionSuggestion extends StatefulWidget {
  final String suggestion;
  final String description;
  final IconData icon;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const PredictiveActionSuggestion({
    super.key,
    required this.suggestion,
    required this.description,
    required this.icon,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  State<PredictiveActionSuggestion> createState() => _PredictiveActionSuggestionState();
}

class _PredictiveActionSuggestionState extends State<PredictiveActionSuggestion>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Auto-show after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _handleAccept() {
    HapticFeedback.mediumImpact();
    widget.onAccept();
    _dismiss();
  }

  void _handleDismiss() {
    HapticFeedback.lightImpact();
    widget.onDismiss();
    _dismiss();
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.all(DesignTokens.spacingM),
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          gradient: PremiumColors.trustGradientSecondary,
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.guardPrimary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.suggestion,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _handleDismiss,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Later',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _handleAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Doen',
                      style: TextStyle(
                        color: DesignTokens.guardPrimary,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data classes for the contextual system
class MicroMoment {
  final MicroMomentType type;
  final String message;
  final MicroMomentPriority priority;
  final MicroMomentAction action;
  final Map<String, dynamic> contextData;

  MicroMoment({
    required this.type,
    required this.message,
    required this.priority,
    required this.action,
    required this.contextData,
  });
}

enum MicroMomentType {
  motivation,
  reminder,
  suggestion,
  summary,
  alert,
}

enum MicroMomentPriority {
  low,
  medium,
  high,
}

enum MicroMomentAction {
  showGreeting,
  showEarnings,
  showShifts,
  showProfile,
  showNotifications,
}

enum SmartCardContext {
  earnings,
  shifts,
  profile,
  neutral,
}