import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../bloc/job_state.dart';

/// Service for persisting job filter preferences and saved searches
/// Follows Dutch data privacy regulations and provides seamless UX continuity
class FilterPersistenceService {
  static const String _filtersKey = 'job_discovery_filters';
  static const String _savedSearchesKey = 'saved_job_searches';
  static const String _filterHistoryKey = 'job_filter_history';
  static const String _viewPreferenceKey = 'job_view_preference';
  static const String _lastFilterUsedKey = 'last_filter_used_timestamp';
  
  static FilterPersistenceService? _instance;
  static FilterPersistenceService get instance => _instance ??= FilterPersistenceService._();
  
  FilterPersistenceService._();
  
  SharedPreferences? _prefs;
  
  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  /// Save current filter state for auto-restoration
  Future<bool> saveCurrentFilters(JobFilter filters) async {
    try {
      await initialize();
      
      final filterMap = {
        'searchQuery': filters.searchQuery,
        'hourlyRateRange': {
          'start': filters.hourlyRateRange.start,
          'end': filters.hourlyRateRange.end,
        },
        'maxDistance': filters.maxDistance,
        'jobType': filters.jobType,
        'certificates': filters.certificates,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _prefs!.setString(_filtersKey, json.encode(filterMap));
      await _prefs!.setInt(_lastFilterUsedKey, DateTime.now().millisecondsSinceEpoch);
      
      // Add to filter history (keep last 10)
      await _addToFilterHistory(filters);
      
      return true;
    } catch (e) {
      debugPrint('Failed to save filters: $e');
      return false;
    }
  }
  
  /// Load last used filters (within 7 days)
  Future<JobFilter?> loadLastFilters() async {
    try {
      await initialize();
      
      final filtersJson = _prefs!.getString(_filtersKey);
      final lastUsed = _prefs!.getInt(_lastFilterUsedKey);
      
      if (filtersJson == null || lastUsed == null) return null;
      
      // Only restore filters used within last 7 days
      final lastUsedDate = DateTime.fromMillisecondsSinceEpoch(lastUsed);
      final daysSinceLastUse = DateTime.now().difference(lastUsedDate).inDays;
      
      if (daysSinceLastUse > 7) {
        debugPrint('Filters too old (${daysSinceLastUse} days), not restoring');
        return null;
      }
      
      final filterMap = json.decode(filtersJson) as Map<String, dynamic>;
      
      return JobFilter(
        searchQuery: filterMap['searchQuery'] ?? '',
        hourlyRateRange: RangeValues(
          (filterMap['hourlyRateRange']?['start'] ?? 15.0).toDouble(),
          (filterMap['hourlyRateRange']?['end'] ?? 50.0).toDouble(),
        ),
        maxDistance: (filterMap['maxDistance'] ?? 10.0).toDouble(),
        jobType: filterMap['jobType'] ?? '',
        certificates: List<String>.from(filterMap['certificates'] ?? []),
      );
    } catch (e) {
      debugPrint('Failed to load filters: $e');
      return null;
    }
  }
  
  /// Save a named search for quick access
  Future<bool> saveSearch(String name, JobFilter filters) async {
    try {
      await initialize();
      
      final savedSearches = await getSavedSearches();
      
      // Remove existing search with same name
      savedSearches.removeWhere((search) => search.name == name);
      
      // Add new search (limit to 10 saved searches)
      savedSearches.insert(0, SavedJobSearch(
        name: name,
        filters: filters,
        createdAt: DateTime.now(),
      ));
      
      if (savedSearches.length > 10) {
        savedSearches.removeRange(10, savedSearches.length);
      }
      
      final savedSearchesJson = savedSearches.map((s) => s.toJson()).toList();
      await _prefs!.setString(_savedSearchesKey, json.encode(savedSearchesJson));
      
      return true;
    } catch (e) {
      debugPrint('Failed to save search: $e');
      return false;
    }
  }
  
  /// Get all saved searches
  Future<List<SavedJobSearch>> getSavedSearches() async {
    try {
      await initialize();
      
      final savedSearchesJson = _prefs!.getString(_savedSearchesKey);
      if (savedSearchesJson == null) return [];
      
      final savedSearchesList = json.decode(savedSearchesJson) as List<dynamic>;
      
      return savedSearchesList
          .map((json) => SavedJobSearch.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Failed to get saved searches: $e');
      return [];
    }
  }
  
  /// Delete a saved search
  Future<bool> deleteSavedSearch(String name) async {
    try {
      await initialize();
      
      final savedSearches = await getSavedSearches();
      savedSearches.removeWhere((search) => search.name == name);
      
      final savedSearchesJson = savedSearches.map((s) => s.toJson()).toList();
      await _prefs!.setString(_savedSearchesKey, json.encode(savedSearchesJson));
      
      return true;
    } catch (e) {
      debugPrint('Failed to delete saved search: $e');
      return false;
    }
  }
  
  /// Get filter history for quick access
  Future<List<FilterHistoryItem>> getFilterHistory() async {
    try {
      await initialize();
      
      final historyJson = _prefs!.getString(_filterHistoryKey);
      if (historyJson == null) return [];
      
      final historyList = json.decode(historyJson) as List<dynamic>;
      
      return historyList
          .map((json) => FilterHistoryItem.fromJson(json))
          .take(5) // Only show last 5
          .toList();
    } catch (e) {
      debugPrint('Failed to get filter history: $e');
      return [];
    }
  }
  
  /// Add filter combination to history
  Future<void> _addToFilterHistory(JobFilter filters) async {
    try {
      // Don't add to history if no filters are active
      if (!filters.hasActiveFilters) return;
      
      final history = await getFilterHistory();
      
      // Remove duplicate filters
      history.removeWhere((item) => _filtersEqual(item.filters, filters));
      
      // Add new filter to beginning
      history.insert(0, FilterHistoryItem(
        filters: filters,
        usedAt: DateTime.now(),
      ));
      
      // Keep only last 10
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }
      
      final historyJson = history.map((item) => item.toJson()).toList();
      await _prefs!.setString(_filterHistoryKey, json.encode(historyJson));
    } catch (e) {
      debugPrint('Failed to add to filter history: $e');
    }
  }
  
  /// Save view preference (list/grid/compact)
  Future<bool> saveViewPreference(JobViewType viewType) async {
    try {
      await initialize();
      await _prefs!.setString(_viewPreferenceKey, viewType.toString());
      return true;
    } catch (e) {
      debugPrint('Failed to save view preference: $e');
      return false;
    }
  }
  
  /// Load view preference
  Future<JobViewType> loadViewPreference() async {
    try {
      await initialize();
      
      final viewTypeString = _prefs!.getString(_viewPreferenceKey);
      if (viewTypeString == null) return JobViewType.card;
      
      return JobViewType.values.firstWhere(
        (type) => type.toString() == viewTypeString,
        orElse: () => JobViewType.card,
      );
    } catch (e) {
      debugPrint('Failed to load view preference: $e');
      return JobViewType.card;
    }
  }
  
  /// Clear all saved data (for privacy compliance)
  Future<bool> clearAllData() async {
    try {
      await initialize();
      
      await _prefs!.remove(_filtersKey);
      await _prefs!.remove(_savedSearchesKey);
      await _prefs!.remove(_filterHistoryKey);
      await _prefs!.remove(_viewPreferenceKey);
      await _prefs!.remove(_lastFilterUsedKey);
      
      return true;
    } catch (e) {
      debugPrint('Failed to clear all data: $e');
      return false;
    }
  }
  
  /// Compare two filter objects for equality
  bool _filtersEqual(JobFilter filter1, JobFilter filter2) {
    return filter1.searchQuery == filter2.searchQuery &&
           filter1.hourlyRateRange == filter2.hourlyRateRange &&
           filter1.maxDistance == filter2.maxDistance &&
           filter1.jobType == filter2.jobType &&
           _listsEqual(filter1.certificates, filter2.certificates);
  }
  
  /// Compare two lists for equality
  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    
    final sorted1 = [...list1]..sort();
    final sorted2 = [...list2]..sort();
    
    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i] != sorted2[i]) return false;
    }
    
    return true;
  }
}

/// Job view type enum
enum JobViewType { card, list, compact }

extension JobViewTypeExtension on JobViewType {
  String get displayName {
    switch (this) {
      case JobViewType.card:
        return 'Kaarten';
      case JobViewType.list:
        return 'Lijst';
      case JobViewType.compact:
        return 'Compact';
    }
  }
  
  IconData get icon {
    switch (this) {
      case JobViewType.card:
        return Icons.view_module;
      case JobViewType.list:
        return Icons.view_list;
      case JobViewType.compact:
        return Icons.view_agenda;
    }
  }
}

/// Saved job search data class
class SavedJobSearch {
  final String name;
  final JobFilter filters;
  final DateTime createdAt;
  
  const SavedJobSearch({
    required this.name,
    required this.filters,
    required this.createdAt,
  });
  
  /// Get display description of the search
  String get description {
    final parts = <String>[];
    
    if (filters.searchQuery.isNotEmpty) {
      parts.add('"${filters.searchQuery}"');
    }
    
    if (filters.jobType.isNotEmpty) {
      parts.add(filters.jobType);
    }
    
    if (filters.maxDistance < 10) {
      parts.add('max ${filters.maxDistance.round()}km');
    }
    
    if (filters.certificates.isNotEmpty) {
      parts.add('${filters.certificates.length} certificaten');
    }
    
    return parts.isEmpty ? 'Alle opdrachten' : parts.join(' • ');
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filters': {
        'searchQuery': filters.searchQuery,
        'hourlyRateRange': {
          'start': filters.hourlyRateRange.start,
          'end': filters.hourlyRateRange.end,
        },
        'maxDistance': filters.maxDistance,
        'jobType': filters.jobType,
        'certificates': filters.certificates,
      },
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  static SavedJobSearch fromJson(Map<String, dynamic> json) {
    final filtersJson = json['filters'];
    
    return SavedJobSearch(
      name: json['name'],
      filters: JobFilter(
        searchQuery: filtersJson['searchQuery'] ?? '',
        hourlyRateRange: RangeValues(
          (filtersJson['hourlyRateRange']?['start'] ?? 15.0).toDouble(),
          (filtersJson['hourlyRateRange']?['end'] ?? 50.0).toDouble(),
        ),
        maxDistance: (filtersJson['maxDistance'] ?? 10.0).toDouble(),
        jobType: filtersJson['jobType'] ?? '',
        certificates: List<String>.from(filtersJson['certificates'] ?? []),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}

/// Filter history item data class
class FilterHistoryItem {
  final JobFilter filters;
  final DateTime usedAt;
  
  const FilterHistoryItem({
    required this.filters,
    required this.usedAt,
  });
  
  /// Get display summary of the filter combination
  String get summary {
    final parts = <String>[];
    
    if (filters.searchQuery.isNotEmpty) {
      parts.add('"${filters.searchQuery}"');
    }
    
    if (filters.jobType.isNotEmpty) {
      parts.add(filters.jobType);
    }
    
    if (filters.hourlyRateRange != const RangeValues(15, 50)) {
      parts.add('€${filters.hourlyRateRange.start.round()}-€${filters.hourlyRateRange.end.round()}');
    }
    
    if (filters.maxDistance < 10) {
      parts.add('${filters.maxDistance.round()}km');
    }
    
    if (filters.certificates.isNotEmpty) {
      parts.add('${filters.certificates.length} cert.');
    }
    
    return parts.isEmpty ? 'Alle opdrachten' : parts.join(' • ');
  }
  
  /// Get Dutch relative time string
  String get relativeTime {
    final difference = DateTime.now().difference(usedAt);
    
    if (difference.inMinutes < 1) {
      return 'zojuist';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}u geleden';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d geleden';
    } else {
      return '${usedAt.day}/${usedAt.month}';
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'filters': {
        'searchQuery': filters.searchQuery,
        'hourlyRateRange': {
          'start': filters.hourlyRateRange.start,
          'end': filters.hourlyRateRange.end,
        },
        'maxDistance': filters.maxDistance,
        'jobType': filters.jobType,
        'certificates': filters.certificates,
      },
      'usedAt': usedAt.millisecondsSinceEpoch,
    };
  }
  
  static FilterHistoryItem fromJson(Map<String, dynamic> json) {
    final filtersJson = json['filters'];
    
    return FilterHistoryItem(
      filters: JobFilter(
        searchQuery: filtersJson['searchQuery'] ?? '',
        hourlyRateRange: RangeValues(
          (filtersJson['hourlyRateRange']?['start'] ?? 15.0).toDouble(),
          (filtersJson['hourlyRateRange']?['end'] ?? 50.0).toDouble(),
        ),
        maxDistance: (filtersJson['maxDistance'] ?? 10.0).toDouble(),
        jobType: filtersJson['jobType'] ?? '',
        certificates: List<String>.from(filtersJson['certificates'] ?? []),
      ),
      usedAt: DateTime.fromMillisecondsSinceEpoch(json['usedAt']),
    );
  }
}