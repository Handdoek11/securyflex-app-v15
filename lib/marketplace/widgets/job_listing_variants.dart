import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import '../model/security_job_data.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_state.dart';
import '../services/favorites_service.dart';
import '../services/filter_persistence_service.dart'; // Import for JobViewType

/// Compact job listing item for dense view with essential information only
/// Optimized for high-density scrolling with minimal vertical space usage
class CompactJobListItem extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onApplyPressed;
  final bool showFavoriteButton;
  
  const CompactJobListItem({
    super.key,
    required this.job,
    this.userRole = UserRole.guard,
    this.onTap,
    this.onApplyPressed,
    this.showFavoriteButton = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXS / 2,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingM,
                vertical: DesignTokens.spacingS,
              ),
              child: Row(
                children: [
                  // Company avatar (smaller)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Icon(
                      Icons.business,
                      color: colorScheme.primary,
                      size: DesignTokens.iconSizeS,
                    ),
                  ),
                  
                  const SizedBox(width: DesignTokens.spacingS),
                  
                  // Job info (expanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Job title and hourly rate
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                job.jobTitle,
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontWeight: DesignTokens.fontWeightSemiBold,
                                  fontSize: DesignTokens.fontSizeBody,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spacingS),
                            Text(
                              '€${job.hourlyRate.toStringAsFixed(2)}/u',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: DesignTokens.fontWeightBold,
                                fontSize: DesignTokens.fontSizeBody,
                                color: DesignTokens.colorSuccess,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: DesignTokens.spacingXXS),
                        
                        // Company, location, duration
                        Text(
                          '${job.companyName} • ${job.location} • ${job.duration}h',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightRegular,
                            fontSize: DesignTokens.fontSizeCaption,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showFavoriteButton) ...[
                        _CompactFavoriteButton(
                          jobId: job.jobId,
                          userRole: userRole,
                        ),
                        const SizedBox(width: DesignTokens.spacingXS),
                      ],
                      _CompactApplyButton(
                        job: job,
                        userRole: userRole,
                        onApplyPressed: onApplyPressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dense job listing item with two-line layout for balanced density
/// Shows more information than compact but less than full card view
class DenseJobListItem extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final VoidCallback? onTap;
  final VoidCallback? onApplyPressed;
  final bool showFavoriteButton;
  final List<String>? userCertificates;
  
  const DenseJobListItem({
    super.key,
    required this.job,
    this.userRole = UserRole.guard,
    this.onTap,
    this.onApplyPressed,
    this.showFavoriteButton = true,
    this.userCertificates,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
    final hasMatchingCerts = userCertificates != null && 
        job.requiredCertificates.any((cert) => userCertificates!.contains(cert));
    
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXS,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row: Company info + Actions
                  Row(
                    children: [
                      // Company avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: Icon(
                          Icons.business,
                          color: colorScheme.primary,
                          size: DesignTokens.iconSizeS,
                        ),
                      ),
                      
                      const SizedBox(width: DesignTokens.spacingS),
                      
                      // Company name and rating
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              job.companyName,
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontWeight: DesignTokens.fontWeightSemiBold,
                                fontSize: DesignTokens.fontSizeBody,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 12,
                                  color: DesignTokens.colorWarning,
                                ),
                                const SizedBox(width: DesignTokens.spacingXXS),
                                Text(
                                  '${job.companyRating.toStringAsFixed(1)} • ${job.applicantCount} sollicitanten',
                                  style: TextStyle(
                                    fontFamily: DesignTokens.fontFamily,
                                    fontWeight: DesignTokens.fontWeightRegular,
                                    fontSize: DesignTokens.fontSizeCaption,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Actions
                      if (showFavoriteButton)
                        _CompactFavoriteButton(
                          jobId: job.jobId,
                          userRole: userRole,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: DesignTokens.spacingS),
                  
                  // Job title
                  Text(
                    job.jobTitle,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      fontSize: DesignTokens.fontSizeBodyLarge,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: DesignTokens.spacingXS),
                  
                  // Details row
                  Row(
                    children: [
                      // Hourly rate
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingXXS,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                        ),
                        child: Text(
                          '€${job.hourlyRate.toStringAsFixed(2)}/uur',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightBold,
                            fontSize: DesignTokens.fontSizeCaption,
                            color: DesignTokens.colorSuccess,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: DesignTokens.spacingS),
                      
                      // Location and duration
                      Expanded(
                        child: Text(
                          '${job.location} • ${job.duration}h • ${job.distance.toStringAsFixed(1)}km',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightRegular,
                            fontSize: DesignTokens.fontSizeCaption,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Certificate match indicator
                      if (hasMatchingCerts)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingXS,
                            vertical: DesignTokens.spacingXXS,
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
                                size: 10,
                                color: DesignTokens.colorSuccess,
                              ),
                              const SizedBox(width: DesignTokens.spacingXXS),
                              Text(
                                'Match',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontWeight: DesignTokens.fontWeightMedium,
                                  fontSize: DesignTokens.fontSizeCaption,
                                  color: DesignTokens.colorSuccess,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(width: DesignTokens.spacingS),
                      
                      // Apply button
                      _DenseApplyButton(
                        job: job,
                        userRole: userRole,
                        onApplyPressed: onApplyPressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact favorite button for space-efficient layouts
class _CompactFavoriteButton extends StatelessWidget {
  final String jobId;
  final UserRole userRole;
  
  const _CompactFavoriteButton({
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
        
        return InkWell(
          onTap: () => FavoritesService().toggleFavorite(jobId),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingXS),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite 
                  ? DesignTokens.colorError 
                  : colorScheme.onSurfaceVariant,
              size: DesignTokens.iconSizeS,
            ),
          ),
        );
      },
    );
  }
}

/// Compact apply button for single-line layouts
class _CompactApplyButton extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final VoidCallback? onApplyPressed;
  
  const _CompactApplyButton({
    required this.job,
    required this.userRole,
    this.onApplyPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final hasApplied = state is JobLoaded && state.hasAppliedToJob(job.jobId);
        final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
        
        if (hasApplied) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.colorInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(
                color: DesignTokens.colorInfo.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check,
                  size: 12,
                  color: DesignTokens.colorInfo,
                ),
                const SizedBox(width: DesignTokens.spacingXXS),
                Text(
                  'Toegepast',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.colorInfo,
                  ),
                ),
              ],
            ),
          );
        }
        
        return InkWell(
          onTap: onApplyPressed,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              'Solliciteren',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dense apply button for two-line layouts
class _DenseApplyButton extends StatelessWidget {
  final SecurityJobData job;
  final UserRole userRole;
  final VoidCallback? onApplyPressed;
  
  const _DenseApplyButton({
    required this.job,
    required this.userRole,
    this.onApplyPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final hasApplied = state is JobLoaded && state.hasAppliedToJob(job.jobId);
        final colorScheme = SecuryFlexTheme.getColorScheme(userRole);
        
        if (hasApplied) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.colorInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.colorInfo.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
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
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.colorInfo,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ElevatedButton(
          onPressed: onApplyPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingXS,
            ),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
            elevation: 0,
          ),
          child: Text(
            'Solliciteren',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeCaption,
            ),
          ),
        );
      },
    );
  }
}

/// Job list wrapper that adapts layout based on view type
class AdaptiveJobList extends StatelessWidget {
  final List<SecurityJobData> jobs;
  final JobViewType viewType;
  final UserRole userRole;
  final VoidCallback? onRefresh;
  final Function(SecurityJobData)? onJobTap;
  final Function(SecurityJobData)? onApplyPressed;
  final List<String>? userCertificates;
  final ScrollController? scrollController;
  
  const AdaptiveJobList({
    super.key,
    required this.jobs,
    required this.viewType,
    this.userRole = UserRole.guard,
    this.onRefresh,
    this.onJobTap,
    this.onApplyPressed,
    this.userCertificates,
    this.scrollController,
  });
  
  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return _buildEmptyState();
    }
    
    Widget listWidget;
    
    switch (viewType) {
      case JobViewType.compact:
        listWidget = ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return CompactJobListItem(
              job: job,
              userRole: userRole,
              onTap: () => onJobTap?.call(job),
              onApplyPressed: () => onApplyPressed?.call(job),
            );
          },
        );
        break;
        
      case JobViewType.list:
        listWidget = ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return DenseJobListItem(
              job: job,
              userRole: userRole,
              userCertificates: userCertificates,
              onTap: () => onJobTap?.call(job),
              onApplyPressed: () => onApplyPressed?.call(job),
            );
          },
        );
        break;
        
      case JobViewType.card:
      default:
        // Import and use existing OptimizedJobCard
        listWidget = ListView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return RepaintBoundary(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                child: Text('Card view placeholder for job: ${job.jobTitle}'),
              ),
            );
          },
        );
    }
    
    return onRefresh != null
        ? RefreshIndicator(
            onRefresh: () async => onRefresh?.call(),
            child: listWidget,
          )
        : listWidget;
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.work_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Text(
            'Geen opdrachten gevonden',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeBodyLarge,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            'Probeer andere zoekfilters of kom later terug',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeBody,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}