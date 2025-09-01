import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';

/// Enhanced presence detection service for SecuryFlex Chat
/// Manages online status, last seen, and typing indicators with auto-cleanup
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  static PresenceService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _presenceTimer;
  Timer? _typingCleanupTimer;
  String? _currentUserId;
  bool _isOnline = false;
  
  static const Duration _presenceUpdateInterval = Duration(seconds: 30);
  static const Duration _typingTimeout = Duration(seconds: 5);
  static const Duration _offlineThreshold = Duration(minutes: 2);

  /// Initialize presence service for current user
  Future<void> initialize() async {
    if (!AuthService.isLoggedIn) return;

    _currentUserId = AuthService.currentUserType; // Should be actual user ID
    await _setOnlineStatus(true);
    _startPresenceUpdates();
    _startTypingCleanup();
    
    debugPrint('PresenceService initialized for user: $_currentUserId');
  }

  /// Set user online status
  Future<void> _setOnlineStatus(bool isOnline) async {
    if (_currentUserId == null) return;

    try {
      _isOnline = isOnline;
      
      await _firestore
          .collection('user_presence')
          .doc(_currentUserId)
          .set({
        'userId': _currentUserId,
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'userRole': AuthService.currentUserType.toLowerCase(),
        'userName': AuthService.currentUserName,
        'platform': defaultTargetPlatform.name,
        'appVersion': '1.0.0', // Should be from package info
      }, SetOptions(merge: true));
      
      debugPrint('User presence updated: online=$isOnline');
    } catch (e) {
      debugPrint('Error updating presence: $e');
    }
  }

  /// Start periodic presence updates
  void _startPresenceUpdates() {
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(_presenceUpdateInterval, (timer) {
      if (_isOnline) {
        _setOnlineStatus(true);
      }
    });
  }

  /// Start typing status cleanup
  void _startTypingCleanup() {
    _typingCleanupTimer?.cancel();
    _typingCleanupTimer = Timer.periodic(_typingTimeout, (timer) {
      _cleanupExpiredTypingStatus();
    });
  }

  /// Clean up expired typing status entries
  Future<void> _cleanupExpiredTypingStatus() async {
    try {
      final cutoffTime = DateTime.now().subtract(_typingTimeout);
      
      final expiredTyping = await _firestore
          .collection('typing_status')
          .where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in expiredTyping.docs) {
        batch.delete(doc.reference);
      }
      
      if (expiredTyping.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Cleaned up ${expiredTyping.docs.length} expired typing status entries');
      }
    } catch (e) {
      debugPrint('Error cleaning up typing status: $e');
    }
  }

  /// Set typing status for a conversation
  Future<void> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    if (_currentUserId == null) return;

    try {
      final typingDocId = '${conversationId}_$_currentUserId';
      
      if (isTyping) {
        await _firestore
            .collection('typing_status')
            .doc(typingDocId)
            .set({
          'conversationId': conversationId,
          'userId': _currentUserId,
          'userName': AuthService.currentUserName,
          'userRole': AuthService.currentUserType.toLowerCase(),
          'isTyping': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore
            .collection('typing_status')
            .doc(typingDocId)
            .delete();
      }
      
      debugPrint('Typing status updated: $isTyping for conversation $conversationId');
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Watch typing status for a conversation
  Stream<List<TypingUser>> watchTypingStatus(String conversationId) {
    return _firestore
        .collection('typing_status')
        .where('conversationId', isEqualTo: conversationId)
        .where('isTyping', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final typingUsers = <TypingUser>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        
        // Don't include current user in typing list
        if (userId != null && userId != _currentUserId) {
          typingUsers.add(TypingUser(
            userId: userId,
            userName: data['userName'] as String? ?? 'Onbekende gebruiker',
            userRole: data['userRole'] as String? ?? 'user',
            lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
          ));
        }
      }
      
      return typingUsers;
    });
  }

  /// Watch user presence status
  Stream<UserPresence> watchUserPresence(String userId) {
    return _firestore
        .collection('user_presence')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return UserPresence(
          userId: userId,
          isOnline: false,
          lastSeen: null,
        );
      }
      
      final data = snapshot.data()!;
      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
      final isOnline = data['isOnline'] as bool? ?? false;
      
      // Check if user is actually online based on last seen time
      final actuallyOnline = isOnline && lastSeen != null &&
          DateTime.now().difference(lastSeen) < _offlineThreshold;
      
      return UserPresence(
        userId: userId,
        isOnline: actuallyOnline,
        lastSeen: lastSeen,
        userName: data['userName'] as String?,
        userRole: data['userRole'] as String?,
        platform: data['platform'] as String?,
      );
    });
  }

  /// Get multiple users' presence status
  Stream<Map<String, UserPresence>> watchMultipleUserPresence(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value({});
    }
    
    return _firestore
        .collection('user_presence')
        .where('userId', whereIn: userIds)
        .snapshots()
        .map((snapshot) {
      final presenceMap = <String, UserPresence>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String;
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final isOnline = data['isOnline'] as bool? ?? false;
        
        // Check if user is actually online
        final actuallyOnline = isOnline && lastSeen != null &&
            DateTime.now().difference(lastSeen) < _offlineThreshold;
        
        presenceMap[userId] = UserPresence(
          userId: userId,
          isOnline: actuallyOnline,
          lastSeen: lastSeen,
          userName: data['userName'] as String?,
          userRole: data['userRole'] as String?,
          platform: data['platform'] as String?,
        );
      }
      
      // Add offline status for users not found
      for (final userId in userIds) {
        if (!presenceMap.containsKey(userId)) {
          presenceMap[userId] = UserPresence(
            userId: userId,
            isOnline: false,
            lastSeen: null,
          );
        }
      }
      
      return presenceMap;
    });
  }

  /// Set user offline when app goes to background
  Future<void> setOffline() async {
    await _setOnlineStatus(false);
    _presenceTimer?.cancel();
    debugPrint('User set to offline');
  }

  /// Set user online when app comes to foreground
  Future<void> setOnline() async {
    await _setOnlineStatus(true);
    _startPresenceUpdates();
    debugPrint('User set to online');
  }

  /// Format last seen time in Dutch
  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Nooit online geweest';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Net online';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minuten geleden';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} uur geleden';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dagen geleden';
    } else {
      return 'Meer dan een week geleden';
    }
  }

  /// Get online status indicator color
  Color getOnlineStatusColor(bool isOnline) {
    return isOnline ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E);
  }

  /// Dispose resources
  void dispose() {
    _presenceTimer?.cancel();
    _typingCleanupTimer?.cancel();
    setOffline();
    debugPrint('PresenceService disposed');
  }

  /// Check if service is initialized
  bool get isInitialized => _currentUserId != null;

  /// Get current user online status
  bool get isCurrentUserOnline => _isOnline;
}

/// Typing user model
class TypingUser {
  final String userId;
  final String userName;
  final String userRole;
  final DateTime lastUpdated;

  const TypingUser({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.lastUpdated,
  });

  /// Get Dutch display name for user role
  String getRoleDisplayName() {
    switch (userRole.toLowerCase()) {
      case 'guard':
        return 'Beveiliger';
      case 'company':
        return 'Bedrijf';
      case 'admin':
        return 'Beheerder';
      default:
        return 'Gebruiker';
    }
  }
}

/// User presence model
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? userName;
  final String? userRole;
  final String? platform;

  const UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.userName,
    this.userRole,
    this.platform,
  });

  /// Get status text in Dutch
  String getStatusText() {
    if (isOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      return PresenceService.instance.formatLastSeen(lastSeen);
    } else {
      return 'Offline';
    }
  }

  /// Get Dutch display name for user role
  String getRoleDisplayName() {
    switch (userRole?.toLowerCase()) {
      case 'guard':
        return 'Beveiliger';
      case 'company':
        return 'Bedrijf';
      case 'admin':
        return 'Beheerder';
      default:
        return 'Gebruiker';
    }
  }
}
