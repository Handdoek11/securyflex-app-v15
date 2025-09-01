import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';

/// Application dialog adapted from template's filter screen structure
/// Provides job application form with availability confirmation and motivation
class ApplicationDialog extends StatefulWidget {
  final SecurityJobData jobData;
  
  const ApplicationDialog({
    super.key,
    required this.jobData,
  });

  @override
  State<ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<ApplicationDialog>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  final TextEditingController _motivationController = TextEditingController();
  
  bool _isAvailable = false;
  String _contactPreference = 'email';
  bool _isSubmitting = false;
  String _errorMessage = '';

  // Helper method to get consistent color scheme - Changed to guard
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController?.forward();
    super.initState();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: PremiumGlassContainer(
        intensity: GlassIntensity.premium,
        elevation: GlassElevation.overlay,
        tintColor: colorScheme.primary,
        enableTrustBorder: true,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingL),
                      child: Column(
                        children: [
                          _buildJobInfo(),
                          SizedBox(height: DesignTokens.spacingL),
                          _buildAvailabilitySection(),
                          SizedBox(height: DesignTokens.spacingL),
                          _buildMotivationSection(),
                          SizedBox(height: DesignTokens.spacingL),
                          _buildContactPreferenceSection(),
                          if (_errorMessage.isNotEmpty) ...[
                            SizedBox(height: DesignTokens.spacingL),
                            _buildErrorMessage(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        );
  }

  Widget _buildHeader() {
    final slideAnimation = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.0, 0.3, curve: Curves.fastOutSlowIn),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _colorScheme.primary.withValues(alpha: 0.3),
              _colorScheme.secondary.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.radiusXL),
            topRight: Radius.circular(DesignTokens.radiusXL),
          ),
          border: Border(
            bottom: BorderSide(
              color: _colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: _colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.work_outline,
                color: _colorScheme.primary,
                size: 24,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sollicitatie',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeHeading,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: _colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Bevestig je beschikbaarheid',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightRegular,
                      color: _colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.close, color: _colorScheme.onSurfaceVariant),
              style: IconButton.styleFrom(
                backgroundColor: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobInfo() {
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.2, 0.5, curve: Curves.fastOutSlowIn),
    ));

    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          border: Border.all(
            color: _colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.jobData.jobTitle,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: _colorScheme.primary,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            _buildInfoRow(
              Icons.business_outlined,
              widget.jobData.companyName,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildInfoRow(
              Icons.location_on_outlined,
              widget.jobData.location,
            ),
            SizedBox(height: DesignTokens.spacingS),
            _buildInfoRow(
              Icons.schedule_outlined,
              widget.jobData.startDate != null
                  ? DateFormat('dd MMM yyyy, HH:mm', 'nl_NL').format(widget.jobData.startDate!)
                  : 'Datum nog niet bekend',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeS,
          color: _colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightRegular,
              color: _colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    final slideAnimation = Tween<Offset>(
      begin: Offset(0.5, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.3, 0.6, curve: Curves.fastOutSlowIn),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          border: Border.all(
            color: _colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: _colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Beschikbaarheid',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _isAvailable = !_isAvailable;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(DesignTokens.spacingS + DesignTokens.spacingXS), // 12px
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isAvailable
                          ? _colorScheme.primary
                          : DesignTokens.colorGray300,
                    ),
                    color: _isAvailable
                        ? _colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ik ben beschikbaar voor deze opdracht',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bevestig dat je beschikbaar bent op de geplande datum en tijd',
                              style: TextStyle(
                                fontSize: 12,
                                color: DesignTokens.colorGray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        activeTrackColor: _colorScheme.primary,
                        value: _isAvailable,
                        onChanged: (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationSection() {
    final slideAnimation = Tween<Offset>(
      begin: Offset(-0.5, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.4, 0.7, curve: Curves.fastOutSlowIn),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          border: Border.all(
            color: _colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_note,
                  color: _colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Motivatiebericht (optioneel)',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Container(
              decoration: BoxDecoration(
                color: _colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: _colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _motivationController,
                maxLines: 4,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: EdgeInsets.all(DesignTokens.spacingM),
                  hintText: 'Waarom ben je geschikt voor deze opdracht? Vertel over je ervaring en motivatie...',
                  hintStyle: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    color: _colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeBody,
                  color: _colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactPreferenceSection() {
    final slideAnimation = Tween<Offset>(
      begin: Offset(0.5, 0),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.5, 0.8, curve: Curves.fastOutSlowIn),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          border: Border.all(
            color: _colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_phone_outlined,
                  color: _colorScheme.primary,
                  size: DesignTokens.iconSizeM,
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text(
                  'Contactvoorkeur',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeSubtitle,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            Column(
              children: [
                _buildContactOption('email', 'E-mail', Icons.email_outlined),
                SizedBox(height: 8),
                _buildContactOption('phone', 'Telefoon', Icons.phone_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(String value, String label, IconData icon) {
    final isSelected = _contactPreference == value;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _contactPreference = value;
          });
        },
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingS + DesignTokens.spacingXS), // 12px
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? _colorScheme.primary
                  : DesignTokens.colorGray300,
            ),
            color: isSelected
                ? _colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? _colorScheme.primary
                    : DesignTokens.colorGray600,
              ),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected
                      ? _colorScheme.primary
                      : DesignTokens.colorGray700,
                ),
              ),
              Spacer(),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: _colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingS + DesignTokens.spacingXS), // 12px
        decoration: BoxDecoration(
          color: DesignTokens.statusCancelled.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DesignTokens.statusCancelled.withValues(alpha: 0.200)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: DesignTokens.statusCancelled.withValues(alpha: 0.600), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage,
                style: TextStyle(color: DesignTokens.statusCancelled.withValues(alpha: 0.600), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final slideUpAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Interval(0.6, 1.0, curve: Curves.fastOutSlowIn),
    ));

    return SlideTransition(
      position: slideUpAnimation,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _colorScheme.surfaceContainer.withValues(alpha: 0.5),
              _colorScheme.surfaceContainer.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(DesignTokens.radiusXL),
            bottomRight: Radius.circular(DesignTokens.radiusXL),
          ),
          border: Border(
            top: BorderSide(
              color: _colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => context.pop(),
                icon: Icon(Icons.close),
                label: Text('Annuleren'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingM,
                    horizontal: DesignTokens.spacingL,
                  ),
                  side: BorderSide(
                    color: _colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                ),
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: UnifiedButton(
                text: _isSubmitting ? 'Bezig...' : 'Solliciteren',
                onPressed: _isSubmitting ? null : _handleSubmit,
                size: UnifiedButtonSize.large,
                type: UnifiedButtonType.primary,
                icon: _isSubmitting ? null : Icons.send,
                isLoading: _isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_isAvailable) {
      setState(() {
        _errorMessage = 'Bevestig eerst je beschikbaarheid voor deze opdracht.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      final success = await ApplicationService.submitApplication(
        jobId: widget.jobData.jobId,
        jobTitle: widget.jobData.jobTitle,
        companyName: widget.jobData.companyName,
        isAvailable: _isAvailable,
        motivationMessage: _motivationController.text.trim(),
        contactPreference: _contactPreference,
      );

      if (success && mounted) {
        context.pop(true); // Return true to indicate success
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Je hebt al gesolliciteerd op deze opdracht.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden. Probeer het opnieuw.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
