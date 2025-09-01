import 'package:flutter/material.dart';
import '../unified_design_tokens.dart';

/// Modern, performance-optimized job management widget
/// 
/// This replaces the legacy job_management_widget.dart with:
/// - Maximum 3 nesting levels (vs 5+ in legacy)
/// - Consolidated styling via UnifiedDashboardCard
/// - Clean job management interface
/// - Material 3 compliance
/// - Performance-first design
class ModernJobManagementWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final List<CompanyJob>? jobs;
  final VoidCallback? onCreateJob;
  final VoidCallback? onViewAll;

  const ModernJobManagementWidget({
    super.key,
    this.animationController,
    this.animation,
    this.jobs,
    this.onCreateJob,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final companyJobs = jobs ?? CompanyJob.mockJobs();
    
    // Temporarily replace UnifiedDashboardCard with simple Container for debugging
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.statusPending.withValues(alpha: 0.1),
        border: Border.all(color: DesignTokens.statusPending, width: 2),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opdracht Beheer',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: DesignTokens.statusPending,
            ),
          ),
          Text(
            '${companyJobs.length} actieve opdrachten',
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.statusPending.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: DesignTokens.statusPending,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nieuwe Opdracht',
                  style: TextStyle(
                    color: DesignTokens.colorWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: DesignTokens.statusPending),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Bekijk alles',
                  style: TextStyle(
                    color: DesignTokens.statusPending,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Jobs content
          companyJobs.isEmpty
            ? Container(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Column(
                  children: [
                    Icon(Icons.work_off, size: 48, color: Colors.grey),
                    SizedBox(height: DesignTokens.spacingM),
                    Text(
                      'Geen actieve opdrachten',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DesignTokens.colorGray600,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingS),
                    Text(
                      'Maak je eerste opdracht aan om beveiligers te vinden',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                children: companyJobs.take(3).map((job) => Container(
                  margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: DesignTokens.colorWhite,
                    border: Border.all(color: DesignTokens.statusPending.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: DesignTokens.statusPending.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.security, color: DesignTokens.statusPending),
                      ),
                      SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${job.location} • ${job.rate}',
                              style: TextStyle(
                                color: DesignTokens.colorGray600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: job.status == CompanyJobStatus.active
                            ? DesignTokens.statusConfirmed.withValues(alpha: 0.1)
                            : DesignTokens.statusPending.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          job.status == CompanyJobStatus.active ? 'Actief' : 'Concept',
                          style: TextStyle(
                            color: job.status == CompanyJobStatus.active
                              ? DesignTokens.statusConfirmed.withValues(alpha: 0.7)
                              : DesignTokens.statusPending.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
        ],
      ),
    );
  }





}

/// Data model for company jobs
class CompanyJob {
  final String id;
  final String title;
  final String location;
  final String rate;
  final String schedule;
  final int applicants;
  final CompanyJobStatus status;

  const CompanyJob({
    required this.id,
    required this.title,
    required this.location,
    required this.rate,
    required this.schedule,
    required this.applicants,
    required this.status,
  });

  /// Mock data for development and testing
  static List<CompanyJob> mockJobs() {
    return [
      const CompanyJob(
        id: '1',
        title: 'Winkelcentrum Beveiliging',
        location: 'Amsterdam Zuidoost',
        rate: '€42/u',
        schedule: 'Ma-Vr 09:00-17:00',
        applicants: 8,
        status: CompanyJobStatus.active,
      ),
      const CompanyJob(
        id: '2',
        title: 'Evenement Security',
        location: 'Rotterdam Centrum',
        rate: '€45/u',
        schedule: 'Za 18:00-02:00',
        applicants: 12,
        status: CompanyJobStatus.active,
      ),
      const CompanyJob(
        id: '3',
        title: 'Kantoor Beveiliging',
        location: 'Utrecht',
        rate: '€38/u',
        schedule: 'Ma-Vr 22:00-06:00',
        applicants: 3,
        status: CompanyJobStatus.draft,
      ),
    ];
  }

  /// Create from API response
  factory CompanyJob.fromJson(Map<String, dynamic> json) {
    return CompanyJob(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      rate: json['rate'] ?? '',
      schedule: json['schedule'] ?? '',
      applicants: json['applicants'] ?? 0,
      status: CompanyJobStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CompanyJobStatus.draft,
      ),
    );
  }
}

/// Company job status enumeration
enum CompanyJobStatus {
  active,
  draft,
  filled,
  expired,
}
