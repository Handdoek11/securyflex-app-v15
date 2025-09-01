import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_header.dart';
import '../models/message_model.dart';
import 'enhanced_chat_input.dart';

/// Interactive demo screen showcasing enhanced chat input features
/// Demonstrates all animations, interactions, and accessibility features
class ChatInputDemo extends StatefulWidget {
  const ChatInputDemo({super.key});

  @override
  State<ChatInputDemo> createState() => _ChatInputDemoState();
}

class _ChatInputDemoState extends State<ChatInputDemo> with TickerProviderStateMixin {
  UserRole _currentRole = UserRole.guard;
  bool _isEnabled = true;
  bool _showReply = false;
  bool _enableHaptic = true;
  bool _showCharacterCounter = true;
  bool _showBackdrop = true;
  final int _maxLength = 4000;
  
  final List<DemoMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  
  MessageReply? _replyTo;
  
  @override
  void initState() {
    super.initState();
    _addWelcomeMessages();
  }
  
  void _addWelcomeMessages() {
    _messages.addAll([
      DemoMessage(
        text: 'Welkom bij de SecuryFlex Enhanced Chat Input Demo! 🎉',
        isSystem: true,
      ),
      DemoMessage(
        text: 'Probeer verschillende functies uit:',
        isSystem: true,
      ),
      DemoMessage(
        text: '• Typ een bericht en zie de animaties',
        isSystem: true,
      ),
      DemoMessage(
        text: '• Druk op de bijlage knop voor het floating menu',
        isSystem: true,
      ),
      DemoMessage(
        text: '• Wissel tussen user roles voor verschillende kleuren',
        isSystem: true,
      ),
      DemoMessage(
        text: '• Test de focus glow en haptic feedback',
        isSystem: true,
      ),
    ]);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onSendMessage(String message) {
    setState(() {
      _messages.add(DemoMessage(
        text: message,
        isSystem: false,
        timestamp: DateTime.now(),
      ));
      
      // Clear reply if set
      _replyTo = null;
    });
    
    _scrollToBottom();
    
    // Add simulated response after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _messages.add(DemoMessage(
            text: _getSimulatedResponse(message),
            isSystem: false,
            isResponse: true,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });
  }
  
  void _onSendFile(String filePath, String fileName, MessageType type) {
    setState(() {
      _messages.add(DemoMessage(
        text: _getFileMessage(fileName, type),
        isSystem: false,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }
  
  String _getFileMessage(String fileName, MessageType type) {
    switch (type) {
      case MessageType.image:
        return '📷 Afbeelding: $fileName';
      case MessageType.file:
        return '📄 Document: $fileName';
      default:
        return '📎 Bijlage: $fileName';
    }
  }
  
  String _getSimulatedResponse(String message) {
    final responses = [
      'Bedankt voor je bericht! De animaties werken perfect. ✨',
      'Geweldig! De enhanced input voelt erg responsief aan. 🚀',
      'Mooi! De haptic feedback geeft een premium gevoel. 👌',
      'Fantastisch! De focus glow en transities zijn heel smooth. 💫',
      'Perfect! De role-based theming past goed bij SecuryFlex. 🎨',
    ];
    return responses[message.hashCode.abs() % responses.length];
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _setReply(DemoMessage message) {
    setState(() {
      _replyTo = MessageReply(
        messageId: message.timestamp.millisecondsSinceEpoch.toString(),
        senderId: 'demo_user',
        senderName: message.isResponse ? 'Demo Bot' : 'You',
        content: message.text,
        messageType: MessageType.text,
      );
    });
  }
  
  void _clearReply() {
    setState(() {
      _replyTo = null;
    });
  }
  
  void _showFeatureExplanation(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Role (voor theming)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Wrap(
            spacing: DesignTokens.spacingS,
            children: UserRole.values.map((role) {
              final isSelected = role == _currentRole;
              final colorScheme = SecuryFlexTheme.getColorScheme(role);
              
              return ChoiceChip(
                label: Text(_getRoleDisplayName(role)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentRole = role;
                    });
                    if (_enableHaptic) {
                      HapticFeedback.lightImpact();
                    }
                  }
                },
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.primary : null,
                  fontWeight: isSelected ? DesignTokens.fontWeightMedium : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.guard:
        return 'Beveiliger';
      case UserRole.company:
        return 'Bedrijf';
      case UserRole.admin:
        return 'Admin';
    }
  }
  
  Widget _buildSettingsPanel() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instellingen',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          _buildSettingTile(
            'Input Ingeschakeld',
            'Schakel de input aan/uit',
            _isEnabled,
            (value) => setState(() => _isEnabled = value),
          ),
          
          _buildSettingTile(
            'Haptic Feedback',
            'Voelbare feedback bij interacties',
            _enableHaptic,
            (value) => setState(() => _enableHaptic = value),
          ),
          
          _buildSettingTile(
            'Karakterteller',
            'Toon karakter telling',
            _showCharacterCounter,
            (value) => setState(() => _showCharacterCounter = value),
          ),
          
          _buildSettingTile(
            'Backdrop Blur',
            'Wazig effect voor bijlage menu',
            _showBackdrop,
            (value) => setState(() => _showBackdrop = value),
          ),
          
          _buildSettingTile(
            'Antwoord Voorbeeld',
            'Toon reply preview',
            _showReply,
            (value) {
              setState(() => _showReply = value);
              if (value && _messages.isNotEmpty) {
                _setReply(_messages.last);
              } else {
                _clearReply();
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: SecuryFlexTheme.getColorScheme(_currentRole).primary,
      ),
    );
  }
  
  Widget _buildMessageList() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusL),
          ),
        ),
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            return _buildMessageBubble(message);
          },
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble(DemoMessage message) {
    final colorScheme = SecuryFlexTheme.getColorScheme(_currentRole);
    
    if (message.isSystem) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    final isResponse = message.isResponse;
    
    return GestureDetector(
      onLongPress: () => _setReply(message),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
        child: Row(
          mainAxisAlignment: isResponse ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isResponse) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondary,
                child: Icon(
                  Icons.smart_toy,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onSecondary,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: isResponse 
                      ? colorScheme.surfaceContainerHigh
                      : colorScheme.primary,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                ),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isResponse 
                        ? colorScheme.onSurface
                        : colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
            if (!isResponse) ...[
              SizedBox(width: DesignTokens.spacingS),
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: DesignTokens.iconSizeS,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureButtons() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Feature Demonstratie',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: [
              _buildFeatureButton(
                'Focus Glow',
                'Zie de glow effect rond de input',
                Icons.blur_on,
                () => _showFeatureExplanation(
                  'Focus Glow',
                  'De input field toont een subtiele glow in de role kleur wanneer je erop tikt. Dit geeft duidelijke visuele feedback.',
                ),
              ),
              _buildFeatureButton(
                'Send Animatie',
                'Rotatie en schaal effecten',
                Icons.send,
                () => _showFeatureExplanation(
                  'Send Button Animatie',
                  'De send button heeft meerdere animatie staten:\n• Scale effect bij drukken\n• Rotatie tijdens versturen\n• Loading indicator\n• Haptic feedback',
                ),
              ),
              _buildFeatureButton(
                'Bijlage Menu',
                'Floating menu met backdrop blur',
                Icons.attach_file,
                () => _showFeatureExplanation(
                  'Attachment Menu',
                  'Het bijlage menu gebruikt:\n• Backdrop blur effect\n• Staggered animaties\n• Spring physics\n• iOS-style design',
                ),
              ),
              _buildFeatureButton(
                'Typing Feedback',
                'Dynamische hoogte en feedback',
                Icons.keyboard,
                () => _showFeatureExplanation(
                  'Typing Features',
                  'Tijdens het typen:\n• Input hoogte past zich aan\n• Typing indicator updates\n• Character counter animaties\n• Auto-resize voor multi-line',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final colorScheme = SecuryFlexTheme.getColorScheme(_currentRole);
    
    return SizedBox(
      width: (MediaQuery.of(context).size.width - (DesignTokens.spacingM * 3)) / 2,
      child: Material(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(_currentRole);
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            UnifiedHeader(
              title: 'Chat Input Demo',
              type: UnifiedHeaderType.simple,
              userRole: _currentRole,
            ),
            
            // Settings panels
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildRoleSelector(),
                  Divider(height: 1),
                  _buildSettingsPanel(),
                  Divider(height: 1),
                  _buildFeatureButtons(),
                  Divider(height: 1),
                ],
              ),
            ),
            
            // Message list
            _buildMessageList(),
            
            // Enhanced chat input
            EnhancedChatInput(
              userRole: _currentRole,
              onSendMessage: _onSendMessage,
              onSendFile: _onSendFile,
              replyTo: _showReply ? _replyTo : null,
              onCancelReply: _clearReply,
              placeholder: 'Typ je bericht hier...',
              isEnabled: _isEnabled,
              maxLength: _maxLength,
              showCharacterCounter: _showCharacterCounter,
              enableHapticFeedback: _enableHaptic,
              showAttachmentBackdrop: _showBackdrop,
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo message model for the demo screen
class DemoMessage {
  final String text;
  final bool isSystem;
  final bool isResponse;
  final DateTime timestamp;

  DemoMessage({
    required this.text,
    this.isSystem = false,
    this.isResponse = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}