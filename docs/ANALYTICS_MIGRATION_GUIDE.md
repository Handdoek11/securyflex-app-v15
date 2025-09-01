# 📊 SecuryFlex Analytics Migration Guide

## 🎯 Overview

This guide provides comprehensive instructions for migrating SecuryFlex to the new analytics system. The migration process is designed to be safe, reversible, and minimally disruptive to existing functionality.

## 🏗️ Migration Architecture

### Current Schema
```
companies/{companyId}
├── Basic company data
├── totalJobsPosted, activeJobs, completedJobs
└── totalSpent, totalGuardsHired, averageJobValue

jobs/{jobId}
├── Job posting data
├── applicationsCount
└── applicantIds[]

applications/{applicationId}
├── Application data
├── status, applicationDate
└── companyName, jobId
```

### New Analytics Schema
```
companies/{companyId}/
├── analytics_daily/{YYYY-MM-DD}     // Daily aggregations
├── analytics_weekly/{YYYY-WW}       // Weekly aggregations  
├── analytics_monthly/{YYYY-MM}      // Monthly aggregations
├── analytics_summary/current        // Current period summary
├── funnel_analytics/{period}        // Recruitment funnel data
└── source_analytics/{source}        // Source effectiveness data

jobs/{jobId}/
├── analytics_events/{eventId}       // Individual tracking events
├── analytics_daily/{YYYY-MM-DD}     // Daily job analytics
├── view_tracking/{viewId}           // View tracking
└── application_tracking/{appId}     // Application tracking

applications/{applicationId}/
├── lifecycle_events/{eventId}       // Application lifecycle
├── interaction_tracking/{intId}     // User interactions
└── outcome_tracking/final           // Final outcomes
```

## 🚀 Migration Process

### Phase 1: Pre-Migration Validation
- ✅ Verify Firestore connection
- ✅ Validate existing data integrity
- ✅ Check company data completeness
- ✅ Assess migration scope

### Phase 2: Schema Preparation
- 🔧 Create analytics subcollections
- 🔧 Initialize summary documents
- 🔧 Set up indexing structure
- 🔧 Prepare migration metadata

### Phase 3: Data Migration
- 📊 Migrate company analytics
- 📊 Migrate job performance data
- 📊 Migrate application history
- 📊 Create historical aggregations

### Phase 4: Post-Migration Validation
- ✅ Verify data completeness
- ✅ Validate analytics calculations
- ✅ Test query performance
- ✅ Confirm service functionality

### Phase 5: Analytics Initialization
- 🎯 Initialize analytics services
- 🎯 Clear service caches
- 🎯 Test dashboard functionality
- 🎯 Enable real-time tracking

## 🛠️ Migration Tools

### Command Line Interface

#### Basic Migration
```bash
# Validate migration readiness
dart lib/company_dashboard/tools/analytics_migration_cli.dart validate

# Execute full migration
dart lib/company_dashboard/tools/analytics_migration_cli.dart migrate

# Execute dry run (validation only)
dart lib/company_dashboard/tools/analytics_migration_cli.dart migrate --dry-run
```

#### Advanced Options
```bash
# Migrate specific companies
dart analytics_migration_cli.dart migrate --companies=company1,company2

# Skip post-migration validation (faster)
dart analytics_migration_cli.dart migrate --skip-validation

# Force migration without confirmation
dart analytics_migration_cli.dart migrate --force
```

#### Monitoring & Rollback
```bash
# Check migration status
dart analytics_migration_cli.dart status

# View migration logs
dart analytics_migration_cli.dart logs

# Rollback migration
dart analytics_migration_cli.dart rollback --migration-id=migration_1234567890
```

### Flutter Migration Monitor

```dart
// Add to your admin dashboard
import 'package:securyflex_app/company_dashboard/tools/analytics_migration_cli.dart';

// Display migration monitor
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const MigrationMonitorWidget(),
  ),
);
```

## 📋 Pre-Migration Checklist

### Environment Preparation
- [ ] Backup Firestore database
- [ ] Verify Firebase project permissions
- [ ] Ensure sufficient Firestore quota
- [ ] Test network connectivity
- [ ] Prepare rollback plan

### Data Validation
- [ ] Verify company data completeness
- [ ] Check job posting integrity
- [ ] Validate application records
- [ ] Confirm user data consistency
- [ ] Review data relationships

### System Requirements
- [ ] Flutter SDK 3.0+
- [ ] Firebase Admin SDK access
- [ ] Firestore read/write permissions
- [ ] Cloud Functions deployment rights
- [ ] Monitoring tools access

## 🔧 Migration Configuration

### Firestore Indexes
```javascript
// Required composite indexes
const requiredIndexes = [
  {
    collection: 'companies/{companyId}/analytics_daily',
    fields: [
      { field: 'date', order: 'desc' },
      { field: 'totalApplications', order: 'desc' }
    ]
  },
  {
    collection: 'jobs/{jobId}/analytics_events',
    fields: [
      { field: 'eventType', order: 'asc' },
      { field: 'timestamp', order: 'desc' }
    ]
  },
  // ... additional indexes
];
```

### Performance Settings
```dart
// Migration performance configuration
const migrationConfig = {
  'batchSize': 10,              // Companies per batch
  'maxConcurrency': 5,          // Parallel operations
  'retryAttempts': 3,           // Retry failed operations
  'timeoutSeconds': 300,        // Operation timeout
  'validationLevel': 'strict',  // Validation strictness
};
```

## 📊 Expected Migration Results

### Data Volume Estimates
- **Companies**: ~100-500 records
- **Jobs**: ~1,000-5,000 records  
- **Applications**: ~5,000-25,000 records
- **Analytics Events**: ~50,000-250,000 new records
- **Aggregations**: ~10,000-50,000 new records

### Performance Metrics
- **Migration Time**: 15-45 minutes (depending on data volume)
- **Firestore Reads**: ~10,000-50,000 operations
- **Firestore Writes**: ~50,000-250,000 operations
- **Memory Usage**: ~100-500 MB peak
- **Network Transfer**: ~10-100 MB

### Success Criteria
- ✅ 100% data integrity maintained
- ✅ All companies have analytics summaries
- ✅ Historical data properly aggregated
- ✅ Analytics services functional
- ✅ Dashboard displays correctly

## 🚨 Troubleshooting

### Common Issues

#### Migration Fails During Data Migration
```bash
# Check logs for specific errors
dart analytics_migration_cli.dart logs

# Retry with specific companies
dart analytics_migration_cli.dart migrate --companies=failed_company_id

# Skip validation if data issues
dart analytics_migration_cli.dart migrate --skip-validation
```

#### Firestore Permission Errors
```bash
# Verify Firebase project configuration
firebase projects:list

# Check Firestore rules
firebase firestore:rules:get

# Update security rules if needed
firebase deploy --only firestore:rules
```

#### Performance Issues
```bash
# Monitor Firestore usage
# Check quota limits in Firebase Console
# Reduce batch size if needed
# Increase timeout settings
```

### Error Recovery

#### Partial Migration Failure
1. Check migration logs for specific errors
2. Fix underlying data issues
3. Resume migration for failed companies
4. Validate results after completion

#### Complete Migration Failure
1. Review error logs thoroughly
2. Fix configuration or data issues
3. Execute rollback if necessary
4. Restart migration from beginning

#### Data Inconsistency
1. Run post-migration validation
2. Compare source and target data
3. Fix inconsistencies manually
4. Re-run validation to confirm

## 🔄 Rollback Procedures

### Automatic Rollback
```bash
# Rollback specific migration
dart analytics_migration_cli.dart rollback --migration-id=migration_1234567890

# Force rollback without confirmation
dart analytics_migration_cli.dart rollback --migration-id=migration_1234567890 --force
```

### Manual Rollback
```dart
// Emergency rollback via code
final migration = AnalyticsMigration();
final success = await migration.rollbackMigration();

if (success) {
  print('Rollback completed successfully');
} else {
  print('Manual cleanup required');
}
```

### Post-Rollback Verification
- [ ] Verify analytics collections removed
- [ ] Check original data integrity
- [ ] Test existing functionality
- [ ] Clear analytics caches
- [ ] Restart application services

## 📈 Post-Migration Tasks

### Immediate Actions
1. **Verify Dashboard Functionality**
   - Test company analytics dashboard
   - Verify data visualization
   - Check real-time updates

2. **Enable Analytics Tracking**
   - Activate event tracking
   - Start aggregation services
   - Monitor performance metrics

3. **User Communication**
   - Notify stakeholders of completion
   - Provide analytics training
   - Document new features

### Ongoing Monitoring
- Monitor Firestore usage and costs
- Track analytics performance metrics
- Review data quality regularly
- Optimize queries as needed
- Plan for future enhancements

## 🎯 Success Validation

### Functional Tests
```dart
// Test analytics service
final analytics = AnalyticsService.instance;
final dashboardData = await analytics.getCompanyDashboardData('test_company');
assert(dashboardData.isNotEmpty);

// Test event tracking
await analytics.trackEvent(
  jobId: 'test_job',
  eventType: JobEventType.view,
  source: 'test',
);

// Test aggregation
final timeSeriesData = await analytics.getTimeSeriesData(
  companyId: 'test_company',
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);
assert(timeSeriesData.isNotEmpty);
```

### Performance Validation
- Dashboard loads within 2 seconds
- Analytics queries complete within 1 second
- Real-time updates work correctly
- Memory usage remains stable
- No significant performance degradation

### Data Quality Checks
- All companies have analytics summaries
- Historical data properly aggregated
- Event tracking captures new activities
- Calculations match expected values
- No data loss or corruption

## 📞 Support & Escalation

### Migration Support
- **Technical Issues**: Check troubleshooting guide
- **Data Problems**: Review validation logs
- **Performance Issues**: Monitor Firestore metrics
- **Rollback Needs**: Follow rollback procedures

### Emergency Contacts
- **Development Team**: For technical issues
- **Database Admin**: For Firestore problems
- **Product Owner**: For business decisions
- **DevOps Team**: For infrastructure issues

---

**⚠️ Important**: Always perform a dry run before executing the actual migration. Ensure you have a complete backup and rollback plan ready before proceeding with production migration.

**🎯 Goal**: Seamlessly transition SecuryFlex to advanced analytics capabilities while maintaining 100% data integrity and zero downtime for existing functionality.
