import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_buttons.dart';
import '../../unified_card_system.dart';
import '../../unified_input_system.dart';
import '../../unified_theme_system.dart';
import '../bloc/job_bloc.dart';
import '../bloc/job_event.dart';
import '../bloc/job_state.dart';
import '../services/postcode_service.dart';
import '../services/certificate_matching_service.dart';

/// JobSearchWidget met geavanceerde filters voor Nederlandse beveiligingsmarktplaats
/// 
/// Comprehensive job search interface with Nederlandse postcode validation,
/// certificate matching, salary filtering, and real-time search capabilities.
/// Uses UnifiedComponents for consistent design and role-based theming.
class JobSearchWidget extends StatefulWidget {
  final UserRole userRole;
  final String? initialSearchQuery;
  final String? userPostcode;
  final List<String>? userCertificates;
  final VoidCallback? onFiltersChanged;
  final bool showAdvancedFilters;
  final bool isCompactMode;
  
  const JobSearchWidget({
    super.key,
    this.userRole = UserRole.guard,
    this.initialSearchQuery,
    this.userPostcode,
    this.userCertificates,
    this.onFiltersChanged,
    this.showAdvancedFilters = true,
    this.isCompactMode = false,
  });
  
  @override
  State<JobSearchWidget> createState() => _JobSearchWidgetState();
}

class _JobSearchWidgetState extends State<JobSearchWidget> 
    with SingleTickerProviderStateMixin {
  
  // Controllers
  late final TextEditingController _searchController;
  late final TextEditingController _postcodeController;
  late final AnimationController _animationController;
  
  // State variables
  bool _showAdvancedFilters = false;
  RangeValues _salaryRange = const RangeValues(15.0, 35.0);
  double _maxDistance = 25.0;
  String _selectedJobType = '';
  List<String> _selectedCertificates = [];
  String _sortBy = 'relevance';
  bool _onlyShowQualified = false;
  
  // Available options
  final List<String> _jobTypes = [
    'Alle types',
    'Objectbeveiliging',
    'Evenementbeveiliging',
    'Winkelbeveiliging',
    'Persoonbeveiliging',
    'Portier',
  ];
  
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchQuery ?? '');
    _postcodeController = TextEditingController(text: widget.userPostcode ?? '');
    _selectedCertificates = List.from(widget.userCertificates ?? []);
    _showAdvancedFilters = widget.showAdvancedFilters;
    
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    
    if (_showAdvancedFilters) {
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _postcodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: widget.userRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (!widget.isCompactMode) _buildHeader(),
          
          // Basic search
          _buildBasicSearch(),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Advanced filters toggle and content
          if (widget.showAdvancedFilters) ...[
            _buildFiltersToggle(),
            _buildAdvancedFilters(),
          ],
          
          SizedBox(height: DesignTokens.spacingL),
          
          // Search actions
          _buildSearchActions(),
          
          // Active filters summary
          _buildActiveFiltersSummary(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingL),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: _getThemeColors().primary,
            size: DesignTokens.iconSizeL,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Text(
            'Opdrachten zoeken',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: _getThemeColors().onSurface,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBasicSearch() {
    return Column(
      children: [
        // Search input
        UnifiedInput.search(
          label: 'Zoeken naar opdrachten',
          controller: _searchController,
          hint: 'Bijv. beveiliging, Amsterdam, VCA...',
          onChanged: _onSearchChanged,
          onSubmitted: _onSearchSubmitted,
          userRole: widget.userRole,
        ),
        
        SizedBox(height: DesignTokens.spacingM),
        
        // Postcode and distance (always visible for location-based search)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: UnifiedInput.standard(
                label: 'Postcode',
                controller: _postcodeController,
                hint: '1234AB',
                validator: _validatePostcode,
                onChanged: _onPostcodeChanged,
                userRole: widget.userRole,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max afstand',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeMeta,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: _getThemeColors().onSurface,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    '${_maxDistance.round()} km',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: _getThemeColors().primary,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 1.0,
                    max: 50.0,
                    divisions: 49,
                    activeColor: _getThemeColors().primary,
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFiltersToggle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
      child: UnifiedButton.text(
        text: _showAdvancedFilters ? 'Minder filters' : 'Meer filters',
        onPressed: _toggleAdvancedFilters,
      ),
    );
  }
  
  Widget _buildAdvancedFilters() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _animationController,
          child: Container(
            padding: EdgeInsets.only(top: DesignTokens.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salary range
                _buildSalaryFilter(),
                
                SizedBox(height: DesignTokens.spacingL),
                
                // Job type
                _buildJobTypeFilter(),
                
                SizedBox(height: DesignTokens.spacingL),
                
                // Certificates
                _buildCertificatesFilter(),
                
                SizedBox(height: DesignTokens.spacingL),
                
                // Sort and additional options
                _buildSortAndOptions(),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSalaryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uurloon bereik',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeMeta,
            fontWeight: DesignTokens.fontWeightMedium,
            color: _getThemeColors().onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          '€${_salaryRange.start.round()} - €${_salaryRange.end.round()} per uur',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: _getThemeColors().primary,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        RangeSlider(
          values: _salaryRange,
          min: 12.0,
          max: 50.0,
          divisions: 38,
          activeColor: _getThemeColors().primary,
          labels: RangeLabels(
            '€${_salaryRange.start.round()}',
            '€${_salaryRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _salaryRange = values;
            });
            _applyFilters();
          },
        ),
      ],
    );
  }
  
  Widget _buildJobTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type opdracht',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeMeta,
            fontWeight: DesignTokens.fontWeightMedium,
            color: _getThemeColors().onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: _jobTypes.map((type) {
            final isSelected = _selectedJobType == type || (type == 'Alle types' && _selectedJobType.isEmpty);
            return UnifiedButton.category(
              text: type,
              isSelected: isSelected,
              onPressed: () {
                setState(() {
                  _selectedJobType = type == 'Alle types' ? '' : type;
                });
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCertificatesFilter() {
    final availableCertificates = CertificateMatchingService.getAllRecognizedCertificates()
        .map((cert) => cert.name)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vereiste certificaten',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeMeta,
            fontWeight: DesignTokens.fontWeightMedium,
            color: _getThemeColors().onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: availableCertificates.map((cert) {
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
                _applyFilters();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildSortAndOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sort options
        Text(
          'Sorteren op',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeMeta,
            fontWeight: DesignTokens.fontWeightMedium,
            color: _getThemeColors().onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: _getThemeColors().outline),
            borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value ?? 'relevance';
                });
                _applyFilters();
              },
              items: [
                DropdownMenuItem(value: 'relevance', child: Text('Relevantie')),
                DropdownMenuItem(value: 'salary_desc', child: Text('Salaris (hoog-laag)')),
                DropdownMenuItem(value: 'salary_asc', child: Text('Salaris (laag-hoog)')),
                DropdownMenuItem(value: 'distance', child: Text('Afstand')),
                DropdownMenuItem(value: 'start_date', child: Text('Startdatum')),
                DropdownMenuItem(value: 'company_rating', child: Text('Bedrijfsrating')),
              ],
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            ),
          ),
        ),
        
        SizedBox(height: DesignTokens.spacingM),
        
        // Additional options
        if (widget.userCertificates != null && widget.userCertificates!.isNotEmpty) ...[
          Row(
            children: [
              Checkbox(
                value: _onlyShowQualified,
                onChanged: (value) {
                  setState(() {
                    _onlyShowQualified = value ?? false;
                  });
                  _applyFilters();
                },
                activeColor: _getThemeColors().primary,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  'Alleen opdrachten waarvoor ik gekwalificeerd ben',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: _getThemeColors().onSurface,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildSearchActions() {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        final isLoading = state is JobLoading;
        
        return Row(
          children: [
            Expanded(
              child: UnifiedButton.primary(
                text: 'Zoeken',
                onPressed: isLoading ? () {} : _performSearch,
                isLoading: isLoading,
                backgroundColor: _getThemeColors().primary,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
            UnifiedButton.secondary(
              text: 'Wissen',
              onPressed: _clearFilters,
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildActiveFiltersSummary() {
    return BlocBuilder<JobBloc, JobState>(
      builder: (context, state) {
        if (state is! JobLoaded || !state.hasActiveFilters) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: EdgeInsets.only(top: DesignTokens.spacingM),
          padding: EdgeInsets.all(DesignTokens.spacingS),
          decoration: BoxDecoration(
            color: _getThemeColors().surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusS),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actieve filters:',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeMeta,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _getThemeColors().onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                state.filterSummary,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: _getThemeColors().onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Event handlers
  void _onSearchChanged(String query) {
    // Debounced search - only trigger after user stops typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _applyFilters();
      }
    });
  }
  
  void _onSearchSubmitted(String query) {
    _performSearch();
  }
  
  void _onPostcodeChanged(String postcode) {
    _applyFilters();
  }
  
  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });
    
    if (_showAdvancedFilters) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  void _performSearch() {
    _applyFilters();
  }
  
  void _applyFilters() {
    final jobBloc = context.read<JobBloc>();
    
    jobBloc.add(FilterJobs(
      searchQuery: _searchController.text.trim(),
      hourlyRateRange: _salaryRange,
      maxDistance: _maxDistance,
      jobType: _selectedJobType,
      certificates: _selectedCertificates,
    ));
    
    widget.onFiltersChanged?.call();
  }
  
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _postcodeController.text = widget.userPostcode ?? '';
      _salaryRange = const RangeValues(15.0, 35.0);
      _maxDistance = 25.0;
      _selectedJobType = '';
      _selectedCertificates.clear();
      _sortBy = 'relevance';
      _onlyShowQualified = false;
    });
    
    final jobBloc = context.read<JobBloc>();
    jobBloc.add(const ClearFilters());
    
    widget.onFiltersChanged?.call();
  }
  
  // Validation
  String? _validatePostcode(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final validation = PostcodeService.validatePostcodeDetailed(value);
    if (!validation.isValid) {
      return validation.errorMessage;
    }
    
    return null;
  }
  
  // Theme helper
  ColorScheme _getThemeColors() {
    return SecuryFlexTheme.getColorScheme(widget.userRole);
  }
}