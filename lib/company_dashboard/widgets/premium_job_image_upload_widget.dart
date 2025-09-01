import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/premium_job_image_service.dart';
import '../models/job_image_data.dart';
import '../../unified_components/unified_loading_indicator.dart';
import '../../unified_components/unified_snackbar.dart';
import '../../unified_components/unified_glassmorphic_container.dart';
import '../../unified_components/unified_button.dart';
import '../../unified_components/unified_icon_button.dart';

/// Premium job image upload widget with drag-and-drop, gallery management, and AI analysis
/// Nederlandse security marketplace compliant - Enterprise solution
class PremiumJobImageUploadWidget extends StatefulWidget {
  final String jobId;
  final List<JobImageData>? existingImages;
  final Function(List<JobImageData>) onImagesUpdated;
  final int maxImages;
  final bool enableAIAnalysis;
  final bool showInsights;
  final VoidCallback? onAnalysisComplete;

  const PremiumJobImageUploadWidget({
    Key? key,
    required this.jobId,
    this.existingImages,
    required this.onImagesUpdated,
    this.maxImages = 10,
    this.enableAIAnalysis = true,
    this.showInsights = true,
    this.onAnalysisComplete,
  }) : super(key: key);

  @override
  State<PremiumJobImageUploadWidget> createState() => _PremiumJobImageUploadWidgetState();
}

class _PremiumJobImageUploadWidgetState extends State<PremiumJobImageUploadWidget> 
    with TickerProviderStateMixin {
  late final PremiumJobImageService _imageService;
  final List<JobImageData> _images = [];
  final Map<String, double> _uploadProgress = {};
  final Map<String, UploadStatus> _uploadStatus = {};
  
  bool _isDragOver = false;
  bool _isProcessing = false;
  String? _currentUploadId;
  
  late AnimationController _dragAnimationController;
  late AnimationController _successAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize service
    _imageService = PremiumJobImageService.instance;
    
    // Initialize animations
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _dragAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.easeIn,
    ));
    
    // Load existing images
    if (widget.existingImages != null) {
      _images.addAll(widget.existingImages!);
    }
    
    // Setup upload progress listener
    _imageService.uploadProgressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _uploadProgress[progress.imageId] = progress.progress;
          if (progress.progress >= 1.0) {
            _uploadStatus[progress.imageId] = UploadStatus.completed;
            _successAnimationController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  /// Handle file selection from picker
  Future<void> _pickImages() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null && result.files.isNotEmpty) {
        await _processPickedFiles(result.files);
      }
    } catch (e) {
      _showError('Fout bij selecteren van afbeeldingen: $e');
    }
  }

  /// Process selected files
  Future<void> _processPickedFiles(List<PlatformFile> files) async {
    if (_images.length + files.length > widget.maxImages) {
      _showError('Maximum ${widget.maxImages} afbeeldingen toegestaan');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      for (final file in files) {
        if (!_validateFile(file)) continue;

        final String uploadId = DateTime.now().millisecondsSinceEpoch.toString();
        setState(() {
          _currentUploadId = uploadId;
          _uploadStatus[uploadId] = UploadStatus.uploading;
        });

        // Upload with progress tracking
        final JobImageData? uploadedImage = await _uploadImage(file, uploadId);
        
        if (uploadedImage != null) {
          setState(() {
            _images.add(uploadedImage);
            _uploadStatus[uploadId] = UploadStatus.completed;
          });
          
          // Trigger AI analysis if enabled
          if (widget.enableAIAnalysis) {
            await _analyzeImage(uploadedImage);
          }
        }
      }

      // Update parent with new images
      widget.onImagesUpdated(_images);
      
      // Success animation
      await _successAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _successAnimationController.reset();
      
    } finally {
      setState(() {
        _isProcessing = false;
        _currentUploadId = null;
      });
    }
  }

  /// Validate file before upload
  bool _validateFile(PlatformFile file) {
    // Check file size (max 10MB)
    const int maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
      _showError('Bestand te groot. Maximum 10MB toegestaan.');
      return false;
    }

    // Check file type
    final List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
    final String? extension = file.extension?.toLowerCase();
    if (extension == null || !allowedExtensions.contains(extension)) {
      _showError('Ongeldig bestandstype. Alleen JPG, PNG, WebP en HEIC toegestaan.');
      return false;
    }

    return true;
  }

  /// Upload image with progress tracking
  Future<JobImageData?> _uploadImage(PlatformFile file, String uploadId) async {
    try {
      // Create file reference
      File? imageFile;
      if (!kIsWeb && file.path != null) {
        imageFile = File(file.path!);
      }

      // Upload to Firebase Storage
      final JobImageData uploadedImage = await _imageService.uploadJobImage(
        jobId: widget.jobId,
        imageFile: imageFile,
        webImageBytes: kIsWeb ? file.bytes : null,
        isPrimary: _images.isEmpty, // First image is primary
      );

      return uploadedImage;
    } catch (e) {
      _showError('Upload mislukt: $e');
      setState(() => _uploadStatus[uploadId] = UploadStatus.failed);
      return null;
    }
  }

  /// Trigger AI analysis for image
  Future<void> _analyzeImage(JobImageData image) async {
    try {
      final JobImageData analyzedImage = await _imageService.analyzeImage(image);
      
      // Update image with analysis results
      final int index = _images.indexWhere((img) => img.imageId == image.imageId);
      if (index != -1) {
        setState(() {
          _images[index] = analyzedImage;
        });
      }
      
      // Notify parent
      widget.onAnalysisComplete?.call();
      
    } catch (e) {
      debugPrint('AI analyse mislukt: $e');
    }
  }

  /// Delete image
  Future<void> _deleteImage(JobImageData image) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Afbeelding verwijderen?'),
        content: const Text('Deze actie kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _imageService.deleteImage(image);
        setState(() {
          _images.remove(image);
        });
        widget.onImagesUpdated(_images);
        _showSuccess('Afbeelding verwijderd');
      } catch (e) {
        _showError('Verwijderen mislukt: $e');
      }
    }
  }

  /// Set image as primary
  Future<void> _setPrimaryImage(JobImageData image) async {
    try {
      // Update all images
      for (int i = 0; i < _images.length; i++) {
        _images[i] = _images[i].copyWith(
          isPrimary: _images[i].imageId == image.imageId,
        );
      }
      
      setState(() {});
      widget.onImagesUpdated(_images);
      
      // Update in Firebase
      await _imageService.setPrimaryImage(widget.jobId, image.imageId);
      
      _showSuccess('Hoofdafbeelding ingesteld');
    } catch (e) {
      _showError('Instellen hoofdafbeelding mislukt: $e');
    }
  }

  /// Reorder images
  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final JobImageData item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
      
      // Update display order
      for (int i = 0; i < _images.length; i++) {
        _images[i] = _images[i].copyWith(displayOrder: i);
      }
    });
    
    widget.onImagesUpdated(_images);
  }

  /// Build drag and drop zone
  Widget _buildDropZone() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragOver ? _scaleAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isDragOver 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade400,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: _isDragOver 
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 64,
                      color: _isDragOver 
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isDragOver 
                          ? 'Laat los om te uploaden'
                          : 'Sleep afbeeldingen hierheen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _isDragOver 
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'of klik om te selecteren',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    UnifiedButton(
                      onPressed: _isProcessing ? null : _pickImages,
                      text: 'Selecteer afbeeldingen',
                      icon: Icons.add_photo_alternate,
                      variant: UnifiedButtonVariant.secondary,
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

  /// Build image gallery
  Widget _buildImageGallery() {
    if (_images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Toegevoegde afbeeldingen (${_images.length}/${widget.maxImages})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_images.length > 1)
              TextButton.icon(
                onPressed: () => setState(() {}), // Toggle reorder mode
                icon: const Icon(Icons.reorder, size: 20),
                label: const Text('Volgorde aanpassen'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _images.length,
          itemBuilder: (context, index) {
            final image = _images[index];
            return _buildImageTile(image, index);
          },
        ),
      ],
    );
  }

  /// Build individual image tile
  Widget _buildImageTile(JobImageData image, int index) {
    final bool isUploading = _uploadStatus[image.imageId] == UploadStatus.uploading;
    final double? progress = _uploadProgress[image.imageId];

    return UnifiedGlassmorphicContainer(
      padding: EdgeInsets.zero,
      borderRadius: 12,
      child: Stack(
        children: [
          // Image preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: image.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: UnifiedLoadingIndicator(size: 24),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.error_outline, color: Colors.red),
              ),
            ),
          ),
          
          // Upload progress overlay
          if (isUploading && progress != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularPercentIndicator(
                  radius: 30.0,
                  lineWidth: 4.0,
                  percent: progress,
                  center: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: Theme.of(context).primaryColor,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          
          // Primary badge
          if (image.isPrimary)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hoofd',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // AI insights badge
          if (widget.showInsights && image.analysis != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getInsightSummary(image.analysis!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          
          // Action buttons
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              children: [
                if (!image.isPrimary)
                  UnifiedIconButton(
                    icon: Icons.star_border,
                    onPressed: () => _setPrimaryImage(image),
                    size: 28,
                    backgroundColor: Colors.white70,
                    iconColor: Colors.amber,
                  ),
                const SizedBox(width: 4),
                UnifiedIconButton(
                  icon: Icons.delete_outline,
                  onPressed: () => _deleteImage(image),
                  size: 28,
                  backgroundColor: Colors.white70,
                  iconColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get AI insight summary
  String _getInsightSummary(ImageAnalysisData analysis) {
    final List<String> insights = [];
    
    if (analysis.locationType != null) {
      insights.add(analysis.locationType!.displayName);
    }
    
    if (analysis.hasSecurityEquipment) {
      insights.add('Beveiliging zichtbaar');
    }
    
    if (analysis.imageQualityScore > 0.8) {
      insights.add('Hoge kwaliteit');
    }
    
    return insights.join(' • ');
  }

  /// Show error message
  void _showError(String message) {
    UnifiedSnackbar.show(
      context: context,
      message: message,
      type: SnackbarType.error,
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    UnifiedSnackbar.show(
      context: context,
      message: message,
      type: SnackbarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with info
        Row(
          children: [
            const Icon(Icons.photo_library, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Job Afbeeldingen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (widget.enableAIAnalysis)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'AI Analyse',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Info text
        Text(
          'Voeg maximaal ${widget.maxImages} afbeeldingen toe om uw vacature aantrekkelijker te maken. '
          'De eerste afbeelding wordt gebruikt als hoofdafbeelding.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Drop zone (only show if not at max)
        if (_images.length < widget.maxImages)
          _buildDropZone(),
        
        // Processing indicator
        if (_isProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                const UnifiedLoadingIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Afbeeldingen verwerken...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        
        // Image gallery
        _buildImageGallery(),
        
        // Tips section
        if (_images.isEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, 
                  size: 20, 
                  color: Colors.blue.shade700
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips voor betere afbeeldingen:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Gebruik hoge resolutie foto\'s (minimaal 1200x800)\n'
                        '• Toon de werklocatie en werkomgeving\n'
                        '• Voeg foto\'s toe van beveiligingsapparatuur indien relevant\n'
                        '• Zorg voor goede belichting en scherpte',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Upload status enum
enum UploadStatus {
  idle,
  uploading,
  processing,
  completed,
  failed,
}