import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// Advanced filter panel with preset saving capability
class AdvancedFilterPanel extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final VoidCallback? onExport;
  
  const AdvancedFilterPanel({
    super.key,
    required this.onFiltersChanged,
    this.onExport,
  });

  @override
  State<AdvancedFilterPanel> createState() => _AdvancedFilterPanelState();
}

class _AdvancedFilterPanelState extends State<AdvancedFilterPanel> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  
  // Filter values
  String? _selectedStatus;
  String? _selectedDateRange;
  String? _selectedLocation;
  String? _selectedCertificate;
  double _minRate = 0;
  double _maxRate = 100;
  int? _minGuards;
  int? _maxGuards;
  String? _selectedUrgency;
  
  // Saved presets
  List<FilterPreset> _savedPresets = [];
  TextEditingController _presetNameController = TextEditingController();
  
  // Export formats
  String _selectedExportFormat = 'CSV';
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadSavedPresets();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _presetNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSavedPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = prefs.getStringList('company_filter_presets') ?? [];
    setState(() {
      _savedPresets = presetsJson
          .map((json) => FilterPreset.fromJson(jsonDecode(json)))
          .toList();
    });
  }
  
  Future<void> _savePreset(String name) async {
    final preset = FilterPreset(
      name: name,
      filters: _getCurrentFilters(),
      createdAt: DateTime.now(),
    );
    
    _savedPresets.add(preset);
    
    final prefs = await SharedPreferences.getInstance();
    final presetsJson = _savedPresets
        .map((preset) => jsonEncode(preset.toJson()))
        .toList();
    await prefs.setStringList('company_filter_presets', presetsJson);
    
    setState(() {});
    _presetNameController.clear();
  }
  
  Map<String, dynamic> _getCurrentFilters() {
    return {
      'status': _selectedStatus,
      'dateRange': _selectedDateRange,
      'location': _selectedLocation,
      'certificate': _selectedCertificate,
      'minRate': _minRate,
      'maxRate': _maxRate,
      'minGuards': _minGuards,
      'maxGuards': _maxGuards,
      'urgency': _selectedUrgency,
    };
  }
  
  void _applyPreset(FilterPreset preset) {
    setState(() {
      _selectedStatus = preset.filters['status'];
      _selectedDateRange = preset.filters['dateRange'];
      _selectedLocation = preset.filters['location'];
      _selectedCertificate = preset.filters['certificate'];
      _minRate = preset.filters['minRate'] ?? 0;
      _maxRate = preset.filters['maxRate'] ?? 100;
      _minGuards = preset.filters['minGuards'];
      _maxGuards = preset.filters['maxGuards'];
      _selectedUrgency = preset.filters['urgency'];
    });
    widget.onFiltersChanged(_getCurrentFilters());
  }
  
  void _resetFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDateRange = null;
      _selectedLocation = null;
      _selectedCertificate = null;
      _minRate = 0;
      _maxRate = 100;
      _minGuards = null;
      _maxGuards = null;
      _selectedUrgency = null;
    });
    widget.onFiltersChanged({});
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colorScheme),
          _buildFilterContent(colorScheme),
          _buildPresetSection(colorScheme),
          _buildActionBar(colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: colorScheme.primary,
            size: 24,
          ),
          SizedBox(width: DesignTokens.spacingM),
          Text(
            'Geavanceerde Filters',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSubtitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: colorScheme.onSurface,
            ),
          ),
          Spacer(),
          // Quick actions
          _buildQuickFilterChip('Vandaag', colorScheme),
          SizedBox(width: DesignTokens.spacingS),
          _buildQuickFilterChip('Deze Week', colorScheme),
          SizedBox(width: DesignTokens.spacingS),
          _buildQuickFilterChip('Urgent', colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildQuickFilterChip(String label, ColorScheme colorScheme) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12),
      ),
      onPressed: () {
        if (mounted) {
          // Apply quick filter
          if (label == 'Vandaag') {
            setState(() => _selectedDateRange = 'today');
          } else if (label == 'Deze Week') {
            setState(() => _selectedDateRange = 'week');
          } else if (label == 'Urgent') {
            setState(() => _selectedUrgency = 'high');
          }
          widget.onFiltersChanged(_getCurrentFilters());
        }
      },
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
      side: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.3),
      ),
    );
  }
  
  Widget _buildFilterContent(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row of filters
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildDropdownFilter(
                  label: 'Status',
                  value: _selectedStatus,
                  items: ['Actief', 'Inactief', 'Voltooid', 'Geannuleerd'],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    widget.onFiltersChanged(_getCurrentFilters());
                  },
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: DesignTokens.spacingL),
              Flexible(
                fit: FlexFit.loose,
                child: _buildDropdownFilter(
                  label: 'Periode',
                  value: _selectedDateRange,
                  items: ['Vandaag', 'Deze Week', 'Deze Maand', 'Dit Jaar'],
                  onChanged: (value) {
                    setState(() => _selectedDateRange = value);
                    widget.onFiltersChanged(_getCurrentFilters());
                  },
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: DesignTokens.spacingL),
              Flexible(
                fit: FlexFit.loose,
                child: _buildDropdownFilter(
                  label: 'Locatie',
                  value: _selectedLocation,
                  items: ['Amsterdam', 'Rotterdam', 'Den Haag', 'Utrecht'],
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                    widget.onFiltersChanged(_getCurrentFilters());
                  },
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingL),
          // Second row with range sliders
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: _buildRangeSlider(
                  label: 'Uurtarief',
                  min: 0,
                  max: 100,
                  currentMin: _minRate,
                  currentMax: _maxRate,
                  onChanged: (min, max) {
                    setState(() {
                      _minRate = min;
                      _maxRate = max;
                    });
                    widget.onFiltersChanged(_getCurrentFilters());
                  },
                  colorScheme: colorScheme,
                ),
              ),
              SizedBox(width: DesignTokens.spacingL),
              Flexible(
                fit: FlexFit.loose,
                child: _buildDropdownFilter(
                  label: 'Certificaat Vereist',
                  value: _selectedCertificate,
                  items: ['WPBR', 'VCA', 'BHV', 'EHBO', 'Geen'],
                  onChanged: (value) {
                    setState(() => _selectedCertificate = value);
                    widget.onFiltersChanged(_getCurrentFilters());
                  },
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
          items: items.map((item) => DropdownMenuItem(
            value: item.toLowerCase(),
            child: Text(item, style: TextStyle(fontSize: 14)),
          )).toList(),
          onChanged: (newValue) {
            if (mounted) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildRangeSlider({
    required String label,
    required double min,
    required double max,
    required double currentMin,
    required double currentMax,
    required Function(double, double) onChanged,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '€${currentMin.toInt()} - €${currentMax.toInt()}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: RangeValues(currentMin, currentMax),
          min: min,
          max: max,
          divisions: 20,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.primary.withValues(alpha: 0.2),
          onChanged: (values) {
            if (mounted) {
              onChanged(values.start, values.end);
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildPresetSection(ColorScheme colorScheme) {
    if (_savedPresets.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingM,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Opgeslagen Filters',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Wrap(
            spacing: DesignTokens.spacingS,
            runSpacing: DesignTokens.spacingS,
            children: _savedPresets.map((preset) => Chip(
              label: Text(
                preset.name,
                style: TextStyle(fontSize: 12),
              ),
              deleteIcon: Icon(Icons.close, size: 16),
              onDeleted: () async {
                if (mounted) {
                  setState(() {
                    _savedPresets.remove(preset);
                  });
                  final prefs = await SharedPreferences.getInstance();
                  final presetsJson = _savedPresets
                      .map((p) => jsonEncode(p.toJson()))
                      .toList();
                  await prefs.setStringList('company_filter_presets', presetsJson);
                }
              },
              backgroundColor: colorScheme.secondaryContainer,
              side: BorderSide(
                color: colorScheme.secondary.withValues(alpha: 0.3),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionBar(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DesignTokens.radiusL),
          bottomRight: Radius.circular(DesignTokens.radiusL),
        ),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Save preset
          SizedBox(
            width: 200,
            child: TextField(
              controller: _presetNameController,
              decoration: InputDecoration(
                hintText: 'Preset naam...',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.save, size: 20),
                  onPressed: () {
                    if (_presetNameController.text.isNotEmpty && mounted) {
                      _savePreset(_presetNameController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: DesignTokens.spacingL),
          // Export options
          DropdownButton<String>(
            value: _selectedExportFormat,
            items: ['CSV', 'Excel', 'PDF', 'JSON'].map((format) => 
              DropdownMenuItem(
                value: format,
                child: Text(format, style: TextStyle(fontSize: 14)),
              ),
            ).toList(),
            onChanged: (value) {
              if (mounted && value != null) {
                setState(() => _selectedExportFormat = value);
              }
            },
          ),
          SizedBox(width: DesignTokens.spacingS),
          ElevatedButton.icon(
            onPressed: widget.onExport,
            icon: Icon(Icons.download, size: 18),
            label: Text('Exporteer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
          ),
          Spacer(),
          // Reset button
          TextButton(
            onPressed: _resetFilters,
            child: Text('Reset'),
          ),
          SizedBox(width: DesignTokens.spacingM),
          // Apply button
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                widget.onFiltersChanged(_getCurrentFilters());
              }
            },
            child: Text('Toepassen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter preset model
class FilterPreset {
  final String name;
  final Map<String, dynamic> filters;
  final DateTime createdAt;
  
  FilterPreset({
    required this.name,
    required this.filters,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'filters': filters,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory FilterPreset.fromJson(Map<String, dynamic> json) => FilterPreset(
    name: json['name'],
    filters: json['filters'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}