import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../../unified_components/ultra_smooth_animation_system.dart';
import '../models/message_model.dart';
import 'input_field_animations.dart';

/// Modern floating attachment menu with backdrop blur and staggered animations
/// iOS-style design with spring physics and natural easing
class FloatingAttachmentMenu extends StatefulWidget {
  /// User role for theming
  final UserRole userRole;
  
  /// Whether the menu is visible
  final bool isVisible;
  
  /// Callback when file is selected
  final Function(String filePath, String fileName, MessageType type)? onFileSelected;
  
  /// Callback when menu should be closed
  final VoidCallback? onClose;
  
  /// Custom attachment options
  final List<AttachmentOption>? customOptions;
  
  /// Whether to show backdrop blur effect
  final bool showBackdropBlur;
  
  /// Menu animation duration
  final Duration animationDuration;

  const FloatingAttachmentMenu({
    super.key,
    required this.userRole,
    required this.isVisible,
    this.onFileSelected,
    this.onClose,
    this.customOptions,
    this.showBackdropBlur = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<FloatingAttachmentMenu> createState() => _FloatingAttachmentMenuState();
}

class _FloatingAttachmentMenuState extends State<FloatingAttachmentMenu>
    with TickerProviderStateMixin, AnimationLifecycleMixin {
  
  // Animation controllers
  late AnimationController _menuController;
  late AnimationController _backdropController;
  late AnimationController _staggerController;
  
  // Animations
  late Animation<double> _menuSlideAnimation;
  late Animation<double> _menuOpacityAnimation;
  late Animation<double> _backdropAnimation;
  late List<Animation<double>> _itemAnimations;
  
  // Services
  final ImagePicker _imagePicker = ImagePicker();
  
  // Default attachment options
  late List<AttachmentOption> _attachmentOptions;

  @override
  void initState() {
    super.initState();
    _initializeAttachmentOptions();
    _initializeAnimations();
    
    if (widget.isVisible) {
      _showMenu();
    }
  }
  
  void _initializeAttachmentOptions() {
    _attachmentOptions = widget.customOptions ?? [
      AttachmentOption(
        icon: Icons.camera_alt,
        label: 'Camera',
        color: DesignTokens.colorPrimaryBlue,
        onTap: () => _pickImage(ImageSource.camera),
      ),
      AttachmentOption(
        icon: Icons.photo_library,
        label: 'Galerij',
        color: DesignTokens.colorSecondaryTeal,
        onTap: () => _pickImage(ImageSource.gallery),
      ),
      AttachmentOption(
        icon: Icons.description,
        label: 'Document',
        color: DesignTokens.colorWarning,
        onTap: _pickFile,
      ),
      AttachmentOption(
        icon: Icons.location_on,
        label: 'Locatie',
        color: DesignTokens.colorError,
        onTap: _shareLocation,
      ),
    ];
  }
  
  void _initializeAnimations() {
    final animationSystem = UltraSmoothAnimationSystem();
    
    // Menu slide and opacity animations with ultra-smooth system
    _menuController = AnimationController(
      duration: animationSystem.getOptimalDuration(widget.animationDuration),
      vsync: this,
    );
    registerController(_menuController);
    
    _menuSlideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: animationSystem.getOptimalCurve(),
    ));
    
    _menuOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    // Backdrop blur animation with ultra-smooth system
    _backdropController = AnimationController(
      duration: animationSystem.getOptimalDuration(InputFieldAnimations.fast),
      vsync: this,
    );
    registerController(_backdropController);
    
    _backdropAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backdropController,
      curve: animationSystem.getOptimalCurve(),
    ));
    
    // Staggered item animations with ultra-smooth system
    _staggerController = AnimationController(
      duration: animationSystem.getOptimalDuration(const Duration(milliseconds: 400)),
      vsync: this,
    );
    registerController(_staggerController);
    
    _itemAnimations = InputFieldAnimations.createStaggeredAnimations(
      _staggerController,
      _attachmentOptions.length,
      staggerDelay: 0.1,
    );
  }

  @override
  void didUpdateWidget(FloatingAttachmentMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _showMenu();
      } else {
        _hideMenu();
      }
    }
    
    if (widget.customOptions != oldWidget.customOptions) {
      _initializeAttachmentOptions();
      _updateStaggeredAnimations();
    }
  }
  
  void _updateStaggeredAnimations() {
    _itemAnimations = InputFieldAnimations.createStaggeredAnimations(
      _staggerController,
      _attachmentOptions.length,
      staggerDelay: 0.1,
    );
  }
  
  void _showMenu() {
    _menuController.forward();
    if (widget.showBackdropBlur) {
      _backdropController.forward();
    }
    _staggerController.forward();
  }
  
  void _hideMenu() {
    _menuController.reverse();
    _backdropController.reverse();
    _staggerController.reverse();
  }
  
  void _closeMenu() {
    _hideMenu();
    widget.onClose?.call();
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
        widget.onFileSelected?.call(image.path, image.name, MessageType.image);
        _closeMenu();
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
          widget.onFileSelected?.call(file.path!, file.name, MessageType.file);
          _closeMenu();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Fout bij selecteren bestand: ${e.toString()}');
    }
  }
  
  void _shareLocation() {
    // TODO: Implement location sharing
    _showInfoSnackBar('Locatie delen wordt binnenkort beschikbaar');
    _closeMenu();
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),
    );
  }
  
  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorInfo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
      ),
    );
  }

  Widget _buildBackdrop() {
    if (!widget.showBackdropBlur) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _backdropAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _backdropAnimation.value,
          child: GestureDetector(
            onTap: _closeMenu,
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 10.0 * _backdropAnimation.value,
                  sigmaY: 10.0 * _backdropAnimation.value,
                ),
                child: Container(
                  color: DesignTokens.colorBlack.withValues(alpha: 0.2 * _backdropAnimation.value),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAttachmentItem(AttachmentOption option, int index) {
    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, child) {
        final animationValue = _itemAnimations[index].value;
        
        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Transform.scale(
            scale: 0.3 + (0.7 * animationValue),
            child: Opacity(
              opacity: animationValue,
              child: GestureDetector(
                onTap: () {
                  InputFieldAnimations.selectionHaptic();
                  option.onTap();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumGlassContainer(
                      intensity: GlassIntensity.standard,
                      elevation: GlassElevation.floating,
                      tintColor: option.color,
                      enableTrustBorder: true,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                      width: 56,
                      height: 56,
                      padding: EdgeInsets.zero,
                      child: Icon(
                        option.icon,
                        color: option.color,
                        size: DesignTokens.iconSizeXL,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      option.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: option.color,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMenuContent() {
    return AnimatedBuilder(
      animation: _menuSlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 200 * _menuSlideAnimation.value),
          child: AnimatedBuilder(
            animation: _menuOpacityAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _menuOpacityAnimation.value,
                child: Container(
                  margin: EdgeInsets.all(DesignTokens.spacingM),
                  padding: EdgeInsets.all(DesignTokens.spacingL),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.colorBlack.withValues(alpha: 0.1),
                        offset: const Offset(0, 8),
                        blurRadius: 24.0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle indicator
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Menu title
                      Text(
                        'Bijlage toevoegen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingL),
                      
                      // Attachment options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _attachmentOptions.asMap().entries.map((entry) {
                          return _buildAttachmentItem(entry.value, entry.key);
                        }).toList(),
                      ),
                      
                      SizedBox(height: DesignTokens.spacingM),
                      
                      // Cancel button
                      TextButton(
                        onPressed: _closeMenu,
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                        ),
                        child: Text('Annuleren'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }
    
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop blur
          _buildBackdrop(),
          
          // Menu content
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildMenuContent(),
          ),
        ],
      ),
    );
  }
}

/// Configuration for attachment menu options
class AttachmentOption {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Preset attachment options for common use cases
class AttachmentPresets {
  static List<AttachmentOption> standard(VoidCallback onCamera, VoidCallback onGallery, VoidCallback onFile) => [
    AttachmentOption(
      icon: Icons.camera_alt,
      label: 'Camera',
      color: DesignTokens.colorPrimaryBlue,
      onTap: onCamera,
    ),
    AttachmentOption(
      icon: Icons.photo_library,
      label: 'Galerij',
      color: DesignTokens.colorSecondaryTeal,
      onTap: onGallery,
    ),
    AttachmentOption(
      icon: Icons.description,
      label: 'Document',
      color: DesignTokens.colorWarning,
      onTap: onFile,
    ),
  ];
  
  static List<AttachmentOption> extended(
    VoidCallback onCamera,
    VoidCallback onGallery,
    VoidCallback onFile,
    VoidCallback onLocation,
    VoidCallback onContact,
  ) => [
    ...standard(onCamera, onGallery, onFile),
    AttachmentOption(
      icon: Icons.location_on,
      label: 'Locatie',
      color: DesignTokens.colorError,
      onTap: onLocation,
    ),
    AttachmentOption(
      icon: Icons.contact_phone,
      label: 'Contact',
      color: DesignTokens.colorInfo,
      onTap: onContact,
    ),
  ];
}