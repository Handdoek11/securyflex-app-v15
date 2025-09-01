import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

/// Guard availability status enum
enum GuardStatus {
  beschikbaar,
  bezet,
  nietBeschikbaar,
  offline,
  actief,
  geschorst,
}

extension GuardStatusExtension on GuardStatus {
  /// Get the display name in Dutch
  String get displayName {
    switch (this) {
      case GuardStatus.beschikbaar:
        return 'Beschikbaar';
      case GuardStatus.bezet:
        return 'Bezet';
      case GuardStatus.nietBeschikbaar:
        return 'Niet Beschikbaar';
      case GuardStatus.offline:
        return 'Offline';
      case GuardStatus.actief:
        return 'Actief';
      case GuardStatus.geschorst:
        return 'Geschorst';
    }
  }

  /// Get the icon for this status
  IconData get icon {
    switch (this) {
      case GuardStatus.beschikbaar:
        return Icons.check_circle;
      case GuardStatus.bezet:
        return Icons.work;
      case GuardStatus.nietBeschikbaar:
        return Icons.do_not_disturb;
      case GuardStatus.offline:
        return Icons.offline_bolt;
      case GuardStatus.actief:
        return Icons.verified;
      case GuardStatus.geschorst:
        return Icons.block;
    }
  }

  /// Get the color for this status
  Color get color {
    switch (this) {
      case GuardStatus.beschikbaar:
        return DesignTokens.statusConfirmed;
      case GuardStatus.bezet:
        return DesignTokens.statusInProgress;
      case GuardStatus.nietBeschikbaar:
        return DesignTokens.statusCancelled;
      case GuardStatus.offline:
        return DesignTokens.colorGray500;
      case GuardStatus.actief:
        return DesignTokens.statusConfirmed;
      case GuardStatus.geschorst:
        return DesignTokens.colorError;
    }
  }
}