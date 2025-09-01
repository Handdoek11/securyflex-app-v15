import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/unified_components.dart';
import '../bloc/job_completion_bloc.dart';
import '../models/job_workflow_models.dart';
import '../localization/job_completion_rating_nl.dart';

/// Comprehensive Job Completion Review Interface
/// 
/// Enhanced review interface with category-based ratings following SecuryFlex patterns.
/// Integrates with existing JobCompletionRatingService and uses unified design system.
/// 
/// Features:
/// - Category-based rating (communication, punctuality, professionalism, overall satisfaction)
/// - Individual star ratings for each category
/// - Comment section with character limits
/// - Role-based theming (Guard vs Company perspectives)
/// - Submission validation and loading states
/// - Dutch localization throughout
class ComprehensiveJobReviewInterface extends StatefulWidget {
  final String jobId;
  final String workflowId;
  final String raterId;
  final String raterRole; // 'guard' or 'company'
  final JobWorkflow? workflow;
  final VoidCallback? onReviewSubmitted;
  final bool isReadOnly;
  
  const ComprehensiveJobReviewInterface({
    super.key,
    required this.jobId,
    required this.workflowId,
    required this.raterId,
    required this.raterRole,
    this.workflow,
    this.onReviewSubmitted,
    this.isReadOnly = false,
  });

  @override
  State<ComprehensiveJobReviewInterface> createState() => 
      _ComprehensiveJobReviewInterfaceState();
}

class _ComprehensiveJobReviewInterfaceState 
    extends State<ComprehensiveJobReviewInterface>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final Map<String, double> _categoryRatings = {
    'communication': 0.0,
    'punctuality': 0.0,
    'professionalism': 0.0,
    'overall': 0.0,
  };
  
  String _comments = '';
  bool _isSubmitting = false;
  final _commentsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobCompletionBloc, JobCompletionState>(
      listener: (context, state) {
        if (state is JobCompletionInProgress && 
            state.currentState == JobWorkflowState.rated) {
          _onReviewSubmitted();
        } else if (state is JobCompletionError) {
          _showErrorSnackBar(context, state.message);
        }
      },
      child: _buildReviewInterface(context),
    );
  }

  Widget _buildReviewInterface(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.raterRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildHeaderCard(context, colorScheme),
              SizedBox(height: DesignTokens.spacingM),
              _buildCategoryRatingsCard(context, colorScheme),
              SizedBox(height: DesignTokens.spacingM),
              _buildCommentsCard(context, colorScheme),
              SizedBox(height: DesignTokens.spacingL),
              _buildSubmitSection(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ColorScheme colorScheme) {
    final subtitle = widget.raterRole == 'guard' 
        ? ComprehensiveJobReviewLocalizationNL.reviewSubtitleGuard
        : ComprehensiveJobReviewLocalizationNL.reviewSubtitleCompany;
    
    return UnifiedCard.standard(
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rate_review_rounded,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeL,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ComprehensiveJobReviewLocalizationNL.reviewTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightBold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.workflow != null) ...[
              SizedBox(height: DesignTokens.spacingM),
              _buildJobSummary(context, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJobSummary(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ComprehensiveJobReviewLocalizationNL.jobSummaryTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          _buildSummaryRow(
            context,
            colorScheme,
            ComprehensiveJobReviewLocalizationNL.jobTitleLabel,
            widget.workflow?.jobTitle ?? ComprehensiveJobReviewLocalizationNL.notAvailable,
          ),
          _buildSummaryRow(
            context,
            colorScheme,
            widget.raterRole == 'guard' 
                ? ComprehensiveJobReviewLocalizationNL.companyLabel
                : ComprehensiveJobReviewLocalizationNL.guardLabel,
            widget.raterRole == 'guard'
                ? widget.workflow?.companyName ?? ComprehensiveJobReviewLocalizationNL.notAvailable
                : widget.workflow?.selectedGuardName ?? ComprehensiveJobReviewLocalizationNL.notAvailable,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRatingsCard(BuildContext context, ColorScheme colorScheme) {
    return UnifiedCard.standard(
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  ComprehensiveJobReviewLocalizationNL.categoryRatingsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              ComprehensiveJobReviewLocalizationNL.categoryRatingsInstructions,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            ..._buildCategoryRatingRows(context, colorScheme),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryRatingRows(BuildContext context, ColorScheme colorScheme) {
    final categories = ComprehensiveJobReviewLocalizationNL.getRatingCategories(widget.raterRole);
    
    return categories.entries.map((category) {
      return Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spacingL),
        child: _buildCategoryRating(
          context,
          colorScheme,
          category.key,
          category.value,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryRating(
    BuildContext context,
    ColorScheme colorScheme,
    String categoryKey,
    String categoryLabel,
  ) {
    final currentRating = _categoryRatings[categoryKey] ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Row(
          children: [
            Expanded(
              child: RatingBar.builder(
                initialRating: currentRating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 32,
                itemPadding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
                itemBuilder: (context, _) => Icon(
                  Icons.star_rate_rounded,
                  color: _getRatingColor(colorScheme, currentRating),
                ),
                onRatingUpdate: (rating) {
                  if (!widget.isReadOnly) {
                    setState(() {
                      _categoryRatings[categoryKey] = rating;
                    });
                  }
                },
                ignoreGestures: widget.isReadOnly,
              ),
            ),
            if (currentRating > 0) ...[
              SizedBox(width: DesignTokens.spacingM),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: _getRatingColor(colorScheme, currentRating).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  JobCompletionRatingLocalizationNL.getRatingDescription(currentRating),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: _getRatingColor(colorScheme, currentRating),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCommentsCard(BuildContext context, ColorScheme colorScheme) {
    return UnifiedCard.standard(
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.comment_rounded,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  ComprehensiveJobReviewLocalizationNL.commentsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            UnifiedInput(
              variant: UnifiedInputVariant.multiline,
              label: ComprehensiveJobReviewLocalizationNL.commentsLabel,
              controller: _commentsController,
              hint: ComprehensiveJobReviewLocalizationNL.commentsHint,
              helperText: ComprehensiveJobReviewLocalizationNL.commentsHelper,
              maxLines: 4,
              maxLength: 500,
              isEnabled: !widget.isReadOnly,
              onChanged: (value) {
                setState(() {
                  _comments = value;
                });
              },
              userRole: widget.raterRole == 'guard' ? UserRole.guard : UserRole.company,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitSection(BuildContext context, ColorScheme colorScheme) {
    if (widget.isReadOnly) return const SizedBox.shrink();
    
    final canSubmit = _canSubmitReview() && !_isSubmitting;
    final averageRating = _calculateAverageRating();
    
    return Column(
      children: [
        if (averageRating > 0) ...[
          UnifiedCard.standard(
            backgroundColor: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rate_rounded,
                    color: _getRatingColor(colorScheme, averageRating),
                    size: DesignTokens.iconSizeL,
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ComprehensiveJobReviewLocalizationNL.overallRatingLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: DesignTokens.fontFamily,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${averageRating.toStringAsFixed(1)} ${ComprehensiveJobReviewLocalizationNL.starsSuffix}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: DesignTokens.fontWeightBold,
                            color: _getRatingColor(colorScheme, averageRating),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
        ],
        SizedBox(
          width: double.infinity,
          child: UnifiedButton(
            text: _isSubmitting 
                ? ComprehensiveJobReviewLocalizationNL.submittingButton 
                : ComprehensiveJobReviewLocalizationNL.submitButton,
            type: UnifiedButtonType.primary,
            size: UnifiedButtonSize.large,
            backgroundColor: canSubmit ? colorScheme.primary : colorScheme.outline,
            foregroundColor: canSubmit ? colorScheme.onPrimary : colorScheme.onSurface,
            isLoading: _isSubmitting,
            isEnabled: canSubmit,
            onPressed: canSubmit ? _submitReview : null,
          ),
        ),
      ],
    );
  }

  Color _getRatingColor(ColorScheme colorScheme, double rating) {
    if (rating >= 4.5) return DesignTokens.statusCompleted;
    if (rating >= 4.0) return DesignTokens.statusPending;
    if (rating >= 3.0) return colorScheme.primary;
    if (rating >= 2.0) return DesignTokens.colorWarning;
    return DesignTokens.colorError;
  }

  bool _canSubmitReview() {
    // Check if at least the overall rating is provided
    final overallRating = _categoryRatings['overall'] ?? 0.0;
    return overallRating > 0;
  }

  double _calculateAverageRating() {
    final ratings = _categoryRatings.values.where((rating) => rating > 0);
    if (ratings.isEmpty) return 0.0;
    
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  void _submitReview() {
    if (!_canSubmitReview() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Calculate overall rating (use overall category or average of all)
    final overallRating = _categoryRatings['overall'] ?? _calculateAverageRating();
    
    // Convert raterRole to RaterType enum
    final raterType = widget.raterRole == 'guard' ? RaterType.guard : RaterType.company;

    // Submit rating using existing JobCompletionBloc pattern with enhanced metadata
    context.read<JobCompletionBloc>().add(
      JobRatingSubmit(
        jobId: widget.jobId,
        raterId: widget.raterId,
        raterType: raterType,
        rating: overallRating.round(),
        comments: _buildEnhancedComments(),
      ),
    );
  }

  String _buildEnhancedComments() {
    final buffer = StringBuffer();
    
    // Add category ratings as structured data
    final categoryRatings = _categoryRatings.entries
        .where((entry) => entry.value > 0)
        .map((entry) => '${ComprehensiveJobReviewLocalizationNL.getRatingCategories(widget.raterRole)[entry.key]}: ${entry.value.toStringAsFixed(1)}')
        .join(', ');
    
    if (categoryRatings.isNotEmpty) {
      buffer.writeln('Categoriebeoordelingen: $categoryRatings');
    }
    
    if (_comments.isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(_comments);
    }
    
    return buffer.toString();
  }

  void _onReviewSubmitted() {
    setState(() {
      _isSubmitting = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ComprehensiveJobReviewLocalizationNL.reviewSubmitted,
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        backgroundColor: DesignTokens.statusCompleted,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );

    // Call callback if provided
    widget.onReviewSubmitted?.call();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        backgroundColor: DesignTokens.colorError,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
      ),
    );
  }
}

/// Extended Dutch localization for comprehensive job review interface
class ComprehensiveJobReviewLocalizationNL extends JobCompletionRatingLocalizationNL {
  // Enhanced review interface texts
  static const String reviewTitle = 'Beoordeel de samenwerking';
  static const String reviewSubtitleGuard = 'Geef een gedetailleerde beoordeling van je samenwerking met dit bedrijf.';
  static const String reviewSubtitleCompany = 'Geef een gedetailleerde beoordeling van je samenwerking met deze beveiliger.';
  
  // Job summary
  static const String jobSummaryTitle = 'Opdracht details';
  static const String jobTitleLabel = 'Titel:';
  static const String companyLabel = 'Bedrijf:';
  static const String guardLabel = 'Beveiliger:';
  static const String notAvailable = 'Niet beschikbaar';
  
  // Category ratings
  static const String categoryRatingsTitle = 'Categorie beoordelingen';
  static const String categoryRatingsInstructions = 'Beoordeel verschillende aspecten van de samenwerking (0-5 sterren)';
  
  // Rating categories for guards (rating companies)
  static const Map<String, String> guardRatingCategories = {
    'communication': 'Communicatie',
    'punctuality': 'Betaling op tijd', 
    'professionalism': 'Professionaliteit',
    'overall': 'Algemene tevredenheid',
  };
  
  // Rating categories for companies (rating guards)
  static const Map<String, String> companyRatingCategories = {
    'communication': 'Communicatie',
    'punctuality': 'Stiptheid',
    'professionalism': 'Professionaliteit', 
    'overall': 'Algemene tevredenheid',
  };
  
  // Comments section
  static const String commentsTitle = 'Aanvullende opmerkingen';
  static const String commentsLabel = 'Opmerkingen (optioneel)';
  static const String commentsHint = 'Deel je ervaring en feedback over deze samenwerking...';
  static const String commentsHelper = 'Je kunt aanvullende details delen die anderen kunnen helpen.';
  
  // Overall rating
  static const String overallRatingLabel = 'Gemiddelde beoordeling';
  static const String starsSuffix = 'sterren';
  
  // Buttons
  static const String submitButton = 'Beoordeling indienen';
  static const String submittingButton = 'Beoordeling indienen...';
  
  // Status messages
  static const String reviewSubmitted = 'Uitgebreide beoordeling succesvol ingediend!';
  
  /// Get rating categories based on user role
  static Map<String, String> getRatingCategories(String userRole) {
    return userRole == 'guard' ? guardRatingCategories : companyRatingCategories;
  }
  
  /// Get category descriptions
  static Map<String, String> getCategoryDescriptions(String userRole) {
    if (userRole == 'guard') {
      return {
        'communication': 'Hoe goed communiceerde het bedrijf tijdens de opdracht?',
        'punctuality': 'Werd de betaling op tijd verwerkt?',
        'professionalism': 'Hoe professioneel was het bedrijf in de samenwerking?',
        'overall': 'Hoe tevreden ben je over de algemene samenwerking?',
      };
    } else {
      return {
        'communication': 'Hoe goed communiceerde de beveiliger tijdens de opdracht?',
        'punctuality': 'Was de beveiliger op tijd en betrouwbaar?',
        'professionalism': 'Hoe professioneel was de beveiliger in de uitvoering?',
        'overall': 'Hoe tevreden ben je over de algemene prestatie?',
      };
    }
  }
}