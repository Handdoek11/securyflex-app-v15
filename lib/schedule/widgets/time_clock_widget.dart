import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../blocs/schedule_bloc.dart';
import '../models/time_entry_model.dart';
import '../models/shift_model.dart';

/// UnifiedTimeClockWidget for GPS-verified time tracking
/// 
/// Features:
/// - Real-time clock display in Nederlandse timezone
/// - GPS verification status indicators
/// - Check-in/check-out buttons with location verification
/// - Break management controls
/// - CAO compliance warnings
/// - Role-based theming (guard/company/admin)
class UnifiedTimeClockWidget extends StatefulWidget {
  final UserRole userRole;
  final Shift? activeShift;
  final TimeEntry? currentTimeEntry;
  final Function(String notes)? onCheckIn;
  final Function(String notes)? onCheckOut;
  final Function(BreakEntryType type, Duration duration)? onStartBreak;
  final VoidCallback? onEndBreak;
  final bool showCAOWarnings;
  final bool showLocationStatus;

  const UnifiedTimeClockWidget({
    super.key,
    required this.userRole,
    this.activeShift,
    this.currentTimeEntry,
    this.onCheckIn,
    this.onCheckOut,
    this.onStartBreak,
    this.onEndBreak,
    this.showCAOWarnings = true,
    this.showLocationStatus = true,
  });

  @override
  State<UnifiedTimeClockWidget> createState() => _UnifiedTimeClockWidgetState();
}

class _UnifiedTimeClockWidgetState extends State<UnifiedTimeClockWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _statusController;
  final TextEditingController _notesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _statusController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            boxShadow: [DesignTokens.shadowMedium],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: DesignTokens.spacingL),
              _buildTimeDisplay(),
              const SizedBox(height: DesignTokens.spacingL),
              if (widget.showLocationStatus) _buildLocationStatus(),
              const SizedBox(height: DesignTokens.spacingL),
              _buildActionButtons(),
              if (widget.showCAOWarnings) ...[
                const SizedBox(height: DesignTokens.spacingM),
                _buildCAOWarnings(),
              ],
              if (_isOnBreak()) ...[
                const SizedBox(height: DesignTokens.spacingM),
                _buildBreakControls(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: _getPrimaryColor(),
          size: DesignTokens.iconSizeL,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Text(
            'Tijd Registratie',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeHeading,
              fontWeight: DesignTokens.fontWeightBold,
              color: _getTextPrimaryColor(),
            ),
          ),
        ),
        if (widget.activeShift != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingS,
              vertical: DesignTokens.spacingXS,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(widget.activeShift!.status),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Text(
              _getShiftStatusText(widget.activeShift!.status),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorWhite,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeDisplay() {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        
        return Column(
          children: [
            Text(
              _formatTime(now),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 48,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getPrimaryColor(),
              ),
            ),
            Text(
              _formatDate(now),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextSecondaryColor(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationStatus() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded || state.lastLocationUpdate == null) {
          return const SizedBox.shrink();
        }
        
        final location = state.lastLocationUpdate!;
        final isAccurate = location.accuracy <= 50.0;
        final isMocked = location.isMocked;
        
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: _getLocationStatusColor(isAccurate, isMocked),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Row(
            children: [
              Icon(
                _getLocationIcon(isAccurate, isMocked),
                color: DesignTokens.colorWhite,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocationStatusText(isAccurate, isMocked),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: DesignTokens.colorWhite,
                      ),
                    ),
                    Text(
                      'Nauwkeurigheid: ${location.accuracy.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: DesignTokens.colorWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final isCheckedIn = widget.currentTimeEntry?.checkInTime != null && 
                        widget.currentTimeEntry?.checkOutTime == null;
    
    if (!isCheckedIn) {
      return _buildCheckInButton();
    } else {
      return Column(
        children: [
          _buildCheckOutButton(),
          const SizedBox(height: DesignTokens.spacingM),
          _buildBreakButtons(),
        ],
      );
    }
  }

  Widget _buildCheckInButton() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        
        return AnimatedContainer(
          duration: DesignTokens.durationMedium,
          child: ElevatedButton.icon(
            onPressed: isLoading || widget.activeShift == null ? null : _showCheckInDialog,
            icon: isLoading 
                ? SizedBox(
                    width: DesignTokens.iconSizeM,
                    height: DesignTokens.iconSizeM,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(DesignTokens.colorWhite),
                    ),
                  )
                : AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.1),
                        child: Icon(
                          Icons.play_circle_fill,
                          size: DesignTokens.iconSizeL,
                        ),
                      );
                    },
                  ),
            label: Text(
              'Inchecken',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.colorSuccess,
              foregroundColor: DesignTokens.colorWhite,
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingL,
                horizontal: DesignTokens.spacingXL,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              ),
              elevation: DesignTokens.elevationMedium,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckOutButton() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        
        return ElevatedButton.icon(
          onPressed: isLoading ? null : _showCheckOutDialog,
          icon: isLoading 
              ? SizedBox(
                  width: DesignTokens.iconSizeM,
                  height: DesignTokens.iconSizeM,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(DesignTokens.colorWhite),
                  ),
                )
              : Icon(
                  Icons.stop_circle,
                  size: DesignTokens.iconSizeL,
                ),
          label: Text(
            'Uitchecken',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeL,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.colorError,
            foregroundColor: DesignTokens.colorWhite,
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.spacingL,
              horizontal: DesignTokens.spacingXL,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            elevation: DesignTokens.elevationMedium,
          ),
        );
      },
    );
  }

  Widget _buildBreakButtons() {
    if (_isOnBreak()) {
      return ElevatedButton.icon(
        onPressed: widget.onEndBreak,
        icon: Icon(
          Icons.play_arrow,
          size: DesignTokens.iconSizeM,
        ),
        label: Text(
          'Pauze beëindigen',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.colorInfo,
          foregroundColor: DesignTokens.colorWhite,
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingM,
            horizontal: DesignTokens.spacingL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
        ),
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _startBreak(BreakEntryType.mandatory, const Duration(minutes: 15)),
            icon: Icon(
              Icons.coffee,
              size: DesignTokens.iconSizeS,
              color: _getPrimaryColor(),
            ),
            label: Text(
              'Korte pauze',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getPrimaryColor(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _getPrimaryColor()),
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingS,
                horizontal: DesignTokens.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _startBreak(BreakEntryType.meal, const Duration(minutes: 30)),
            icon: Icon(
              Icons.restaurant,
              size: DesignTokens.iconSizeS,
              color: _getPrimaryColor(),
            ),
            label: Text(
              'Lunch pauze',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getPrimaryColor(),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _getPrimaryColor()),
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spacingS,
                horizontal: DesignTokens.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakControls() {
    final activeBreak = widget.currentTimeEntry?.breaks
        .where((b) => b.endTime == null)
        .firstOrNull;
    
    if (activeBreak == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWarningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorWarning),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.pause_circle,
                color: DesignTokens.colorWarning,
                size: DesignTokens.iconSizeM,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  'Actieve pauze',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.colorWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingS),
          StreamBuilder<DateTime>(
            stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
            builder: (context, snapshot) {
              final now = snapshot.data ?? DateTime.now();
              final duration = now.difference(activeBreak.startTime);
              
              return Text(
                '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.colorWarning,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCAOWarnings() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is! ScheduleLoaded || state.lastEarningsResult == null) {
          return const SizedBox.shrink();
        }
        
        final earnings = state.lastEarningsResult!;
        final violations = earnings.caoCompliance.violations;
        
        if (violations.isEmpty) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorErrorLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: DesignTokens.colorError),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: DesignTokens.colorError,
                    size: DesignTokens.iconSizeM,
                  ),
                  const SizedBox(width: DesignTokens.spacingS),
                  Text(
                    'CAO Waarschuwingen',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: DesignTokens.colorError,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingS),
              ...violations.map((violation) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spacingXS),
                child: Text(
                  '• ${violation.description}',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightRegular,
                    color: DesignTokens.colorError,
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  void _showCheckInDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Inchecken',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Weet u zeker dat u wilt inchecken voor deze dienst?',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextSecondaryColor(),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notities (optioneel)',
                hintText: 'Voeg eventuele opmerkingen toe...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Annuleren',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getTextSecondaryColor(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              widget.onCheckIn?.call(_notesController.text);
              _notesController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.colorSuccess,
              foregroundColor: DesignTokens.colorWhite,
            ),
            child: Text(
              'Inchecken',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Uitchecken',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Weet u zeker dat u wilt uitchecken?',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextSecondaryColor(),
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Afsluitnotities (optioneel)',
                hintText: 'Voeg eventuele opmerkingen toe...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Annuleren',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getTextSecondaryColor(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              widget.onCheckOut?.call(_notesController.text);
              _notesController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.colorError,
              foregroundColor: DesignTokens.colorWhite,
            ),
            child: Text(
              'Uitchecken',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startBreak(BreakEntryType type, Duration duration) {
    widget.onStartBreak?.call(type, duration);
  }

  bool _isOnBreak() {
    return widget.currentTimeEntry?.breaks
        .any((b) => b.endTime == null) ?? false;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'januari', 'februari', 'maart', 'april', 'mei', 'juni',
      'juli', 'augustus', 'september', 'oktober', 'november', 'december'
    ];
    const weekdays = [
      '', 'maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'
    ];
    
    return '${weekdays[date.weekday]} ${date.day} ${months[date.month]} ${date.year}';
  }

  Color _getBackgroundColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardBackground;
      case UserRole.company:
        return DesignTokens.companyBackground;
      case UserRole.admin:
        return DesignTokens.adminBackground;
    }
  }

  Color _getPrimaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  Color _getTextPrimaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextPrimary;
      case UserRole.company:
        return DesignTokens.companyTextPrimary;
      case UserRole.admin:
        return DesignTokens.adminTextPrimary;
    }
  }

  Color _getTextSecondaryColor() {
    switch (widget.userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextSecondary;
      case UserRole.company:
        return DesignTokens.companyTextSecondary;
      case UserRole.admin:
        return DesignTokens.adminTextSecondary;
    }
  }

  Color _getStatusColor(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return DesignTokens.statusDraft;
      case ShiftStatus.published:
        return DesignTokens.statusPending;
      case ShiftStatus.confirmed:
        return DesignTokens.statusConfirmed;
      case ShiftStatus.inProgress:
        return DesignTokens.statusInProgress;
      case ShiftStatus.completed:
        return DesignTokens.statusCompleted;
      case ShiftStatus.cancelled:
        return DesignTokens.statusCancelled;
      case ShiftStatus.noShow:
        return DesignTokens.colorError;
      case ShiftStatus.expired:
        return DesignTokens.statusExpired;
      case ShiftStatus.replacement:
        return DesignTokens.colorWarning;
      default:
        return DesignTokens.colorGray500;
    }
  }

  String _getShiftStatusText(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.draft:
        return 'Concept';
      case ShiftStatus.published:
        return 'Gepubliceerd';
      case ShiftStatus.confirmed:
        return 'Bevestigd';
      case ShiftStatus.inProgress:
        return 'Actief';
      case ShiftStatus.completed:
        return 'Voltooid';
      case ShiftStatus.cancelled:
        return 'Geannuleerd';
      case ShiftStatus.noShow:
        return 'Niet verschenen';
      case ShiftStatus.expired:
        return 'Verlopen';
      case ShiftStatus.replacement:
        return 'Vervanger';
      default:
        return 'Onbekend';
    }
  }

  Color _getLocationStatusColor(bool isAccurate, bool isMocked) {
    if (isMocked) return DesignTokens.colorError;
    if (isAccurate) return DesignTokens.colorSuccess;
    return DesignTokens.colorWarning;
  }

  IconData _getLocationIcon(bool isAccurate, bool isMocked) {
    if (isMocked) return Icons.location_off;
    if (isAccurate) return Icons.location_on;
    return Icons.location_searching;
  }

  String _getLocationStatusText(bool isAccurate, bool isMocked) {
    if (isMocked) return 'Nep locatie gedetecteerd';
    if (isAccurate) return 'GPS locatie bevestigd';
    return 'GPS signaal zwak';
  }
}

/// User roles for theming
enum UserRole {
  guard,
  company,
  admin,
}

/// Extension for List.firstOrNull
extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}