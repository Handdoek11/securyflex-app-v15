import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';
// CompanyDashboardTheme import removed - using unified design tokens
import 'package:securyflex_app/company_dashboard/widgets/company_header_elements.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/responsive/responsive_provider.dart';
import '../../core/responsive/responsive_extensions.dart';
import '../widgets/premium_job_image_upload_widget.dart';
import '../models/job_image_data.dart' as img_data;

/// Job posting form screen with Dutch validation
/// Allows companies to create new security job postings
class JobPostingFormScreen extends StatefulWidget {
  final JobPostingData? existingJob; // For editing existing jobs

  const JobPostingFormScreen({super.key, this.existingJob});

  @override
  State<JobPostingFormScreen> createState() => _JobPostingFormScreenState();
}

class _JobPostingFormScreenState extends State<JobPostingFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController animationController;
  late ScrollController scrollController;

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
  List<String> _selectedCertificates = [];
  List<String> _selectedSkills = [];
  int _minimumExperience = 0;
  bool _isUrgent = false;
  bool _isLoading = false;
  
  // Image state
  List<img_data.JobImageData> _uploadedImages = [];

  // Available options
  final List<String> _availableCertificates = [
    'Beveiligingsdiploma A',
    'Beveiligingsdiploma B',
    'BHV',
    'EHBO',
    'Evenementbeveiliging',
    'Persoonbeveiliging',
  ];

  final List<String> _availableSkills = [
    'Toegangscontrole',
    'Surveillance',
    'Crowd Control',
    'Communicatie',
    'Rapportage',
    'Conflicthantering',
  ];

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    scrollController = ScrollController();

    // Initialize form with existing job data if editing
    if (widget.existingJob != null) {
      _initializeFormWithExistingJob();
    }

    animationController.forward();
    super.initState();
  }

  void _initializeFormWithExistingJob() {
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
    _selectedCertificates = List.from(job.requiredCertificates);
    _selectedSkills = List.from(job.requiredSkills);
    _minimumExperience = job.minimumExperience;
    _isUrgent = job.isUrgent;
  }

  /// Get current company ID from authenticated user
  String _getCurrentCompanyId() {
    // In demo mode, use a default company ID
    // In production, this would get the company ID from the authenticated user
    if (AuthService.isLoggedIn && AuthService.currentUserType == 'company') {
      // For demo purposes, use a consistent company ID
      // In production, this would be stored in user profile
      return 'COMP001';
    }
    return 'COMP001'; // Fallback
  }

  @override
  void dispose() {
    animationController.dispose();
    scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _postalCodeController.dispose();
    _hourlyRateController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      color: companyColors.surfaceContainerHighest,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: UnifiedHeader.animated(
            title: widget.existingJob != null ? 'Job Bewerken' : 'Nieuwe Job',
            animationController: animationController,
            scrollController: scrollController,
            enableScrollAnimation: true,
            userRole: UserRole.company,
            titleAlignment: TextAlign.left, // ✅ Standardized left alignment
            actions: [
              CompanyHeaderElements.buildBackButton(
                context: context,
                onPressed: () => context.pop(),
              ),
              if (widget.existingJob != null)
                HeaderElements.actionButton(
                  icon: Icons.delete_outline,
                  onPressed: _showDeleteConfirmation,
                  userRole: UserRole.company,
                ),
            ],
          ),
        ),
        body: _buildForm(context),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        children: [
          _buildBasicInfoSection(),
          SizedBox(height: DesignTokens.spacingXL),
          _buildLocationSection(),
          SizedBox(height: DesignTokens.spacingXL),
          _buildScheduleSection(),
          SizedBox(height: DesignTokens.spacingXL),
          _buildRequirementsSection(),
          SizedBox(height: DesignTokens.spacingXL),
          _buildImageUploadSection(),
          SizedBox(height: DesignTokens.spacingXL),
          _buildAdditionalOptionsSection(),
          SizedBox(
            height: DesignTokens.spacingXXL * 2.5,
          ), // Space for bottom bar
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section header boven de container
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingXS,
            bottom: DesignTokens.spacingS,
          ),
          child: Text(
            'Basis Informatie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ✅ Container zonder header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: companyColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: companyColors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Job Titel *',
                  hintText: 'Bijv. Objectbeveiliging Kantoorpand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Titel is verplicht';
                  }
                  if (value.trim().length < 5) {
                    return 'Titel moet minimaal 5 karakters bevatten';
                  }
                  return null;
                },
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Job type dropdown
              DropdownButtonFormField<JobType>(
                initialValue: _selectedJobType,
                decoration: InputDecoration(
                  labelText: 'Type Beveiliging *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
                items: JobType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedJobType = value;
                    });
                  }
                },
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Beschrijving *',
                  hintText:
                      'Beschrijf de job, werkzaamheden en verwachtingen...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Beschrijving is verplicht';
                  }
                  if (value.trim().length < 20) {
                    return 'Beschrijving moet minimaal 20 karakters bevatten';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section header boven de container
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingXS,
            bottom: DesignTokens.spacingS,
          ),
          child: Text(
            'Locatie & Vergoeding',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ✅ Container zonder header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: companyColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: companyColors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Locatie *',
                  hintText: 'Bijv. Amsterdam Centrum',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Locatie is verplicht';
                  }
                  return null;
                },
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Postal code with Dutch validation
              TextFormField(
                controller: _postalCodeController,
                decoration: InputDecoration(
                  labelText: 'Postcode *',
                  hintText: '1234AB',
                  prefixIcon: Icon(Icons.local_post_office),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Postcode is verplicht';
                  }
                  if (!DutchBusinessValidation.isValidPostalCode(value)) {
                    return 'Ongeldige postcode (gebruik 1234AB formaat)';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Auto-format postal code as user types
                  if (value.length == 6) {
                    final formatted = DutchBusinessValidation.formatPostalCode(
                      value,
                    );
                    if (formatted != value) {
                      _postalCodeController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Hourly rate
              TextFormField(
                controller: _hourlyRateController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Uurtarief *',
                  hintText: '18.50',
                  prefixIcon: Icon(Icons.euro),
                  suffixText: '€/uur',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Uurtarief is verplicht';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null) {
                    return 'Ongeldig bedrag';
                  }
                  if (rate < 10.0) {
                    return 'Minimum uurtarief is €10.00';
                  }
                  if (rate > 100.0) {
                    return 'Maximum uurtarief is €100.00';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section header boven de container
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingXS,
            bottom: DesignTokens.spacingS,
          ),
          child: Text(
            'Planning',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ✅ Container zonder header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: companyColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: companyColors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start date
              ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: companyColors.primary,
                ),
                title: Text('Startdatum'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy', 'nl_NL').format(_startDate),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectStartDate(context),
              ),

              const Divider(),

              // End date
              ListTile(
                leading: Icon(Icons.event, color: companyColors.primary),
                title: Text('Einddatum'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy', 'nl_NL').format(_endDate),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectEndDate(context),
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Urgent checkbox
              CheckboxListTile(
                title: Text('Urgente Job'),
                subtitle: Text('Prioriteit in zoekresultaten'),
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value ?? false;
                  });
                },
                activeColor: companyColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementsSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section header boven de container
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingXS,
            bottom: DesignTokens.spacingS,
          ),
          child: Text(
            'Vereisten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ✅ Container zonder header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: companyColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: companyColors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimum experience
              Text(
                'Minimale Ervaring: $_minimumExperience jaar',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
                activeColor: companyColors.primary,
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Required certificates
              Text(
                'Vereiste Certificaten',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCertificates.map((cert) {
                  final isSelected = _selectedCertificates.contains(cert);
                  return FilterChip(
                    label: Text(cert),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCertificates.add(cert);
                        } else {
                          _selectedCertificates.remove(cert);
                        }
                      });
                    },
                    selectedColor: companyColors.primaryContainer,
                    checkmarkColor: companyColors.onPrimaryContainer,
                  );
                }).toList(),
              ),

              SizedBox(height: DesignTokens.spacingM),

              // Required skills
              Text(
                'Gewenste Vaardigheden',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: DesignTokens.spacingS),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(skill);
                        } else {
                          _selectedSkills.remove(skill);
                        }
                      });
                    },
                    selectedColor: companyColors.secondaryContainer,
                    checkmarkColor: companyColors.onSecondaryContainer,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingXS,
            bottom: DesignTokens.spacingS,
          ),
          child: Text(
            'Afbeeldingen Toevoegen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Image upload widget
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: companyColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: companyColors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: PremiumJobImageUploadWidget(
            jobId: widget.existingJob?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
            existingImages: widget.existingJob?.images?.cast<img_data.JobImageData>(),
            onImagesUpdated: (images) {
              setState(() {
                _uploadedImages = images;
              });
            },
            maxImages: 5,
            enableAIAnalysis: true,
            showInsights: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalOptionsSection() {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Section header boven de container
        Padding(
          padding: EdgeInsets.only(
            left: DesignTokens.spacingXS,
            bottom: DesignTokens.spacingS,
          ),
          child: Text(
            'Aanvullende Informatie',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: companyColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ✅ Container zonder header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          decoration: BoxDecoration(
            color: companyColors.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            boxShadow: [
              BoxShadow(
                color: companyColors.shadow.withValues(alpha: 0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Special instructions
              TextFormField(
                controller: _specialInstructionsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Speciale Instructies',
                  hintText:
                      'Bijzondere aandachtspunten, toegangsprocedures, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + context.safeAreaResponsivePadding.bottom,
      ),
      decoration: BoxDecoration(
        color: companyColors.surface,
        boxShadow: [
          BoxShadow(
            color: companyColors.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: UnifiedButton.secondary(
              text: 'Annuleren',
              size: UnifiedButtonSize.small,
              onPressed: () => context.pop(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: _isLoading
                ? UnifiedButton.primary(
                    text: 'Bezig...',
                    size: UnifiedButtonSize.small,
                    onPressed: () {}, // Disabled state
                  )
                : UnifiedButton.primary(
                    text: widget.existingJob != null
                        ? 'Bijwerken'
                        : 'Publiceren',
                    size: UnifiedButtonSize.small,
                    onPressed: () {
                      _submitForm();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('nl', 'NL'),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('nl', 'NL'),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate job ID if creating new
      final jobId = widget.existingJob?.id ?? 'JOB_${DateTime.now().millisecondsSinceEpoch}';
      
      final jobData = JobPostingData(
        jobId: widget.existingJob?.jobId ?? jobId,
        companyId: _getCurrentCompanyId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        postalCode: _postalCodeController.text.trim().toUpperCase(),
        hourlyRate: double.parse(_hourlyRateController.text),
        startDate: _startDate,
        endDate: _endDate,
        requiredCertificates: _selectedCertificates,
        requiredSkills: _selectedSkills,
        minimumExperience: _minimumExperience,
        status: JobPostingStatus.active,
        createdDate: widget.existingJob?.createdDate ?? DateTime.now(),
        isUrgent: _isUrgent,
        specialInstructions: _specialInstructionsController.text.trim().isEmpty
            ? null
            : _specialInstructionsController.text.trim(),
        jobType: _selectedJobType,
        images: _uploadedImages.isNotEmpty ? _uploadedImages : null,
      );

      bool success;
      if (widget.existingJob != null) {
        success = await JobPostingService.instance.updateJob(jobData);
      } else {
        success = await JobPostingService.instance.createJob(jobData);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.existingJob != null
                    ? 'Job succesvol bijgewerkt'
                    : 'Job succesvol gepubliceerd',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          context.pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Er is een fout opgetreden. Probeer opnieuw.'),
              backgroundColor: DesignTokens.statusCancelled,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout: ${e.toString()}'),
            backgroundColor: DesignTokens.statusCancelled,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Opdracht Verwijderen'),
        content: Text(
          'Weet je zeker dat je deze opdracht wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          UnifiedButton.text(
            text: 'Annuleren',
            onPressed: () => context.pop(),
          ),
          UnifiedButton.primary(
            text: 'Verwijderen',
            onPressed: () async {
              context.pop();
              await _deleteJob();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJob() async {
    if (widget.existingJob == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await JobPostingService.instance.deleteJob(
        widget.existingJob!.jobId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opdracht succesvol verwijderd'),
            backgroundColor: DesignTokens.statusConfirmed,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij verwijderen: ${e.toString()}'),
            backgroundColor: DesignTokens.statusCancelled,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
