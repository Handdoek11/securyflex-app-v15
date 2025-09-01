import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/guards/shared/guard_text_styles.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// Unified job components for consistent guard screen display
/// 
/// This library provides standardized job-related components that ensure
/// perfect design unity across all guard screens in SecuryFlex.
/// 
/// All components use:
/// - GuardTextStyles for consistent typography
/// - DesignTokens for spacing and colors
/// - Role-based theming for UserRole.guard
/// - UnifiedCard.standard for consistent card styling

/// Standardized job card component for marketplace and dashboard
class UnifiedJobCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String location;
  final double distance;
  final double hourlyRate;
  final double rating;
  final int reviewCount;
  final String? imagePath;
  final VoidCallback? onTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final bool hasApplied;

  const UnifiedJobCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.distance,
    required this.hourlyRate,
    required this.rating,
    required this.reviewCount,
    this.imagePath,
    this.onTap,
    this.showFavoriteButton = true,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.hasApplied = false,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.guard,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(DesignTokens.radiusL)),
        child: Stack(
          children: [
            Column(
              children: [
                // Job image section
                if (imagePath != null)
                  AspectRatio(
                    aspectRatio: 2,
                    child: Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                    ),
                  ),
                
                // Job details section
                Container(
                  color: SecuryFlexTheme.getColorScheme(UserRole.guard).surface,
                  child: Row(
                    children: [
                      // Main job information
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: DesignTokens.spacingM,
                            top: DesignTokens.spacingS,
                            bottom: DesignTokens.spacingS,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Job title
                              Text(
                                jobTitle,
                                style: GuardTextStyles.jobTitle(context),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              // Company name and location row
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      companyName,
                                      style: GuardTextStyles.jobCompany(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: DesignTokens.spacingXS),
                                  Icon(
                                    FontAwesomeIcons.locationDot,
                                    size: 12,
                                    color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${distance.toStringAsFixed(1)} km',
                                      style: GuardTextStyles.jobLocation(context),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Rating section
                              if (rating > 0) ...[
                                SizedBox(height: DesignTokens.spacingXS),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: rating,
                                      itemBuilder: (context, index) => Icon(
                                        Icons.star,
                                        color: SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
                                      ),
                                      itemCount: 5,
                                      itemSize: 16,
                                      unratedColor: DesignTokens.colorGray300,
                                    ),
                                    SizedBox(width: DesignTokens.spacingXS),
                                    Text(
                                      '$reviewCount reacties',
                                      style: GuardTextStyles.jobRating(context),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      // Salary section
                      Padding(
                        padding: EdgeInsets.only(
                          right: DesignTokens.spacingM,
                          top: DesignTokens.spacingS,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '€${hourlyRate.toStringAsFixed(2)}',
                              style: GuardTextStyles.jobSalary(context),
                            ),
                            Text(
                              '/per uur',
                              style: GuardTextStyles.jobSalaryUnit(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Application status badge
            if (hasApplied)
              Positioned(
                top: DesignTokens.spacingS,
                left: DesignTokens.spacingS,
                child: UnifiedJobStatusBadge(
                  status: JobApplicationStatus.applied,
                ),
              ),
            
            // Favorite button
            if (showFavoriteButton)
              Positioned(
                top: DesignTokens.spacingS,
                right: DesignTokens.spacingS,
                child: UnifiedJobFavoriteButton(
                  isFavorite: isFavorite,
                  onToggle: onFavoriteToggle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Job application status enumeration
enum JobApplicationStatus {
  applied,
  pending,
  accepted,
  rejected,
  withdrawn,
}

/// Unified status badge for job applications
class UnifiedJobStatusBadge extends StatelessWidget {
  final JobApplicationStatus status;

  const UnifiedJobStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late IconData icon;
    late String text;

    switch (status) {
      case JobApplicationStatus.applied:
        backgroundColor = DesignTokens.statusPending;
        icon = Icons.send;
        text = 'Gesolliciteerd';
        break;
      case JobApplicationStatus.pending:
        backgroundColor = DesignTokens.statusPending;
        icon = Icons.hourglass_empty;
        text = 'In behandeling';
        break;
      case JobApplicationStatus.accepted:
        backgroundColor = DesignTokens.statusCompleted;
        icon = Icons.check_circle;
        text = 'Geaccepteerd';
        break;
      case JobApplicationStatus.rejected:
        backgroundColor = DesignTokens.colorError;
        icon = Icons.cancel;
        text = 'Afgewezen';
        break;
      case JobApplicationStatus.withdrawn:
        backgroundColor = DesignTokens.colorGray500;
        icon = Icons.remove_circle;
        text = 'Ingetrokken';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.colorBlack.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: DesignTokens.colorWhite,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            text,
            style: GuardTextStyles.statusBadge(context),
          ),
        ],
      ),
    );
  }
}

/// Unified favorite button for job cards
class UnifiedJobFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;

  const UnifiedJobFavoriteButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        onTap: onToggle,
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: isFavorite
                ? colorScheme.primary.withValues(alpha: 0.1)
                : DesignTokens.colorWhite.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.colorBlack.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite 
                ? colorScheme.primary 
                : colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Unified job filter chip for consistent filter interface
class UnifiedJobFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const UnifiedJobFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
              color: isSelected
                  ? DesignTokens.colorWhite
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified job list item for applications and history screens
class UnifiedJobListItem extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String applicationDate;
  final JobApplicationStatus status;
  final VoidCallback? onTap;

  const UnifiedJobListItem({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.applicationDate,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: UserRole.guard,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            // Job information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jobTitle,
                    style: GuardTextStyles.jobTitle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    companyName,
                    style: GuardTextStyles.jobCompany(context),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Sollicitatie: $applicationDate',
                    style: GuardTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            
            // Status badge
            UnifiedJobStatusBadge(status: status),
          ],
        ),
      ),
    );
  }
}