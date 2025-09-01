import 'dart:async';
import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../models/message_model.dart';
import 'input_field_animations.dart';
import 'animated_send_button.dart';
import 'floating_attachment_menu.dart';

/// Enhanced chat input with premium animations and modern design
/// Features: focus glow, height transitions, character counter, typing detection,
/// haptic feedback, and accessibility improvements
class EnhancedChatInput extends StatefulWidget {
  /// User role for theming
  final UserRole userRole;
  
  /// Callback when message is sent
  final Function(String message) onSendMessage;
  
  /// Callback when file is sent
  final Function(String filePath, String fileName, MessageType type)? onSendFile;
  
  /// Callback when typing status changes
  final Function(bool isTyping)? onTypingChanged;
  
  /// Reply message to display
  final MessageReply? replyTo;
  
  /// Callback to cancel reply
  final VoidCallback? onCancelReply;
  
  /// Custom placeholder text
  final String? placeholder;
  
  /// Whether input is enabled
  final bool isEnabled;
  
  /// Maximum number of lines
  final int maxLines;
  
  /// Maximum character length
  final int? maxLength;
  
  /// Whether to show character counter
  final bool showCharacterCounter;
  
  /// Whether to enable haptic feedback
  final bool enableHapticFeedback;
  
  /// Custom attachment options
  final List<AttachmentOption>? customAttachmentOptions;
  
  /// Whether to show backdrop blur on attachment menu
  final bool showAttachmentBackdrop;
  
  /// Input field decoration style
  final InputDecorationType decorationType;

  const EnhancedChatInput({
    super.key,
    required this.userRole,
    required this.onSendMessage,
    this.onSendFile,
    this.onTypingChanged,
    this.replyTo,
    this.onCancelReply,
    this.placeholder,
    this.isEnabled = true,
    this.maxLines = 5,
    this.maxLength = 4000,
    this.showCharacterCounter = true,
    this.enableHapticFeedback = true,
    this.customAttachmentOptions,
    this.showAttachmentBackdrop = true,
    this.decorationType = InputDecorationType.outline,
  });

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput>
    with TickerProviderStateMixin, AnimationLifecycleMixin {
  
  // Text and focus management
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Animation controllers
  late AnimationController _focusController;
  late AnimationController _heightController;
  late AnimationController _counterController;
  late AnimationController _attachmentController;
  
  // Animations
  late Animation<double> _focusGlowAnimation;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _heightAnimation;
  late Animation<Color?> _counterColorAnimation;
  late Animation<double> _attachmentRotationAnimation;
  
  // State management
  bool _isTyping = false;
  bool _isFocused = false;
  bool _showAttachmentMenu = false;
  bool _isSending = false;
  Timer? _typingTimer;
  double _currentHeight = 56.0;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupListeners();
  }
  
  void _initializeAnimations() {
    // Focus glow animation
    _focusController = InputFieldAnimations.createFocusController(this);
    registerController(_focusController);
    
    _focusGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: InputFieldAnimations.easeOutCubic,
    ));
    
    _setupBorderColorAnimation();
    
    // Height animation for multi-line input
    _heightController = AnimationController(
      duration: InputFieldAnimations.fast,
      vsync: this,
    );
    registerController(_heightController);
    
    _heightAnimation = Tween<double>(
      begin: 56.0,
      end: 56.0,
    ).animate(CurvedAnimation(
      parent: _heightController,
      curve: InputFieldAnimations.easeOutCubic,
    ));
    
    // Character counter animation
    _counterController = AnimationController(
      duration: InputFieldAnimations.fast,
      vsync: this,
    );
    registerController(_counterController);
    
    _setupCounterColorAnimation();
    
    // Attachment button rotation
    _attachmentController = AnimationController(
      duration: InputFieldAnimations.medium,
      vsync: this,
    );
    registerController(_attachmentController);
    
    _attachmentRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _attachmentController,
      curve: InputFieldAnimations.easeOutCubic,
    ));
  }
  
  void _setupBorderColorAnimation() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    _borderColorAnimation = ColorTween(
      begin: colorScheme.outline,
      end: colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: InputFieldAnimations.easeOutCubic,
    ));
  }
  
  void _setupCounterColorAnimation() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    _counterColorAnimation = ColorTween(
      begin: colorScheme.onSurfaceVariant,
      end: colorScheme.error,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: InputFieldAnimations.easeOutCubic,
    ));
  }
  
  void _setupListeners() {
    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  void _onTextChanged() {
    final text = _textController.text;
    final hasText = text.trim().isNotEmpty;
    
    // Handle typing state
    if (hasText && !_isTyping) {
      _setTyping(true);
    } else if (!hasText && _isTyping) {
      _setTyping(false);
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    if (hasText) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _setTyping(false);
      });
    }
    
    // Handle character counter color
    if (widget.maxLength != null && widget.showCharacterCounter) {
      final isOverLimit = text.length > widget.maxLength!;
      
      if (isOverLimit && _counterController.value < 1.0) {
        _counterController.forward();
      } else if (!isOverLimit && _counterController.value > 0.0) {
        _counterController.reverse();
      }
    }
    
    // Handle height changes for multi-line
    _updateInputHeight();
    
    setState(() {}); // Trigger rebuild for send button state
  }
  
  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    
    if (isFocused != _isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      
      if (isFocused) {
        _focusController.forward();
        if (widget.enableHapticFeedback) {
          InputFieldAnimations.lightHaptic();
        }
      } else {
        _focusController.reverse();
      }
    }
  }
  
  void _setTyping(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      widget.onTypingChanged?.call(isTyping);
    }
  }
  
  void _updateInputHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject = context.findRenderObject() as RenderBox?;
      if (renderObject != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: _textController.text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        
        textPainter.layout(maxWidth: renderObject.size.width - 120); // Account for buttons
        
        final lines = (textPainter.height / textPainter.preferredLineHeight).ceil();
        final clampedLines = lines.clamp(1, widget.maxLines);
        final newHeight = 24.0 + (clampedLines * 24.0) + 16.0; // Base + lines + padding
        
        if ((newHeight - _currentHeight).abs() > 1.0) {
          _currentHeight = newHeight;
          _heightAnimation = Tween<double>(
            begin: _heightAnimation.value,
            end: newHeight,
          ).animate(CurvedAnimation(
            parent: _heightController,
            curve: InputFieldAnimations.easeOutCubic,
          ));
          _heightController.forward(from: 0.0);
        }
      }
    });
  }
  
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      setState(() {
        _isSending = true;
      });
      
      if (widget.enableHapticFeedback) {
        InputFieldAnimations.sendHaptic();
      }
      
      widget.onSendMessage(text);
      _textController.clear();
      _setTyping(false);
      
      // Reset sending state after animation
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      });
    }
  }
  
  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
    
    if (_showAttachmentMenu) {
      _attachmentController.forward();
      if (widget.enableHapticFeedback) {
        InputFieldAnimations.mediumHaptic();
      }
    } else {
      _attachmentController.reverse();
    }
  }
  
  void _onFileSelected(String filePath, String fileName, MessageType type) {
    widget.onSendFile?.call(filePath, fileName, type);
    _toggleAttachmentMenu();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Widget _buildReplyPreview() {
    if (widget.replyTo == null) return const SizedBox.shrink();
    
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Container(
      margin: EdgeInsets.only(
        left: DesignTokens.spacingM,
        right: DesignTokens.spacingM,
        top: DesignTokens.spacingS,
      ),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Antwoord op ${widget.replyTo!.senderName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  widget.replyTo!.content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
              size: DesignTokens.iconSizeS,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCharacterCounter() {
    if (!widget.showCharacterCounter || widget.maxLength == null) {
      return const SizedBox.shrink();
    }
    
    final currentLength = _textController.text.length;
    final maxLength = widget.maxLength!;
    final isOverLimit = currentLength > maxLength;
    
    return AnimatedBuilder(
      animation: _counterColorAnimation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(
            right: DesignTokens.spacingM,
            bottom: DesignTokens.spacingXS,
          ),
          child: Text(
            '$currentLength/$maxLength',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isOverLimit 
                  ? _counterColorAnimation.value 
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isOverLimit 
                  ? DesignTokens.fontWeightMedium 
                  : DesignTokens.fontWeightRegular,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInputField() {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _focusGlowAnimation,
          builder: (context, child) {
            return Container(
              constraints: BoxConstraints(
                minHeight: 56.0,
                maxHeight: _heightAnimation.value,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: _borderColorAnimation.value ?? colorScheme.outline,
                  width: _isFocused ? 2.0 : 1.0,
                ),
                boxShadow: _isFocused ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3 * _focusGlowAnimation.value),
                    offset: InputFieldAnimations.glowOffset,
                    blurRadius: InputFieldAnimations.glowBlur,
                    spreadRadius: InputFieldAnimations.glowSpread,
                  ),
                ] : null,
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: widget.isEnabled,
                maxLines: null,
                minLines: 1,
                maxLength: widget.maxLength,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: widget.placeholder ?? 'Typ een bericht...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingM,
                  ),
                  counterText: '', // Hide default counter
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: (_) => _sendMessage(),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          AnimatedBuilder(
            animation: _attachmentRotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _attachmentRotationAnimation.value * 2 * 3.14159,
                child: IconButton(
                  onPressed: widget.isEnabled ? _toggleAttachmentMenu : null,
                  icon: Icon(
                    _showAttachmentMenu ? Icons.close : Icons.attach_file,
                    color: widget.isEnabled 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              );
            },
          ),
          
          // Text input
          Expanded(
            child: Column(
              children: [
                _buildInputField(),
                if (widget.showCharacterCounter && widget.maxLength != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildCharacterCounter(),
                  ),
              ],
            ),
          ),
          
          SizedBox(width: DesignTokens.spacingS),
          
          // Send button
          AnimatedSendButton(
            userRole: widget.userRole,
            isEnabled: _textController.text.trim().isNotEmpty && widget.isEnabled,
            isSending: _isSending,
            onPressed: _sendMessage,
            showLoadingIndicator: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply preview
              _buildReplyPreview(),
              
              // Input area
              _buildInputArea(),
            ],
          ),
          
          // Floating attachment menu
          FloatingAttachmentMenu(
            userRole: widget.userRole,
            isVisible: _showAttachmentMenu,
            onFileSelected: _onFileSelected,
            onClose: _toggleAttachmentMenu,
            customOptions: widget.customAttachmentOptions,
            showBackdropBlur: widget.showAttachmentBackdrop,
          ),
        ],
      ),
    );
  }
}

/// Input decoration types for different visual styles
enum InputDecorationType {
  outline,
  filled,
  underlined,
  rounded,
}

/// Simplified enhanced chat input for basic use cases
class SimpleChatInput extends StatelessWidget {
  final UserRole userRole;
  final Function(String message) onSendMessage;
  final String? placeholder;
  final bool isEnabled;

  const SimpleChatInput({
    super.key,
    required this.userRole,
    required this.onSendMessage,
    this.placeholder,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedChatInput(
      userRole: userRole,
      onSendMessage: onSendMessage,
      placeholder: placeholder,
      isEnabled: isEnabled,
      showCharacterCounter: false,
      enableHapticFeedback: false,
    );
  }
}