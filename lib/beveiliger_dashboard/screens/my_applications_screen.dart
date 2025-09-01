import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';


/// Screen for guards to track their job applications
/// Shows all applications with current status and details
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<ApplicationData> _applications = [];
  List<ApplicationData> _filteredApplications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  ApplicationStatus? _selectedFilter;
  StreamSubscription<List<ApplicationData>>? _applicationsSubscription;

  @override
  void initState() {
    super.initState();
    _startWatchingApplications();
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
    _applicationsSubscription = ApplicationService.watchUserApplications()
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
                _errorMessage =
                    'Fout bij laden van sollicitaties: ${error.toString()}';
                _isLoading = false;
              });
            }
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: UnifiedHeader.simple(
            title: 'Mijn Sollicitaties',
            userRole: UserRole.guard,
            titleAlignment: TextAlign.left,
            leading: HeaderElements.backButton(
              userRole: UserRole.guard,
              onPressed: () => context.pop(),
            ),
          ),
        ),
            body: _buildBody(),
          ),
        ),
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
            SizedBox(height: 16),
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
            Icon(Icons.error_outline, size: 64, color: DesignTokens.statusCancelled),
            SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: DesignTokens.statusCancelled),
            ),
            SizedBox(height: 16),
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
            Icon(Icons.work_outline, size: 64, color: DesignTokens.colorGray500),
            SizedBox(height: 16),
            Text(
              'Nog geen sollicitaties',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'Je hebt nog niet gesolliciteerd op jobs.\nBekijk de beschikbare jobs om te beginnen.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: DesignTokens.colorGray600),
            ),
            SizedBox(height: 24),
            UnifiedButton.primary(
              text: 'Jobs bekijken',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _startWatchingApplications(),
      child: ListView.builder(
        itemCount: _filteredApplications.length + 1, // +1 for section title
        padding: EdgeInsets.only(top: DesignTokens.spacingS),
        cacheExtent: 1000.0, // Performance optimization: pre-cache 1000px of content
        itemBuilder: (context, index) {
          // First item is the section title
          if (index == 0) {
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

          return RepaintBoundary(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM, vertical: DesignTokens.spacingS),
              child: _buildApplicationCard(_filteredApplications[appIndex]),
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

  Widget _buildApplicationCard(ApplicationData application) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      ),
                    ),
                    Text(
                      application.companyName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: DesignTokens.colorGray600),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(application.status),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: DesignTokens.colorGray600),
              SizedBox(width: 4),
              Text(
                'Gesolliciteerd op ${DateFormat('dd MMM yyyy').format(application.applicationDate)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: DesignTokens.colorGray600),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.contact_mail, size: 16, color: DesignTokens.colorGray600),
              SizedBox(width: 4),
              Text(
                'Contact: ${application.contactPreference}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: DesignTokens.colorGray600),
              ),
            ],
          ),
          if (application.status == ApplicationStatus.accepted) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DesignTokens.statusConfirmed.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                border: Border.all(color: DesignTokens.statusConfirmed.withValues(alpha: 0.200)),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: DesignTokens.statusConfirmed.withValues(alpha: 0.700), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gefeliciteerd! Je sollicitatie is geaccepteerd. Het bedrijf neemt binnenkort contact met je op.',
                      style: TextStyle(
                        color: DesignTokens.statusConfirmed.withValues(alpha: 0.700),
                        fontSize: DesignTokens.fontSizeCaption,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
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
    IconData icon;

    switch (status) {
      case ApplicationStatus.pending:
        backgroundColor = DesignTokens.statusPending.withValues(alpha: 0.100);
        textColor = DesignTokens.statusPending.withValues(alpha: 0.800);
        text = 'In behandeling';
        icon = Icons.schedule;
        break;
      case ApplicationStatus.accepted:
        backgroundColor = DesignTokens.statusConfirmed.withValues(alpha: 0.100);
        textColor = DesignTokens.statusConfirmed.withValues(alpha: 0.800);
        text = 'Geaccepteerd';
        icon = Icons.check_circle;
        break;
      case ApplicationStatus.rejected:
        backgroundColor = DesignTokens.statusCancelled.withValues(alpha: 0.100);
        textColor = DesignTokens.statusCancelled.withValues(alpha: 0.800);
        text = 'Afgewezen';
        icon = Icons.cancel;
        break;
      case ApplicationStatus.withdrawn:
        backgroundColor = DesignTokens.colorGray200;
        textColor = DesignTokens.colorGray700;
        text = 'Ingetrokken';
        icon = Icons.remove_circle;
        break;
      case ApplicationStatus.interviewInvited:
        backgroundColor = DesignTokens.statusAccepted.withValues(alpha: 0.100);
        textColor = DesignTokens.statusAccepted.withValues(alpha: 0.800);
        text = 'Uitnodiging gesprek';
        icon = Icons.event;
        break;
      case ApplicationStatus.documentsPending:
        backgroundColor = DesignTokens.statusPending.withValues(alpha: 0.100);
        textColor = DesignTokens.statusPending.withValues(alpha: 0.800);
        text = 'Wachten op documenten';
        icon = Icons.description;
        break;
      case ApplicationStatus.contractOffered:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;
        textColor = Theme.of(context).colorScheme.secondary;
        text = 'Contract aangeboden';
        icon = Icons.handshake;
        break;
      case ApplicationStatus.interviewScheduled:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;
        textColor = Theme.of(context).colorScheme.primary;
        text = 'Gesprek ingepland';
        icon = Icons.calendar_today;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: DesignTokens.fontSizeCaption,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
        ],
      ),
    );
  }
}
