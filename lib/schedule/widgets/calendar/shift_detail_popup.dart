import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../unified_design_tokens.dart';
import '../../../unified_buttons.dart';
import '../../../unified_card_system.dart';
import '../../../unified_theme_system.dart';
import '../../models/shift_model.dart';
import '../../models/time_entry_model.dart';

/// ShiftDetailPopup - Detailed shift information dialog
/// 
/// Features:
/// - Comprehensive shift information display
/// - GPS verification status
/// - Time tracking details
/// - CAO compliance information
/// - Quick actions (check-in, swap, etc.)
/// - Nederlandse localization
/// - Role-based theming
class ShiftDetailPopup extends StatelessWidget {
  final UserRole userRole;
  final Shift shift;
  final TimeEntry? timeEntry;
  final Function(Shift)? onCheckIn;
  final Function(Shift)? onCheckOut;
  final Function(Shift)? onSwapShift;
  final Function(Shift)? onCancelShift;
  final Function(Shift)? onEditShift;
  final bool canEdit;
  final bool canSwap;
  final bool canCancel;

  const ShiftDetailPopup({
    super.key,
    required this.userRole,
    required this.shift,
    this.timeEntry,
    this.onCheckIn,
    this.onCheckOut,
    this.onSwapShift,
    this.onCancelShift,
    this.onEditShift,
    this.canEdit = false,
    this.canSwap = true,
    this.canCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: UnifiedCard.standard(
          userRole: userRole,
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: DesignTokens.spacingL),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShiftInfo(),
                      const SizedBox(height: DesignTokens.spacingL),
                      _buildLocationInfo(),
                      const SizedBox(height: DesignTokens.spacingL),
                      _buildTimeInfo(),
                      if (timeEntry != null) ...[
                        const SizedBox(height: DesignTokens.spacingL),
                        _buildTimeTrackingInfo(),
                      ],
                      if (shift.requiredCertifications.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.spacingL),
                        _buildRequirementsInfo(),
                      ],
                      if (shift.shiftDescription.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.spacingL),
                        _buildNotesInfo(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spacingL),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _getShiftStatusColor(shift.status),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shift.shiftTitle,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeHeading,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: _getTextPrimaryColor(),
                ),
              ),
              Text(
                _getShiftStatusText(shift.status),
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeM,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _getShiftStatusColor(shift.status),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.close,
            color: _getTextSecondaryColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftInfo() {
    return _buildInfoSection(
      'Dienst Informatie',
      Icons.work_outline,
      [
        _buildInfoRow('Type', shift.isEmergencyShift ? 'Nooddienst' : 'Regulier'),
        _buildInfoRow('Beschrijving', shift.shiftDescription),
        _buildInfoRow('Aangemaakt', DateFormat('dd-MM-yyyy HH:mm').format(shift.createdAt)),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return _buildInfoSection(
      'Locatie Informatie',
      Icons.location_on_outlined,
      [
        _buildInfoRow('Adres', shift.location.address),
        _buildInfoRow('Coördinaten', '${shift.location.latitude.toStringAsFixed(4)}, ${shift.location.longitude.toStringAsFixed(4)}'),
        _buildInfoRow('GPS Verificatie', shift.requiresLocationVerification ? 'Vereist' : 'Niet vereist'),
        if (shift.requiresLocationVerification)
          _buildGPSStatus(),
      ],
    );
  }

  Widget _buildTimeInfo() {
    final duration = shift.endTime.difference(shift.startTime);
    final isOvertime = duration.inHours > 8;
    
    return _buildInfoSection(
      'Tijd Informatie',
      Icons.schedule_outlined,
      [
        _buildInfoRow('Start tijd', DateFormat('EEEE dd-MM-yyyy HH:mm', 'nl_NL').format(shift.startTime)),
        _buildInfoRow('Eind tijd', DateFormat('EEEE dd-MM-yyyy HH:mm', 'nl_NL').format(shift.endTime)),
        _buildInfoRow('Duur', '${duration.inHours}u ${duration.inMinutes % 60}m'),
        _buildInfoRow('Uurtarief', '€${shift.hourlyRate.toStringAsFixed(2)}'),
        _buildInfoRow('Totaal tarief', '€${shift.totalEarnings.toStringAsFixed(2)}'),
        if (isOvertime)
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: DesignTokens.colorWarning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(color: DesignTokens.colorWarning),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: DesignTokens.colorWarning,
                  size: DesignTokens.iconSizeS,
                ),
                const SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Overwerk - CAO tarieven gelden',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.colorWarning,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTimeTrackingInfo() {
    if (timeEntry == null) return const SizedBox.shrink();
    
    final totalDuration = timeEntry!.getTotalWorkDuration();
    final isOvertime = totalDuration.inHours > 8;
    
    return _buildInfoSection(
      'Tijd Registratie',
      Icons.timer_outlined,
      [
        _buildInfoRow('Ingecheckt', timeEntry!.checkInTime != null 
            ? DateFormat('HH:mm').format(timeEntry!.checkInTime!) 
            : 'Nog niet'),
        _buildInfoRow('Uitgecheckt', timeEntry!.checkOutTime != null 
            ? DateFormat('HH:mm').format(timeEntry!.checkOutTime!) 
            : 'Nog niet'),
        _buildInfoRow('Totaal gewerkt', '${totalDuration.inHours}u ${totalDuration.inMinutes % 60}m'),
        _buildInfoRow('Pauzes', '${timeEntry!.breaks.length} pauze${timeEntry!.breaks.length == 1 ? '' : 's'}'),
        if (timeEntry!.checkInLocation != null)
          _buildInfoRow('GPS Check-in', 'Geverifieerd'),
        if (timeEntry!.checkOutLocation != null)
          _buildInfoRow('GPS Check-out', 'Geverifieerd'),
        if (isOvertime)
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            decoration: BoxDecoration(
              color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(color: DesignTokens.colorSuccess),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: DesignTokens.colorSuccess,
                  size: DesignTokens.iconSizeS,
                ),
                const SizedBox(width: DesignTokens.spacingXS),
                Text(
                  'Overwerk geregistreerd - CAO tarieven',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.colorSuccess,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRequirementsInfo() {
    return _buildInfoSection(
      'Vereisten',
      Icons.verified_user_outlined,
      shift.requiredCertifications.map((cert) => _buildRequirementItem(cert)).toList(),
    );
  }

  Widget _buildNotesInfo() {
    return _buildInfoSection(
      'Opmerkingen',
      Icons.note_outlined,
      [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorGray100,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Text(
            shift.shiftDescription,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightRegular,
              color: _getTextPrimaryColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: _getPrimaryColor(),
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              title,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getTextPrimaryColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: _getTextSecondaryColor(),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextPrimaryColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGPSStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (shift.gpsVerificationStatus) {
      case 'verified':
        statusColor = DesignTokens.colorSuccess;
        statusText = 'GPS Geverifieerd';
        statusIcon = Icons.location_on;
        break;
      case 'failed':
        statusColor = DesignTokens.colorError;
        statusText = 'GPS Verificatie Mislukt';
        statusIcon = Icons.location_off;
        break;
      case 'pending':
        statusColor = DesignTokens.colorWarning;
        statusText = 'GPS Verificatie In Behandeling';
        statusIcon = Icons.location_searching;
        break;
      default:
        statusColor = DesignTokens.colorGray500;
        statusText = 'Niet Geverifieerd';
        statusIcon = Icons.location_disabled;
    }
    
    return Container(
      margin: EdgeInsets.only(top: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingXS),
          Text(
            statusText,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String requirement) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: _getPrimaryColor(),
            size: DesignTokens.iconSizeS,
          ),
          const SizedBox(width: DesignTokens.spacingXS),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightRegular,
                color: _getTextPrimaryColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final List<Widget> buttons = [];
    
    // Check-in/Check-out buttons
    if (timeEntry?.checkInTime == null && shift.status == ShiftStatus.confirmed) {
      buttons.add(
        Expanded(
          child: UnifiedButton.primary(
            text: 'Inchecken',
            onPressed: () {
              context.pop();
              onCheckIn?.call(shift);
            },
          ),
        ),
      );
    } else if (timeEntry?.checkInTime != null && timeEntry?.checkOutTime == null) {
      buttons.add(
        Expanded(
          child: UnifiedButton(
            text: 'Uitchecken',
            onPressed: () {
              context.pop();
              onCheckOut?.call(shift);
            },
            backgroundColor: DesignTokens.colorError,
          ),
        ),
      );
    }
    
    // Swap button
    if (canSwap && shift.status == ShiftStatus.confirmed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: DesignTokens.spacingS));
      buttons.add(
        Expanded(
          child: UnifiedButton.secondary(
            text: 'Ruilen',
            onPressed: () {
              context.pop();
              onSwapShift?.call(shift);
            },
          ),
        ),
      );
    }
    
    // Edit button
    if (canEdit) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: DesignTokens.spacingS));
      buttons.add(
        Expanded(
          child: UnifiedButton.text(
            text: 'Bewerken',
            onPressed: () {
              context.pop();
              onEditShift?.call(shift);
            },
          ),
        ),
      );
    }
    
    // Cancel button
    if (canCancel && shift.status != ShiftStatus.cancelled && shift.status != ShiftStatus.completed) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(width: DesignTokens.spacingS));
      buttons.add(
        Expanded(
          child: UnifiedButton.text(
            text: 'Annuleren',
            onPressed: () => _showCancelConfirmation(context),
          ),
        ),
      );
    }
    
    if (buttons.isEmpty) {
      buttons.add(
        Expanded(
          child: UnifiedButton.secondary(
            text: 'Sluiten',
            onPressed: () => context.pop(),
          ),
        ),
      );
    }
    
    return Row(children: buttons);
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Dienst Annuleren',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getTextPrimaryColor(),
          ),
        ),
        content: Text(
          'Weet u zeker dat u deze dienst wilt annuleren? Deze actie kan niet ongedaan worden gemaakt.',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightRegular,
            color: _getTextSecondaryColor(),
          ),
        ),
        actions: [
          UnifiedButton.text(
            text: 'Terug',
            onPressed: () => context.pop(),
          ),
          UnifiedButton(
            text: 'Annuleren',
            backgroundColor: DesignTokens.colorError,
            onPressed: () {
              context.pop();
              context.pop();
              onCancelShift?.call(shift);
            },
          ),
        ],
      ),
    );
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

  Color _getPrimaryColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardPrimary;
      case UserRole.company:
        return DesignTokens.companyPrimary;
      case UserRole.admin:
        return DesignTokens.adminPrimary;
    }
  }

  Color _getTextPrimaryColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextPrimary;
      case UserRole.company:
        return DesignTokens.companyTextPrimary;
      case UserRole.admin:
        return DesignTokens.adminTextPrimary;
    }
  }

  Color _getTextSecondaryColor() {
    switch (userRole) {
      case UserRole.guard:
        return DesignTokens.guardTextSecondary;
      case UserRole.company:
        return DesignTokens.companyTextSecondary;
      case UserRole.admin:
        return DesignTokens.adminTextSecondary;
    }
  }

  Color _getShiftStatusColor(ShiftStatus status) {
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
}

