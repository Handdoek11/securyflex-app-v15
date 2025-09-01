import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../models/message_model.dart';

/// WhatsApp-quality file preview with thumbnails and download functionality
/// Follows SecuryFlex unified design system patterns
class UnifiedFilePreview extends StatelessWidget {
  final MessageAttachment attachment;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final bool showDownloadButton;
  final bool isCompact;

  const UnifiedFilePreview({
    super.key,
    required this.attachment,
    required this.userRole,
    this.onTap,
    this.onDownload,
    this.showDownloadButton = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    if (_isImage()) {
      return _buildImagePreview(context, colorScheme);
    } else {
      return _buildFilePreview(context, colorScheme);
    }
  }

  Widget _buildImagePreview(BuildContext context, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: onTap ?? () => _showImageViewer(context),
      child: UnifiedCard.standard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: Stack(
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: attachment.thumbnailUrl ?? attachment.fileUrl,
                width: isCompact ? 120 : 200,
                height: isCompact ? 90 : 150,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(colorScheme),
                errorWidget: (context, url, error) => _buildImageError(context, colorScheme),
              ),
              
              // Overlay with file info
              if (!isCompact)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildImageOverlay(context, colorScheme),
                ),
              
              // Download button
              if (showDownloadButton)
                Positioned(
                  top: DesignTokens.spacingS,
                  right: DesignTokens.spacingS,
                  child: _buildDownloadButton(colorScheme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(BuildContext context, ColorScheme colorScheme) {
    return UnifiedCard.standard(
      child: InkWell(
        onTap: onTap ?? _downloadFile,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Row(
            children: [
              // File icon
              _buildFileIcon(colorScheme),
              
              SizedBox(width: DesignTokens.spacingM),
              
              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Row(
                      children: [
                        Text(
                          _formatFileSize(attachment.fileSize),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' • ${_getFileTypeLabel()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Download button
              if (showDownloadButton)
                _buildDownloadButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      width: isCompact ? 120 : 200,
      height: isCompact ? 90 : 150,
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildImageError(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: isCompact ? 120 : 200,
      height: isCompact ? 90 : 150,
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: colorScheme.error,
            size: DesignTokens.iconSizeL,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Kan afbeelding\nniet laden',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageOverlay(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            DesignTokens.colorBlack.withValues(alpha: 0.7),
          ],
        ),
      ),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              attachment.fileName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DesignTokens.colorWhite,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatFileSize(attachment.fileSize),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DesignTokens.colorWhite.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;
    
    final extension = attachment.fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = DesignTokens.colorError;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        iconColor = colorScheme.primary;
        break;
      case 'xlsx':
      case 'xls':
        iconData = Icons.table_chart;
        iconColor = DesignTokens.colorSuccess;
        break;
      case 'pptx':
      case 'ppt':
        iconData = Icons.slideshow;
        iconColor = DesignTokens.colorWarning;
        break;
      case 'txt':
        iconData = Icons.text_snippet;
        iconColor = colorScheme.onSurfaceVariant;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = colorScheme.onSurfaceVariant;
    }
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: DesignTokens.iconSizeL,
      ),
    );
  }

  Widget _buildDownloadButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.colorBlack.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
      ),
      child: UnifiedButton.icon(
        icon: Icons.download,
        onPressed: onDownload ?? _downloadFile,
        color: DesignTokens.colorWhite,
        size: UnifiedButtonSize.small,
      ),
    );
  }

  void _showImageViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageViewer(
          imageUrl: attachment.fileUrl,
          fileName: attachment.fileName,
          userRole: userRole,
        ),
      ),
    );
  }

  Future<void> _downloadFile() async {
    try {
      final uri = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // TODO: Implement proper error logging
      debugPrint('Error downloading file: $e');
    }
  }

  bool _isImage() {
    final extension = attachment.fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  String _getFileTypeLabel() {
    final extension = attachment.fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF Document';
      case 'doc':
      case 'docx':
        return 'Word Document';
      case 'xlsx':
      case 'xls':
        return 'Excel Spreadsheet';
      case 'pptx':
      case 'ppt':
        return 'PowerPoint Presentation';
      case 'txt':
        return 'Text Document';
      default:
        return extension.toUpperCase();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Full-screen image viewer
class _ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String fileName;
  final UserRole userRole;

  const _ImageViewer({
    required this.imageUrl,
    required this.fileName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.colorBlack,
      appBar: AppBar(
        backgroundColor: DesignTokens.colorBlack.withValues(alpha: 0.8),
        foregroundColor: DesignTokens.colorWhite,
        title: Text(
          fileName,
          style: TextStyle(
            color: DesignTokens.colorWhite,
            fontSize: DesignTokens.fontSizeM,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _downloadImage(),
            icon: const Icon(Icons.download),
            color: DesignTokens.colorWhite,
          ),
        ],
      ),
      body: PhotoView(
        imageProvider: CachedNetworkImageProvider(imageUrl),
        backgroundDecoration: const BoxDecoration(
          color: DesignTokens.colorBlack,
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
      ),
    );
  }

  Future<void> _downloadImage() async {
    try {
      final uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // TODO: Implement proper error logging
      debugPrint('Error downloading image: $e');
    }
  }
}
