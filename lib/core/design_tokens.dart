export '../unified_design_tokens.dart';

/// Re-export of unified design tokens for backward compatibility
/// 
/// This file maintains compatibility with existing imports while
/// centralizing all design tokens in the unified system.
/// 
/// Usage:
/// ```dart
/// import 'package:securyflex_app/core/design_tokens.dart';
/// 
/// // All DesignTokens.* references work as expected
/// color: DesignTokens.guardPrimary,
/// fontSize: DesignTokens.fontSizeBody,
/// ```
/// 
/// For new code, prefer importing directly:
/// ```dart
/// import 'package:securyflex_app/unified_design_tokens.dart';
/// ```