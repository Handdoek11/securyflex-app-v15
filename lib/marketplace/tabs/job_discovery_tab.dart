import 'dart:async';
import 'dart:ui' as ui;
import 'package:securyflex_app/marketplace/calendar_popup_view.dart';
import 'package:securyflex_app/marketplace/job_list_view.dart';
import 'package:securyflex_app/marketplace/widgets/jobs_section_title.dart';
import 'package:securyflex_app/marketplace/widgets/job_card_with_images.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/state/job_state_manager.dart';
import 'package:securyflex_app/marketplace/services/favorites_service.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/company_dashboard/services/premium_job_image_service.dart';
import 'package:securyflex_app/company_dashboard/models/job_image_data.dart' as img_data;
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
// BeveiligerDashboardTheme import removed - using unified design tokens
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../job_filters_screen.dart';
import '../job_details_screen.dart';
import '../../routing/app_routes.dart';

/// Job Discovery Tab Component
/// Extracted from JobsHomeScreen to be used in TabBarView
/// Maintains all existing functionality: search, filters, job listings
/// Follows SecuryFlex unified design system and Dutch localization
class JobDiscoveryTab extends StatefulWidget {
  const JobDiscoveryTab({super.key, required this.animationController});

  final AnimationController animationController;

  @override
  State<JobDiscoveryTab> createState() => _JobDiscoveryTabState();
}

class _JobDiscoveryTabState extends State<JobDiscoveryTab> {
  Animation<double>? topBarAnimation;

  // Following template pattern: use state manager for data
  List<SecurityJobData> jobList = JobStateManager.filteredJobs;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService();
  final ApplicationService _applicationService = ApplicationService();
  final PremiumJobImageService _imageService = PremiumJobImageService.instance;
  Timer? _searchDebounce;
  bool isSearching = false;
  bool isLoading = false;
  String? errorMessage;
  Map<String, List<img_data.JobImageData>> _jobImages = {};
  Set<String> _appliedJobs = {};

  // Add scroll opacity for animated header (matching Dashboard/Planning pattern)
  double topBarOpacity = 0.0;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    _loadJobImages();
    _loadApplicationStatus();
    super.initState();

    // Initialize favorites service
    _favoritesService.initialize();

    // Add top bar animation (matching Dashboard/Planning pattern)
    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    // Add scroll listener for header opacity animation
    _scrollController.addListener(() {
      if (_scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() {
            topBarOpacity = 1.0;
          });
        }
      } else if (_scrollController.offset <= 24 &&
          _scrollController.offset >= 0) {
        if (topBarOpacity != _scrollController.offset / 24) {
          setState(() {
            topBarOpacity = _scrollController.offset / 24;
          });
        }
      } else if (_scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() {
            topBarOpacity = 0.0;
          });
        }
      }
    });

    searchController.addListener(_onSearchChanged);

    // Initialize comprehensive mock data for realistic job display
    _initializeMockJobData();
  }

  /// Initialize comprehensive Dutch security job mock data
  Future<void> _initializeMockJobData() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Initialize mock data through JobStateManager
      await JobStateManager.initializeDemoData();
      
      // Update UI state with loaded jobs - safety check
      if (mounted) {
        setState(() {
          jobList = JobStateManager.filteredJobs;
          isLoading = false;
        });

        // Debug output for development
        debugPrint('JobDiscoveryTab: Loaded ${jobList.length} Nederlandse beveiligingsjobs');
        debugPrint('JobDiscoveryTab: Job types available: ${JobStateManager.getAvailableJobTypes()}');

        // Forward animation for job cards - safety check
        if (widget.animationController.isAnimating == false) {
          widget.animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Fout bij laden van Nederlandse beveiligingsjobs: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  void _onSearchChanged() {
    if (!mounted) return; // Safety check
    
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) { // Safety check before performing search
        _performSearch(searchController.text);
      }
    });
  }

  void _performSearch(String query) {
    if (!mounted) return; // Safety check
    
    // Following template pattern: update state manager and refresh UI
    JobStateManager.updateSearchQuery(query);
    if (mounted) {
      setState(() {
        jobList = JobStateManager.filteredJobs;
        isSearching = query.isNotEmpty;
      });
    }
  }

  Future<void> _loadJobImages() async {
    // Load images for visible jobs
    for (final job in jobList.take(10)) {
      try {
        final images = await _imageService.getJobImages(job.id);
        if (mounted) {
          setState(() {
            _jobImages[job.id] = images;
          });
        }
      } catch (e) {
        // Continue loading other images even if one fails
        debugPrint('Failed to load images for job ${job.id}: $e');
      }
    }
  }
  
  Future<void> _loadApplicationStatus() async {
    try {
      final applications = await ApplicationService.getUserApplications();
      if (mounted) {
        setState(() {
          _appliedJobs = applications.map((app) => app.jobId).toSet();
        });
      }
    } catch (e) {
      debugPrint('Failed to load application status: $e');
    }
  }
  
  @override
  void dispose() {
    // Cancel all async operations first
    _searchDebounce?.cancel();
    _searchDebounce = null;
    
    // Dispose controllers
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _scrollController.dispose();
    
    // FavoritesService is a singleton - no disposal needed
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Theme(
        data: SecuryFlexTheme.getTheme(UserRole.guard),
        child: InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        return Column(
                          children: <Widget>[getSearchBarUI(), getTimeDateUI()],
                        );
                      }, childCount: 1),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      floating: true,
                      delegate: ContestTabHeader(getFilterBarUI()),
                    ),
                  ];
                },
            body: errorMessage != null
                  ? _buildErrorState()
                  : isLoading
                  ? _buildLoadingState()
                  : jobList.isEmpty && isSearching
                  ? _buildEmptyResults()
                  : ListView.builder(
                      itemCount: jobList.length + 1, // +1 for section title
                      padding: const EdgeInsets.only(top: 8),
                      scrollDirection: Axis.vertical,
                      itemBuilder: (BuildContext context, int index) {
                        // First item is the section title
                        if (index == 0) {
                          final titleAnimation =
                              Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: widget.animationController,
                                  curve: const Interval(
                                    0.0,
                                    0.2,
                                    curve: Curves.fastOutSlowIn,
                                  ),
                                ),
                              );

                          widget.animationController.forward();

                          return JobsSectionTitle(
                            title: 'Jobs',
                            subtitle: isSearching
                                ? 'Zoekresultaten'
                                : 'Vind je volgende opdracht',
                            jobCount: jobList.length,
                            isSearching: isSearching,
                            animationController: widget.animationController,
                            animation: titleAnimation,
                          );
                        }

                        // Adjust index for job items
                        final jobIndex = index - 1;

                        // Dashboard-style staggered animation with optimized count
                        final int count = jobList.length > 8
                            ? 8
                            : jobList.length;
                        final Animation<double>
                        animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: widget.animationController,
                            curve: Interval(
                              0.2 +
                                  (0.8 / count) *
                                      (jobIndex %
                                          count), // Start after title animation
                              1.0,
                              curve: Curves.fastOutSlowIn,
                            ),
                          ),
                        );

                        final job = jobList[jobIndex];
                        final jobImages = _jobImages[job.id] ?? [];
                        final hasApplied = _appliedJobs.contains(job.id);
                        
                        return FadeTransition(
                          opacity: animation,
                          child: Transform(
                            transform: Matrix4.translationValues(
                              0.0, 50 * (1.0 - animation.value), 0.0),
                            child: JobCardWithImages.discovery(
                              job: job,
                              images: jobImages,
                              userCertificates: ['WPBR', 'VCA'], // TODO: Get from user profile
                              hasApplied: hasApplied,
                              onTap: () {
                                context.go('${AppRoutes.beveiligerJobs}/${job.id}');
                              },
                              onApplyPressed: () async {
                                // Handle application
                                await ApplicationService.submitApplication(
                                  jobId: job.id,
                                  jobTitle: job.jobTitle.isNotEmpty ? job.jobTitle : job.titleTxt,
                                  companyName: job.companyName.isNotEmpty ? job.companyName : job.subTxt.split(',').first,
                                  isAvailable: true,
                                  motivationMessage: 'Ik ben zeer geïnteresseerd in deze positie',
                                  contactPreference: 'email',
                                );
                                setState(() {
                                  _appliedJobs.add(job.id);
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sollicitatie verstuurd!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              onFavoriteToggle: () async {
                                await _favoritesService.toggleFavorite(job.id);
                                setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
    );
  }

  Widget getTimeDateUI() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.spacingL,
        bottom: DesignTokens.spacingM,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      showDemoDialog(context: context);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXS,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Kies datum',
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightRegular,
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                          SizedBox(height: DesignTokens.spacingS),
                          Text(
                            '${DateFormat("dd, MMM", "nl_NL").format(startDate)} - ${DateFormat("dd, MMM", "nl_NL").format(endDate)}',
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightMedium,
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.onSurface,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: DesignTokens.spacingS),
            child: Container(
              width: 1,
              height: 42,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingS,
                        vertical: DesignTokens.spacingXS,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Type',
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightRegular,
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                          SizedBox(height: DesignTokens.spacingS),
                          Text(
                            'Alle jobs',
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightMedium,
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.onSurface,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget getSearchBarUI() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingS,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: DesignTokens.spacingM,
                top: DesignTokens.spacingS,
                bottom: DesignTokens.spacingS,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.1),  // Zeer subtiele achtergrond voor contrast
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),  // Subtle border
                  ),
                  boxShadow: [DesignTokens.shadowMedium],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingM,
                    vertical: DesignTokens.spacingXS,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: (String txt) {
                      // Search is handled by the listener, but trigger rebuild for clear button
                      setState(() {});
                    },
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBodyLarge,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                    cursorColor: colorScheme.primary,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Zoek jobs, bedrijf, locatie...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: DesignTokens.fontSizeBodyLarge,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              onPressed: () {
                                searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
              boxShadow: [DesignTokens.shadowMedium],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.spacingM),
                  child: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 20,
                    color: colorScheme.surface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget getFilterBarUI() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    // Gebruik gradient kleuren die matchen met de achtergrond
    final backgroundColor = topBarOpacity > 0
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C5CE7).withValues(alpha: 0.15 * topBarOpacity),
              const Color(0xFFA29BFE).withValues(alpha: 0.15 * topBarOpacity),
            ],
          )
        : null;
    
    final showBlur = topBarOpacity > 0;

    return Stack(
      children: <Widget>[
        if (showBlur)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 10.0 * topBarOpacity,
                  sigmaY: 10.0 * topBarOpacity,
                ),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        Container(
          decoration: backgroundColor != null
              ? BoxDecoration(gradient: backgroundColor)
              : null,  // Dynamische gradient achtergrond
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(DesignTokens.spacingS),
                    child: Text(
                      isSearching
                          ? '${jobList.length} jobs gevonden'
                          : '${jobList.length} beschikbare jobs',
                      style: TextStyle(
                        fontWeight: DesignTokens.fontWeightRegular,
                        fontSize: DesignTokens.fontSizeBody,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    splashColor: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    onTap: () async {
                      FocusScope.of(context).requestFocus(FocusNode());
                      // Following template pattern: await navigation and refresh data
                      await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (BuildContext context) => JobFiltersScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                      // Refresh data after returning from filters
                      setState(() {
                        jobList = JobStateManager.filteredJobs;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: DesignTokens.spacingS),
                      child: Row(
                        children: <Widget>[
                          Text(
                            'Filters',
                            style: TextStyle(
                              fontWeight: DesignTokens.fontWeightMedium,
                              fontSize: DesignTokens.fontSizeBody,
                              color: colorScheme.primary,
                              fontFamily: DesignTokens.fontFamily,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(DesignTokens.spacingS),
                            child: Icon(
                              Icons.sort,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: Divider(height: 1)),
      ],
    );
  }

  void showDemoDialog({BuildContext? context}) {
    showDialog<dynamic>(
      context: context!,
      builder: (BuildContext context) => CalendarPopupView(
        barrierDismissible: true,
        minimumDate: DateTime.now(),
        initialEndDate: endDate,
        initialStartDate: startDate,
        onApplyClick: (DateTime startData, DateTime endData) {
          setState(() {
            startDate = startData;
            endDate = endData;
          });
        },
        onCancelClick: () {},
      ),
    );
  }

  Widget _buildEmptyResults() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    // Following template pattern: centered empty state with icon and text
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Template-style empty state icon
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              color: DesignTokens.colorGray100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 48, color: DesignTokens.colorGray400),
          ),
          const SizedBox(height: 24),
          // Template-style title text
          Text(
            'Geen opdrachten gevonden',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.colorGray700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Template-style subtitle text
          Text(
            'Probeer een andere zoekterm of pas je filters aan',
            style: TextStyle(
              color: DesignTokens.colorGray500,
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamily,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Template-style action button
          if (searchController.text.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  searchController.clear();
                  _performSearch('');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: DesignTokens.colorWhite,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Wis zoekopdracht',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    // Following template pattern: centered loading indicator
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Jobs laden...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.colorGray600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    // Following template pattern: centered error state with retry option
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingXXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Template-style error icon
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              color: DesignTokens.statusCancelled.withValues(alpha: 0.50),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48, color: DesignTokens.statusCancelled.withValues(alpha: 0.400)),
          ),
          const SizedBox(height: 24),
          // Template-style error title
          Text(
            'Er is iets misgegaan',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
              color: DesignTokens.colorGray700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Template-style error message
          Text(
            errorMessage ?? 'Probeer het opnieuw',
            style: TextStyle(
              color: DesignTokens.colorGray500,
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: DesignTokens.fontFamily,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Template-style retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _retryLoadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: DesignTokens.colorWhite,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Probeer opnieuw',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _retryLoadData() {
    if (!mounted) return;
    
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    // Retry loading comprehensive mock data
    _initializeMockJobData();
  }
}

class ContestTabHeader extends SliverPersistentHeaderDelegate {
  ContestTabHeader(this.searchUI);
  final Widget searchUI;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return searchUI;
  }

  @override
  double get maxExtent => 56.0; // Slightly increased for better touch targets

  @override
  double get minExtent => 56.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
