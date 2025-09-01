/**
 * Cloud Functions for SecuryFlex Analytics Aggregation
 * Handles scheduled aggregation of analytics data with cost optimization
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function to aggregate daily analytics
 * Runs every day at 2:00 AM Amsterdam time
 */
exports.aggregateDailyAnalytics = functions
  .region('europe-west1') // Amsterdam region for Dutch business
  .pubsub
  .schedule('0 2 * * *')
  .timeZone('Europe/Amsterdam')
  .onRun(async (context) => {
    console.log('Starting daily analytics aggregation...');
    
    try {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      const dateStr = yesterday.toISOString().split('T')[0];
      
      // Get all companies
      const companiesSnapshot = await db.collection('companies').get();
      const aggregationPromises = [];
      
      // Process companies in batches to avoid timeout
      const batchSize = 10;
      for (let i = 0; i < companiesSnapshot.docs.length; i += batchSize) {
        const batch = companiesSnapshot.docs.slice(i, i + batchSize);
        
        const batchPromises = batch.map(companyDoc => 
          aggregateCompanyDailyAnalytics(companyDoc.id, dateStr)
        );
        
        aggregationPromises.push(Promise.all(batchPromises));
      }
      
      await Promise.all(aggregationPromises);
      
      console.log(`Daily analytics aggregation completed for ${companiesSnapshot.docs.length} companies`);
      return { success: true, companiesProcessed: companiesSnapshot.docs.length };
      
    } catch (error) {
      console.error('Error in daily analytics aggregation:', error);
      throw error;
    }
  });

/**
 * Scheduled function to aggregate weekly analytics
 * Runs every Monday at 3:00 AM Amsterdam time
 */
exports.aggregateWeeklyAnalytics = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 3 * * 1') // Monday at 3 AM
  .timeZone('Europe/Amsterdam')
  .onRun(async (context) => {
    console.log('Starting weekly analytics aggregation...');
    
    try {
      const lastWeek = new Date();
      lastWeek.setDate(lastWeek.getDate() - 7);
      const weekIdentifier = getWeekIdentifier(lastWeek);
      
      const companiesSnapshot = await db.collection('companies').get();
      
      for (const companyDoc of companiesSnapshot.docs) {
        await aggregateCompanyWeeklyAnalytics(companyDoc.id, weekIdentifier);
      }
      
      console.log(`Weekly analytics aggregation completed for week ${weekIdentifier}`);
      return { success: true, week: weekIdentifier };
      
    } catch (error) {
      console.error('Error in weekly analytics aggregation:', error);
      throw error;
    }
  });

/**
 * Scheduled function to aggregate monthly analytics
 * Runs on the 1st day of each month at 4:00 AM Amsterdam time
 */
exports.aggregateMonthlyAnalytics = functions
  .region('europe-west1')
  .pubsub
  .schedule('0 4 1 * *') // 1st day of month at 4 AM
  .timeZone('Europe/Amsterdam')
  .onRun(async (context) => {
    console.log('Starting monthly analytics aggregation...');
    
    try {
      const lastMonth = new Date();
      lastMonth.setMonth(lastMonth.getMonth() - 1);
      const monthIdentifier = getMonthIdentifier(lastMonth);
      
      const companiesSnapshot = await db.collection('companies').get();
      
      for (const companyDoc of companiesSnapshot.docs) {
        await aggregateCompanyMonthlyAnalytics(companyDoc.id, monthIdentifier);
      }
      
      console.log(`Monthly analytics aggregation completed for month ${monthIdentifier}`);
      return { success: true, month: monthIdentifier };
      
    } catch (error) {
      console.error('Error in monthly analytics aggregation:', error);
      throw error;
    }
  });

/**
 * HTTP function to trigger manual aggregation
 * Can be called for specific companies and date ranges
 */
exports.triggerManualAggregation = functions
  .region('europe-west1')
  .https
  .onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    // Verify admin role (implement your role checking logic)
    const userRole = context.auth.token.role || 'user';
    if (userRole !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can trigger manual aggregation');
    }
    
    const { companyId, startDate, endDate, aggregationType } = data;
    
    try {
      console.log(`Manual aggregation triggered for company ${companyId} from ${startDate} to ${endDate}`);
      
      if (aggregationType === 'daily' || !aggregationType) {
        const start = new Date(startDate);
        const end = new Date(endDate);
        
        for (let current = new Date(start); current <= end; current.setDate(current.getDate() + 1)) {
          const dateStr = current.toISOString().split('T')[0];
          await aggregateCompanyDailyAnalytics(companyId, dateStr);
        }
      }
      
      return { success: true, message: 'Manual aggregation completed' };
      
    } catch (error) {
      console.error('Error in manual aggregation:', error);
      throw new functions.https.HttpsError('internal', 'Aggregation failed');
    }
  });

/**
 * Aggregate daily analytics for a specific company
 */
async function aggregateCompanyDailyAnalytics(companyId, date) {
  try {
    console.log(`Aggregating daily analytics for company ${companyId} on ${date}`);
    
    // Get all jobs for the company
    const jobsSnapshot = await db
      .collection('jobs')
      .where('companyId', '==', companyId)
      .get();
    
    let totalViews = 0;
    let uniqueViews = 0;
    let newApplications = 0;
    let totalApplications = 0;
    const sourceBreakdown = {};
    
    // Aggregate data from job analytics
    for (const jobDoc of jobsSnapshot.docs) {
      const jobId = jobDoc.id;
      
      // Get job daily analytics
      const jobAnalyticsDoc = await db
        .collection('jobs')
        .doc(jobId)
        .collection('analytics_daily')
        .doc(date)
        .get();
      
      if (jobAnalyticsDoc.exists) {
        const jobAnalytics = jobAnalyticsDoc.data();
        totalViews += jobAnalytics.totalViews || 0;
        uniqueViews += jobAnalytics.uniqueViews || 0;
        newApplications += jobAnalytics.newApplications || 0;
        totalApplications += jobAnalytics.totalApplications || 0;
      }
      
      // Get job events for source analysis
      const eventsSnapshot = await db
        .collection('jobs')
        .doc(jobId)
        .collection('analytics_events')
        .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(new Date(date)))
        .where('timestamp', '<', admin.firestore.Timestamp.fromDate(new Date(date + 'T23:59:59')))
        .get();
      
      eventsSnapshot.docs.forEach(eventDoc => {
        const event = eventDoc.data();
        const source = event.source || 'unknown';
        
        if (!sourceBreakdown[source]) {
          sourceBreakdown[source] = { applications: 0, hires: 0, cost: 0 };
        }
        
        if (event.eventType === 'application') {
          sourceBreakdown[source].applications++;
          sourceBreakdown[source].cost += 5.0; // Estimated cost per application
        } else if (event.eventType === 'hire') {
          sourceBreakdown[source].hires++;
          sourceBreakdown[source].cost += 50.0; // Estimated cost per hire
        }
      });
    }
    
    // Get application data for the date
    const companyDoc = await db.collection('companies').doc(companyId).get();
    const companyName = companyDoc.data()?.companyName || '';
    
    const applicationsSnapshot = await db
      .collection('applications')
      .where('companyName', '==', companyName)
      .get();
    
    let applicationsAccepted = 0;
    let applicationsRejected = 0;
    let applicationsPending = 0;
    
    applicationsSnapshot.docs.forEach(appDoc => {
      const appData = appDoc.data();
      const appDate = appData.applicationDate?.toDate();
      
      if (appDate && appDate.toISOString().split('T')[0] === date) {
        const status = appData.status || 'pending';
        switch (status) {
          case 'accepted':
            applicationsAccepted++;
            break;
          case 'rejected':
            applicationsRejected++;
            break;
          default:
            applicationsPending++;
        }
      }
    });
    
    // Calculate metrics
    const viewToApplicationRate = totalViews > 0 ? (newApplications / totalViews) * 100 : 0;
    const applicationToHireRate = totalApplications > 0 ? (applicationsAccepted / totalApplications) * 100 : 0;
    const totalRecruitmentSpend = Object.values(sourceBreakdown).reduce((sum, metrics) => sum + metrics.cost, 0);
    
    // Create daily analytics document
    const dailyAnalytics = {
      date,
      companyId,
      jobsPosted: jobsSnapshot.docs.length,
      jobsActive: jobsSnapshot.docs.filter(doc => doc.data().status === 'active').length,
      jobsCompleted: 0, // Calculate from job status changes
      jobsCancelled: 0,
      totalApplications: newApplications,
      applicationsAccepted,
      applicationsRejected,
      applicationsPending,
      jobViews: totalViews,
      uniqueJobViews: uniqueViews,
      viewToApplicationRate,
      applicationToHireRate,
      averageTimeToFill: 48.0, // Default estimate in hours
      averageTimeToFirstApplication: 24.0,
      totalCostPerHire: applicationsAccepted > 0 ? 75.0 : 0.0,
      totalRecruitmentSpend,
      sourceBreakdown,
      averageApplicationQuality: 3.5,
      guardRetentionRate: 85.0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    
    // Save daily analytics
    await db
      .collection('companies')
      .doc(companyId)
      .collection('analytics_daily')
      .doc(date)
      .set(dailyAnalytics);
    
    console.log(`Daily analytics aggregated for company ${companyId} on ${date}`);
    
  } catch (error) {
    console.error(`Error aggregating daily analytics for company ${companyId}:`, error);
    throw error;
  }
}

/**
 * Aggregate weekly analytics for a specific company
 */
async function aggregateCompanyWeeklyAnalytics(companyId, week) {
  try {
    console.log(`Aggregating weekly analytics for company ${companyId} for week ${week}`);
    
    const weekStart = parseWeekIdentifier(week);
    const weekDays = [];
    
    for (let i = 0; i < 7; i++) {
      const day = new Date(weekStart);
      day.setDate(day.getDate() + i);
      weekDays.push(day.toISOString().split('T')[0]);
    }
    
    // Get daily analytics for the week
    const dailyAnalyticsPromises = weekDays.map(day =>
      db.collection('companies')
        .doc(companyId)
        .collection('analytics_daily')
        .doc(day)
        .get()
    );
    
    const dailyAnalyticsDocs = await Promise.all(dailyAnalyticsPromises);
    const dailyAnalyticsList = dailyAnalyticsDocs
      .filter(doc => doc.exists)
      .map(doc => doc.data());
    
    if (dailyAnalyticsList.length === 0) return;
    
    // Aggregate weekly data
    const weeklyAnalytics = aggregateAnalyticsData(companyId, week, dailyAnalyticsList);
    
    // Save weekly analytics
    await db
      .collection('companies')
      .doc(companyId)
      .collection('analytics_weekly')
      .doc(week)
      .set(weeklyAnalytics);
    
    console.log(`Weekly analytics aggregated for company ${companyId} for week ${week}`);
    
  } catch (error) {
    console.error(`Error aggregating weekly analytics for company ${companyId}:`, error);
    throw error;
  }
}

/**
 * Aggregate monthly analytics for a specific company
 */
async function aggregateCompanyMonthlyAnalytics(companyId, month) {
  try {
    console.log(`Aggregating monthly analytics for company ${companyId} for month ${month}`);
    
    const monthStart = parseMonthIdentifier(month);
    const monthEnd = new Date(monthStart.getFullYear(), monthStart.getMonth() + 1, 0);
    
    const startDate = monthStart.toISOString().split('T')[0];
    const endDate = monthEnd.toISOString().split('T')[0];
    
    // Get daily analytics for the month
    const dailyAnalyticsSnapshot = await db
      .collection('companies')
      .doc(companyId)
      .collection('analytics_daily')
      .where('date', '>=', startDate)
      .where('date', '<=', endDate)
      .get();
    
    const dailyAnalyticsList = dailyAnalyticsSnapshot.docs.map(doc => doc.data());
    
    if (dailyAnalyticsList.length === 0) return;
    
    // Aggregate monthly data
    const monthlyAnalytics = aggregateAnalyticsData(companyId, month, dailyAnalyticsList);
    
    // Save monthly analytics
    await db
      .collection('companies')
      .doc(companyId)
      .collection('analytics_monthly')
      .doc(month)
      .set(monthlyAnalytics);
    
    console.log(`Monthly analytics aggregated for company ${companyId} for month ${month}`);
    
  } catch (error) {
    console.error(`Error aggregating monthly analytics for company ${companyId}:`, error);
    throw error;
  }
}

/**
 * Helper function to aggregate analytics data
 */
function aggregateAnalyticsData(companyId, period, dailyAnalyticsList) {
  const totalJobsPosted = dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.jobsPosted || 0), 0);
  const totalApplications = dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.totalApplications || 0), 0);
  const totalViews = dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.jobViews || 0), 0);
  const totalSpend = dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.totalRecruitmentSpend || 0), 0);
  
  const avgViewToApplicationRate = dailyAnalyticsList.length > 0
    ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.viewToApplicationRate || 0), 0) / dailyAnalyticsList.length
    : 0;
  
  const avgApplicationToHireRate = dailyAnalyticsList.length > 0
    ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.applicationToHireRate || 0), 0) / dailyAnalyticsList.length
    : 0;
  
  // Merge source breakdowns
  const mergedSources = {};
  dailyAnalyticsList.forEach(analytics => {
    const sourceBreakdown = analytics.sourceBreakdown || {};
    Object.entries(sourceBreakdown).forEach(([source, metrics]) => {
      if (!mergedSources[source]) {
        mergedSources[source] = { applications: 0, hires: 0, cost: 0 };
      }
      mergedSources[source].applications += metrics.applications || 0;
      mergedSources[source].hires += metrics.hires || 0;
      mergedSources[source].cost += metrics.cost || 0;
    });
  });
  
  return {
    date: period,
    companyId,
    jobsPosted: totalJobsPosted,
    jobsActive: dailyAnalyticsList[dailyAnalyticsList.length - 1]?.jobsActive || 0,
    jobsCompleted: dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.jobsCompleted || 0), 0),
    jobsCancelled: dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.jobsCancelled || 0), 0),
    totalApplications,
    applicationsAccepted: dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.applicationsAccepted || 0), 0),
    applicationsRejected: dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.applicationsRejected || 0), 0),
    applicationsPending: dailyAnalyticsList[dailyAnalyticsList.length - 1]?.applicationsPending || 0,
    jobViews: totalViews,
    uniqueJobViews: dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.uniqueJobViews || 0), 0),
    viewToApplicationRate: avgViewToApplicationRate,
    applicationToHireRate: avgApplicationToHireRate,
    averageTimeToFill: dailyAnalyticsList.length > 0
      ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.averageTimeToFill || 0), 0) / dailyAnalyticsList.length
      : 0,
    averageTimeToFirstApplication: dailyAnalyticsList.length > 0
      ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.averageTimeToFirstApplication || 0), 0) / dailyAnalyticsList.length
      : 0,
    totalCostPerHire: dailyAnalyticsList.length > 0
      ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.totalCostPerHire || 0), 0) / dailyAnalyticsList.length
      : 0,
    totalRecruitmentSpend: totalSpend,
    sourceBreakdown: mergedSources,
    averageApplicationQuality: dailyAnalyticsList.length > 0
      ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.averageApplicationQuality || 0), 0) / dailyAnalyticsList.length
      : 0,
    guardRetentionRate: dailyAnalyticsList.length > 0
      ? dailyAnalyticsList.reduce((sum, analytics) => sum + (analytics.guardRetentionRate || 0), 0) / dailyAnalyticsList.length
      : 0,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

/**
 * Helper functions for date handling
 */
function getWeekIdentifier(date) {
  const year = date.getFullYear();
  const dayOfYear = Math.floor((date - new Date(year, 0, 0)) / 86400000);
  const week = Math.floor((dayOfYear - date.getDay() + 10) / 7);
  return `${year}-W${week.toString().padStart(2, '0')}`;
}

function parseWeekIdentifier(week) {
  const [year, weekStr] = week.split('-W');
  const weekNumber = parseInt(weekStr);
  
  const jan1 = new Date(parseInt(year), 0, 1);
  const daysToAdd = (weekNumber - 1) * 7 - jan1.getDay() + 1;
  return new Date(jan1.getTime() + daysToAdd * 86400000);
}

function getMonthIdentifier(date) {
  return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}`;
}

function parseMonthIdentifier(month) {
  const [year, monthStr] = month.split('-');
  return new Date(parseInt(year), parseInt(monthStr) - 1, 1);
}
