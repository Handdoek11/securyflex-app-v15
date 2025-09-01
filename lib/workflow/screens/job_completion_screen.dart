import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/unified_components.dart';
import '../bloc/job_completion_bloc.dart';
import '../widgets/job_completion_rating_widget.dart';
import '../widgets/workflow_status_widget.dart';
import '../models/job_workflow_models.dart';
import '../../reviews/screens/submit_review_screen.dart';
import '../../reviews/models/comprehensive_review_model.dart';

/// Job completion screen with integrated rating system
/// 
/// Follows existing SecuryFlex screen patterns and integrates with job completion workflow
/// Uses unified components and maintains role-based theming
class JobCompletionScreen extends StatefulWidget {
  final String jobId;
  final String workflowId;
  final String userId;
  final String userRole; // 'guard' or 'company'
  final JobWorkflow? workflow;

  const JobCompletionScreen({
    super.key,
    required this.jobId,
    required this.workflowId,
    required this.userId,
    required this.userRole,
    this.workflow,
  });

  @override
  State<JobCompletionScreen> createState() => _JobCompletionScreenState();
}

class _JobCompletionScreenState extends State<JobCompletionScreen> {
  late ScrollController _scrollController;
  bool _showRatingWidget = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkIfRatingNeeded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfRatingNeeded() {
    // Show rating widget if job is completed but not yet rated
    if (widget.workflow?.currentState == JobWorkflowState.completed) {
      setState(() {
        _showRatingWidget = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(
      widget.userRole == 'guard' ? UserRole.guard : UserRole.company
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocListener<JobCompletionBloc, JobCompletionState>(
        listener: (context, state) {
          if (state is JobCompletionInProgress && 
              state.currentState == JobWorkflowState.rated) {
            setState(() {
              _showRatingWidget = false;
            });
            _showCompletionMessage();
          } else if (state is JobCompletionError) {
            _showErrorMessage(state.message);
          }
        },
        child: Column(
          children: [
            _buildAppBar(context, colorScheme),
            Expanded(
              child: _buildBody(context, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return UnifiedHeader.simple(
      title: 'Opdracht voltooien',
      backgroundColor: colorScheme.primary,
      userRole: UserRole.guard,
      titleAlignment: TextAlign.left,
      leading: HeaderElements.backButton(
        userRole: UserRole.guard,
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobSummary(context, colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildWorkflowStatus(context, colorScheme),
          if (_showRatingWidget) ...[
            SizedBox(height: DesignTokens.spacingL),
            _buildRatingSection(context, colorScheme),
          ],
          SizedBox(height: DesignTokens.spacingL),
          _buildNextSteps(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildJobSummary(BuildContext context, ColorScheme colorScheme) {
    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    widget.workflow?.jobTitle ?? 'Beveiligingsopdracht',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: DesignTokens.fontFamily,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildSummaryItem(
              context, 
              colorScheme,
              'Opdracht ID', 
              widget.jobId,
              Icons.tag
            ),
            _buildSummaryItem(
              context, 
              colorScheme,
              widget.userRole == 'guard' ? 'Opdrachtgever' : 'Beveiliger',
              widget.userRole == 'guard' ? widget.workflow?.companyName : widget.workflow?.selectedGuardName,
              Icons.business
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context, 
    ColorScheme colorScheme, 
    String label, 
    String? value,
    IconData icon
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Niet beschikbaar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStatus(BuildContext context, ColorScheme colorScheme) {
    if (widget.workflow == null) {
      return Container();
    }

    return WorkflowStatusWidget(
      workflowId: widget.workflowId,
      userRole: widget.userRole,
      userId: widget.userId,
    );
  }

  Widget _buildRatingSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beoordeling vereist',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        
        // Add button to navigate to comprehensive review system
        ElevatedButton.icon(
          onPressed: () async {
            // Navigate to the new comprehensive review screen
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmitReviewScreen(
                  workflowId: widget.workflowId,
                  jobId: widget.jobId,
                  revieweeId: widget.userRole == 'guard' 
                      ? widget.workflow?.companyId ?? '' 
                      : widget.workflow?.selectedGuardId ?? '',
                  revieweeName: widget.userRole == 'guard'
                      ? 'Bedrijf' // In production, fetch actual company name
                      : 'Beveiliger', // In production, fetch actual guard name
                  reviewerType: widget.userRole == 'guard'
                      ? ReviewerType.guard
                      : ReviewerType.company,
                  userRole: widget.userRole == 'guard'
                      ? UserRole.guard
                      : UserRole.company,
                  shiftDate: widget.workflow?.metadata.actualEndTime ?? widget.workflow?.updatedAt,
                ),
              ),
            );
            
            if (result == true && mounted) {
              // Review submitted successfully
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Review succesvol ingediend!'),
                  backgroundColor: DesignTokens.colorSuccess,
                ),
              );
              
              // Scroll to top to show completion message
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
          icon: Icon(Icons.rate_review),
          label: Text('Schrijf uitgebreide review'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingXL,
              vertical: DesignTokens.spacingM,
            ),
          ),
        ),
        
        SizedBox(height: DesignTokens.spacingL),
        
        // Keep the existing quick rating widget as alternative
        Text(
          'Of gebruik snelle beoordeling:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        JobCompletionRatingWidget(
          jobId: widget.jobId,
          workflowId: widget.workflowId,
          raterId: widget.userId,
          raterRole: widget.userRole,
          workflow: widget.workflow,
          onRatingSubmitted: () {
            // Scroll to top to show completion message
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
        ),
      ],
    );
  }

  Widget _buildNextSteps(BuildContext context, ColorScheme colorScheme) {
    final workflow = widget.workflow;
    if (workflow == null) return Container();

    String nextStepText;
    IconData nextStepIcon;
    
    switch (workflow.currentState) {
      case JobWorkflowState.completed:
        nextStepText = 'Beoordeel je samenwerking om door te gaan';
        nextStepIcon = Icons.star_rate;
        break;
      case JobWorkflowState.rated:
        nextStepText = 'Wachten op betaling verwerking';
        nextStepIcon = Icons.payment;
        break;
      case JobWorkflowState.paid:
        nextStepText = 'Opdracht succesvol afgerond!';
        nextStepIcon = Icons.check_circle;
        break;
      default:
        nextStepText = 'Status wordt bijgewerkt...';
        nextStepIcon = Icons.update;
    }

    return UnifiedCard.standard(
      backgroundColor: colorScheme.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        child: Row(
          children: [
            Icon(
              nextStepIcon,
              color: colorScheme.primary,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Text(
                nextStepText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Beoordeling voltooid! Je wordt op de hoogte gehouden van de betaling.',
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        backgroundColor: DesignTokens.statusCompleted,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(DesignTokens.spacingM),
      ),
    );
  }

  void _showErrorMessage(String message) {
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