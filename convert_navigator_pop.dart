import 'dart:io';

void main() async {
  print('🚀 Starting Navigator.pop to context.pop conversion...\n');
  
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib directory not found!');
    return;
  }
  
  int totalFilesProcessed = 0;
  int totalReplacements = 0;
  
  // Files to convert based on audit
  final filesToConvert = [
    'lib/beveiliger_notificaties/screens/notification_preferences_screen.dart',
    'lib/chat/screens/enhanced_chat_screen.dart',
    'lib/chat/screens/chat_screen.dart',
    'lib/schedule/architecture/schedule_data_flow.dart',
    'lib/marketplace/widgets/application_tracker.dart',
    'lib/marketplace/tabs/applications_tab.dart',
    'lib/billing/screens/subscription_management_screen.dart',
    'lib/billing/screens/subscription_upgrade_screen.dart',
    'lib/chat/screens/chat_screen_demo.dart',
    'lib/chat/screens/notification_settings_screen.dart',
    'lib/workflow/widgets/workflow_status_widget.dart',
    'lib/unified_components/expandable_text.dart',
    'lib/marketplace/widgets/favorites_list.dart',
    'lib/marketplace/calendar_popup_view.dart',
    'lib/marketplace/tabs/job_history_tab.dart',
  ];
  
  for (final filePath in filesToConvert) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  File not found: $filePath');
      continue;
    }
    
    String content = await file.readAsString();
    String originalContent = content;
    
    // Check if go_router import exists, if not add it
    if (!content.contains("import 'package:go_router/go_router.dart';")) {
      // Find the last import statement
      final importRegex = RegExp(r'^import\s+[\'""].*[\'""];', multiLine: true);
      final matches = importRegex.allMatches(content).toList();
      if (matches.isNotEmpty) {
        final lastImport = matches.last;
        content = content.substring(0, lastImport.end) +
            "\nimport 'package:go_router/go_router.dart';" +
            content.substring(lastImport.end);
      }
    }
    
    // Replace Navigator.pop patterns
    final patterns = [
      // Navigator.pop(context) -> context.pop()
      RegExp(r'Navigator\.pop\(context\)'),
      // Navigator.pop(context, value) -> context.pop(value)
      RegExp(r'Navigator\.pop\(context,\s*([^)]+)\)'),
      // Navigator.of(context).pop() -> context.pop()
      RegExp(r'Navigator\.of\(context\)\.pop\(\)'),
      // Navigator.of(context).pop(value) -> context.pop(value)
      RegExp(r'Navigator\.of\(context\)\.pop\(([^)]+)\)'),
    ];
    
    int fileReplacements = 0;
    
    // Pattern 1: Navigator.pop(context)
    content = content.replaceAllMapped(patterns[0], (match) {
      fileReplacements++;
      return 'context.pop()';
    });
    
    // Pattern 2: Navigator.pop(context, value)
    content = content.replaceAllMapped(patterns[1], (match) {
      fileReplacements++;
      return 'context.pop(${match.group(1)})';
    });
    
    // Pattern 3: Navigator.of(context).pop()
    content = content.replaceAllMapped(patterns[2], (match) {
      fileReplacements++;
      return 'context.pop()';
    });
    
    // Pattern 4: Navigator.of(context).pop(value)
    content = content.replaceAllMapped(patterns[3], (match) {
      fileReplacements++;
      return 'context.pop(${match.group(1)})';
    });
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('✅ Converted $filePath - $fileReplacements replacements');
      totalFilesProcessed++;
      totalReplacements += fileReplacements;
    }
  }
  
  print('\n📊 Conversion Summary:');
  print('   Files processed: $totalFilesProcessed');
  print('   Total replacements: $totalReplacements');
  print('   ✅ Navigator.pop conversion complete!\n');
}