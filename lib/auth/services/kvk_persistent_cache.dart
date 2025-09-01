import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'kvk_additional_classes.dart';

/// Persistent SQLite cache for KvK validation data
/// Provides long-term storage with automatic cleanup and integrity verification
class KvKPersistentCache {
  static Database? _database;
  static const String _tableName = 'kvk_cache';
  static const String _auditTableName = 'kvk_audit';
  static const int _maxCacheAgeDays = 7; // Cache valid for 7 days
  static const int _maxAuditEntries = 10000;

  /// Initialize the database and create tables
  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, 'kvk_cache.db');
      
      return await openDatabase(
        dbPath,
        version: 2,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
        onOpen: (db) async {
          // Enable foreign keys and WAL mode for better performance
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
          await db.execute('PRAGMA cache_size = 10000');
        },
      );
    } catch (e) {
      debugPrint('Error initializing KvK cache database: $e');
      rethrow;
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    // Main cache table
    await db.execute('''
      CREATE TABLE $_tableName (
        kvk_number TEXT PRIMARY KEY,
        data_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        accessed_at INTEGER NOT NULL,
        access_count INTEGER DEFAULT 1,
        checksum TEXT NOT NULL,
        eligibility_score REAL,
        is_security_eligible INTEGER,
        company_name TEXT
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_created_at ON $_tableName(created_at)');
    await db.execute('CREATE INDEX idx_accessed_at ON $_tableName(accessed_at)');
    await db.execute('CREATE INDEX idx_eligibility ON $_tableName(is_security_eligible)');

    // Audit table
    await db.execute('''
      CREATE TABLE $_auditTableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kvk_number TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        success INTEGER NOT NULL,
        error_code TEXT,
        duration_ms INTEGER,
        source TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_audit_timestamp ON $_auditTableName(timestamp)');
    await db.execute('CREATE INDEX idx_audit_kvk ON $_auditTableName(kvk_number)');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      try {
        await db.execute('ALTER TABLE $_tableName ADD COLUMN eligibility_score REAL');
        await db.execute('ALTER TABLE $_tableName ADD COLUMN is_security_eligible INTEGER');
        await db.execute('ALTER TABLE $_tableName ADD COLUMN company_name TEXT');
        await db.execute('CREATE INDEX idx_eligibility ON $_tableName(is_security_eligible)');
      } catch (e) {
        debugPrint('Error upgrading database: $e');
        // If columns already exist, continue silently
      }
    }
  }

  /// Store KvK data in persistent cache
  static Future<void> store(String kvkNumber, KvKData data) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final dataJson = json.encode(data.toJson());
      final checksum = _calculateChecksum(dataJson, now);

      await db.insert(
        _tableName,
        {
          'kvk_number': kvkNumber,
          'data_json': dataJson,
          'created_at': now,
          'accessed_at': now,
          'access_count': 1,
          'checksum': checksum,
          'eligibility_score': data.eligibilityScore,
          'is_security_eligible': data.isSecurityEligible ? 1 : 0,
          'company_name': data.companyName,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('KvK data cached for $kvkNumber');
    } catch (e) {
      debugPrint('Error storing KvK data in cache: $e');
      // Don't throw - cache failures shouldn't break the app
    }
  }

  /// Retrieve KvK data from persistent cache
  static Future<KvKData?> retrieve(String kvkNumber) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredThreshold = now - (_maxCacheAgeDays * 24 * 60 * 60 * 1000);

      final results = await db.query(
        _tableName,
        where: 'kvk_number = ? AND created_at > ?',
        whereArgs: [kvkNumber, expiredThreshold],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final row = results.first;
      final dataJson = row['data_json'] as String;
      final storedChecksum = row['checksum'] as String;
      final createdAt = row['created_at'] as int;

      // Verify data integrity
      final expectedChecksum = _calculateChecksum(dataJson, createdAt);
      if (storedChecksum != expectedChecksum) {
        debugPrint('Cache integrity check failed for $kvkNumber, removing entry');
        await delete(kvkNumber);
        return null;
      }

      // Update access statistics
      await db.update(
        _tableName,
        {
          'accessed_at': now,
          'access_count': (row['access_count'] as int) + 1,
        },
        where: 'kvk_number = ?',
        whereArgs: [kvkNumber],
      );

      // Parse and return the data
      final dataMap = json.decode(dataJson) as Map<String, dynamic>;
      return KvKData.fromJson(dataMap);
    } catch (e) {
      debugPrint('Error retrieving KvK data from cache: $e');
      return null;
    }
  }

  /// Delete specific entry from cache
  static Future<void> delete(String kvkNumber) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'kvk_number = ?',
        whereArgs: [kvkNumber],
      );
      debugPrint('KvK cache entry deleted for $kvkNumber');
    } catch (e) {
      debugPrint('Error deleting KvK cache entry: $e');
    }
  }

  /// Clear all expired entries
  static Future<int> cleanupExpired() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredThreshold = now - (_maxCacheAgeDays * 24 * 60 * 60 * 1000);

      final deletedCount = await db.delete(
        _tableName,
        where: 'created_at < ?',
        whereArgs: [expiredThreshold],
      );

      if (deletedCount > 0) {
        debugPrint('Cleaned up $deletedCount expired KvK cache entries');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('Error cleaning up expired cache entries: $e');
      return 0;
    }
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      debugPrint('All KvK cache entries cleared');
    } catch (e) {
      debugPrint('Error clearing all cache entries: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredThreshold = now - (_maxCacheAgeDays * 24 * 60 * 60 * 1000);

      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      final validResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE created_at > ?',
        [expiredThreshold],
      );
      final securityEligibleResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE is_security_eligible = 1 AND created_at > ?',
        [expiredThreshold],
      );

      final totalAccesses = await db.rawQuery('SELECT SUM(access_count) as total FROM $_tableName');
      final avgEligibilityResult = await db.rawQuery(
        'SELECT AVG(eligibility_score) as avg FROM $_tableName WHERE created_at > ? AND eligibility_score IS NOT NULL',
        [expiredThreshold],
      );

      return {
        'totalEntries': totalResult.first['count'] as int,
        'validEntries': validResult.first['count'] as int,
        'expiredEntries': (totalResult.first['count'] as int) - (validResult.first['count'] as int),
        'securityEligibleCompanies': securityEligibleResult.first['count'] as int,
        'totalAccesses': totalAccesses.first['total'] ?? 0,
        'averageEligibilityScore': avgEligibilityResult.first['avg'] ?? 0.0,
        'cacheMaxAgeDays': _maxCacheAgeDays,
      };
    } catch (e) {
      debugPrint('Error getting cache statistics: $e');
      return {
        'error': e.toString(),
        'totalEntries': 0,
        'validEntries': 0,
        'expiredEntries': 0,
      };
    }
  }

  /// Search cached companies by name
  static Future<List<KvKData>> searchByCompanyName(String searchTerm, {int limit = 10}) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiredThreshold = now - (_maxCacheAgeDays * 24 * 60 * 60 * 1000);
      final searchPattern = '%${searchTerm.toLowerCase()}%';

      final results = await db.query(
        _tableName,
        where: 'created_at > ? AND LOWER(company_name) LIKE ?',
        whereArgs: [expiredThreshold, searchPattern],
        orderBy: 'access_count DESC, created_at DESC',
        limit: limit,
      );

      final companies = <KvKData>[];
      for (final row in results) {
        try {
          final dataJson = row['data_json'] as String;
          final dataMap = json.decode(dataJson) as Map<String, dynamic>;
          companies.add(KvKData.fromJson(dataMap));
        } catch (e) {
          debugPrint('Error parsing cached company data: $e');
          continue;
        }
      }

      return companies;
    } catch (e) {
      debugPrint('Error searching cached companies: $e');
      return [];
    }
  }

  /// Log audit entry
  static Future<void> logAudit({
    required String kvkNumber,
    required String action,
    required bool success,
    String? errorCode,
    int? durationMs,
    String source = 'api',
  }) async {
    try {
      final db = await database;
      await db.insert(_auditTableName, {
        'kvk_number': kvkNumber,
        'action': action,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'success': success ? 1 : 0,
        'error_code': errorCode,
        'duration_ms': durationMs,
        'source': source,
      });

      // Cleanup old audit entries to prevent database growth
      final totalAuditEntries = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_auditTableName'),
      ) ?? 0;

      if (totalAuditEntries > _maxAuditEntries) {
        final deleteCount = totalAuditEntries - (_maxAuditEntries * 0.8).round();
        await db.delete(
          _auditTableName,
          where: 'id IN (SELECT id FROM $_auditTableName ORDER BY timestamp ASC LIMIT ?)',
          whereArgs: [deleteCount],
        );
      }
    } catch (e) {
      debugPrint('Error logging audit entry: $e');
    }
  }

  /// Get audit statistics
  static Future<Map<String, dynamic>> getAuditStatistics({int? lastHours}) async {
    try {
      final db = await database;
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (lastHours != null) {
        final threshold = DateTime.now().subtract(Duration(hours: lastHours)).millisecondsSinceEpoch;
        whereClause = 'WHERE timestamp > ?';
        whereArgs = [threshold];
      }

      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_auditTableName $whereClause', whereArgs);
      final successResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_auditTableName $whereClause ${whereClause.isEmpty ? 'WHERE' : 'AND'} success = 1', whereArgs);
      final avgDurationResult = await db.rawQuery('SELECT AVG(duration_ms) as avg FROM $_auditTableName $whereClause ${whereClause.isEmpty ? 'WHERE' : 'AND'} duration_ms IS NOT NULL', whereArgs);

      return {
        'totalRequests': totalResult.first['count'] as int,
        'successfulRequests': successResult.first['count'] as int,
        'failedRequests': (totalResult.first['count'] as int) - (successResult.first['count'] as int),
        'averageDurationMs': avgDurationResult.first['avg'] ?? 0.0,
        'successRate': (totalResult.first['count'] as int) > 0 
          ? (successResult.first['count'] as int) / (totalResult.first['count'] as int)
          : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting audit statistics: $e');
      return {'error': e.toString()};
    }
  }

  /// Calculate integrity checksum
  static String _calculateChecksum(String data, int timestamp) {
    final combined = '$data:$timestamp:kvk-cache-v2';
    return combined.hashCode.abs().toString();
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Optimize database performance
  static Future<void> optimize() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
      await db.execute('ANALYZE');
      debugPrint('KvK cache database optimized');
    } catch (e) {
      debugPrint('Error optimizing database: $e');
    }
  }
}

