import 'dart:async';
import 'package:securyflex_app/marketplace/calendar_popup_view.dart';
import 'package:securyflex_app/marketplace/job_list_view.dart';
import 'package:securyflex_app/marketplace/widgets/jobs_section_title.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/marketplace/state/job_state_manager.dart';
import 'package:securyflex_app/marketplace/services/favorites_service.dart';
import 'package:securyflex_app/marketplace/screens/favorites_screen.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_buttons.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'job_filters_screen.dart';

class JobsHomeScreen extends StatefulWidget {
  const JobsHomeScreen({super.key});

  @override
  State<JobsHomeScreen> createState() => _JobsHomeScreenState();
}

class _JobsHomeScreenState extends State<JobsHomeScreen>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  Animation<double>? topBarAnimation;

  // Following template pattern: use state manager for data
  List<SecurityJobData> jobList = JobStateManager.filteredJobs;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService();
  Timer? _searchDebounce;
  bool isSearching = false;
  bool isLoading = false;
  String? errorMessage;

  // Add scroll opacity for animated header (matching Dashboard/Planning pattern)
  double topBarOpacity = 0.0;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize favorites service
    _favoritesService.initialize();

    // Add top bar animation (matching Dashboard/Planning pattern)
    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    // Performance optimized scroll listener
    _scrollController.addListener(_onScroll);

    searchController.addListener(_onSearchChanged);

    // Load initial job data
    _loadInitialData();

    super.initState();
  }

  /// Load initial job data from Firestore
  void _loadInitialData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await JobStateManager.loadJobs();
      if (mounted) {
        setState(() {
          isLoading = false;
          jobList = JobStateManager.filteredJobs;
          errorMessage = JobStateManager.errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Fout bij laden van jobs: $e';
        });
      }
    }
  }

  Future<bool> getData() async {
    await Future<dynamic>.delayed(const Duration(milliseconds: 200));
    return true;
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(searchController.text);
    });
  }

  void _performSearch(String query) {
    // Following template pattern: update state manager and refresh UI
    JobStateManager.updateSearchQuery(query);
    setState(() {
      jobList = JobStateManager.filteredJobs;
      isSearching = query.isNotEmpty;
    });
  }

  // Performance optimization: Throttled scroll listener
  void _onScroll() {
    final offset = _scrollController.offset;
    double newOpacity;

    if (offset >= 24) {
      newOpacity = 1.0;
    } else if (offset <= 0) {
      newOpacity = 0.0;
    } else {
      newOpacity = offset / 24;
    }

    // Only setState if opacity actually changed (reduces rebuilds)
    if ((newOpacity - topBarOpacity).abs() > 0.01) {
      setState(() {
        topBarOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    animationController?.dispose();
    _scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return Container(
      color: DesignTokens.guardSurface, // ✅ Consistent met andere screens
      child: Theme(
        data: SecuryFlexTheme.getTheme(UserRole.guard),
        child: Scaffold(
          backgroundColor:
              Colors.transparent, // ✅ Transparant voor Container kleur
          body: Stack(
            children: <Widget>[
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                child: Column(
                  children: <Widget>[
                    getAppBarUI(),
                    Expanded(
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
                                      children: <Widget>[
                                        getSearchBarUI(),
                                        getTimeDateUI(),
                                      ],
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
                        body: Container(
                          color: DesignTokens
                              .guardSurface, // ✅ Consistent achtergrond
                          child: errorMessage != null
                              ? _buildErrorState()
                              : isLoading
                              ? _buildLoadingState()
                              : jobList.isEmpty && isSearching
                              ? _buildEmptyResults()
                              : ListView.builder(
                                  itemCount:
                                      jobList.length +
                                      1, // +1 for section title
                                  padding: EdgeInsets.only(top: DesignTokens.spacingS),
                                  scrollDirection: Axis.vertical,
                                  itemBuilder: (BuildContext context, int index) {
                                    // First item is the section title
                                    if (index == 0) {
                                      final titleAnimation =
                                          Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animationController!,
                                              curve: const Interval(
                                                0.0,
                                                0.2,
                                                curve: Curves.fastOutSlowIn,
                                              ),
                                            ),
                                          );

                                      animationController?.forward();

                                      return JobsSectionTitle(
                                        title: 'Beschikbare Jobs',
                                        subtitle: isSearching
                                            ? 'Zoekresultaten'
                                            : 'Vind je volgende opdracht',
                                        jobCount: jobList.length,
                                        isSearching: isSearching,
                                        animationController:
                                            animationController,
                                        animation: titleAnimation,
                                      );
                                    }

                                    // Adjust index for job items
                                    final jobIndex = index - 1;

                                    // Dashboard-style staggered animation with optimized count
                                    final int count = jobList.length > 8
                                        ? 8
                                        : jobList.length;
                                    final Animation<double> animation =
                                        Tween<double>(
                                          begin: 0.0,
                                          end: 1.0,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animationController!,
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

                                    // Performance optimization: RepaintBoundary for expensive job widgets
                                    return RepaintBoundary(
                                      child: JobsContainer(
                                        animationController:
                                            animationController,
                                        animation: animation,
                                        child: JobListView(
                                          callback: () {},
                                          jobData: jobList[jobIndex],
                                          animation: animation,
                                          animationController:
                                              animationController!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
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

    // Interpolate tussen surface en header kleur gebaseerd op scroll positie
    final backgroundColor = Color.lerp(
      DesignTokens.guardSurface,
      colorScheme.surface, // Header kleur
      topBarOpacity,
    )!;

    return Stack(
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: backgroundColor, // ✅ Animerende achtergrond
              boxShadow: [DesignTokens.shadowLight],
            ),
          ),
        ),
        Container(
          color: backgroundColor, // ✅ Animerende achtergrond
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
                          : '${JobStateManager.allJobs.length} beschikbare jobs',
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
                      await context.push('/job-filters'); // Converted from Navigator.push to GoRouter
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

  Widget getAppBarUI() {
    return UnifiedHeader.animated(
      title: 'Jobs',
      animationController: animationController!,
      scrollController: _scrollController,
      enableScrollAnimation: true,
      userRole: UserRole.guard, // ✅ Corrected: Jobs pagina is voor guards
      titleAlignment: TextAlign.left, // ✅ Links uitlijnen zoals andere pagina's
      actions: [
        ValueListenableBuilder<Set<String>>(
          valueListenable: _favoritesService.favoriteJobIds,
          builder: (context, favoriteIds, child) {
            return HeaderElements.actionButton(
              icon: favoriteIds.isEmpty
                  ? Icons.favorite_border
                  : Icons.favorite,
              onPressed: () {
                context.push('/beveiliger/favorites');
                // Original: Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => const FavoritesScreen(),
                //   ),
                // );
              },
              userRole: UserRole.guard,
            );
          },
        ),
        HeaderElements.actionButton(
          icon: Icons.account_circle,
          onPressed: () {
            context.push('/beveiliger/profile');
          },
          userRole: UserRole.guard,
        ),
      ],
    );
  }

  Widget _buildEmptyResults() {

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
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Template-style action button
          if (searchController.text.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: UnifiedButton.primary(
                text: 'Wis zoekopdracht',
                onPressed: () {
                  searchController.clear();
                  _performSearch('');
                },
                size: UnifiedButtonSize.large,
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
            style: TextStyle(fontSize: 16, color: DesignTokens.colorGray600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {

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
            child: Icon(Icons.error_outline, size: 48, color: DesignTokens.statusCancelled.withValues(alpha: 0.4)),
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
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Template-style retry button
          SizedBox(
            width: double.infinity,
            child: UnifiedButton.primary(
              text: 'Probeer opnieuw',
              onPressed: _retryLoadData,
              size: UnifiedButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }

  void _retryLoadData() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      await JobStateManager.refreshData();
      if (mounted) {
        setState(() {
          isLoading = false;
          jobList = JobStateManager.filteredJobs;
          errorMessage = JobStateManager.errorMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Fout bij laden van jobs: $e';
        });
      }
    }
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
