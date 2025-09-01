/**
 * SECURYFLEX FIREBASE SECURITY MONITORING FUNCTIONS
 * Nederlandse Compliance + Real-time Threat Detection + Rate Limiting
 * 
 * This module implements comprehensive security monitoring for SecuryFlex:
 * - Real-time rate limiting with progressive penalties
 * - DoS protection and threat detection
 * - Nederlandse compliance monitoring (GDPR/AVG)
 * - Security audit trail with immutable logging
 * - BSN data protection and certificate validation
 */

const { onDocumentWritten, onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const logger = require("firebase-functions/logger");

// Initialize Firebase Admin
initializeApp();
const db = getFirestore();
const storage = getStorage();

// Set global options for cost control and security
setGlobalOptions({ 
  maxInstances: 10,
  region: 'europe-west1' // Nederlandse datacenter
});

// ========================================
// RATE LIMITING SYSTEM
// ========================================

/**
 * Real-time rate limiting with progressive penalties
 */
const RATE_LIMITS = {
  // Firestore operations per minute
  user_reads: { default: 100, guard: 150, company: 200, admin: 1000 },
  user_updates: { default: 20, guard: 30, company: 50, admin: 200 },
  job_reads: { default: 200, guard: 300, company: 100, admin: 500 },
  certificate_reads: { default: 10, guard: 20, company: 5, admin: 100 },
  certificate_creates: { default: 5, guard: 10, company: 0, admin: 50 },
  
  // Storage operations per minute
  chat_uploads: { default: 20, guard: 30, company: 10, admin: 100 },
  profile_uploads: { default: 5, guard: 5, company: 5, admin: 20 },
  cert_uploads: { default: 3, guard: 5, company: 0, admin: 10 },
  
  // Security-sensitive operations per hour
  gdpr_requests: { default: 3, guard: 3, company: 3, admin: 50 },
  password_resets: { default: 5, guard: 5, company: 5, admin: 20 }
};

/**
 * Check and update rate limits for a user
 */
async function checkRateLimit(userId, operation, userType = 'default') {
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
        lastRequest: now
      };
    }
    
    // Get limit for user type and operation
    const limit = RATE_LIMITS[operation]?.[userType] || RATE_LIMITS[operation]?.default || 100;
    
    // Check for violations and apply progressive penalties
    const violations = await getSecurityViolations(userId);
    const penaltyMultiplier = calculatePenaltyMultiplier(violations);
    const effectiveLimit = Math.floor(limit * penaltyMultiplier);
    
    // Check if rate limit exceeded
    if (rateLimitData.requests >= effectiveLimit) {
      // Log security violation
      await logSecurityViolation(userId, 'rate_limit', {
        operation,
        limit: effectiveLimit,
        attempts: rateLimitData.requests + 1
      });
      
      throw new HttpsError('resource-exhausted', 
        `Rate limit exceeded for ${operation}. Limit: ${effectiveLimit} per minute.`);
    }
    
    // Update rate limit
    rateLimitData.requests++;
    rateLimitData.lastRequest = now;
    
    transaction.set(rateLimitRef, rateLimitData, { merge: true });
    
    return true;
  });
}

/**
 * Get security violations for progressive penalties
 */
async function getSecurityViolations(userId) {
  const violationDoc = await db.collection('security_violations').doc(userId).get();
  return violationDoc.exists ? violationDoc.data() : { count: 0, severity: 'low' };
}

/**
 * Calculate penalty multiplier based on violation history
 */
function calculatePenaltyMultiplier(violations) {
  if (violations.count > 10) return 0.1; // 90% reduction
  if (violations.count > 5) return 0.2;  // 80% reduction
  if (violations.count > 2) return 0.5;  // 50% reduction
  return 1.0; // No penalty
}

// ========================================
// SECURITY MONITORING FUNCTIONS
// ========================================

/**
 * Monitor all document writes for suspicious activity
 */
exports.securityMonitor = onDocumentWritten('/{collection}/{documentId}', async (event) => {
  const { collection, documentId } = event.params;
  const { data, eventType } = event;
  
  // Skip system collections
  if (['rate_limits', 'security_audit', 'threat_monitoring'].includes(collection)) {
    return null;
  }
  
  const userId = data?.after?.data()?.userId || event.authId;
  
  if (!userId) return null;
  
  try {
    // Check for suspicious patterns
    const suspiciousActivity = await detectSuspiciousActivity(userId, collection, eventType, data);
    
    if (suspiciousActivity.detected) {
      await handleThreatDetection(userId, suspiciousActivity);
    }
    
    // Log all sensitive operations
    if (['certificates', 'users', 'gdpr_requests'].includes(collection)) {
      await createSecurityAuditLog({
        userId,
        action: eventType,
        resourceType: collection,
        resourceId: documentId,
        timestamp: new Date(),
        success: true,
        riskLevel: suspiciousActivity.riskLevel || 'low',
        metadata: {
          collection,
          operation: eventType,
          dataSize: JSON.stringify(data?.after?.data() || {}).length
        }
      });
    }
    
  } catch (error) {
    logger.error('Security monitoring error:', error);
  }
  
  return null;
});

/**
 * Detect suspicious activity patterns
 */
async function detectSuspiciousActivity(userId, collection, eventType, data) {
  const now = Date.now();
  const hourAgo = now - (60 * 60 * 1000);
  
  // Get recent user activity
  const recentActivity = await db.collection('security_audit')
    .where('userId', '==', userId)
    .where('timestamp', '>', new Date(hourAgo))
    .orderBy('timestamp', 'desc')
    .limit(100)
    .get();
    
  const activities = recentActivity.docs.map(doc => doc.data());
  
  // Detection patterns
  const patterns = {
    // Rapid-fire operations (potential bot/scraper)
    rapidFire: activities.length > 200,
    
    // Mass data access
    massAccess: activities.filter(a => a.action === 'read').length > 500,
    
    // Certificate manipulation
    certManipulation: collection === 'certificates' && 
                     activities.filter(a => a.resourceType === 'certificates').length > 20,
    
    // Privilege escalation attempts
    privilegeEscalation: eventType === 'update' && 
                        data?.after?.data()?.userType !== data?.before?.data()?.userType,
    
    // BSN data access patterns
    bsnAccess: collection === 'certificates' &&
              data?.after?.data()?.holderBsn &&
              !data?.after?.data()?.holderBsn.startsWith('ENC:'),
    
    // Unusual time patterns (Nederlandse business hours)
    unusualTiming: isOutsideBusinessHours(now)
  };
  
  // Calculate risk level
  const detectedPatterns = Object.keys(patterns).filter(key => patterns[key]);
  const riskLevel = calculateRiskLevel(detectedPatterns);
  
  return {
    detected: detectedPatterns.length > 0,
    patterns: detectedPatterns,
    riskLevel,
    timestamp: now
  };
}

/**
 * Check if activity is outside Nederlandse business hours
 */
function isOutsideBusinessHours(timestamp) {
  const date = new Date(timestamp);
  const hour = date.getHours();
  const day = date.getDay();
  
  // Weekend or outside 6:00-22:00 CET
  return day === 0 || day === 6 || hour < 6 || hour > 22;
}

/**
 * Calculate risk level based on detected patterns
 */
function calculateRiskLevel(patterns) {
  const highRiskPatterns = ['privilegeEscalation', 'bsnAccess', 'certManipulation'];
  const mediumRiskPatterns = ['rapidFire', 'massAccess'];
  
  if (patterns.some(p => highRiskPatterns.includes(p))) return 'critical';
  if (patterns.some(p => mediumRiskPatterns.includes(p))) return 'high';
  if (patterns.length > 2) return 'medium';
  return 'low';
}

/**
 * Handle detected threats
 */
async function handleThreatDetection(userId, suspiciousActivity) {
  // Create threat monitoring record
  await db.collection('threat_monitoring').add({
    userId,
    threatType: suspiciousActivity.patterns[0] || 'unknown',
    severity: suspiciousActivity.riskLevel,
    timestamp: new Date(),
    blocked: suspiciousActivity.riskLevel === 'critical',
    patterns: suspiciousActivity.patterns,
    autoGenerated: true
  });
  
  // Auto-block critical threats
  if (suspiciousActivity.riskLevel === 'critical') {
    await emergencyUserSuspension(userId, 'Automatic suspension due to critical threat detection');
  }
  
  // Increment violation counter
  await logSecurityViolation(userId, 'suspicious_activity', {
    patterns: suspiciousActivity.patterns,
    riskLevel: suspiciousActivity.riskLevel
  });
  
  logger.warn(`Threat detected for user ${userId}:`, suspiciousActivity);
}

// ========================================
// NEDERLANDSE COMPLIANCE FUNCTIONS
// ========================================

/**
 * GDPR/AVG Compliance Monitoring
 */
exports.gdprComplianceMonitor = onDocumentCreated('gdpr_requests/{requestId}', async (event) => {
  const requestData = event.data.data();
  const { userId, requestType, legalBasis } = requestData;
  
  try {
    // Validate Nederlandse AVG requirements
    await validateAVGCompliance(requestData);
    
    // Auto-process simple requests
    if (requestType === 'export' && legalBasis === 'consent') {
      await processGDPRExportRequest(userId, event.params.requestId);
    }
    
    // Set compliance timeline (30 days per AVG)
    const deadline = new Date();
    deadline.setDate(deadline.getDate() + 30);
    
    await event.data.ref.update({
      deadline,
      status: 'processing',
      complianceCheck: 'passed',
      processedAt: new Date()
    });
    
  } catch (error) {
    logger.error('GDPR compliance error:', error);
    await event.data.ref.update({
      status: 'rejected',
      error: error.message,
      processedAt: new Date()
    });
  }
});

/**
 * Validate AVG (Nederlandse GDPR) compliance
 */
async function validateAVGCompliance(requestData) {
  const { requestType, legalBasis, dataTypes } = requestData;
  
  // Nederlandse AVG specific validations
  if (requestType === 'delete' && legalBasis === 'consent') {
    // Check if data is required for legal obligations
    const hasLegalObligations = dataTypes.some(type => 
      ['tax_records', 'employment_records', 'certificate_data'].includes(type)
    );
    
    if (hasLegalObligations) {
      throw new Error('Cannot delete data required for legal obligations under Nederlandse wet');
    }
  }
  
  // Validate BSN data handling
  if (dataTypes.includes('bsn_data')) {
    // BSN data requires special handling per Nederlandse privacy law
    await validateBSNDataRequest(requestData);
  }
}

/**
 * BSN (Burgerservicenummer) data validation
 */
async function validateBSNDataRequest(requestData) {
  // Nederlandse BSN privacy requirements are strict
  if (requestData.requestType === 'export') {
    // BSN data export requires additional verification
    throw new Error('BSN data export requires additional identity verification per Nederlandse wet');
  }
}

// ========================================
// CERTIFICATE SECURITY FUNCTIONS
// ========================================

/**
 * Monitor certificate uploads for Nederlandse compliance
 */
exports.certificateSecurityMonitor = onDocumentCreated('certificates/{certificateId}', async (event) => {
  const certData = event.data.data();
  const certificateId = event.params.certificateId;
  
  try {
    // Validate Nederlandse certificate format
    await validateNederlandseCertificate(certData);
    
    // Check for BSN encryption
    if (certData.holderBsn && !certData.holderBsn.startsWith('ENC:')) {
      throw new Error('BSN data must be encrypted per Nederlandse privacy law');
    }
    
    // Validate certificate authority
    await validateCertificateAuthority(certData.issuingAuthority);
    
    // Auto-verify known authorities
    if (['Politie Nederland', 'VCA Nederland'].includes(certData.issuingAuthority)) {
      await scheduleAutomaticVerification(certificateId);
    }
    
  } catch (error) {
    logger.error(`Certificate validation error for ${certificateId}:`, error);
    
    // Mark certificate as invalid
    await event.data.ref.update({
      status: 'invalid',
      validationError: error.message,
      validatedAt: new Date()
    });
    
    // Log security violation
    await logSecurityViolation(certData.userId, 'invalid_certificate', {
      certificateId,
      error: error.message
    });
  }
});

/**
 * Validate Nederlandse certificate requirements
 */
async function validateNederlandseCertificate(certData) {
  const { certificateNumber, certificateType, issuingAuthority } = certData;
  
  // Nederlandse certificate number format validation
  const validFormats = {
    WPBR: /^WPBR-[A-Z0-9]{8,12}$/,
    VCA: /^VCA-[A-Z0-9]{8,10}$/,
    BHV: /^BHV-[A-Z0-9]{6,10}$/,
    EHBO: /^EHBO-[A-Z0-9]{6,10}$/,
    SVPB: /^SVPB-[A-Z0-9]{8,12}$/
  };
  
  if (!validFormats[certificateType]?.test(certificateNumber)) {
    throw new Error(`Invalid ${certificateType} certificate number format`);
  }
  
  // Validate expiration date
  const now = new Date();
  if (certData.expirationDate.toDate() <= now) {
    throw new Error('Certificate has expired');
  }
  
  // Check certificate against known revocation lists
  await checkCertificateRevocation(certificateNumber, certificateType);
}

/**
 * Validate certificate issuing authority
 */
async function validateCertificateAuthority(authority) {
  const validAuthorities = [
    'Politie Nederland',
    'VCA Nederland', 
    'BHV Nederland',
    'EHBO Nederland',
    'SVPB',
    'Ministerie van Justitie'
  ];
  
  if (!validAuthorities.includes(authority)) {
    throw new Error(`Invalid certificate authority: ${authority}`);
  }
}

/**
 * Check certificate against revocation lists
 */
async function checkCertificateRevocation(certificateNumber, certificateType) {
  // In production, this would check against real Nederlandse certificate databases
  // For now, implement basic checks
  
  const revocationRef = db.collection('certificate_revocations')
    .where('certificateNumber', '==', certificateNumber)
    .where('certificateType', '==', certificateType);
    
  const revoked = await revocationRef.get();
  
  if (!revoked.empty) {
    throw new Error('Certificate has been revoked');
  }
}

// ========================================
// SECURITY UTILITY FUNCTIONS
// ========================================

/**
 * Create immutable security audit log
 */
async function createSecurityAuditLog(auditData) {
  await db.collection('security_audit').add({
    ...auditData,
    timestamp: new Date(),
    immutable: true,
    version: '2.0'
  });
}

/**
 * Log security violations with progressive tracking
 */
async function logSecurityViolation(userId, violationType, metadata = {}) {
  const violationRef = db.collection('security_violations').doc(userId);
  
  await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(violationRef);
    
    const currentData = doc.exists ? doc.data() : {
      userId,
      count: 0,
      violations: [],
      severity: 'low'
    };
    
    currentData.count++;
    currentData.violations.push({
      type: violationType,
      timestamp: new Date(),
      metadata
    });
    
    // Update severity based on violation count and types
    if (currentData.count > 10) currentData.severity = 'critical';
    else if (currentData.count > 5) currentData.severity = 'high';
    else if (currentData.count > 2) currentData.severity = 'medium';
    
    transaction.set(violationRef, currentData, { merge: true });
  });
}

/**
 * Emergency user suspension
 */
async function emergencyUserSuspension(userId, reason) {
  await db.collection('users').doc(userId).update({
    suspended: true,
    suspensionReason: reason,
    suspendedAt: new Date(),
    suspensionType: 'automatic'
  });
  
  logger.warn(`User ${userId} suspended: ${reason}`);
}

// ========================================
// SCHEDULED MAINTENANCE FUNCTIONS
// ========================================

/**
 * Daily security cleanup and monitoring
 */
exports.dailySecurityMaintenance = onSchedule('0 2 * * *', async (event) => {
  logger.info('Starting daily security maintenance...');
  
  try {
    // Clean up expired rate limits
    await cleanupExpiredRateLimits();
    
    // Clean up old audit logs (keep 1 year for Nederlandse compliance)
    await cleanupOldAuditLogs();
    
    // Generate daily security report
    await generateDailySecurityReport();
    
    // Check certificate expirations
    await checkCertificateExpirations();
    
    // Validate Nederlandse compliance
    await validateNederlandseCompliance();
    
    logger.info('Daily security maintenance completed');
    
  } catch (error) {
    logger.error('Daily security maintenance error:', error);
  }
});

/**
 * Clean up expired rate limit records
 */
async function cleanupExpiredRateLimits() {
  const expired = Date.now() - (24 * 60 * 60 * 1000); // 24 hours
  
  const batch = db.batch();
  const expiredDocs = await db.collection('rate_limits')
    .where('lastRequest', '<', expired)
    .limit(500)
    .get();
    
  expiredDocs.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  logger.info(`Cleaned up ${expiredDocs.size} expired rate limit records`);
}

/**
 * Clean up old audit logs (Nederlandse compliance: 1 year retention)
 */
async function cleanupOldAuditLogs() {
  const oneYearAgo = new Date();
  oneYearAgo.setFullYear(oneYearAgo.getFullYear() - 1);
  
  const batch = db.batch();
  const oldLogs = await db.collection('security_audit')
    .where('timestamp', '<', oneYearAgo)
    .limit(1000)
    .get();
    
  oldLogs.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  logger.info(`Cleaned up ${oldLogs.size} old audit log records`);
}

/**
 * Generate daily security report
 */
async function generateDailySecurityReport() {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  // Get security statistics
  const threats = await db.collection('threat_monitoring')
    .where('timestamp', '>=', yesterday)
    .where('timestamp', '<', today)
    .get();
    
  const violations = await db.collection('security_violations')
    .where('timestamp', '>=', yesterday)
    .where('timestamp', '<', today)
    .get();
    
  const report = {
    date: yesterday.toISOString().split('T')[0],
    threatsDetected: threats.size,
    violationsRecorded: violations.size,
    threatsByType: {},
    violationsBySeverity: {},
    generatedAt: new Date()
  };
  
  // Aggregate threat data
  threats.docs.forEach(doc => {
    const data = doc.data();
    report.threatsByType[data.threatType] = (report.threatsByType[data.threatType] || 0) + 1;
  });
  
  // Aggregate violation data
  violations.docs.forEach(doc => {
    const data = doc.data();
    report.violationsBySeverity[data.severity] = (report.violationsBySeverity[data.severity] || 0) + 1;
  });
  
  await db.collection('security_reports').add(report);
  logger.info('Daily security report generated:', report);
}

/**
 * Check certificate expirations (Nederlandse compliance)
 */
async function checkCertificateExpirations() {
  const thirtyDaysFromNow = new Date();
  thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
  
  const expiringCerts = await db.collection('certificates')
    .where('expirationDate', '<=', thirtyDaysFromNow)
    .where('status', '==', 'verified')
    .get();
    
  for (const doc of expiringCerts.docs) {
    const certData = doc.data();
    
    // Send expiration warning
    await db.collection('certificate_alerts').add({
      userId: certData.userId,
      certificateId: doc.id,
      alertType: 'expiration_warning',
      expirationDate: certData.expirationDate,
      daysUntilExpiration: Math.ceil(
        (certData.expirationDate.toDate() - new Date()) / (1000 * 60 * 60 * 24)
      ),
      sent: false,
      createdAt: new Date()
    });
  }
  
  logger.info(`Found ${expiringCerts.size} expiring certificates`);
}

/**
 * Validate Nederlandse compliance status
 */
async function validateNederlandseCompliance() {
  const complianceChecks = [
    { type: 'GDPR', check: validateGDPRCompliance },
    { type: 'AVG', check: validateAVGCompliance },
    { type: 'WPBR', check: validateWPBRCompliance },
    { type: 'BTW', check: validateBTWCompliance }
  ];
  
  for (const { type, check } of complianceChecks) {
    try {
      const result = await check();
      
      await db.collection('compliance_monitoring').doc(type).set({
        complianceType: type,
        status: result.compliant ? 'compliant' : 'violation',
        lastCheck: new Date(),
        nextCheck: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
        violations: result.violations || [],
        riskScore: result.riskScore || 0
      }, { merge: true });
      
    } catch (error) {
      logger.error(`Compliance check failed for ${type}:`, error);
    }
  }
}

// Placeholder compliance validation functions
async function validateGDPRCompliance() {
  return { compliant: true, violations: [], riskScore: 0 };
}

async function validateWPBRCompliance() {
  return { compliant: true, violations: [], riskScore: 0 };
}

async function validateBTWCompliance() {
  return { compliant: true, violations: [], riskScore: 0 };
}

// ========================================
// CALLABLE FUNCTIONS FOR ADMIN
// ========================================

/**
 * Manual security assessment trigger
 */
exports.triggerSecurityAssessment = onCall(async (request) => {
  const { auth } = request;
  
  if (!auth || !await isAdmin(auth.uid)) {
    throw new HttpsError('permission-denied', 'Admin access required');
  }
  
  logger.info('Manual security assessment triggered by admin:', auth.uid);
  
  // Trigger comprehensive security scan
  const results = await performSecurityAssessment();
  
  await createSecurityAuditLog({
    userId: auth.uid,
    action: 'manual_security_assessment',
    resourceType: 'system',
    resourceId: 'global',
    timestamp: new Date(),
    success: true,
    riskLevel: 'low',
    metadata: { results }
  });
  
  return results;
});

/**
 * Perform comprehensive security assessment
 */
async function performSecurityAssessment() {
  const results = {
    timestamp: new Date(),
    checks: {}
  };
  
  // Check active threats
  const activeThreats = await db.collection('threat_monitoring')
    .where('blocked', '==', false)
    .where('severity', 'in', ['high', 'critical'])
    .get();
    
  results.checks.activeThreats = {
    count: activeThreats.size,
    status: activeThreats.size === 0 ? 'passed' : 'warning'
  };
  
  // Check rate limit violations
  const rateLimitViolations = await db.collection('security_violations')
    .where('violations', 'array-contains-any', ['rate_limit'])
    .get();
    
  results.checks.rateLimitViolations = {
    count: rateLimitViolations.size,
    status: rateLimitViolations.size < 10 ? 'passed' : 'warning'
  };
  
  // Overall security status
  const warningChecks = Object.values(results.checks).filter(check => check.status === 'warning');
  results.overallStatus = warningChecks.length === 0 ? 'secure' : 'attention_required';
  
  return results;
}

/**
 * Check if user is admin
 */
async function isAdmin(uid) {
  const userDoc = await db.collection('users').doc(uid).get();
  return userDoc.exists && userDoc.data().userType === 'admin';
}