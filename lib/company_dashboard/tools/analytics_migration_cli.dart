// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/analytics_migration_service.dart';
import '../../unified_design_tokens.dart';

/// Command-line interface for analytics migration
/// Provides easy-to-use commands for migration operations
class AnalyticsMigrationCLI {
  static const String version = '1.0.0';
  
  static Future<void> main(List<String> args) async {
    print('SecuryFlex Analytics Migration CLI v$version');
    print('=' * 50);
    
    if (args.isEmpty) {
      _printUsage();
      return;
    }
    
    final command = args[0].toLowerCase();
    final options = _parseOptions(args.skip(1).toList());
    
    switch (command) {
      case 'migrate':
        await _executeMigration(options);
        break;
      case 'validate':
        await _validateMigration(options);
        break;
      case 'rollback':
        await _rollbackMigration(options);
        break;
      case 'status':
        await _showStatus();
        break;
      case 'logs':
        await _showLogs();
        break;
      case 'help':
        _printUsage();
        break;
      default:
        print('Unknown command: $command');
        _printUsage();
    }
  }
  
  /// Execute migration with options
  static Future<void> _executeMigration(Map<String, dynamic> options) async {
    try {
      print('Starting analytics migration...');
      
      final migrationService = AnalyticsMigrationService.instance;
      
      final result = await migrationService.executeMigration(
        dryRun: options['dry-run'] ?? false,
        specificCompanies: options['companies'],
        skipValidation: options['skip-validation'] ?? false,
      );
      
      if (result.success) {
        print('\n✅ Migration completed successfully!');
        print('\nStatistics:');
        result.stats?.forEach((key, value) {
          print('  $key: $value');
        });
      } else {
        print('\n❌ Migration failed: ${result.error}');
        exit(1);
      }
      
    } catch (e) {
      print('\n❌ Migration error: $e');
      exit(1);
    }
  }
  
  /// Validate migration without executing
  static Future<void> _validateMigration(Map<String, dynamic> options) async {
    try {
      print('Validating migration readiness...');
      
      final migrationService = AnalyticsMigrationService.instance;
      
      final result = await migrationService.executeMigration(
        dryRun: true,
        specificCompanies: options['companies'],
        skipValidation: false,
      );
      
      if (result.success) {
        print('\n✅ Migration validation passed!');
        print('Ready to execute migration.');
      } else {
        print('\n❌ Migration validation failed: ${result.error}');
        exit(1);
      }
      
    } catch (e) {
      print('\n❌ Validation error: $e');
      exit(1);
    }
  }
  
  /// Rollback migration
  static Future<void> _rollbackMigration(Map<String, dynamic> options) async {
    try {
      final migrationId = options['migration-id'];
      if (migrationId == null) {
        print('❌ Migration ID is required for rollback');
        print('Usage: dart migration_cli.dart rollback --migration-id=<id>');
        exit(1);
      }
      
      print('Rolling back migration: $migrationId');
      print('⚠️  This will delete all analytics data!');
      
      if (!options['force']) {
        stdout.write('Are you sure? (y/N): ');
        final confirmation = stdin.readLineSync()?.toLowerCase();
        if (confirmation != 'y' && confirmation != 'yes') {
          print('Rollback cancelled.');
          return;
        }
      }
      
      final migrationService = AnalyticsMigrationService.instance;
      final success = await migrationService.rollbackMigration(migrationId);
      
      if (success) {
        print('\n✅ Rollback completed successfully!');
      } else {
        print('\n❌ Rollback failed!');
        exit(1);
      }
      
    } catch (e) {
      print('\n❌ Rollback error: $e');
      exit(1);
    }
  }
  
  /// Show migration status
  static Future<void> _showStatus() async {
    try {
      final migrationService = AnalyticsMigrationService.instance;
      final status = migrationService.getMigrationStatus();
      
      print('Migration Status:');
      print('  In Progress: ${status['inProgress']}');
      print('  Current Migration ID: ${status['currentMigrationId'] ?? 'None'}');
      print('  Log Entries: ${status['logCount']}');
      
      if (status['stats'] != null && (status['stats'] as Map).isNotEmpty) {
        print('\nStatistics:');
        (status['stats'] as Map).forEach((key, value) {
          print('  $key: $value');
        });
      }
      
    } catch (e) {
      print('❌ Error getting status: $e');
      exit(1);
    }
  }
  
  /// Show migration logs
  static Future<void> _showLogs() async {
    try {
      final migrationService = AnalyticsMigrationService.instance;
      final logs = migrationService.getMigrationLogs();
      
      if (logs.isEmpty) {
        print('No migration logs available.');
        return;
      }
      
      print('Migration Logs (${logs.length} entries):');
      print('-' * 50);
      
      for (final log in logs) {
        print(log);
      }
      
    } catch (e) {
      print('❌ Error getting logs: $e');
      exit(1);
    }
  }
  
  /// Parse command-line options
  static Map<String, dynamic> _parseOptions(List<String> args) {
    final options = <String, dynamic>{};
    
    for (final arg in args) {
      if (arg.startsWith('--')) {
        final parts = arg.substring(2).split('=');
        final key = parts[0];
        final value = parts.length > 1 ? parts[1] : true;
        
        // Handle special cases
        switch (key) {
          case 'companies':
            options[key] = value.toString().split(',');
            break;
          case 'dry-run':
          case 'skip-validation':
          case 'force':
            options[key] = value == true || value == 'true';
            break;
          default:
            options[key] = value;
        }
      }
    }
    
    return options;
  }
  
  /// Print usage information
  static void _printUsage() {
    print('''
Usage: dart analytics_migration_cli.dart <command> [options]

Commands:
  migrate     Execute analytics migration
  validate    Validate migration without executing
  rollback    Rollback a migration
  status      Show current migration status
  logs        Show migration logs
  help        Show this help message

Options:
  --dry-run              Run migration validation only
  --companies=id1,id2    Migrate specific companies only
  --skip-validation      Skip post-migration validation
  --migration-id=<id>    Migration ID for rollback
  --force                Force operation without confirmation

Examples:
  # Validate migration
  dart analytics_migration_cli.dart validate

  # Execute full migration
  dart analytics_migration_cli.dart migrate

  # Execute dry run
  dart analytics_migration_cli.dart migrate --dry-run

  # Migrate specific companies
  dart analytics_migration_cli.dart migrate --companies=company1,company2

  # Rollback migration
  dart analytics_migration_cli.dart rollback --migration-id=migration_1234567890

  # Show status
  dart analytics_migration_cli.dart status

  # Show logs
  dart analytics_migration_cli.dart logs

Migration Process:
1. Pre-Migration Validation - Checks data integrity and prerequisites
2. Schema Preparation - Creates analytics subcollections
3. Data Migration - Migrates historical data
4. Post-Migration Validation - Verifies migrated data
5. Analytics Initialization - Initializes analytics services

Safety Features:
- Dry run mode for testing
- Comprehensive validation
- Detailed logging
- Rollback capability
- Progress monitoring

For more information, see the migration documentation.
''');
  }
}

/// Migration monitoring widget for Flutter apps
class MigrationMonitorWidget extends StatefulWidget {
  const MigrationMonitorWidget({super.key});

  @override
  State<MigrationMonitorWidget> createState() => _MigrationMonitorWidgetState();
}

class _MigrationMonitorWidgetState extends State<MigrationMonitorWidget> {
  final AnalyticsMigrationService _migrationService = AnalyticsMigrationService.instance;
  Timer? _statusTimer;
  Map<String, dynamic> _status = {};
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _startStatusMonitoring();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusMonitoring() {
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _updateStatus();
    });
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _status = _migrationService.getMigrationStatus();
      _logs = _migrationService.getMigrationLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Migration Monitor'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migration Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _status['inProgress'] == true ? Icons.sync : Icons.check_circle,
                          color: _status['inProgress'] == true ? DesignTokens.statusPending : DesignTokens.statusConfirmed,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _status['inProgress'] == true ? 'In Progress' : 'Idle',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    if (_status['currentMigrationId'] != null) ...[
                      const SizedBox(height: 8),
                      Text('Migration ID: ${_status['currentMigrationId']}'),
                    ],
                    const SizedBox(height: 8),
                    Text('Log Entries: ${_status['logCount'] ?? 0}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistics Card
            if (_status['stats'] != null && (_status['stats'] as Map).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...(_status['stats'] as Map).entries.map((entry) =>
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key.toString()),
                              Text(entry.value.toString()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Logs Section
            Text(
              'Migration Logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Card(
                child: _logs.isEmpty
                    ? const Center(
                        child: Text('No logs available'),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[_logs.length - 1 - index]; // Reverse order
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Text(
                              log,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
