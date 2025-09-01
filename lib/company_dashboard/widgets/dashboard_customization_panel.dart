import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';

/// Dashboard customization panel for personalizing the interface
class DashboardCustomizationPanel extends StatefulWidget {
  final Function(DashboardConfig) onConfigChanged;
  
  const DashboardCustomizationPanel({
    super.key,
    required this.onConfigChanged,
  });

  @override
  State<DashboardCustomizationPanel> createState() => _DashboardCustomizationPanelState();
}

class _DashboardCustomizationPanelState extends State<DashboardCustomizationPanel> {
  late DashboardConfig _currentConfig;
  bool _isEditMode = false;
  
  // Widget visibility toggles
  Map<String, bool> _widgetVisibility = {
    'revenue_metrics': true,
    'active_jobs': true,
    'applications': true,
    'team_overview': true,
    'live_stats': true,
    'analytics_chart': true,
    'quick_actions': true,
    'recent_activity': true,
  };
  
  // Layout preferences
  String _selectedLayout = 'grid'; // grid, list, cards
  String _selectedDensity = 'comfortable'; // compact, comfortable, spacious
  
  // Color preferences
  String _accentColor = 'blue';
  bool _useHighContrast = false;
  
  // Data refresh settings
  int _refreshInterval = 30; // seconds
  bool _autoRefresh = true;
  
  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }
  
  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('company_dashboard_config');
    
    if (configJson != null) {
      setState(() {
        _currentConfig = DashboardConfig.fromJson(jsonDecode(configJson));
        _applyConfig(_currentConfig);
      });
    } else {
      _currentConfig = DashboardConfig.defaultConfig();
    }
  }
  
  void _applyConfig(DashboardConfig config) {
    _widgetVisibility = config.widgetVisibility;
    _selectedLayout = config.layout;
    _selectedDensity = config.density;
    _accentColor = config.accentColor;
    _useHighContrast = config.useHighContrast;
    _refreshInterval = config.refreshInterval;
    _autoRefresh = config.autoRefresh;
  }
  
  Future<void> _saveConfiguration() async {
    final config = DashboardConfig(
      widgetVisibility: _widgetVisibility,
      layout: _selectedLayout,
      density: _selectedDensity,
      accentColor: _accentColor,
      useHighContrast: _useHighContrast,
      refreshInterval: _refreshInterval,
      autoRefresh: _autoRefresh,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_dashboard_config', jsonEncode(config.toJson()));
    
    widget.onConfigChanged(config);
    
    setState(() {
      _currentConfig = config;
      _isEditMode = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dashboard configuratie opgeslagen'),
          backgroundColor: DesignTokens.colorSuccess,
        ),
      );
    }
  }
  
  void _resetToDefaults() {
    final defaultConfig = DashboardConfig.defaultConfig();
    _applyConfig(defaultConfig);
    setState(() {
      _currentConfig = defaultConfig;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _isEditMode ? 400 : 50,
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        boxShadow: _isEditMode ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(-2, 0),
          ),
        ] : [],
      ),
      child: _isEditMode ? _buildEditPanel(colorScheme) : _buildCollapsedButton(colorScheme),
    );
  }
  
  Widget _buildCollapsedButton(ColorScheme colorScheme) {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 20),
      child: IconButton(
        icon: Icon(Icons.settings, color: colorScheme.primary),
        onPressed: () => setState(() => _isEditMode = true),
        tooltip: 'Dashboard aanpassen',
      ),
    );
  }
  
  Widget _buildEditPanel(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildHeader(colorScheme),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWidgetVisibilitySection(colorScheme),
                SizedBox(height: DesignTokens.spacingXL),
                _buildLayoutSection(colorScheme),
                SizedBox(height: DesignTokens.spacingXL),
                _buildAppearanceSection(colorScheme),
                SizedBox(height: DesignTokens.spacingXL),
                _buildDataSection(colorScheme),
              ],
            ),
          ),
        ),
        _buildFooter(colorScheme),
      ],
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
          Icon(Icons.dashboard_customize, color: colorScheme.primary),
          SizedBox(width: DesignTokens.spacingM),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              'Dashboard Aanpassen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSubtitle,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => setState(() => _isEditMode = false),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWidgetVisibilitySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Widgets Tonen/Verbergen', Icons.widgets, colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        ..._widgetVisibility.entries.map((entry) {
          return SwitchListTile(
            title: Text(_getWidgetDisplayName(entry.key)),
            value: entry.value,
            onChanged: (value) {
              setState(() {
                _widgetVisibility[entry.key] = value;
              });
            },
            secondary: Icon(_getWidgetIcon(entry.key)),
            dense: true,
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildLayoutSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Layout Opties', Icons.view_module, colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        // Layout style
        ListTile(
          title: Text('Weergave'),
          subtitle: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'grid',
                label: Text('Grid'),
                icon: Icon(Icons.grid_view),
              ),
              ButtonSegment(
                value: 'list',
                label: Text('Lijst'),
                icon: Icon(Icons.view_list),
              ),
              ButtonSegment(
                value: 'cards',
                label: Text('Kaarten'),
                icon: Icon(Icons.view_carousel),
              ),
            ],
            selected: {_selectedLayout},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _selectedLayout = selection.first;
              });
            },
          ),
        ),
        // Density
        ListTile(
          title: Text('Dichtheid'),
          subtitle: SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'compact', label: Text('Compact')),
              ButtonSegment(value: 'comfortable', label: Text('Normaal')),
              ButtonSegment(value: 'spacious', label: Text('Ruim')),
            ],
            selected: {_selectedDensity},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _selectedDensity = selection.first;
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAppearanceSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Uiterlijk', Icons.palette, colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        // Accent color
        ListTile(
          title: Text('Accent Kleur'),
          subtitle: Row(
            children: [
              _buildColorOption('blue', Colors.blue),
              _buildColorOption('green', Colors.green),
              _buildColorOption('purple', Colors.purple),
              _buildColorOption('orange', Colors.orange),
              _buildColorOption('red', Colors.red),
            ],
          ),
        ),
        // High contrast
        SwitchListTile(
          title: Text('Hoog Contrast'),
          subtitle: Text('Voor betere leesbaarheid'),
          value: _useHighContrast,
          onChanged: (value) {
            setState(() {
              _useHighContrast = value;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildDataSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Data & Verversing', Icons.refresh, colorScheme),
        SizedBox(height: DesignTokens.spacingM),
        // Auto refresh
        SwitchListTile(
          title: Text('Automatisch Vernieuwen'),
          value: _autoRefresh,
          onChanged: (value) {
            setState(() {
              _autoRefresh = value;
            });
          },
        ),
        // Refresh interval
        if (_autoRefresh)
          ListTile(
            title: Text('Verversingsinterval'),
            subtitle: Slider(
              value: _refreshInterval.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              label: '$_refreshInterval seconden',
              onChanged: (value) {
                setState(() {
                  _refreshInterval = value.round();
                });
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        SizedBox(width: DesignTokens.spacingS),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
  
  Widget _buildColorOption(String value, Color color) {
    final isSelected = _accentColor == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _accentColor = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ] : [],
          ),
          child: isSelected ? Icon(
            Icons.check,
            color: Colors.white,
            size: 16,
          ) : null,
        ),
      ),
    );
  }
  
  Widget _buildFooter(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _resetToDefaults,
            child: Text('Reset'),
          ),
          Spacer(),
          TextButton(
            onPressed: () => setState(() => _isEditMode = false),
            child: Text('Annuleren'),
          ),
          SizedBox(width: DesignTokens.spacingM),
          ElevatedButton(
            onPressed: _saveConfiguration,
            child: Text('Opslaan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getWidgetDisplayName(String key) {
    final names = {
      'revenue_metrics': 'Omzet Statistieken',
      'active_jobs': 'Actieve Opdrachten',
      'applications': 'Sollicitaties',
      'team_overview': 'Team Overzicht',
      'live_stats': 'Live Dashboard',
      'analytics_chart': 'Analytics Grafiek',
      'quick_actions': 'Snelle Acties',
      'recent_activity': 'Recente Activiteit',
    };
    return names[key] ?? key;
  }
  
  IconData _getWidgetIcon(String key) {
    final icons = {
      'revenue_metrics': Icons.euro,
      'active_jobs': Icons.work,
      'applications': Icons.person_add,
      'team_overview': Icons.groups,
      'live_stats': Icons.speed,
      'analytics_chart': Icons.analytics,
      'quick_actions': Icons.flash_on,
      'recent_activity': Icons.history,
    };
    return icons[key] ?? Icons.widgets;
  }
}

/// Dashboard configuration model
class DashboardConfig {
  final Map<String, bool> widgetVisibility;
  final String layout;
  final String density;
  final String accentColor;
  final bool useHighContrast;
  final int refreshInterval;
  final bool autoRefresh;
  
  DashboardConfig({
    required this.widgetVisibility,
    required this.layout,
    required this.density,
    required this.accentColor,
    required this.useHighContrast,
    required this.refreshInterval,
    required this.autoRefresh,
  });
  
  factory DashboardConfig.defaultConfig() {
    return DashboardConfig(
      widgetVisibility: {
        'revenue_metrics': true,
        'active_jobs': true,
        'applications': true,
        'team_overview': true,
        'live_stats': true,
        'analytics_chart': true,
        'quick_actions': true,
        'recent_activity': true,
      },
      layout: 'grid',
      density: 'comfortable',
      accentColor: 'blue',
      useHighContrast: false,
      refreshInterval: 30,
      autoRefresh: true,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'widgetVisibility': widgetVisibility,
    'layout': layout,
    'density': density,
    'accentColor': accentColor,
    'useHighContrast': useHighContrast,
    'refreshInterval': refreshInterval,
    'autoRefresh': autoRefresh,
  };
  
  factory DashboardConfig.fromJson(Map<String, dynamic> json) => DashboardConfig(
    widgetVisibility: Map<String, bool>.from(json['widgetVisibility']),
    layout: json['layout'],
    density: json['density'],
    accentColor: json['accentColor'],
    useHighContrast: json['useHighContrast'],
    refreshInterval: json['refreshInterval'],
    autoRefresh: json['autoRefresh'],
  );
}