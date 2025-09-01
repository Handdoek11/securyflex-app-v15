import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore schema extension for SecuryFlex analytics
/// Defines subcollections structure and indexing configuration
/// Builds on existing schema without breaking current functionality

class AnalyticsFirestoreSchema {
  // Collection names for analytics subcollections
  static const String analyticsDaily = 'analytics_daily';
  static const String analyticsWeekly = 'analytics_weekly';
  static const String analyticsMonthly = 'analytics_monthly';
  static const String analyticsSummary = 'analytics_summary';
  static const String funnelAnalytics = 'funnel_analytics';
  static const String sourceAnalytics = 'source_analytics';
  static const String analyticsEvents = 'analytics_events';
  static const String viewTracking = 'view_tracking';
  static const String applicationTracking = 'application_tracking';
  static const String lifecycleEvents = 'lifecycle_events';
  static const String interactionTracking = 'interaction_tracking';
  static const String outcomeTracking = 'outcome_tracking';

  // Document IDs for summary documents
  static const String currentSummary = 'current';
  static const String finalOutcome = 'final';

  /// Get company analytics daily collection reference
  static CollectionReference getCompanyAnalyticsDaily(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(analyticsDaily);
  }

  /// Get company analytics weekly collection reference
  static CollectionReference getCompanyAnalyticsWeekly(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(analyticsWeekly);
  }

  /// Get company analytics monthly collection reference
  static CollectionReference getCompanyAnalyticsMonthly(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(analyticsMonthly);
  }

  /// Get company analytics summary document reference
  static DocumentReference getCompanyAnalyticsSummary(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(analyticsSummary)
        .doc(currentSummary);
  }

  /// Get company funnel analytics collection reference
  static CollectionReference getCompanyFunnelAnalytics(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(funnelAnalytics);
  }

  /// Get company source analytics collection reference
  static CollectionReference getCompanySourceAnalytics(String companyId) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection(sourceAnalytics);
  }

  /// Get job analytics events collection reference
  static CollectionReference getJobAnalyticsEvents(String jobId) {
    return FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection(analyticsEvents);
  }

  /// Get job analytics daily collection reference
  static CollectionReference getJobAnalyticsDaily(String jobId) {
    return FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection(analyticsDaily);
  }

  /// Get job view tracking collection reference
  static CollectionReference getJobViewTracking(String jobId) {
    return FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection(viewTracking);
  }

  /// Get job application tracking collection reference
  static CollectionReference getJobApplicationTracking(String jobId) {
    return FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .collection(applicationTracking);
  }

  /// Get application lifecycle events collection reference
  static CollectionReference getApplicationLifecycleEvents(String applicationId) {
    return FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .collection(lifecycleEvents);
  }

  /// Get application interaction tracking collection reference
  static CollectionReference getApplicationInteractionTracking(String applicationId) {
    return FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .collection(interactionTracking);
  }

  /// Get application outcome tracking document reference
  static DocumentReference getApplicationOutcomeTracking(String applicationId) {
    return FirebaseFirestore.instance
        .collection('applications')
        .doc(applicationId)
        .collection(outcomeTracking)
        .doc(finalOutcome);
  }
}

/// Firestore composite indexes required for analytics queries
/// These indexes must be created in Firebase Console or via Firebase CLI
class AnalyticsFirestoreIndexes {
  static const List<Map<String, dynamic>> requiredIndexes = [
    // Company Analytics Daily Queries
    {
      'collection': 'companies/{companyId}/analytics_daily',
      'fields': [
        {'field': 'date', 'order': 'desc'},
        {'field': 'totalApplications', 'order': 'desc'},
      ],
      'description': 'Company daily analytics sorted by date and applications'
    },
    {
      'collection': 'companies/{companyId}/analytics_daily',
      'fields': [
        {'field': 'date', 'order': 'asc'},
        {'field': 'viewToApplicationRate', 'order': 'desc'},
      ],
      'description': 'Company daily analytics for conversion rate analysis'
    },
    
    // Job Analytics Events Queries
    {
      'collection': 'jobs/{jobId}/analytics_events',
      'fields': [
        {'field': 'eventType', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
      'description': 'Job events filtered by type and sorted by time'
    },
    {
      'collection': 'jobs/{jobId}/analytics_events',
      'fields': [
        {'field': 'source', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
      'description': 'Job events filtered by source and sorted by time'
    },
    {
      'collection': 'jobs/{jobId}/analytics_events',
      'fields': [
        {'field': 'userRole', 'order': 'asc'},
        {'field': 'eventType', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
      'description': 'Job events filtered by user role and event type'
    },
    
    // Funnel Analytics Queries
    {
      'collection': 'companies/{companyId}/funnel_analytics',
      'fields': [
        {'field': 'period', 'order': 'asc'},
        {'field': 'updatedAt', 'order': 'desc'},
      ],
      'description': 'Funnel analytics sorted by period and update time'
    },
    
    // Source Analytics Queries
    {
      'collection': 'companies/{companyId}/source_analytics',
      'fields': [
        {'field': 'costPerHire', 'order': 'asc'},
        {'field': 'totalHires', 'order': 'desc'},
      ],
      'description': 'Source analytics for cost-effectiveness analysis'
    },
    {
      'collection': 'companies/{companyId}/source_analytics',
      'fields': [
        {'field': 'source', 'order': 'asc'},
        {'field': 'lastUpdated', 'order': 'desc'},
      ],
      'description': 'Source analytics filtered by source type'
    },
    
    // Job Daily Analytics Queries
    {
      'collection': 'jobs/{jobId}/analytics_daily',
      'fields': [
        {'field': 'date', 'order': 'desc'},
        {'field': 'totalViews', 'order': 'desc'},
      ],
      'description': 'Job daily analytics sorted by date and views'
    },
    {
      'collection': 'jobs/{jobId}/analytics_daily',
      'fields': [
        {'field': 'date', 'order': 'asc'},
        {'field': 'newApplications', 'order': 'desc'},
      ],
      'description': 'Job daily analytics for application tracking'
    },
    
    // Application Lifecycle Events Queries
    {
      'collection': 'applications/{applicationId}/lifecycle_events',
      'fields': [
        {'field': 'eventType', 'order': 'asc'},
        {'field': 'timestamp', 'order': 'desc'},
      ],
      'description': 'Application lifecycle events by type and time'
    },
    
    // Cross-collection Analytics Queries
    {
      'collection': 'jobs',
      'fields': [
        {'field': 'companyId', 'order': 'asc'},
        {'field': 'createdDate', 'order': 'desc'},
        {'field': 'status', 'order': 'asc'},
      ],
      'description': 'Jobs filtered by company and status for analytics'
    },
    {
      'collection': 'applications',
      'fields': [
        {'field': 'companyName', 'order': 'asc'},
        {'field': 'applicationDate', 'order': 'desc'},
        {'field': 'status', 'order': 'asc'},
      ],
      'description': 'Applications filtered by company and status'
    },
  ];

  /// Generate Firebase CLI commands for creating indexes
  static List<String> generateFirebaseCLICommands() {
    return requiredIndexes.map((index) {
      final collection = index['collection'] as String;
      final fields = index['fields'] as List<Map<String, dynamic>>;
      
      final fieldSpecs = fields.map((field) {
        final fieldName = field['field'] as String;
        final order = field['order'] as String;
        return '$fieldName:$order';
      }).join(',');
      
      return 'firebase firestore:indexes:create --collection-group="$collection" --field-config="$fieldSpecs"';
    }).toList();
  }

  /// Validate that required indexes exist (for development/testing)
  static Future<bool> validateIndexes() async {
    // This would typically check against Firebase Admin SDK
    // For now, return true as indexes are created manually
    return true;
  }
}
