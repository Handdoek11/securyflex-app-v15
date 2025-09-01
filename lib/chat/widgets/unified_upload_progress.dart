import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';

/// WhatsApp-quality upload progress indicator with Dutch labels
/// Follows SecuryFlex unified design system patterns
class UnifiedUploadProgress extends StatefulWidget {
  final String fileName;
  final double progress;
  final UserRole userRole;
  final VoidCallback? onCancel;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;

  const UnifiedUploadProgress({
    super.key,
    required this.fileName,
    required this.progress,
    required this.userRole,
    this.onCancel,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<UnifiedUploadProgress> createState() => _UnifiedUploadProgressState();
}

class _UnifiedUploadProgressState extends State<UnifiedUploadProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: UnifiedCard.standard(
          backgroundColor: widget.hasError 
              ? DesignTokens.colorError.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // File icon
                    _buildFileIcon(colorScheme),
                    
                    SizedBox(width: DesignTokens.spacingM),
                    
                    // File info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: DesignTokens.fontWeightSemiBold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: DesignTokens.spacingXS),
                          _buildStatusText(context, colorScheme),
                        ],
                      ),
                    ),
                    
                    // Cancel button
                    if (!widget.isCompleted && !widget.hasError && widget.onCancel != null)
                      _buildCancelButton(colorScheme),
                  ],
                ),
                
                // Progress bar
                if (!widget.isCompleted && !widget.hasError) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildProgressBar(colorScheme),
                ],
                
                // Error message
                if (widget.hasError && widget.errorMessage != null) ...[
                  SizedBox(height: DesignTokens.spacingS),
                  _buildErrorMessage(context, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    if (widget.hasError) {
      iconData = Icons.error_outline;
      iconColor = DesignTokens.colorError;
    } else if (widget.isCompleted) {
      iconData = Icons.check_circle;
      iconColor = DesignTokens.colorSuccess;
    } else {
      iconData = Icons.upload_file;
      iconColor = colorScheme.primary;
    }

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: DesignTokens.iconSizeL,
      ),
    );
  }

  Widget _buildStatusText(BuildContext context, ColorScheme colorScheme) {
    String statusText;
    Color textColor;

    if (widget.hasError) {
      statusText = 'Upload mislukt';
      textColor = DesignTokens.colorError;
    } else if (widget.isCompleted) {
      statusText = 'Upload voltooid';
      textColor = DesignTokens.colorSuccess;
    } else {
      final percentage = (widget.progress * 100).round();
      statusText = 'Uploaden... $percentage%';
      textColor = colorScheme.primary;
    }

    return Text(
      statusText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: textColor,
        fontWeight: DesignTokens.fontWeightMedium,
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 6,
          ),
        ),
        
        SizedBox(height: DesignTokens.spacingXS),
        
        // Progress text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getProgressText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(widget.progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
      ),
      child: UnifiedButton.icon(
        icon: Icons.close,
        onPressed: widget.onCancel ?? () {},
        color: colorScheme.onSurfaceVariant,
        size: UnifiedButtonSize.small,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: DesignTokens.colorError.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressText() {
    if (widget.progress < 0.1) {
      return 'Voorbereiden...';
    } else if (widget.progress < 0.5) {
      return 'Uploaden...';
    } else if (widget.progress < 0.9) {
      return 'Bijna klaar...';
    } else {
      return 'Voltooien...';
    }
  }
}

/// Upload progress overlay for full-screen display
class UploadProgressOverlay extends StatelessWidget {
  final List<UploadProgressItem> uploads;
  final UserRole userRole;

  const UploadProgressOverlay({
    super.key,
    required this.uploads,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (uploads.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: colorScheme.surface.withValues(alpha: 0.95),
        child: Column(
          children: uploads.map((upload) {
            return UnifiedUploadProgress(
              fileName: upload.fileName,
              progress: upload.progress,
              userRole: userRole,
              onCancel: upload.onCancel,
              isCompleted: upload.isCompleted,
              hasError: upload.hasError,
              errorMessage: upload.errorMessage,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Upload progress item data
class UploadProgressItem {
  final String fileName;
  final double progress;
  final VoidCallback? onCancel;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;

  const UploadProgressItem({
    required this.fileName,
    required this.progress,
    this.onCancel,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });

  UploadProgressItem copyWith({
    String? fileName,
    double? progress,
    VoidCallback? onCancel,
    bool? isCompleted,
    bool? hasError,
    String? errorMessage,
  }) {
    return UploadProgressItem(
      fileName: fileName ?? this.fileName,
      progress: progress ?? this.progress,
      onCancel: onCancel ?? this.onCancel,
      isCompleted: isCompleted ?? this.isCompleted,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
