import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../core/unified_components.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../bloc/job_completion_bloc.dart';
import '../models/job_workflow_models.dart';
import '../localization/job_completion_rating_nl.dart';

/// Job completion rating widget following existing SecuryFlex patterns
/// 
/// Extends existing rating patterns from ProfileStatsWidget and job details screen
/// Uses existing flutter_rating_bar package and unified design system
class JobCompletionRatingWidget extends StatefulWidget {
  final String jobId;
  final String workflowId;
  final String raterId;
  final String raterRole; // 'guard' or 'company'
  final JobWorkflow? workflow;
  final VoidCallback? onRatingSubmitted;
  
  const JobCompletionRatingWidget({
    super.key,
    required this.jobId,
    required this.workflowId,
    required this.raterId,
    required this.raterRole,
    this.workflow,
    this.onRatingSubmitted,
  });

  @override
  State<JobCompletionRatingWidget> createState() => _JobCompletionRatingWidgetState();
}

class _JobCompletionRatingWidgetState extends State<JobCompletionRatingWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  double _currentRating = 0.0;
  String _comments = '';
  bool _isSubmitting = false;
  final _commentsController = TextEditingController();

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
      duration: const Duration(milliseconds: 600),
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
          _onRatingSubmitted();
        } else if (state is JobCompletionError) {
          _showErrorSnackBar(context, state.message);
        }
      },
      child: _buildRatingCard(context),
    );
  }

  Widget _buildRatingCard(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.raterRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(DesignTokens.spacingM),
          child: UnifiedCard.standard(
            backgroundColor: colorScheme.surfaceContainer,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, colorScheme),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildRatingSection(context, colorScheme),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildCommentsSection(context, colorScheme),
                  SizedBox(height: DesignTokens.spacingL),
                  _buildSubmitButton(context, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final subtitle = widget.raterRole == 'guard' 
        ? JobCompletionRatingLocalizationNL.ratingSubtitleGuard
        : JobCompletionRatingLocalizationNL.ratingSubtitleCompany;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star_rate_rounded,
              color: colorScheme.primary,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                JobCompletionRatingLocalizationNL.ratingTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          JobCompletionRatingLocalizationNL.ratingInstructions,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Center(
          child: Column(
            children: [
              RatingBar.builder(
                initialRating: _currentRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemSize: 40,
                itemPadding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
                itemBuilder: (context, _) => Icon(
                  Icons.star_rate_rounded,
                  color: _getRatingColor(colorScheme),
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _currentRating = rating;
                  });
                },
              ),
              SizedBox(height: DesignTokens.spacingM),
              if (_currentRating > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(colorScheme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Text(
                    JobCompletionRatingLocalizationNL.getRatingDescription(_currentRating),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: _getRatingColor(colorScheme),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          JobCompletionRatingLocalizationNL.commentsLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        TextFormField(
          controller: _commentsController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: JobCompletionRatingLocalizationNL.commentsHint,
            hintStyle: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: EdgeInsets.all(DesignTokens.spacingM),
          ),
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            color: colorScheme.onSurface,
          ),
          onChanged: (value) {
            setState(() {
              _comments = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, ColorScheme colorScheme) {
    final canSubmit = _currentRating > 0 && !_isSubmitting;
    
    return SizedBox(
      width: double.infinity,
      child: UnifiedButton(
        text: _isSubmitting ? JobCompletionRatingLocalizationNL.submittingButton : JobCompletionRatingLocalizationNL.submitButton,
        type: UnifiedButtonType.primary,
        backgroundColor: canSubmit ? colorScheme.primary : colorScheme.outline,
        foregroundColor: canSubmit ? colorScheme.onPrimary : colorScheme.onSurface,
        isLoading: _isSubmitting,
        onPressed: canSubmit ? _submitRating : null,
      ),
    );
  }

  Color _getRatingColor(ColorScheme colorScheme) {
    // Use existing rating color logic from ProfileStatsWidget
    if (_currentRating >= 4.5) return DesignTokens.statusCompleted;
    if (_currentRating >= 4.0) return DesignTokens.statusPending;
    if (_currentRating >= 3.5) return colorScheme.primary;
    return DesignTokens.colorError;
  }


  void _submitRating() {
    if (_currentRating == 0 || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Convert raterRole to RaterType enum
    final raterType = widget.raterRole == 'guard' ? RaterType.guard : RaterType.company;

    // Submit rating using existing JobCompletionBloc pattern
    context.read<JobCompletionBloc>().add(
      JobRatingSubmit(
        jobId: widget.jobId,
        raterId: widget.raterId,
        raterType: raterType,
        rating: _currentRating.toInt(),
        comments: _comments.isNotEmpty ? _comments : null,
      ),
    );
  }

  void _onRatingSubmitted() {
    setState(() {
      _isSubmitting = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          JobCompletionRatingLocalizationNL.ratingSubmitted,
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        backgroundColor: DesignTokens.statusCompleted,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
      ),
    );

    // Call callback if provided
    widget.onRatingSubmitted?.call();
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
      ),
    );
  }
}