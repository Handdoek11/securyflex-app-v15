import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';

/// Dialog variant enumeration
enum UnifiedDialogVariant {
  /// Standard dialog with default styling
  standard,
  /// Alert dialog for important messages
  alert,
  /// Confirmation dialog with action buttons
  confirmation,
  /// Full-screen dialog for complex forms
  fullscreen,
  /// Bottom sheet dialog for mobile-first interactions
  bottomSheet,
}

/// Unified Dialog Component for SecuryFlex
/// 
/// A comprehensive dialog system that provides consistent styling
/// and behavior across all modules while supporting different variants
/// and role-based theming.
/// 
/// Features:
/// - Consistent styling using DesignTokens
/// - Multiple dialog variants (standard, alert, confirmation, etc.)
/// - Role-based color theming
/// - Mobile-first design with responsive behavior
/// - Accessibility compliance
/// - Dutch localization support
class UnifiedDialog extends StatelessWidget {
  /// Dialog variant determines the styling and behavior
  final UnifiedDialogVariant variant;
  
  /// Dialog title
  final String? title;
  
  /// Dialog content widget
  final Widget? content;
  
  /// Action buttons for the dialog
  final List<Widget>? actions;
  
  /// Custom width (not applicable for fullscreen/bottomSheet)
  final double? width;
  
  /// Custom height (not applicable for fullscreen)
  final double? height;
  
  /// User role for theming
  final UserRole? userRole;
  
  /// Whether the dialog is dismissible
  final bool isDismissible;
  
  /// Custom padding for content
  final EdgeInsetsGeometry? contentPadding;
  
  /// Custom background color
  final Color? backgroundColor;
  
  /// Icon to display in the dialog
  final IconData? icon;
  
  /// Icon color
  final Color? iconColor;

  const UnifiedDialog({
    super.key,
    this.variant = UnifiedDialogVariant.standard,
    this.title,
    this.content,
    this.actions,
    this.width,
    this.height,
    this.userRole,
    this.isDismissible = true,
    this.contentPadding,
    this.backgroundColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case UnifiedDialogVariant.standard:
      case UnifiedDialogVariant.alert:
      case UnifiedDialogVariant.confirmation:
        return _buildStandardDialog(context);
      case UnifiedDialogVariant.fullscreen:
        return _buildFullscreenDialog(context);
      case UnifiedDialogVariant.bottomSheet:
        return _buildBottomSheetDialog(context);
    }
  }

  Widget _buildStandardDialog(BuildContext context) {
    final colorScheme = _getColorScheme(context);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusModal),
      ),
      child: Container(
        width: width,
        height: height,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || icon != null) _buildDialogHeader(context, theme, colorScheme),
            if (content != null) _buildDialogContent(context),
            if (actions != null && actions!.isNotEmpty) _buildDialogActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenDialog(BuildContext context) {
    final colorScheme = _getColorScheme(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: content,
      bottomNavigationBar: actions != null && actions!.isNotEmpty
          ? Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: _buildActionButtons(context),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomSheetDialog(BuildContext context) {
    final colorScheme = _getColorScheme(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusModal),
          topRight: Radius.circular(DesignTokens.radiusModal),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar for bottom sheet
          Container(
            margin: EdgeInsets.only(top: DesignTokens.spacingS),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null || icon != null) _buildDialogHeader(context, theme, colorScheme),
          if (content != null) _buildDialogContent(context),
          if (actions != null && actions!.isNotEmpty) _buildDialogActions(context),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: contentPadding ?? EdgeInsets.fromLTRB(
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        DesignTokens.spacingL,
        DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
              ),
              child: Icon(
                icon,
                color: iconColor ?? colorScheme.primary,
                size: DesignTokens.iconSizeL,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
          ],
          Expanded(
            child: Text(
              title ?? '',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogContent(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        padding: contentPadding ?? EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingL,
          vertical: DesignTokens.spacingS,
        ),
        child: content,
      ),
    );
  }

  Widget _buildDialogActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Row(
        children: _buildActionButtons(context),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    if (actions == null || actions!.isEmpty) return [];
    
    List<Widget> buttons = [];
    for (int i = 0; i < actions!.length; i++) {
      if (i > 0) buttons.add(SizedBox(width: DesignTokens.spacingS));
      buttons.add(Expanded(child: actions![i]));
    }
    return buttons;
  }

  /// Get the appropriate color scheme based on user role
  ColorScheme _getColorScheme(BuildContext context) {
    if (userRole != null) {
      return SecuryFlexTheme.getColorScheme(userRole!);
    }
    return Theme.of(context).colorScheme;
  }

  /// Static method to show a standard dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    UnifiedDialogVariant variant = UnifiedDialogVariant.standard,
    UserRole? userRole,
    bool isDismissible = true,
    double? width,
    double? height,
  }) {
    final dialog = UnifiedDialog(
      variant: variant,
      title: title,
      content: content,
      actions: actions,
      userRole: userRole,
      isDismissible: isDismissible,
      width: width,
      height: height,
    );

    switch (variant) {
      case UnifiedDialogVariant.bottomSheet:
        return showModalBottomSheet<T>(
          context: context,
          builder: (context) => dialog,
          isDismissible: isDismissible,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusModal),
              topRight: Radius.circular(DesignTokens.radiusModal),
            ),
          ),
        );
      case UnifiedDialogVariant.fullscreen:
        return showDialog<T>(
          context: context,
          builder: (context) => dialog,
          barrierDismissible: isDismissible,
          useSafeArea: false,
        );
      default:
        return showDialog<T>(
          context: context,
          builder: (context) => dialog,
          barrierDismissible: isDismissible,
        );
    }
  }

  /// Static method to show an alert dialog
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    UserRole? userRole,
    VoidCallback? onConfirm,
  }) {
    return show(
      context: context,
      title: title,
      content: Text(message),
      variant: UnifiedDialogVariant.alert,
      userRole: userRole,
      actions: [
        UnifiedButton.primary(
          text: confirmText,
          onPressed: () {
            context.pop();
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  /// Static method to show a confirmation dialog
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Bevestigen',
    String cancelText = 'Annuleren',
    UserRole? userRole,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: Text(message),
      variant: UnifiedDialogVariant.confirmation,
      userRole: userRole,
      actions: [
        UnifiedButton.secondary(
          text: cancelText,
          onPressed: () {
            context.pop(false);
            onCancel?.call();
          },
        ),
        UnifiedButton.primary(
          text: confirmText,
          onPressed: () {
            context.pop(true);
            onConfirm?.call();
          },
        ),
      ],
    );
  }

  /// Static method to show a loading dialog
  static void showLoading({
    required BuildContext context,
    String? message,
    UserRole? userRole,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnifiedDialog(
        variant: UnifiedDialogVariant.standard,
        userRole: userRole,
        content: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              if (message != null) ...[
                SizedBox(height: DesignTokens.spacingM),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Static method to hide loading dialog
  static void hideLoading(BuildContext context) {
    context.pop();
  }
}