import 'package:flutter/material.dart';
import 'unified_design_tokens.dart';
import 'beveiliger_agenda/models/shift_data.dart';
import 'company_dashboard/models/job_posting_data.dart';

/// 🎨 **Unified Status Color System**
/// 
/// This class provides consistent status color mapping across the entire SecuryFlex app.
/// It maintains the visual richness of the Planning page while ensuring consistency
/// and scalability across all features.
/// 
/// **Design Philosophy:**
/// - Status-driven design enhances UX through visual hierarchy
/// - Consistent color mapping improves user recognition and workflow
/// - Centralized control enables easy maintenance and theming
/// - Role-based theming compatibility maintained
/// 
/// **Usage Examples:**
/// ```dart
/// // Get color for shift status
/// final color = StatusColorHelper.getShiftStatusColor(ShiftStatus.confirmed);
/// 
/// // Get color for job posting status  
/// final color = StatusColorHelper.getJobPostingStatusColor(JobPostingStatus.active);
/// 
/// // Get color for generic status string
/// final color = StatusColorHelper.getGenericStatusColor('pending');
/// ```
class StatusColorHelper {
  StatusColorHelper._(); // Private constructor - static class only

  /// **Shift Status Colors**
  /// Maps shift workflow states to appropriate visual indicators
  static Color getShiftStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.pending:
        return DesignTokens.statusPending;      // Orange - Waiting for acceptance
      case ShiftStatus.accepted:
        return DesignTokens.statusAccepted;     // Blue - Accepted by guard
      case ShiftStatus.confirmed:
        return DesignTokens.statusConfirmed;    // Green - Confirmed by company
      case ShiftStatus.inProgress:
        return DesignTokens.statusInProgress;   // Navy - Currently active
      case ShiftStatus.completed:
        return DesignTokens.statusCompleted;    // Light Green - Successfully finished
      case ShiftStatus.cancelled:
        return DesignTokens.statusCancelled;    // Red - Cancelled/Rejected
    }
  }

  /// **Job Posting Status Colors**
  /// Maps job posting lifecycle states to visual indicators
  static Color getJobPostingStatusColor(JobPostingStatus status) {
    switch (status) {
      case JobPostingStatus.draft:
        return DesignTokens.statusDraft;        // Gray - Draft/Concept
      case JobPostingStatus.active:
        return DesignTokens.statusConfirmed;    // Green - Active and accepting applications
      case JobPostingStatus.filled:
        return DesignTokens.statusAccepted;     // Blue - Position filled
      case JobPostingStatus.cancelled:
        return DesignTokens.statusCancelled;    // Red - Cancelled
      case JobPostingStatus.completed:
        return DesignTokens.statusCompleted;    // Light Green - Successfully completed
      case JobPostingStatus.expired:
        return DesignTokens.statusExpired;      // Light Orange - Expired
    }
  }

  /// **Generic Status Colors**
  /// Maps common status strings to colors for flexible usage
  static Color getGenericStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      // Pending states
      case 'pending':
      case 'wachtend':
      case 'in behandeling':
        return DesignTokens.statusPending;
      
      // Accepted states
      case 'accepted':
      case 'geaccepteerd':
      case 'approved':
      case 'goedgekeurd':
        return DesignTokens.statusAccepted;
      
      // Confirmed states
      case 'confirmed':
      case 'bevestigd':
      case 'active':
      case 'actief':
        return DesignTokens.statusConfirmed;
      
      // In progress states
      case 'inprogress':
      case 'in_progress':
      case 'bezig':
      case 'started':
      case 'gestart':
        return DesignTokens.statusInProgress;
      
      // Completed states
      case 'completed':
      case 'voltooid':
      case 'finished':
      case 'afgerond':
        return DesignTokens.statusCompleted;
      
      // Cancelled states
      case 'cancelled':
      case 'geannuleerd':
      case 'rejected':
      case 'afgewezen':
        return DesignTokens.statusCancelled;
      
      // Draft states
      case 'draft':
      case 'concept':
      case 'ontwerp':
        return DesignTokens.statusDraft;
      
      // Expired states
      case 'expired':
      case 'verlopen':
      case 'overdue':
      case 'achterstallig':
        return DesignTokens.statusExpired;
      
      // Default fallback
      default:
        return DesignTokens.colorGray500;
    }
  }

  /// **Priority Colors**
  /// Maps priority levels to visual urgency indicators
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase().trim()) {
      case 'low':
      case 'laag':
        return DesignTokens.priorityLow;
      case 'medium':
      case 'middel':
      case 'gemiddeld':
        return DesignTokens.priorityMedium;
      case 'high':
      case 'hoog':
        return DesignTokens.priorityHigh;
      case 'urgent':
      case 'spoed':
      case 'kritiek':
        return DesignTokens.priorityUrgent;
      default:
        return DesignTokens.priorityLow;
    }
  }

  /// **Availability Colors**
  /// Maps availability states to visual indicators (for guard profiles)
  static Color getAvailabilityColor(String availability) {
    switch (availability.toLowerCase().trim()) {
      case 'available':
      case 'beschikbaar':
      case 'vrij':
        return DesignTokens.statusConfirmed;    // Green - Available
      case 'busy':
      case 'bezet':
      case 'niet beschikbaar':
        return DesignTokens.statusPending;      // Orange - Busy
      case 'offline':
      case 'inactief':
        return DesignTokens.statusCancelled;    // Red - Offline
      default:
        return DesignTokens.colorGray500;       // Gray - Unknown
    }
  }

  /// **Status Text Helpers**
  /// Get Dutch status text for consistent UI labels
  static String getShiftStatusText(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.pending:
        return 'Wachtend';
      case ShiftStatus.accepted:
        return 'Geaccepteerd';
      case ShiftStatus.confirmed:
        return 'Bevestigd';
      case ShiftStatus.inProgress:
        return 'Bezig';
      case ShiftStatus.completed:
        return 'Voltooid';
      case ShiftStatus.cancelled:
        return 'Geannuleerd';
    }
  }

  /// **Status Icon Helpers**
  /// Get appropriate icons for status indicators
  static IconData getShiftStatusIcon(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.pending:
        return Icons.schedule;
      case ShiftStatus.accepted:
        return Icons.thumb_up;
      case ShiftStatus.confirmed:
        return Icons.check_circle;
      case ShiftStatus.inProgress:
        return Icons.play_circle;
      case ShiftStatus.completed:
        return Icons.check_circle_outline;
      case ShiftStatus.cancelled:
        return Icons.cancel;
    }
  }
}
