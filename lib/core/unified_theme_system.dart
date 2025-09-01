export '../unified_theme_system.dart';

/// Re-export of unified theme system for backward compatibility
/// 
/// This file maintains compatibility with existing imports while
/// centralizing the theme system implementation.
/// 
/// Usage:
/// ```dart
/// import 'package:securyflex_app/core/unified_theme_system.dart';
/// 
/// // Get theme for specific role
/// final theme = SecuryFlexTheme.getTheme(UserRole.guard);
/// ```
/// 
/// For new code, prefer importing directly:
/// ```dart
/// import 'package:securyflex_app/unified_theme_system.dart';
/// ```