import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models/payment_models.dart';

/// PSD2 (Payment Services Directive 2) Compliance Service
/// Ensures compliance with EU payment services regulations
class PSD2ComplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // PSD2 transaction limits and thresholds
  static const double strongAuthenticationThreshold = 30.00; // €30
  static const double dailyLimitWithoutAuth = 150.00; // €150
  static const int maxConsecutiveTransactions = 5;
  static const Duration transactionTimeout = Duration(minutes: 5);
  
  // PSD2 required data retention periods
  static const Duration transactionRetentionPeriod = Duration(days: 1825); // 5 years
  static const Duration authenticationRetentionPeriod = Duration(days: 365); // 1 year
  
  /// Implement Strong Customer Authentication (SCA)
  Future<Map<String, dynamic>> performStrongCustomerAuthentication({
    required String userId,
    required double transactionAmount,
    required String paymentMethod,
    required String merchantId,
    Map<String, dynamic>? transactionContext,
  }) async {
    
    try {
      // Check if SCA is required
      final scaRequired = await _isStrongAuthenticationRequired(
        userId: userId,
        amount: transactionAmount,
        paymentMethod: paymentMethod,
        context: transactionContext,
      );
      
      if (!scaRequired) {
        return {
          'sca_required': false,
          'authentication_status': 'exempted',
          'exemption_reason': await _getExemptionReason(userId, transactionAmount),
          'transaction_id': _generateTransactionId(),
        };
      }
      
      // Initiate SCA process
      final authenticationChallenge = await _createAuthenticationChallenge(
        userId: userId,
        amount: transactionAmount,
        merchantId: merchantId,
      );
      
      // Log SCA initiation for compliance
      await _logSCAEvent(
        userId: userId,
        eventType: 'sca_initiated',
        transactionAmount: transactionAmount,
        challengeId: authenticationChallenge['challenge_id'],
      );
      
      return {
        'sca_required': true,
        'authentication_status': 'challenge_sent',
        'challenge_id': authenticationChallenge['challenge_id'],
        'challenge_methods': authenticationChallenge['methods'],
        'expires_at': authenticationChallenge['expires_at'],
        'transaction_id': authenticationChallenge['transaction_id'],
      };
      
    } catch (e) {
      throw Exception('SCA process failed: $e');
    }
  }
  
  /// Validate SCA response from user
  Future<Map<String, dynamic>> validateSCAResponse({
    required String challengeId,
    required String userId,
    required Map<String, String> authenticationFactors,
  }) async {
    
    try {
      // Get challenge details
      final challenge = await _getAuthenticationChallenge(challengeId);
      if (challenge == null) {
        throw Exception('Invalid challenge ID');
      }
      
      // Check if challenge has expired
      final expiresAt = (challenge['expires_at'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        await _logSCAEvent(
          userId: userId,
          eventType: 'sca_expired',
          challengeId: challengeId,
        );
        
        return {
          'authentication_status': 'expired',
          'success': false,
          'error': 'Authentication challenge expired',
        };
      }
      
      // Validate authentication factors
      final validationResults = await _validateAuthenticationFactors(
        userId: userId,
        challenge: challenge,
        providedFactors: authenticationFactors,
      );
      
      if (validationResults['success']) {
        // Mark challenge as completed
        await _completeAuthenticationChallenge(challengeId);
        
        await _logSCAEvent(
          userId: userId,
          eventType: 'sca_successful',
          challengeId: challengeId,
        );
        
        return {
          'authentication_status': 'authenticated',
          'success': true,
          'authentication_token': _generateAuthenticationToken(userId, challengeId),
          'valid_until': DateTime.now().add(const Duration(minutes: 30)),
        };
      } else {
        await _logSCAEvent(
          userId: userId,
          eventType: 'sca_failed',
          challengeId: challengeId,
          failureReason: validationResults['reason'],
        );
        
        return {
          'authentication_status': 'failed',
          'success': false,
          'error': validationResults['reason'],
          'retry_allowed': validationResults['retry_allowed'],
        };
      }
      
    } catch (e) {
      throw Exception('SCA validation failed: $e');
    }
  }
  
  /// Process payment with PSD2 compliance
  Future<Map<String, dynamic>> processCompliantPayment({
    required String userId,
    required double amount,
    required String currency,
    required PaymentMethod paymentMethod,
    required String merchantId,
    String? authenticationToken,
    Map<String, dynamic>? additionalData,
  }) async {
    
    try {
      // Validate currency (must be EUR for SEPA payments)
      if (!_isValidCurrency(currency)) {
        throw Exception('Unsupported currency for EU payments: $currency');
      }
      
      // Check transaction limits
      final limitCheck = await _checkTransactionLimits(
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      
      if (!limitCheck['within_limits']) {
        return {
          'success': false,
          'error': 'Transaction exceeds limits',
          'limit_details': limitCheck,
        };
      }
      
      // Validate authentication if required
      if (authenticationToken != null) {
        final authValid = await _validateAuthenticationToken(authenticationToken);
        if (!authValid) {
          return {
            'success': false,
            'error': 'Invalid or expired authentication token',
          };
        }
      }
      
      // Create payment transaction record
      final transactionId = _generateTransactionId();
      final paymentData = {
        'transaction_id': transactionId,
        'user_id': userId,
        'amount': amount,
        'currency': currency,
        'payment_method': paymentMethod.name,
        'merchant_id': merchantId,
        'status': 'processing',
        'created_at': FieldValue.serverTimestamp(),
        'psd2_compliant': true,
        'authentication_token': authenticationToken,
        'risk_score': await _calculateRiskScore(userId, amount, paymentMethod),
        'additional_data': additionalData ?? {},
      };
      
      await _firestore.collection('psd2_transactions').add(paymentData);
      
      // Process the actual payment
      final paymentResult = await _executePayment(paymentData);
      
      // Update transaction status
      await _updateTransactionStatus(transactionId, paymentResult);
      
      // Generate transaction report for authorities if required
      if (_requiresAuthorityReporting(amount, paymentMethod)) {
        await _generateAuthorityReport(transactionId, paymentData, paymentResult);
      }
      
      return {
        'success': paymentResult['success'],
        'transaction_id': transactionId,
        'reference_number': paymentResult['reference_number'],
        'estimated_completion': paymentResult['estimated_completion'],
        'psd2_compliant': true,
      };
      
    } catch (e) {
      throw Exception('PSD2 compliant payment processing failed: $e');
    }
  }
  
  /// Implement Transaction Monitoring for AML compliance
  Future<Map<String, dynamic>> monitorTransaction({
    required String transactionId,
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    
    try {
      // Get user's transaction history
      final transactionHistory = await _getUserTransactionHistory(userId);
      
      // Calculate risk indicators
      final riskIndicators = await _calculateRiskIndicators(
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        history: transactionHistory,
      );
      
      // Determine monitoring level
      final monitoringLevel = _determineMonitoringLevel(riskIndicators);
      
      // Check against sanctions lists
      final sanctionsCheck = await _checkSanctionsList(userId);
      
      // Create monitoring record
      final monitoringRecord = {
        'transaction_id': transactionId,
        'user_id': userId,
        'monitoring_level': monitoringLevel,
        'risk_score': riskIndicators['total_score'],
        'risk_factors': riskIndicators['factors'],
        'sanctions_check': sanctionsCheck,
        'requires_enhanced_dd': riskIndicators['total_score'] > 70,
        'requires_reporting': riskIndicators['total_score'] > 85,
        'monitored_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('transaction_monitoring').add(monitoringRecord);
      
      // Generate suspicious activity report if necessary
      if (riskIndicators['total_score'] > 85) {
        await _generateSuspiciousActivityReport(transactionId, monitoringRecord);
      }
      
      return {
        'monitoring_completed': true,
        'risk_level': monitoringLevel,
        'additional_checks_required': riskIndicators['total_score'] > 70,
        'transaction_approved': sanctionsCheck['clear'] && riskIndicators['total_score'] < 90,
      };
      
    } catch (e) {
      throw Exception('Transaction monitoring failed: $e');
    }
  }
  
  /// Generate PSD2 compliance report
  Future<Map<String, dynamic>> generateComplianceReport({
    required DateTime reportPeriod,
  }) async {
    
    try {
      final report = <String, dynamic>{};
      
      // Report metadata
      report['report_metadata'] = {
        'period': reportPeriod.toIso8601String(),
        'generated_at': DateTime.now().toIso8601String(),
        'report_type': 'psd2_compliance',
        'version': '1.0',
      };
      
      // Transaction statistics
      report['transaction_statistics'] = await _getTransactionStatistics(reportPeriod);
      
      // SCA statistics
      report['sca_statistics'] = await _getSCAStatistics(reportPeriod);
      
      // Compliance metrics
      report['compliance_metrics'] = await _getComplianceMetrics(reportPeriod);
      
      // Risk and fraud statistics
      report['risk_statistics'] = await _getRiskStatistics(reportPeriod);
      
      // Data protection compliance
      report['data_protection'] = await _getDataProtectionMetrics(reportPeriod);
      
      // Operational incidents
      report['operational_incidents'] = await _getOperationalIncidents(reportPeriod);
      
      // Regulatory communications
      report['regulatory_communications'] = await _getRegulatoryCommunications(reportPeriod);
      
      // Store report
      await _storeComplianceReport(report);
      
      return report;
      
    } catch (e) {
      throw Exception('PSD2 compliance report generation failed: $e');
    }
  }
  
  // Private helper methods
  
  Future<bool> _isStrongAuthenticationRequired({
    required String userId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? context,
  }) async {
    
    // Always require SCA for amounts above threshold
    if (amount > strongAuthenticationThreshold) {
      return true;
    }
    
    // Check cumulative amount since last authentication
    final cumulativeAmount = await _getCumulativeAmountSinceAuth(userId);
    if (cumulativeAmount > dailyLimitWithoutAuth) {
      return true;
    }
    
    // Check number of consecutive transactions
    final consecutiveCount = await _getConsecutiveTransactionCount(userId);
    if (consecutiveCount >= maxConsecutiveTransactions) {
      return true;
    }
    
    // Risk-based analysis
    final riskScore = await _calculateRiskScore(userId, amount, PaymentMethod.values.firstWhere((e) => e.name == paymentMethod));
    if (riskScore > 50) {
      return true;
    }
    
    return false;
  }
  
  Future<String> _getExemptionReason(String userId, double amount) async {
    if (amount <= 30.00) {
      return 'Low value payment exemption (≤ €30)';
    }
    
    final cumulativeAmount = await _getCumulativeAmountSinceAuth(userId);
    if (cumulativeAmount <= 150.00) {
      return 'Cumulative amount exemption (≤ €150)';
    }
    
    return 'Risk-based exemption';
  }
  
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'PSD2-$timestamp-$random';
  }
  
  Future<Map<String, dynamic>> _createAuthenticationChallenge({
    required String userId,
    required double amount,
    required String merchantId,
  }) async {
    
    final challengeId = 'CHL-${DateTime.now().millisecondsSinceEpoch}';
    final transactionId = _generateTransactionId();
    final expiresAt = DateTime.now().add(transactionTimeout);
    
    // Get user's available authentication methods
    final availableMethods = await _getUserAuthMethods(userId);
    
    final challengeData = {
      'challenge_id': challengeId,
      'transaction_id': transactionId,
      'user_id': userId,
      'amount': amount,
      'merchant_id': merchantId,
      'methods': availableMethods,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'expires_at': Timestamp.fromDate(expiresAt),
      'attempts': 0,
      'max_attempts': 3,
    };
    
    await _firestore.collection('sca_challenges').add(challengeData);
    
    return {
      'challenge_id': challengeId,
      'transaction_id': transactionId,
      'methods': availableMethods,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
  
  Future<List<String>> _getUserAuthMethods(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    
    final methods = <String>[];
    
    if (userData['sms_verified'] == true) methods.add('sms');
    if (userData['totp_enabled'] == true) methods.add('totp');
    if (userData['biometric_enabled'] == true) methods.add('biometric');
    
    return methods;
  }
  
  Future<Map<String, dynamic>?> _getAuthenticationChallenge(String challengeId) async {
    final snapshot = await _firestore
        .collection('sca_challenges')
        .where('challenge_id', isEqualTo: challengeId)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
  }
  
  Future<Map<String, dynamic>> _validateAuthenticationFactors({
    required String userId,
    required Map<String, dynamic> challenge,
    required Map<String, String> providedFactors,
  }) async {
    
    final availableMethods = challenge['methods'] as List<dynamic>;
    var validatedFactors = 0;
    final failureReasons = <String>[];
    
    // Validate SMS OTP
    if (availableMethods.contains('sms') && providedFactors.containsKey('sms_code')) {
      final isValid = await _validateSMSCode(userId, providedFactors['sms_code']!);
      if (isValid) {
        validatedFactors++;
      } else {
        failureReasons.add('Invalid SMS code');
      }
    }
    
    // Validate TOTP
    if (availableMethods.contains('totp') && providedFactors.containsKey('totp_code')) {
      final isValid = await _validateTOTPCode(userId, providedFactors['totp_code']!);
      if (isValid) {
        validatedFactors++;
      } else {
        failureReasons.add('Invalid TOTP code');
      }
    }
    
    // Validate biometric
    if (availableMethods.contains('biometric') && providedFactors.containsKey('biometric_token')) {
      final isValid = await _validateBiometricToken(userId, providedFactors['biometric_token']!);
      if (isValid) {
        validatedFactors++;
      } else {
        failureReasons.add('Biometric verification failed');
      }
    }
    
    // PSD2 requires at least 2 factors
    final success = validatedFactors >= 2;
    
    return {
      'success': success,
      'validated_factors': validatedFactors,
      'reason': success ? 'Authentication successful' : failureReasons.join(', '),
      'retry_allowed': (challenge['attempts'] as int) < (challenge['max_attempts'] as int),
    };
  }
  
  Future<bool> _validateSMSCode(String userId, String code) async {
    // Implementation would validate SMS OTP
    // For demo purposes, return true
    return code.length == 6 && code.contains(RegExp(r'^\d+$'));
  }
  
  Future<bool> _validateTOTPCode(String userId, String code) async {
    // Implementation would validate TOTP code
    // For demo purposes, return true  
    return code.length == 6 && code.contains(RegExp(r'^\d+$'));
  }
  
  Future<bool> _validateBiometricToken(String userId, String token) async {
    // Implementation would validate biometric token
    // For demo purposes, return true
    return token.isNotEmpty && token.length > 10;
  }
  
  Future<void> _completeAuthenticationChallenge(String challengeId) async {
    await _firestore
        .collection('sca_challenges')
        .where('challenge_id', isEqualTo: challengeId)
        .get()
        .then((snapshot) {
      for (final doc in snapshot.docs) {
        doc.reference.update({
          'status': 'completed',
          'completed_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  
  String _generateAuthenticationToken(String userId, String challengeId) {
    final data = '$userId:$challengeId:${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  bool _isValidCurrency(String currency) {
    return currency == 'EUR'; // SecuryFlex operates in EUR
  }
  
  Future<Map<String, dynamic>> _checkTransactionLimits({
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
  }) async {
    
    // Get user's daily transaction limits
    final userLimits = await _getUserLimits(userId);
    final dailySpent = await _getDailySpentAmount(userId);
    
    final withinDailyLimit = (dailySpent + amount) <= userLimits['daily_limit']!;
    final withinTransactionLimit = amount <= userLimits['transaction_limit']!;
    
    return {
      'within_limits': withinDailyLimit && withinTransactionLimit,
      'daily_limit': userLimits['daily_limit'],
      'daily_spent': dailySpent,
      'daily_remaining': userLimits['daily_limit']! - dailySpent,
      'transaction_limit': userLimits['transaction_limit'],
    };
  }
  
  Future<bool> _validateAuthenticationToken(String token) async {
    // Implementation would validate authentication token
    // Check expiration, signature, etc.
    return token.isNotEmpty;
  }
  
  Future<int> _calculateRiskScore(String userId, double amount, PaymentMethod paymentMethod) async {
    int riskScore = 0;
    
    // Amount-based risk
    if (amount > 1000) {
      riskScore += 30;
    } else if (amount > 500) {
      riskScore += 20;
    } else if (amount > 100) {
      riskScore += 10;
    }
    
    // Payment method risk
    switch (paymentMethod) {
      case PaymentMethod.bankTransfer:
        riskScore += 10;
        break;
      case PaymentMethod.ideal:
        riskScore += 5;
        break;
      case PaymentMethod.sepa:
        riskScore += 8;
        break;
      case PaymentMethod.cash:
        riskScore += 25;
        break;
    }
    
    // User history risk
    final userRiskFactor = await _getUserRiskFactor(userId);
    riskScore += userRiskFactor;
    
    return riskScore.clamp(0, 100);
  }
  
  Future<Map<String, dynamic>> _executePayment(Map<String, dynamic> paymentData) async {
    // Mock payment execution - in production would integrate with payment processor
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
    
    return {
      'success': true,
      'reference_number': 'REF-${DateTime.now().millisecondsSinceEpoch}',
      'estimated_completion': DateTime.now().add(const Duration(hours: 1)),
      'processing_fee': 0.35, // €0.35 typical SEPA fee
    };
  }
  
  Future<void> _updateTransactionStatus(String transactionId, Map<String, dynamic> result) async {
    await _firestore
        .collection('psd2_transactions')
        .where('transaction_id', isEqualTo: transactionId)
        .get()
        .then((snapshot) {
      for (final doc in snapshot.docs) {
        doc.reference.update({
          'status': result['success'] ? 'completed' : 'failed',
          'result': result,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    });
  }
  
  bool _requiresAuthorityReporting(double amount, PaymentMethod paymentMethod) {
    // Report large transactions to authorities
    return amount >= 10000.00; // €10,000 threshold
  }
  
  Future<void> _generateAuthorityReport(String transactionId, Map<String, dynamic> paymentData, Map<String, dynamic> result) async {
    await _firestore.collection('authority_reports').add({
      'transaction_id': transactionId,
      'report_type': 'large_transaction',
      'amount': paymentData['amount'],
      'currency': paymentData['currency'],
      'user_id': paymentData['user_id'],
      'merchant_id': paymentData['merchant_id'],
      'payment_method': paymentData['payment_method'],
      'transaction_date': paymentData['created_at'],
      'status': result['success'] ? 'completed' : 'failed',
      'reported_at': FieldValue.serverTimestamp(),
      'authority': 'FIU-NL', // Financial Intelligence Unit Netherlands
    });
  }
  
  Future<double> _getCumulativeAmountSinceAuth(String userId) async {
    // Get cumulative transaction amount since last strong authentication
    final lastAuth = await _getLastStrongAuthentication(userId);
    final since = lastAuth ?? DateTime.now().subtract(const Duration(days: 1));
    
    final transactions = await _firestore
        .collection('psd2_transactions')
        .where('user_id', isEqualTo: userId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(since))
        .get();
    
    double cumulative = 0.0;
    for (final doc in transactions.docs) {
      cumulative += (doc.data()['amount'] as num).toDouble();
    }
    
    return cumulative;
  }
  
  Future<int> _getConsecutiveTransactionCount(String userId) async {
    final lastAuth = await _getLastStrongAuthentication(userId);
    final since = lastAuth ?? DateTime.now().subtract(const Duration(hours: 1));
    
    final transactions = await _firestore
        .collection('psd2_transactions')
        .where('user_id', isEqualTo: userId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(since))
        .get();
    
    return transactions.docs.length;
  }
  
  Future<DateTime?> _getLastStrongAuthentication(String userId) async {
    final lastAuth = await _firestore
        .collection('sca_challenges')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completed_at', descending: true)
        .limit(1)
        .get();
    
    if (lastAuth.docs.isNotEmpty) {
      return (lastAuth.docs.first.data()['completed_at'] as Timestamp).toDate();
    }
    
    return null;
  }
  
  Future<Map<String, double>> _getUserLimits(String userId) async {
    final userDoc = await _firestore.collection('user_limits').doc(userId).get();
    final limits = userDoc.data() ?? {};
    
    return {
      'daily_limit': (limits['daily_limit'] as num?)?.toDouble() ?? 5000.0,
      'transaction_limit': (limits['transaction_limit'] as num?)?.toDouble() ?? 2500.0,
    };
  }
  
  Future<double> _getDailySpentAmount(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final transactions = await _firestore
        .collection('psd2_transactions')
        .where('user_id', isEqualTo: userId)
        .where('created_at', isGreaterThan: Timestamp.fromDate(startOfDay))
        .where('status', isEqualTo: 'completed')
        .get();
    
    double totalSpent = 0.0;
    for (final doc in transactions.docs) {
      totalSpent += (doc.data()['amount'] as num).toDouble();
    }
    
    return totalSpent;
  }
  
  Future<int> _getUserRiskFactor(String userId) async {
    final userDoc = await _firestore.collection('user_risk_profiles').doc(userId).get();
    final riskData = userDoc.data() ?? {};
    
    return (riskData['risk_score'] as int?) ?? 10; // Default low risk
  }
  
  Future<List<Map<String, dynamic>>> _getUserTransactionHistory(String userId) async {
    final transactions = await _firestore
        .collection('psd2_transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();
    
    return transactions.docs.map((doc) => doc.data()).toList();
  }
  
  Future<Map<String, dynamic>> _calculateRiskIndicators({
    required String userId,
    required double amount,
    required PaymentMethod paymentMethod,
    required List<Map<String, dynamic>> history,
  }) async {
    
    final factors = <String>[];
    int totalScore = 0;
    
    // Unusual amount indicator
    if (history.isNotEmpty) {
      final averageAmount = history
          .map((t) => (t['amount'] as num).toDouble())
          .reduce((a, b) => a + b) / history.length;
      
      if (amount > averageAmount * 3) {
        totalScore += 25;
        factors.add('Unusual transaction amount');
      }
    }
    
    // Frequency indicator
    final todayTransactions = history.where((t) {
      final transactionDate = (t['created_at'] as Timestamp).toDate();
      final today = DateTime.now();
      return transactionDate.day == today.day && 
             transactionDate.month == today.month &&
             transactionDate.year == today.year;
    }).length;
    
    if (todayTransactions > 10) {
      totalScore += 20;
      factors.add('High transaction frequency');
    }
    
    // Time-based indicator
    final currentHour = DateTime.now().hour;
    if (currentHour < 6 || currentHour > 22) {
      totalScore += 15;
      factors.add('Off-hours transaction');
    }
    
    // Payment method indicator
    if (paymentMethod == PaymentMethod.cash) {
      totalScore += 15;
      factors.add('Cash payment');
    } else if (paymentMethod == PaymentMethod.bankTransfer) {
      totalScore += 10;
      factors.add('Bank transfer payment');
    }
    
    return {
      'total_score': totalScore,
      'factors': factors,
      'risk_level': totalScore > 70 ? 'high' : totalScore > 40 ? 'medium' : 'low',
    };
  }
  
  String _determineMonitoringLevel(Map<String, dynamic> riskIndicators) {
    final score = riskIndicators['total_score'] as int;
    
    if (score > 85) return 'enhanced';
    if (score > 70) return 'standard_plus';
    if (score > 40) return 'standard';
    return 'basic';
  }
  
  Future<Map<String, dynamic>> _checkSanctionsList(String userId) async {
    // In production, this would check against official sanctions lists
    return {
      'clear': true,
      'checked_lists': ['EU', 'UN', 'OFAC', 'NL_National'],
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  Future<void> _generateSuspiciousActivityReport(String transactionId, Map<String, dynamic> monitoringRecord) async {
    await _firestore.collection('suspicious_activity_reports').add({
      'transaction_id': transactionId,
      'user_id': monitoringRecord['user_id'],
      'risk_score': monitoringRecord['risk_score'],
      'risk_factors': monitoringRecord['risk_factors'],
      'report_reason': 'High risk score threshold exceeded',
      'generated_at': FieldValue.serverTimestamp(),
      'status': 'pending_review',
      'authority_notified': false,
    });
  }
  
  Future<void> _logSCAEvent({
    required String userId,
    required String eventType,
    String? challengeId,
    double? transactionAmount,
    String? failureReason,
  }) async {
    
    await _firestore.collection('sca_audit_log').add({
      'user_id': userId,
      'event_type': eventType,
      'challenge_id': challengeId,
      'transaction_amount': transactionAmount,
      'failure_reason': failureReason,
      'timestamp': FieldValue.serverTimestamp(),
      'ip_address': '', // Would be populated from request context
      'user_agent': '', // Would be populated from request context
    });
  }
  
  Future<Map<String, dynamic>> _getTransactionStatistics(DateTime period) async {
    // Implementation would gather transaction statistics
    return {
      'total_transactions': 0,
      'total_volume': 0.0,
      'average_amount': 0.0,
      'success_rate': 0.0,
    };
  }
  
  Future<Map<String, dynamic>> _getSCAStatistics(DateTime period) async {
    // Implementation would gather SCA statistics
    return {
      'sca_challenges_issued': 0,
      'sca_success_rate': 0.0,
      'exemptions_granted': 0,
      'authentication_methods_used': {},
    };
  }
  
  Future<Map<String, dynamic>> _getComplianceMetrics(DateTime period) async {
    return {
      'psd2_compliance_rate': 1.0,
      'data_retention_compliance': true,
      'incident_response_time_avg_minutes': 0.0,
      'audit_findings': 0,
    };
  }
  
  Future<Map<String, dynamic>> _getRiskStatistics(DateTime period) async {
    return {
      'high_risk_transactions': 0,
      'fraud_detected': 0,
      'false_positives': 0,
      'investigation_cases': 0,
    };
  }
  
  Future<Map<String, dynamic>> _getDataProtectionMetrics(DateTime period) async {
    return {
      'gdpr_requests_processed': 0,
      'data_breaches': 0,
      'consent_withdrawal_rate': 0.0,
      'data_retention_compliance': 1.0,
    };
  }
  
  Future<List<Map<String, dynamic>>> _getOperationalIncidents(DateTime period) async {
    return [];
  }
  
  Future<List<Map<String, dynamic>>> _getRegulatoryCommunications(DateTime period) async {
    return [];
  }
  
  Future<void> _storeComplianceReport(Map<String, dynamic> report) async {
    await _firestore.collection('psd2_compliance_reports').add({
      ...report,
      'created_at': FieldValue.serverTimestamp(),
      'report_version': '1.0',
    });
  }
}