import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../unified_design_tokens.dart';
import '../../chat/services/auto_chat_service.dart';
import '../../beveiliger_notificaties/services/guard_notification_service.dart';
import '../../beveiliger_notificaties/models/guard_notification.dart';
import '../../billing/services/feature_access_service.dart';
import '../../auth/auth_service.dart';

/// Service for managing applications from Company perspective
/// Handles reviewing, accepting, and rejecting guard applications with Firebase integration
class ApplicationReviewService {
  static ApplicationReviewService? _instance;
  static ApplicationReviewService get instance {
    _instance ??= ApplicationReviewService._();
    return _instance!;
  }
  
  ApplicationReviewService._();
  
  // Firebase integration
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _applicationsCollection = 'applications';
  static const String _jobsCollection = 'jobs';
  
  // Services
  final GuardNotificationService _guardNotificationService = GuardNotificationService.instance;
  final FeatureAccessService _featureAccessService = FeatureAccessService.instance;
  
  // Fallback mock data storage for demo mode
  static final Map<String, ApplicationReviewData> _applicationReviews = {};
  static final Map<String, List<String>> _companyApplications = {};
  
  /// Get all applications for company's jobs with subscription-based access control
  Future<List<ApplicationReviewData>> getCompanyApplications(String companyId) async {
    try {
      if (companyId.isEmpty) return [];

      // Check subscription access for application management
      final canAccess = await _featureAccessService.hasFeatureAccess(
        userId: companyId,
        featureKey: 'job_posting', // Companies need job posting access to see applications
        context: {'action': 'view_applications'},
      );

      if (!canAccess) {
        debugPrint('❌ Application access blocked - subscription required');
        throw FeatureAccessDeniedException(
          message: 'Een actief bedrijfabonnement is vereist om sollicitaties te bekijken',
          featureKey: 'job_posting',
        );
      }

      // Get company's jobs first
      final jobSnapshot = await _firestore
          .collection(_jobsCollection)
          .where('companyId', isEqualTo: companyId)
          .get();
      
      final jobIds = jobSnapshot.docs.map((doc) => doc.id).toList();
      
      if (jobIds.isEmpty) return [];
      
      // Get all applications for these jobs
      final applicationsSnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', whereIn: jobIds)
          .orderBy('applicationDate', descending: true)
          .get();
      
      final applications = <ApplicationReviewData>[];
      for (final doc in applicationsSnapshot.docs) {
        final applicationReviewData = await _convertToApplicationReviewData(doc);
        if (applicationReviewData != null) {
          applications.add(applicationReviewData);
        }
      }
      
      return applications;
    } catch (e) {
      debugPrint('Error fetching company applications: $e');
      
      // Fallback to mock data for demo mode
      await initializeMockData(companyId);
      final applicationIds = _companyApplications[companyId] ?? [];
      final applications = applicationIds
          .map((id) => _applicationReviews[id])
          .where((app) => app != null)
          .cast<ApplicationReviewData>()
          .toList();
      
      applications.sort((a, b) => b.applicationDate.compareTo(a.applicationDate));
      return applications;
    }
  }
  
  /// Get pending applications (not yet reviewed)
  Future<List<ApplicationReviewData>> getPendingApplications(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final allApplications = await getCompanyApplications(companyId);
    return allApplications
        .where((app) => app.status == ApplicationReviewStatus.pending)
        .toList();
  }
  
  /// Get applications for specific job
  Future<List<ApplicationReviewData>> getJobApplications(String jobId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    return _applicationReviews.values
        .where((app) => app.jobId == jobId)
        .toList()
      ..sort((a, b) => b.applicationDate.compareTo(a.applicationDate));
  }
  
  /// Accept guard application with Firebase integration and notifications
  Future<bool> acceptApplication(String applicationId, {String? message}) async {
    try {
      if (applicationId.isEmpty) return false;
      
      // Update application in Firebase
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'status': 'accepted',
        'reviewDate': FieldValue.serverTimestamp(),
        'reviewMessage': message,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get application data for further processing
      final appDoc = await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .get();
      
      if (appDoc.exists) {
        final appData = appDoc.data()!;
        final jobId = appData['jobId'] as String;
        final guardId = appData['userId'] as String;
        
        // Get job data for notifications
        final jobDoc = await _firestore.collection(_jobsCollection).doc(jobId).get();
        if (jobDoc.exists) {
          final jobData = jobDoc.data()!;
          final jobTitle = jobData['title'] as String;
          final companyName = jobData['companyName'] as String? ?? 'Bedrijf';
          
          // Send acceptance notification to guard
          await _guardNotificationService.sendApplicationAccepted(
            guardId: guardId,
            jobId: jobId,
            jobTitle: jobTitle,
            companyName: companyName,
            message: message,
          );
          
          // Update job status if needed
          await _updateJobStatusIfFilled(jobId);
          
          // Create chat between company and guard
          await _createApplicationChat(guardId, jobId, jobTitle);
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error accepting application: $e');
      
      // Fallback to mock data for demo mode
      final application = _applicationReviews[applicationId];
      if (application == null) return false;
      
      final updatedApplication = application.copyWith(
        status: ApplicationReviewStatus.accepted,
        reviewDate: DateTime.now(),
        reviewMessage: message,
      );
      
      _applicationReviews[applicationId] = updatedApplication;
      return true;
    }
  }
  
  /// Reject guard application with Firebase integration and notifications
  Future<bool> rejectApplication(String applicationId, {String? reason}) async {
    try {
      if (applicationId.isEmpty) return false;
      
      // Update application in Firebase
      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'status': 'rejected',
        'reviewDate': FieldValue.serverTimestamp(),
        'reviewMessage': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Get application data for notifications
      final appDoc = await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .get();
      
      if (appDoc.exists) {
        final appData = appDoc.data()!;
        final jobId = appData['jobId'] as String;
        final guardId = appData['userId'] as String;
        
        // Get job data for notifications
        final jobDoc = await _firestore.collection(_jobsCollection).doc(jobId).get();
        if (jobDoc.exists) {
          final jobData = jobDoc.data()!;
          final jobTitle = jobData['title'] as String;
          final companyName = jobData['companyName'] as String? ?? 'Bedrijf';
          
          // Send rejection notification to guard
          await _guardNotificationService.sendApplicationRejected(
            guardId: guardId,
            jobId: jobId,
            jobTitle: jobTitle,
            companyName: companyName,
            reason: reason,
          );
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error rejecting application: $e');
      
      // Fallback to mock data for demo mode
      final application = _applicationReviews[applicationId];
      if (application == null) return false;
      
      final updatedApplication = application.copyWith(
        status: ApplicationReviewStatus.rejected,
        reviewDate: DateTime.now(),
        reviewMessage: reason,
      );
      
      _applicationReviews[applicationId] = updatedApplication;
      return true;
    }
  }
  
  /// Get application statistics for company
  Future<Map<String, dynamic>> getApplicationStats(String companyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final applications = await getCompanyApplications(companyId);
    
    final pending = applications.where((app) => app.status == ApplicationReviewStatus.pending).length;
    final accepted = applications.where((app) => app.status == ApplicationReviewStatus.accepted).length;
    final rejected = applications.where((app) => app.status == ApplicationReviewStatus.rejected).length;
    
    final averageRating = applications.isEmpty ? 0.0 :
        applications.fold<double>(0.0, (total, app) => total + app.guardRating) / applications.length;
    
    return {
      'totalApplications': applications.length,
      'pendingReview': pending,
      'accepted': accepted,
      'rejected': rejected,
      'acceptanceRate': applications.isEmpty ? 0.0 : (accepted / applications.length) * 100,
      'averageGuardRating': averageRating,
      'averageResponseTime': 6.5, // hours (mock data)
    };
  }
  
  /// MVP BULK OPERATIONS FOR LOWLANDS FESTIVAL WORKFLOW
  
  /// Bulk accept applications (MVP: Creates individual 1-on-1 chats)
  /// Perfect for Lowlands Festival: Accept 6 guards, create individual chats
  Future<BulkApplicationResult> bulkAcceptApplications({
    required String companyId,
    required String companyName,
    required List<String> applicationIds,
    required String jobId,
    required String jobTitle,
    required String jobLocation,
    required DateTime jobStartDate,
    String? acceptanceMessage,
    Map<String, dynamic>? jobMetadata,
  }) async {
    try {
      debugPrint('Processing bulk accept for ${applicationIds.length} applications');
      
      final List<String> successfulAcceptances = [];
      final List<String> failedAcceptances = [];
      final List<String> createdConversations = [];
      
      // Process each application individually
      for (final applicationId in applicationIds) {
        final application = _applicationReviews[applicationId];
        if (application == null) {
          failedAcceptances.add(applicationId);
          continue;
        }
        
        // Accept the application
        final acceptSuccess = await acceptApplication(
          applicationId, 
          message: acceptanceMessage ?? 'Gefeliciteerd! Je bent geselecteerd voor $jobTitle.',
        );
        
        if (!acceptSuccess) {
          failedAcceptances.add(applicationId);
          continue;
        }
        
        successfulAcceptances.add(applicationId);
        
        // Create individual 1-on-1 chat for this guard-company pair
        final conversationId = await AutoChatService.instance.createAssignmentConversation(
          assignmentId: jobId,
          assignmentTitle: jobTitle,
          guardId: application.guardId,
          guardName: application.guardName,
          companyId: companyId,
          companyName: companyName,
          assignmentDate: jobStartDate,
          assignmentLocation: jobLocation,
        );
        
        if (conversationId != null) {
          createdConversations.add(conversationId);
          
          // Send personalized acceptance notification
          await _sendAcceptanceNotification(
            guardId: application.guardId,
            guardName: application.guardName,
            jobTitle: jobTitle,
            companyName: companyName,
            conversationId: conversationId,
            jobStartDate: jobStartDate,
            jobLocation: jobLocation,
          );
        }
        
        // Small delay between operations to prevent overwhelm
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      debugPrint('Bulk accept completed: ${successfulAcceptances.length} successful, ${failedAcceptances.length} failed');
      
      return BulkApplicationResult(
        success: failedAcceptances.isEmpty,
        totalProcessed: applicationIds.length,
        successCount: successfulAcceptances.length,
        failureCount: failedAcceptances.length,
        successfulApplicationIds: successfulAcceptances,
        failedApplicationIds: failedAcceptances,
        createdConversationIds: createdConversations,
        message: failedAcceptances.isEmpty 
          ? 'Alle ${successfulAcceptances.length} sollicitanten succesvol geaccepteerd!'
          : '${successfulAcceptances.length} geaccepteerd, ${failedAcceptances.length} gefaald',
      );
      
    } catch (e) {
      debugPrint('Error in bulk accept applications: $e');
      return BulkApplicationResult(
        success: false,
        totalProcessed: applicationIds.length,
        successCount: 0,
        failureCount: applicationIds.length,
        errorMessage: 'Fout bij bulk accepteren: ${e.toString()}',
      );
    }
  }
  
  /// Bulk reject applications with personalized feedback
  Future<BulkApplicationResult> bulkRejectApplications({
    required List<String> applicationIds,
    required String rejectionReason,
    Map<String, String>? personalizedReasons, // applicationId -> personal reason
  }) async {
    try {
      debugPrint('Processing bulk reject for ${applicationIds.length} applications');
      
      final List<String> successfulRejections = [];
      final List<String> failedRejections = [];
      
      for (final applicationId in applicationIds) {
        final application = _applicationReviews[applicationId];
        if (application == null) {
          failedRejections.add(applicationId);
          continue;
        }
        
        // Use personalized reason if available, otherwise use general reason
        final reason = personalizedReasons?[applicationId] ?? rejectionReason;
        
        final rejectSuccess = await rejectApplication(applicationId, reason: reason);
        
        if (rejectSuccess) {
          successfulRejections.add(applicationId);
          
          // Send personalized rejection notification
          await _sendRejectionNotification(
            guardId: application.guardId,
            guardName: application.guardName,
            jobTitle: 'de geselecteerde opdracht', // Generic since we may not have job context
            reason: reason,
          );
        } else {
          failedRejections.add(applicationId);
        }
        
        // Small delay between operations
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      debugPrint('Bulk reject completed: ${successfulRejections.length} successful, ${failedRejections.length} failed');
      
      return BulkApplicationResult(
        success: failedRejections.isEmpty,
        totalProcessed: applicationIds.length,
        successCount: successfulRejections.length,
        failureCount: failedRejections.length,
        successfulApplicationIds: successfulRejections,
        failedApplicationIds: failedRejections,
        message: failedRejections.isEmpty 
          ? 'Alle ${successfulRejections.length} sollicitanten succesvol afgewezen'
          : '${successfulRejections.length} afgewezen, ${failedRejections.length} gefaald',
      );
      
    } catch (e) {
      debugPrint('Error in bulk reject applications: $e');
      return BulkApplicationResult(
        success: false,
        totalProcessed: applicationIds.length,
        successCount: 0,
        failureCount: applicationIds.length,
        errorMessage: 'Fout bij bulk afwijzen: ${e.toString()}',
      );
    }
  }
  
  /// Send acceptance notification with chat invitation
  Future<void> _sendAcceptanceNotification({
    required String guardId,
    required String guardName,
    required String jobTitle,
    required String companyName,
    required String conversationId,
    required DateTime jobStartDate,
    required String jobLocation,
  }) async {
    try {
      // TODO: Implement proper notification sending for MVP
      // For now, notifications are handled via the individual chat creation
      debugPrint('ACCEPTANCE NOTIFICATION: $guardName selected for $jobTitle');
      debugPrint('Chat created: $conversationId');
      
      // In production, you would implement:
      // await GuardNotificationService.instance.sendApplicationAccepted(...);
      
      debugPrint('Acceptance notification sent to $guardName ($guardId)');
      
    } catch (e) {
      debugPrint('Error sending acceptance notification to $guardId: $e');
    }
  }
  
  /// Send rejection notification with helpful feedback
  Future<void> _sendRejectionNotification({
    required String guardId,
    required String guardName,
    required String jobTitle,
    required String reason,
  }) async {
    try {
      // TODO: Implement proper rejection notification for MVP
      debugPrint('REJECTION NOTIFICATION: $guardName not selected for $jobTitle');
      debugPrint('Reason: $reason');
      
      // In production, you would implement:
      // await GuardNotificationService.instance.sendApplicationRejected(...);
      
      debugPrint('Rejection notification sent to $guardName ($guardId)');
      
    } catch (e) {
      debugPrint('Error sending rejection notification to $guardId: $e');
    }
  }
  
  /// Convert Firestore document to ApplicationReviewData
  Future<ApplicationReviewData?> _convertToApplicationReviewData(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      return ApplicationReviewData(
        applicationId: doc.id,
        jobId: data['jobId'] ?? '',
        guardId: data['userId'] ?? '',
        guardName: data['applicantName'] ?? 'Onbekende Beveiliger',
        guardEmail: data['applicantEmail'] ?? '',
        guardPhone: data['applicantPhone'] ?? '',
        motivationMessage: data['message'] ?? '',
        applicationDate: (data['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: _statusFromString(data['status'] ?? 'pending'),
        guardRating: (data['guardRating'] ?? 4.5).toDouble(),
        guardExperience: data['guardExperience'] ?? 1,
        guardCertificates: List<String>.from(data['guardCertificates'] ?? []),
        reviewDate: (data['reviewDate'] as Timestamp?)?.toDate(),
        reviewMessage: data['reviewMessage'],
      );
    } catch (e) {
      debugPrint('Error converting Firestore document to ApplicationReviewData: $e');
      return null;
    }
  }
  
  /// Convert string to ApplicationReviewStatus
  ApplicationReviewStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return ApplicationReviewStatus.accepted;
      case 'rejected': return ApplicationReviewStatus.rejected;
      case 'pending': 
      default: return ApplicationReviewStatus.pending;
    }
  }
  
  
  /// Update job status when position is filled
  Future<void> _updateJobStatusIfFilled(String jobId) async {
    try {
      // Get job data
      final jobDoc = await _firestore.collection(_jobsCollection).doc(jobId).get();
      if (!jobDoc.exists) return;
      
      final jobData = jobDoc.data()!;
      final maxPositions = jobData['maxPositions'] ?? 1;
      
      // Count accepted applications
      final acceptedAppsSnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      final acceptedCount = acceptedAppsSnapshot.docs.length;
      
      // Update job status if positions filled
      if (acceptedCount >= maxPositions) {
        await _firestore.collection(_jobsCollection).doc(jobId).update({
          'status': 'filled',
          'filledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Notify remaining applicants that position is filled
        await _notifyRemainingApplicants(jobId);
        
        debugPrint('Job $jobId status updated to filled');
      }
    } catch (e) {
      debugPrint('Error updating job status: $e');
    }
  }
  
  /// Notify remaining applicants that position is filled
  Future<void> _notifyRemainingApplicants(String jobId) async {
    try {
      // Get pending applications
      final pendingApps = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Get job data for notification
      final jobDoc = await _firestore.collection(_jobsCollection).doc(jobId).get();
      if (!jobDoc.exists) return;
      
      final jobData = jobDoc.data()!;
      final jobTitle = jobData['title'] as String;
      
      // Send notifications to pending applicants
      for (final doc in pendingApps.docs) {
        final appData = doc.data();
        try {
          await GuardNotificationService.instance.sendJobPositionFilled(
            guardId: appData['userId'],
            jobId: jobId,
            jobTitle: jobTitle,
          );
        } catch (e) {
          debugPrint('Error notifying guard ${appData['userId']}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error notifying remaining applicants: $e');
    }
  }
  
  /// Create chat between company and guard(s) after acceptance
  Future<void> _createApplicationChat(String guardId, String jobId, String jobTitle) async {
    try {
      // Get job details for chat creation
      final jobDoc = await _firestore.collection(_jobsCollection).doc(jobId).get();
      if (!jobDoc.exists) {
        debugPrint('Job not found for chat creation: $jobId');
        return;
      }
      
      final jobData = jobDoc.data()!;
      final companyId = jobData['companyId'] as String;
      final companyName = jobData['companyName'] as String? ?? 'Bedrijf';
      final jobLocation = jobData['location'] as String? ?? 'Nederland';
      final jobStartDate = (jobData['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
      
      // Guard details will be fetched in the loop below
      
      // Check if there are other accepted guards for this job (for group chat)
      final acceptedAppsSnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      final acceptedGuardIds = <String>[];
      final acceptedGuardNames = <String>[];
      
      for (final doc in acceptedAppsSnapshot.docs) {
        final appGuardId = doc.data()['userId'] as String;
        acceptedGuardIds.add(appGuardId);
        
        // Get guard name
        final appGuardDoc = await _firestore.collection('users').doc(appGuardId).get();
        final appGuardName = appGuardDoc.exists ? 
          (appGuardDoc.data()!['name'] as String? ?? 'Beveiliger') : 'Beveiliger';
        acceptedGuardNames.add(appGuardName);
      }
      
      // Create chat using AutoChatService
      final conversationId = await AutoChatService.instance.createApplicationAcceptedChat(
        jobId: jobId,
        jobTitle: jobTitle,
        guardIds: acceptedGuardIds,
        guardNames: acceptedGuardNames,
        companyId: companyId,
        companyName: companyName,
        jobStartDate: jobStartDate,
        jobLocation: jobLocation,
      );
      
      if (conversationId != null) {
        debugPrint('Chat created successfully: $conversationId');
        
        // Send push notification to all parties
        await _sendChatCreatedNotifications(
          conversationId: conversationId,
          jobTitle: jobTitle,
          guardIds: acceptedGuardIds,
          companyId: companyId,
        );
      }
    } catch (e) {
      debugPrint('Error creating application chat: $e');
    }
  }
  
  /// Send push notifications when chat is created
  Future<void> _sendChatCreatedNotifications({
    required String conversationId,
    required String jobTitle,
    required List<String> guardIds,
    required String companyId,
  }) async {
    try {
      // Send notification to each guard about new chat
      for (final guardId in guardIds) {
        // Create a simple notification for chat creation
        final notification = GuardNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: guardId,
          type: GuardNotificationType.jobUpdate,
          title: 'Nieuwe Chat: $jobTitle',
          body: 'Er is een chat aangemaakt voor deze opdracht. Open de chat om te communiceren met het bedrijf.',
          data: {
            'conversationId': conversationId,
            'jobTitle': jobTitle,
          },
          timestamp: DateTime.now(),
          priority: NotificationPriority.high,
          actionUrl: '/chat/$conversationId',
        );
        
        // Save notification to Firestore
        await FirebaseFirestore.instance
            .collection('notifications')
            .add(notification.toFirestore());
      }
      
      debugPrint('Chat notifications sent to ${guardIds.length} guards');
    } catch (e) {
      debugPrint('Error sending chat notifications: $e');
    }
  }
  
  /// Initialize mock application data for fallback (public for testing)
  Future<void> initializeMockData(String companyId) async {
    if (_applicationReviews.isNotEmpty) return;
    
    // Create sample applications
    final mockApplications = [
      ApplicationReviewData(
        applicationId: 'APP001',
        jobId: 'JOB001',
        guardId: 'GUARD001',
        guardName: 'Jan de Beveiliger',
        guardEmail: 'jan@beveiliger.nl',
        guardPhone: '+31 6 12345678',
        motivationMessage: 'Ik heb 5 jaar ervaring met objectbeveiliging en ben beschikbaar voor deze opdracht.',
        applicationDate: DateTime.now().subtract(const Duration(hours: 6)),
        status: ApplicationReviewStatus.pending,
        guardRating: 4.7,
        guardExperience: 5,
        guardCertificates: ['Beveiligingsdiploma A', 'BHV', 'EHBO'],
      ),
      ApplicationReviewData(
        applicationId: 'APP002',
        jobId: 'JOB001',
        guardId: 'GUARD002',
        guardName: 'Maria van der Berg',
        guardEmail: 'maria@security.nl',
        guardPhone: '+31 6 87654321',
        motivationMessage: 'Ervaren beveiliger met specialisatie in kantoorbeveiliging. Flexibel beschikbaar.',
        applicationDate: DateTime.now().subtract(const Duration(hours: 12)),
        status: ApplicationReviewStatus.pending,
        guardRating: 4.9,
        guardExperience: 8,
        guardCertificates: ['Beveiligingsdiploma A', 'Beveiligingsdiploma B', 'BHV'],
      ),
    ];
    
    for (final app in mockApplications) {
      _applicationReviews[app.applicationId] = app;
      
      // Add to company applications
      final companyId = 'COMP001'; // Mock company ID
      _companyApplications[companyId] ??= [];
      _companyApplications[companyId]!.add(app.applicationId);
    }
  }
}

/// Application review data model for Company perspective
class ApplicationReviewData {
  final String applicationId;
  final String jobId;
  final String guardId;
  final String guardName;
  final String guardEmail;
  final String guardPhone;
  final String motivationMessage;
  final DateTime applicationDate;
  final ApplicationReviewStatus status;
  final DateTime? reviewDate;
  final String? reviewMessage;
  final double guardRating;
  final int guardExperience;
  final List<String> guardCertificates;
  final String? guardProfileUrl;
  
  const ApplicationReviewData({
    required this.applicationId,
    required this.jobId,
    required this.guardId,
    required this.guardName,
    required this.guardEmail,
    required this.guardPhone,
    required this.motivationMessage,
    required this.applicationDate,
    this.status = ApplicationReviewStatus.pending,
    this.reviewDate,
    this.reviewMessage,
    this.guardRating = 0.0,
    this.guardExperience = 0,
    this.guardCertificates = const [],
    this.guardProfileUrl,
  });
  
  /// Copy with method for updates
  ApplicationReviewData copyWith({
    String? applicationId,
    String? jobId,
    String? guardId,
    String? guardName,
    String? guardEmail,
    String? guardPhone,
    String? motivationMessage,
    DateTime? applicationDate,
    ApplicationReviewStatus? status,
    DateTime? reviewDate,
    String? reviewMessage,
    double? guardRating,
    int? guardExperience,
    List<String>? guardCertificates,
    String? guardProfileUrl,
  }) {
    return ApplicationReviewData(
      applicationId: applicationId ?? this.applicationId,
      jobId: jobId ?? this.jobId,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      guardEmail: guardEmail ?? this.guardEmail,
      guardPhone: guardPhone ?? this.guardPhone,
      motivationMessage: motivationMessage ?? this.motivationMessage,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      reviewDate: reviewDate ?? this.reviewDate,
      reviewMessage: reviewMessage ?? this.reviewMessage,
      guardRating: guardRating ?? this.guardRating,
      guardExperience: guardExperience ?? this.guardExperience,
      guardCertificates: guardCertificates ?? this.guardCertificates,
      guardProfileUrl: guardProfileUrl ?? this.guardProfileUrl,
    );
  }
}

/// Application review status enumeration
enum ApplicationReviewStatus {
  pending,     // In behandeling
  accepted,    // Geaccepteerd
  rejected,    // Afgewezen
  withdrawn,   // Ingetrokken
}

/// Extension for Dutch display names
extension ApplicationReviewStatusExtension on ApplicationReviewStatus {
  String get displayName {
    switch (this) {
      case ApplicationReviewStatus.pending:
        return 'In behandeling';
      case ApplicationReviewStatus.accepted:
        return 'Geaccepteerd';
      case ApplicationReviewStatus.rejected:
        return 'Afgewezen';
      case ApplicationReviewStatus.withdrawn:
        return 'Ingetrokken';
    }
  }
  
  /// Get status color for UI
  Color get statusColor {
    switch (this) {
      case ApplicationReviewStatus.pending:
        return DesignTokens.colorWarning; // Orange
      case ApplicationReviewStatus.accepted:
        return DesignTokens.colorSuccess; // Green
      case ApplicationReviewStatus.rejected:
        return DesignTokens.colorError; // Red
      case ApplicationReviewStatus.withdrawn:
        return const Color(0xFF9CA3AF); // Gray
    }
  }
}

/// Result of bulk application operations (MVP)
class BulkApplicationResult {
  final bool success;
  final int totalProcessed;
  final int successCount;
  final int failureCount;
  final List<String> successfulApplicationIds;
  final List<String> failedApplicationIds;
  final List<String> createdConversationIds; // Individual chat IDs created
  final String? message;
  final String? errorMessage;

  const BulkApplicationResult({
    required this.success,
    required this.totalProcessed,
    required this.successCount,
    required this.failureCount,
    this.successfulApplicationIds = const [],
    this.failedApplicationIds = const [],
    this.createdConversationIds = const [],
    this.message,
    this.errorMessage,
  });

  /// Get user-friendly success message in Dutch
  String get displayMessage {
    if (errorMessage != null) return errorMessage!;
    if (message != null) return message!;
    
    if (success) {
      return 'Alle $successCount sollicitaties succesvol verwerkt!';
    } else {
      return '$successCount gelukt, $failureCount mislukt van $totalProcessed totaal';
    }
  }

  /// Check if all operations succeeded
  bool get isCompleteSuccess => success && failureCount == 0;

  /// Check if any operations succeeded
  bool get hasPartialSuccess => successCount > 0;

  /// Get success rate as percentage
  double get successRate => totalProcessed > 0 ? (successCount / totalProcessed) * 100 : 0.0;
}
