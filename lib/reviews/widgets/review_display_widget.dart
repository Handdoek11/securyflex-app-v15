import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import '../models/comprehensive_review_model.dart';

/// Widget to display a single review with glassmorphism design
class ReviewDisplayWidget extends StatelessWidget {
  final ComprehensiveJobReview review;
  final UserRole userRole;
  final VoidCallback? onRespond;
  final VoidCallback? onFlag;
  final bool showFullDetails;

  const ReviewDisplayWidget({
    super.key,
    required this.review,
    required this.userRole,
    this.onRespond,
    this.onFlag,
    this.showFullDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme),
                if (showFullDetails) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildRatingCategories(colorScheme),
                ],
                if (review.comment != null && review.comment!.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildComment(colorScheme),
                ],
                if (review.tags.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingS),
                  _buildTags(colorScheme),
                ],
                if (review.responseText != null) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildResponse(colorScheme),
                ],
                if (showFullDetails && 
                    (review.companyFields != null || review.guardFields != null)) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  _buildSpecificFields(colorScheme),
                ],
                SizedBox(height: DesignTokens.spacingM),
                _buildActions(context, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
          child: Text(
            review.isAnonymous ? '?' : review.reviewerId.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (review.isAnonymous)
                    Text(
                      'Anonieme ${review.reviewerType == ReviewerType.guard ? "Beveiliger" : "Bedrijf"}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  if (review.isVerified) ...[
                    SizedBox(width: DesignTokens.spacingXS),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: DesignTokens.colorSuccess,
                    ),
                  ],
                ],
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  _buildStarRating(review.overallRating, colorScheme),
                  SizedBox(width: DesignTokens.spacingS),
                  Text(
                    review.overallRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (review.status == ReviewStatus.edited)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              'Bewerkt',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingCategories(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Column(
        children: [
          _buildRatingRow('Communicatie', review.categories.communication, colorScheme),
          _buildRatingRow('Professionaliteit', review.categories.professionalism, colorScheme),
          _buildRatingRow('Betrouwbaarheid', review.categories.reliability, colorScheme),
          _buildRatingRow('Veiligheid', review.categories.safety, colorScheme),
          _buildRatingRow('Werkkwaliteit', review.categories.workQuality, colorScheme),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, double value, ColorScheme colorScheme) {
    if (value == 0) return SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildSmallStarRating(value, colorScheme),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(ColorScheme colorScheme) {
    return Text(
      review.comment!,
      style: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
    );
  }

  Widget _buildTags(ColorScheme colorScheme) {
    return Wrap(
      spacing: DesignTokens.spacingXS,
      runSpacing: DesignTokens.spacingXS,
      children: review.tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResponse(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 16,
                color: colorScheme.primary,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                'Reactie',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeCaption,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: colorScheme.primary,
                ),
              ),
              if (review.responseDate != null) ...[
                Spacer(),
                Text(
                  _formatDate(review.responseDate!),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            review.responseText!,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificFields(ColorScheme colorScheme) {
    if (review.companyFields != null) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bedrijfsbeoordeling',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            if (review.companyFields!.wouldWorkAgain)
              Row(
                children: [
                  Icon(
                    Icons.thumb_up,
                    size: 16,
                    color: DesignTokens.colorSuccess,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    'Zou weer voor dit bedrijf werken',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: DesignTokens.colorSuccess,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }
    
    if (review.guardFields != null) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beveiligerbeoordeling',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            if (review.guardFields!.wouldHireAgain)
              Row(
                children: [
                  Icon(
                    Icons.thumb_up,
                    size: 16,
                    color: DesignTokens.colorSuccess,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    'Zou deze beveiliger weer inhuren',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: DesignTokens.colorSuccess,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }
    
    return SizedBox.shrink();
  }

  Widget _buildActions(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        if (review.canRespond && onRespond != null)
          TextButton.icon(
            onPressed: onRespond,
            icon: Icon(
              Icons.reply,
              size: 16,
              color: colorScheme.primary,
            ),
            label: Text(
              'Reageren',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
          ),
        Spacer(),
        if (onFlag != null)
          IconButton(
            onPressed: onFlag,
            icon: Icon(
              Icons.flag_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
      ],
    );
  }

  Widget _buildStarRating(double rating, ColorScheme colorScheme) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Icon(
          starValue <= rating.round() ? Icons.star : Icons.star_border,
          size: 16,
          color: starValue <= rating.round()
              ? DesignTokens.colorSuccess
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        );
      }),
    );
  }

  Widget _buildSmallStarRating(double rating, ColorScheme colorScheme) {
    return Row(
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Icon(
          starValue <= rating.round() ? Icons.star : Icons.star_border,
          size: 12,
          color: starValue <= rating.round()
              ? DesignTokens.colorSuccess
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Widget to display review statistics summary
class ReviewStatsSummaryWidget extends StatelessWidget {
  final UserReviewStats stats;
  final UserRole userRole;

  const ReviewStatsSummaryWidget({
    super.key,
    required this.stats,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(userRole);

    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stats.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < stats.averageRating.round()
                                ? Icons.star
                                : Icons.star_border,
                            size: 20,
                            color: DesignTokens.colorSuccess,
                          );
                        }),
                      ),
                      Text(
                        '${stats.totalReviews} beoordelingen',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.spacingL),
              // Rating distribution bars
              ...stats.ratingDistribution.entries.map((entry) {
                final percentage = stats.totalReviews > 0
                    ? (entry.value / stats.totalReviews * 100)
                    : 0.0;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
                  child: Row(
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Icon(
                        Icons.star,
                        size: 12,
                        color: DesignTokens.colorSuccess,
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}