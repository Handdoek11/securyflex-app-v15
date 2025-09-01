import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../models/message_model.dart';

/// WhatsApp-quality chat input with typing detection and file attachments
/// Follows SecuryFlex unified design system patterns
class UnifiedChatInput extends StatefulWidget {
  final UserRole userRole;
  final Function(String message) onSendMessage;
  final Function(String filePath, String fileName, MessageType type)? onSendFile;
  final Function(bool isTyping)? onTypingChanged;
  final MessageReply? replyTo;
  final VoidCallback? onCancelReply;
  final String? placeholder;
  final bool isEnabled;
  final int maxLines;
  final int? maxLength;

  const UnifiedChatInput({
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
  });

  @override
  State<UnifiedChatInput> createState() => _UnifiedChatInputState();
}

class _UnifiedChatInputState extends State<UnifiedChatInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _showAttachmentMenu = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    
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
  }

  void _setTyping(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      widget.onTypingChanged?.call(isTyping);
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && widget.isEnabled) {
      widget.onSendMessage(text);
      _textController.clear();
      _setTyping(false);
    }
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        widget.onSendFile?.call(image.path, image.name, MessageType.image);
        _toggleAttachmentMenu();
      }
    } catch (e) {
      _showErrorSnackBar('Fout bij selecteren afbeelding: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          widget.onSendFile?.call(file.path!, file.name, MessageType.file);
          _toggleAttachmentMenu();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Fout bij selecteren bestand: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorError,
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
      child: Column(
        children: [
          // Reply preview
          if (widget.replyTo != null)
            _buildReplyPreview(colorScheme),
          
          // Attachment menu
          if (_showAttachmentMenu)
            _buildAttachmentMenu(colorScheme),
          
          // Main input area
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
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

  Widget _buildAttachmentMenu(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            color: colorScheme.primary,
            onTap: () => _pickImage(ImageSource.camera),
          ),
          _buildAttachmentOption(
            icon: Icons.photo_library,
            label: 'Galerij',
            color: colorScheme.secondary,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
          _buildAttachmentOption(
            icon: Icons.description,
            label: 'Document',
            color: colorScheme.tertiary,
            onTap: _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            child: Icon(
              icon,
              color: color,
              size: DesignTokens.iconSizeL,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            onPressed: widget.isEnabled ? _toggleAttachmentMenu : null,
            icon: Icon(
              _showAttachmentMenu ? Icons.close : Icons.attach_file,
              color: widget.isEnabled 
                  ? colorScheme.primary 
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
          
          // Text input
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: widget.maxLines * 24.0,
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: widget.isEnabled,
                maxLines: null,
                maxLength: widget.maxLength,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: widget.placeholder ?? 'Typ een bericht...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    borderSide: BorderSide(
                      color: colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    borderSide: BorderSide(
                      color: colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  counterText: '', // Hide character counter
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          SizedBox(width: DesignTokens.spacingS),
          
          // Send button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _textController.text.trim().isNotEmpty && widget.isEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
                onTap: _textController.text.trim().isNotEmpty && widget.isEnabled
                    ? _sendMessage
                    : null,
                child: Icon(
                  Icons.send,
                  color: _textController.text.trim().isNotEmpty && widget.isEnabled
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: DesignTokens.iconSizeL,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
