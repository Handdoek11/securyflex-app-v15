import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';

/// Drag and Drop Job Scheduler for desktop
/// Allows companies to drag guards onto shifts for quick assignment
class DragDropJobScheduler extends StatefulWidget {
  const DragDropJobScheduler({super.key});

  @override
  State<DragDropJobScheduler> createState() => _DragDropJobSchedulerState();
}

class _DragDropJobSchedulerState extends State<DragDropJobScheduler> {
  // Sample data structures
  final List<Job> _jobs = [
    Job(id: '1', title: 'Winkelcentrum Beveiliging', location: 'Amsterdam', date: '28 Jan', requiredGuards: 3, assignedGuards: []),
    Job(id: '2', title: 'Evenement Security', location: 'Rotterdam', date: '29 Jan', requiredGuards: 5, assignedGuards: []),
    Job(id: '3', title: 'Kantoor Beveiliging', location: 'Utrecht', date: '30 Jan', requiredGuards: 2, assignedGuards: []),
    Job(id: '4', title: 'Bouwplaats Bewaking', location: 'Den Haag', date: '31 Jan', requiredGuards: 4, assignedGuards: []),
  ];

  final List<Guard> _availableGuards = [
    Guard(id: '1', name: 'Jan de Vries', certificates: ['WPBR', 'BHV'], rating: 4.8, avatar: 'JV'),
    Guard(id: '2', name: 'Maria Bakker', certificates: ['WPBR', 'EHBO'], rating: 4.6, avatar: 'MB'),
    Guard(id: '3', name: 'Peter Jansen', certificates: ['WPBR', 'VCA'], rating: 4.9, avatar: 'PJ'),
    Guard(id: '4', name: 'Sophie van Dam', certificates: ['WPBR', 'BHV', 'EHBO'], rating: 4.7, avatar: 'SD'),
    Guard(id: '5', name: 'Ahmed Hassan', certificates: ['WPBR'], rating: 4.5, avatar: 'AH'),
    Guard(id: '6', name: 'Linda Smit', certificates: ['WPBR', 'VCA', 'BHV'], rating: 4.8, avatar: 'LS'),
  ];

  Guard? _draggedGuard;
  String? _hoveredJobId;
  bool _showSuccessAnimation = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      height: 600, // Fixed height to prevent unbounded constraints
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          Flexible(
            fit: FlexFit.loose,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Jobs column
                Flexible(
                  flex: 3,
                  fit: FlexFit.loose,
                  child: _buildJobsColumn(colorScheme),
                ),
                SizedBox(width: DesignTokens.spacingL),
                // Available guards column
                SizedBox(
                  width: 300,
                  child: _buildGuardsColumn(colorScheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.calendar_month, color: colorScheme.primary, size: 28),
        SizedBox(width: DesignTokens.spacingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Planning - Drag & Drop',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Sleep guards naar opdrachten om ze toe te wijzen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Spacer(),
        // Quick stats
        _buildQuickStat('Totaal Guards', '${_availableGuards.length}', Icons.people, DesignTokens.colorInfo, colorScheme),
        SizedBox(width: DesignTokens.spacingL),
        _buildQuickStat('Open Shifts', '${_jobs.fold(0, (sum, job) => sum + (job.requiredGuards - job.assignedGuards.length))}', Icons.warning, DesignTokens.colorWarning, colorScheme),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobsColumn(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opdrachten',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Expanded(
          child: ListView.builder(
            itemCount: _jobs.length,
            itemBuilder: (context, index) {
              return _buildJobCard(_jobs[index], colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(Job job, ColorScheme colorScheme) {
    final needsGuards = job.requiredGuards - job.assignedGuards.length;
    final isComplete = needsGuards <= 0;
    final isHovered = _hoveredJobId == job.id;

    return DragTarget<Guard>(
      onWillAccept: (guard) {
        if (!isComplete && guard != null) {
          setState(() => _hoveredJobId = job.id);
          return true;
        }
        return false;
      },
      onLeave: (_) => setState(() => _hoveredJobId = null),
      onAccept: (guard) {
        setState(() {
          job.assignedGuards.add(guard);
          _availableGuards.remove(guard);
          _hoveredJobId = null;
          _showSuccessAnimation = true;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${guard.name} toegewezen aan ${job.title}'),
            backgroundColor: DesignTokens.colorSuccess,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) setState(() => _showSuccessAnimation = false);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: isHovered 
              ? DesignTokens.colorInfo.withValues(alpha: 0.1)
              : colorScheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(
              color: isHovered 
                ? DesignTokens.colorInfo
                : isComplete 
                  ? DesignTokens.colorSuccess.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isHovered ? 2 : 1,
            ),
            boxShadow: isHovered ? [
              BoxShadow(
                color: DesignTokens.colorInfo.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : [],
          ),
          child: UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job header
                Row(
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : Icons.work_outline,
                      color: isComplete ? DesignTokens.colorSuccess : colorScheme.primary,
                      size: 24,
                    ),
                    SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: colorScheme.onSurfaceVariant),
                              SizedBox(width: 4),
                              Text(job.location, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              SizedBox(width: 16),
                              Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                              SizedBox(width: 4),
                              Text(job.date, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isComplete 
                          ? DesignTokens.colorSuccess.withValues(alpha: 0.1)
                          : needsGuards > 0 
                            ? DesignTokens.colorWarning.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isComplete 
                            ? DesignTokens.colorSuccess
                            : DesignTokens.colorWarning,
                        ),
                      ),
                      child: Text(
                        isComplete 
                          ? 'Volledig' 
                          : 'Nog $needsGuards nodig',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isComplete 
                            ? DesignTokens.colorSuccess
                            : DesignTokens.colorWarning,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: DesignTokens.spacingM),
                
                // Progress bar
                LinearProgressIndicator(
                  value: job.assignedGuards.length / job.requiredGuards,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? DesignTokens.colorSuccess : DesignTokens.colorInfo,
                  ),
                ),
                
                SizedBox(height: DesignTokens.spacingM),
                
                // Assigned guards
                if (job.assignedGuards.isNotEmpty) ...[
                  Text(
                    'Toegewezen Guards (${job.assignedGuards.length}/${job.requiredGuards})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job.assignedGuards.map((guard) => _buildAssignedGuardChip(guard, job, colorScheme)).toList(),
                  ),
                ] else
                  Container(
                    padding: EdgeInsets.all(DesignTokens.spacingM),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_downward, size: 16, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        SizedBox(width: 8),
                        Text(
                          'Sleep guards hierheen om toe te wijzen',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignedGuardChip(Guard guard, Job job, ColorScheme colorScheme) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: Text(
          guard.avatar,
          style: TextStyle(fontSize: 10, color: colorScheme.onPrimary),
        ),
      ),
      label: Text(guard.name, style: TextStyle(fontSize: 12)),
      deleteIcon: Icon(Icons.close, size: 16),
      onDeleted: () {
        setState(() {
          job.assignedGuards.remove(guard);
          _availableGuards.add(guard);
        });
      },
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      deleteIconColor: colorScheme.error,
    );
  }

  Widget _buildGuardsColumn(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beschikbare Guards',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSubtitle,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Zoek guard...',
            prefixIcon: Icon(Icons.search, size: 20),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Expanded(
          child: ListView.builder(
            itemCount: _availableGuards.length,
            itemBuilder: (context, index) {
              return _buildDraggableGuardCard(_availableGuards[index], colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDraggableGuardCard(Guard guard, ColorScheme colorScheme) {
    return Draggable<Guard>(
      data: guard,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          width: 250,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: colorScheme.primary, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary,
                child: Text(guard.avatar, style: TextStyle(color: colorScheme.onPrimary)),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    guard.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Wordt toegewezen...',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildGuardCard(guard, colorScheme, isDragging: true),
      ),
      child: _buildGuardCard(guard, colorScheme, isDragging: false),
    );
  }

  Widget _buildGuardCard(Guard guard, ColorScheme colorScheme, {required bool isDragging}) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: isDragging 
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            guard.avatar,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          guard.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              children: guard.certificates.map((cert) => Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.colorInfo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cert,
                  style: TextStyle(fontSize: 10, color: DesignTokens.colorInfo),
                ),
              )).toList(),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: DesignTokens.colorWarning),
                Text(
                  ' ${guard.rating}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.drag_indicator,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// Data models
class Job {
  final String id;
  final String title;
  final String location;
  final String date;
  final int requiredGuards;
  final List<Guard> assignedGuards;

  Job({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.requiredGuards,
    required this.assignedGuards,
  });
}

class Guard {
  final String id;
  final String name;
  final List<String> certificates;
  final double rating;
  final String avatar;

  Guard({
    required this.id,
    required this.name,
    required this.certificates,
    required this.rating,
    required this.avatar,
  });
}