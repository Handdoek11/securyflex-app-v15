import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/widgets/company_header_elements.dart';


/// Screen for companies to review job applications
/// Shows all applications for a specific job with ability to accept/reject
class ApplicationReviewScreen extends StatefulWidget {
  final JobPostingData jobData;

  const ApplicationReviewScreen({
    super.key,
    required this.jobData,
  });

  @override
  State<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends State<ApplicationReviewScreen>
    with TickerProviderStateMixin {
  List<ApplicationData> _applications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController animationController;
  late ScrollController scrollController;
  StreamSubscription<List<ApplicationData>>? _applicationsSubscription;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    scrollController = ScrollController();
    animationController.forward();
    _startWatchingApplications();
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    _applicationsSubscription?.cancel();
    super.dispose();
  }

  void _startWatchingApplications() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    _applicationsSubscription?.cancel();
    _applicationsSubscription = ApplicationService
        .watchJobApplications(widget.jobData.jobId)
        .listen(
          (applications) {
            if (mounted) {
              setState(() {
                _applications = applications;
                _isLoading = false;
                _errorMessage = '';
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Fout bij laden van sollicitaties: ${error.toString()}';
                _isLoading = false;
              });
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      color: companyColors.surfaceContainerHighest,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: UnifiedHeader.animated(
            title: 'Sollicitaties',
            animationController: animationController,
            scrollController: scrollController,
            enableScrollAnimation: true,
            userRole: UserRole.company,
            titleAlignment: TextAlign.left, // ✅ Standardized left alignment
            actions: [
              CompanyHeaderElements.buildBackButton(
                context: context,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: DesignTokens.spacingM),
            Text('Sollicitaties laden...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: DesignTokens.iconSizeXXL, color: DesignTokens.statusCancelled),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.statusCancelled),
            ),
            SizedBox(height: DesignTokens.spacingM),
            UnifiedButton.secondary(
              text: 'Opnieuw proberen',
              onPressed: _startWatchingApplications,
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: DesignTokens.iconSizeXXL, color: Colors.grey),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Nog geen sollicitaties',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Er zijn nog geen sollicitaties ontvangen voor deze opdracht.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.colorGray600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildJobHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _startWatchingApplications(),
            child: ListView.builder(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                return _buildApplicationCard(_applications[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobHeader() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: UnifiedCard.standard(
        userRole: UserRole.company,
        padding: EdgeInsets.all(DesignTokens.spacingM),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.jobData.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            '${widget.jobData.location} • €${widget.jobData.hourlyRate.toStringAsFixed(2)}/uur',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: DesignTokens.iconSizeM,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '${_applications.length} sollicitatie${_applications.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(ApplicationData application) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  application.applicantName.isNotEmpty 
                      ? application.applicantName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicantName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    Text(
                      application.applicantEmail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DesignTokens.colorGray600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(application.status),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Motivatie:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Text(
            application.motivationMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(Icons.schedule, size: DesignTokens.iconSizeM, color: DesignTokens.colorGray600),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                'Gesolliciteerd op ${DateFormat('dd MMM yyyy').format(application.applicationDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.colorGray600,
                ),
              ),
              Spacer(),
              if (application.isAvailable)
                UnifiedCard.standard(
                  userRole: UserRole.company,
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS, vertical: DesignTokens.spacingXS / 2),
                  backgroundColor: DesignTokens.statusConfirmed.withValues(alpha: 0.100),
                  child: Text(
                    'Direct beschikbaar',
                    style: TextStyle(
                      color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                      fontSize: DesignTokens.fontSizeXS,
                      fontWeight: DesignTokens.fontWeightMedium,
                    ),
                  ),
                ),
            ],
          ),
          if (application.status == ApplicationStatus.pending) ...[
            SizedBox(height: DesignTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: UnifiedButton.secondary(
                    text: 'Afwijzen',
                    onPressed: () => _updateApplicationStatus(application, ApplicationStatus.rejected),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: UnifiedButton.primary(
                    text: 'Accepteren',
                    onPressed: () => _updateApplicationStatus(application, ApplicationStatus.accepted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case ApplicationStatus.pending:
        backgroundColor = DesignTokens.statusPending.withValues(alpha: 0.100);
        textColor = DesignTokens.statusPending.withValues(alpha: 0.800);
        text = 'In behandeling';
        break;
      case ApplicationStatus.accepted:
        backgroundColor = DesignTokens.statusConfirmed.withValues(alpha: 0.100);
        textColor = DesignTokens.statusConfirmed.withValues(alpha: 0.800);
        text = 'Geaccepteerd';
        break;
      case ApplicationStatus.rejected:
        backgroundColor = DesignTokens.statusCancelled.withValues(alpha: 0.100);
        textColor = DesignTokens.statusCancelled.withValues(alpha: 0.800);
        text = 'Afgewezen';
        break;
      case ApplicationStatus.withdrawn:
        backgroundColor = Colors.grey.withValues(alpha: 0.200);
        textColor = Colors.grey.withValues(alpha: 0.800);
        text = 'Ingetrokken';
        break;
      case ApplicationStatus.interviewInvited:
        backgroundColor = DesignTokens.statusAccepted.withValues(alpha: 0.100);
        textColor = DesignTokens.statusAccepted.withValues(alpha: 0.800);
        text = 'Uitnodiging gesprek';
        break;
      case ApplicationStatus.documentsPending:
        backgroundColor = Colors.purple.withValues(alpha: 0.100);
        textColor = Colors.purple.withValues(alpha: 0.800);
        text = 'Wachten op documenten';
        break;
      case ApplicationStatus.contractOffered:
        backgroundColor = Colors.teal.withValues(alpha: 0.100);
        textColor = Colors.teal.withValues(alpha: 0.800);
        text = 'Contract aangeboden';
        break;
      case ApplicationStatus.interviewScheduled:
        backgroundColor = Colors.indigo.withValues(alpha: 0.100);
        textColor = Colors.indigo.withValues(alpha: 0.800);
        text = 'Gesprek ingepland';
        break;
    }

    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS, vertical: DesignTokens.spacingXS),
      backgroundColor: backgroundColor,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: DesignTokens.fontSizeXS,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    );
  }

  Future<void> _updateApplicationStatus(ApplicationData application, ApplicationStatus newStatus) async {
    try {
      final success = await ApplicationService.updateApplicationStatus(application.id, newStatus);
      
      if (success && mounted) {
        setState(() {
          final index = _applications.indexWhere((app) => app.id == application.id);
          if (index != -1) {
            _applications[index].status = newStatus;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == ApplicationStatus.accepted 
                  ? 'Sollicitatie geaccepteerd'
                  : 'Sollicitatie afgewezen',
            ),
            backgroundColor: newStatus == ApplicationStatus.accepted ? DesignTokens.statusConfirmed : DesignTokens.statusPending,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij bijwerken van sollicitatie'),
            backgroundColor: DesignTokens.statusCancelled,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout: ${e.toString()}'),
            backgroundColor: DesignTokens.statusCancelled,
          ),
        );
      }
    }
  }
}
