import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_buttons.dart';
import '../../unified_card_system.dart';
import '../../unified_theme_system.dart';
import '../services/favorites_service.dart';
import '../model/security_job_data.dart';
import '../widgets/job_card.dart';
import '../models/enhanced_job_models.dart';

/// FavoritesList widget met categorisatie en Nederlandse localisatie
/// 
/// Comprehensive favorites management with categorization, filtering,
/// notification settings, and real-time updates. Provides enhanced
/// job organization and discovery capabilities.
class FavoritesList extends StatefulWidget {
  final UserRole userRole;
  final List<String>? userCertificates;
  final String? userPostcode;
  final FavoriteCategory? categoryFilter;
  final bool showCategoryFilters;
  final bool showNotificationSettings;
  final bool isCompactMode;
  final VoidCallback? onJobTapped;
  final VoidCallback? onFavoritesChanged;
  
  const FavoritesList({
    super.key,
    this.userRole = UserRole.guard,
    this.userCertificates,
    this.userPostcode,
    this.categoryFilter,
    this.showCategoryFilters = true,
    this.showNotificationSettings = false,
    this.isCompactMode = false,
    this.onJobTapped,
    this.onFavoritesChanged,
  });
  
  @override
  State<FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<FavoritesList>
    with SingleTickerProviderStateMixin {
  
  late final TabController _tabController;
  FavoriteCategory _selectedCategory = FavoriteCategory.general;
  String _sortBy = 'dateAdded';
  bool _sortAscending = false;
  
  final List<FavoriteCategory> _categories = [
    FavoriteCategory.general,
    FavoriteCategory.urgent,
    FavoriteCategory.highPay,
    FavoriteCategory.nearLocation,
    FavoriteCategory.preferredCompany,
    FavoriteCategory.goodMatch,
    FavoriteCategory.toApplyLater,
  ];
  
  final List<String> _sortOptions = [
    'dateAdded',
    'salary',
    'distance',
    'companyRating',
    'startDate',
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categoryFilter ?? FavoriteCategory.general;
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: _categories.indexOf(_selectedCategory),
    );
    
    _tabController.addListener(_onTabChanged);
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = _categories[_tabController.index];
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return UnifiedCard.standard(
      userRole: widget.userRole,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Category filters
          if (widget.showCategoryFilters && widget.categoryFilter == null)
            _buildCategoryTabs(),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Sort and filter controls
          _buildControlsBar(),
          
          SizedBox(height: DesignTokens.spacingM),
          
          // Favorites list
          Expanded(
            child: _buildFavoritesList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.favorite,
          color: _getThemeColors().primary,
          size: DesignTokens.iconSizeL,
        ),
        SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favoriete Opdrachten',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: _getThemeColors().onSurface,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: FavoritesService().favoriteJobIds,
                builder: (context, favoriteIds, child) {
                  return Text(
                    '${favoriteIds.length} favoriete opdrachten',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeMeta,
                      color: _getThemeColors().onSurfaceVariant,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Actions menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: _getThemeColors().onSurfaceVariant,
          ),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clearAll',
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: DesignTokens.colorError),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Alle favorieten wissen'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'exportList',
              child: Row(
                children: [
                  Icon(Icons.share, color: _getThemeColors().onSurface),
                  SizedBox(width: DesignTokens.spacingS),
                  Text('Lijst delen'),
                ],
              ),
            ),
            if (widget.showNotificationSettings)
              PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications, color: _getThemeColors().onSurface),
                    SizedBox(width: DesignTokens.spacingS),
                    Text('Meldingen instellen'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 36,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _getThemeColors().primary,
        unselectedLabelColor: _getThemeColors().onSurfaceVariant,
        indicatorColor: _getThemeColors().primary,
        labelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightRegular,
        ),
        tabs: _categories.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getCategoryIcon(category),
                  size: DesignTokens.iconSizeS,
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Text(_getCategoryDisplayName(category)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildControlsBar() {
    return Row(
      children: [
        // Sort dropdown
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(color: _getThemeColors().outline),
              borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value ?? 'dateAdded';
                  });
                },
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(_getSortDisplayName(option)),
                  );
                }).toList(),
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: _getThemeColors().onSurface,
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(width: DesignTokens.spacingS),
        
        // Sort direction button
        UnifiedButton.icon(
          icon: _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
          onPressed: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
          },
          color: _getThemeColors().onSurfaceVariant,
        ),
        
        SizedBox(width: DesignTokens.spacingS),
        
        // View mode toggle
        UnifiedButton.icon(
          icon: widget.isCompactMode ? Icons.view_list : Icons.view_module,
          onPressed: () {
            // This would typically update parent state
            widget.onFavoritesChanged?.call();
          },
          color: _getThemeColors().onSurfaceVariant,
        ),
      ],
    );
  }
  
  Widget _buildFavoritesList() {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoritesService().favoriteJobIds,
      builder: (context, favoriteIds, child) {
        final favoriteJobs = _getFavoriteJobs(favoriteIds);
        final filteredJobs = _filterJobsByCategory(favoriteJobs);
        final sortedJobs = _sortJobs(filteredJobs);
        
        if (sortedJobs.isEmpty) {
          return _buildEmptyState();
        }
        
        if (widget.isCompactMode) {
          return ListView.separated(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            itemCount: sortedJobs.length,
            separatorBuilder: (context, index) => 
                SizedBox(height: DesignTokens.spacingS),
            itemBuilder: (context, index) {
              return _buildCompactJobItem(sortedJobs[index]);
            },
          );
        } else {
          return GridView.builder(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: DesignTokens.spacingS,
              mainAxisSpacing: DesignTokens.spacingS,
              childAspectRatio: 0.85,
            ),
            itemCount: sortedJobs.length,
            itemBuilder: (context, index) {
              return JobCard(
                job: sortedJobs[index],
                userRole: widget.userRole,
                userCertificates: widget.userCertificates,
                userPostcode: widget.userPostcode,
                isCompact: true,
                onTap: widget.onJobTapped,
                onFavoriteToggled: widget.onFavoritesChanged,
              );
            },
          );
        }
      },
    );
  }
  
  Widget _buildCompactJobItem(SecurityJobData job) {
    return UnifiedCard.compact(
      isClickable: true,
      onTap: widget.onJobTapped,
      userRole: widget.userRole,
      child: Row(
        children: [
          // Job info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.jobTitle,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBodyLarge,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: _getThemeColors().onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  job.companyName,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: _getThemeColors().onSurfaceVariant,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.euro,
                      size: DesignTokens.iconSizeS,
                      color: DesignTokens.colorSuccess,
                    ),
                    Text(
                      '€${job.hourlyRate.toStringAsFixed(2)}/uur',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: DesignTokens.colorSuccess,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Column(
            children: [
              // Favorite button
              UnifiedButton.icon(
                icon: Icons.favorite,
                onPressed: () {
                  FavoritesService().removeFromFavorites(job.jobId);
                  widget.onFavoritesChanged?.call();
                },
                color: DesignTokens.colorError,
              ),
              
              SizedBox(height: DesignTokens.spacingS),
              
              // Category badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXXS,
                ),
                decoration: BoxDecoration(
                  color: _getThemeColors().primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Icon(
                  _getCategoryIcon(_selectedCategory),
                  size: DesignTokens.iconSizeS,
                  color: _getThemeColors().primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(_selectedCategory),
            size: 64,
            color: _getThemeColors().surfaceContainerHighest,
          ),
          SizedBox(height: DesignTokens.spacingL),
          Text(
            _getEmptyStateMessage(_selectedCategory),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBodyLarge,
              color: _getThemeColors().onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedButton.secondary(
            text: 'Opdrachten zoeken',
            onPressed: () {
              // Navigate to job search
              widget.onJobTapped?.call();
            },
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  List<SecurityJobData> _getFavoriteJobs(Set<String> favoriteIds) {
    return SecurityJobData.jobList
        .where((job) => favoriteIds.contains(job.jobId))
        .toList();
  }
  
  List<SecurityJobData> _filterJobsByCategory(List<SecurityJobData> jobs) {
    // For demo purposes, we'll use simple logic
    // In a real app, jobs would have associated categories
    switch (_selectedCategory) {
      case FavoriteCategory.highPay:
        return jobs.where((job) => job.hourlyRate >= 25.0).toList();
      case FavoriteCategory.urgent:
        return jobs.where((job) => job.startDate != null && 
            job.startDate!.difference(DateTime.now()).inDays <= 3).toList();
      case FavoriteCategory.nearLocation:
        return jobs.where((job) => job.distance <= 10.0).toList();
      default:
        return jobs;
    }
  }
  
  List<SecurityJobData> _sortJobs(List<SecurityJobData> jobs) {
    final sortedJobs = List<SecurityJobData>.from(jobs);
    
    sortedJobs.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'salary':
          comparison = a.hourlyRate.compareTo(b.hourlyRate);
          break;
        case 'distance':
          comparison = a.distance.compareTo(b.distance);
          break;
        case 'companyRating':
          comparison = a.companyRating.compareTo(b.companyRating);
          break;
        case 'startDate':
          final dateA = a.startDate ?? DateTime(2099);
          final dateB = b.startDate ?? DateTime(2099);
          comparison = dateA.compareTo(dateB);
          break;
        case 'dateAdded':
        default:
          // For demo, sort by job ID as proxy for date added
          comparison = a.jobId.compareTo(b.jobId);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return sortedJobs;
  }
  
  String _getCategoryDisplayName(FavoriteCategory category) {
    switch (category) {
      case FavoriteCategory.general:
        return 'Alle';
      case FavoriteCategory.urgent:
        return 'Spoedeisend';
      case FavoriteCategory.highPay:
        return 'Goed betaald';
      case FavoriteCategory.nearLocation:
        return 'Dichtbij';
      case FavoriteCategory.preferredCompany:
        return 'Favoriete werkgever';
      case FavoriteCategory.goodMatch:
        return 'Goede match';
      case FavoriteCategory.toApplyLater:
        return 'Later solliciteren';
    }
  }
  
  IconData _getCategoryIcon(FavoriteCategory category) {
    switch (category) {
      case FavoriteCategory.general:
        return Icons.favorite;
      case FavoriteCategory.urgent:
        return Icons.priority_high;
      case FavoriteCategory.highPay:
        return Icons.euro;
      case FavoriteCategory.nearLocation:
        return Icons.location_on;
      case FavoriteCategory.preferredCompany:
        return Icons.business;
      case FavoriteCategory.goodMatch:
        return Icons.verified;
      case FavoriteCategory.toApplyLater:
        return Icons.schedule;
    }
  }
  
  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'dateAdded':
        return 'Datum toegevoegd';
      case 'salary':
        return 'Salaris';
      case 'distance':
        return 'Afstand';
      case 'companyRating':
        return 'Bedrijfsbeoordeling';
      case 'startDate':
        return 'Startdatum';
      default:
        return sortBy;
    }
  }
  
  String _getEmptyStateMessage(FavoriteCategory category) {
    switch (category) {
      case FavoriteCategory.general:
        return 'Geen favoriete opdrachten.\nVoeg opdrachten toe door op het hart-icoon te tikken.';
      case FavoriteCategory.urgent:
        return 'Geen spoedeisende favorieten';
      case FavoriteCategory.highPay:
        return 'Geen goed betaalde favorieten';
      case FavoriteCategory.nearLocation:
        return 'Geen favorieten in de buurt';
      case FavoriteCategory.preferredCompany:
        return 'Geen favorieten van jouw favoriete werkgevers';
      case FavoriteCategory.goodMatch:
        return 'Geen favorieten die goed bij je passen';
      case FavoriteCategory.toApplyLater:
        return 'Geen opdrachten om later op te solliciteren';
    }
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'clearAll':
        _showClearAllDialog();
        break;
      case 'exportList':
        _exportFavoritesList();
        break;
      case 'notifications':
        _showNotificationSettings();
        break;
    }
  }
  
  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alle favorieten wissen'),
        content: Text('Weet je zeker dat je alle favoriete opdrachten wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuleren'),
          ),
          UnifiedButton.primary(
            text: 'Wissen',
            onPressed: () {
              Navigator.pop(context);
              FavoritesService().clearFavorites();
              widget.onFavoritesChanged?.call();
            },
          ),
        ],
      ),
    );
  }
  
  void _exportFavoritesList() {
    // In a real app, this would export the favorites list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Favorieten lijst geëxporteerd'),
        backgroundColor: DesignTokens.colorSuccess,
      ),
    );
  }
  
  void _showNotificationSettings() {
    // In a real app, this would show notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Meldingen instellingen geopend'),
        backgroundColor: DesignTokens.colorInfo,
      ),
    );
  }
  
  ColorScheme _getThemeColors() {
    return SecuryFlexTheme.getColorScheme(widget.userRole);
  }
}