// navigator_migration_script.dart
// Automated Navigator 1.0 to GoRouter 2.0 migration script
// Run with: dart navigator_migration_script.dart

import 'dart:io';
import 'dart:async';

class NavigatorMigrationTool {
  static const Map<String, String> conversionPatterns = {
    // Simple pop operations - Safe for automation
    r'Navigator\.pop\(context\)': 'context.pop() // 🚀 CONVERTED: Navigator.pop → context.pop',
    r'Navigator\.of\(context\)\.pop\(\)': 'context.pop() // 🚀 CONVERTED: Navigator.of(context).pop → context.pop',
    
    // Pop with parameters - Safe for automation  
    r'Navigator\.pop\(context,\s*([^)]+)\)': 'context.pop(\$1) // 🚀 CONVERTED: Navigator.pop → context.pop',
    r'Navigator\.of\(context\)\.pop\(([^)]+)\)': 'context.pop(\$1) // 🚀 CONVERTED: Navigator.of(context).pop → context.pop',
    
    // Named route navigation - Safe for automation
    r"Navigator\.pushNamed\(context,\s*['\"]([^'\"]+)['\"]\)": 'context.push(\'\$1\') // 🚀 CONVERTED: Navigator.pushNamed → context.push',
    
    // Stack clearing operations - Safe for automation
    r"Navigator\.of\(context\)\.pushNamedAndRemoveUntil\(['\"]([^'\"]+)['\"],\s*\([^)]*\)\s*=>\s*false\)": 'context.go(\'\$1\') // 🚀 CONVERTED: Navigator.pushNamedAndRemoveUntil → context.go (clears stack)',
    r"Navigator\.pushNamedAndRemoveUntil\(context,\s*['\"]([^'\"]+)['\"],\s*\([^)]*\)\s*=>\s*false\)": 'context.go(\'\$1\') // 🚀 CONVERTED: Navigator.pushNamedAndRemoveUntil → context.go (clears stack)',
  };
  
  static const Map<String, String> manualPatterns = {
    // Patterns that need manual review
    r'Navigator\.of\(context\)\.push\(': 'MANUAL_REVIEW: Navigator.of(context).push → context.push (needs route definition)',
    r'Navigator\.push\(': 'MANUAL_REVIEW: Navigator.push → context.push (needs route definition)',
    r'MaterialPageRoute': 'MANUAL_REVIEW: MaterialPageRoute → GoRoute definition needed',
    r'CupertinoPageRoute': 'MANUAL_REVIEW: CupertinoPageRoute → GoRoute definition needed',
    r'PageRouteBuilder': 'MANUAL_REVIEW: PageRouteBuilder → GoRoute with custom transition',
  };
  
  static int _totalFiles = 0;
  static int _migratedFiles = 0;
  static int _automaticConversions = 0;
  static int _manualReviewsNeeded = 0;
  static List<String> _manualReviewFiles = [];
  
  static Future<void> main() async {
    print('🚀 Starting Navigator 1.0 to GoRouter 2.0 migration...');
    print('=' * 60);
    
    await _analyzeCurrentState();
    await _migrateAllFiles();
    await _generateReport();
    await _validateMigration();
    
    print('\n✅ Migration process completed!');
    print('📋 Check the migration report above for next steps.');
  }
  
  static Future<void> _analyzeCurrentState() async {
    print('🔍 Analyzing current Navigator usage...');
    
    final libDir = Directory('./lib');
    if (!await libDir.exists()) {
      print('❌ ./lib directory not found. Run from project root.');
      exit(1);
    }
    
    int totalNavigatorInstances = 0;
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        _totalFiles++;
        final content = await entity.readAsString();
        final navigatorMatches = RegExp(r'Navigator\.').allMatches(content);
        totalNavigatorInstances += navigatorMatches.length;
      }
    }
    
    print('📊 Found $_totalFiles Dart files');
    print('📊 Found $totalNavigatorInstances Navigator instances');
    print('');
  }
  
  static Future<void> _migrateAllFiles() async {
    final libDir = Directory('./lib');
    
    print('🔄 Starting automated migration...');
    print('');
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _migrateFile(entity);
      }
    }
  }
  
  static Future<void> _migrateFile(File file) async {
    String content = await file.readAsString();
    String originalContent = content;
    
    // Skip already converted files
    if (content.contains('// 🚀 CONVERTED')) {
      return;
    }
    
    // Skip files without Navigator usage
    if (!content.contains('Navigator.')) {
      return;
    }
    
    bool hasChanges = false;
    bool needsManualReview = false;
    
    // Apply automatic conversion patterns
    for (final entry in conversionPatterns.entries) {
      final regex = RegExp(entry.key);
      if (regex.hasMatch(content)) {
        content = content.replaceAllMapped(regex, (match) {
          _automaticConversions++;
          hasChanges = true;
          return entry.value;
        });
      }
    }
    
    // Check for patterns needing manual review
    for (final entry in manualPatterns.entries) {
      final regex = RegExp(entry.key);
      if (regex.hasMatch(content)) {
        needsManualReview = true;
        _manualReviewsNeeded++;
        
        // Add comment for manual review
        content = content.replaceAllMapped(regex, (match) {
          return '${match.group(0)} // ⚠️ ${entry.value}';
        });
      }
    }
    
    // Add go_router import if changes were made
    if (hasChanges && !content.contains('go_router/go_router.dart')) {
      content = _addGoRouterImport(content);
    }
    
    // Write changes if any were made
    if (content != originalContent) {
      await file.writeAsString(content);
      _migratedFiles++;
      
      print('✅ ${hasChanges ? "Migrated" : "Marked"}: ${file.path}');
      
      if (needsManualReview) {
        _manualReviewFiles.add(file.path);
        print('   ⚠️  Manual review needed');
      }
    }
  }
  
  static String _addGoRouterImport(String content) {
    // Find the first import statement and add go_router after it
    final importRegex = RegExp(r"import 'package:flutter/material\.dart';");
    if (importRegex.hasMatch(content)) {
      return content.replaceFirst(
        importRegex,
        "import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';"
      );
    }
    
    // Fallback: add at the beginning if no material import found
    if (content.startsWith('import')) {
      final firstImport = content.indexOf('\n');
      return content.substring(0, firstImport + 1) + 
             "import 'package:go_router/go_router.dart';\n" +
             content.substring(firstImport + 1);
    }
    
    return "import 'package:go_router/go_router.dart';\n" + content;
  }
  
  static Future<void> _generateReport() async {
    print('\n📋 MIGRATION REPORT');
    print('=' * 60);
    print('📊 Total Files Processed: $_totalFiles');
    print('✅ Files Modified: $_migratedFiles');
    print('🔄 Automatic Conversions: $_automaticConversions');
    print('⚠️  Manual Reviews Needed: $_manualReviewsNeeded');
    print('');
    
    if (_manualReviewFiles.isNotEmpty) {
      print('📝 FILES REQUIRING MANUAL REVIEW:');
      print('-' * 40);
      for (final file in _manualReviewFiles) {
        print('   • $file');
      }
      print('');
      print('🔍 Search for "⚠️ MANUAL_REVIEW" comments in these files');
      print('');
    }
    
    print('🎯 NEXT STEPS:');
    print('-' * 40);
    print('1. Review files marked for manual review');
    print('2. Add missing routes to app_routes.dart');
    print('3. Update app_router.dart with new route definitions');
    print('4. Run: flutter analyze');
    print('5. Run: flutter test');
    print('6. Test critical navigation flows manually');
    print('');
  }
  
  static Future<void> _validateMigration() async {
    print('🔍 Running validation checks...');
    print('');
    
    // Check for remaining unconverted Navigator instances
    int remainingNavigator = 0;
    final libDir = Directory('./lib');
    
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final content = await entity.readAsString();
        final navigatorMatches = RegExp(r'Navigator\.').allMatches(content);
        final convertedMatches = RegExp(r'// 🚀 CONVERTED').allMatches(content);
        final manualMatches = RegExp(r'// ⚠️').allMatches(content);
        
        remainingNavigator += (navigatorMatches.length - convertedMatches.length - manualMatches.length);
      }
    }
    
    print('📊 Remaining unconverted Navigator instances: $remainingNavigator');
    
    if (remainingNavigator == 0) {
      print('✅ All Navigator instances have been processed!');
    } else {
      print('⚠️  Some Navigator instances may need attention');
    }
    
    // Try to run flutter analyze
    try {
      print('🔍 Running flutter analyze...');
      final result = await Process.run('flutter', ['analyze']);
      
      if (result.exitCode == 0) {
        print('✅ Flutter analyze passed!');
      } else {
        print('⚠️  Flutter analyze found issues:');
        print(result.stdout);
        if (result.stderr.isNotEmpty) {
          print('Errors:');
          print(result.stderr);
        }
      }
    } catch (e) {
      print('⚠️  Could not run flutter analyze: $e');
    }
  }
}

void main() async {
  try {
    await NavigatorMigrationTool.main();
  } catch (e, stackTrace) {
    print('❌ Migration failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}