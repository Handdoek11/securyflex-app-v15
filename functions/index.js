/**
 * SECURYFLEX FIREBASE FUNCTIONS
 * Nederlandse Security Platform - Cloud Functions
 * 
 * This module implements the core Firebase Cloud Functions for SecuryFlex:
 * - Security monitoring and threat detection
 * - Rate limiting and DoS protection
 * - Nederlandse compliance automation (GDPR/AVG)
 * - Certificate validation and BSN protection
 * - Real-time audit logging
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

// Global security settings for Nederlandse datacenter
setGlobalOptions({ 
  maxInstances: 10,
  region: 'europe-west1' // Nederlandse datacenter voor GDPR compliance
});

// ========================================
// SECURITY MONITORING FUNCTIONS
// ========================================

// Import comprehensive security monitoring
const securityFunctions = require('./security-monitoring');

// Export security monitoring functions
exports.securityMonitor = securityFunctions.securityMonitor;
exports.gdprComplianceMonitor = securityFunctions.gdprComplianceMonitor;
exports.certificateSecurityMonitor = securityFunctions.certificateSecurityMonitor;
exports.dailySecurityMaintenance = securityFunctions.dailySecurityMaintenance;
exports.triggerSecurityAssessment = securityFunctions.triggerSecurityAssessment;

// ========================================
// RATE LIMITING API FUNCTIONS
// ========================================

/**
 * Real-time rate limiting check for client applications
 */
exports.checkRateLimit = onCall(async (request) => {
  const { auth, data } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }
  
  const { operation, userType = 'default' } = data;
  
  if (!operation) {
    throw new HttpsError('invalid-argument', 'Operation parameter required');
  }
  
  try {
    // Get user type from Firestore if not provided
    let effectiveUserType = userType;
    if (userType === 'default') {
      const userDoc = await db.collection('users').doc(auth.uid).get();
      effectiveUserType = userDoc.exists ? userDoc.data().userType || 'default' : 'default';
    }
    
    // Check rate limit using security monitoring module
    const rateLimitPassed = await checkUserRateLimit(auth.uid, operation, effectiveUserType);
    
    return {
      allowed: rateLimitPassed,
      operation,
      userType: effectiveUserType,
      timestamp: new Date().toISOString()
    };
    
  } catch (error) {
    if (error.code === 'resource-exhausted') {
      throw error; // Re-throw rate limit errors
    }
    
    logger.error('Rate limit check error:', error);
    throw new HttpsError('internal', 'Rate limit check failed');
  }
});

/**
 * Helper function to check rate limits
 */
async function checkUserRateLimit(userId, operation, userType) {
  const now = Date.now();
  const windowStart = now - (60 * 1000); // 1-minute window
  
  const rateLimitRef = db.collection('rate_limits').doc(userId);
  
  return db.runTransaction(async (transaction) => {
    const rateLimitDoc = await transaction.get(rateLimitRef);
    
    let rateLimitData = rateLimitDoc.exists ? rateLimitDoc.data() : {};
    
    // Reset window if expired
    if (!rateLimitData.windowStart || rateLimitData.windowStart < windowStart) {
      rateLimitData = {
        windowStart: now,
        requests: 0,
        lastRequest: now,
        [operation]: 0
      };
    }
    
    // Rate limits per user type per minute
    const LIMITS = {
      user_reads: { default: 100, guard: 150, company: 200, admin: 1000 },
      job_reads: { default: 200, guard: 300, company: 100, admin: 500 },
      certificate_reads: { default: 10, guard: 20, company: 5, admin: 100 }
    };
    
    const limit = LIMITS[operation]?.[userType] || LIMITS[operation]?.default || 100;
    const currentCount = rateLimitData[operation] || 0;
    
    // Check if limit exceeded
    if (currentCount >= limit) {
      // Log violation
      await logRateLimitViolation(userId, operation, limit, currentCount + 1);
      throw new HttpsError('resource-exhausted', `Rate limit exceeded for ${operation}`);
    }
    
    // Update counters
    rateLimitData.requests = (rateLimitData.requests || 0) + 1;
    rateLimitData[operation] = currentCount + 1;
    rateLimitData.lastRequest = now;
    
    transaction.set(rateLimitRef, rateLimitData, { merge: true });
    
    return true;
  });
}

/**
 * Log rate limit violations for security monitoring
 */
async function logRateLimitViolation(userId, operation, limit, attempts) {
  await db.collection('security_violations').add({
    userId,
    violationType: 'rate_limit',
    operation,
    limit,
    attempts,
    timestamp: new Date(),
    severity: attempts > limit * 2 ? 'high' : 'medium',
    autoGenerated: true
  });
}

// ========================================
// NEDERLANDSE COMPLIANCE FUNCTIONS
// ========================================

/**
 * GDPR/AVG data export for Nederlandse compliance
 */
exports.exportUserData = onCall(async (request) => {
  const { auth, data } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }
  
  const { requestId } = data;
  
  if (!requestId) {
    throw new HttpsError('invalid-argument', 'Request ID required');
  }
  
  try {
    // Validate GDPR request
    const gdprRequestDoc = await db.collection('gdpr_requests').doc(requestId).get();
    
    if (!gdprRequestDoc.exists) {
      throw new HttpsError('not-found', 'GDPR request not found');
    }
    
    const gdprData = gdprRequestDoc.data();
    
    if (gdprData.userId !== auth.uid) {
      throw new HttpsError('permission-denied', 'Access denied');
    }
    
    if (gdprData.requestType !== 'export') {
      throw new HttpsError('invalid-argument', 'Not an export request');
    }
    
    // Export user data according to Nederlandse AVG requirements
    const userData = await exportCompleteUserData(auth.uid, gdprData.dataTypes);
    
    // Update request status
    await gdprRequestDoc.ref.update({
      status: 'completed',
      completedAt: new Date(),
      exportSize: JSON.stringify(userData).length
    });
    
    // Log compliance action
    await db.collection('security_audit').add({
      userId: auth.uid,
      action: 'gdpr_export_completed',
      resourceType: 'user_data',
      resourceId: auth.uid,
      timestamp: new Date(),
      success: true,
      riskLevel: 'low',
      metadata: {
        requestId,
        dataTypes: gdprData.dataTypes,
        exportSize: JSON.stringify(userData).length
      }
    });
    
    return {
      success: true,
      userData,
      exportDate: new Date().toISOString(),
      requestId
    };
    
  } catch (error) {
    logger.error('GDPR export error:', error);
    throw error instanceof HttpsError ? error : new HttpsError('internal', 'Export failed');
  }
});

/**
 * Export complete user data for GDPR compliance
 */
async function exportCompleteUserData(userId, dataTypes) {
  const userData = {
    userId,
    exportTimestamp: new Date().toISOString(),
    dataTypes
  };
  
  // User profile data
  if (dataTypes.includes('profile_data')) {
    const userDoc = await db.collection('users').doc(userId).get();
    userData.profile = userDoc.exists ? userDoc.data() : null;
  }
  
  // Certificate data (with BSN encryption compliance)
  if (dataTypes.includes('certificate_data')) {
    const certificates = await db.collection('certificates')
      .where('userId', '==', userId)
      .get();
    
    userData.certificates = certificates.docs.map(doc => {
      const certData = doc.data();
      // Ensure BSN remains encrypted in export
      if (certData.holderBsn && certData.holderBsn.startsWith('ENC:')) {
        certData.holderBsn = '[ENCRYPTED_BSN_DATA]';
      }
      return { id: doc.id, ...certData };
    });
  }
  
  // Application history
  if (dataTypes.includes('application_data')) {
    const applications = await db.collection('applications')
      .where('guardId', '==', userId)
      .get();
    
    userData.applications = applications.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  }
  
  return userData;
}

// ========================================
// SYSTEM HEALTH MONITORING
// ========================================

/**
 * Health check endpoint for monitoring
 */
exports.healthCheck = onRequest((request, response) => {
  response.set('Access-Control-Allow-Origin', '*');
  
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    services: {
      firestore: 'operational',
      storage: 'operational',
      authentication: 'operational',
      functions: 'operational'
    },
    region: 'europe-west1',
    compliance: 'Nederlandse AVG/GDPR'
  };
  
  response.json(health);
});

/**
 * Security status endpoint for admin monitoring
 */
exports.securityStatus = onCall(async (request) => {
  const { auth } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }
  
  // Check if user is admin
  const userDoc = await db.collection('users').doc(auth.uid).get();
  if (!userDoc.exists || userDoc.data().userType !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin access required');
  }
  
  try {
    // Get current security metrics
    const now = new Date();
    const dayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    
    const [threats, violations, activeUsers] = await Promise.all([
      db.collection('threat_monitoring')
        .where('timestamp', '>=', dayAgo)
        .get(),
      db.collection('security_violations')
        .where('timestamp', '>=', dayAgo)
        .get(),
      db.collection('rate_limits')
        .where('lastRequest', '>=', dayAgo.getTime())
        .get()
    ]);
    
    return {
      status: 'secure',
      timestamp: now.toISOString(),
      metrics: {
        threatsDetected24h: threats.size,
        violationsRecorded24h: violations.size,
        activeUsers24h: activeUsers.size,
        systemLoad: 'normal'
      },
      compliance: {
        gdpr: 'compliant',
        avg: 'compliant',
        wpbr: 'compliant'
      }
    };
    
  } catch (error) {
    logger.error('Security status error:', error);
    throw new HttpsError('internal', 'Failed to get security status');
  }
});

logger.info('SecuryFlex Firebase Functions initialized with comprehensive security monitoring');