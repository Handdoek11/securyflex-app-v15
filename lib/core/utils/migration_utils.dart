import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unified_design_tokens.dart';

/// Migration utilities for transitioning from legacy state management to BLoC
/// Provides feature flags, parallel implementation support, and migration tracking
class MigrationUtils {
  static const String _migrationPrefix = 'migration_';
  static const String _featureFlagPrefix = 'feature_flag_';
  
  /// Feature flags for gradual BLoC migration
  static const String authBlocEnabled = 'auth_bloc_enabled';
  static const String jobBlocEnabled = 'job_bloc_enabled';
  static const String dashboardBlocEnabled = 'dashboard_bloc_enabled';
  static const String planningBlocEnabled = 'planning_bloc_enabled';
  static const String profileBlocEnabled = 'profile_bloc_enabled';
  
  /// Migration phases
  static const String phase1Foundation = 'phase_1_foundation';
  static const String phase2Auth = 'phase_2_auth';
  static const String phase3Marketplace = 'phase_3_marketplace';
  static const String phase4Dashboard = 'phase_4_dashboard';
  static const String phase5Planning = 'phase_5_planning';
  static const String phase6Profile = 'phase_6_profile';
  static const String phase7CrossBloc = 'phase_7_cross_bloc';
  static const String phase8Testing = 'phase_8_testing';
  
  /// Check if a feature flag is enabled
  static Future<bool> isFeatureEnabled(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_featureFlagPrefix$featureName') ?? false;
  }
  
  /// Enable a feature flag
  static Future<void> enableFeature(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_featureFlagPrefix$featureName', true);
    debugPrint('🟢 Feature enabled: $featureName');
  }
  
  /// Disable a feature flag
  static Future<void> disableFeature(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_featureFlagPrefix$featureName', false);
    debugPrint('🔴 Feature disabled: $featureName');
  }
  
  /// Mark a migration phase as completed
  static Future<void> markPhaseCompleted(String phaseName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_migrationPrefix$phaseName', true);
    await prefs.setString('$_migrationPrefix${phaseName}_completed_at',
                         DateTime.now().toIso8601String());
    debugPrint('✅ Migration phase completed: $phaseName');
  }
  
  /// Check if a migration phase is completed
  static Future<bool> isPhaseCompleted(String phaseName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_migrationPrefix$phaseName') ?? false;
  }
  
  /// Get migration progress percentage
  static Future<double> getMigrationProgress() async {
    final phases = [
      phase1Foundation,
      phase2Auth,
      phase3Marketplace,
      phase4Dashboard,
      phase5Planning,
      phase6Profile,
      phase7CrossBloc,
      phase8Testing,
    ];
    
    int completedPhases = 0;
    for (final phase in phases) {
      if (await isPhaseCompleted(phase)) {
        completedPhases++;
      }
    }
    
    return completedPhases / phases.length;
  }
  
  /// Get migration status summary
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    final progress = await getMigrationProgress();
    final phases = [
      phase1Foundation,
      phase2Auth,
      phase3Marketplace,
      phase4Dashboard,
      phase5Planning,
      phase6Profile,
      phase7CrossBloc,
      phase8Testing,
    ];
    
    final phaseStatus = <String, bool>{};
    for (final phase in phases) {
      phaseStatus[phase] = await isPhaseCompleted(phase);
    }
    
    return {
      'progress': progress,
      'progressPercentage': (progress * 100).round(),
      'phases': phaseStatus,
      'isComplete': progress >= 1.0,
    };
  }
  
  /// Reset all migration flags (for testing)
  static Future<void> resetMigration() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
        key.startsWith(_migrationPrefix) || key.startsWith(_featureFlagPrefix));
    
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    debugPrint('🔄 Migration flags reset');
  }
  
  /// Enable all features for testing
  static Future<void> enableAllFeatures() async {
    await enableFeature(authBlocEnabled);
    await enableFeature(jobBlocEnabled);
    await enableFeature(dashboardBlocEnabled);
    await enableFeature(planningBlocEnabled);
    await enableFeature(profileBlocEnabled);
    debugPrint('🟢 All features enabled for testing');
  }
  
  /// Disable all features (rollback)
  static Future<void> disableAllFeatures() async {
    await disableFeature(authBlocEnabled);
    await disableFeature(jobBlocEnabled);
    await disableFeature(dashboardBlocEnabled);
    await disableFeature(planningBlocEnabled);
    await disableFeature(profileBlocEnabled);
    debugPrint('🔴 All features disabled (rollback)');
  }
  
  /// Log migration event for analytics
  static void logMigrationEvent(String event, Map<String, dynamic>? parameters) {
    debugPrint('📊 Migration Event: $event');
    if (parameters != null) {
      debugPrint('   Parameters: $parameters');
    }
    
    // TODO: Send to Firebase Analytics
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'migration_event',
    //   parameters: {
    //     'event': event,
    //     'timestamp': DateTime.now().millisecondsSinceEpoch,
    //     ...?parameters,
    //   },
    // );
  }
}

/// Widget wrapper for feature flag-based conditional rendering
class FeatureFlag extends StatelessWidget {
  final String featureName;
  final Widget enabledChild;
  final Widget disabledChild;
  final bool defaultValue;
  
  const FeatureFlag({
    super.key,
    required this.featureName,
    required this.enabledChild,
    required this.disabledChild,
    this.defaultValue = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: MigrationUtils.isFeatureEnabled(featureName),
      initialData: defaultValue,
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? defaultValue;
        return isEnabled ? enabledChild : disabledChild;
      },
    );
  }
}

/// Widget wrapper for parallel BLoC/Legacy implementation
class ParallelImplementation<T extends BlocBase> extends StatelessWidget {
  final String featureName;
  final T Function() createBloc;
  final Widget Function(BuildContext context) blocBuilder;
  final Widget Function(BuildContext context) legacyBuilder;
  final bool defaultUseBloC;
  
  const ParallelImplementation({
    super.key,
    required this.featureName,
    required this.createBloc,
    required this.blocBuilder,
    required this.legacyBuilder,
    this.defaultUseBloC = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: MigrationUtils.isFeatureEnabled(featureName),
      initialData: defaultUseBloC,
      builder: (context, snapshot) {
        final useBloC = snapshot.data ?? defaultUseBloC;
        
        if (useBloC) {
          return BlocProvider<T>(
            create: (context) => createBloc(),
            child: Builder(builder: blocBuilder),
          );
        } else {
          return Builder(builder: legacyBuilder);
        }
      },
    );
  }
}

/// Migration progress indicator widget
class MigrationProgressIndicator extends StatelessWidget {
  final bool showDetails;
  
  const MigrationProgressIndicator({
    super.key,
    this.showDetails = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: MigrationUtils.getMigrationStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final status = snapshot.data!;
        final progress = status['progress'] as double;
        final percentage = status['progressPercentage'] as int;
        
        return Card(
          elevation: 2.0,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BLoC Migration Progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? DesignTokens.statusConfirmed : DesignTokens.statusAccepted,
                  ),
                ),
                const SizedBox(height: 8),
                Text('$percentage% Complete'),
                if (showDetails) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Phase Status:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ..._buildPhaseStatus(status['phases'] as Map<String, bool>),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<Widget> _buildPhaseStatus(Map<String, bool> phases) {
    return phases.entries.map((entry) {
      final phaseName = entry.key.replaceAll('_', ' ').toUpperCase();
      final isCompleted = entry.value;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? DesignTokens.statusConfirmed : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              phaseName,
              style: TextStyle(
                color: isCompleted ? DesignTokens.statusConfirmed : Colors.grey,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Development tools for migration testing
class MigrationDevTools {
  /// Show migration debug panel
  static void showDebugPanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _MigrationDebugDialog(),
    );
  }
}

class _MigrationDebugDialog extends StatefulWidget {
  const _MigrationDebugDialog();
  
  @override
  State<_MigrationDebugDialog> createState() => _MigrationDebugDialogState();
}

class _MigrationDebugDialogState extends State<_MigrationDebugDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Migration Debug Tools'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MigrationProgressIndicator(showDetails: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await MigrationUtils.enableAllFeatures();
                setState(() {});
              },
              child: const Text('Enable All Features'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await MigrationUtils.disableAllFeatures();
                setState(() {});
              },
              child: const Text('Disable All Features'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await MigrationUtils.resetMigration();
                setState(() {});
              },
              child: const Text('Reset Migration'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
