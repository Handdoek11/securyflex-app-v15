import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/marketplace/services/favorites_service.dart';
import 'package:securyflex_app/marketplace/job_list_view.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';

/// Screen displaying user's favorite jobs
/// 
/// Features:
/// - Real-time updates when favorites change
/// - Empty state when no favorites
/// - Job cards with remove from favorites option
/// - Consistent styling with main jobs screen
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  AnimationController? animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    animationController?.forward();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              UnifiedHeader.simple(
                title: 'Favoriete Jobs',
                userRole: UserRole.guard,
                titleAlignment: TextAlign.center,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
                  onPressed: () => context.pop(),
                ),
            actions: [
              ValueListenableBuilder<Set<String>>(
                valueListenable: _favoritesService.favoriteJobIds,
                builder: (context, favoriteIds, child) {
                  if (favoriteIds.isEmpty) return const SizedBox.shrink();
                  
                  return HeaderElements.actionButton(
                    icon: Icons.clear_all,
                    onPressed: _showClearAllDialog,
                    userRole: UserRole.guard,
                  );
                },
              ),
            ],
          ),
              Expanded(
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: _favoritesService.favoriteJobIds,
                  builder: (context, favoriteIds, child) {
                    final favoriteJobs = _favoritesService.getFavoriteJobs();
                    
                    if (favoriteJobs.isEmpty) {
                      return _buildEmptyState();
                    }
                    
                    return _buildFavoritesList(favoriteJobs);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: DesignTokens.spacingL),
            Text(
              'Geen favoriete jobs',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBodyLarge,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: colorScheme.onSurface,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              'Jobs die je als favoriet markeert verschijnen hier.\nTik op het hartje bij een job om deze toe te voegen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontFamily: DesignTokens.fontFamily,
                height: 1.5,
              ),
            ),
            SizedBox(height: DesignTokens.spacingXL),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: Icon(Icons.search),
              label: Text('Zoek Jobs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingL,
                  vertical: DesignTokens.spacingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<SecurityJobData> favoriteJobs) {
    return ListView.builder(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      itemCount: favoriteJobs.length,
      itemBuilder: (context, index) {
        final job = favoriteJobs[index];
        final count = favoriteJobs.length > 8 ? 8 : favoriteJobs.length;
        
        final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(
          parent: animationController!,
          curve: Interval(
            (1 / count) * (index % count),
            1.0,
            curve: Curves.fastOutSlowIn,
          ),
        ));

        if (index == 0) {
          animationController?.forward();
        }

        return JobListView(
          callback: () {},
          jobData: job,
          animation: animation,
          animationController: animationController!,
          showFavoriteButton: true,
          isFavoriteScreen: true,
        );
      },
    );
  }

  void _showClearAllDialog() {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Alle favorieten verwijderen?',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          content: Text(
            'Dit kan niet ongedaan worden gemaakt.',
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Annuleren',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _favoritesService.clearFavorites();
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alle favorieten verwijderd'),
                    backgroundColor: colorScheme.primary,
                  ),
                );
              },
              child: Text(
                'Verwijderen',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
