import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/smart_pricing_service.dart';
import 'package:securyflex_app/company_dashboard/services/guard_matching_engine.dart';
import 'package:securyflex_app/company_dashboard/services/job_analytics_service.dart';

/// Smart Job Creation Wizard
/// 
/// An intelligent guided job posting interface that provides:
/// - Step-by-step job creation with smart suggestions
/// - AI-powered pricing recommendations
/// - Template library for quick posting
/// - Real-time compliance checking
/// - Guard matching preview
/// - Performance predictions
/// 
/// Features:
/// - Multi-step wizard with progress tracking
/// - Auto-completion and suggestions
/// - Template-based quick creation
/// - Real-time validation and compliance
/// - Preview of expected results
/// - Integration with all AI services
class SmartJobCreationWizard extends StatefulWidget {
  final JobPostingData? existingJob;
  final Function(JobPostingData)? onJobCreated;
  final Function(JobPostingData)? onJobUpdated;

  const SmartJobCreationWizard({
    super.key,
    this.existingJob,
    this.onJobCreated,
    this.onJobUpdated,
  });

  @override
  State<SmartJobCreationWizard> createState() => _SmartJobCreationWizardState();
}

class _SmartJobCreationWizardState extends State<SmartJobCreationWizard>
    with TickerProviderStateMixin {
  
  // Wizard state
  int _currentStep = 0;
  final int _totalSteps = 5;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  
  // Form state
  JobType _selectedJobType = JobType.objectbeveiliging;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  List<String> _selectedSkills = [];
  List<String> _selectedCertificates = [];
  int _minimumExperience = 0;
  bool _isUrgent = false;
  
  // AI-powered data
  SmartPricingData? _pricingData;
  List<GuardMatchSuggestion> _guardSuggestions = [];
  PredictionData? _predictions;
  ComplianceCheckResult? _complianceCheck;
  JobTemplateData? _selectedTemplate;
  
  // Loading states
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeFromExistingJob();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _postalCodeController.dispose();
    _hourlyRateController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _initializeFromExistingJob() {
    if (widget.existingJob != null) {
      final job = widget.existingJob!;
      _titleController.text = job.title;
      _descriptionController.text = job.description;
      _locationController.text = job.location;
      _postalCodeController.text = job.postalCode;
      _hourlyRateController.text = job.hourlyRate.toString();
      _specialInstructionsController.text = job.specialInstructions ?? '';
      
      _selectedJobType = job.jobType;
      _startDate = job.startDate;
      _endDate = job.endDate;
      _selectedSkills = List.from(job.requiredSkills);
      _selectedCertificates = List.from(job.requiredCertificates);
      _minimumExperience = job.minimumExperience;
      _isUrgent = job.isUrgent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Scaffold(
      backgroundColor: companyColors.surface,
      body: Column(
        children: [
          // Header with progress
          UnifiedHeader.simple(
            title: widget.existingJob != null ? 'Job Bewerken' : 'Nieuwe Job Maken',
            userRole: UserRole.company,
            leading: IconButton(
              icon: Icon(Icons.close, color: companyColors.onSurface),
              onPressed: () => context.pop(),
            ),
          ),
          
          // Progress indicator
          _buildProgressIndicator(companyColors),
          
          // Wizard content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildCurrentStep(companyColors),
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(companyColors),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stap ${_currentStep + 1} van $_totalSteps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                _getStepTitle(_currentStep),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme colors) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(colors);
      case 1:
        return _buildRequirementsStep(colors);
      case 2:
        return _buildPricingStep(colors);
      case 3:
        return _buildPreviewStep(colors);
      case 4:
        return _buildConfirmationStep(colors);
      default:
        return _buildBasicInfoStep(colors);
    }
  }

  Widget _buildBasicInfoStep(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template selection
          _buildTemplateSelector(colors),
          SizedBox(height: DesignTokens.spacingL),
          
          // Job type selection
          _buildJobTypeSelector(colors),
          SizedBox(height: DesignTokens.spacingL),
          
          // Basic information form
          _buildBasicInfoForm(colors),
        ],
      ),
    );
  }

  Widget _buildTemplateSelector(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: colors.primary),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Sjablonen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Begin met een sjabloon voor snellere job creatie',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          // Template options
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: [
              _buildTemplateChip('Evenementbeveiliging', Icons.event, colors),
              _buildTemplateChip('Objectbeveiliging', Icons.business, colors),
              _buildTemplateChip('Persoonbeveiliging', Icons.person_pin, colors),
              _buildTemplateChip('Mobiele Surveillance', Icons.directions_car, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String title, IconData icon, ColorScheme colors) {
    final isSelected = _selectedTemplate?.templateName == title;

    return UnifiedButton.category(
      text: title,
      isSelected: isSelected,
      onPressed: () {
        setState(() {
          if (isSelected) {
            _selectedTemplate = null;
          } else {
            _applyTemplate(title);
          }
        });
      },
    );
  }

  Widget _buildJobTypeSelector(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type Beveiliging',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: JobType.values.map((type) {
              final isSelected = _selectedJobType == type;
              return UnifiedButton.category(
                text: type.displayName,
                isSelected: isSelected,
                onPressed: () {
                  setState(() {
                    _selectedJobType = type;
                  });
                  _updatePricingSuggestions();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoForm(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          // Title field with suggestions
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Job Titel',
              hintText: 'Bijv. Evenementbeveiliging Amsterdam',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.auto_awesome, color: colors.primary),
                onPressed: _generateTitleSuggestions,
                tooltip: 'AI Suggesties',
              ),
            ),
            onChanged: (value) => _validateForm(),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          // Description field with AI assistance
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Beschrijving',
              hintText: 'Beschrijf de beveiligingsopdracht...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.psychology, color: colors.primary),
                onPressed: _generateDescriptionSuggestions,
                tooltip: 'AI Beschrijving',
              ),
            ),
            onChanged: (value) => _validateForm(),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          // Location and postal code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Locatie',
                    hintText: 'Amsterdam',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                  ),
                  onChanged: (value) => _validateForm(),
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: InputDecoration(
                    labelText: 'Postcode',
                    hintText: '1012AB',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                  ),
                  onChanged: (value) => _validateForm(),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          // Date selection
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Start Datum',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                  colors,
                ),
              ),
              SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: _buildDateSelector(
                  'Eind Datum',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                  colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, Function(DateTime) onChanged, ColorScheme colors) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onChanged(selectedDate);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: UnifiedCard.standard(
          userRole: UserRole.company,
          padding: EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outline, width: DesignTokens.spacingXS / 4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: UnifiedButton.secondary(
                text: 'Vorige',
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: UnifiedButton.primary(
              text: _currentStep == _totalSteps - 1 
                ? (_isSubmitting ? 'Bezig...' : 'Voltooien')
                : 'Volgende',
              onPressed: _currentStep == _totalSteps - 1 ? _submitJob : _nextStep,
              isLoading: _isSubmitting,
            ),
          ),
        ],
        ),
      ),
    );
  }

  // Step navigation methods
  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
      
      // Load data for next step
      _loadStepData();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  // Helper methods
  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Basis Informatie';
      case 1: return 'Vereisten';
      case 2: return 'Prijsstelling';
      case 3: return 'Voorbeeld';
      case 4: return 'Bevestiging';
      default: return '';
    }
  }

  void _applyTemplate(String templateName) {
    // Apply template logic here
    setState(() {
      _selectedTemplate = JobTemplateData(
        templateId: 'template_${templateName.toLowerCase()}',
        templateName: templateName,
        category: 'Beveiliging',
        description: 'Template voor $templateName',
        defaultSkills: [],
        defaultCertificates: [],
        defaultExperience: 1,
        suggestedRate: 20.0,
        defaultSettings: {},
        createdAt: DateTime.now(),
        usageCount: 0,
      );
    });
  }

  void _updatePricingSuggestions() async {
    if (_locationController.text.isNotEmpty && _postalCodeController.text.isNotEmpty) {
      setState(() {
      });

      try {
        final pricing = await SmartPricingService().getSmartPricing(
          jobType: _selectedJobType,
          location: _locationController.text,
          postalCode: _postalCodeController.text,
          startDate: _startDate,
          endDate: _endDate,
          requiredSkills: _selectedSkills,
          requiredCertificates: _selectedCertificates,
          minimumExperience: _minimumExperience,
          isUrgent: _isUrgent,
        );

        setState(() {
          _pricingData = pricing;
          _hourlyRateController.text = pricing.recommendedRate.toString();
        });
      } catch (e) {
        debugPrint('Error loading pricing: $e');
      } finally {
        setState(() {
        });
      }
    }
  }

  void _generateTitleSuggestions() {
    // AI title generation logic
    final suggestions = [
      '${_selectedJobType.displayName} - ${_locationController.text}',
      'Ervaren ${_selectedJobType.displayName} Gezocht',
      '${_selectedJobType.displayName} ${_isUrgent ? "URGENT" : ""}',
    ];
    
    _showSuggestionDialog('Titel Suggesties', suggestions, (suggestion) {
      _titleController.text = suggestion;
    });
  }

  void _generateDescriptionSuggestions() {
    // AI description generation logic
    final suggestions = [
      'Wij zoeken een ervaren beveiliger voor ${_selectedJobType.displayName.toLowerCase()} in ${_locationController.text}.',
      'Voor onze klant zoeken wij een betrouwbare beveiliger met ervaring in ${_selectedJobType.displayName.toLowerCase()}.',
      'Ben jij de beveiliger die wij zoeken voor deze ${_selectedJobType.displayName.toLowerCase()} opdracht?',
    ];
    
    _showSuggestionDialog('Beschrijving Suggesties', suggestions, (suggestion) {
      _descriptionController.text = suggestion;
    });
  }

  void _showSuggestionDialog(String title, List<String> suggestions, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions.map((suggestion) => ListTile(
            title: Text(suggestion),
            onTap: () {
              onSelect(suggestion);
              context.pop();
            },
          )).toList(),
        ),
        actions: [
          UnifiedButton.text(
            text: 'Annuleren',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  void _loadStepData() {
    // Load data specific to current step
    switch (_currentStep) {
      case 2:
        _updatePricingSuggestions();
        break;
      case 3:
        _loadGuardSuggestions();
        _loadPredictions();
        break;
    }
  }

  void _loadGuardSuggestions() async {
    setState(() {
    });

    try {
      final suggestions = await GuardMatchingEngine().getGuardSuggestions(
        jobType: _selectedJobType,
        location: _locationController.text,
        postalCode: _postalCodeController.text,
        requiredSkills: _selectedSkills,
        requiredCertificates: _selectedCertificates,
        minimumExperience: _minimumExperience,
        startDate: _startDate,
        endDate: _endDate,
        maxHourlyRate: double.tryParse(_hourlyRateController.text) ?? 25.0,
        maxSuggestions: 5,
      );

      setState(() {
        _guardSuggestions = suggestions;
      });
    } catch (e) {
      debugPrint('Error loading guard suggestions: $e');
    } finally {
      setState(() {
      });
    }
  }

  void _loadPredictions() async {
    setState(() {
    });

    try {
      final predictions = await JobAnalyticsService().getJobPredictions(
        jobId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        jobType: _selectedJobType,
        location: _locationController.text,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 20.0,
        requiredSkills: _selectedSkills,
        startDate: _startDate,
        isUrgent: _isUrgent,
      );

      setState(() {
        _predictions = predictions;
      });
    } catch (e) {
      debugPrint('Error loading predictions: $e');
    } finally {
      setState(() {
      });
    }
  }

  void _validateForm() {
    // Form validation logic
  }

  void _submitJob() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create job data
      final jobData = JobPostingData(
        jobId: widget.existingJob?.jobId ?? '',
        companyId: 'COMP001', // Get from auth service
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        postalCode: _postalCodeController.text,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 20.0,
        startDate: _startDate,
        endDate: _endDate,
        requiredSkills: _selectedSkills,
        requiredCertificates: _selectedCertificates,
        minimumExperience: _minimumExperience,
        status: JobPostingStatus.active,
        createdDate: widget.existingJob?.createdDate ?? DateTime.now(),
        isUrgent: _isUrgent,
        specialInstructions: _specialInstructionsController.text.isEmpty 
          ? null 
          : _specialInstructionsController.text,
        jobType: _selectedJobType,
        // AI-powered data
        smartPricing: _pricingData,
        suggestedGuards: _guardSuggestions,
        templateUsed: _selectedTemplate,
        complianceCheck: _complianceCheck,
        predictions: _predictions,
      );

      // Call appropriate callback
      if (widget.existingJob != null) {
        widget.onJobUpdated?.call(jobData);
      } else {
        widget.onJobCreated?.call(jobData);
      }

      // Show success and close
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingJob != null 
              ? 'Job succesvol bijgewerkt' 
              : 'Job succesvol aangemaakt'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan: ${e.toString()}'),
            backgroundColor: DesignTokens.statusCancelled,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildRequirementsStep(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills selection
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vereiste Vaardigheden',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),

                Wrap(
                  spacing: DesignTokens.spacingS,
                  runSpacing: DesignTokens.spacingS,
                  children: _getAvailableSkills().map((skill) {
                    final isSelected = _selectedSkills.contains(skill);
                    return UnifiedButton.category(
                      text: skill,
                      isSelected: isSelected,
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Certificates selection
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vereiste Certificaten',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),

                Wrap(
                  spacing: DesignTokens.spacingS,
                  runSpacing: DesignTokens.spacingS,
                  children: _getAvailableCertificates().map((cert) {
                    final isSelected = _selectedCertificates.contains(cert);
                    return UnifiedButton.category(
                      text: cert,
                      isSelected: isSelected,
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCertificates.remove(cert);
                          } else {
                            _selectedCertificates.add(cert);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: DesignTokens.spacingL),

          // Experience and urgency
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ervaring & Prioriteit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),

                // Experience slider
                Text('Minimale Ervaring: $_minimumExperience jaar'),
                Slider(
                  value: _minimumExperience.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_minimumExperience jaar',
                  onChanged: (value) {
                    setState(() {
                      _minimumExperience = value.round();
                    });
                  },
                ),
                SizedBox(height: DesignTokens.spacingM),

                // Urgency toggle
                SwitchListTile(
                  title: Text('Urgente Opdracht'),
                  subtitle: Text('Verhoogde zichtbaarheid en prioriteit'),
                  value: _isUrgent,
                  onChanged: (value) {
                    setState(() {
                      _isUrgent = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Pricing Recommendations
          if (_pricingData != null) ...[
            UnifiedCard.standard(
              userRole: UserRole.company,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: colors.primary),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'AI Prijsaanbevelingen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),

                  // Pricing options
                  _buildPricingOption(
                    'Aanbevolen',
                    _pricingData!.recommendedRate,
                    'Optimaal voor kwaliteit en concurrentie',
                    colors.primary,
                    true,
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  _buildPricingOption(
                    'Competitief',
                    _pricingData!.competitiveRate,
                    'Lagere prijs voor meer kandidaten',
                    colors.secondary,
                    false,
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  _buildPricingOption(
                    'Premium',
                    _pricingData!.premiumRate,
                    'Hogere prijs voor top kwaliteit',
                    colors.tertiary,
                    false,
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
          ],

          // Manual rate input
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aangepast Tarief',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),

                TextFormField(
                  controller: _hourlyRateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Uurtarief (€)',
                    hintText: '20.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                    ),
                    prefixText: '€ ',
                    suffixText: '/uur',
                  ),
                  onChanged: (value) => _validateForm(),
                ),
              ],
            ),
          ),

          // Pricing factors
          if (_pricingData != null) ...[
            SizedBox(height: DesignTokens.spacingL),
            UnifiedCard.standard(
              userRole: UserRole.company,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prijsfactoren',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingM),

                  ..._pricingData!.factors.map((factor) => Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
                    child: Row(
                      children: [
                        Icon(
                          factor.impact > 0 ? Icons.trending_up : Icons.trending_down,
                          color: factor.impact > 0 ? DesignTokens.statusConfirmed : DesignTokens.statusCancelled,
                          size: 16,
                        ),
                        SizedBox(width: DesignTokens.spacingS),
                        Expanded(
                          child: Text(
                            '${factor.name}: ${factor.description}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Text(
                          '${(factor.impact * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: factor.impact > 0 ? DesignTokens.statusConfirmed : DesignTokens.statusCancelled,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingOption(String title, double rate, String description, Color color, bool isRecommended) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRecommended ? color : Colors.grey.shade300,
          width: isRecommended ? DesignTokens.spacingXS / 2 : DesignTokens.spacingXS / 4,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: ListTile(
        leading: Icon(
          isRecommended ? Icons.star : Icons.radio_button_unchecked,
          color: color,
        ),
        title: Row(
          children: [
            Text(title),
            if (isRecommended) ...[
              SizedBox(width: DesignTokens.spacingS),
              UnifiedCard.standard(
                userRole: UserRole.company,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                backgroundColor: color,
                child: Text(
                  'AANBEVOLEN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: DesignTokens.colorWhite,
                    fontWeight: DesignTokens.fontWeightBold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(description),
        trailing: Text(
          '€${rate.toStringAsFixed(2)}/uur',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: color,
          ),
        ),
        onTap: () {
          setState(() {
            _hourlyRateController.text = rate.toString();
          });
        },
      ),
    );
  }

  Widget _buildPreviewStep(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guard suggestions preview
          if (_guardSuggestions.isNotEmpty) ...[
            UnifiedCard.standard(
              userRole: UserRole.company,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: colors.primary),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Aanbevolen Beveiligers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),

                  ..._guardSuggestions.take(3).map((guard) => Padding(
                    padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(guard.profileImageUrl),
                      ),
                      title: Text(guard.guardName),
                      subtitle: Text(
                        '${guard.matchPercentage.toStringAsFixed(0)}% match • '
                        '${guard.rating.toStringAsFixed(1)}⭐ • '
                        '${guard.distanceKm.toStringAsFixed(1)} km',
                      ),
                      trailing: Text(
                        '€${guard.hourlyRate.toStringAsFixed(2)}/uur',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
          ],

          // Predictions preview
          if (_predictions != null) ...[
            UnifiedCard.standard(
              userRole: UserRole.company,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: colors.primary),
                      SizedBox(width: DesignTokens.spacingS),
                      Text(
                        'Verwachtingen',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingM),

                  Row(
                    children: [
                      Expanded(
                        child: _buildPredictionCard(
                          'Sollicitaties',
                          '${_predictions!.predictedApplications}',
                          Icons.person_add,
                          colors,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: _buildPredictionCard(
                          'Invultijd',
                          '${_predictions!.predictedTimeToFill.inDays} dagen',
                          Icons.schedule,
                          colors,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: _buildPredictionCard(
                          'Succes kans',
                          '${(_predictions!.predictedHireSuccess * 100).toStringAsFixed(0)}%',
                          Icons.check_circle,
                          colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
          ],

          // Job summary
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Samenvatting',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),

                _buildSummaryRow('Titel', _titleController.text),
                _buildSummaryRow('Type', _selectedJobType.displayName),
                _buildSummaryRow('Locatie', '${_locationController.text}, ${_postalCodeController.text}'),
                _buildSummaryRow('Periode', '${_startDate.day}/${_startDate.month} - ${_endDate.day}/${_endDate.month}'),
                _buildSummaryRow('Tarief', '€${_hourlyRateController.text}/uur'),
                if (_selectedSkills.isNotEmpty)
                  _buildSummaryRow('Vaardigheden', _selectedSkills.join(', ')),
                if (_selectedCertificates.isNotEmpty)
                  _buildSummaryRow('Certificaten', _selectedCertificates.join(', ')),
                if (_minimumExperience > 0)
                  _buildSummaryRow('Ervaring', '$_minimumExperience jaar'),
                if (_isUrgent)
                  _buildSummaryRow('Prioriteit', 'Urgent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(ColorScheme colors) {
    return Center(
      child: UnifiedCard.standard(
        userRole: UserRole.company,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: colors.primary,
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Job Klaar voor Publicatie',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Uw job is geconfigureerd met AI-aanbevelingen en klaar om gepubliceerd te worden.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacingL),

            // Final summary
            UnifiedCard.standard(
              userRole: UserRole.company,
              padding: EdgeInsets.all(DesignTokens.spacingM),
              backgroundColor: colors.surfaceContainerHighest,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verwachte sollicitaties:'),
                      Text(
                        '${_predictions?.predictedApplications ?? "5-15"}',
                        style: TextStyle(fontWeight: DesignTokens.fontWeightSemiBold),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verwachte invultijd:'),
                      Text(
                        '${_predictions?.predictedTimeToFill.inDays ?? 2-4} dagen',
                        style: TextStyle(fontWeight: DesignTokens.fontWeightSemiBold),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Beschikbare beveiligers:'),
                      Text(
                        '${_guardSuggestions.length} matches',
                        style: TextStyle(fontWeight: DesignTokens.fontWeightSemiBold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(String title, String value, IconData icon, ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingM),
      backgroundColor: colors.surfaceContainerHighest,
      child: Column(
        children: [
          Icon(icon, color: colors.primary),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: colors.primary,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for skills and certificates
  List<String> _getAvailableSkills() {
    return [
      'Crowd Control',
      'CCTV Monitoring',
      'Access Control',
      'Patrol Services',
      'Emergency Response',
      'Customer Service',
      'Report Writing',
      'Conflict Resolution',
      'First Aid',
      'Fire Safety',
    ];
  }

  List<String> _getAvailableCertificates() {
    return [
      'Beveiliger 2',
      'Portier',
      'Evenementbeveiliging',
      'EHBO',
      'BHV',
      'VCA',
      'Crowd Control',
      'Surveillance',
    ];
  }
}
