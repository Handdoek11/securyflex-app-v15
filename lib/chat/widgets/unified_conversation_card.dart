import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// WhatsApp-quality conversation card with unread badges and role-based theming
/// Follows SecuryFlex unified design system patterns
class UnifiedConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showOnlineStatus;
  final bool isSelected;

  const UnifiedConversationCard({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.userRole,
    this.onTap,
    this.onLongPress,
    this.showOnlineStatus = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    
    return UnifiedCard.standard(
      isClickable: true,
      onTap: onTap,
      backgroundColor: isSelected 
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      margin: EdgeInsets.symmetric(
        horizontal: 0, // Remove horizontal margin for full width
        vertical: DesignTokens.spacingXS,
      ),
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Row(
            children: [
              // Avatar with online status
              _buildAvatar(context, colorScheme, otherParticipant),
              
              SizedBox(width: DesignTokens.spacingM),
              
              // Conversation details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and timestamp row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTitle(context, colorScheme),
                        ),
                        _buildTimestamp(context, colorScheme),
                      ],
                    ),
                    
                    SizedBox(height: DesignTokens.spacingXS),
                    
                    // Last message and unread badge row
                    Row(
                      children: [
                        Expanded(
                          child: _buildLastMessage(context, colorScheme),
                        ),
                        if (unreadCount > 0)
                          _buildUnreadBadge(context, colorScheme, unreadCount),
                      ],
                    ),
                    
                    // Typing indicator
                    if (conversation.hasTypingUsers)
                      _buildTypingIndicator(context, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, ColorScheme colorScheme, ParticipantDetails? otherParticipant) {
    return Stack(
      children: [
        // Main avatar
        CircleAvatar(
          radius: 28,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: conversation.conversationType == ConversationType.group
              ? Icon(
                  Icons.group,
                  color: colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeL,
                )
              : _buildUserAvatar(context, colorScheme, otherParticipant),
        ),
        
        // Online status indicator
        if (showOnlineStatus && 
            otherParticipant != null && 
            otherParticipant.isOnline &&
            conversation.conversationType == ConversationType.direct)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: DesignTokens.colorSuccess,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context, ColorScheme colorScheme, ParticipantDetails? participant) {
    if (participant?.avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          participant!.avatarUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(context, colorScheme, participant),
        ),
      );
    }
    
    return _buildInitialsAvatar(context, colorScheme, participant);
  }

  Widget _buildInitialsAvatar(BuildContext context, ColorScheme colorScheme, ParticipantDetails? participant) {
    final displayName = conversation.getDisplayTitle(currentUserId);
    final initials = displayName.isNotEmpty 
        ? displayName.split(' ').take(2).map((word) => word[0].toUpperCase()).join()
        : '?';
    
    return Text(
      initials,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: DesignTokens.fontWeightSemiBold,
      ),
    );
  }

  Widget _buildTitle(BuildContext context, ColorScheme colorScheme) {
    final title = conversation.getDisplayTitle(currentUserId);
    
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: conversation.getUnreadCount(currentUserId) > 0 
            ? DesignTokens.fontWeightBold 
            : DesignTokens.fontWeightSemiBold,
        color: colorScheme.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTimestamp(BuildContext context, ColorScheme colorScheme) {
    final timestamp = conversation.lastMessage?.timestamp ?? conversation.updatedAt;
    
    return Text(
      _formatTimestamp(timestamp),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: conversation.getUnreadCount(currentUserId) > 0 
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        fontWeight: conversation.getUnreadCount(currentUserId) > 0 
            ? DesignTokens.fontWeightSemiBold
            : DesignTokens.fontWeightRegular,
      ),
    );
  }

  Widget _buildLastMessage(BuildContext context, ColorScheme colorScheme) {
    if (conversation.lastMessage == null) {
      return Text(
        'Geen berichten',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    final lastMessage = conversation.lastMessage!;
    final isCurrentUserMessage = lastMessage.senderId == currentUserId;
    final displayText = lastMessage.getDisplayText();
    
    return Row(
      children: [
        // Delivery status for current user messages
        if (isCurrentUserMessage)
          _buildMessageStatus(context, colorScheme, lastMessage),
        
        // Message content
        Expanded(
          child: Text(
            isCurrentUserMessage ? 'Jij: $displayText' : displayText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: conversation.getUnreadCount(currentUserId) > 0 
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: conversation.getUnreadCount(currentUserId) > 0 
                  ? DesignTokens.fontWeightMedium
                  : DesignTokens.fontWeightRegular,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageStatus(BuildContext context, ColorScheme colorScheme, LastMessagePreview lastMessage) {
    Widget statusIcon;
    
    switch (lastMessage.deliveryStatus) {
      case MessageDeliveryStatus.sending:
        statusIcon = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        );
        break;
      case MessageDeliveryStatus.sent:
        statusIcon = Icon(
          Icons.check,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        );
        break;
      case MessageDeliveryStatus.delivered:
        statusIcon = Icon(
          Icons.done_all,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        );
        break;
      case MessageDeliveryStatus.read:
        statusIcon = Icon(
          Icons.done_all,
          size: 14,
          color: colorScheme.primary,
        );
        break;
      case MessageDeliveryStatus.failed:
        statusIcon = Icon(
          Icons.error_outline,
          size: 14,
          color: DesignTokens.colorError,
        );
        break;
    }
    
    return Container(
      margin: EdgeInsets.only(right: DesignTokens.spacingXS),
      child: statusIcon,
    );
  }

  Widget _buildUnreadBadge(BuildContext context, ColorScheme colorScheme, int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: count > 99 ? DesignTokens.spacingS : DesignTokens.spacingXS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: DesignTokens.fontSizeXS,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(top: DesignTokens.spacingXS),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: _buildTypingAnimation(colorScheme),
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Expanded(
            child: Text(
              conversation.getTypingIndicatorText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 600 + (index * 200)),
          curve: Curves.easeInOut,
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      final weekdays = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];
      return weekdays[timestamp.weekday - 1];
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'nu';
    }
  }
}
