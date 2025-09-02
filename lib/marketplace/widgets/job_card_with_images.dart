import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../../company_dashboard/models/job_image_data.dart';
import '../model/security_job_data.dart';
import 'optimized_job_card.dart';

/// Context for card display
enum JobCardContext {
  discovery,    // Marketplace discovery tab
  application,  // Applications tab  
  activeShift,  // Active jobs/shifts tab
  history,      // Job history tab
  management,   // Company management view
}

/// Enhanced job card that displays uploaded images with context-aware variations
class JobCardWithImages extends StatelessWidget {
  final SecurityJobData job;
  final List<JobImageData>? images;
  final UserRole userRole;
  final List<String>? userCertificates;
  final bool showApplicationButton;
  final bool showFavoriteButton;
  final VoidCallback? onTap;
  final VoidCallback? onApplyPressed;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onWithdraw;
  final VoidCallback? onViewShift;
  final JobCardContext context;
  final String? applicationStatus;
  final DateTime? applicationDate;
  final DateTime? shiftDate;
  final String? shiftTime;
  final double? totalEarnings;
  final bool isUrgent;
  final bool hasApplied;
  
  const JobCardWithImages({
    Key? key,
    required this.job,
    this.images,
    this.userRole = UserRole.guard,
    this.userCertificates,
    this.showApplicationButton = true,
    this.showFavoriteButton = true,
    this.onTap,
    this.onApplyPressed,
    this.onFavoriteToggle,
    this.onWithdraw,
    this.onViewShift,
    this.context = JobCardContext.discovery,
    this.applicationStatus,
    this.applicationDate,
    this.shiftDate,
    this.shiftTime,
    this.totalEarnings,
    this.isUrgent = false,
    this.hasApplied = false,
  }) : super(key: key);
  
  // Named constructor for discovery/marketplace context
  factory JobCardWithImages.discovery({
    Key? key,
    required SecurityJobData job,
    List<JobImageData>? images,
    List<String>? userCertificates,
    VoidCallback? onTap,
    VoidCallback? onApplyPressed,
    VoidCallback? onFavoriteToggle,
    bool hasApplied = false,
  }) {
    return JobCardWithImages(
      key: key,
      job: job,
      images: images,
      userRole: UserRole.guard,
      userCertificates: userCertificates,
      showApplicationButton: true,
      showFavoriteButton: true,
      onTap: onTap,
      onApplyPressed: onApplyPressed,
      onFavoriteToggle: onFavoriteToggle,
      context: JobCardContext.discovery,
      hasApplied: hasApplied,
    );
  }
  
  // Named constructor for applications context
  factory JobCardWithImages.application({
    Key? key,
    required SecurityJobData job,
    List<JobImageData>? images,
    required String applicationStatus,
    required DateTime applicationDate,
    VoidCallback? onTap,
    VoidCallback? onWithdraw,
  }) {
    return JobCardWithImages(
      key: key,
      job: job,
      images: images,
      userRole: UserRole.guard,
      showApplicationButton: false,
      showFavoriteButton: false,
      onTap: onTap,
      onWithdraw: onWithdraw,
      context: JobCardContext.application,
      applicationStatus: applicationStatus,
      applicationDate: applicationDate,
    );
  }
  
  // Named constructor for active shift context
  factory JobCardWithImages.activeShift({
    Key? key,
    required SecurityJobData job,
    List<JobImageData>? images,
    required DateTime shiftDate,
    required String shiftTime,
    double? totalEarnings,
    bool isUrgent = false,
    VoidCallback? onTap,
    VoidCallback? onViewShift,
  }) {
    return JobCardWithImages(
      key: key,
      job: job,
      images: images,
      userRole: UserRole.guard,
      showApplicationButton: false,
      showFavoriteButton: false,
      onTap: onTap,
      onViewShift: onViewShift,
      context: JobCardContext.activeShift,
      shiftDate: shiftDate,
      shiftTime: shiftTime,
      totalEarnings: totalEarnings,
      isUrgent: isUrgent,
    );
  }
  
  // Named constructor for history context
  factory JobCardWithImages.history({
    Key? key,
    required SecurityJobData job,
    List<JobImageData>? images,
    required DateTime completedDate,
    double? totalEarnings,
    VoidCallback? onTap,
  }) {
    return JobCardWithImages(
      key: key,
      job: job,
      images: images,
      userRole: UserRole.guard,
      showApplicationButton: false,
      showFavoriteButton: false,
      onTap: onTap,
      context: JobCardContext.history,
      shiftDate: completedDate,
      totalEarnings: totalEarnings,
    );
  }
  
  // Named constructor for company management context
  factory JobCardWithImages.management({
    Key? key,
    required SecurityJobData job,
    List<JobImageData>? images,
    VoidCallback? onTap,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return JobCardWithImages(
      key: key,
      job: job,
      images: images,
      userRole: UserRole.company,
      showApplicationButton: false,
      showFavoriteButton: false,
      onTap: onTap,
      context: JobCardContext.management,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = images != null && images!.isNotEmpty;
    
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingS,
        ),
        child: PremiumGlassContainer(
          intensity: GlassIntensity.standard,
          elevation: GlassElevation.floating,
          tintColor: SecuryFlexTheme.getColorScheme(userRole).surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          padding: EdgeInsets.zero,
          enableTrustBorder: true,
          onTap: onTap,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image carousel if available
                if (hasImages) _buildImageCarousel(),
                
                // Card content
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      JobCardHeader(
                        job: job,
                        userRole: userRole,
                        showFavoriteButton: showFavoriteButton,
                      ),
                      const SizedBox(height: DesignTokens.spacingS),
                      JobCardDetails(job: job, userRole: userRole),
                      const SizedBox(height: DesignTokens.spacingS),
                      // Context-specific content
                      _buildContextSpecificContent(),
                      // Certificates (only in discovery)
                      if (context == JobCardContext.discovery && userCertificates?.isNotEmpty == true)
                        JobCardCertificates(
                          job: job,
                          userCertificates: userCertificates!,
                        ),
                      // Actions based on context
                      _buildContextActions(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    // Get primary image or first image
    final primaryImage = images!.firstWhere(
      (img) => img.isPrimary,
      orElse: () => images!.first,
    );

    return Container(
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          // Main image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusM),
              topRight: Radius.circular(DesignTokens.radiusM),
            ),
            child: CachedNetworkImage(
              imageUrl: primaryImage.thumbnailUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.business,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          
          // Gradient overlay for better text visibility
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Image count indicator if multiple images
          if (images!.length > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${images!.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // AI insights badge if available
          if (primaryImage.analysis != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getLocationTypeText(primaryImage.analysis!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getLocationTypeText(ImageAnalysisData analysis) {
    if (analysis.locationType != null) {
      return analysis.locationType!.displayName;
    }
    if (analysis.hasSecurityEquipment) {
      return 'Beveiligd';
    }
    return 'Geverifieerd';
  }

  
  Widget _buildContextSpecificContent() {
    switch (context) {
      case JobCardContext.application:
        return _buildApplicationStatus();
      case JobCardContext.activeShift:
        return _buildShiftDetails();
      case JobCardContext.history:
        return _buildHistoryDetails();
      case JobCardContext.management:
        return _buildManagementStats();
      case JobCardContext.discovery:
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildApplicationStatus() {
    if (applicationStatus == null || applicationDate == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: _getStatusColor(applicationStatus!).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getStatusColor(applicationStatus!).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(applicationStatus!),
            size: 16,
            color: _getStatusColor(applicationStatus!),
          ),
          const SizedBox(width: DesignTokens.spacingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_getStatusText(applicationStatus!)}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _getStatusColor(applicationStatus!),
                  ),
                ),
                Text(
                  'Gesolliciteerd: ${_formatDate(applicationDate!)}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShiftDetails() {
    if (shiftDate == null || shiftTime == null) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        if (isUrgent)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  'URGENTE OPDRACHT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: DesignTokens.spacingS),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              _formatDate(shiftDate!),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              shiftTime!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
        if (totalEarnings != null) ...[
          const SizedBox(height: DesignTokens.spacingXS),
          Row(
            children: [
              Icon(Icons.euro, size: 14, color: Colors.green.shade600),
              const SizedBox(width: 4),
              Text(
                'Totaal: €${totalEarnings!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildHistoryDetails() {
    if (shiftDate == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Voltooid: ${_formatDate(shiftDate!)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (totalEarnings != null) ...[
            const Spacer(),
            Text(
              '€${totalEarnings!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildManagementStats() {
    // For company management view, show application stats
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.people, '${job.applicantCount ?? 0}', 'Sollicitanten'),
          _buildStatItem(Icons.visibility, '${job.viewCount ?? 0}', 'Bekeken'),
          _buildStatItem(Icons.star, job.rating?.toStringAsFixed(1) ?? 'N/A', 'Rating'),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.blue),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildContextActions() {
    switch (context) {
      case JobCardContext.discovery:
        if (!showApplicationButton) return const SizedBox.shrink();
        return JobCardActions(
          job: job,
          userRole: userRole,
          onApplyPressed: hasApplied ? null : onApplyPressed,
        );
      
      case JobCardContext.application:
        if (applicationStatus == 'pending' && onWithdraw != null) {
          return Padding(
            padding: const EdgeInsets.only(top: DesignTokens.spacingS),
            child: OutlinedButton.icon(
              onPressed: onWithdraw,
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Intrekken'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      
      case JobCardContext.activeShift:
        if (onViewShift != null) {
          return Padding(
            padding: const EdgeInsets.only(top: DesignTokens.spacingS),
            child: ElevatedButton.icon(
              onPressed: onViewShift,
              icon: const Icon(Icons.event_note, size: 16),
              label: const Text('Bekijk in Planning'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SecuryFlexTheme.getColorScheme(userRole).primary,
                foregroundColor: Colors.white,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      
      case JobCardContext.history:
      case JobCardContext.management:
      default:
        return const SizedBox.shrink();
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'in behandeling':
        return Colors.orange;
      case 'accepted':
      case 'geaccepteerd':
        return Colors.green;
      case 'rejected':
      case 'afgewezen':
        return Colors.red;
      case 'withdrawn':
      case 'ingetrokken':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'in behandeling':
        return Icons.hourglass_empty;
      case 'accepted':
      case 'geaccepteerd':
        return Icons.check_circle;
      case 'rejected':
      case 'afgewezen':
        return Icons.cancel;
      case 'withdrawn':
      case 'ingetrokken':
        return Icons.remove_circle;
      default:
        return Icons.info;
    }
  }
  
  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'In behandeling';
      case 'accepted':
        return 'Geaccepteerd';
      case 'rejected':
        return 'Afgewezen';
      case 'withdrawn':
        return 'Ingetrokken';
      default:
        return status;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Vandaag';
    } else if (difference == 1) {
      return 'Gisteren';
    } else if (difference < 7) {
      return '$difference dagen geleden';
    } else {
      return '${date.day}-${date.month}-${date.year}';
    }
  }
}

/// Compact image gallery for job cards
class JobCardImageGallery extends StatelessWidget {
  final List<JobImageData> images;
  final double height;

  const JobCardImageGallery({
    Key? key,
    required this.images,
    this.height = 120,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < images.length - 1 ? DesignTokens.spacingS : 0,
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: image.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.error_outline),
                      ),
                    ),
                    if (image.isPrimary)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'HOOFD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}