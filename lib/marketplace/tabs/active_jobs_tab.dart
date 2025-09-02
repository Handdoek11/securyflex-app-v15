import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/demo_application_to_shift_converter.dart';
import '../../beveiliger_agenda/models/shift_data.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/premium_glass_system.dart';
import '../widgets/job_card_with_images.dart';
import '../model/security_job_data.dart';
import '../repository/static_job_repository.dart';
import '../../company_dashboard/services/premium_job_image_service.dart';
import '../../company_dashboard/models/job_image_data.dart' as img_data;
import 'package:intl/intl.dart';

/// Active Jobs Tab - Shows confirmed/active jobs that have been converted to shifts
/// 
/// This tab displays jobs where:
/// 1. Application has been accepted/confirmed
/// 2. Job has been converted to an active shift
/// 3. Guard can see work details and navigate to planning
class ActiveJobsTab extends StatefulWidget {
  final AnimationController animationController;
  
  const ActiveJobsTab({
    super.key,
    required this.animationController,
  });

  @override
  State<ActiveJobsTab> createState() => _ActiveJobsTabState();
}

class _ActiveJobsTabState extends State<ActiveJobsTab> {
  final DemoApplicationToShiftConverter _converter = DemoApplicationToShiftConverter();
  final PremiumJobImageService _imageService = PremiumJobImageService.instance;
  List<ShiftData> activeShifts = [];
  final Map<String, SecurityJobData> _jobDataCache = {};
  final Map<String, List<img_data.JobImageData>> _jobImages = {};
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadActiveJobs();
    _loadJobData();
  }
  
  Future<void> _loadJobData() async {
    // Load job data from repository for active job cards
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
  
  Future<void> _loadActiveJobs() async {
    setState(() => isLoading = true);
    
    try {
      // Get active shifts from demo converter
      final shifts = await _converter.getActiveShifts();
      
      setState(() {
        activeShifts = shifts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading active jobs: $e');
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }
    
    if (activeShifts.isEmpty) {
      return _buildEmptyState(colorScheme);
    }
    
    return RefreshIndicator(
      onRefresh: _loadActiveJobs,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        itemCount: activeShifts.length,
        itemBuilder: (context, index) {
          final shift = activeShifts[index];
          return _buildActiveJobCard(shift, colorScheme);
        },
      ),
    );
  }
  
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Geen actieve opdrachten',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              'Zodra je sollicitaties worden goedgekeurd,\nverschijnen ze hier als actieve opdrachten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXL),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to available jobs tab
                DefaultTabController.of(context).animateTo(0);
              },
              icon: Icon(Icons.search),
              label: Text('Bekijk beschikbare opdrachten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingL,
                  vertical: DesignTokens.spacingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActiveJobCard(ShiftData shift, ColorScheme colorScheme) {
    // Try to find corresponding job data
    final jobData = _jobDataCache.values.firstWhere(
      (job) => job.titleTxt == shift.title,
      orElse: () => SecurityJobData(
        jobId: shift.id,
        jobTitle: shift.title,
        companyName: shift.companyName,
        location: shift.location,
        companyRating: 4.5,
        applicantCount: 0,
        hourlyRate: shift.hourlyRate,
        imagePath: 'assets/images/default_job.png',
      ),
    );
    
    final jobImages = _jobImages[jobData.id] ?? [];
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: JobCardWithImages.activeShift(
        job: jobData,
        images: jobImages,
        shiftDate: shift.startTime,
        shiftTime: '${DateFormat('HH:mm').format(shift.startTime)} - ${DateFormat('HH:mm').format(shift.endTime)}',
        totalEarnings: shift.totalEarnings,
        isUrgent: shift.isUrgent,
        onTap: () => _navigateToShiftDetails(shift),
        onViewShift: () => _navigateToPlanning(shift),
      ),
    );
  }
  
  // Old implementation kept for reference - remove after testing
  Widget _buildActiveJobCardOld(ShiftData shift, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: PremiumGlassContainer(
        intensity: GlassIntensity.subtle,
        elevation: GlassElevation.raised,
        tintColor: colorScheme.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        padding: EdgeInsets.all(DesignTokens.spacingM),
        onTap: () => _navigateToShiftDetails(shift),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.title,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeSubtitle,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: colorScheme.onSurface,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        shift.companyName,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: DesignTokens.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(shift.status, colorScheme),
              ],
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            Divider(color: colorScheme.outlineVariant),
            SizedBox(height: DesignTokens.spacingM),
            
            // Shift details
            _buildDetailRow(
              Icons.calendar_today_outlined,
              DateFormat('dd MMMM yyyy', 'nl_NL').format(shift.startTime),
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildDetailRow(
              Icons.access_time_outlined,
              '${DateFormat('HH:mm').format(shift.startTime)} - ${DateFormat('HH:mm').format(shift.endTime)}',
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildDetailRow(
              Icons.location_on_outlined,
              shift.location,
              colorScheme,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildDetailRow(
              Icons.euro_outlined,
              '€${shift.hourlyRate.toStringAsFixed(2)}/uur (Totaal: €${shift.totalEarnings.toStringAsFixed(2)})',
              colorScheme,
            ),
            
            if (shift.isUrgent) ...[
              SizedBox(height: DesignTokens.spacingM),
              Container(
                padding: EdgeInsets.all(DesignTokens.spacingS),
                decoration: BoxDecoration(
                  color: DesignTokens.statusCancelled.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  border: Border.all(
                    color: DesignTokens.statusCancelled.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: DesignTokens.statusCancelled,
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Text(
                      'URGENTE OPDRACHT',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.statusCancelled,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            SizedBox(height: DesignTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToPlanning(shift),
                    icon: Icon(Icons.event_note_outlined, size: 18),
                    label: Text('Bekijk in Planning'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary),
                      padding: EdgeInsets.symmetric(
                        vertical: DesignTokens.spacingS,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToShiftDetails(shift),
                    icon: Icon(Icons.info_outline, size: 18),
                    label: Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        vertical: DesignTokens.spacingS,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(ShiftStatus status, ColorScheme colorScheme) {
    Color chipColor;
    String statusText;
    
    switch (status) {
      case ShiftStatus.confirmed:
        chipColor = DesignTokens.statusConfirmed;
        statusText = 'Bevestigd';
        break;
      case ShiftStatus.accepted:
        chipColor = DesignTokens.statusAccepted;
        statusText = 'Geaccepteerd';
        break;
      case ShiftStatus.inProgress:
        chipColor = DesignTokens.statusInProgress;
        statusText = 'Bezig';
        break;
      default:
        chipColor = colorScheme.primary;
        statusText = 'Actief';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeCaption,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: chipColor,
          fontFamily: DesignTokens.fontFamily,
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: colorScheme.onSurface,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ),
      ],
    );
  }
  
  void _navigateToShiftDetails(ShiftData shift) {
    // TODO: Navigate to shift details screen
    debugPrint('Navigate to shift details: ${shift.id}');
  }
  
  void _navigateToPlanning(ShiftData shift) {
    // Navigate to planning screen with this shift selected
    context.push('/beveiliger/schedule');
    // Original: Navigator.pushNamed(
    //   context,
    //   '/planning',
    //   arguments: {'selectedShiftId': shift.id},
    // );
  }
}