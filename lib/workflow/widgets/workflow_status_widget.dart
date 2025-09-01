import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../bloc/workflow_orchestration_bloc.dart';
import '../models/job_workflow_models.dart';

/// WorkflowStatusWidget displays real-time workflow status in dashboards
/// Provides visual feedback and actionable buttons for workflow transitions
/// Supports both guard and company perspectives with role-based theming
class WorkflowStatusWidget extends StatelessWidget {
  final String workflowId;
  final String userRole; // 'guard' or 'company'
  final String userId;
  final VoidCallback? onTap;
  final bool isCompact;

  const WorkflowStatusWidget({
    super.key,
    required this.workflowId,
    required this.userRole,
    required this.userId,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WorkflowOrchestrationBloc(
        orchestrationService: context.read(),
      )..add(WatchWorkflow(workflowId: workflowId)),
      child: BlocBuilder<WorkflowOrchestrationBloc, WorkflowOrchestrationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildLoadingCard();
          }

          if (state.isError) {
            return _buildErrorCard(state.errorMessage ?? 'Onbekende fout');
          }

          if (state.hasWorkflow) {
            return _buildWorkflowCard(context, state.workflow!);
          }

          return _buildEmptyCard();
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return UnifiedCard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getThemePrimaryColor(),
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            Text(
              'Laden workflow status...',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return UnifiedCard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: DesignTokens.statusCancelled,
              size: 20,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                'Fout: $error',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.statusCancelled,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return UnifiedCard(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Text(
          'Geen workflow gegevens beschikbaar',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: DesignTokens.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkflowCard(BuildContext context, JobWorkflow workflow) {
    return UnifiedCard(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        child: isCompact
            ? _buildCompactLayout(context, workflow)
            : _buildFullLayout(context, workflow),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, JobWorkflow workflow) {
    return Row(
      children: [
        _buildStatusIndicator(workflow.currentState),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workflow.jobTitle,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.darkText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                workflow.currentState.displayNameNL,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXS,
                  color: _getStatusColor(workflow.currentState),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_hasActions(workflow)) ...[
          SizedBox(width: DesignTokens.spacingS),
          _buildActionButton(context, workflow),
        ],
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, JobWorkflow workflow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with status
        Row(
          children: [
            _buildStatusIndicator(workflow.currentState),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workflow.jobTitle,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.darkText,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    workflow.currentState.displayNameNL,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeS,
                      color: _getStatusColor(workflow.currentState),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: DesignTokens.spacingS),

        // Details section
        _buildWorkflowDetails(workflow),

        // Progress indicator
        if (_shouldShowProgress(workflow)) ...[
          SizedBox(height: DesignTokens.spacingS),
          _buildProgressIndicator(workflow),
        ],

        // Actions
        if (_hasActions(workflow)) ...[
          SizedBox(height: DesignTokens.spacingM),
          _buildActionButtons(context, workflow),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(JobWorkflowState status) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildWorkflowDetails(JobWorkflow workflow) {
    final details = <Widget>[];

    // Company/Guard info
    if (userRole == 'guard' && workflow.companyName.isNotEmpty) {
      details.add(_buildDetailRow(
        icon: Icons.business,
        label: 'Bedrijf',
        value: workflow.companyName,
      ));
    } else if (userRole == 'company' && workflow.selectedGuardName != null) {
      details.add(_buildDetailRow(
        icon: Icons.security,
        label: 'Beveiliger',
        value: workflow.selectedGuardName!,
      ));
    }

    // Hourly rate
    if (workflow.metadata.agreedHourlyRate != null) {
      details.add(_buildDetailRow(
        icon: Icons.euro,
        label: 'Uurloon',
        value: '€${workflow.metadata.agreedHourlyRate!.toStringAsFixed(2)}',
      ));
    }

    // Scheduled start time
    if (workflow.metadata.scheduledStartTime != null) {
      details.add(_buildDetailRow(
        icon: Icons.schedule,
        label: 'Geplande start',
        value: _formatDateTime(workflow.metadata.scheduledStartTime!),
      ));
    }

    // Location
    if (workflow.metadata.location?.isNotEmpty == true) {
      details.add(_buildDetailRow(
        icon: Icons.location_on,
        label: 'Locatie',
        value: workflow.metadata.location!,
      ));
    }

    return Column(
      children: details
          .map((detail) => Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
                child: detail,
              ))
          .toList(),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: DesignTokens.mutedText,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: DesignTokens.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              color: DesignTokens.darkText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(JobWorkflow workflow) {
    final progress = _calculateProgress(workflow.currentState);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voortgang',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXS,
            color: DesignTokens.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: DesignTokens.mutedText.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(_getThemePrimaryColor()),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, JobWorkflow workflow) {
    final action = _getPrimaryAction(workflow);
    if (action == null) return SizedBox.shrink();

    return UnifiedButton(
      text: action['label'],
      type: UnifiedButtonType.secondary,
      size: UnifiedButtonSize.small,
      onPressed: () => _handleAction(context, workflow, action['action']),
    );
  }

  Widget _buildActionButtons(BuildContext context, JobWorkflow workflow) {
    final actions = _getAvailableActions(workflow);
    if (actions.isEmpty) return SizedBox.shrink();

    return Row(
      children: actions
          .map((action) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: action == actions.last ? 0 : DesignTokens.spacingS,
                  ),
                  child: UnifiedButton(
                    text: action['label'],
                    type: action['isPrimary'] == true
                        ? UnifiedButtonType.primary
                        : UnifiedButtonType.secondary,
                    onPressed: () => _handleAction(context, workflow, action['action']),
                  ),
                ),
              ))
          .toList(),
    );
  }

  // Helper methods

  Color _getThemePrimaryColor() {
    switch (userRole) {
      case 'guard':
        return DesignTokens.guardPrimary;
      case 'company':
        return DesignTokens.companyPrimary;
      default:
        return DesignTokens.colorPrimaryBlue;
    }
  }

  Color _getStatusColor(JobWorkflowState status) {
    switch (status) {
      case JobWorkflowState.posted:
        return DesignTokens.statusPending;
      case JobWorkflowState.applied:
      case JobWorkflowState.underReview:
        return DesignTokens.statusPending;
      case JobWorkflowState.accepted:
      case JobWorkflowState.inProgress:
        return DesignTokens.statusInProgress;
      case JobWorkflowState.completed:
      case JobWorkflowState.rated:
      case JobWorkflowState.paid:
        return DesignTokens.statusCompleted;
      case JobWorkflowState.closed:
        return DesignTokens.statusDraft;
      case JobWorkflowState.cancelled:
        return DesignTokens.statusCancelled;
    }
  }

  double _calculateProgress(JobWorkflowState status) {
    const progressMap = {
      JobWorkflowState.posted: 0.1,
      JobWorkflowState.applied: 0.2,
      JobWorkflowState.underReview: 0.3,
      JobWorkflowState.accepted: 0.4,
      JobWorkflowState.inProgress: 0.6,
      JobWorkflowState.completed: 0.8,
      JobWorkflowState.rated: 0.9,
      JobWorkflowState.paid: 1.0,
      JobWorkflowState.closed: 1.0,
      JobWorkflowState.cancelled: 0.0,
    };
    return progressMap[status] ?? 0.0;
  }

  bool _shouldShowProgress(JobWorkflow workflow) {
    return workflow.currentState != JobWorkflowState.cancelled &&
           workflow.currentState != JobWorkflowState.closed;
  }

  bool _hasActions(JobWorkflow workflow) {
    return _getAvailableActions(workflow).isNotEmpty;
  }

  Map<String, dynamic>? _getPrimaryAction(JobWorkflow workflow) {
    final actions = _getAvailableActions(workflow);
    try {
      return actions.firstWhere(
        (action) => action['isPrimary'] == true,
      );
    } catch (e) {
      return actions.isEmpty ? null : actions.first;
    }
  }

  List<Map<String, dynamic>> _getAvailableActions(JobWorkflow workflow) {
    final actions = <Map<String, dynamic>>[];

    if (userRole == 'company') {
      switch (workflow.currentState) {
        case JobWorkflowState.underReview:
          actions.addAll([
            {
              'label': 'Accepteren',
              'action': 'accept_application',
              'isPrimary': true,
            },
            {
              'label': 'Afwijzen',
              'action': 'reject_application',
              'isPrimary': false,
            },
          ]);
          break;
        case JobWorkflowState.completed:
          actions.add({
            'label': 'Beoordelen',
            'action': 'rate_job',
            'isPrimary': true,
          });
          break;
        default:
          break;
      }
    } else if (userRole == 'guard') {
      switch (workflow.currentState) {
        case JobWorkflowState.accepted:
          actions.add({
            'label': 'Starten',
            'action': 'start_job',
            'isPrimary': true,
          });
          break;
        case JobWorkflowState.inProgress:
          actions.add({
            'label': 'Voltooien',
            'action': 'complete_job',
            'isPrimary': true,
          });
          break;
        case JobWorkflowState.completed:
          actions.add({
            'label': 'Beoordelen',
            'action': 'rate_job',
            'isPrimary': true,
          });
          break;
        default:
          break;
      }
    }

    return actions;
  }

  void _handleAction(BuildContext context, JobWorkflow workflow, String action) {
    final bloc = context.read<WorkflowOrchestrationBloc>();

    switch (action) {
      case 'accept_application':
        // Navigate to acceptance dialog/screen
        _showAcceptanceDialog(context, workflow, bloc);
        break;
      case 'start_job':
        // Start job execution
        bloc.add(StartJobExecution(
          workflowId: workflow.id,
          guardId: userId,
          actualStartTime: DateTime.now(),
        ));
        break;
      case 'complete_job':
        // Navigate to job completion screen
        _showCompletionDialog(context, workflow, bloc);
        break;
      case 'rate_job':
        // Navigate to rating screen
        _showRatingDialog(context, workflow);
        break;
      default:
        // Handle other actions
        break;
    }
  }

  void _showAcceptanceDialog(BuildContext context, JobWorkflow workflow, WorkflowOrchestrationBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sollicitatie Accepteren'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wilt u de sollicitatie van ${workflow.selectedGuardName} accepteren voor "${workflow.jobTitle}"?'),
            SizedBox(height: DesignTokens.spacingM),
            TextField(
              decoration: InputDecoration(
                labelText: 'Bericht voor de beveiliger (optioneel)',
                hintText: 'Welkom bij ons team! We kijken uit naar de samenwerking.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              bloc.add(AcceptJobApplication(
                workflowId: workflow.id,
                companyId: userId,
                acceptanceMessage: 'Welkom bij ons team!',
              ));
              Navigator.of(context).pop();
            },
            child: Text('Accepteren'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, JobWorkflow workflow, WorkflowOrchestrationBloc bloc) {
    double hoursWorked = 8.0; // Default value
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Opdracht Voltooien'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Gewerkte uren:'),
            TextFormField(
              initialValue: hoursWorked.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) => hoursWorked = double.tryParse(value) ?? 8.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              bloc.add(CompleteJobExecution(
                workflowId: workflow.id,
                guardId: userId,
                actualEndTime: DateTime.now(),
                totalHoursWorked: hoursWorked,
              ));
              Navigator.of(context).pop();
            },
            child: Text('Voltooien'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, JobWorkflow workflow) {
    // This would typically navigate to a dedicated rating screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Beoordeling scherm wordt geladen...')),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}