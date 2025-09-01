#!/usr/bin/env dart

/// Automated Hardcoded Color Replacement System
/// 
/// This script automatically replaces all hardcoded Colors.* and Color(0x*) 
/// references with appropriate DesignTokens equivalents across the entire codebase.
/// 
/// Features:
/// - Safe replacement with rollback capability
/// - Context-aware color mapping
/// - Backup generation before changes
/// - Validation and testing integration

import 'dart:io';

class AutomatedColorMigration {
  // Color mapping from hardcoded values to DesignTokens
  static const Map<String, String> colorMappings = {
    // Flutter Colors.* mappings
    'Colors.green': 'DesignTokens.statusConfirmed',
    'Colors.green[700]': 'DesignTokens.statusConfirmed',
    'Colors.green[50]': 'DesignTokens.statusCompleted',
    'Colors.grey[400]': 'DesignTokens.colorGray400',
    'Colors.grey[600]': 'DesignTokens.colorGray600',
    'Colors.red': 'DesignTokens.statusCancelled',
    'Colors.blue': 'DesignTokens.statusAccepted',
    'Colors.orange': 'DesignTokens.statusPending',
    'Colors.white': 'DesignTokens.colorWhite',
    'Colors.black': 'DesignTokens.colorBlack',
    'Colors.transparent': 'Colors.transparent', // Keep transparent
    
    // Common hex color patterns
    'Color(0xFF1E3A8A)': 'DesignTokens.colorPrimaryBlue',
    'Color(0xFF54D3C2)': 'DesignTokens.colorSecondaryTeal',
    'Color(0xFF10B981)': 'DesignTokens.colorSuccess',
    'Color(0xFFF59E0B)': 'DesignTokens.colorWarning',
    'Color(0xFFEF4444)': 'DesignTokens.colorError',
    'Color(0xFF3B82F6)': 'DesignTokens.colorPrimaryBlueLight',
    'Color(0xFFFFFFFF)': 'DesignTokens.colorWhite',
    'Color(0xFF000000)': 'DesignTokens.colorBlack',
    
    // Context-specific mappings
    'Theme.of(context).primaryColor': 'colorScheme.primary',
    'Theme.of(context).backgroundColor': 'colorScheme.surface',
    'Theme.of(context).scaffoldBackgroundColor': 'colorScheme.surfaceContainerHighest',
  };

  static const List<String> importStatements = [
    "import 'package:securyflex_app/unified_design_tokens.dart';",
    "import '../../unified_design_tokens.dart';",
    "import '../unified_design_tokens.dart';",
  ];

  static Future<void> main() async {
    print('🎨 Starting Automated Color Migration...');
    print('📁 Scanning project for hardcoded colors...\n');

    final projectRoot = Directory.current;
    final libDir = Directory('${projectRoot.path}/lib');
    
    if (!libDir.existsSync()) {
      print('❌ Error: lib directory not found');
      return;
    }

    // Create backup
    await _createBackup(libDir);
    
    // Scan and replace colors
    final results = await _scanAndReplace(libDir);
    
    // Generate report
    _generateReport(results);
    
    print('\n✅ Color migration completed successfully!');
    print('📊 Run `dart scripts/validate_migration.dart` to verify changes');
  }

  static Future<void> _createBackup(Directory libDir) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupDir = Directory('backups/color_migration_$timestamp');
    
    print('💾 Creating backup at ${backupDir.path}...');
    
    if (backupDir.existsSync()) {
      await backupDir.delete(recursive: true);
    }
    await backupDir.create(recursive: true);
    
    await _copyDirectory(libDir, Directory('${backupDir.path}/lib'));
    print('✅ Backup created successfully');
  }

  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    
    await for (final entity in source.list()) {
      if (entity is Directory) {
        final newDir = Directory('${destination.path}/${entity.uri.pathSegments.last}');
        await _copyDirectory(entity, newDir);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        final newFile = File('${destination.path}/${entity.uri.pathSegments.last}');
        await entity.copy(newFile.path);
      }
    }
  }

  static Future<MigrationResults> _scanAndReplace(Directory libDir) async {
    final results = MigrationResults();
    final dartFiles = <File>[];
    
    // Collect all Dart files
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
    
    print('📝 Processing ${dartFiles.length} Dart files...\n');
    
    for (final file in dartFiles) {
      final fileResult = await _processFile(file);
      results.addFileResult(fileResult);
      
      if (fileResult.changesCount > 0) {
        print('✅ ${file.path}: ${fileResult.changesCount} colors replaced');
      }
    }
    
    return results;
  }

  static Future<FileResult> _processFile(File file) async {
    final result = FileResult(file.path);
    
    try {
      final content = await file.readAsString();
      final originalContent = content;
      var modifiedContent = content;
      bool needsImport = false;
      bool hasImport = false;

      // Check if file already has DesignTokens import
      for (final import in importStatements) {
        if (content.contains(import)) {
          hasImport = true;
          break;
        }
      }

      // Replace colors
      for (final entry in colorMappings.entries) {
        final pattern = entry.key;
        final replacement = entry.value;
        
        if (modifiedContent.contains(pattern)) {
          modifiedContent = modifiedContent.replaceAll(pattern, replacement);
          result.addChange(pattern, replacement);
          
          if (replacement.startsWith('DesignTokens.')) {
            needsImport = true;
          }
        }
      }

      // Add import if needed and not already present
      if (needsImport && !hasImport) {
        final importToAdd = _determineCorrectImport(file.path);
        modifiedContent = _addImport(modifiedContent, importToAdd);
        result.addImport(importToAdd);
      }

      // Write changes if any were made
      if (modifiedContent != originalContent) {
        await file.writeAsString(modifiedContent);
        result.markAsChanged();
      }

    } catch (e) {
      result.addError('Failed to process file: $e');
    }
    
    return result;
  }

  static String _determineCorrectImport(String filePath) {
    final depth = filePath.split('/').where((part) => part != 'lib').length - 1;
    final prefix = '../' * depth;
    return "import '${prefix}unified_design_tokens.dart';";
  }

  static String _addImport(String content, String import) {
    final lines = content.split('\n');
    int insertIndex = 0;
    
    // Find the right place to insert (after existing imports)
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ')) {
        insertIndex = i + 1;
      } else if (lines[i].isEmpty && insertIndex > 0) {
        break;
      }
    }
    
    lines.insert(insertIndex, import);
    return lines.join('\n');
  }

  static void _generateReport(MigrationResults results) {
    final report = '''
📊 AUTOMATED COLOR MIGRATION REPORT
=====================================

📈 Summary:
- Files processed: ${results.totalFiles}
- Files modified: ${results.modifiedFiles}
- Total replacements: ${results.totalReplacements}
- Import statements added: ${results.importsAdded}

🔄 Most Common Replacements:
${results.getTopReplacements().map((r) => '  • ${r.from} → ${r.replacement} (${r.count}x)').join('\n')}

${results.errors.isNotEmpty ? '❌ Errors:\n${results.errors.map((e) => '  • $e').join('\n')}' : '✅ No errors encountered'}

📁 Modified Files:
${results.modifiedFilesList.map((f) => '  • $f').join('\n')}

🔧 Next Steps:
1. Run tests: flutter test
2. Run static analysis: flutter analyze
3. Visual verification: flutter run
4. Rollback if needed: dart scripts/rollback_migration.dart
''';

    print(report);
    
    // Save report to file
    final reportFile = File('migration_reports/color_migration_${DateTime.now().millisecondsSinceEpoch}.md');
    reportFile.createSync(recursive: true);
    reportFile.writeAsStringSync(report);
  }
}

class MigrationResults {
  final List<FileResult> fileResults = [];
  final List<String> errors = [];

  void addFileResult(FileResult result) {
    fileResults.add(result);
    errors.addAll(result.errors);
  }

  int get totalFiles => fileResults.length;
  int get modifiedFiles => fileResults.where((f) => f.wasChanged).length;
  int get totalReplacements => fileResults.fold(0, (sum, f) => sum + f.changesCount);
  int get importsAdded => fileResults.where((f) => f.importAdded.isNotEmpty).length;

  List<String> get modifiedFilesList => 
    fileResults.where((f) => f.wasChanged).map((f) => f.filePath).toList();

  List<ReplacementStats> getTopReplacements() {
    final stats = <String, ReplacementStats>{};
    
    for (final file in fileResults) {
      for (final change in file.changes) {
        final key = '${change.from} → ${change.to}';
        stats[key] ??= ReplacementStats(change.from, change.to, 0);
        stats[key]!.count++;
      }
    }
    
    final list = stats.values.toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list.take(10).toList();
  }
}

class FileResult {
  final String filePath;
  final List<ColorChange> changes = [];
  final List<String> errors = [];
  String importAdded = '';
  bool wasChanged = false;

  FileResult(this.filePath);

  void addChange(String from, String to) {
    changes.add(ColorChange(from, to));
  }

  void addError(String error) {
    errors.add(error);
  }

  void addImport(String import) {
    importAdded = import;
  }

  void markAsChanged() {
    wasChanged = true;
  }

  int get changesCount => changes.length;
}

class ColorChange {
  final String from;
  final String to;

  ColorChange(this.from, this.to);
}

class ReplacementStats {
  final String from;
  final String replacement;
  int count;

  ReplacementStats(this.from, this.replacement, this.count);
}

void main() async {
  await AutomatedColorMigration.main();
}