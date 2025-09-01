// run_migration.dart  
// Execute the complete GoRouter migration process

import 'dart:io';

void main() async {
  print('🚀 SECURYFLEX GOROUTER MIGRATION');
  print('=' * 50);
  
  // Step 1: Run migration script
  print('\n📋 Step 1: Running automated migration script...');
  await _runMigrationScript();
  
  // Step 2: Update critical files manually
  print('\n📋 Step 2: Applying critical file fixes...');
  await _applyCriticalFixes();
  
  // Step 3: Validate migration
  print('\n📋 Step 3: Validating migration...');
  await _validateMigration();
  
  // Step 4: Show next steps
  print('\n📋 Step 4: Next steps...');
  _showNextSteps();
}

Future<void> _runMigrationScript() async {
  try {
    final result = await Process.run('dart', ['navigator_migration_script.dart']);
    print(result.stdout);
    if (result.stderr.isNotEmpty) {
      print('Warnings/Errors:');
      print(result.stderr);
    }
  } catch (e) {
    print('❌ Failed to run migration script: $e');
  }
}

Future<void> _applyCriticalFixes() async {
  final criticalFiles = [
    './lib/beveiliger_dashboard/modern_beveiliger_dashboard_v2.dart',
    './lib/beveiliger_profiel/screens/beveiliger_profiel_screen.dart',
    './lib/chat/screens/chat_screen.dart',
    './lib/beveiliger_notificaties/screens/notification_preferences_screen.dart',
    './lib/marketplace/screens/jobs_tab_screen.dart',
  ];
  
  for (final filePath in criticalFiles) {
    await _fixCriticalFile(filePath);
  }
}

Future<void> _fixCriticalFile(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    print('⚠️  File not found: $filePath');
    return;
  }
  
  String content = await file.readAsString();
  String originalContent = content;
  
  // Apply specific fixes for critical patterns
  
  // Fix 1: Replace Navigator.pushNamed with context.push
  content = content.replaceAllMapped(
    RegExp(r"Navigator\.pushNamed\(context,\s*['\"]([^'\"]+)['\"]\)"),
    (match) => "context.push('${match.group(1)}') // 🚀 CONVERTED: Navigator.pushNamed → context.push"
  );
  
  // Fix 2: Handle MaterialPageRoute conversions with TODO comments
  content = content.replaceAllMapped(
    RegExp(r'Navigator\.of\(context\)\.push\(\s*MaterialPageRoute'),
    (match) => '// TODO: Convert to context.push() with proper route\n    // ${match.group(0)}'
  );
  
  // Fix 3: Add go_router import if needed
  if (content != originalContent && !content.contains('go_router/go_router.dart')) {
    content = _addGoRouterImport(content);
  }
  
  if (content != originalContent) {
    await file.writeAsString(content);
    print('✅ Fixed critical patterns in: $filePath');
  }
}

String _addGoRouterImport(String content) {
  return content.replaceFirst(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';"
  );
}

Future<void> _validateMigration() async {
  // Count remaining Navigator instances
  try {
    final result = await Process.run('grep', [
      '-r', 'Navigator\\.', './lib', '--include=*.dart'
    ]);
    
    final lines = result.stdout.toString().split('\n');
    final unconvertedLines = lines.where((line) => 
      line.isNotEmpty && 
      !line.contains('// 🚀 CONVERTED') && 
      !line.contains('// TODO') &&
      !line.contains('// ⚠️')
    ).toList();
    
    print('📊 Remaining unconverted Navigator instances: ${unconvertedLines.length}');
    
    if (unconvertedLines.length > 0) {
      print('\n📝 Files with remaining instances:');
      final fileSet = <String>{};
      for (final line in unconvertedLines.take(10)) {
        final file = line.split(':')[0];
        fileSet.add(file);
      }
      for (final file in fileSet) {
        print('   • $file');
      }
      if (unconvertedLines.length > 10) {
        print('   ... and ${unconvertedLines.length - 10} more');
      }
    }
    
  } catch (e) {
    print('⚠️  Could not count Navigator instances: $e');
  }
  
  // Run flutter analyze
  try {
    print('\n🔍 Running flutter analyze...');
    final result = await Process.run('flutter', ['analyze']);
    if (result.exitCode == 0) {
      print('✅ Flutter analyze passed!');
    } else {
      print('⚠️  Flutter analyze issues found:');
      print(result.stdout);
    }
  } catch (e) {
    print('⚠️  Could not run flutter analyze: $e');
  }
}

void _showNextSteps() {
  print('🎯 NEXT STEPS TO COMPLETE MIGRATION:');
  print('-' * 40);
  print('');
  
  print('1. 📝 MANUAL REVIEW REQUIRED:');
  print('   • Search for "TODO: Convert to context.push()" comments');
  print('   • Search for "⚠️ MANUAL_REVIEW" comments');
  print('   • Replace MaterialPageRoute with proper routes');
  print('');
  
  print('2. 🔧 ADD MISSING ROUTES:');
  print('   • Update lib/routing/app_router.dart with new route definitions');
  print('   • Add screen imports for new routes');
  print('   • Configure route parameters and extras');
  print('');
  
  print('3. 🧪 TESTING:');
  print('   • Run: flutter test');
  print('   • Test critical navigation flows manually:');
  print('     - Login → Dashboard');
  print('     - Profile → Certificates');
  print('     - Job Discovery → Job Details');
  print('     - Chat → Conversations');
  print('');
  
  print('4. 📊 VALIDATION:');
  print('   • Ensure all Navigator instances are converted');
  print('   • Run: flutter analyze (should pass)');
  print('   • Performance test: memory usage <150MB');
  print('');
  
  print('5. 🚀 COMPLETION CRITERIA:');
  print('   • 0 Navigator.pop() instances remaining');
  print('   • 0 Navigator.push() instances remaining');
  print('   • 0 MaterialPageRoute for navigation');
  print('   • All tests pass');
  print('   • Core user journeys work');
  print('');
  
  print('📧 Run this script again to check progress!');
}