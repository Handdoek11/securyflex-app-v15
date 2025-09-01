// lib/routing/app_routes.dart

/// Route path constants voor SecuryFlex navigatie
class AppRoutes {
  // Root routes
  static const String root = '/';
  static const String splash = '/splash';
  
  // Authentication routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String termsAcceptance = '/terms';
  
  // Beveiliger (Security Guard) routes
  static const String beveiligerShell = '/beveiliger';
  static const String beveiligerDashboard = '/beveiliger/dashboard';
  static const String beveiligerProfile = '/beveiliger/profile';
  static const String beveiligerJobs = '/beveiliger/jobs';
  static const String beveiligerJobDetails = '/beveiliger/jobs/:jobId';
  static const String beveiligerSchedule = '/beveiliger/schedule';
  static const String beveiligerChat = '/beveiliger/chat';
  static const String beveiligerChatConversation = '/beveiliger/chat/:conversationId';
  static const String beveiligerNotifications = '/beveiliger/notifications';
  static const String beveiligerCertificates = '/beveiliger/certificates';
  static const String beveiligerApplications = '/beveiliger/applications';
  
  // Company routes
  static const String companyShell = '/company';
  static const String companyDashboard = '/company/dashboard';
  static const String companyProfile = '/company/profile';
  static const String companyJobs = '/company/jobs';
  static const String companyJobCreate = '/company/jobs/create';
  static const String companyJobDetails = '/company/jobs/:jobId';
  static const String companyApplications = '/company/applications';
  static const String companyApplicationDetails = '/company/applications/:applicationId';
  static const String companyTeam = '/company/team';
  static const String companyAnalytics = '/company/analytics';
  static const String companyChat = '/company/chat';
  static const String companyChatConversation = '/company/chat/:conversationId';
  static const String companyNotifications = '/company/notifications';
  static const String companyJobPosting = '/company/job-posting';
  static const String companyTeamManagement = '/company/team-management';
  
  // NEW ROUTES FOR NAVIGATION MIGRATION
  
  // Billing & Payments
  static const String payments = '/beveiliger/payments';
  static const String subscriptionUpgrade = '/subscription-upgrade'; 
  static const String subscriptionManagement = '/subscription-management';
  
  // Notifications
  static const String notificationCenter = '/notifications';
  static const String notificationPreferences = '/notifications/preferences';
  
  // Profile & Certificates
  static const String certificateAdd = '/beveiliger/certificates/add';
  static const String certificateEdit = '/beveiliger/certificates/:certificateId/edit';
  static const String specializations = '/beveiliger/specializations';
  
  // Reviews & Applications
  static const String reviewScreen = '/review/:reviewId';
  static const String applicationReview = '/company/applications/:applicationId/review';
  
  // Chat Features
  static const String filePreview = '/chat/file-preview/:fileId';
  static const String chatSettings = '/chat/settings';
  
  // Company Job Management
  static const String companyJobEdit = '/company/jobs/:jobId/edit';
  
  // Schedule & Planning
  static const String scheduleEdit = '/beveiliger/schedule/edit';
  static const String availabilitySettings = '/beveiliger/availability';
  
  // Demo Routes (for testing)
  static const String chatDemo = '/demo/chat';
  static const String messageBubbleDemo = '/demo/message-bubble';
  
  // Shared routes
  static const String help = '/help';
  static const String privacy = '/privacy';
  static const String privacyDashboard = '/privacy-dashboard';
  static const String settings = '/settings';
  
  // Error routes
  static const String notFound = '/404';
  static const String error = '/error';
  static const String unauthorized = '/unauthorized';
}

/// Named route identifiers for type-safe navigation
class RouteNames {
  // Root routes
  static const String root = 'root';
  static const String splash = 'splash';
  
  // Authentication routes
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot_password';
  static const String verifyEmail = 'verify_email';
  static const String termsAcceptance = 'terms';
  
  // Beveiliger routes
  static const String beveiligerShell = 'beveiliger_shell';
  static const String beveiligerDashboard = 'beveiliger_dashboard';
  static const String beveiligerProfile = 'beveiliger_profile';
  static const String beveiligerJobs = 'beveiliger_jobs';
  static const String beveiligerJobDetails = 'beveiliger_job_details';
  static const String beveiligerSchedule = 'beveiliger_schedule';
  static const String beveiligerChat = 'beveiliger_chat';
  static const String beveiligerChatConversation = 'beveiliger_chat_conversation';
  static const String beveiligerNotifications = 'beveiliger_notifications';
  static const String beveiligerCertificates = 'beveiliger_certificates';
  static const String beveiligerApplications = 'beveiliger_applications';
  
  // Company routes
  static const String companyShell = 'company_shell';
  static const String companyDashboard = 'company_dashboard';
  static const String companyProfile = 'company_profile';
  static const String companyJobs = 'company_jobs';
  static const String companyJobCreate = 'company_job_create';
  static const String companyJobDetails = 'company_job_details';
  static const String companyApplications = 'company_applications';
  static const String companyApplicationDetails = 'company_application_details';
  static const String companyTeam = 'company_team';
  static const String companyAnalytics = 'company_analytics';
  static const String companyChat = 'company_chat';
  static const String companyChatConversation = 'company_chat_conversation';
  static const String companyNotifications = 'company_notifications';
  static const String companyJobPosting = 'company_job_posting';
  static const String companyTeamManagement = 'company_team_management';
  
  // NEW ROUTE NAMES FOR MIGRATION
  
  // Billing & Payments
  static const String payments = 'payments';
  static const String subscriptionUpgrade = 'subscription_upgrade';
  static const String subscriptionManagement = 'subscription_management';
  
  // Notifications
  static const String notificationCenter = 'notification_center';
  static const String notificationPreferences = 'notification_preferences';
  
  // Profile & Certificates
  static const String certificateAdd = 'certificate_add';
  static const String certificateEdit = 'certificate_edit';
  static const String specializations = 'specializations';
  
  // Reviews & Applications
  static const String reviewScreen = 'review_screen';
  static const String applicationReview = 'application_review';
  
  // Chat Features
  static const String filePreview = 'file_preview';
  static const String chatSettings = 'chat_settings';
  
  // Company Job Management
  static const String companyJobEdit = 'company_job_edit';
  
  // Schedule & Planning
  static const String scheduleEdit = 'schedule_edit';
  static const String availabilitySettings = 'availability_settings';
  
  // Demo Routes
  static const String chatDemo = 'chat_demo';
  static const String messageBubbleDemo = 'message_bubble_demo';
  
  // Shared routes
  static const String help = 'help';
  static const String privacy = 'privacy';
  static const String privacyDashboard = 'privacy_dashboard';
  static const String settings = 'settings';
  
  // Error routes
  static const String notFound = 'not_found';
  static const String error = 'error';
  static const String unauthorized = 'unauthorized';
}

/// Tab indices for bottom navigation
class TabIndex {
  // Beveiliger tabs
  static const int beveiligerDashboard = 0;
  static const int beveiligerJobs = 1;
  static const int beveiligerSchedule = 2;
  static const int beveiligerChat = 3;
  static const int beveiligerProfile = 4;
  
  // Company tabs
  static const int companyDashboard = 0;
  static const int companyJobs = 1;
  static const int companyTeam = 2;
  static const int companyAnalytics = 3;
  static const int companyProfile = 4;
}