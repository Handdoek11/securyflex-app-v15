import 'package:flutter/material.dart';

enum UnifiedButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
}

/// Unified button widget
class UnifiedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final UnifiedButtonVariant variant;
  final bool isLoading;

  const UnifiedButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.variant = UnifiedButtonVariant.primary,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    Color backgroundColor;
    Color foregroundColor;
    
    switch (variant) {
      case UnifiedButtonVariant.primary:
        backgroundColor = colors.primary;
        foregroundColor = colors.onPrimary;
        break;
      case UnifiedButtonVariant.secondary:
        backgroundColor = colors.secondary;
        foregroundColor = colors.onSecondary;
        break;
      case UnifiedButtonVariant.tertiary:
        backgroundColor = Colors.transparent;
        foregroundColor = colors.primary;
        break;
      case UnifiedButtonVariant.danger:
        backgroundColor = colors.error;
        foregroundColor = colors.onError;
        break;
    }

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (variant == UnifiedButtonVariant.tertiary) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: content,
    );
  }
}