import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/marketplace/widgets/job_card_with_images.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/company_dashboard/services/premium_job_image_service.dart';
import 'package:securyflex_app/company_dashboard/models/job_image_data.dart' as img_data;
import 'package:securyflex_app/marketplace/repository/static_job_repository.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens

/// Applications Tab Component
/// Extracted from MyApplicationsScreen to be used in TabBarView
/// Maintains all existing functionality: real-time updates, filtering, status management
/// Follows SecuryFlex unified design system and Dutch localization
class ApplicationsTab extends StatefulWidget {
  const ApplicationsTab({
    super.key,
    required this.animationController,
    this.onJobSelected, // Cross-tab navigation hook
  });

  final AnimationController animationController;
  final Function(String jobId)? onJobSelected; // For navigating to job details

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> {
  List<ApplicationData> _applications = [];
  List<ApplicationData> _filteredApplications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  ApplicationStatus? _selectedFilter;
  StreamSubscription<List<ApplicationData>>? _applicationsSubscription;
  final PremiumJobImageService _imageService = PremiumJobImageService.instance;
  final Map<String, List<img_data.JobImageData>> _jobImages = {};
  final Map<String, SecurityJobData> _jobDataCache = {};

  @override
  void initState() {
    super.initState();
    _startWatchingApplications();
    _loadJobData();
  }
  
  Future<void> _loadJobData() async {
    // Load job data from repository for application cards
    final repository = StaticJobRepository();
    final jobs = await repository.getJobs();
    for (final job in jobs) {
      _jobDataCache[job.jobId] = job;
      // Load images for each job
      try {
        final images = await _imageService.getJobImages(job.id);
        if (mounted) {
          setState(() {
            _jobImages[job.id] = images;
          });
        }
      } catch (e) {
        debugPrint('Failed to load images for job ${job.id}: $e');
      }
    }
  }

  @override
  void dispose() {
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
        .watchUserApplications()
        .listen(
          (applications) {
            if (mounted) {
              setState(() {
                _applications = applications;
                _updateFilteredApplications();
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
    // Transparant voor gradient achtergrond
    return Theme(
      data: SecuryFlexTheme.getTheme(UserRole.guard),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                SecuryFlexTheme.getColorScheme(UserRole.guard).primary,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Sollicitaties laden...',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.colorGray600,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: DesignTokens.statusCancelled),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.statusCancelled,
                fontFamily: DesignTokens.fontFamily,
              ),
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
            Icon(Icons.work_outline, size: 64, color: DesignTokens.colorGray400), // ✅ Design token
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Nog geen sollicitaties',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Je hebt nog niet gesolliciteerd op jobs.\nBekijk de beschikbare jobs om te beginnen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.colorGray600,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            UnifiedButton.primary(
              text: 'Jobs bekijken',
              onPressed: () {
                // Cross-tab navigation hook - switch to Jobs tab
                if (widget.onJobSelected != null) {
                  widget.onJobSelected!(''); // Empty string indicates switch to jobs tab
                }
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) {
          _startWatchingApplications();
        }
      },
      child: ListView.builder(
        itemCount: _filteredApplications.length + 1, // +1 for section title
        padding: EdgeInsets.only(top: DesignTokens.spacingS),
        itemBuilder: (context, index) {
          // First item is the section title
          if (index == 0) {
            // Safety check before animating
            if (widget.animationController.isAnimating == false) {
              widget.animationController.forward();
            }

            return Container(
              padding: EdgeInsets.all(DesignTokens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mijn Sollicitaties',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeTitle,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: DesignTokens.fontFamily,
                      color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'Overzicht van al je sollicitaties en hun status',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontFamily: DesignTokens.fontFamily,
                      color: SecuryFlexTheme.getColorScheme(UserRole.guard).onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          // Adjust index for application items
          final appIndex = index - 1;

          // Dashboard-style staggered animation with optimized count
          final int count = _filteredApplications.length > 8 ? 8 : _filteredApplications.length;
          Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: widget.animationController,
                  curve: Interval(
                    0.2 + (0.8 / count) * (appIndex % count), // Start after title animation
                    1.0,
                    curve: Curves.fastOutSlowIn,
                  ),
                ),
              );

          return Container(
            margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM, vertical: DesignTokens.spacingS),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildApplicationCard(_filteredApplications[appIndex]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateFilteredApplications() {
    if (_selectedFilter == null) {
      _filteredApplications = List.from(_applications);
    } else {
      _filteredApplications = _applications
          .where((app) => app.status == _selectedFilter)
          .toList();
    }
  }

  Future<void> _withdrawApplication(String applicationId) async {
    try {
      await ApplicationService.withdrawApplication(applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sollicitatie ingetrokken'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij intrekken: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildApplicationCard(ApplicationData application) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with job title, company, and status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.jobTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            application.companyName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.colorGray600,
                              fontFamily: DesignTokens.fontFamily,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (application.location != null) ...[
                          SizedBox(width: DesignTokens.spacingS),
                          Icon(Icons.location_on, size: 14, color: DesignTokens.guardTextSecondary),
                          SizedBox(width: DesignTokens.spacingXS),
                          Expanded(
                            flex: 1,
                            child: Text(
                              application.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: DesignTokens.guardTextSecondary,
                                fontFamily: DesignTokens.fontFamily,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusChip(application.status),
            ],
          ),
          
          SizedBox(height: DesignTokens.spacingS),
          
          // Basic application info
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: DesignTokens.colorGray600),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                'Gesolliciteerd op ${DateFormat('dd MMM yyyy', 'nl_NL').format(application.applicationDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.colorGray600,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              if (application.salaryOffered != null) ...[
                Spacer(),
                Icon(Icons.euro, size: 16, color: DesignTokens.statusConfirmed.withValues(alpha: 0.600)),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  '€${application.salaryOffered!.toStringAsFixed(2)}/uur',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.statusConfirmed.withValues(alpha: 0.700),
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ],
          ),
          
          // Company response message
          if (application.companyResponse != null) ...[
            SizedBox(height: DesignTokens.spacingS),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(DesignTokens.spacingS),
              decoration: BoxDecoration(
                color: _getStatusBackgroundColor(application.status),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(color: _getStatusBorderColor(application.status)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(application.status),
                        color: _getStatusTextColor(application.status),
                        size: 16,
                      ),
                      SizedBox(width: DesignTokens.spacingXS),
                      Text(
                        'Reactie van ${application.companyName}',
                        style: TextStyle(
                          color: _getStatusTextColor(application.status),
                          fontSize: DesignTokens.fontSizeS,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    application.companyResponse!,
                    style: TextStyle(
                      color: _getStatusTextColor(application.status),
                      fontSize: DesignTokens.fontSizeS,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Status-specific details
          ..._buildStatusSpecificContent(application),
          
          // Action buttons
          if (_shouldShowActionButtons(application)) ...[
            SizedBox(height: DesignTokens.spacingS),
            ..._buildActionButtons(application),
          ],
          
          // Cross-tab navigation: View job details
          if (widget.onJobSelected != null) ...[
            SizedBox(height: DesignTokens.spacingS),
            UnifiedButton.secondary(
              text: 'Job bekijken',
              onPressed: () => widget.onJobSelected!(application.jobId),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ApplicationStatus status) {
    final backgroundColor = _getStatusBackgroundColor(status);
    final textColor = _getStatusTextColor(status);
    final text = status.displayTextNL;
    final icon = _getStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Get status background color
  Color _getStatusBackgroundColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return DesignTokens.statusPending.withValues(alpha: 0.100);
      case ApplicationStatus.accepted:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.100);
      case ApplicationStatus.rejected:
        return DesignTokens.statusCancelled.withValues(alpha: 0.100);
      case ApplicationStatus.withdrawn:
        return DesignTokens.statusArchived.withValues(alpha: 0.200); // ✅ Design token voor withdrawn
      case ApplicationStatus.interviewInvited:
        return DesignTokens.statusAccepted.withValues(alpha: 0.100);
      case ApplicationStatus.documentsPending:
        return DesignTokens.statusDraft.withValues(alpha: 0.100); // ✅ Design token voor pending documents
      case ApplicationStatus.contractOffered:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.200);
      case ApplicationStatus.interviewScheduled:
        return DesignTokens.statusPending.withValues(alpha: 0.100);
    }
  }
  
  /// Get status text color
  Color _getStatusTextColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return DesignTokens.statusPending.withValues(alpha: 0.800);
      case ApplicationStatus.accepted:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.800);
      case ApplicationStatus.rejected:
        return DesignTokens.statusCancelled.withValues(alpha: 0.800);
      case ApplicationStatus.withdrawn:
        return DesignTokens.statusArchived.withValues(alpha: 0.800); // ✅ Design token voor withdrawn
      case ApplicationStatus.interviewInvited:
        return DesignTokens.statusAccepted.withValues(alpha: 0.800);
      case ApplicationStatus.documentsPending:
        return DesignTokens.statusDraft.withValues(alpha: 0.800); // ✅ Design token voor pending documents
      case ApplicationStatus.contractOffered:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.900);
      case ApplicationStatus.interviewScheduled:
        return DesignTokens.statusPending.withValues(alpha: 0.800);
    }
  }
  
  /// Get status border color
  Color _getStatusBorderColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return DesignTokens.statusPending.withValues(alpha: 0.300);
      case ApplicationStatus.accepted:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.300);
      case ApplicationStatus.rejected:
        return DesignTokens.statusCancelled.withValues(alpha: 0.300);
      case ApplicationStatus.withdrawn:
        return DesignTokens.colorGray400;
      case ApplicationStatus.interviewInvited:
        return DesignTokens.statusAccepted.withValues(alpha: 0.300);
      case ApplicationStatus.documentsPending:
        return DesignTokens.statusDraft.withValues(alpha: 0.300); // ✅ Design token voor pending documents
      case ApplicationStatus.contractOffered:
        return DesignTokens.statusConfirmed.withValues(alpha: 0.400);
      case ApplicationStatus.interviewScheduled:
        return DesignTokens.statusPending.withValues(alpha: 0.300);
    }
  }
  
  /// Get status icon
  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.accepted:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.cancel;
      case ApplicationStatus.withdrawn:
        return Icons.remove_circle;
      case ApplicationStatus.interviewInvited:
        return Icons.calendar_today;
      case ApplicationStatus.documentsPending:
        return Icons.description;
      case ApplicationStatus.contractOffered:
        return Icons.assignment;
      case ApplicationStatus.interviewScheduled:
        return Icons.event;
    }
  }
  
  /// Build status-specific content based on application status
  List<Widget> _buildStatusSpecificContent(ApplicationData application) {
    switch (application.status) {
      case ApplicationStatus.interviewInvited:
      case ApplicationStatus.interviewScheduled:
        return _buildInterviewContent(application);
      case ApplicationStatus.documentsPending:
        return _buildDocumentsContent(application);
      case ApplicationStatus.contractOffered:
        return _buildContractContent(application);
      case ApplicationStatus.accepted:
        return _buildAcceptedContent(application);
      case ApplicationStatus.rejected:
        return _buildRejectedContent(application);
      default:
        return [];
    }
  }
  
  /// Build interview-specific content
  List<Widget> _buildInterviewContent(ApplicationData application) {
    if (application.interviewDate == null) return [];
    
    return [
      SizedBox(height: DesignTokens.spacingS),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: DesignTokens.statusAccepted.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(color: DesignTokens.statusAccepted.withValues(alpha: 0.200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: DesignTokens.statusAccepted.withValues(alpha: 0.700), size: 16),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Interview Details',
                  style: TextStyle(
                    color: DesignTokens.statusAccepted.withValues(alpha: 0.700),
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Datum: ${DateFormat('EEEE dd MMMM yyyy, HH:mm', 'nl_NL').format(application.interviewDate!)}',
              style: TextStyle(
                color: DesignTokens.statusAccepted.withValues(alpha: 0.800),
                fontSize: DesignTokens.fontSizeS,
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            if (application.interviewType != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Row(
                children: [
                  Icon(
                    application.interviewType == 'video' ? Icons.videocam : Icons.location_on,
                    color: DesignTokens.statusAccepted.withValues(alpha: 0.600),
                    size: 14,
                  ),
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    application.interviewType == 'video' ? 'Video interview' : 
                    application.interviewType == 'telefoon' ? 'Telefonisch interview' : 'Persoonlijk gesprek',
                    style: TextStyle(
                      color: DesignTokens.statusAccepted.withValues(alpha: 0.700),
                      fontSize: DesignTokens.fontSizeS,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            ],
            if (application.interviewDetails != null) ...[
              SizedBox(height: DesignTokens.spacingS),
              Text(
                application.interviewDetails!,
                style: TextStyle(
                  color: DesignTokens.statusAccepted.withValues(alpha: 0.700),
                  fontSize: DesignTokens.fontSizeS,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
  
  /// Build documents-pending content
  List<Widget> _buildDocumentsContent(ApplicationData application) {
    if (application.missingDocuments == null || application.missingDocuments!.isEmpty) return [];
    
    return [
      SizedBox(height: DesignTokens.spacingS),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: DesignTokens.statusDraft.withValues(alpha: 0.50), // ✅ Design token
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(color: DesignTokens.statusDraft.withValues(alpha: 0.200)), // ✅ Design token
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: DesignTokens.statusDraft.withValues(alpha: 0.700), size: 16), // ✅ Design token
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Ontbrekende documenten',
                  style: TextStyle(
                    color: DesignTokens.statusDraft.withValues(alpha: 0.700), // ✅ Design token
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingS),
            ...application.missingDocuments!.map((doc) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
              child: Row(
                children: [
                  Icon(Icons.check_box_outline_blank, color: DesignTokens.statusDraft.withValues(alpha: 0.600), size: 16), // ✅ Design token
                  SizedBox(width: DesignTokens.spacingXS),
                  Text(
                    doc,
                    style: TextStyle(
                      color: DesignTokens.statusDraft.withValues(alpha: 0.700), // ✅ Design token
                      fontSize: DesignTokens.fontSizeS,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    ];
  }
  
  /// Build contract-offered content
  List<Widget> _buildContractContent(ApplicationData application) {
    return [
      SizedBox(height: DesignTokens.spacingS),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: DesignTokens.statusConfirmed.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(color: DesignTokens.statusConfirmed.withValues(alpha: 0.300)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: DesignTokens.statusConfirmed.withValues(alpha: 0.800), size: 16),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Contract Details',
                  style: TextStyle(
                    color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
            if (application.salaryOffered != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                'Salaris: €${application.salaryOffered!.toStringAsFixed(2)} per uur',
                style: TextStyle(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
            if (application.startDate != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                'Startdatum: ${DateFormat('dd MMMM yyyy', 'nl_NL').format(application.startDate!)}',
                style: TextStyle(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                  fontSize: DesignTokens.fontSizeS,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
            if (application.contractType != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                'Type: ${application.contractType!}',
                style: TextStyle(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                  fontSize: DesignTokens.fontSizeS,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }
  
  /// Build accepted-status content
  List<Widget> _buildAcceptedContent(ApplicationData application) {
    return [
      SizedBox(height: DesignTokens.spacingS),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: DesignTokens.statusConfirmed.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(color: DesignTokens.statusConfirmed.withValues(alpha: 0.200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.celebration, color: DesignTokens.statusConfirmed.withValues(alpha: 0.700), size: 20),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Gefeliciteerd!',
                  style: TextStyle(
                    color: DesignTokens.statusConfirmed.withValues(alpha: 0.700),
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              'Je sollicitatie is geaccepteerd. Het bedrijf neemt binnenkort contact met je op voor de volgende stappen.',
              style: TextStyle(
                color: DesignTokens.statusConfirmed.withValues(alpha: 0.700),
                fontSize: DesignTokens.fontSizeS,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            if (application.startDate != null) ...[
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                'Startdatum: ${DateFormat('dd MMMM yyyy', 'nl_NL').format(application.startDate!)}',
                style: TextStyle(
                  color: DesignTokens.statusConfirmed.withValues(alpha: 0.800),
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
            // Add action button to view in Active tab
            SizedBox(height: DesignTokens.spacingM),
            ElevatedButton.icon(
              onPressed: () => _navigateToActiveTab(application),
              icon: Icon(Icons.work, size: 18),
              label: Text('Bekijk in Actief'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.statusConfirmed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
  
  /// Navigate to Active tab and trigger shift conversion if needed
  void _navigateToActiveTab(ApplicationData application) async {
    // Switch to Active tab (index 2)
    DefaultTabController.of(context).animateTo(2);
  }
  
  /// Build rejected-status content
  List<Widget> _buildRejectedContent(ApplicationData application) {
    if (application.rejectionReason == null) return [];
    
    return [
      SizedBox(height: DesignTokens.spacingS),
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: DesignTokens.statusCancelled.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          border: Border.all(color: DesignTokens.statusCancelled.withValues(alpha: 0.200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: DesignTokens.statusCancelled.withValues(alpha: 0.700), size: 16),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Reden van afwijzing',
                  style: TextStyle(
                    color: DesignTokens.statusCancelled.withValues(alpha: 0.700),
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              application.rejectionReason!,
              style: TextStyle(
                color: DesignTokens.statusCancelled.withValues(alpha: 0.700),
                fontSize: DesignTokens.fontSizeS,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ],
        ),
      ),
    ];
  }
  
  /// Check if action buttons should be shown
  bool _shouldShowActionButtons(ApplicationData application) {
    return application.status == ApplicationStatus.interviewInvited ||
           application.status == ApplicationStatus.documentsPending ||
           application.status == ApplicationStatus.contractOffered;
  }
  
  /// Build action buttons based on application status
  List<Widget> _buildActionButtons(ApplicationData application) {
    switch (application.status) {
      case ApplicationStatus.interviewInvited:
        return [
          Row(
            children: [
              Expanded(
                child: UnifiedButton.secondary(
                  text: 'Interview bevestigen',
                  onPressed: () => _confirmInterview(application),
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: UnifiedButton.primary(
                  text: 'Details bekijken',
                  onPressed: () => _showInterviewDetails(application),
                ),
              ),
            ],
          ),
        ];
      case ApplicationStatus.documentsPending:
        return [
          UnifiedButton.primary(
            text: 'Documenten uploaden',
            onPressed: () => _uploadDocuments(application),
          ),
        ];
      case ApplicationStatus.contractOffered:
        return [
          Row(
            children: [
              Expanded(
                child: UnifiedButton.secondary(
                  text: 'Contract bekijken',
                  onPressed: () => _viewContract(application),
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: UnifiedButton.primary(
                  text: 'Accepteren',
                  onPressed: () => _acceptContract(application),
                ),
              ),
            ],
          ),
        ];
      default:
        return [];
    }
  }
  
  // Action button handlers (placeholder implementations)
  void _confirmInterview(ApplicationData application) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Interview bevestigd voor ${application.companyName}'),
        backgroundColor: DesignTokens.statusAccepted.withValues(alpha: 0.600),
      ),
    );
  }
  
  void _showInterviewDetails(ApplicationData application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Interview Details',
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        content: Text(
          application.interviewDetails ?? 'Geen verdere details beschikbaar.',
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        actions: [
          UnifiedButton.primary(
            text: 'Sluiten',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  void _uploadDocuments(ApplicationData application) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document upload functionaliteit wordt binnenkort beschikbaar'),
        backgroundColor: DesignTokens.statusDraft.withValues(alpha: 0.600), // ✅ Design token
      ),
    );
  }
  
  void _viewContract(ApplicationData application) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contract wordt geopend...'),
        backgroundColor: DesignTokens.statusConfirmed.withValues(alpha: 0.600),
      ),
    );
  }
  
  void _acceptContract(ApplicationData application) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Contract Accepteren',
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        content: Text(
          'Weet je zeker dat je het contract van ${application.companyName} wilt accepteren?',
          style: TextStyle(fontFamily: DesignTokens.fontFamily),
        ),
        actions: [
          UnifiedButton.secondary(
            text: 'Annuleren',
            onPressed: () => Navigator.pop(context),
          ),
          UnifiedButton.primary(
            text: 'Accepteren',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Contract geaccepteerd!'),
                  backgroundColor: DesignTokens.statusConfirmed.withValues(alpha: 0.600),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
