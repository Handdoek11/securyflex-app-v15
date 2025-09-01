import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:developer' as developer;

/// Haptic feedback service for security action confirmations
/// 
/// Provides contextual haptic feedback for different security actions:
/// - Clock in/out confirmation
/// - Emergency button activation
/// - Job application submission
/// - Time tracking confirmations
/// - Security alert acknowledgments
class HapticFeedbackService {
  static const String _tag = 'HapticFeedbackService';
  static bool _isInitialized = false;
  static bool _isHapticAvailable = false;
  
  /// Initialize haptic feedback service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Test if haptic feedback is available
      await HapticFeedback.selectionClick();
      _isHapticAvailable = true;
      
      if (kDebugMode) {
        developer.log('$_tag: Haptic feedback initialized successfully', name: 'HapticFeedback');
      }
      
    } catch (e) {
      _isHapticAvailable = false;
      
      if (kDebugMode) {
        developer.log('$_tag: Haptic feedback not available: $e', name: 'HapticFeedback');
      }
    } finally {
      _isInitialized = true;
    }
  }
  
  /// Clock in/out confirmation haptic feedback
  /// Uses medium impact for important time tracking actions
  static Future<void> timeTrackingConfirmation({required bool isClockIn}) async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      if (isClockIn) {
        // Double tap pattern for clock in
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.mediumImpact();
      } else {
        // Single strong tap for clock out
        await HapticFeedback.heavyImpact();
      }
      
      if (kDebugMode) {
        developer.log('$_tag: Time tracking feedback triggered (${isClockIn ? 'in' : 'out'})', 
                     name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Time tracking feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// Emergency action haptic feedback
  /// Uses strong pattern to indicate critical action
  static Future<void> emergencyActionConfirmation() async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      // Emergency pattern: 3 heavy impacts with short delays
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
      
      if (kDebugMode) {
        developer.log('$_tag: Emergency action feedback triggered', name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Emergency feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// Job application submission confirmation
  /// Uses light impact for successful submission
  static Future<void> jobApplicationConfirmation() async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      // Success pattern: light impact followed by selection click
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.selectionClick();
      
      if (kDebugMode) {
        developer.log('$_tag: Job application feedback triggered', name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Job application feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// Security alert acknowledgment feedback
  /// Uses medium impact to confirm important security actions
  static Future<void> securityAlertConfirmation({required SecurityAlertType alertType}) async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      switch (alertType) {
        case SecurityAlertType.incident:
          // Incident pattern: 2 medium impacts
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.mediumImpact();
          break;
          
        case SecurityAlertType.emergency:
          // Emergency pattern: 3 heavy impacts (same as emergency action)
          await emergencyActionConfirmation();
          return; // Already logged in emergency method
          
        case SecurityAlertType.warning:
          // Warning pattern: single medium impact
          await HapticFeedback.mediumImpact();
          break;
          
        case SecurityAlertType.info:
          // Info pattern: light impact
          await HapticFeedback.lightImpact();
          break;
      }
      
      if (kDebugMode) {
        developer.log('$_tag: Security alert feedback triggered (${alertType.name})', 
                     name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Security alert feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// General action confirmation feedback
  /// Uses selection click for standard UI actions
  static Future<void> actionConfirmation() async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      await HapticFeedback.selectionClick();
      
      if (kDebugMode) {
        developer.log('$_tag: Action confirmation feedback triggered', name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Action confirmation feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// Error feedback for failed actions
  /// Uses distinct pattern to indicate failure
  static Future<void> errorFeedback() async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      // Error pattern: 2 light impacts with longer delay
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.lightImpact();
      
      if (kDebugMode) {
        developer.log('$_tag: Error feedback triggered', name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Error feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// Success feedback for completed actions
  /// Uses positive pattern to indicate success
  static Future<void> successFeedback() async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      // Success pattern: 3 light impacts with quick timing
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
      await HapticFeedback.lightImpact();
      
      if (kDebugMode) {
        developer.log('$_tag: Success feedback triggered', name: 'HapticFeedback');
      }
      
    } catch (e) {
      if (kDebugMode) {
        developer.log('$_tag: Success feedback failed: $e', name: 'HapticFeedback');
      }
    }
  }
  
  /// Navigation feedback for tab/page changes
  /// Uses subtle selection click
  static Future<void> navigationFeedback() async {
    if (!_isInitialized) await initialize();
    if (!_isHapticAvailable) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail for navigation feedback to avoid spam in logs
    }
  }
  
  /// Check if haptic feedback is available
  static bool get isAvailable => _isHapticAvailable;
  
  /// Check if haptic feedback is initialized
  static bool get isInitialized => _isInitialized;
}

/// Security alert types for contextual haptic feedback
enum SecurityAlertType {
  incident,   // Security incident
  emergency,  // Emergency situation
  warning,    // Security warning
  info,       // Informational alert
}

/// Extension methods for easy haptic feedback integration
extension HapticFeedbackExtension on Widget {
  /// Wrap widget with haptic feedback on tap
  Widget withHapticFeedback({
    VoidCallback? onTap,
    HapticFeedbackType type = HapticFeedbackType.selection,
  }) {
    return GestureDetector(
      onTap: () async {
        switch (type) {
          case HapticFeedbackType.selection:
            await HapticFeedbackService.actionConfirmation();
            break;
          case HapticFeedbackType.success:
            await HapticFeedbackService.successFeedback();
            break;
          case HapticFeedbackType.error:
            await HapticFeedbackService.errorFeedback();
            break;
          case HapticFeedbackType.emergency:
            await HapticFeedbackService.emergencyActionConfirmation();
            break;
        }
        onTap?.call();
      },
      child: this,
    );
  }
}

/// Haptic feedback types for extension method
enum HapticFeedbackType {
  selection,
  success,
  error,
  emergency,
}