import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_buttons.dart';
import '../../unified_card_system.dart';
import '../../unified_theme_system.dart';
import '../../beveiliger_dashboard/widgets/mini_map_preview.dart';
import '../model/security_job_data.dart';
import '../services/certificate_matching_service.dart';
import '../services/postcode_service.dart';
import '../services/favorites_service.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../dialogs/application_dialog.dart';

/// JobCard met certificate match indicators en Nederlandse formatting
/// 
/// Comprehensive job card component with certificate compatibility indicators,
/// Dutch currency and date formatting, distance calculation, and application status.
/// Uses UnifiedCard system for consistent design and role-based theming.
class JobCard extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final List<String>? userCertificates;
  final String? userPostcode;
  final bool showApplicationButton;
  final bool showFavoriteButton;
  final bool isCompact;
  final VoidCallback? onTap;
  final VoidCallback? onApplyPressed;
  final VoidCallback? onFavoriteToggled;
  
  const JobCard({
    super.key,
    required this.job,
    this.userRole = UserRole.guard,
    this.userCertificates,
    this.userPostcode,
    this.showApplicationButton = true,
    this.showFavoriteButton = true,
    this.isCompact = false,
    this.onTap,
    this.onApplyPressed,
    this.onFavoriteToggled,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final hasApplied = state is JobLoaded && state.hasAppliedToJob(job.jobId);
        
        return UnifiedCard.standard(
          isClickable: onTap != null,
          onTap: onTap,
          userRole: userRole,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with company info and favorite button
              _buildHeader(context, hasApplied),
              
              SizedBox(height: DesignTokens.spacingM),
              
              // Job title and type
              _buildJobTitle(context),
              
              SizedBox(height: DesignTokens.spacingS),
              
              // Key details (salary, location, duration)
              _buildKeyDetails(context),
              
              SizedBox(height: DesignTokens.spacingM),
              
              // Certificate match indicators
              if (userCertificates != null && userCertificates!.isNotEmpty)
                _buildCertificateMatch(context),
              
              if (!isCompact) ...[
                SizedBox(height: DesignTokens.spacingM),
                
                // Job description preview
                _buildDescription(context),
                
                SizedBox(height: DesignTokens.spacingM),
                
                // Footer with stats and actions
                _buildFooter(context, hasApplied),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader(BuildContext context, bool hasApplied) {
    return Row(
      children: [
        // Company logo placeholder
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getThemeColors().surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            border: Border.all(
              color: _getThemeColors().outline,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.business,
            color: _getThemeColors().onSurfaceVariant,
            size: DesignTokens.iconSizeM,
          ),
        ),
        
        SizedBox(width: DesignTokens.spacingM),
        
        // Company info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.companyName,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBodyLarge,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: _getThemeColors().onSurface,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.colorWarning,
                  ),
                  SizedBox(width: DesignTokens.spacingXXS),
                  Text(
                    job.companyRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeMeta,
                      color: _getThemeColors().onSurfaceVariant,
                    ),
                  ),
                  Text(
                    ' • ${job.applicantCount} sollicitanten',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeMeta,
                      color: _getThemeColors().onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Status and actions
        Column(
          children: [
            // Application status indicator
            if (hasApplied)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.colorInfo,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  'GESOLLICITEERD',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.colorWhite,
                    letterSpacing: DesignTokens.letterSpacingWide,
                  ),
                ),
              ),
            
            if (showFavoriteButton) ...[
              if (hasApplied) SizedBox(height: DesignTokens.spacingXS),
              ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritesService().favoriteJobIds,
                builder: (context, favoriteIds, child) {
                  final isFavorite = favoriteIds.contains(job.jobId);
                  return UnifiedButton.icon(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    onPressed: () {
                      FavoritesService().toggleFavorite(job.jobId);
                      onFavoriteToggled?.call();
                    },
                    color: isFavorite 
                        ? DesignTokens.colorError 
                        : _getThemeColors().onSurfaceVariant,
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
  
  Widget _buildJobTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          job.jobTitle,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: _getThemeColors().onSurface,
            fontFamily: DesignTokens.fontFamily,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXXS,
          ),
          decoration: BoxDecoration(
            color: _getThemeColors().primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Text(
            job.jobType,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMeta,
              fontWeight: DesignTokens.fontWeightMedium,
              color: _getThemeColors().primary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildKeyDetails(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Salary
            Icon(
              Icons.euro,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.colorSuccess,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              '€${job.hourlyRate.toStringAsFixed(2)}/uur',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBodyLarge,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.colorSuccess,
              ),
            ),
            
            SizedBox(width: DesignTokens.spacingL),
            
            // Duration
            Icon(
              Icons.access_time,
              size: DesignTokens.iconSizeS,
              color: _getThemeColors().onSurfaceVariant,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              '${job.duration} uur',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: _getThemeColors().onSurfaceVariant,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        Row(
          children: [
            // Location with distance
            Icon(
              Icons.location_on,
              size: DesignTokens.iconSizeS,
              color: _getThemeColors().onSurfaceVariant,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Expanded(
              child: Text(
                job.location,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: _getThemeColors().onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Distance indicator
            if (userPostcode != null && userPostcode!.isNotEmpty)
              FutureBuilder<double>(
                future: _calculateDistance(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data! > 0) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getDistanceColor(snapshot.data!).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      ),
                      child: Text(
                        '${snapshot.data!.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeMeta,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: _getDistanceColor(snapshot.data!),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
        
        if (job.startDate != null) ...[
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: DesignTokens.iconSizeS,
                color: _getThemeColors().onSurfaceVariant,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                'Start: ${_formatDate(job.startDate!)}',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: _getThemeColors().onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildCertificateMatch(BuildContext context) {
    final matchResult = CertificateMatchingService.matchCertificates(
      userCertificates!,
      job.requiredCertificates,
    );
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: _getCertificateMatchColor(matchResult.matchScore).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getCertificateMatchColor(matchResult.matchScore).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match score header
          Row(
            children: [
              Icon(
                _getCertificateMatchIcon(matchResult.matchScore),
                size: DesignTokens.iconSizeS,
                color: _getCertificateMatchColor(matchResult.matchScore),
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                'Certificaat match: ${matchResult.matchScore}%',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeMeta,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: _getCertificateMatchColor(matchResult.matchScore),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXXS,
                ),
                decoration: BoxDecoration(
                  color: _getCertificateMatchColor(matchResult.matchScore),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  matchResult.eligibilityDescription,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.colorWhite,
                  ),
                ),
              ),
            ],
          ),
          
          // Required certificates
          if (job.requiredCertificates.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Vereiste certificaten:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeMeta,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getThemeColors().onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Wrap(
              spacing: DesignTokens.spacingXS,
              runSpacing: DesignTokens.spacingXXS,
              children: job.requiredCertificates.map((cert) {
                final hasThis = matchResult.matchedCertificates.contains(cert);
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXXS,
                  ),
                  decoration: BoxDecoration(
                    color: hasThis 
                        ? DesignTokens.colorSuccess.withValues(alpha: 0.1)
                        : DesignTokens.colorError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    border: Border.all(
                      color: hasThis 
                          ? DesignTokens.colorSuccess.withValues(alpha: 0.3)
                          : DesignTokens.colorError.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasThis ? Icons.check_circle : Icons.cancel,
                        size: DesignTokens.iconSizeXS,
                        color: hasThis ? DesignTokens.colorSuccess : DesignTokens.colorError,
                      ),
                      SizedBox(width: DesignTokens.spacingXXS),
                      Text(
                        cert,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeXS,
                          color: hasThis ? DesignTokens.colorSuccess : DesignTokens.colorError,
                          fontWeight: DesignTokens.fontWeightMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Omschrijving',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeMeta,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: _getThemeColors().onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          job.description,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: _getThemeColors().onSurfaceVariant,
            height: DesignTokens.lineHeightNormal,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildFooter(BuildContext context, bool hasApplied) {
    return Row(
      children: [
        // Job statistics
        if (!hasApplied) ...[
          Icon(
            Icons.people_outline,
            size: DesignTokens.iconSizeS,
            color: _getThemeColors().onSurfaceVariant,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            '${job.applicantCount} sollicitanten',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMeta,
              color: _getThemeColors().onSurfaceVariant,
            ),
          ),
          
          SizedBox(width: DesignTokens.spacingM),
          
          // Posted time ago
          Text(
            _getTimeAgoText(),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMeta,
              color: _getThemeColors().onSurfaceVariant,
            ),
          ),
        ],
        
        Spacer(),
        
        // Action button
        if (showApplicationButton)
          UnifiedButton.primary(
            text: hasApplied ? 'Gesolliciteerd' : 'Solliciteer nu',
            onPressed: hasApplied ? () {} : () => _showApplicationDialog(context),
            backgroundColor: hasApplied 
                ? _getThemeColors().surfaceContainerHighest
                : _getThemeColors().primary,
            size: UnifiedButtonSize.small,
          ),
      ],
    );
  }
  
  // Helper methods
  Future<double> _calculateDistance() async {
    if (userPostcode == null || userPostcode!.isEmpty) return 0.0;
    
    // Extract postcode from job location (simplified)
    final regex = RegExp(r'(\d{4}\s?[A-Z]{2})');
    final match = regex.firstMatch(job.location);
    if (match == null) return 0.0;
    
    final jobPostcode = match.group(1)!;
    return await PostcodeService.calculateDistance(userPostcode!, jobPostcode);
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  String _getTimeAgoText() {
    if (job.startDate == null) return 'Nieuw';
    
    final now = DateTime.now();
    final difference = job.startDate!.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} dagen';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} uur';
    } else {
      return 'Nu';
    }
  }
  
  Color _getDistanceColor(double distance) {
    if (distance <= 5) return DesignTokens.colorSuccess;
    if (distance <= 15) return DesignTokens.colorWarning;
    return DesignTokens.colorError;
  }
  
  Color _getCertificateMatchColor(int matchScore) {
    if (matchScore >= 90) return DesignTokens.colorSuccess;
    if (matchScore >= 70) return DesignTokens.colorInfo;
    if (matchScore >= 50) return DesignTokens.colorWarning;
    return DesignTokens.colorError;
  }
  
  IconData _getCertificateMatchIcon(int matchScore) {
    if (matchScore >= 90) return Icons.verified;
    if (matchScore >= 70) return Icons.check_circle;
    if (matchScore >= 50) return Icons.info;
    return Icons.warning;
  }
  
  void _showApplicationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ApplicationDialog(
        jobData: job,
      ),
    );
  }
  
  ColorScheme _getThemeColors() {
    return SecuryFlexTheme.getColorScheme(userRole);
  }
}