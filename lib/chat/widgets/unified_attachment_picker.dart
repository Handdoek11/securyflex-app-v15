import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';

/// WhatsApp-quality attachment picker with camera, gallery, and document options
/// Follows SecuryFlex unified design system patterns with Dutch localization
class UnifiedAttachmentPicker extends StatefulWidget {
  final UserRole userRole;
  final Function(String filePath, String fileName, AttachmentType type)? onFileSelected;
  final VoidCallback? onCancel;
  final bool showCamera;
  final bool showGallery;
  final bool showDocuments;
  final bool showVideos;

  const UnifiedAttachmentPicker({
    super.key,
    required this.userRole,
    this.onFileSelected,
    this.onCancel,
    this.showCamera = true,
    this.showGallery = true,
    this.showDocuments = true,
    this.showVideos = false,
  });

  @override
  State<UnifiedAttachmentPicker> createState() => _UnifiedAttachmentPickerState();
}

class _UnifiedAttachmentPickerState extends State<UnifiedAttachmentPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: DesignTokens.colorBlack.withValues(alpha: 0.5),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.all(DesignTokens.spacingL),
              child: UnifiedCard.standard(
                backgroundColor: colorScheme.surface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    _buildHeader(context, colorScheme),
                    
                    // Attachment options
                    _buildAttachmentOptions(context, colorScheme),
                    
                    // Cancel button
                    _buildCancelButton(context, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.attach_file,
            color: colorScheme.primary,
            size: DesignTokens.iconSizeL,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Text(
              'Bestand delen',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        children: [
          // First row
          Row(
            children: [
              if (widget.showCamera)
                Expanded(
                  child: _buildAttachmentOption(
                    context: context,
                    colorScheme: colorScheme,
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: colorScheme.primary,
                    onTap: _pickFromCamera,
                  ),
                ),
              if (widget.showCamera && widget.showGallery)
                SizedBox(width: DesignTokens.spacingM),
              if (widget.showGallery)
                Expanded(
                  child: _buildAttachmentOption(
                    context: context,
                    colorScheme: colorScheme,
                    icon: Icons.photo_library,
                    label: 'Galerij',
                    color: colorScheme.secondary,
                    onTap: _pickFromGallery,
                  ),
                ),
            ],
          ),
          
          if ((widget.showCamera || widget.showGallery) && 
              (widget.showDocuments || widget.showVideos))
            SizedBox(height: DesignTokens.spacingL),
          
          // Second row
          if (widget.showDocuments || widget.showVideos)
            Row(
              children: [
                if (widget.showDocuments)
                  Expanded(
                    child: _buildAttachmentOption(
                      context: context,
                      colorScheme: colorScheme,
                      icon: Icons.description,
                      label: 'Document',
                      color: colorScheme.tertiary,
                      onTap: _pickDocument,
                    ),
                  ),
                if (widget.showDocuments && widget.showVideos)
                  SizedBox(width: DesignTokens.spacingM),
                if (widget.showVideos)
                  Expanded(
                    child: _buildAttachmentOption(
                      context: context,
                      colorScheme: colorScheme,
                      icon: Icons.videocam,
                      label: 'Video',
                      color: DesignTokens.colorWarning,
                      onTap: _pickVideo,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required BuildContext context,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: UnifiedCard.standard(
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: DesignTokens.iconSizeXL,
                ),
              ),
              SizedBox(height: DesignTokens.spacingM),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: UnifiedButton.secondary(
          text: 'Annuleren',
          onPressed: _cancel,
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (await _requestCameraPermission()) {
      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          widget.onFileSelected?.call(image.path, image.name, AttachmentType.image);
          _close();
        }
      } catch (e) {
        _showErrorSnackBar('Fout bij maken foto: ${e.toString()}');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (await _requestPhotosPermission()) {
      try {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (image != null) {
          widget.onFileSelected?.call(image.path, image.name, AttachmentType.image);
          _close();
        }
      } catch (e) {
        _showErrorSnackBar('Fout bij selecteren afbeelding: ${e.toString()}');
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'rtf', 'xlsx', 'xls', 'pptx', 'ppt'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          widget.onFileSelected?.call(file.path!, file.name, AttachmentType.document);
          _close();
        }
      }
    } catch (e) {
      _showErrorSnackBar('Fout bij selecteren document: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    if (await _requestPhotosPermission()) {
      try {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 5),
        );
        
        if (video != null) {
          widget.onFileSelected?.call(video.path, video.name, AttachmentType.video);
          _close();
        }
      } catch (e) {
        _showErrorSnackBar('Fout bij selecteren video: ${e.toString()}');
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog('Camera', 'foto\'s maken');
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _requestPhotosPermission() async {
    final status = await Permission.photos.request();
    if (status.isDenied) {
      _showPermissionDialog('Foto\'s', 'afbeeldingen selecteren');
      return false;
    }
    return status.isGranted;
  }

  void _showPermissionDialog(String permission, String purpose) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission toegang vereist'),
        content: Text(
          'SecuryFlex heeft toegang tot $permission nodig om $purpose. '
          'Ga naar Instellingen om deze toestemming te geven.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              openAppSettings();
            },
            child: const Text('Instellingen'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorError,
      ),
    );
  }

  void _cancel() {
    widget.onCancel?.call();
    _close();
  }

  void _close() {
    _animationController.reverse().then((_) {
      if (mounted) {
        context.pop();
      }
    });
  }
}

/// Attachment type enumeration
enum AttachmentType {
  image,
  document,
  video,
}

/// Show attachment picker as modal
Future<void> showAttachmentPicker({
  required BuildContext context,
  required UserRole userRole,
  Function(String filePath, String fileName, AttachmentType type)? onFileSelected,
  VoidCallback? onCancel,
  bool showCamera = true,
  bool showGallery = true,
  bool showDocuments = true,
  bool showVideos = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (context) => UnifiedAttachmentPicker(
      userRole: userRole,
      onFileSelected: onFileSelected,
      onCancel: onCancel,
      showCamera: showCamera,
      showGallery: showGallery,
      showDocuments: showDocuments,
      showVideos: showVideos,
    ),
  );
}
