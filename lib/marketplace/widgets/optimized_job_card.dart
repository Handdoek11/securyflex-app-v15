import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../model/security_job_data.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../services/favorites_service.dart';

/// Optimized JobCard with maximum 8-level nesting depth for 60 FPS scrolling
/// 
/// Performance Optimizations:
/// - RepaintBoundary to isolate repaints
/// - const constructors where possible
/// - Extracted sub-components to reduce complexity  
/// - Eliminated unnecessary Container/Padding chains
/// - Optimized for ListView.builder performance
/// 
/// Reduces original 14-level nesting to 8 levels maximum
class OptimizedJobCard extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final List<String>? userCertificates;
  final bool showApplicationButton;
  final bool showFavoriteButton;
  final VoidCallback? onTap;
  final VoidCallback? onApplyPressed;

  const OptimizedJobCard({
    super.key,
    required this.job,
    this.userRole = UserRole.guard,
    this.userCertificates,
    this.showApplicationButton = true,
    this.showFavoriteButton = true,
    this.onTap,
    this.onApplyPressed,
  });

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary prevents parent widget rebuilds from affecting this card
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
            child: InkWell(
            onTap: null, // onTap handled by PremiumGlassContainer
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Padding(
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
                  if (userCertificates?.isNotEmpty == true)
                    JobCardCertificates(
                      job: job,
                      userCertificates: userCertificates!,
                    ),
                  if (showApplicationButton)
                    JobCardActions(
                      job: job,
                      userRole: userRole,
                      onApplyPressed: onApplyPressed,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

}

/// Extracted header component - optimized to 4 levels maximum
class JobCardHeader extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final bool showFavoriteButton;

  const JobCardHeader({
    super.key,
    required this.job,
    required this.userRole,
    required this.showFavoriteButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CompanyLogo(companyName: job.companyName, userRole: userRole),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: CompanyInfo(
            companyName: job.companyName,
            rating: job.companyRating,
            applicantCount: job.applicantCount,
            userRole: userRole,
          ),
        ),
        if (showFavoriteButton) 
          FavoriteButton(jobId: job.jobId, userRole: userRole),
      ],
    );
  }
}

/// Company logo component - optimized const widget
class CompanyLogo extends StatelessWidget {
  final String companyName;
  final UserRole userRole;

  const CompanyLogo({
    super.key,
    required this.companyName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Icon(
        Icons.business,
        color: colorScheme.primary,
        size: DesignTokens.iconSizeM,
      ),
    );
  }
}

/// Company info component - flattened structure
class CompanyInfo extends StatelessWidget {
  final String companyName;
  final double rating;
  final int applicantCount;
  final UserRole userRole;

  const CompanyInfo({
    super.key,
    required this.companyName,
    required this.rating,
    required this.applicantCount,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          companyName,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBodyLarge,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
            fontFamily: DesignTokens.fontFamily,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: DesignTokens.spacingXXS),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
              fontFamily: DesignTokens.fontFamily,
            ),
            children: [
              const WidgetSpan(
                child: Icon(
                  Icons.star,
                  size: 12,
                  color: DesignTokens.colorWarning,
                ),
              ),
              TextSpan(text: ' ${rating.toStringAsFixed(1)}'),
              TextSpan(text: ' • $applicantCount sollicitanten'),
            ],
          ),
        ),
      ],
    );
  }
}

/// Optimized favorite button with ValueListenableBuilder
class FavoriteButton extends StatelessWidget {
  final String jobId;
  final UserRole userRole;

  const FavoriteButton({
    super.key,
    required this.jobId,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService().favoriteJobIds,
      builder: (context, favoriteIds, child) {
        final isFavorite = favoriteIds.contains(jobId);
        final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
        
        return IconButton(
          onPressed: () => FavoritesService().toggleFavorite(jobId),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite 
                ? DesignTokens.colorError 
                : colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeM,
          ),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: const EdgeInsets.all(4),
        );
      },
    );
  }
}

/// Job details component - flattened information display
class JobCardDetails extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;

  const JobCardDetails({
    super.key,
    required this.job,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Job title
        Text(
          job.jobTitle,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
            fontFamily: DesignTokens.fontFamily,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: DesignTokens.spacingS),
        
        // Key details in optimized row
        Row(
          children: [
            DetailChip(
              icon: Icons.euro,
              text: '€${job.hourlyRate.toStringAsFixed(2)}/uur',
              color: DesignTokens.colorSuccess,
            ),
            const SizedBox(width: DesignTokens.spacingM),
            DetailChip(
              icon: Icons.access_time,
              text: '${job.duration}h',
              color: colorScheme.onSurfaceVariant,
            ),
            const Spacer(),
            DetailChip(
              icon: Icons.location_on,
              text: job.location,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

/// Optimized detail chip component
class DetailChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const DetailChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: DesignTokens.iconSizeS, color: color),
        const SizedBox(width: DesignTokens.spacingXXS),
        Text(
          text,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: color,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ],
    );
  }
}

/// Certificate matching component - optional display
class JobCardCertificates extends StatelessWidget {
  final SecurityJobData job;
  final List<String> userCertificates;

  const JobCardCertificates({
    super.key,
    required this.job,
    required this.userCertificates,
  });

  @override
  Widget build(BuildContext context) {
    final hasRequiredCerts = job.requiredCertificates
        .any((req) => userCertificates.contains(req));

    if (!hasRequiredCerts) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: DesignTokens.iconSizeS,
            color: DesignTokens.colorSuccess,
          ),
          const SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Certificaten matched',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: DesignTokens.colorSuccess,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action buttons component - BLoC integrated
class JobCardActions extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final VoidCallback? onApplyPressed;

  const JobCardActions({
    super.key,
    required this.job,
    required this.userRole,
    this.onApplyPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Try to get JobBloc if available, fallback to false for hasApplied
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    // Check if JobBloc is available before using BlocBuilder
    Widget buildContent(bool hasApplied) {
      return _buildActionContent(context, colorScheme, hasApplied);
    }
    
    // Try to read JobBloc - if not available, use default state
    try {
      final jobBloc = context.read<JobBloc>();
      return BlocBuilder<JobBloc, JobState>(
        bloc: jobBloc,
        builder: (context, state) {
          final hasApplied = state is JobLoaded && state.hasAppliedToJob(job.jobId);
          return buildContent(hasApplied);
        },
      );
    } on ProviderNotFoundException catch (_) {
      // JobBloc not provided - fallback to not applied state
      return buildContent(false);
    }
  }
  
  Widget _buildActionContent(BuildContext context, ColorScheme colorScheme, bool hasApplied) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spacingM),
      child: hasApplied
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.colorInfo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: DesignTokens.iconSizeS,
                    color: DesignTokens.colorInfo,
                  ),
                  const SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    'Gesolliciteerd',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: DesignTokens.colorInfo,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApplyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingS,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                ),
                child: Text(
                  'Solliciteren',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ),
            ),
    );
  }
}