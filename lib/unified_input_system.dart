import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';

/// Input field variant enumeration
enum UnifiedInputVariant {
  /// Standard text input field
  standard,
  /// Outlined input field with border
  outlined,
  /// Filled input field with background
  filled,
  /// Search input field with search icon
  search,
  /// Password input field with visibility toggle
  password,
  /// Email input field with email validation
  email,
  /// Phone input field with phone formatting
  phone,
  /// Multiline text area
  multiline,
}

/// Unified Input Component for SecuryFlex
/// 
/// A standardized input component that provides consistent styling
/// and behavior across all modules while supporting different variants
/// and role-based theming.
/// 
/// Features:
/// - Consistent styling using DesignTokens
/// - Multiple input variants (standard, outlined, filled, etc.)
/// - Role-based color theming
/// - Built-in validation support
/// - Accessibility compliance
/// - Dutch localization support
class UnifiedInput extends StatefulWidget {
  /// Input variant determines the styling
  final UnifiedInputVariant variant;
  
  /// Text editing controller
  final TextEditingController? controller;
  
  /// Label text
  final String? label;
  
  /// Hint text
  final String? hint;
  
  /// Helper text
  final String? helperText;
  
  /// Error text
  final String? errorText;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Whether the field is enabled
  final bool isEnabled;
  
  /// Whether the field is read-only
  final bool isReadOnly;
  
  /// Maximum number of lines
  final int? maxLines;
  
  /// Minimum number of lines
  final int? minLines;
  
  /// Maximum length of input
  final int? maxLength;
  
  /// Input type
  final TextInputType? keyboardType;
  
  /// Text input action
  final TextInputAction? textInputAction;
  
  /// Validation function
  final String? Function(String?)? validator;
  
  /// On changed callback
  final void Function(String)? onChanged;
  
  /// On submitted callback
  final void Function(String)? onSubmitted;
  
  /// Prefix icon
  final IconData? prefixIcon;
  
  /// Suffix icon
  final IconData? suffixIcon;
  
  /// Suffix icon callback
  final VoidCallback? onSuffixIconPressed;
  
  /// User role for theming
  final UserRole? userRole;
  
  /// Custom focus node
  final FocusNode? focusNode;
  
  /// Whether to obscure text (for passwords)
  final bool obscureText;
  
  /// Auto focus
  final bool autofocus;

  const UnifiedInput({
    super.key,
    this.variant = UnifiedInputVariant.standard,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.userRole,
    this.focusNode,
    this.obscureText = false,
    this.autofocus = false,
  });

  @override
  State<UnifiedInput> createState() => _UnifiedInputState();

  /// Static factory method for standard input
  static UnifiedInput standard({
    required String label,
    TextEditingController? controller,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    UserRole? userRole,
  }) {
    return UnifiedInput(
      variant: UnifiedInputVariant.standard,
      label: label,
      controller: controller,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      validator: validator,
      onChanged: onChanged,
      userRole: userRole,
    );
  }

  /// Static factory method for email input
  static UnifiedInput email({
    required String label,
    TextEditingController? controller,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    UserRole? userRole,
  }) {
    return UnifiedInput(
      variant: UnifiedInputVariant.email,
      label: label,
      controller: controller,
      hint: hint ?? 'naam@voorbeeld.nl',
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? _defaultEmailValidator,
      onChanged: onChanged,
      userRole: userRole,
      prefixIcon: Icons.email_outlined,
    );
  }

  /// Static factory method for password input
  static UnifiedInput password({
    required String label,
    TextEditingController? controller,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    UserRole? userRole,
  }) {
    return UnifiedInput(
      variant: UnifiedInputVariant.password,
      label: label,
      controller: controller,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      obscureText: true,
      validator: validator ?? _defaultPasswordValidator,
      onChanged: onChanged,
      userRole: userRole,
      prefixIcon: Icons.lock_outlined,
    );
  }

  /// Static factory method for search input
  static UnifiedInput search({
    required String label,
    TextEditingController? controller,
    String? hint,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    UserRole? userRole,
  }) {
    return UnifiedInput(
      variant: UnifiedInputVariant.search,
      label: label,
      controller: controller,
      hint: hint ?? 'Zoeken...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      userRole: userRole,
      prefixIcon: Icons.search,
      textInputAction: TextInputAction.search,
    );
  }

  /// Static factory method for multiline input
  static UnifiedInput multiline({
    required String label,
    TextEditingController? controller,
    String? hint,
    String? helperText,
    String? errorText,
    bool isRequired = false,
    int maxLines = 3,
    int? maxLength,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    UserRole? userRole,
  }) {
    return UnifiedInput(
      variant: UnifiedInputVariant.multiline,
      label: label,
      controller: controller,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      isRequired: isRequired,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      userRole: userRole,
    );
  }

  /// Default email validator
  static String? _defaultEmailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mailadres is verplicht';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Voer een geldig e-mailadres in';
    }
    return null;
  }

  /// Default password validator
  static String? _defaultPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wachtwoord is verplicht';
    }
    if (value.length < 8) {
      return 'Wachtwoord moet minimaal 8 tekens bevatten';
    }
    return null;
  }
}

class _UnifiedInputState extends State<UnifiedInput> {
  bool _isPasswordVisible = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Get the appropriate color scheme based on user role
  ColorScheme _getColorScheme(BuildContext context) {
    if (widget.userRole != null) {
      return SecuryFlexTheme.getColorScheme(widget.userRole!);
    }
    return Theme.of(context).colorScheme;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = _getColorScheme(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
              children: widget.isRequired ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: colorScheme.error,
                  ),
                ),
              ] : null,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.isEnabled,
          readOnly: widget.isReadOnly,
          obscureText: widget.variant == UnifiedInputVariant.password && !_isPasswordVisible,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType ?? _getKeyboardType(),
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: _getInputDecoration(context, colorScheme),
        ),
        if (widget.helperText != null) ...[
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (widget.errorText != null) ...[
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  TextInputType? _getKeyboardType() {
    switch (widget.variant) {
      case UnifiedInputVariant.email:
        return TextInputType.emailAddress;
      case UnifiedInputVariant.phone:
        return TextInputType.phone;
      case UnifiedInputVariant.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  InputDecoration _getInputDecoration(BuildContext context, ColorScheme colorScheme) {
    return InputDecoration(
      hintText: widget.hint,
      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      prefixIcon: widget.prefixIcon != null ? Icon(
        widget.prefixIcon,
        color: colorScheme.onSurfaceVariant,
      ) : null,
      suffixIcon: _getSuffixIcon(colorScheme),
      filled: widget.variant == UnifiedInputVariant.filled,
      fillColor: widget.variant == UnifiedInputVariant.filled 
          ? colorScheme.surfaceContainerHighest 
          : null,
      border: _getBorder(colorScheme),
      enabledBorder: _getBorder(colorScheme),
      focusedBorder: _getBorder(colorScheme, focused: true),
      errorBorder: _getBorder(colorScheme, error: true),
      focusedErrorBorder: _getBorder(colorScheme, error: true, focused: true),
      contentPadding: EdgeInsets.all(DesignTokens.spacingInputPadding),
      counterText: widget.maxLength != null ? null : '',
    );
  }

  Widget? _getSuffixIcon(ColorScheme colorScheme) {
    if (widget.variant == UnifiedInputVariant.password) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      );
    }
    
    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: colorScheme.onSurfaceVariant,
        ),
        onPressed: widget.onSuffixIconPressed,
      );
    }
    
    return null;
  }

  InputBorder _getBorder(ColorScheme colorScheme, {bool focused = false, bool error = false}) {
    Color borderColor;
    double borderWidth;
    
    if (error) {
      borderColor = colorScheme.error;
      borderWidth = 2.0;
    } else if (focused) {
      borderColor = colorScheme.primary;
      borderWidth = 2.0;
    } else {
      borderColor = colorScheme.outline;
      borderWidth = 1.0;
    }
    
    switch (widget.variant) {
      case UnifiedInputVariant.outlined:
      case UnifiedInputVariant.standard:
      case UnifiedInputVariant.email:
      case UnifiedInputVariant.password:
      case UnifiedInputVariant.phone:
      case UnifiedInputVariant.multiline:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        );
      case UnifiedInputVariant.filled:
      case UnifiedInputVariant.search:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          borderSide: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        );
    }
  }
}
