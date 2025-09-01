import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/marketplace/model/security_job_data.dart';

/// Service for managing user's favorite jobs
/// 
/// Features:
/// - Add/remove jobs from favorites
/// - Persist favorites locally using SharedPreferences
/// - Real-time updates via ValueNotifier
/// - User-specific favorites (tied to current user)
/// - Offline support with local storage
class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  static const String _favoritesKey = 'user_favorites';
  
  // Real-time favorites state
  final ValueNotifier<Set<String>> _favoriteJobIds = ValueNotifier<Set<String>>({});
  
  /// Get current favorite job IDs as a stream
  ValueListenable<Set<String>> get favoriteJobIds => _favoriteJobIds;
  
  /// Get current favorite job IDs synchronously
  Set<String> get currentFavorites => Set.from(_favoriteJobIds.value);
  
  /// Initialize favorites service
  Future<void> initialize() async {
    await _loadFavorites();
  }
  
  /// Check if a job is favorited
  bool isFavorite(String jobId) {
    return _favoriteJobIds.value.contains(jobId);
  }
  
  /// Toggle favorite status of a job
  Future<bool> toggleFavorite(String jobId) async {
    if (jobId.isEmpty) return false;
    
    try {
      final currentFavorites = Set<String>.from(_favoriteJobIds.value);
      
      if (currentFavorites.contains(jobId)) {
        // Remove from favorites
        currentFavorites.remove(jobId);
        debugPrint('Removed job $jobId from favorites');
      } else {
        // Add to favorites
        currentFavorites.add(jobId);
        debugPrint('Added job $jobId to favorites');
      }
      
      // Update state
      _favoriteJobIds.value = currentFavorites;
      
      // Persist to storage
      await _saveFavorites();
      
      return true;
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      return false;
    }
  }
  
  /// Add job to favorites
  Future<bool> addToFavorites(String jobId) async {
    if (jobId.isEmpty || isFavorite(jobId)) return false;
    
    try {
      final currentFavorites = Set<String>.from(_favoriteJobIds.value);
      currentFavorites.add(jobId);
      
      _favoriteJobIds.value = currentFavorites;
      await _saveFavorites();
      
      debugPrint('Added job $jobId to favorites');
      return true;
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      return false;
    }
  }
  
  /// Remove job from favorites
  Future<bool> removeFromFavorites(String jobId) async {
    if (jobId.isEmpty || !isFavorite(jobId)) return false;
    
    try {
      final currentFavorites = Set<String>.from(_favoriteJobIds.value);
      currentFavorites.remove(jobId);
      
      _favoriteJobIds.value = currentFavorites;
      await _saveFavorites();
      
      debugPrint('Removed job $jobId from favorites');
      return true;
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      return false;
    }
  }
  
  /// Get all favorite jobs with full job data
  List<SecurityJobData> getFavoriteJobs() {
    final favoriteIds = _favoriteJobIds.value;
    return SecurityJobData.jobList
        .where((job) => favoriteIds.contains(job.jobId))
        .toList();
  }
  
  /// Clear all favorites
  Future<void> clearFavorites() async {
    try {
      _favoriteJobIds.value = {};
      await _saveFavorites();
      debugPrint('Cleared all favorites');
    } catch (e) {
      debugPrint('Error clearing favorites: $e');
    }
  }
  
  /// Get favorites count
  int get favoritesCount => _favoriteJobIds.value.length;
  
  /// Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _getCurrentUserId();
      final key = '${_favoritesKey}_$userId';
      
      final favoritesJson = prefs.getString(key);
      if (favoritesJson != null) {
        final favoritesList = List<String>.from(json.decode(favoritesJson));
        _favoriteJobIds.value = favoritesList.toSet();
        debugPrint('Loaded ${favoritesList.length} favorites for user $userId');
      } else {
        _favoriteJobIds.value = {};
        debugPrint('No favorites found for user $userId');
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      _favoriteJobIds.value = {};
    }
  }
  
  /// Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _getCurrentUserId();
      final key = '${_favoritesKey}_$userId';
      
      final favoritesList = _favoriteJobIds.value.toList();
      final favoritesJson = json.encode(favoritesList);
      
      await prefs.setString(key, favoritesJson);
      debugPrint('Saved ${favoritesList.length} favorites for user $userId');
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }
  
  /// Get current user ID for user-specific favorites
  String _getCurrentUserId() {
    if (AuthService.isLoggedIn) {
      return AuthService.currentUserName; // Use name as ID for demo
    }
    return 'guest'; // Fallback for non-logged in users
  }
  
  /// Reset favorites when user logs out
  void onUserLogout() {
    _favoriteJobIds.value = {};
    debugPrint('Cleared favorites on user logout');
  }
  
  /// Load favorites when user logs in
  Future<void> onUserLogin() async {
    await _loadFavorites();
    debugPrint('Loaded favorites on user login');
  }
}
