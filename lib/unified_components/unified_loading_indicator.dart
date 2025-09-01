import 'package:flutter/material.dart';

/// Unified loading indicator widget
class UnifiedLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const UnifiedLoadingIndicator({
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 48,
      height: size ?? 48,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}