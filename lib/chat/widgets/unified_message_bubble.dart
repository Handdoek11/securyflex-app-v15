import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../models/message_model.dart';
import '../services/read_receipt_service.dart';

/// WhatsApp-quality message bubble with delivery status and role-based theming
/// Follows SecuryFlex unified design system patterns
class UnifiedMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isGroupChat;

  const UnifiedMessageBubble({
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
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!isCurrentUser && showAvatar && isGroupChat)
            _buildAvatar(context),
          
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name for group chats
                  if (!isCurrentUser && isGroupChat)
                    _buildSenderName(context, colorScheme),
                  
                  // Reply preview
                  if (message.replyTo != null)
                    _buildReplyPreview(context, colorScheme),
                  
                  // Main message bubble
                  _buildMessageBubble(context, colorScheme),
                  
                  // Timestamp and delivery status
                  if (showTimestamp)
                    _buildMessageFooter(context, colorScheme),
                ],
              ),
            ),
          ),
          
          // Spacing for current user messages
          if (isCurrentUser && showAvatar)
            SizedBox(width: DesignTokens.spacingS),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: DesignTokens.spacingS),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: DesignTokens.colorGray200,
        child: Text(
          message.senderName.isNotEmpty 
              ? message.senderName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.colorGray700,
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
        message.senderName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: UnifiedCard.standard(
        padding: EdgeInsets.all(DesignTokens.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.replyTo!.senderName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              message.replyTo!.content,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: _getBubbleColor(colorScheme),
          borderRadius: _getBubbleBorderRadius(),
        ),
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content
            _buildMessageContent(context, colorScheme),
            
            // Edited indicator
            if (message.isEdited)
              _buildEditedIndicator(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ColorScheme colorScheme) {
    switch (message.messageType) {
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
    return Text(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachment != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: CachedNetworkImage(
              imageUrl: message.attachment!.fileUrl,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 150,
                color: DesignTokens.colorGray200,
                child: Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 200,
                height: 150,
                color: DesignTokens.colorGray200,
                child: Icon(
                  Icons.error,
                  color: DesignTokens.colorError,
                ),
              ),
            ),
          ),
        if (message.content.isNotEmpty) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            message.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Icon(
            Icons.description,
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
                message.attachment?.fileName ?? 'Document',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
              if (message.attachment?.fileSize != null)
                Text(
                  _formatFileSize(message.attachment!.fileSize),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCurrentUser 
                        ? DesignTokens.colorWhite.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceContent(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          Icons.mic,
          color: isCurrentUser ? DesignTokens.colorWhite : colorScheme.primary,
          size: DesignTokens.iconSizeM,
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Text(
            'Spraakbericht',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isCurrentUser ? DesignTokens.colorWhite : colorScheme.onSurface,
            ),
          ),
        ),
        Icon(
          Icons.play_arrow,
          color: isCurrentUser ? DesignTokens.colorWhite : colorScheme.primary,
          size: DesignTokens.iconSizeM,
        ),
      ],
    );
  }

  Widget _buildSystemContent(BuildContext context, ColorScheme colorScheme) {
    return Text(
      message.content,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEditedIndicator(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.only(top: DesignTokens.spacingXS),
      child: Text(
        'bewerkt',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isCurrentUser 
              ? DesignTokens.colorWhite.withValues(alpha: 0.7)
              : colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(
        top: DesignTokens.spacingXS,
        left: isCurrentUser ? 0 : DesignTokens.spacingS,
        right: isCurrentUser ? DesignTokens.spacingS : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timestamp
          Text(
            _formatTimestamp(message.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.colorGray600,
              fontSize: DesignTokens.fontSizeXS,
            ),
          ),
          
          // Delivery status for current user messages
          if (isCurrentUser) ...[
            SizedBox(width: DesignTokens.spacingXS),
            _buildDeliveryStatus(context, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryStatus(BuildContext context, ColorScheme colorScheme) {
    final status = message.getOverallDeliveryStatus();

    // Use read receipt service for enhanced status display
    return GestureDetector(
      onTap: () => _showReadReceiptDetails(context),
      child: ReadReceiptService.instance.getReadReceiptIcon(
        status,
        color: status == MessageDeliveryStatus.read
            ? colorScheme.primary
            : DesignTokens.colorGray600,
      ),
    );
  }

  /// Show detailed read receipt information
  void _showReadReceiptDetails(BuildContext context) {
    final detailedInfo = ReadReceiptService.instance.getDetailedReadReceiptInfo(message);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bezorgingsinformatie'),
        content: Text(detailedInfo),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getBubbleColor(ColorScheme colorScheme) {
    if (message.messageType == MessageType.system) {
      return colorScheme.surfaceContainerHighest;
    }
    
    return isCurrentUser 
        ? colorScheme.primary
        : colorScheme.surface;
  }

  BorderRadius _getBubbleBorderRadius() {
    const radius = DesignTokens.radiusM;
    
    if (message.messageType == MessageType.system) {
      return BorderRadius.circular(radius);
    }
    
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.circular(isCurrentUser ? radius : DesignTokens.radiusS),
      bottomRight: Radius.circular(isCurrentUser ? DesignTokens.radiusS : radius),
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
