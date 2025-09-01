import 'dart:io';

void main() async {
  final files = [
    './lib/auth/profile_screen.dart',
    './lib/auth/widgets/certificate_dashboard.dart',
    './lib/auth/widgets/certificate_list_view.dart',
    './lib/auth/widgets/kvk_validation_widget.dart',
    './lib/auth/widgets/secure_bsn_display_widget.dart',
    './lib/beveiliger_dashboard/dialogs/status_selection_dialog.dart',
    './lib/beveiliger_dashboard/screens/daily_overview_screen.dart',
    './lib/beveiliger_dashboard/screens/my_applications_screen.dart',
    './lib/beveiliger_dashboard/widgets/compliance_status_widget.dart',
    './lib/beveiliger_dashboard/widgets/notification_badge_widget.dart',
    './lib/beveiliger_notificaties/screens/notification_center_screen.dart',
    './lib/beveiliger_notificaties/widgets/notification_item_widget.dart',
    './lib/beveiliger_profiel/screens/certificate_add_screen.dart',
    './lib/beveiliger_profiel/screens/profiel_edit_screen.dart',
    './lib/beveiliger_profiel/widgets/profile_image_widget.dart',
    './lib/beveiliger_profiel/widgets/specialisaties_widget.dart',
    './lib/chat/widgets/chat_input_demo.dart',
    './lib/chat/widgets/unified_attachment_picker.dart',
    './lib/company_dashboard/company_dashboard_home.dart',
    './lib/company_dashboard/screens/application_review_screen.dart',
    './lib/company_dashboard/screens/company_notifications_screen.dart',
    './lib/company_dashboard/screens/company_profile_screen.dart',
    './lib/company_dashboard/screens/job_posting_form_screen.dart',
    './lib/company_dashboard/widgets/bulk_job_management_widget.dart',
    './lib/company_dashboard/widgets/bulk_operations_toolbar.dart',
    './lib/company_dashboard/widgets/company_profile_overview.dart',
    './lib/company_dashboard/widgets/smart_job_creation_wizard.dart',
    './lib/legal/screens/terms_acceptance_screen.dart',
    './lib/marketplace/dialogs/application_dialog.dart',
    './lib/marketplace/dialogs/premium_application_dialog.dart',
    './lib/marketplace/screens/favorites_screen.dart',
    './lib/privacy/screens/privacy_dashboard_screen.dart',
    './lib/privacy/widgets/consent_management_section.dart',
    './lib/privacy/widgets/data_export_section.dart',
    './lib/schedule/widgets/calendar/shift_detail_popup.dart',
    './lib/schedule/widgets/time_clock_widget.dart',
    './lib/unified_dialog_system.dart',
    './lib/workflow/screens/job_completion_screen.dart',
  ];
  
  print('Starting Navigator.pop() replacement...');
  int totalReplacements = 0;
  
  for (String filePath in files) {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File not found: $filePath');
        continue;
      }
      
      String content = await file.readAsString();
      final originalContent = content;
      
      // Replace Navigator.of(context).pop() with context.pop()
      content = content.replaceAll('Navigator.of(context).pop()', 'context.pop()');
      
      // Also handle Navigator.of(context).pop(result) patterns
      final regex = RegExp(r'Navigator\.of\(context\)\.pop\((.*?)\)');
      content = content.replaceAllMapped(regex, (match) {
        final arg = match.group(1);
        if (arg != null && arg.trim().isNotEmpty) {
          return 'context.pop(${arg})';
        }
        return 'context.pop()';
      });
      
      if (content != originalContent) {
        await file.writeAsString(content);
        final replacements = originalContent.split('Navigator.of(context).pop').length - 1;
        totalReplacements += replacements;
        print('Updated $filePath ($replacements replacements)');
      }
    } catch (e) {
      print('Error processing $filePath: $e');
    }
  }
  
  print('\n✅ Navigator.pop() replacement complete!');
  print('Total replacements: $totalReplacements');
  print('\nNote: Remember to add "import \'package:go_router/go_router.dart\';" to files that need it.');
}