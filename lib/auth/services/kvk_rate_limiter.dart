import 'dart:math';
import 'package:flutter/foundation.dart';

/// Advanced rate limiter with user-based throttling and exponential backoff
class KvKRateLimiter {
  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 10;
  static const int _maxRequestsPerHour = 100;
  static const int _maxRequestsPerDay = 500;
  
  // Exponential backoff configuration
  static const Duration _baseBackoffDelay = Duration(seconds: 1);
  static const int _maxBackoffMultiplier = 32; // Max ~32 seconds
  
  // Storage for rate limiting data
  static final Map<String, List<DateTime>> _minuteRequests = {};
  static final Map<String, List<DateTime>> _hourlyRequests = {};
  static final Map<String, List<DateTime>> _dailyRequests = {};
  static final Map<String, int> _failureCount = {};
  static final Map<String, DateTime?> _lastFailureTime = {};
  static final Map<String, Duration> _currentBackoff = {};

  /// Check if request is allowed for the given user/IP
  static bool isRequestAllowed(String identifier) {
    final now = DateTime.now();
    
    // Clean up old requests
    _cleanupOldRequests(identifier, now);
    
    // Check daily limit
    final dailyRequests = _dailyRequests[identifier] ?? [];
    if (dailyRequests.length >= _maxRequestsPerDay) {
      debugPrint('Rate limit exceeded: Daily limit reached for $identifier');
      return false;
    }
    
    // Check hourly limit
    final hourlyRequests = _hourlyRequests[identifier] ?? [];
    if (hourlyRequests.length >= _maxRequestsPerHour) {
      debugPrint('Rate limit exceeded: Hourly limit reached for $identifier');
      return false;
    }
    
    // Check per-minute limit
    final minuteRequests = _minuteRequests[identifier] ?? [];
    if (minuteRequests.length >= _maxRequestsPerMinute) {
      debugPrint('Rate limit exceeded: Per-minute limit reached for $identifier');
      return false;
    }
    
    // Check exponential backoff
    if (_isInBackoffPeriod(identifier, now)) {
      debugPrint('Rate limit exceeded: In backoff period for $identifier');
      return false;
    }
    
    return true;
  }

  /// Record a successful request
  static void recordSuccessfulRequest(String identifier) {
    final now = DateTime.now();
    
    // Record the request
    _minuteRequests.putIfAbsent(identifier, () => []).add(now);
    _hourlyRequests.putIfAbsent(identifier, () => []).add(now);
    _dailyRequests.putIfAbsent(identifier, () => []).add(now);
    
    // Reset failure count on successful request
    _failureCount[identifier] = 0;
    _currentBackoff.remove(identifier);
    
    debugPrint('Successful request recorded for $identifier');
  }

  /// Record a failed request and apply exponential backoff
  static void recordFailedRequest(String identifier) {
    final now = DateTime.now();
    
    // Increment failure count
    _failureCount[identifier] = (_failureCount[identifier] ?? 0) + 1;
    _lastFailureTime[identifier] = now;
    
    // Calculate exponential backoff
    final failureCount = _failureCount[identifier]!;
    final backoffMultiplier = min(pow(2, failureCount - 1).toInt(), _maxBackoffMultiplier);
    final backoffDelay = Duration(
      milliseconds: _baseBackoffDelay.inMilliseconds * backoffMultiplier,
    );
    
    _currentBackoff[identifier] = backoffDelay;
    
    debugPrint('Failed request recorded for $identifier. Backoff: ${backoffDelay.inSeconds}s');
  }

  /// Get remaining requests for different time windows
  static Map<String, int> getRemainingRequests(String identifier) {
    final now = DateTime.now();
    _cleanupOldRequests(identifier, now);
    
    final minuteRequests = _minuteRequests[identifier]?.length ?? 0;
    final hourlyRequests = _hourlyRequests[identifier]?.length ?? 0;
    final dailyRequests = _dailyRequests[identifier]?.length ?? 0;
    
    return {
      'perMinute': _maxRequestsPerMinute - minuteRequests,
      'perHour': _maxRequestsPerHour - hourlyRequests,
      'perDay': _maxRequestsPerDay - dailyRequests,
    };
  }

  /// Get time until next request is allowed
  static Duration? getTimeUntilNextRequest(String identifier) {
    final now = DateTime.now();
    
    // Check if in backoff period
    if (_isInBackoffPeriod(identifier, now)) {
      final lastFailure = _lastFailureTime[identifier]!;
      final backoffDelay = _currentBackoff[identifier]!;
      final backoffEnd = lastFailure.add(backoffDelay);
      return backoffEnd.difference(now);
    }
    
    _cleanupOldRequests(identifier, now);
    
    // Check minute window
    final minuteRequests = _minuteRequests[identifier] ?? [];
    if (minuteRequests.length >= _maxRequestsPerMinute) {
      final oldestRequest = minuteRequests.first;
      final windowEnd = oldestRequest.add(const Duration(minutes: 1));
      return windowEnd.difference(now);
    }
    
    // Check hour window
    final hourlyRequests = _hourlyRequests[identifier] ?? [];
    if (hourlyRequests.length >= _maxRequestsPerHour) {
      final oldestRequest = hourlyRequests.first;
      final windowEnd = oldestRequest.add(const Duration(hours: 1));
      return windowEnd.difference(now);
    }
    
    // Check day window
    final dailyRequests = _dailyRequests[identifier] ?? [];
    if (dailyRequests.length >= _maxRequestsPerDay) {
      final oldestRequest = dailyRequests.first;
      final windowEnd = oldestRequest.add(const Duration(days: 1));
      return windowEnd.difference(now);
    }
    
    return null; // No restriction
  }

  /// Get current failure count for identifier
  static int getFailureCount(String identifier) {
    return _failureCount[identifier] ?? 0;
  }

  /// Check if identifier is currently in backoff period
  static bool _isInBackoffPeriod(String identifier, DateTime now) {
    final lastFailure = _lastFailureTime[identifier];
    final backoffDelay = _currentBackoff[identifier];
    
    if (lastFailure == null || backoffDelay == null) return false;
    
    final backoffEnd = lastFailure.add(backoffDelay);
    return now.isBefore(backoffEnd);
  }

  /// Clean up old requests outside the time windows
  static void _cleanupOldRequests(String identifier, DateTime now) {
    // Clean up minute requests
    final minuteRequests = _minuteRequests[identifier];
    if (minuteRequests != null) {
      minuteRequests.removeWhere(
        (time) => now.difference(time) > const Duration(minutes: 1),
      );
      if (minuteRequests.isEmpty) {
        _minuteRequests.remove(identifier);
      }
    }
    
    // Clean up hourly requests
    final hourlyRequests = _hourlyRequests[identifier];
    if (hourlyRequests != null) {
      hourlyRequests.removeWhere(
        (time) => now.difference(time) > const Duration(hours: 1),
      );
      if (hourlyRequests.isEmpty) {
        _hourlyRequests.remove(identifier);
      }
    }
    
    // Clean up daily requests
    final dailyRequests = _dailyRequests[identifier];
    if (dailyRequests != null) {
      dailyRequests.removeWhere(
        (time) => now.difference(time) > const Duration(days: 1),
      );
      if (dailyRequests.isEmpty) {
        _dailyRequests.remove(identifier);
      }
    }
  }

  /// Clear all rate limiting data for an identifier
  static void clearIdentifier(String identifier) {
    _minuteRequests.remove(identifier);
    _hourlyRequests.remove(identifier);
    _dailyRequests.remove(identifier);
    _failureCount.remove(identifier);
    _lastFailureTime.remove(identifier);
    _currentBackoff.remove(identifier);
    
    debugPrint('Rate limiting data cleared for $identifier');
  }

  /// Clear all rate limiting data
  static void clearAll() {
    _minuteRequests.clear();
    _hourlyRequests.clear();
    _dailyRequests.clear();
    _failureCount.clear();
    _lastFailureTime.clear();
    _currentBackoff.clear();
    
    debugPrint('All rate limiting data cleared');
  }

  /// Get comprehensive statistics
  static Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final stats = <String, dynamic>{
      'limits': {
        'perMinute': _maxRequestsPerMinute,
        'perHour': _maxRequestsPerHour,
        'perDay': _maxRequestsPerDay,
      },
      'activeIdentifiers': <String, Map<String, dynamic>>{},
      'totalActiveIdentifiers': 0,
      'totalBackoffIdentifiers': 0,
    };
    
    final allIdentifiers = <String>{};
    allIdentifiers.addAll(_minuteRequests.keys);
    allIdentifiers.addAll(_hourlyRequests.keys);
    allIdentifiers.addAll(_dailyRequests.keys);
    allIdentifiers.addAll(_failureCount.keys);
    
    var backoffCount = 0;
    
    for (final identifier in allIdentifiers) {
      _cleanupOldRequests(identifier, now);
      
      final minuteRequests = _minuteRequests[identifier]?.length ?? 0;
      final hourlyRequests = _hourlyRequests[identifier]?.length ?? 0;
      final dailyRequests = _dailyRequests[identifier]?.length ?? 0;
      final failureCount = _failureCount[identifier] ?? 0;
      final isInBackoff = _isInBackoffPeriod(identifier, now);
      
      if (isInBackoff) backoffCount++;
      
      stats['activeIdentifiers'][identifier] = {
        'minuteRequests': minuteRequests,
        'hourlyRequests': hourlyRequests,
        'dailyRequests': dailyRequests,
        'failureCount': failureCount,
        'isInBackoff': isInBackoff,
        'remainingRequests': getRemainingRequests(identifier),
        'nextRequestIn': getTimeUntilNextRequest(identifier)?.inSeconds,
      };
    }
    
    stats['totalActiveIdentifiers'] = allIdentifiers.length;
    stats['totalBackoffIdentifiers'] = backoffCount;
    
    return stats;
  }

  /// Create a custom rate limit exception
  static KvKRateLimitException createException(String identifier) {
    final remaining = getRemainingRequests(identifier);
    final nextRequestIn = getTimeUntilNextRequest(identifier);
    final failureCount = getFailureCount(identifier);
    
    String message;
    String suggestion;
    
    if (nextRequestIn != null) {
      if (nextRequestIn.inDays > 0) {
        message = 'Dagelijkse limiet bereikt. Probeer morgen opnieuw.';
        suggestion = 'Wacht tot ${nextRequestIn.inDays + 1} dag(en) voordat u opnieuw probeert.';
      } else if (nextRequestIn.inHours > 0) {
        message = 'Uurlimiet bereikt. Probeer over ${nextRequestIn.inHours + 1} uur opnieuw.';
        suggestion = 'Wacht ${nextRequestIn.inHours + 1} uur voordat u opnieuw probeert.';
      } else if (nextRequestIn.inMinutes > 0) {
        message = 'Te veel verzoeken. Probeer over ${nextRequestIn.inMinutes + 1} minuten opnieuw.';
        suggestion = 'Wacht ${nextRequestIn.inMinutes + 1} minuten voordat u opnieuw probeert.';
      } else {
        message = 'Te veel verzoeken. Probeer over ${nextRequestIn.inSeconds + 1} seconden opnieuw.';
        suggestion = 'Wacht ${nextRequestIn.inSeconds + 1} seconden voordat u opnieuw probeert.';
      }
    } else {
      message = 'Rate limit bereikt.';
      suggestion = 'Probeer later opnieuw.';
    }
    
    return KvKRateLimitException(
      message: message,
      suggestion: suggestion,
      remaining: remaining,
      nextRequestIn: nextRequestIn,
      failureCount: failureCount,
    );
  }
}

/// Custom exception for rate limiting
class KvKRateLimitException implements Exception {
  final String message;
  final String suggestion;
  final Map<String, int> remaining;
  final Duration? nextRequestIn;
  final int failureCount;

  const KvKRateLimitException({
    required this.message,
    required this.suggestion,
    required this.remaining,
    this.nextRequestIn,
    required this.failureCount,
  });

  @override
  String toString() {
    return 'KvKRateLimitException: $message\n'
           'Suggestion: $suggestion\n'
           'Remaining requests: $remaining\n'
           'Next request in: ${nextRequestIn?.inSeconds}s\n'
           'Failure count: $failureCount';
  }

  /// Get user-friendly Dutch message
  String get dutchMessage => message;

  /// Get action suggestion in Dutch
  String get dutchSuggestion => suggestion;
}