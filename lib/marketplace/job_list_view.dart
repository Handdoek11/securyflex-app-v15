import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/guards/shared/guard_text_styles.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_routes.dart';

import 'model/security_job_data.dart';
import 'job_details_screen.dart';
import 'services/application_service.dart';
import 'services/favorites_service.dart';

class JobListView extends StatelessWidget {
  const JobListView({
    super.key,
    this.jobData,
    this.animationController,
    this.animation,
    this.callback,
    this.showFavoriteButton = true,
    this.isFavoriteScreen = false,
  });

  final VoidCallback? callback;
  final SecurityJobData? jobData;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final bool showFavoriteButton;
  final bool isFavoriteScreen;

  // Helper method to get consistent color scheme - changed to guard for blue theme
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation!,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 50 * (1.0 - animation!.value), 0.0),
            child: Padding(
              padding: EdgeInsets.only(
                  left: DesignTokens.spacingM,   // 16px - optimal mobile spacing
                  right: DesignTokens.spacingM,  // 16px - optimal mobile spacing  
                  top: DesignTokens.spacingS,    // 8px - vertical spacing
                  bottom: DesignTokens.spacingS), // 8px - vertical spacing
              child: PremiumGlassContainer(
                  intensity: GlassIntensity.standard,
                  elevation: GlassElevation.floating,
                  tintColor: _colorScheme.primary,
                  enableTrustBorder: true,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  padding: EdgeInsets.zero,
                  onTap: () {
                    context.go('${AppRoutes.beveiligerJobs}/${jobData?.id ?? 'unknown'}');
                    if (callback != null) callback!();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    child: Stack(
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            AspectRatio(
                              aspectRatio: 2,
                              child: Image.asset(
                                jobData!.imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          left: DesignTokens.spacingS,  // Compact inner padding
                                          top: DesignTokens.spacingS,   // Compact vertical space
                                          bottom: DesignTokens.spacingS),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            jobData!.titleTxt,
                                            textAlign: TextAlign.left,
                                            style: GuardTextStyles.jobTitle(context),
                                          ),
                                          Text(
                                            jobData!.subTxt,
                                            overflow: TextOverflow.ellipsis,
                                            style: GuardTextStyles.jobCompany(context),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.only(top: DesignTokens.spacingXS), // Minimal space before rating
                                            child: Row(
                                              children: <Widget>[
                                                RatingBar(
                                                  initialRating:
                                                      jobData!.rating,
                                                  direction: Axis.horizontal,
                                                  allowHalfRating: true,
                                                  itemCount: 5,
                                                  itemSize: 24,
                                                  ratingWidget: RatingWidget(
                                                    full: Icon(
                                                      Icons.star_rate_rounded,
                                                      color: _colorScheme.primary,
                                                    ),
                                                    half: Icon(
                                                      Icons.star_half_rounded,
                                                      color: _colorScheme.primary,
                                                    ),
                                                    empty: Icon(
                                                      Icons.star_border_rounded,
                                                      color: _colorScheme.primary,
                                                    ),
                                                  ),
                                                  itemPadding:
                                                      EdgeInsets.zero,
                                                  onRatingUpdate: (rating) {
                                                    // TODO: Replace with proper logging if needed
                                                  },
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    ' ${jobData!.reviews} reacties',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GuardTextStyles.jobRating(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        right: DesignTokens.spacingS,  // Compact right padding for salary
                                        top: DesignTokens.spacingS),   // Align with content padding
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: <Widget>[
                                        Text(
                                          '€${jobData!.perHour}',
                                          textAlign: TextAlign.left,
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
                          ],
                        ),
                        // Application status badge
                        _buildApplicationStatusBadge(jobData?.jobId ?? ''),
                        // Favorite button
                        if (showFavoriteButton)
                          _buildFavoriteButton(),
                        // Distance badge in bottom-right corner
                        _buildDistanceBadge(),
                      ],
                    ),
                  ),
                ),
              ),
          ),
            );
      },
    );
  }


  /// Build application status badge with async check
  Widget _buildApplicationStatusBadge(String jobId) {
    if (jobId.isEmpty) return SizedBox.shrink();

    return FutureBuilder<bool>(
      future: ApplicationService.hasAppliedForJob(jobId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink(); // Don't show anything while loading
        }

        if (snapshot.hasData && snapshot.data == true) {
          return Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.statusConfirmed.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
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
                    Icons.check_circle,
                    size: 14,
                    color: DesignTokens.colorWhite,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Gesolliciteerd',
                    style: GuardTextStyles.statusBadge(context),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox.shrink(); // Don't show badge if not applied
      },
    );
  }

  /// Build favorite button with real-time state updates
  Widget _buildFavoriteButton() {
    final favoritesService = FavoritesService();
    final jobId = jobData?.jobId ?? '';

    if (jobId.isEmpty) return SizedBox.shrink();

    return Positioned(
      top: 8,
      right: 8,
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: favoritesService.favoriteJobIds,
        builder: (context, favoriteIds, child) {
          final isFavorite = favoriteIds.contains(jobId);
          final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(32.0),
              onTap: () async {
                final success = await favoritesService.toggleFavorite(jobId);
                if (success && context.mounted) {
                  final message = isFavorite
                      ? 'Verwijderd uit favorieten'
                      : 'Toegevoegd aan favorieten';

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: Duration(seconds: 2),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: isFavorite
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : DesignTokens.colorWhite.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32.0),
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
                  color: isFavorite ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build distance badge in bottom-right corner
  Widget _buildDistanceBadge() {
    if (jobData == null) return SizedBox.shrink();

    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _colorScheme.primary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.colorBlack.withValues(alpha: 0.15),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.locationDot,
              size: 10,
              color: DesignTokens.colorWhite,
            ),
            SizedBox(width: 4),
            Text(
              '${jobData!.dist.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 11,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
