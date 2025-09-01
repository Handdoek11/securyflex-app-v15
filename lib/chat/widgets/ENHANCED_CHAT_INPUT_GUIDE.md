# Enhanced Chat Input Integration Guide

## Overview

The Enhanced Chat Input system provides a premium messaging experience with modern animations, smooth transitions, and professional design patterns. This guide covers integration with existing SecuryFlex chat functionality.

## Quick Start

### Basic Implementation

```dart
import 'package:flutter/material.dart';
import '../widgets/enhanced_chat_input.dart';

class ChatScreen extends StatefulWidget {
  final UserRole userRole;
  
  const ChatScreen({super.key, required this.userRole});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  void _onSendMessage(String message) {
    // Handle message sending
    print('Sending message: $message');
  }
  
  void _onSendFile(String filePath, String fileName, MessageType type) {
    // Handle file sending
    print('Sending file: $fileName ($type)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Your message list here
          Expanded(child: MessageList()),
          
          // Enhanced chat input
          EnhancedChatInput(
            userRole: widget.userRole,
            onSendMessage: _onSendMessage,
            onSendFile: _onSendFile,
          ),
        ],
      ),
    );
  }
}
```

### Advanced Implementation with All Features

```dart
class AdvancedChatScreen extends StatefulWidget {
  final UserRole userRole;
  final String conversationId;
  
  const AdvancedChatScreen({
    super.key,
    required this.userRole,
    required this.conversationId,
  });
  
  @override
  State<AdvancedChatScreen> createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen> {
  bool _isTyping = false;
  MessageReply? _replyTo;

  void _onSendMessage(String message) async {
    // Send message via your chat service
    await ChatService.sendMessage(
      conversationId: widget.conversationId,
      message: message,
      replyTo: _replyTo,
    );
    
    // Clear reply after sending
    setState(() {
      _replyTo = null;
    });
  }
  
  void _onSendFile(String filePath, String fileName, MessageType type) async {
    // Handle file upload and sending
    final fileUrl = await FileUploadService.uploadFile(filePath);
    await ChatService.sendFileMessage(
      conversationId: widget.conversationId,
      fileName: fileName,
      fileUrl: fileUrl,
      type: type,
    );
  }
  
  void _onTypingChanged(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      
      // Update typing indicator in chat service
      ChatService.updateTypingStatus(
        conversationId: widget.conversationId,
        isTyping: isTyping,
      );
    }
  }
  
  void _setReply(MessageModel message) {
    setState(() {
      _replyTo = MessageReply(
        messageId: message.messageId,
        senderId: message.senderId,
        senderName: message.senderName,
        content: message.content,
        messageType: message.messageType,
      );
    });
  }
  
  void _cancelReply() {
    setState(() {
      _replyTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Message list with reply functionality
          Expanded(
            child: MessageList(
              onMessageLongPress: _setReply,
              showTypingIndicator: _isTyping,
            ),
          ),
          
          // Enhanced chat input with all features
          EnhancedChatInput(
            userRole: widget.userRole,
            onSendMessage: _onSendMessage,
            onSendFile: _onSendFile,
            onTypingChanged: _onTypingChanged,
            replyTo: _replyTo,
            onCancelReply: _cancelReply,
            placeholder: 'Typ een bericht...',
            isEnabled: true,
            maxLines: 5,
            maxLength: 4000,
            showCharacterCounter: true,
            enableHapticFeedback: true,
            showAttachmentBackdrop: true,
          ),
        ],
      ),
    );
  }
}
```

## Component Features

### 1. Enhanced Chat Input (`enhanced_chat_input.dart`)

**Key Features:**
- Focus glow animation with role-based colors
- Dynamic height adjustment for multi-line input
- Character counter with color transitions
- Typing detection and status updates
- Haptic feedback for interactions
- Reply preview with smooth animations
- Accessibility improvements

**Configuration Options:**
```dart
EnhancedChatInput(
  userRole: UserRole.guard,                    // Required: determines theming
  onSendMessage: _onSendMessage,              // Required: message send callback
  onSendFile: _onSendFile,                    // Optional: file send callback
  onTypingChanged: _onTypingChanged,          // Optional: typing status callback
  replyTo: _replyTo,                          // Optional: message to reply to
  onCancelReply: _cancelReply,                // Optional: cancel reply callback
  placeholder: 'Custom placeholder...',       // Optional: custom placeholder text
  isEnabled: true,                            // Optional: enable/disable input
  maxLines: 5,                                // Optional: maximum lines for input
  maxLength: 4000,                            // Optional: character limit
  showCharacterCounter: true,                 // Optional: show character count
  enableHapticFeedback: true,                 // Optional: enable haptic feedback
  showAttachmentBackdrop: true,               // Optional: backdrop blur on menu
  customAttachmentOptions: [...],             // Optional: custom attachment options
)
```

### 2. Animated Send Button (`animated_send_button.dart`)

**Key Features:**
- Scale animation on press with haptic feedback
- 360° rotation animation when sending
- Loading indicator with smooth transitions
- Color transitions for enabled/disabled states
- Multiple size and styling options

**Usage:**
```dart
AnimatedSendButton(
  userRole: UserRole.company,
  isEnabled: hasText,
  isSending: isMessageSending,
  onPressed: _sendMessage,
  size: 48.0,                                // Optional: button size
  showLoadingIndicator: true,                // Optional: show loading state
  icon: Icons.send,                          // Optional: custom icon
)
```

### 3. Floating Attachment Menu (`floating_attachment_menu.dart`)

**Key Features:**
- iOS-style sliding animation from bottom
- Backdrop blur with smooth opacity transitions
- Staggered item animations for premium feel
- Spring physics for natural movement
- Customizable attachment options

**Usage:**
```dart
FloatingAttachmentMenu(
  userRole: UserRole.admin,
  isVisible: showMenu,
  onFileSelected: _onFileSelected,
  onClose: _closeMenu,
  showBackdropBlur: true,                    // Optional: backdrop effect
  customOptions: [                           // Optional: custom options
    AttachmentOption(
      icon: Icons.location_on,
      label: 'Locatie',
      color: Colors.red,
      onTap: _shareLocation,
    ),
  ],
)
```

### 4. Animation Utilities (`input_field_animations.dart`)

**Reusable Animation Components:**
```dart
// Create animation controllers
final scaleController = InputFieldAnimations.createButtonPressController(this);
final rotationController = InputFieldAnimations.createSendRotationController(this);

// Create animations with consistent curves
final scaleAnimation = InputFieldAnimations.createScaleAnimation(scaleController);
final rotationAnimation = InputFieldAnimations.createRotationAnimation(rotationController);

// Haptic feedback utilities
InputFieldAnimations.lightHaptic();    // Light tap feedback
InputFieldAnimations.sendHaptic();     // Send action feedback
InputFieldAnimations.selectionHaptic(); // Selection feedback
```

## Integration with Existing Chat System

### 1. Replace Existing Chat Input

Replace your current `UnifiedChatInput` with `EnhancedChatInput`:

```dart
// Old implementation
UnifiedChatInput(
  userRole: widget.userRole,
  onSendMessage: _onSendMessage,
)

// New implementation
EnhancedChatInput(
  userRole: widget.userRole,
  onSendMessage: _onSendMessage,
  onSendFile: _onSendFile,
  enableHapticFeedback: true,
  showCharacterCounter: true,
)
```

### 2. Update Chat Service Integration

Ensure your chat service handles the enhanced features:

```dart
class ChatService {
  static Future<void> sendMessage({
    required String conversationId,
    required String message,
    MessageReply? replyTo,
  }) async {
    final messageModel = MessageModel(
      messageId: generateId(),
      conversationId: conversationId,
      senderId: getCurrentUserId(),
      senderName: getCurrentUserName(),
      content: message,
      timestamp: DateTime.now(),
      replyTo: replyTo,
    );
    
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageModel.messageId)
        .set(messageModel.toMap());
  }
  
  static Future<void> sendFileMessage({
    required String conversationId,
    required String fileName,
    required String fileUrl,
    required MessageType type,
  }) async {
    final attachment = MessageAttachment(
      fileName: fileName,
      fileUrl: fileUrl,
      fileSize: await getFileSize(fileUrl),
      mimeType: getMimeType(fileName),
    );
    
    final messageModel = MessageModel(
      messageId: generateId(),
      conversationId: conversationId,
      senderId: getCurrentUserId(),
      senderName: getCurrentUserName(),
      content: attachment.fileName,
      messageType: type,
      timestamp: DateTime.now(),
      attachment: attachment,
    );
    
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageModel.messageId)
        .set(messageModel.toMap());
  }
}
```

### 3. Handle File Uploads

Implement secure file upload handling:

```dart
class FileUploadService {
  static Future<String> uploadFile(String filePath) async {
    final file = File(filePath);
    final fileName = path.basename(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uploadPath = 'chat_files/$timestamp-$fileName';
    
    try {
      final uploadTask = FirebaseStorage.instance
          .ref()
          .child(uploadPath)
          .putFile(file);
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw FileUploadException('Failed to upload file: $e');
    }
  }
}
```

## Testing the Enhanced Chat Input

### 1. Interactive Demo

Run the interactive demo to test all features:

```dart
import '../widgets/chat_input_demo.dart';

// In your app
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ChatInputDemo(),
  ),
);
```

### 2. Unit Tests

Test the enhanced functionality:

```dart
testWidgets('Enhanced chat input shows focus glow', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EnhancedChatInput(
          userRole: UserRole.guard,
          onSendMessage: (message) {},
        ),
      ),
    ),
  );
  
  // Find and tap the text field
  final textField = find.byType(TextField);
  await tester.tap(textField);
  await tester.pumpAndSettle();
  
  // Verify focus glow is applied
  expect(find.byType(Container), findsWidgets);
});
```

### 3. Accessibility Testing

Ensure proper accessibility:

```dart
testWidgets('Enhanced chat input meets accessibility requirements', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EnhancedChatInput(
          userRole: UserRole.guard,
          onSendMessage: (message) {},
        ),
      ),
    ),
  );
  
  // Check semantic labels
  expect(tester.getSemantics(find.byType(TextField)), matchesSemantics(
    label: 'Typ een bericht...',
    isTextField: true,
  ));
});
```

## Performance Optimization

### 1. Animation Disposal

The enhanced chat input uses `AnimationLifecycleMixin` for automatic disposal:

```dart
class _YourWidgetState extends State<YourWidget> 
    with TickerProviderStateMixin, AnimationLifecycleMixin {
  
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    
    // Register for automatic disposal
    registerController(_controller);
  }
  
  // No need for manual disposal - handled by mixin
}
```

### 2. Optimized Rebuilds

Use `AnimatedBuilder` for selective rebuilds:

```dart
InputFieldAnimations.createOptimizedAnimatedBuilder(
  animation: _scaleAnimation,
  builder: (context, child) {
    return Transform.scale(
      scale: _scaleAnimation.value,
      child: child,
    );
  },
  child: ExpensiveWidget(), // Child is cached and not rebuilt
)
```

## Troubleshooting

### Common Issues

1. **Animations not working**: Ensure you're using `TickerProviderStateMixin`
2. **Haptic feedback not working**: Check device settings and enable in widget
3. **File upload failing**: Verify Firebase Storage rules and permissions
4. **Focus glow not visible**: Check role-based theming is properly configured
5. **Character counter not updating**: Ensure `maxLength` is set and `showCharacterCounter` is true

### Debug Mode

Enable debug information:

```dart
EnhancedChatInput(
  userRole: UserRole.guard,
  onSendMessage: _onSendMessage,
  // Add debug callback to see internal state
  onTypingChanged: (isTyping) {
    print('Typing state changed: $isTyping');
  },
)
```

## Best Practices

1. **Role-based theming**: Always pass the correct `UserRole` for proper theming
2. **Error handling**: Wrap file operations in try-catch blocks
3. **Performance**: Use `const` constructors where possible
4. **Accessibility**: Test with screen readers and high contrast mode
5. **Haptic feedback**: Respect user preferences and system settings
6. **Character limits**: Set appropriate limits based on your backend constraints
7. **File validation**: Validate file types and sizes before upload

## Migration from UnifiedChatInput

1. Replace `UnifiedChatInput` imports with `EnhancedChatInput`
2. Update callback signatures to match new API
3. Add file handling if using attachment features
4. Configure animation and haptic preferences
5. Test thoroughly with all user roles
6. Update any custom styling to work with new component structure

The Enhanced Chat Input system provides a significant upgrade to user experience while maintaining compatibility with existing SecuryFlex patterns and design tokens.