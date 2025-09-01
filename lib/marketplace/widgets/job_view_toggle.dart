import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/premium_glass_system.dart';
import '../services/filter_persistence_service.dart';
import '../bloc/job_state.dart'; // Import for JobFilter

/// Professional job view toggle component with glassmorphic design
/// Supports Card, List, and Compact view types with smooth transitions
/// Persists user preference across app sessions
class JobViewToggle extends StatefulWidget {
  final JobViewType currentView;
  final ValueChanged<JobViewType> onViewChanged;
  final UserRole userRole;
  final bool showLabels;
  
  const JobViewToggle({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    this.userRole = UserRole.guard,
    this.showLabels = false,
  });
  
  @override
  State<JobViewToggle> createState() => _JobViewToggleState();
}

class _JobViewToggleState extends State<JobViewToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  JobViewType? _pendingViewType;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleViewChange(JobViewType newViewType) async {
    if (newViewType == widget.currentView) return;
    
    setState(() {
      _pendingViewType = newViewType;
    });
    
    // Scale animation for feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Save preference
    await FilterPersistenceService.instance.saveViewPreference(newViewType);
    
    // Notify parent with slight delay for smooth animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        widget.onViewChanged(newViewType);
        setState(() {
          _pendingViewType = null;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: PremiumGlassContainer(
            intensity: GlassIntensity.subtle,
            elevation: GlassElevation.floating,
            tintColor: colorScheme.surface,
            enableTrustBorder: true,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
            padding: const EdgeInsets.all(DesignTokens.spacingXS),
            child: widget.showLabels
                ? _buildLabeledToggle(colorScheme)
                : _buildCompactToggle(colorScheme),
          ),
        );
      },
    );
  }
  
  Widget _buildCompactToggle(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: JobViewType.values.map((viewType) {
        final isSelected = viewType == widget.currentView;
        final isPending = _pendingViewType == viewType;
        
        return _buildToggleButton(
          viewType: viewType,
          isSelected: isSelected,
          isPending: isPending,
          colorScheme: colorScheme,
          showLabel: false,
        );
      }).toList(),
    );
  }
  
  Widget _buildLabeledToggle(ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Weergave',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: JobViewType.values.map((viewType) {
            final isSelected = viewType == widget.currentView;
            final isPending = _pendingViewType == viewType;
            
            return _buildToggleButton(
              viewType: viewType,
              isSelected: isSelected,
              isPending: isPending,
              colorScheme: colorScheme,
              showLabel: true,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildToggleButton({
    required JobViewType viewType,
    required bool isSelected,
    required bool isPending,
    required ColorScheme colorScheme,
    required bool showLabel,
  }) {
    final buttonColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
    
    final backgroundColor = isSelected
        ? colorScheme.primary.withValues(alpha: 0.1)
        : Colors.transparent;
    
    Widget buttonContent = Container(
      padding: EdgeInsets.all(showLabel ? DesignTokens.spacingS : DesignTokens.spacingXS),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: isSelected ? Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ) : null,
      ),
      child: showLabel
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  viewType.icon,
                  color: buttonColor,
                  size: DesignTokens.iconSizeM,
                ),
                const SizedBox(height: DesignTokens.spacingXS),
                Text(
                  viewType.displayName,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: isSelected 
                        ? DesignTokens.fontWeightSemiBold 
                        : DesignTokens.fontWeightRegular,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: buttonColor,
                  ),
                ),
              ],
            )
          : Icon(
              viewType.icon,
              color: buttonColor,
              size: DesignTokens.iconSizeM,
            ),
    );
    
    // Add loading indicator if pending
    if (isPending) {
      buttonContent = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0.5, child: buttonContent),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      );
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXS / 2,
      ),
      child: InkWell(
        onTap: isPending ? null : () => _handleViewChange(viewType),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Tooltip(
          message: showLabel ? '' : '${viewType.displayName} weergave',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: buttonContent,
          ),
        ),
      ),
    );
  }
}

/// Saved search dropdown component for quick filter access
class SavedSearchDropdown extends StatefulWidget {
  final ValueChanged<JobFilter> onSearchSelected;
  final VoidCallback onManageSearches;
  final UserRole userRole;
  
  const SavedSearchDropdown({
    super.key,
    required this.onSearchSelected,
    required this.onManageSearches,
    this.userRole = UserRole.guard,
  });
  
  @override
  State<SavedSearchDropdown> createState() => _SavedSearchDropdownState();
}

class _SavedSearchDropdownState extends State<SavedSearchDropdown> {
  List<SavedJobSearch> _savedSearches = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
  }
  
  Future<void> _loadSavedSearches() async {
    setState(() => _isLoading = true);
    
    try {
      final searches = await FilterPersistenceService.instance.getSavedSearches();
      if (mounted) {
        setState(() {
          _savedSearches = searches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (_savedSearches.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return PopupMenuButton<SavedJobSearch>(
      icon: Icon(
        Icons.bookmark,
        color: colorScheme.primary,
        size: DesignTokens.iconSizeM,
      ),
      tooltip: 'Opgeslagen zoekopdrachten',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      itemBuilder: (context) => [
        for (final search in _savedSearches) PopupMenuItem<SavedJobSearch>(
          value: search,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                search.name,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontSize: DesignTokens.fontSizeBody,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingXS),
              Text(
                search.description,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightRegular,
                  fontSize: DesignTokens.fontSizeCaption,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<SavedJobSearch>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.settings, size: DesignTokens.iconSizeS),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Beheer zoekopdrachten',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontSize: DesignTokens.fontSizeBody,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (search) {
        if (search != null) {
          widget.onSearchSelected(search.filters);
        } else {
          widget.onManageSearches();
        }
      },
    );
  }
}

/// Filter history dropdown for quick access to recent filter combinations
class FilterHistoryDropdown extends StatefulWidget {
  final ValueChanged<JobFilter> onHistorySelected;
  final UserRole userRole;
  
  const FilterHistoryDropdown({
    super.key,
    required this.onHistorySelected,
    this.userRole = UserRole.guard,
  });
  
  @override
  State<FilterHistoryDropdown> createState() => _FilterHistoryDropdownState();
}

class _FilterHistoryDropdownState extends State<FilterHistoryDropdown> {
  List<FilterHistoryItem> _history = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final history = await FilterPersistenceService.instance.getFilterHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(widget.userRole);
    
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    
    if (_history.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return PopupMenuButton<FilterHistoryItem>(
      icon: Icon(
        Icons.history,
        color: colorScheme.onSurfaceVariant,
        size: DesignTokens.iconSizeM,
      ),
      tooltip: 'Recente filters',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      itemBuilder: (context) => _history.map((item) => PopupMenuItem<FilterHistoryItem>(
        value: item,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.summary,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                fontSize: DesignTokens.fontSizeBody,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignTokens.spacingXS),
            Text(
              item.relativeTime,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightRegular,
                fontSize: DesignTokens.fontSizeCaption,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      )).toList(),
      onSelected: (item) {
        widget.onHistorySelected(item.filters);
      },
    );
  }
}