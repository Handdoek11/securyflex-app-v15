import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';

/// Messages Content Component
/// 
/// Displays messaging interface for company communications,
/// team messaging, and notification management.
class MessagesContent extends StatelessWidget {
  const MessagesContent({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Messages header
        _buildMessagesHeader(colorScheme),
        SizedBox(height: DesignTokens.spacingL),
        
        // Messages content
        Container(
          height: 600,
          child: UnifiedCard.standard(
            userRole: UserRole.company,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingXL),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: DesignTokens.spacingL),
                    Text(
                      'Berichten Centrum',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSubtitle,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'Communiceer met je team, beheer notificaties\nen ontvang belangrijke updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXL),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to full messages view
                      },
                      icon: Icon(Icons.open_in_new),
                      label: Text('Open Berichten App'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berichten',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Team communicatie en notificaties',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                // Mark all as read
              },
              icon: Icon(Icons.mark_email_read),
              tooltip: 'Alle als gelezen markeren',
            ),
            IconButton(
              onPressed: () {
                // Settings
              },
              icon: Icon(Icons.settings),
              tooltip: 'Berichten instellingen',
            ),
          ],
        ),
      ],
    );
  }
}