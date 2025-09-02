import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui' as ui;
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import '../models/comprehensive_review_model.dart';
import '../bloc/review_bloc.dart';

/// Review submission screen for guards and companies
/// Follows SecuryFlex design system with glassmorphism
class SubmitReviewScreen extends StatefulWidget {
  final String workflowId;
  final String jobId;
  final String revieweeId;
  final String revieweeName;
  final ReviewerType reviewerType;
  final UserRole userRole;
  final DateTime? shiftDate;

  const SubmitReviewScreen({
    super.key,
    required this.workflowId,
    required this.jobId,
    required this.revieweeId,
    required this.revieweeName,
    required this.reviewerType,
    required this.userRole,
    this.shiftDate,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  final _commentController = TextEditingController();
  
  // Core rating categories
  double _communicationRating = 0;
  double _professionalismRating = 0;
  double _reliabilityRating = 0;
  double _safetyRating = 0;
  double _workQualityRating = 0;

  // Company-specific fields (when guard reviews company)
  double _paymentTimelinessRating = 0;
  double _workEnvironmentRating = 0;
  double _equipmentQualityRating = 0;
  double _jobDescriptionRating = 0;
  bool _wouldWorkAgain = false;

  // Guard-specific fields (when company reviews guard)
  double _punctualityRating = 0;
  double _appearanceRating = 0;
  double _followsInstructionsRating = 0;
  double _teamworkRating = 0;
  bool _wouldHireAgain = false;

  // Review settings
  bool _isAnonymous = false;
  final List<String> _selectedTags = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);

    return BlocProvider(
      create: (context) => ReviewBloc(),
      child: BlocConsumer<ReviewBloc, ReviewState>(
        listener: (context, state) {
          if (state is ReviewSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Review succesvol ingediend'),
                backgroundColor: DesignTokens.colorSuccess,
              ),
            );
            context.pop(true);
          } else if (state is ReviewError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: Text(
                'Beoordeling ${widget.reviewerType == ReviewerType.guard ? "Bedrijf" : "Beveiliger"}',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.05),
                        colorScheme.secondary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                // Content
                SingleChildScrollView(
                  padding: EdgeInsets.all(DesignTokens.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRevieweeInfo(colorScheme),
                      SizedBox(height: DesignTokens.spacingL),
                      _buildCoreRatings(colorScheme),
                      SizedBox(height: DesignTokens.spacingL),
                      if (widget.reviewerType == ReviewerType.guard)
                        _buildCompanySpecificRatings(colorScheme)
                      else
                        _buildGuardSpecificRatings(colorScheme),
                      SizedBox(height: DesignTokens.spacingL),
                      _buildCommentSection(colorScheme),
                      SizedBox(height: DesignTokens.spacingL),
                      _buildTagsSection(colorScheme),
                      SizedBox(height: DesignTokens.spacingL),
                      _buildPrivacySettings(colorScheme),
                      SizedBox(height: DesignTokens.spacingXL),
                      _buildSubmitButton(context, state, colorScheme),
                    ],
                  ),
                ),
                if (state is ReviewLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevieweeInfo(ColorScheme colorScheme) {
    return _buildGlassContainer(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
            child: Text(
              widget.revieweeName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.revieweeName,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (widget.shiftDate != null)
                  Text(
                    'Dienst: ${_formatDate(widget.shiftDate!)}',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreRatings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Algemene Beoordeling', colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildGlassContainer(
          child: Column(
            children: [
              _buildRatingRow(
                'Communicatie',
                _communicationRating,
                (value) => setState(() => _communicationRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Professionaliteit',
                _professionalismRating,
                (value) => setState(() => _professionalismRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Betrouwbaarheid',
                _reliabilityRating,
                (value) => setState(() => _reliabilityRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Veiligheid',
                _safetyRating,
                (value) => setState(() => _safetyRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Werkkwaliteit',
                _workQualityRating,
                (value) => setState(() => _workQualityRating = value),
                colorScheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanySpecificRatings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bedrijfsbeoordeling', colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildGlassContainer(
          child: Column(
            children: [
              _buildRatingRow(
                'Betalingssnelheid',
                _paymentTimelinessRating,
                (value) => setState(() => _paymentTimelinessRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Werkomgeving',
                _workEnvironmentRating,
                (value) => setState(() => _workEnvironmentRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Kwaliteit Uitrusting',
                _equipmentQualityRating,
                (value) => setState(() => _equipmentQualityRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Opdracht Beschrijving',
                _jobDescriptionRating,
                (value) => setState(() => _jobDescriptionRating = value),
                colorScheme,
              ),
              Padding(
                padding: EdgeInsets.only(top: DesignTokens.spacingM),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Zou je weer voor dit bedrijf werken?',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: _wouldWorkAgain,
                      onChanged: (value) => setState(() => _wouldWorkAgain = value),
                      activeThumbColor: colorScheme.primary,
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

  Widget _buildGuardSpecificRatings(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Beveiligerbeoordeling', colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildGlassContainer(
          child: Column(
            children: [
              _buildRatingRow(
                'Stiptheid',
                _punctualityRating,
                (value) => setState(() => _punctualityRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Presentatie',
                _appearanceRating,
                (value) => setState(() => _appearanceRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Opvolgen Instructies',
                _followsInstructionsRating,
                (value) => setState(() => _followsInstructionsRating = value),
                colorScheme,
              ),
              _buildRatingRow(
                'Teamwerk',
                _teamworkRating,
                (value) => setState(() => _teamworkRating = value),
                colorScheme,
              ),
              Padding(
                padding: EdgeInsets.only(top: DesignTokens.spacingM),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Zou je deze beveiliger weer inhuren?',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: _wouldHireAgain,
                      onChanged: (value) => setState(() => _wouldHireAgain = value),
                      activeThumbColor: colorScheme.primary,
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

  Widget _buildCommentSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Opmerkingen (Optioneel)', colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildGlassContainer(
          child: TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Deel je ervaring...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              counterStyle: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: DesignTokens.fontSizeCaption,
              ),
            ),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(ColorScheme colorScheme) {
    final availableTags = widget.reviewerType == ReviewerType.guard
        ? ['Op tijd betaald', 'Duidelijke instructies', 'Goede faciliteiten', 
           'Professioneel', 'Aanrader', 'Veilige werkomgeving']
        : ['Stipt', 'Professioneel', 'Betrouwbaar', 'Goede communicatie',
           'Flexibel', 'Aanrader'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Tags (Optioneel)', colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        _buildGlassContainer(
          child: Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
                selectedColor: colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySettings(ColorScheme colorScheme) {
    return _buildGlassContainer(
      child: Row(
        children: [
          Icon(
            Icons.privacy_tip_outlined,
            size: DesignTokens.iconSizeM,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Text(
              'Anonieme beoordeling',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) => setState(() => _isAnonymous = value),
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    ReviewState state,
    ColorScheme colorScheme,
  ) {
    final isValid = _validateReview();

    return SizedBox(
      width: double.infinity,
      child: UnifiedButton.primary(
        text: 'Beoordeling Indienen',
        onPressed: isValid && state is! ReviewLoading
            ? () => _submitReview(context)
            : () {},
        size: UnifiedButtonSize.large,
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double value,
    ValueChanged<double> onChanged,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Row(
            children: List.generate(5, (index) {
              final rating = index + 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(rating.toDouble()),
                  child: Icon(
                    rating <= value ? Icons.star : Icons.star_border,
                    color: rating <= value
                        ? DesignTokens.colorSuccess
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
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
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeTitle,
        fontWeight: DesignTokens.fontWeightBold,
        color: colorScheme.onSurface,
      ),
    );
  }

  bool _validateReview() {
    // At least one rating must be provided
    return _communicationRating > 0 ||
        _professionalismRating > 0 ||
        _reliabilityRating > 0 ||
        _safetyRating > 0 ||
        _workQualityRating > 0;
  }

  void _submitReview(BuildContext context) {
    final categories = ReviewCategories(
      communication: _communicationRating,
      professionalism: _professionalismRating,
      reliability: _reliabilityRating,
      safety: _safetyRating,
      workQuality: _workQualityRating,
    );

    final review = ComprehensiveJobReview(
      id: '', // Will be generated by Firestore
      workflowId: widget.workflowId,
      jobId: widget.jobId,
      reviewerId: AuthService.currentUserId,
      revieweeId: widget.revieweeId,
      reviewerType: widget.reviewerType,
      categories: categories,
      overallRating: categories.averageRating,
      comment: _commentController.text.isNotEmpty ? _commentController.text : null,
      tags: _selectedTags,
      createdAt: DateTime.now(),
      shiftDate: widget.shiftDate,
      isAnonymous: _isAnonymous,
      companyFields: widget.reviewerType == ReviewerType.guard
          ? CompanyReviewFields(
              paymentTimeliness: _paymentTimelinessRating,
              workEnvironment: _workEnvironmentRating,
              equipmentQuality: _equipmentQualityRating,
              jobDescription: _jobDescriptionRating,
              wouldWorkAgain: _wouldWorkAgain,
            )
          : null,
      guardFields: widget.reviewerType == ReviewerType.company
          ? GuardReviewFields(
              punctuality: _punctualityRating,
              appearance: _appearanceRating,
              followsInstructions: _followsInstructionsRating,
              teamwork: _teamworkRating,
              wouldHireAgain: _wouldHireAgain,
            )
          : null,
    );

    context.read<ReviewBloc>().add(SubmitReview(review: review));
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }
}