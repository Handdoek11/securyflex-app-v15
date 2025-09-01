import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/unified_buttons.dart';

/// Premium Application Dialog - Complete Redesign
/// 
/// Een moderne, premium sollicitatie-ervaring voor beveiligers met:
/// - Full-screen immersive experience
/// - Stapsgewijze flow met progress indicator
/// - Confidence-building elementen
/// - Micro-animaties en haptic feedback
/// - Smart validatie en feedback
class PremiumApplicationDialog extends StatefulWidget {
  final SecurityJobData jobData;
  
  const PremiumApplicationDialog({
    super.key,
    required this.jobData,
  });

  @override
  State<PremiumApplicationDialog> createState() => _PremiumApplicationDialogState();
}

class _PremiumApplicationDialogState extends State<PremiumApplicationDialog>
    with TickerProviderStateMixin {
  
  // Animation Controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _checkController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;
  late Animation<double> _scaleIn;
  late Animation<double> _pulse;
  
  // Form State
  final PageController _pageController = PageController();
  final TextEditingController _motivationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  
  int _currentStep = 0;
  final int _totalSteps = 4;
  
  // Application Data
  bool _isAvailable = false;
  String _contactPreference = 'both';
  final List<String> _selectedStrengths = [];
  int _experienceYears = 0;
  bool _hasRelevantExperience = false;
  
  // UI State
  bool _isSubmitting = false;
  bool _showSuccess = false;
  String? _errorMessage;
  
  // Styling
  ColorScheme get _colorScheme => SecuryFlexTheme.getColorScheme(UserRole.guard);
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _mainController.forward();
  }
  
  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    _slideUp = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));
    
    _scaleIn = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    ));
    
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _checkController.dispose();
    _pageController.dispose();
    _motivationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeIn,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Transform.scale(
                scale: _scaleIn.value,
                child: _buildMainContent(),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMainContent() {
    final size = MediaQuery.of(context).size;
    
    return Container(
      width: size.width * 0.95,
      height: size.height * 0.9,
      constraints: BoxConstraints(
        maxWidth: 500,
        maxHeight: 800,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorScheme.surface.withValues(alpha: 0.95),
                  _colorScheme.surface.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
              border: Border.all(
                width: 1,
                color: _colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressBar(),
                Expanded(
                  child: _showSuccess 
                      ? _buildSuccessScreen()
                      : _buildStepContent(),
                ),
                if (!_showSuccess) _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorScheme.primaryContainer.withValues(alpha: 0.3),
            _colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusXL),
          topRight: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Back button
                IconButton(
                  onPressed: _currentStep > 0 
                      ? () => _previousStep()
                      : () => context.pop(),
                  icon: Icon(
                    _currentStep > 0 ? Icons.arrow_back : Icons.close,
                    color: _colorScheme.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: _colorScheme.surface.withValues(alpha: 0.3),
                  ),
                ),
                SizedBox(width: DesignTokens.spacingM),
                
                // Title section
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
                        _getStepTitle(),
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
                
                // Company logo placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _colorScheme.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.business,
                    color: _colorScheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
            
            // Job info summary
            SizedBox(height: DesignTokens.spacingL),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: _colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: _colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.jobData.jobTitle,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeSubtitle,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: _colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spacingXS),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: DesignTokens.iconSizeXS,
                              color: _colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: DesignTokens.spacingXS),
                            Text(
                              widget.jobData.location,
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: DesignTokens.fontSizeCaption,
                                color: _colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingM,
                      vertical: DesignTokens.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                      border: Border.all(
                        color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '€${widget.jobData.hourlyRate.toStringAsFixed(2)}/uur',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightBold,
                        color: DesignTokens.colorSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted 
                          ? _colorScheme.primary
                          : _colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 40 : 30,
                  height: isActive ? 40 : 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted || isActive
                        ? _colorScheme.primary
                        : _colorScheme.surface,
                    border: Border.all(
                      color: isCompleted || isActive
                          ? _colorScheme.primary
                          : _colorScheme.outline.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: _colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: _colorScheme.onPrimary,
                            size: 16,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.fontSizeCaption,
                              fontWeight: DesignTokens.fontWeightBold,
                              color: isActive
                                  ? _colorScheme.onPrimary
                                  : _colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildStepContent() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStep1Availability(),
        _buildStep2Experience(),
        _buildStep3Motivation(),
        _buildStep4Review(),
      ],
    );
  }
  
  Widget _buildStep1Availability() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorScheme.primaryContainer.withValues(alpha: 0.2),
                  _colorScheme.secondaryContainer.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: _colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: 48,
                  color: _colorScheme.primary,
                ),
                SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Ben je beschikbaar?',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: _colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  'Bevestig dat je beschikbaar bent voor deze opdracht',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    color: _colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Date and time info
          _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'Datum',
            value: widget.jobData.startDate != null
                ? DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(widget.jobData.startDate!)
                : 'Nog te bepalen',
            color: _colorScheme.primary,
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Werktijden',
            value: widget.jobData.startDate != null
                ? '${DateFormat('HH:mm', 'nl_NL').format(widget.jobData.startDate!)} - ${DateFormat('HH:mm', 'nl_NL').format(widget.jobData.endDate ?? widget.jobData.startDate!.add(Duration(hours: 8)))}'
                : 'Nog te bepalen',
            color: _colorScheme.secondary,
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Availability toggle
          GestureDetector(
            onTap: () => setState(() => _isAvailable = !_isAvailable),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(DesignTokens.spacingL),
              decoration: BoxDecoration(
                gradient: _isAvailable ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _colorScheme.primary.withValues(alpha: 0.1),
                    _colorScheme.primary.withValues(alpha: 0.05),
                  ],
                ) : null,
                color: !_isAvailable 
                    ? _colorScheme.surfaceContainer.withValues(alpha: 0.3)
                    : null,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                border: Border.all(
                  color: _isAvailable
                      ? _colorScheme.primary
                      : _colorScheme.outline.withValues(alpha: 0.2),
                  width: _isAvailable ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAvailable
                          ? _colorScheme.primary
                          : _colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    child: _isAvailable
                        ? Icon(
                            Icons.check,
                            color: _colorScheme.onPrimary,
                            size: 16,
                          )
                        : null,
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ja, ik ben beschikbaar',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeSubtitle,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: _isAvailable 
                                ? _colorScheme.primary
                                : _colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: DesignTokens.spacingXS),
                        Text(
                          'Ik kan op de gevraagde datum en tijd werken',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeCaption,
                            color: _colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_errorMessage != null && _currentStep == 0) ...[
            SizedBox(height: DesignTokens.spacingM),
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              decoration: BoxDecoration(
                color: DesignTokens.colorError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                border: Border.all(
                  color: DesignTokens.colorError.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: DesignTokens.colorError,
                    size: 20,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeCaption,
                        color: DesignTokens.colorError,
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
  
  Widget _buildStep2Experience() {
    final strengths = [
      'Communicatief sterk',
      'Flexibel',
      'Betrouwbaar',
      'Alert',
      'Teamspeler',
      'Zelfstandig',
      'Probleemoplossend',
      'Stressbestendig',
    ];
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jouw ervaring',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Help ons je beter te leren kennen',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: _colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Years of experience
          Text(
            'Jaren ervaring in beveiliging',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          Row(
            children: List.generate(5, (index) {
              final years = index == 4 ? '5+' : '$index';
              final isSelected = _experienceYears == index;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
                  child: GestureDetector(
                    onTap: () => setState(() => _experienceYears = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _colorScheme.primary,
                            _colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ) : null,
                        color: !isSelected 
                            ? _colorScheme.surfaceContainer.withValues(alpha: 0.3)
                            : null,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                        border: Border.all(
                          color: isSelected
                              ? _colorScheme.primary
                              : _colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          years,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.fontSizeSubtitle,
                            fontWeight: DesignTokens.fontWeightBold,
                            color: isSelected
                                ? _colorScheme.onPrimary
                                : _colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Relevant experience
          Text(
            'Relevante ervaring',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          Container(
            decoration: BoxDecoration(
              color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: _colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _experienceController,
              maxLines: 3,
              onChanged: (value) => setState(() => 
                _hasRelevantExperience = value.trim().isNotEmpty
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(DesignTokens.spacingM),
                hintText: 'Beschrijf kort relevante ervaring voor deze opdracht...',
                hintStyle: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeBody,
                  color: _colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeBody,
                color: _colorScheme.onSurface,
              ),
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Strengths
          Text(
            'Jouw sterke punten (max 3)',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: strengths.map((strength) {
              final isSelected = _selectedStrengths.contains(strength);
              final canSelect = _selectedStrengths.length < 3;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedStrengths.remove(strength);
                    } else if (canSelect) {
                      _selectedStrengths.add(strength);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingS,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _colorScheme.primary.withValues(alpha: 0.1),
                        _colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ) : null,
                    color: !isSelected
                        ? _colorScheme.surfaceContainer.withValues(alpha: 0.3)
                        : null,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? _colorScheme.primary
                          : _colorScheme.outline.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: _colorScheme.primary,
                        ),
                        SizedBox(width: DesignTokens.spacingXS),
                      ],
                      Text(
                        strength,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: isSelected 
                              ? DesignTokens.fontWeightSemiBold
                              : DesignTokens.fontWeightRegular,
                          color: isSelected
                              ? _colorScheme.primary
                              : _colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep3Motivation() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waarom deze opdracht?',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Vertel het bedrijf waarom jij de juiste persoon bent',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: _colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Motivation text field
          Container(
            decoration: BoxDecoration(
              color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: _colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _motivationController,
                  maxLines: 8,
                  maxLength: 500,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(DesignTokens.spacingL),
                    hintText: 'Bijvoorbeeld:\n\n• Waarom spreekt deze opdracht je aan?\n• Wat maakt jou geschikt voor deze functie?\n• Heb je ervaring met soortgelijke opdrachten?',
                    hintStyle: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeBody,
                      color: _colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      height: 1.5,
                    ),
                    counterText: '',
                  ),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    color: _colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(DesignTokens.radiusL),
                      bottomRight: Radius.circular(DesignTokens.radiusL),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_motivationController.text.length}/500 tekens',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: _colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_motivationController.text.length > 100)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: DesignTokens.colorSuccess,
                            ),
                            SizedBox(width: DesignTokens.spacingXS),
                            Text(
                              'Goede lengte',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: DesignTokens.fontSizeCaption,
                                color: DesignTokens.colorSuccess,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Contact preference
          Text(
            'Hoe kan het bedrijf je bereiken?',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          ..._buildContactOptions(),
        ],
      ),
    );
  }
  
  Widget _buildStep4Review() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controleer je sollicitatie',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightBold,
              color: _colorScheme.onSurface,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Alles klopt? Verstuur dan je sollicitatie!',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: _colorScheme.onSurfaceVariant,
            ),
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Summary cards
          _buildSummaryCard(
            title: 'Beschikbaarheid',
            icon: Icons.event_available,
            content: _isAvailable 
                ? 'Beschikbaar voor deze opdracht'
                : 'Niet bevestigd',
            isValid: _isAvailable,
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          _buildSummaryCard(
            title: 'Ervaring',
            icon: Icons.work_history,
            content: '${_experienceYears == 4 ? "5+" : "$_experienceYears"} jaar ervaring\n${_selectedStrengths.join(", ")}',
            isValid: true,
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          _buildSummaryCard(
            title: 'Motivatie',
            icon: Icons.edit_note,
            content: _motivationController.text.isNotEmpty
                ? _motivationController.text
                : 'Geen motivatie toegevoegd',
            isValid: _motivationController.text.isNotEmpty,
          ),
          
          SizedBox(height: DesignTokens.spacingM),
          
          _buildSummaryCard(
            title: 'Contact',
            icon: Icons.contact_phone,
            content: _getContactPreferenceText(),
            isValid: true,
          ),
          
          SizedBox(height: DesignTokens.spacingXL),
          
          // Trust badges
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: DesignTokens.colorSuccess,
                  size: 24,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Veilig solliciteren',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeBody,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: DesignTokens.colorSuccess,
                        ),
                      ),
                      Text(
                        'Je gegevens worden veilig verwerkt',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: _colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomActions() {
    final canProceed = _canProceed();
    
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: _colorScheme.surface.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: _colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousStep,
                  icon: Icon(Icons.arrow_back),
                  label: Text('Vorige'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: DesignTokens.spacingM,
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
            if (_currentStep > 0) SizedBox(width: DesignTokens.spacingM),
            Expanded(
              flex: 2,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: canProceed && _currentStep == _totalSteps - 1
                        ? _pulse.value
                        : 1.0,
                    child: UnifiedButton(
                      text: _currentStep == _totalSteps - 1
                          ? (_isSubmitting ? 'Bezig...' : 'Verstuur sollicitatie')
                          : 'Volgende',
                      onPressed: canProceed && !_isSubmitting
                          ? (_currentStep == _totalSteps - 1 ? _submitApplication : _nextStep)
                          : null,
                      type: UnifiedButtonType.primary,
                      size: UnifiedButtonSize.large,
                      icon: _currentStep == _totalSteps - 1 ? Icons.send : Icons.arrow_forward,
                      isLoading: _isSubmitting,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          DesignTokens.colorSuccess,
                          DesignTokens.colorSuccess.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: DesignTokens.spacingXL),
            
            Text(
              'Sollicitatie verstuurd!',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeHeading,
                fontWeight: DesignTokens.fontWeightBold,
                color: _colorScheme.onSurface,
              ),
            ),
            
            SizedBox(height: DesignTokens.spacingM),
            
            Text(
              'Je sollicitatie is succesvol verzonden naar ${widget.jobData.companyName}',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeBody,
                color: _colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: DesignTokens.spacingXL),
            
            UnifiedButton.primary(
              text: 'Sluiten',
              onPressed: () => context.pop(true),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: _colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: _colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildContactOptions() {
    final options = [
      {'id': 'email', 'icon': Icons.email, 'label': 'E-mail'},
      {'id': 'phone', 'icon': Icons.phone, 'label': 'Telefoon'},
      {'id': 'both', 'icon': Icons.contacts, 'label': 'E-mail & Telefoon'},
    ];
    
    return options.map((option) {
      final isSelected = _contactPreference == option['id'];
      
      return Padding(
        padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
        child: GestureDetector(
          onTap: () => setState(() => _contactPreference = option['id'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              gradient: isSelected ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorScheme.primary.withValues(alpha: 0.1),
                  _colorScheme.primary.withValues(alpha: 0.05),
                ],
              ) : null,
              color: !isSelected
                  ? _colorScheme.surfaceContainer.withValues(alpha: 0.3)
                  : null,
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              border: Border.all(
                color: isSelected
                    ? _colorScheme.primary
                    : _colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  option['icon'] as IconData,
                  color: isSelected ? _colorScheme.primary : _colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Text(
                    option['label'] as String,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: isSelected
                          ? DesignTokens.fontWeightSemiBold
                          : DesignTokens.fontWeightRegular,
                      color: isSelected
                          ? _colorScheme.primary
                          : _colorScheme.onSurface,
                    ),
                  ),
                ),
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
    }).toList();
  }
  
  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required String content,
    required bool isValid,
  }) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: isValid
              ? _colorScheme.outline.withValues(alpha: 0.2)
              : DesignTokens.colorWarning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isValid
                  ? _colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : DesignTokens.colorWarning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isValid ? _colorScheme.primary : DesignTokens.colorWarning,
              size: 20,
            ),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  content,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    color: _colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isValid)
            Icon(
              Icons.check_circle,
              color: DesignTokens.colorSuccess,
              size: 20,
            ),
        ],
      ),
    );
  }
  
  // Navigation methods
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
        _errorMessage = null;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _isAvailable;
      case 1:
        return _selectedStrengths.isNotEmpty;
      case 2:
        return true; // Motivation is optional
      case 3:
        return _isAvailable;
      default:
        return false;
    }
  }
  
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Stap 1: Beschikbaarheid bevestigen';
      case 1:
        return 'Stap 2: Jouw ervaring';
      case 2:
        return 'Stap 3: Motivatie';
      case 3:
        return 'Stap 4: Controleren & versturen';
      default:
        return '';
    }
  }
  
  String _getContactPreferenceText() {
    switch (_contactPreference) {
      case 'email':
        return 'Via e-mail';
      case 'phone':
        return 'Via telefoon';
      case 'both':
        return 'Via e-mail en telefoon';
      default:
        return 'Niet opgegeven';
    }
  }
  
  Future<void> _submitApplication() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
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
        setState(() {
          _showSuccess = true;
        });
        _checkController.forward();
        
        // Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            context.pop(true);
          }
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Je hebt al gesolliciteerd op deze opdracht.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Er is een fout opgetreden. Probeer het opnieuw.';
          _isSubmitting = false;
        });
      }
    }
  }
}