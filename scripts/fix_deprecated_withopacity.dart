#!/usr/bin/env dart
// Automated script to replace deprecated .withOpacity() calls with .withValues(alpha:)
// This fixes Flutter Material Design 3 deprecation warnings

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 Starting deprecated .withOpacity() to .withValues(alpha:) migration...');
  
  final libDir = Directory('./lib');
  if (!libDir.existsSync()) {
    print('❌ Error: lib directory not found. Please run from project root.');
    exit(1);
  }

  int totalFiles = 0;
  int modifiedFiles = 0;
  int totalReplacements = 0;

  await for (final FileSystemEntity entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFiles++;
      final result = await processFile(entity);
      if (result.modified) {
        modifiedFiles++;
        totalReplacements += result.replacements;
        print('✅ Fixed ${result.replacements} occurrences in ${entity.path}');
      }
    }
  }

  print('');
  print('🎉 Migration completed!');
  print('📊 Statistics:');
  print('   - Total files checked: $totalFiles');
  print('   - Files modified: $modifiedFiles');
  print('   - Total replacements: $totalReplacements');
  print('');
  
  if (totalReplacements > 0) {
    print('✨ All deprecated .withOpacity() calls have been replaced with .withValues(alpha:)');
    print('🔥 Your app now uses the latest Flutter Material Design 3 APIs!');
  } else {
    print('ℹ️  No deprecated .withOpacity() calls found to replace.');
  }
}

class ProcessResult {
  final bool modified;
  final int replacements;
  
  ProcessResult(this.modified, this.replacements);
}

Future<ProcessResult> processFile(File file) async {
  try {
    final content = await file.readAsString();
    
    // Pattern to match .withOpacity(numeric_value)
    final withOpacityPattern = RegExp(r'\.withOpacity\(([0-9]*\.?[0-9]+)\)');
    
    if (!withOpacityPattern.hasMatch(content)) {
      return ProcessResult(false, 0);
    }

    final matches = withOpacityPattern.allMatches(content);
    final newContent = content.replaceAllMapped(withOpacityPattern, (match) {
      final opacityValue = match.group(1);
      return '.withValues(alpha: $opacityValue)';
    });

    await file.writeAsString(newContent);
    return ProcessResult(true, matches.length);
    
  } catch (e) {
    print('⚠️  Warning: Could not process ${file.path}: $e');
    return ProcessResult(false, 0);
  }
}