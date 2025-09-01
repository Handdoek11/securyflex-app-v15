// missing_route_definitions.dart
// Route definitions that need to be added to app_router.dart

// ADD THESE ROUTES TO lib/routing/app_router.dart

/*
Add these imports to the top of app_router.dart:
*/

// Billing & Payments
import '../billing/screens/payments_screen.dart';
import '../billing/screens/subscription_upgrade_screen.dart';
import '../billing/screens/subscription_management_screen.dart';

// Notifications  
import '../beveiliger_notificaties/screens/notification_center_screen.dart';
import '../beveiliger_notificaties/screens/notification_preferences_screen.dart';

// Profile & Certificates
import '../beveiliger_profiel/screens/certificate_add_screen.dart'; 
import '../beveiliger_profiel/screens/certificate_edit_screen.dart';
import '../beveiliger_profiel/screens/specializations_screen.dart';

// Chat Features
import '../chat/screens/file_preview_screen.dart';
import '../chat/screens/chat_settings_screen.dart';
import '../chat/demo/enhanced_message_bubble_demo.dart';
import '../chat/screens/chat_screen_demo.dart';

// Company Features  
import '../company_dashboard/screens/company_job_edit_screen.dart';
import '../company_dashboard/screens/application_review_screen.dart';

// Reviews
import '../reviews/screens/review_screen.dart';

// Schedule
import '../schedule/screens/schedule_edit_screen.dart';
import '../schedule/screens/availability_settings_screen.dart';

/*
Add these route definitions to the routes array in GoRouter():
*/

// Billing & Payments Routes
GoRoute(
  path: AppRoutes.payments,
  name: RouteNames.payments,
  builder: (context, state) => const PaymentsScreen(),
),
GoRoute(
  path: AppRoutes.subscriptionUpgrade,
  name: RouteNames.subscriptionUpgrade,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return SubscriptionUpgradeScreen(
      userId: extra?['userId'],
    );
  },
),
GoRoute(
  path: AppRoutes.subscriptionManagement,
  name: RouteNames.subscriptionManagement,
  builder: (context, state) => const SubscriptionManagementScreen(),
),

// Notification Routes
GoRoute(
  path: AppRoutes.notificationCenter,
  name: RouteNames.notificationCenter,
  builder: (context, state) => const NotificationCenterScreen(),
),
GoRoute(
  path: AppRoutes.notificationPreferences,
  name: RouteNames.notificationPreferences,
  builder: (context, state) => const NotificationPreferencesScreen(),
),

// Profile & Certificate Routes
GoRoute(
  path: AppRoutes.certificateAdd,
  name: RouteNames.certificateAdd,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return CertificateAddScreen(
      userId: extra?['userId'] ?? 'current-user-id',
      userRole: extra?['userRole'] ?? UserRole.guard,
    );
  },
),
GoRoute(
  path: AppRoutes.certificateEdit,
  name: RouteNames.certificateEdit,
  builder: (context, state) {
    final certificateId = state.pathParameters['certificateId']!;
    final extra = state.extra as Map<String, dynamic>?;
    return CertificateEditScreen(
      certificateId: certificateId,
      userId: extra?['userId'] ?? 'current-user-id',
    );
  },
),
GoRoute(
  path: AppRoutes.specializations,
  name: RouteNames.specializations,
  builder: (context, state) => const SpecializationsScreen(),
),

// Chat Feature Routes
GoRoute(
  path: AppRoutes.filePreview,
  name: RouteNames.filePreview,
  builder: (context, state) {
    final fileId = state.pathParameters['fileId']!;
    final extra = state.extra as Map<String, dynamic>?;
    return FilePreviewScreen(
      fileId: fileId,
      fileUrl: extra?['fileUrl'] ?? '',
      fileName: extra?['fileName'] ?? 'File',
    );
  },
),
GoRoute(
  path: AppRoutes.chatSettings,
  name: RouteNames.chatSettings,
  builder: (context, state) => const ChatSettingsScreen(),
),

// Company Routes
GoRoute(
  path: AppRoutes.companyJobEdit,
  name: RouteNames.companyJobEdit,
  builder: (context, state) {
    final jobId = state.pathParameters['jobId']!;
    return CompanyJobEditScreen(jobId: jobId);
  },
),
GoRoute(
  path: AppRoutes.applicationReview,
  name: RouteNames.applicationReview,
  builder: (context, state) {
    final applicationId = state.pathParameters['applicationId']!;
    return ApplicationReviewScreen(applicationId: applicationId);
  },
),

// Review Routes
GoRoute(
  path: AppRoutes.reviewScreen,
  name: RouteNames.reviewScreen,
  builder: (context, state) {
    final reviewId = state.pathParameters['reviewId']!;
    final extra = state.extra as Map<String, dynamic>?;
    return ReviewScreen(
      reviewId: reviewId,
      reviewData: extra?['reviewData'],
    );
  },
),

// Schedule Routes
GoRoute(
  path: AppRoutes.scheduleEdit,
  name: RouteNames.scheduleEdit,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>?;
    return ScheduleEditScreen(
      scheduleId: extra?['scheduleId'],
      initialDate: extra?['initialDate'],
    );
  },
),
GoRoute(
  path: AppRoutes.availabilitySettings,
  name: RouteNames.availabilitySettings,
  builder: (context, state) => const AvailabilitySettingsScreen(),
),

// Privacy Routes
GoRoute(
  path: AppRoutes.privacyDashboard,
  name: RouteNames.privacyDashboard,
  builder: (context, state) => const PrivacyDashboardScreen(),
),

// Demo Routes (for testing - can be removed in production)
GoRoute(
  path: AppRoutes.chatDemo,
  name: RouteNames.chatDemo,
  builder: (context, state) => const ChatScreenDemo(),
),
GoRoute(
  path: AppRoutes.messageBubbleDemo,
  name: RouteNames.messageBubbleDemo,
  builder: (context, state) => const EnhancedMessageBubbleDemo(),
),

/*
USAGE EXAMPLES:

Instead of:
Navigator.pushNamed(context, '/payments');

Use:
context.push(AppRoutes.payments);

Instead of:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => SubscriptionUpgradeScreen(userId: userId)
  )
);

Use:
context.push(
  AppRoutes.subscriptionUpgrade,
  extra: {'userId': userId}
);

Instead of:
final result = await Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ReviewScreen(...))
);

Use:
final result = await context.push<bool>(
  AppRoutes.reviewScreen.replaceAll(':reviewId', reviewId),
  extra: {'reviewData': reviewData}
);
*/

/*
CRITICAL NOTES:

1. Some screen classes may not exist yet - create them or update imports
2. Parameter passing uses 'extra' - ensure screens handle this properly  
3. Path parameters use :paramName format - replace with actual values when navigating
4. Return types for dialogs/modals may need adjustment
5. Test each route after adding to ensure proper navigation

MISSING SCREEN FILES TO CREATE:

- PaymentsScreen (lib/billing/screens/payments_screen.dart)
- CertificateEditScreen (lib/beveiliger_profiel/screens/certificate_edit_screen.dart)
- SpecializationsScreen (lib/beveiliger_profiel/screens/specializations_screen.dart)
- FilePreviewScreen (lib/chat/screens/file_preview_screen.dart)
- ChatSettingsScreen (lib/chat/screens/chat_settings_screen.dart)
- CompanyJobEditScreen (lib/company_dashboard/screens/company_job_edit_screen.dart)
- ApplicationReviewScreen (lib/company_dashboard/screens/application_review_screen.dart)
- ReviewScreen (lib/reviews/screens/review_screen.dart)
- ScheduleEditScreen (lib/schedule/screens/schedule_edit_screen.dart)
- AvailabilitySettingsScreen (lib/schedule/screens/availability_settings_screen.dart)
*/