import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../models/message_model.dart';

/// Demo screen showcasing the enhanced message bubble designs
/// Demonstrates all message types, states, and animations
class EnhancedMessageBubbleDemo extends StatefulWidget {
  const EnhancedMessageBubbleDemo({super.key});

  @override
  State<EnhancedMessageBubbleDemo> createState() => _EnhancedMessageBubbleDemoState();
}

class _EnhancedMessageBubbleDemoState extends State<EnhancedMessageBubbleDemo> {
  UserRole _selectedRole = UserRole.guard;
  bool _showTypingIndicator = false;
  final Set<String> _selectedMessages = {};

  final List<MessageModel> _demoMessages = [
    // System message
    MessageModel(
      messageId: 'sys_1',
      conversationId: 'demo',
      senderId: 'system',
      senderName: 'Systeem',
      content: 'Nieuwe beveiligingsopdracht toegewezen',
      messageType: MessageType.system,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    
    // Received text message
    MessageModel(
      messageId: 'msg_1',
      conversationId: 'demo',
      senderId: 'company_123',
      senderName: 'SecureTech Amsterdam',
      content: 'Goedemorgen! We hebben een nieuwe opdracht voor je beschikbaar. Het betreft beveiliging van een evenement in het Vondelpark komende zaterdag van 14:00 tot 22:00.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
      deliveryStatus: {
        'guard_456': UserDeliveryStatus(
          userId: 'guard_456',
          status: MessageDeliveryStatus.read,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        ),
      },
    ),

    // Sent text message with reply
    MessageModel(
      messageId: 'msg_2',
      conversationId: 'demo',
      senderId: 'guard_456',
      senderName: 'Jan de Vries',
      content: 'Prima! Ik ben beschikbaar voor deze opdracht. Zijn er specifieke instructies of voorbereidingen nodig?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      replyTo: MessageReply(
        messageId: 'msg_1',
        senderId: 'company_123',
        senderName: 'SecureTech Amsterdam',
        content: 'Goedemorgen! We hebben een nieuwe opdracht...',
        messageType: MessageType.text,
      ),
      deliveryStatus: {
        'company_123': UserDeliveryStatus(
          userId: 'company_123',
          status: MessageDeliveryStatus.delivered,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
        ),
      },
    ),

    // Image message
    MessageModel(
      messageId: 'msg_3',
      conversationId: 'demo',
      senderId: 'company_123',
      senderName: 'SecureTech Amsterdam',
      content: 'Hier is de plattegrond van het evenement',
      messageType: MessageType.image,
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      attachment: MessageAttachment(
        fileName: 'evenement_plattegrond.jpg',
        fileUrl: 'https://example.com/map.jpg',
        fileSize: 2048000,
        mimeType: 'image/jpeg',
      ),
      deliveryStatus: {
        'guard_456': UserDeliveryStatus(
          userId: 'guard_456',
          status: MessageDeliveryStatus.read,
          timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
        ),
      },
    ),

    // File message
    MessageModel(
      messageId: 'msg_4',
      conversationId: 'demo',
      senderId: 'company_123',
      senderName: 'SecureTech Amsterdam',
      content: '',
      messageType: MessageType.file,
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      attachment: MessageAttachment(
        fileName: 'Beveiligingsprotocol_Vondelpark_2024.pdf',
        fileUrl: 'https://example.com/protocol.pdf',
        fileSize: 5242880,
        mimeType: 'application/pdf',
      ),
      deliveryStatus: {
        'guard_456': UserDeliveryStatus(
          userId: 'guard_456',
          status: MessageDeliveryStatus.delivered,
          timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
        ),
      },
    ),

    // Voice message
    MessageModel(
      messageId: 'msg_5',
      conversationId: 'demo',
      senderId: 'guard_456',
      senderName: 'Jan de Vries',
      content: '',
      messageType: MessageType.voice,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      deliveryStatus: {
        'company_123': UserDeliveryStatus(
          userId: 'company_123',
          status: MessageDeliveryStatus.read,
          timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
      },
    ),

    // Edited message
    MessageModel(
      messageId: 'msg_6',
      conversationId: 'demo',
      senderId: 'guard_456',
      senderName: 'Jan de Vries',
      content: 'Perfect, alles is duidelijk. Ik zal op tijd aanwezig zijn!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isEdited: true,
      editedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      deliveryStatus: {
        'company_123': UserDeliveryStatus(
          userId: 'company_123',
          status: MessageDeliveryStatus.read,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      },
    ),

    // Recent sending message
    MessageModel(
      messageId: 'msg_7',
      conversationId: 'demo',
      senderId: 'guard_456',
      senderName: 'Jan de Vries',
      content: 'Hartelijk dank voor de gedetailleerde informatie. Tot zaterdag!',
      timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
      deliveryStatus: {
        'company_123': UserDeliveryStatus(
          userId: 'company_123',
          status: MessageDeliveryStatus.sending,
          timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        ),
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Message Bubble Demo',
      theme: SecuryFlexTheme.getTheme(_selectedRole),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Enhanced Message Bubbles'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Role selector
            PopupMenuButton<UserRole>(
              icon: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
              ),
              onSelected: (role) {
                setState(() {
                  _selectedRole = role;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: UserRole.guard,
                  child: Row(
                    children: [
                      Icon(Icons.security, size: 20),
                      SizedBox(width: 8),
                      Text('Guard Theme'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: UserRole.company,
                  child: Row(
                    children: [
                      Icon(Icons.business, size: 20),
                      SizedBox(width: 8),
                      Text('Company Theme'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: UserRole.admin,
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 20),
                      SizedBox(width: 8),
                      Text('Admin Theme'),
                    ],
                  ),
                ),
              ],
            ),
            // Typing indicator toggle
            IconButton(
              icon: Icon(
                _showTypingIndicator ? Icons.stop : Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                setState(() {
                  _showTypingIndicator = !_showTypingIndicator;
                });
              },
              tooltip: _showTypingIndicator ? 'Stop Typing' : 'Show Typing',
            ),
          ],
        ),
        body: Column(
          children: [
            // Demo controls
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demo Controls',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Wrap(
                    spacing: DesignTokens.spacingS,
                    runSpacing: DesignTokens.spacingS,
                    children: [
                      _buildInfoChip('Role: ${_selectedRole.name}', Icons.person),
                      _buildInfoChip('Messages: ${_demoMessages.length}', Icons.message),
                      _buildInfoChip('Selected: ${_selectedMessages.length}', Icons.check_circle),
                      if (_showTypingIndicator)
                        _buildInfoChip('Typing Active', Icons.edit, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'Features: Spring animations, role-based theming, delivery status, selection states, typing indicators',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat messages
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                itemCount: _demoMessages.length + (_showTypingIndicator ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator at the end
                  if (_showTypingIndicator && index == _demoMessages.length) {
                    return TypingIndicator(
                      userName: 'SecureTech Amsterdam',
                      userRole: _selectedRole,
                    );
                  }
                  
                  final message = _demoMessages[index];
                  final isCurrentUser = message.senderId.startsWith('guard_');
                  final isSelected = _selectedMessages.contains(message.messageId);
                  
                  return EnhancedMessageBubble(
                    key: ValueKey(message.messageId),
                    message: message,
                    isCurrentUser: isCurrentUser,
                    userRole: _selectedRole,
                    isGroupChat: true,
                    isSelected: isSelected,
                    onTap: () {
                      _showMessageInfo(message);
                    },
                    onLongPress: () {
                      _toggleMessageSelection(message.messageId);
                    },
                    onSelectionToggle: () {
                      _toggleMessageSelection(message.messageId);
                    },
                  );
                },
              ),
            ),
            
            // Action buttons
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedMessages.isNotEmpty 
                          ? () => _clearSelection()
                          : null,
                      icon: const Icon(Icons.clear_all),
                      label: Text('Clear Selection (${_selectedMessages.length})'),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  ElevatedButton.icon(
                    onPressed: () => _showDemoInfo(),
                    icon: const Icon(Icons.info),
                    label: const Text('About Demo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, {Color? color}) {
    final chipColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeS,
            color: chipColor,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessages.clear();
    });
  }

  void _showMessageInfo(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', message.messageType.name),
            _buildInfoRow('Sender', message.senderName),
            _buildInfoRow('Time', _formatTimestamp(message.timestamp)),
            _buildInfoRow('Status', message.getOverallDeliveryStatus().name),
            if (message.isEdited) _buildInfoRow('Edited', 'Yes'),
            if (message.replyTo != null) _buildInfoRow('Reply To', message.replyTo!.senderName),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDemoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enhanced Message Bubbles'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Features Demonstrated:',
                style: TextStyle(
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: 8),
              Text('• Spring-based entrance animations'),
              Text('• Role-based theming (Guard/Company/Admin)'),
              Text('• Enhanced delivery status with micro-interactions'),
              Text('• Message selection with visual feedback'),
              Text('• Modern shadow system for proper elevation'),
              Text('• Typing indicators with animated dots'),
              Text('• Reply previews with visual hierarchy'),
              Text('• Support for text, image, file, and voice messages'),
              Text('• Accessibility-compliant design'),
              Text('• Dutch localization and business standards'),
              SizedBox(height: 16),
              Text(
                'Interactions:',
                style: TextStyle(
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: 8),
              Text('• Tap: View message details'),
              Text('• Long press: Toggle selection'),
              Text('• Switch themes with the person icon'),
              Text('• Toggle typing indicator with edit icon'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: DesignTokens.fontWeightMedium,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d geleden';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h geleden';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m geleden';
    } else {
      return 'Net nu';
    }
  }
}