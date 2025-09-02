import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_shadows.dart';
import '../models/message_model.dart';
import '../services/read_receipt_service.dart';

/// Modern message bubble with enhanced animations and professional styling
/// Features:
/// - Spring-based animations for smooth appearance
/// - Role-based theming with Dutch business standards
/// - Enhanced visual hierarchy with proper shadows
/// - Micro-interactions for delivery status
/// - Accessibility-compliant design
/// 
/// Follows SecuryFlex unified design system patterns
class EnhancedMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isGroupChat;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;
  final bool showTypingIndicator;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.userRole,
    this.onTap,
    this.onLongPress,
    this.onReply,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.isGroupChat = false,
    this.isSelected = false,
    this.onSelectionToggle,
    this.showTypingIndicator = false,
  });

  @override
  State<EnhancedMessageBubble> createState() => _EnhancedMessageBubbleState();
}

class _EnhancedMessageBubbleState extends State<EnhancedMessageBubble>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _statusController;
  late AnimationController _appearanceController;
  late AnimationController _selectionController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _statusAnimation;
  late Animation<double> _appearanceAnimation;
  late Animation<double> _selectionAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;
  late MessageDeliveryStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.message.getOverallDeliveryStatus();
    
    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: DesignTokens.durationFast,
      vsync: this,
    );
    
    _statusController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _selectionController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    // Setup animations with spring physics
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _statusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: Curves.elasticOut,
    ));
    
    _appearanceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOutBack,
    ));
    
    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.bounceOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: widget.isCurrentUser ? const Offset(0.3, 0) : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOutCubic,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));
    
    // Start entrance animations
    _startEntranceAnimation();
  }
  
  void _startEntranceAnimation() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      _appearanceController.forward();
      _statusController.forward();
    }
  }
  
  @override
  void didUpdateWidget(EnhancedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate status changes
    final newStatus = widget.message.getOverallDeliveryStatus();
    if (newStatus != _currentStatus) {
      _currentStatus = newStatus;
      _statusController.reset();
      _statusController.forward();
    }
    
    // Animate selection changes
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectionController.forward();
        HapticFeedback.lightImpact();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _statusController.dispose();
    _appearanceController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _appearanceAnimation,
        _selectionAnimation,
      ]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _appearanceAnimation,
            child: ScaleTransition(
              scale: _appearanceAnimation,
              child: AnimatedContainer(
                duration: DesignTokens.durationMedium,
                margin: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingXS,
                ),
                transform: widget.isSelected 
                    ? Matrix4.diagonal3Values(1.02, 1.02, 1.0)
                    : Matrix4.identity(),
                child: Row(
                  mainAxisAlignment: widget.isCurrentUser 
                      ? MainAxisAlignment.end 
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar for other users
                    if (!widget.isCurrentUser && widget.showAvatar && widget.isGroupChat)
                      _buildEnhancedAvatar(context, colorScheme),
                    
                    // Message bubble
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: widget.isCurrentUser 
                              ? CrossAxisAlignment.end 
                              : CrossAxisAlignment.start,
                          children: [
                            // Sender name for group chats
                            if (!widget.isCurrentUser && widget.isGroupChat)
                              _buildSenderName(context, colorScheme),
                            
                            // Reply preview
                            if (widget.message.replyTo != null)
                              _buildEnhancedReplyPreview(context, colorScheme),
                            
                            // Main message bubble
                            _buildEnhancedMessageBubble(context, colorScheme),
                            
                            // Timestamp and delivery status
                            if (widget.showTimestamp)
                              _buildEnhancedMessageFooter(context, colorScheme),
                          ],
                        ),
                      ),
                    ),
                    
                    // Spacing for current user messages
                    if (widget.isCurrentUser && widget.showAvatar)
                      SizedBox(width: DesignTokens.spacingS),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedAvatar(BuildContext context, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: DesignTokens.durationMedium,
      margin: EdgeInsets.only(right: DesignTokens.spacingS),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.8),
              colorScheme.primary,
            ],
          ),
          boxShadow: UnifiedShadows.lightElevation,
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.transparent,
          child: Text(
            widget.message.senderName.isNotEmpty 
                ? widget.message.senderName[0].toUpperCase()
                : '?',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: DesignTokens.colorWhite,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderName(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(
        bottom: DesignTokens.spacingXS,
        left: DesignTokens.spacingS,
      ),
      child: Text(
        widget.message.senderName,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
    );
  }

  Widget _buildEnhancedReplyPreview(BuildContext context, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: DesignTokens.durationMedium,
      margin: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: widget.isCurrentUser 
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border(
            left: BorderSide(
              color: colorScheme.primary,
              width: 3.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.1),
              offset: const Offset(0, 1),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message.replyTo!.senderName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXXS),
            Text(
              widget.message.replyTo!.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMessageBubble(BuildContext context, ColorScheme colorScheme) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _scaleController.forward();
          HapticFeedback.lightImpact();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                decoration: BoxDecoration(
                  color: _getEnhancedBubbleColor(colorScheme),
                  borderRadius: _getEnhancedBubbleBorderRadius(),
                  boxShadow: _getBubbleShadow(colorScheme),
                  border: widget.isSelected ? Border.all(
                    color: colorScheme.primary,
                    width: 2.0,
                  ) : null,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    _buildMessageContent(context, colorScheme),
                    
                    // Edited indicator
                    if (widget.message.isEdited)
                      _buildEditedIndicator(context, colorScheme),
                    
                    // Selection indicator
                    if (widget.isSelected)
                      _buildSelectionIndicator(context, colorScheme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ColorScheme colorScheme) {
    switch (widget.message.messageType) {
      case MessageType.text:
        return _buildTextContent(context, colorScheme);
      case MessageType.image:
        return _buildImageContent(context, colorScheme);
      case MessageType.file:
        return _buildFileContent(context, colorScheme);
      case MessageType.voice:
        return _buildVoiceContent(context, colorScheme);
      case MessageType.system:
        return _buildSystemContent(context, colorScheme);
    }
  }

  Widget _buildTextContent(BuildContext context, ColorScheme colorScheme) {
    return SelectableText(
      widget.message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: widget.isCurrentUser 
            ? DesignTokens.colorWhite 
            : colorScheme.onSurface,
        height: DesignTokens.lineHeightRelaxed,
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.attachment != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Hero(
              tag: 'message_image_${widget.message.messageId}',
              child: CachedNetworkImage(
                imageUrl: widget.message.attachment!.fileUrl,
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 220,
                  height: 160,
                  decoration: BoxDecoration(
                    color: DesignTokens.colorGray200,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 220,
                  height: 160,
                  decoration: BoxDecoration(
                    color: DesignTokens.colorGray200,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: DesignTokens.colorError,
                        size: DesignTokens.iconSizeL,
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        'Afbeelding niet gevonden',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DesignTokens.colorError,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (widget.message.content.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            widget.message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: widget.isCurrentUser 
            ? DesignTokens.colorWhite.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Icon(
              Icons.description_outlined,
              color: colorScheme.primary,
              size: DesignTokens.iconSizeM,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.message.attachment?.fileName ?? 'Document',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                if (widget.message.attachment?.fileSize != null) ...[
                  SizedBox(height: DesignTokens.spacingXXS),
                  Text(
                    _formatFileSize(widget.message.attachment!.fileSize),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.isCurrentUser 
                          ? DesignTokens.colorWhite.withValues(alpha: 0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.download_outlined,
            color: widget.isCurrentUser 
                ? DesignTokens.colorWhite.withValues(alpha: 0.8)
                : colorScheme.primary,
            size: DesignTokens.iconSizeM,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingXS),
            decoration: BoxDecoration(
              color: widget.isCurrentUser 
                  ? DesignTokens.colorWhite.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic,
              color: widget.isCurrentUser ? DesignTokens.colorWhite : colorScheme.primary,
              size: DesignTokens.iconSizeM,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spraakbericht',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: widget.isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXXS),
                // Voice waveform placeholder
                Row(
                  children: List.generate(12, (i) => Container(
                    width: 3,
                    height: (i % 4 + 1) * 4.0,
                    margin: EdgeInsets.only(right: DesignTokens.spacingXXS),
                    decoration: BoxDecoration(
                      color: widget.isCurrentUser 
                          ? DesignTokens.colorWhite.withValues(alpha: 0.6)
                          : colorScheme.primary.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingXS),
            decoration: BoxDecoration(
              color: widget.isCurrentUser 
                  ? DesignTokens.colorWhite.withValues(alpha: 0.2)
                  : colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow,
              color: widget.isCurrentUser ? DesignTokens.colorWhite : colorScheme.primary,
              size: DesignTokens.iconSizeM,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: DesignTokens.iconSizeS,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            widget.message.content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditedIndicator(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(top: DesignTokens.spacingXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_outlined,
            size: DesignTokens.iconSizeXS,
            color: widget.isCurrentUser 
                ? DesignTokens.colorWhite.withValues(alpha: 0.6)
                : colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: DesignTokens.spacingXXS),
          Text(
            'bewerkt',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: widget.isCurrentUser 
                  ? DesignTokens.colorWhite.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
              fontSize: DesignTokens.fontSizeXS,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionIndicator(BuildContext context, ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _selectionAnimation,
      child: Container(
        margin: EdgeInsets.only(top: DesignTokens.spacingXS),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: DesignTokens.iconSizeS,
              color: colorScheme.primary,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              'Geselecteerd',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ],
        ),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _selectionAnimation.value,
          child: Opacity(
            opacity: _selectionAnimation.value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMessageFooter(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(
        top: DesignTokens.spacingXS,
        left: widget.isCurrentUser ? 0 : DesignTokens.spacingS,
        right: widget.isCurrentUser ? DesignTokens.spacingS : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timestamp
          Text(
            _formatTimestamp(widget.message.timestamp),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: widget.isCurrentUser 
                  ? DesignTokens.colorWhite.withValues(alpha: 0.7)
                  : DesignTokens.colorGray600,
              fontSize: DesignTokens.fontSizeXS,
            ),
          ),
          
          // Delivery status for current user messages
          if (widget.isCurrentUser) ...[
            SizedBox(width: DesignTokens.spacingXS),
            _buildEnhancedDeliveryStatus(context, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildEnhancedDeliveryStatus(BuildContext context, ColorScheme colorScheme) {
    final status = widget.message.getOverallDeliveryStatus();

    return AnimatedBuilder(
      animation: _statusAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _statusAnimation.value,
          child: GestureDetector(
            onTap: () => _showReadReceiptDetails(context),
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacingXXS),
              decoration: BoxDecoration(
                color: status == MessageDeliveryStatus.read
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: _buildStatusIcon(status, colorScheme),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatusIcon(MessageDeliveryStatus status, ColorScheme colorScheme) {
    final baseColor = widget.isCurrentUser 
        ? DesignTokens.colorWhite.withValues(alpha: 0.8)
        : DesignTokens.colorGray600;
    
    final activeColor = status == MessageDeliveryStatus.read
        ? colorScheme.primary
        : baseColor;
        
    switch (status) {
      case MessageDeliveryStatus.sending:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: activeColor,
          ),
        );
      case MessageDeliveryStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: activeColor,
        );
      case MessageDeliveryStatus.delivered:
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: activeColor,
            ),
            Positioned(
              left: 6,
              child: Icon(
                Icons.check,
                size: 16,
                color: activeColor,
              ),
            ),
          ],
        );
      case MessageDeliveryStatus.read:
        return Stack(
          children: [
            Icon(
              Icons.check,
              size: 16,
              color: activeColor,
            ),
            Positioned(
              left: 6,
              child: Icon(
                Icons.check,
                size: 16,
                color: activeColor,
              ),
            ),
          ],
        );
      case MessageDeliveryStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: DesignTokens.colorError,
        );
    }
  }

  Color _getEnhancedBubbleColor(ColorScheme colorScheme) {
    if (widget.message.messageType == MessageType.system) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    }
    
    if (widget.isCurrentUser) {
      return _isHovered || _isPressed 
          ? colorScheme.primary.withValues(alpha: 0.9)
          : colorScheme.primary;
    } else {
      return _isHovered || _isPressed
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.8)
          : colorScheme.surface;
    }
  }

  BorderRadius _getEnhancedBubbleBorderRadius() {
    const radius = DesignTokens.radiusL;
    const tailRadius = DesignTokens.radiusXS;
    
    if (widget.message.messageType == MessageType.system) {
      return BorderRadius.circular(radius);
    }
    
    return BorderRadius.only(
      topLeft: const Radius.circular(radius),
      topRight: const Radius.circular(radius),
      bottomLeft: Radius.circular(widget.isCurrentUser ? radius : tailRadius),
      bottomRight: Radius.circular(widget.isCurrentUser ? tailRadius : radius),
    );
  }
  
  List<BoxShadow> _getBubbleShadow(ColorScheme colorScheme) {
    if (widget.message.messageType == MessageType.system) {
      return UnifiedShadows.lightElevation;
    }
    
    // Use elevation animation for dynamic shadow
    final elevationValue = _elevationAnimation.value;
    final shadowOpacity = (elevationValue / 8.0).clamp(0.1, 0.3);
    
    if (_isPressed) {
      return [BoxShadow(
        color: DesignTokens.colorBlack.withValues(alpha: shadowOpacity * 0.5),
        offset: const Offset(0, 1),
        blurRadius: elevationValue * 0.5,
      )];
    }
    
    if (_isHovered) {
      return [BoxShadow(
        color: DesignTokens.colorBlack.withValues(alpha: shadowOpacity * 1.5),
        offset: Offset(0, elevationValue * 0.3),
        blurRadius: elevationValue * 1.5,
      )];
    }
    
    return widget.isCurrentUser 
        ? [
            BoxShadow(
              color: DesignTokens.colorBlack.withValues(alpha: shadowOpacity),
              offset: Offset(0, elevationValue * 0.2),
              blurRadius: elevationValue,
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.15),
              offset: const Offset(0, 2),
              blurRadius: 8.0,
            ),
          ]
        : UnifiedShadows.mediumElevation;
  }

  /// Show detailed read receipt information
  void _showReadReceiptDetails(BuildContext context) {
    final detailedInfo = ReadReceiptService.instance.getDetailedReadReceiptInfo(widget.message);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bezorgingsinformatie'),
        content: Text(detailedInfo),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'nu';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Typing indicator widget for enhanced chat experience
class TypingIndicator extends StatefulWidget {
  final String userName;
  final UserRole userRole;

  const TypingIndicator({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _dotControllers = List.generate(3, (index) => AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    ));

    _dotAnimations = _dotControllers.asMap().entries.map((entry) {
      final controller = entry.value;
      
      return Tween<double>(
        begin: 0.4,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      for (int i = 0; i < _dotControllers.length; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _dotControllers[i].forward().then((_) {
            if (mounted) _dotControllers[i].reverse();
          });
        }
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (final controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              boxShadow: UnifiedShadows.lightElevation,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} typt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(width: DesignTokens.spacingS),
                Row(
                  children: _dotAnimations.asMap().entries.map((entry) {
                    final animation = entry.value;
                    
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: animation.value),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}