import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../unified_design_tokens.dart';
import '../../unified_card_system.dart';
import '../../unified_buttons.dart';
import '../bloc/certificate_bloc.dart';
import '../bloc/certificate_event.dart';
import '../bloc/certificate_state.dart';

/// Job certificate matching widget that shows eligibility and requirements
class JobCertificateMatcher extends StatefulWidget {
  final String userId;
  final String jobId;
  final String jobTitle;
  final Map<String, List<String>> jobRequirements;
  final Map<String, dynamic>? jobMetadata;
  final Function(bool isEligible, double score)? onEligibilityChanged;

  const JobCertificateMatcher({
    super.key,
    required this.userId,
    required this.jobId,
    required this.jobTitle,
    required this.jobRequirements,
    this.jobMetadata,
    this.onEligibilityChanged,
  });

  @override
  State<JobCertificateMatcher> createState() => _JobCertificateMatcherState();
}

class _JobCertificateMatcherState extends State<JobCertificateMatcher> {
  bool _isChecking = false;
  CertificateJobEligibilityChecked? _eligibilityResult;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CertificateBloc, CertificateState>(
      listener: _handleBlocStateChange,
      child: UnifiedCard(
        variant: UnifiedCardVariant.standard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: DesignTokens.spacingL),
            
            _buildJobRequirements(),
            SizedBox(height: DesignTokens.spacingL),
            
            if (_eligibilityResult != null) ...[
              _buildEligibilityResult(),
              SizedBox(height: DesignTokens.spacingM),
            ],
            
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: DesignTokens.colorPrimaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Icon(
            Icons.work_outline,
            color: DesignTokens.colorPrimaryBlue,
            size: DesignTokens.iconSizeL,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.jobTitle,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeXL,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.darkText,
                ),
              ),
              Text(
                'Certificaat vereisten en geschiktheid',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vereiste Certificaten',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeL,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.darkText,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        
        ...widget.jobRequirements.entries.map((entry) {
          final categoryName = _getCategoryDisplayName(entry.key);
          final requirements = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: DesignTokens.spacingM),
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorGray50,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(color: DesignTokens.colorGray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(entry.key),
                      color: DesignTokens.colorPrimaryBlue,
                      size: DesignTokens.iconSizeM,
                    ),
                    SizedBox(width: DesignTokens.spacingS),
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: DesignTokens.darkText,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignTokens.spacingS),
                Wrap(
                  spacing: DesignTokens.spacingXS,
                  runSpacing: DesignTokens.spacingXS,
                  children: requirements.map((req) => _buildRequirementChip(req)).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequirementChip(String requirement) {
    Color chipColor = DesignTokens.colorGray400;
    Color textColor = DesignTokens.colorWhite;
    IconData? statusIcon;

    if (_eligibilityResult != null) {
      final isMet = _eligibilityResult!.requirementsMet[requirement] ?? false;
      final isMissing = _eligibilityResult!.missingRequirements.contains(requirement);
      final isExpired = _eligibilityResult!.expiredRequirements.contains(requirement);

      if (isMet) {
        chipColor = DesignTokens.colorSuccess;
        statusIcon = Icons.check;
      } else if (isExpired) {
        chipColor = DesignTokens.colorWarning;
        statusIcon = Icons.schedule;
      } else if (isMissing) {
        chipColor = DesignTokens.colorError;
        statusIcon = Icons.close;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Icon(
              statusIcon,
              size: DesignTokens.iconSizeS,
              color: textColor,
            ),
            SizedBox(width: DesignTokens.spacingXS),
          ],
          Text(
            requirement,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEligibilityResult() {
    if (_eligibilityResult == null) return const SizedBox.shrink();

    final isEligible = _eligibilityResult!.isEligible;
    final score = _eligibilityResult!.eligibilityScore;
    final scorePercentage = (score * 100).toStringAsFixed(1);

    final statusColor = isEligible 
      ? DesignTokens.colorSuccess 
      : score > 0.5 
        ? DesignTokens.colorWarning 
        : DesignTokens.colorError;

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEligible ? Icons.check_circle : Icons.warning,
                color: statusColor,
                size: DesignTokens.iconSizeL,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEligible ? 'Geschikt voor deze functie' : 'Niet volledig geschikt',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeL,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'Geschiktheidsscore: $scorePercentage%',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildScoreIndicator(score, statusColor),
            ],
          ),
          
          if (_eligibilityResult!.actionItems.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Actiepunten:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.darkText,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            ..._eligibilityResult!.actionItems.map((action) => 
              Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_right,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.mutedText,
                    ),
                    SizedBox(width: DesignTokens.spacingXS),
                    Expanded(
                      child: Text(
                        action,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeM,
                          color: DesignTokens.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ),
          ],
          
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Laatst gecontroleerd: ${DateFormat('dd-MM-yyyy HH:mm').format(_eligibilityResult!.checkedAt)}',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(double score, Color color) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: score,
                strokeWidth: 6,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          Center(
            child: Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontWeight: DesignTokens.fontWeightBold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: UnifiedButton(
            text: 'Controleer Opnieuw',
            type: UnifiedButtonType.secondary,
            onPressed: _isChecking ? null : _checkEligibility,
            isLoading: _isChecking,
          ),
        ),
        if (_eligibilityResult?.isEligible == true) ...[
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: UnifiedButton(
              text: 'Solliciteer',
              type: UnifiedButtonType.primary,
              onPressed: _applyForJob,
            ),
          ),
        ],
      ],
    );
  }

  void _handleBlocStateChange(BuildContext context, CertificateState state) {
    setState(() {
      _isChecking = state is CertificateLoading;
    });

    if (state is CertificateJobEligibilityChecked) {
      setState(() {
        _eligibilityResult = state;
      });
      
      widget.onEligibilityChanged?.call(state.isEligible, state.eligibilityScore);
      
    } else if (state is CertificateError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.localizedErrorMessage),
          backgroundColor: DesignTokens.colorError,
        ),
      );
    }
  }

  void _checkEligibility() {
    context.read<CertificateBloc>().add(
      CertificateCheckJobEligibility(
        userId: widget.userId,
        jobId: widget.jobId,
        jobRequirements: widget.jobRequirements,
        jobMetadata: widget.jobMetadata,
      ),
    );
  }

  void _applyForJob() {
    // This would trigger the job application flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sollicitatie functionaliteit wordt gestart...'),
        backgroundColor: DesignTokens.colorSuccess,
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'wpbr':
        return 'WPBR Beveiligingscertificaten';
      case 'vca':
        return 'VCA Veiligheidscertificaten';
      case 'bhv':
        return 'BHV Hulpverlening';
      case 'ehbo':
        return 'EHBO Eerste Hulp';
      default:
        return category.toUpperCase();
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wpbr':
        return Icons.security;
      case 'vca':
        return Icons.verified;
      case 'bhv':
        return Icons.health_and_safety;
      case 'ehbo':
        return Icons.medical_services;
      default:
        return Icons.verified_outlined;
    }
  }
}