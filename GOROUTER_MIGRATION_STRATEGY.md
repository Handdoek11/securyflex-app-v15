// navigator_migration_script.dart
// Automated Navigator 1.0 to GoRouter 2.0 migration script

import 'dart:io';

void main() async {
  print('🚀 Starting Navigator 1.0 to GoRouter 2.0 migration...');
  
  await migrateNavigatorPatterns();
  await addRequiredImports();
  await validateMigration();
  
  print('✅ Migration completed! Run flutter analyze to check for issues.');
}

Future<void> migrateNavigatorPatterns() async {
  final libDir = Directory('./lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  for (final file in dartFiles) {
    await migrateFile(file);
  }
}

Future<void> migrateFile(File file) async {
  String content = await file.readAsString();
  String originalContent = content;
  
  // Skip already converted files
  if (content.contains('// 🚀 CONVERTED')) {
    return;
  }
  
  print('🔄 Migrating: ${file.path}');
  
  // Pattern 1: Simple Navigator.pop() replacements
  content = content.replaceAllMapped(
    RegExp(r'Navigator\.of\(context\)\.pop\(\)'),
    (match) => 'context.pop() // 🚀 CONVERTED: Navigator.of(context).pop() → context.pop()'
  );
  
  content = content.replaceAllMapped(
    RegExp(r'Navigator\.pop\(context\)'),
    (match) => 'context.pop() // 🚀 CONVERTED: Navigator.pop() → context.pop()'
  );
  
  content = content.replaceAllMapped(
    RegExp(r'Navigator\.pop\(context,\s*([^)]+)\)'),
    (match) => 'context.pop(${match.group(1)}) // 🚀 CONVERTED: Navigator.pop() → context.pop()'
  );
  
  // Pattern 2: Navigator.pushNamed() replacements
  content = content.replaceAllMapped(
    RegExp(r'Navigator\.pushNamed\(context,\s*[\'"]([^\'"]+)[\'"]\)'),
    (match) => 'context.push(\'${match.group(1)}\') // 🚀 CONVERTED: Navigator.pushNamed() → context.push()'
  );
  
  // Add import if changes were made
  if (content != originalContent && !content.contains('import \'package:go_router/go_router.dart\'')) {
    content = content.replaceFirst(
      "import 'package:flutter/material.dart';",
      "import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';"
    );
  }
  
  // Write changes if any were made
  if (content != originalContent) {
    await file.writeAsString(content);
    print('✅ Updated: ${file.path}');
  }
}

Future<void> addRequiredImports() async {
  print('📦 Adding required imports...');
  // Implementation for adding go_router imports where needed
}

Future<void> validateMigration() async {
  print('🔍 Validating migration...');
  
  final result = await Process.run('flutter', ['analyze']);
  if (result.exitCode != 0) {
    print('❌ Flutter analyze found issues:');
    print(result.stdout);
    print(result.stderr);
  } else {
    print('✅ Flutter analyze passed!');
  }
}