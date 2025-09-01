import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:securyflex_app/core/unified_components.dart';

/// Profile Image Widget met UnifiedCard container
/// 
/// VERPLICHT gebruik van:
/// - UnifiedCard.elevated voor image container
/// - DesignTokens.radiusL voor circular image
/// - Existing image picker service patterns
/// - UnifiedDialog confirmation voor image changes
/// - Existing loading en error handling patterns
class ProfileImageWidget extends StatefulWidget {
  /// Current image URL
  final String? imageUrl;
  
  /// Selected image file (during editing)
  final File? imageFile;
  
  /// Callback when image is selected
  final Function(File imageFile) onImageSelected;
  
  /// User role for theming
  final UserRole userRole;
  
  /// Custom size for the image container
  final double size;

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.imageFile,
    required this.onImageSelected,
    required this.userRole,
    this.size = 120.0,
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return Column(
      children: [
        // Image container met UnifiedCard
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [DesignTokens.shadowMedium],
            ),
            child: Stack(
              children: [
                // Image content
                ClipOval(
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: _buildImageContent(colorScheme),
                  ),
                ),
                
                // Loading overlay
                if (_isLoading)
                  ClipOval(
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                
                // Edit icon overlay
                if (!_isLoading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                        boxShadow: [DesignTokens.shadowMedium],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colorScheme.onPrimary,
                        size: DesignTokens.iconSizeS,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        // Instructional text
        Text(
          'Tik om foto te wijzigen',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImageContent(ColorScheme colorScheme) {
    // Show selected file first (during editing)
    if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(colorScheme);
        },
      );
    }
    
    // Show network image
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(colorScheme);
        },
      );
    }
    
    // Show default avatar
    return _buildDefaultAvatar(colorScheme);
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: colorScheme.primary.withValues(alpha: 0.7),
      ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    // Show bottom sheet met opties
    await UnifiedDialog.show(
      context: context,
      title: 'Profielfoto wijzigen',
      variant: UnifiedDialogVariant.bottomSheet,
      userRole: widget.userRole,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.camera_alt,
              color: SecuryFlexTheme.getColorScheme(widget.userRole).primary,
            ),
            title: Text('Camera'),
            subtitle: Text('Maak een nieuwe foto'),
            onTap: () {
              context.pop();
              _pickImageFromCamera();
            },
          ),
          ListTile(
            leading: Icon(
              Icons.photo_library,
              color: SecuryFlexTheme.getColorScheme(widget.userRole).primary,
            ),
            title: Text('Galerij'),
            subtitle: Text('Kies uit bestaande foto\'s'),
            onTap: () {
              context.pop();
              _pickImageFromGallery();
            },
          ),
          if (widget.imageUrl != null || widget.imageFile != null)
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: SecuryFlexTheme.getColorScheme(widget.userRole).error,
              ),
              title: Text('Verwijderen'),
              subtitle: Text('Verwijder huidige foto'),
              onTap: () {
                context.pop();
                _confirmRemoveImage();
              },
            ),
        ],
      ),
      actions: [
        UnifiedButton.secondary(
          text: 'Annuleren',
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      setState(() => _isLoading = true);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        await _validateAndSelectImage(imageFile);
      }
    } catch (e) {
      _showErrorMessage('Fout bij openen camera: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isLoading = true);
      
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        await _validateAndSelectImage(imageFile);
      }
    } catch (e) {
      _showErrorMessage('Fout bij openen galerij: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _validateAndSelectImage(File imageFile) async {
    try {
      // Validate file size (max 5MB)
      final fileSizeInBytes = await imageFile.length();
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      
      if (fileSizeInBytes > maxSizeInBytes) {
        _showErrorMessage('Bestand is te groot. Maximaal 5MB toegestaan.');
        return;
      }
      
      // Validate file type (basic check)
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        _showErrorMessage('Ongeldig bestandstype. Alleen JPG, JPEG en PNG toegestaan.');
        return;
      }
      
      // Call the callback
      widget.onImageSelected(imageFile);
      
    } catch (e) {
      _showErrorMessage('Fout bij valideren afbeelding: ${e.toString()}');
    }
  }

  Future<void> _confirmRemoveImage() async {
    final result = await UnifiedDialog.showConfirmation(
      context: context,
      title: 'Foto verwijderen',
      message: 'Weet je zeker dat je de huidige profielfoto wilt verwijderen?',
      confirmText: 'Verwijderen',
      cancelText: 'Annuleren',
      userRole: widget.userRole,
    );

    if (result == true) {
      // Create an empty file to signal removal
      final tempFile = File(''); // Empty file signals removal
      widget.onImageSelected(tempFile);
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SecuryFlexTheme.getColorScheme(widget.userRole).error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}