import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart' hide GlassIntensity;
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import 'dialogs/premium_application_dialog.dart';
import 'model/security_job_data.dart';
import 'services/application_service.dart';
import 'services/favorites_service.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key, this.jobData});

  final SecurityJobData? jobData;

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  bool isApplied = false;

  // Helper method to get consistent color scheme - should be Guard role for marketplace
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    // Check if user has already applied for this job
    _checkApplicationStatus();
    super.initState();
  }

  /// Check if user has already applied for this job
  Future<void> _checkApplicationStatus() async {
    if (widget.jobData != null) {
      try {
        final hasApplied = await ApplicationService.hasAppliedForJob(widget.jobData!.jobId);
        if (mounted) {
          setState(() {
            isApplied = hasApplied;
          });
        }
      } catch (e) {
        debugPrint('Error checking application status: $e');
      }
    }
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              getAppBarUI(),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          getJobImageUI(),
                          getJobDetailsUI(),
                          const SizedBox(height: 80), // Space for apply button
                        ],
                      ),
                    ),
                    getApplyButtonUI(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getJobImageUI() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Image.asset(
        widget.jobData!.companyLogo,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget getJobDetailsUI() {
    return PremiumGlassContainer(
      intensity: GlassIntensity.standard,
      elevation: GlassElevation.floating,
      tintColor: _colorScheme.primary,
      enableTrustBorder: true,
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          // Job Header Section
          Padding(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.jobData!.jobTitle,
                        style: TextStyle(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeHeading,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          '€${widget.jobData!.hourlyRate.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeHeading,
                            color: _colorScheme.primary,
                          ),
                        ),
                        Text(
                          '/per uur',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            fontFamily: DesignTokens.fontFamily,
                            color: DesignTokens.guardTextSecondary, // ✅ Design token
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.jobData!.companyName,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                    color: DesignTokens.guardTextSecondary, // ✅ Design token
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(
                      FontAwesomeIcons.locationDot,
                      size: 16,
                      color: _colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.jobData!.location,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.guardTextSecondary, // ✅ Design token
                        ),
                      ),
                    ),
                    Text(
                      '${widget.jobData!.distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 14,
                        color: DesignTokens.guardTextSecondary, // ✅ Design token
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    RatingBar(
                      initialRating: widget.jobData!.companyRating,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 20,
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
                      itemPadding: EdgeInsets.zero,
                      onRatingUpdate: (rating) {},
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.jobData!.applicantCount} reacties',
                      style: TextStyle(
                        fontSize: 14,
                        color: DesignTokens.guardTextSecondary, // ✅ Design token
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Job Info Cards
          getJobInfoCardsUI(),
          const Divider(height: 1),
          // Required Certificates
          getRequiredCertificatesUI(),
          const Divider(height: 1),
          // Job Description
          getJobDescriptionUI(),
            ],
          ),
        );
  }

  Widget getJobInfoCardsUI() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Opdracht details',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildInfoCard(
                  'Start datum',
                  widget.jobData!.startDate != null
                      ? DateFormat('dd MMM yyyy').format(widget.jobData!.startDate!)
                      : 'Direct beschikbaar',
                  Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Duur',
                  '${widget.jobData!.duration} uur',
                  Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildInfoCard(
                  'Type opdracht',
                  widget.jobData!.jobType,
                  Icons.work,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  'Reacties',
                  '${widget.jobData!.applicantCount}',
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingS + DesignTokens.spacingXS), // 12px
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,  // Consistent with job cards
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 16,
                    color: _colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.guardTextSecondary, // ✅ Design token
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getRequiredCertificatesUI() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Vereiste certificaten',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.jobData!.requiredCertificates.map((certificate) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  border: Border.all(
                    color: _colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  certificate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                    color: _colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget getJobDescriptionUI() {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Omschrijving',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.jobData!.description,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: DesignTokens.guardTextSecondary, // ✅ Design token
            ),
          ),
        ],
      ),
    );
  }

  Widget getAppBarUI() {
    return UnifiedHeader.simple(
      title: 'Opdracht details',
      titleAlignment: TextAlign.center, // Modal-style detail screen
      userRole: UserRole.guard,
      leading: HeaderElements.backButton(
        onPressed: () => context.pop(),
        userRole: UserRole.guard,
      ),
      actions: [_buildFavoriteButton()],
    );
  }

  Widget getApplyButtonUI() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              _colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingM,
            right: DesignTokens.spacingM,
            bottom: MediaQuery.of(context).padding.bottom + DesignTokens.spacingM,
            top: DesignTokens.spacingM,
          ),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isApplied
                  ? DesignTokens.colorGray400 // ✅ Design token voor disabled state
                  : _colorScheme.primary,
              borderRadius: const BorderRadius.all(Radius.circular(24.0)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: DesignTokens.colorGray400.withValues(alpha: 0.3), // ✅ Design token
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent, // ✅ Transparant voor InkWell effect
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(24.0)),
                highlightColor: Colors.transparent, // ✅ Transparant voor custom highlight
                onTap: isApplied ? null : () => _showApplicationDialog(),
                child: Center(
                  child: Text(
                    isApplied ? 'Sollicitatie verzonden' : 'Solliciteer',
                    style: TextStyle(
                      fontWeight: DesignTokens.fontWeightMedium,
                    fontFamily: DesignTokens.fontFamily,
                      fontSize: 18,
                      color: DesignTokens.colorWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showApplicationDialog() async {
    if (widget.jobData == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PremiumApplicationDialog(jobData: widget.jobData!);
      },
    );

    if (result == true) {
      setState(() {
        isApplied = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: DesignTokens.colorWhite),
                SizedBox(width: 8),
                Text('Sollicitatie succesvol verzonden!'),
              ],
            ),
            backgroundColor: DesignTokens.statusConfirmed.withValues(alpha: 0.6),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Build favorite button with real-time state updates
  Widget _buildFavoriteButton() {
    final favoritesService = FavoritesService();
    final jobId = widget.jobData?.jobId ?? '';

    if (jobId.isEmpty) return SizedBox.shrink();

    return ValueListenableBuilder<Set<String>>(
      valueListenable: favoritesService.favoriteJobIds,
      builder: (context, favoriteIds, child) {
        final isFavorite = favoriteIds.contains(jobId);
        final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

        return Material(
          color: Colors.transparent, // ✅ Transparant voor InkWell effect
          child: InkWell(
            borderRadius: BorderRadius.circular(32.0),
            onTap: () async {
              final success = await favoritesService.toggleFavorite(jobId);
              if (success && mounted) {
                final message = isFavorite
                    ? 'Verwijderd uit favorieten'
                    : 'Toegevoegd aan favorieten';

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: Duration(seconds: 2),
                      backgroundColor: colorScheme.primary,
                    ),
                  );
                }
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
    );
  }
}