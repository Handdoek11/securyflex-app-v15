import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_buttons.dart';
import '../../unified_card_system.dart';
import '../../unified_theme_system.dart';
import '../services/application_service.dart' show ApplicationData, ApplicationService, ApplicationStatus;
import 'package:go_router/go_router.dart';

/// ApplicationTracker widget voor het monitoren van sollicitatiestatus
/// 
/// Real-time application status tracking with Nederlandse localization,
/// timeline visualization, status updates, and withdrawal functionality.
/// Provides comprehensive overview of application lifecycle.
class ApplicationTracker extends StatefulWidget {
  final UserRole userRole;
  final String? userId;
  final ApplicationStatus? statusFilter;
  final bool showCompactView;
  final bool showWithdrawButton;
  final VoidCallback? onApplicationsUpdated;
  
  const ApplicationTracker({
    super.key,
    this.userRole = UserRole.guard,
    this.userId,
    this.statusFilter,
    this.showCompactView = false,
    this.showWithdrawButton = true,
    this.onApplicationsUpdated,
  });
  
  @override
  State<ApplicationTracker> createState() => _ApplicationTrackerState();
}

class _ApplicationTrackerState extends State<ApplicationTracker>
    with SingleTickerProviderStateMixin {
  
  late final TabController _tabController;
  final List<ApplicationStatus> _statusTabs = [
    ApplicationStatus.pending,
    ApplicationStatus.accepted,
    ApplicationStatus.rejected,
    ApplicationStatus.withdrawn,
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: widget.userRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Status tabs (if not filtering by specific status)
          if (widget.statusFilter == null)
            _buildStatusTabs(),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Applications list
          Expanded(
            child: widget.statusFilter != null
                ? _buildApplicationsList(widget.statusFilter!)
                : TabBarView(
                    controller: _tabController,
                    children: _statusTabs.map((status) => 
                      _buildApplicationsList(status)
                    ).toList(),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.assignment,
          color: _getThemeColors().primary,
          size: DesignTokens.iconSizeL,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mijn Sollicitaties',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: _getThemeColors().onSurface,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              FutureBuilder<List<ApplicationData>>(
                future: ApplicationService.getUserApplications(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final applications = snapshot.data!;
                    final totalApplications = applications.length;
                    final acceptedApplications = applications.where((app) => app.status == ApplicationStatus.accepted).length;
                    final successRate = totalApplications > 0 ? (acceptedApplications / totalApplications * 100) : 0;
                    return Text(
                      '$totalApplications sollicitaties • ${successRate.round()}% succes',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeMeta,
                        color: _getThemeColors().onSurfaceVariant,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        
        // Refresh button
        UnifiedButton.icon(
          icon: Icons.refresh,
          onPressed: () {
            setState(() {});
            widget.onApplicationsUpdated?.call();
          },
          color: _getThemeColors().onSurfaceVariant,
        ),
      ],
    );
  }
  
  Widget _buildStatusTabs() {
    return SizedBox(
      height: 40,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _getThemeColors().primary,
        unselectedLabelColor: _getThemeColors().onSurfaceVariant,
        indicatorColor: _getThemeColors().primary,
        labelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightRegular,
        ),
        tabs: _statusTabs.map((status) {
          return FutureBuilder<List<ApplicationData>>(
            future: ApplicationService.getApplicationsByStatus(status),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getStatusDisplayText(status)),
                    if (count > 0) ...[
                      SizedBox(width: DesignTokens.spacingXS),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingS,
                          vertical: DesignTokens.spacingXXS,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeXS,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: DesignTokens.colorWhite,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildApplicationsList(ApplicationStatus status) {
    return FutureBuilder<List<ApplicationData>>(
      future: ApplicationService.getApplicationsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: _getThemeColors().primary,
            ),
          );
        }
        
        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        }
        
        final applications = snapshot.data ?? [];
        
        if (applications.isEmpty) {
          return _buildEmptyView(status);
        }
        
        return ListView.separated(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          itemCount: applications.length,
          separatorBuilder: (context, index) => 
              SizedBox(height: DesignTokens.spacingS),
          itemBuilder: (context, index) {
            return _buildApplicationCard(applications[index]);
          },
        );
      },
    );
  }
  
  Widget _buildApplicationCard(ApplicationData application) {
    return UnifiedCard.compact(
      userRole: widget.userRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with job info and status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBodyLarge,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: _getThemeColors().onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      application.companyName,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: _getThemeColors().onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status indicator
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(application.status),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  ApplicationService.getStatusDisplayText(application.status),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeMeta,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: DesignTokens.colorWhite,
                  ),
                ),
              ),
            ],
          ),
          
          if (!widget.showCompactView) ...[
            SizedBox(height: DesignTokens.spacingM),
            
            // Application details
            _buildApplicationDetails(application),
            
            SizedBox(height: DesignTokens.spacingM),
            
            // Timeline or actions
            _buildApplicationActions(application),
          ] else ...[
            SizedBox(height: DesignTokens.spacingS),
            
            // Compact info
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: DesignTokens.iconSizeS,
                  color: _getThemeColors().onSurfaceVariant,
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  _formatApplicationDate(application.applicationDate),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeMeta,
                    color: _getThemeColors().onSurfaceVariant,
                  ),
                ),
                
                Spacer(),
                
                if (widget.showWithdrawButton && _canWithdrawApplication(application))
                  UnifiedButton.text(
                    text: 'Intrekken',
                    onPressed: () => _showWithdrawDialog(application),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildApplicationDetails(ApplicationData application) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Application info
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: DesignTokens.iconSizeS,
              color: _getThemeColors().onSurfaceVariant,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              'Gesolliciteerd: ${_formatApplicationDate(application.applicationDate)}',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeMeta,
                color: _getThemeColors().onSurfaceVariant,
              ),
            ),
          ],
        ),
        
        SizedBox(height: DesignTokens.spacingS),
        
        // Motivation message preview
        if (application.motivationMessage.isNotEmpty) ...[
          Text(
            'Motivatie:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMeta,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: _getThemeColors().onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            application.motivationMessage,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeMeta,
              color: _getThemeColors().onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
  
  Widget _buildApplicationActions(ApplicationData application) {
    return Row(
      children: [
        // View details button
        UnifiedButton.secondary(
          text: 'Details',
          onPressed: () => _showApplicationDetails(application),
          size: UnifiedButtonSize.small,
        ),
        
        SizedBox(width: DesignTokens.spacingS),
        
        // Status-specific actions
        if (_canWithdrawApplication(application) && widget.showWithdrawButton)
          UnifiedButton.text(
            text: 'Intrekken',
            onPressed: () => _showWithdrawDialog(application),
          ),
        
        Spacer(),
        
        // Status timeline indicator
        _buildStatusTimeline(application.status),
      ],
    );
  }
  
  Widget _buildStatusTimeline(ApplicationStatus currentStatus) {
    final statuses = [
      ApplicationStatus.pending,
      ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    ];
    
    return Row(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isActive = status == currentStatus;
        final isPast = statuses.indexOf(currentStatus) > index;
        
        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive || isPast 
                    ? _getStatusColor(status)
                    : _getThemeColors().surfaceContainerHighest,
                border: Border.all(
                  color: isActive || isPast 
                      ? _getStatusColor(status)
                      : _getThemeColors().outline,
                  width: 2,
                ),
              ),
              child: Icon(
                _getStatusIcon(status),
                size: DesignTokens.iconSizeXS,
                color: isActive || isPast 
                    ? DesignTokens.colorWhite
                    : _getThemeColors().onSurfaceVariant,
              ),
            ),
            if (index < statuses.length - 1) ...[
              Container(
                width: 20,
                height: 2,
                color: isPast 
                    ? _getStatusColor(currentStatus)
                    : _getThemeColors().surfaceContainerHighest,
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
  
  Widget _buildEmptyView(ApplicationStatus status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 64,
            color: _getThemeColors().surfaceContainerHighest,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            _getEmptyStateMessage(status),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBodyLarge,
              color: _getThemeColors().onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: DesignTokens.colorError,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            'Er is een fout opgetreden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBodyLarge,
              color: DesignTokens.colorError,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            error,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: _getThemeColors().onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  String _formatApplicationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Vandaag';
    } else if (difference.inDays == 1) {
      return 'Gisteren';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dagen geleden';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  String _getStatusDisplayText(ApplicationStatus status) {
    return ApplicationService.getStatusDisplayText(status);
  }
  
  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return DesignTokens.statusPending;
      case ApplicationStatus.accepted:
        return DesignTokens.statusAccepted;
      case ApplicationStatus.rejected:
        return DesignTokens.statusCancelled;
      case ApplicationStatus.withdrawn:
        return DesignTokens.statusDraft;
      case ApplicationStatus.interviewInvited:
        return DesignTokens.statusPending;
      case ApplicationStatus.documentsPending:
        return DesignTokens.statusPending;
      case ApplicationStatus.contractOffered:
        return DesignTokens.statusAccepted;
      case ApplicationStatus.interviewScheduled:
        return DesignTokens.statusPending;
    }
  }
  
  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.hourglass_empty;
      case ApplicationStatus.accepted:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.withdrawn:
        return Icons.undo;
      case ApplicationStatus.interviewInvited:
        return Icons.event;
      case ApplicationStatus.documentsPending:
        return Icons.description;
      case ApplicationStatus.contractOffered:
        return Icons.handshake;
      case ApplicationStatus.interviewScheduled:
        return Icons.calendar_today;
    }
  }
  
  String _getEmptyStateMessage(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Geen sollicitaties in behandeling';
      case ApplicationStatus.accepted:
        return 'Geen geaccepteerde sollicitaties';
      case ApplicationStatus.rejected:
        return 'Geen afgewezen sollicitaties';
      case ApplicationStatus.withdrawn:
        return 'Geen ingetrokken sollicitaties';
      case ApplicationStatus.interviewInvited:
        return 'Geen uitnodigingen voor gesprekken';
      case ApplicationStatus.documentsPending:
        return 'Geen sollicitaties wachtend op documenten';
      case ApplicationStatus.contractOffered:
        return 'Geen contractaanbiedingen';
      case ApplicationStatus.interviewScheduled:
        return 'Geen ingeplande gesprekken';
    }
  }
  
  bool _canWithdrawApplication(ApplicationData application) {
    return application.status == ApplicationStatus.pending;
  }
  
  void _showApplicationDetails(ApplicationData application) {
    showDialog(
      context: context,
      builder: (context) => ApplicationDetailsDialog(
        application: application,
        userRole: widget.userRole,
      ),
    );
  }
  
  void _showWithdrawDialog(ApplicationData application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sollicitatie intrekken'),
        content: Text(
          'Weet je zeker dat je je sollicitatie voor "${application.jobTitle}" wilt intrekken?'
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Annuleren'),
          ),
          UnifiedButton.primary(
            text: 'Intrekken',
            onPressed: () async {
              context.pop();
              await _withdrawApplication(application);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _withdrawApplication(ApplicationData application) async {
    final success = await ApplicationService.withdrawApplication(application.id);
    
    if (success) {
      setState(() {});
      widget.onApplicationsUpdated?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sollicitatie succesvol ingetrokken'),
            backgroundColor: DesignTokens.colorSuccess,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij intrekken sollicitatie'),
            backgroundColor: DesignTokens.colorError,
          ),
        );
      }
    }
  }
  
  ColorScheme _getThemeColors() {
    return SecuryFlexTheme.getColorScheme(widget.userRole);
  }
}

/// Dialog for showing detailed application information
class ApplicationDetailsDialog extends StatelessWidget {
  final ApplicationData application;
  final UserRole userRole;
  
  const ApplicationDetailsDialog({
    super.key,
    required this.application,
    required this.userRole,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sollicitatie Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              application.jobTitle,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBodyLarge,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            Text(
              application.companyName,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorGray600,
              ),
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            
            Text('Status: ${ApplicationService.getStatusDisplayText(application.status)}'),
            Text('Gesolliciteerd: ${application.applicationDate.day}/${application.applicationDate.month}/${application.applicationDate.year}'),
            
            if (application.motivationMessage.isNotEmpty) ...[
              SizedBox(height: DesignTokens.spacingM),
              Text(
                'Motivatie:',
                style: TextStyle(
                  fontWeight: DesignTokens.fontWeightBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(application.motivationMessage),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text('Sluiten'),
        ),
      ],
    );
  }
}