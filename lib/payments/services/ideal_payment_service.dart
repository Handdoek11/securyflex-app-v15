import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';
import '../security/payment_encryption_service.dart';
import 'payment_audit_service.dart';

/// iDEAL payment service for SecuryFlex Dutch market
/// 
/// Features:
/// - iDEAL payment processing for expenses and deposits
/// - Integration with Dutch banks (ABN AMRO, ING, Rabobank, etc.)
/// - Real-time payment confirmation
/// - Refund capabilities
/// - Mobile-optimized payment flow
/// - PCI DSS compliance
/// - Dutch banking regulations compliance
/// - Comprehensive transaction logging
class iDEALPaymentService {
  final FirebaseFirestore _firestore;
  final Dio _httpClient;
  final PaymentEncryptionService _encryptionService;
  final PaymentAuditService _auditService;
  
  // iDEAL configuration
  static const String _idealApiUrl = 'https://api.ideal-payments.nl';
  static const Duration _paymentTimeout = Duration(minutes: 10);
  static const double _minPaymentAmount = 0.01; // €0.01 minimum
  static const double _maxPaymentAmount = 50000.0; // €50,000 maximum
  
  // Supported Dutch banks
  static const Map<String, String> _supportedBanks = {
    'ABNANL2A': 'ABN AMRO',
    'INGBNL2A': 'ING',
    'RABONL2U': 'Rabobank',
    'SNSBNL2A': 'SNS Bank',
    'ASNBNL21': 'ASN Bank',
    'BUNQNL2A': 'Bunq',
    'KNABNL2H': 'Knab',
    'RBRBNL21': 'RegioBank',
    'TRIONL2U': 'Triodos Bank',
    'HANDNL2A': 'Handelsbanken',
  };

  iDEALPaymentService({
    FirebaseFirestore? firestore,
    Dio? httpClient,
    PaymentEncryptionService? encryptionService,
    PaymentAuditService? auditService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _httpClient = httpClient ?? Dio(),
       _encryptionService = encryptionService ?? PaymentEncryptionService(),
       _auditService = auditService ?? PaymentAuditService() {
    _configureHttpClient();
  }

  /// Configure HTTP client for iDEAL API
  void _configureHttpClient() {
    _httpClient.options = BaseOptions(
      baseUrl: _idealApiUrl,
      connectTimeout: _paymentTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'SecuryFlex/1.0 (iDEAL Payment Service)',
      },
    );

    _httpClient.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['Authorization'] = await _getApiKey();
          options.headers['X-Request-ID'] = const Uuid().v4();
          options.headers['X-Merchant-ID'] = _getMerchantId();
          handler.next(options);
        },
        onResponse: (response, handler) {
          _auditService.logPaymentRequest(
            type: 'IDEAL_REQUEST',
            status: 'SUCCESS',
            details: {'status_code': response.statusCode},
          );
          handler.next(response);
        },
        onError: (error, handler) {
          _auditService.logPaymentRequest(
            type: 'IDEAL_ERROR',
            status: 'ERROR',
            details: {'error': error.toString()},
          );
          handler.next(error);
        },
      ),
    );
  }

  /// Get list of available Dutch banks for iDEAL
  Future<List<iDEALBank>> getAvailableBanks() async {
    try {
      final response = await _httpClient.get('/banks');
      
      if (response.statusCode == 200) {
        final banksData = response.data['banks'] as List;
        return banksData.map((bankData) => iDEALBank(
          bic: bankData['bic'],
          name: bankData['name'],
          logoUrl: bankData['logo_url'],
          countryCode: 'NL',
        )).toList();
      } else {
        // Fallback to static list
        return _getSupportedBanksList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch banks from API, using static list: $e');
      }
      return _getSupportedBanksList();
    }
  }

  /// Create iDEAL payment for expense reimbursement or deposit
  Future<iDEALPaymentResult> createPayment({
    required String userId,
    required double amount,
    required String description,
    required String returnUrl,
    required String webhookUrl,
    required PaymentType paymentType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate payment request
      await _validateiDEALPayment(
        amount: amount,
        description: description,
        returnUrl: returnUrl,
      );

      // Create payment record
      final payment = iDEALPayment(
        id: const Uuid().v4(),
        userId: userId,
        amount: amount,
        currency: 'EUR',
        description: description,
        paymentType: paymentType,
        status: PaymentStatus.pending,
        returnUrl: returnUrl,
        webhookUrl: webhookUrl,
        createdAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      // Store encrypted payment data
      await _storeiDEALPaymentRecord(payment);

      // Create iDEAL payment request
      final paymentRequest = {
        'amount': {
          'value': (amount * 100).round(), // Convert to cents
          'currency': 'EUR',
        },
        'description': description,
        'redirectUrl': returnUrl,
        'webhookUrl': webhookUrl,
        'metadata': {
          'payment_id': payment.id,
          'user_id': userId,
          'payment_type': paymentType.name,
          ...metadata ?? {},
        },
        'method': 'ideal',
        'locale': 'nl_NL',
      };

      final response = await _httpClient.post('/payments', data: paymentRequest);

      if (response.statusCode == 201) {
        final responseData = response.data;
        final checkoutUrl = responseData['_links']['checkout']['href'];
        
        // Update payment with provider details
        await _updateiDEALPayment(payment.id, {
          'provider_payment_id': responseData['id'],
          'checkout_url': checkoutUrl,
          'status': PaymentStatus.awaitingBank.name,
        });

        // Log payment creation
        await _auditService.logPaymentTransaction(
          paymentId: payment.id,
          type: paymentType,
          amount: amount,
          status: PaymentStatus.awaitingBank,
          userId: userId,
        );

        return iDEALPaymentResult(
          paymentId: payment.id,
          providerPaymentId: responseData['id'],
          checkoutUrl: checkoutUrl,
          status: PaymentStatus.awaitingBank,
          expiresAt: DateTime.parse(responseData['expiresAt']),
          qrCodeUrl: responseData['details']?['qrCode']?['src'],
        );
      } else {
        throw PaymentException(
          'iDEAL betaling aanmaken mislukt: ${response.statusMessage}',
          PaymentErrorCode.paymentCreationFailed,
        );
      }

    } catch (e) {
      await _handleiDEALError(userId, e);
      rethrow;
    }
  }

  /// Process iDEAL payment with bank selection
  Future<iDEALPaymentResult> processPaymentWithBank({
    required String paymentId,
    required String bankBIC,
  }) async {
    try {
      // Get payment record
      final paymentDoc = await _firestore.collection('ideal_payments').doc(paymentId).get();
      
      if (!paymentDoc.exists) {
        throw PaymentException(
          'iDEAL betaling niet gevonden: $paymentId',
          PaymentErrorCode.paymentNotFound,
        );
      }

      final paymentData = paymentDoc.data()!;
      final providerPaymentId = paymentData['provider_payment_id'];

      // Validate bank
      if (!_supportedBanks.containsKey(bankBIC)) {
        throw PaymentException(
          'Niet-ondersteunde bank: $bankBIC',
          PaymentErrorCode.unsupportedBank,
        );
      }

      // Create bank-specific payment
      final bankPaymentRequest = {
        'issuer': bankBIC,
      };

      final response = await _httpClient.post(
        '/payments/$providerPaymentId/bank-selection',
        data: bankPaymentRequest,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final bankUrl = responseData['_links']['redirect']['href'];

        // Update payment with bank details
        await _updateiDEALPayment(paymentId, {
          'selected_bank_bic': bankBIC,
          'selected_bank_name': _supportedBanks[bankBIC],
          'bank_redirect_url': bankUrl,
          'status': PaymentStatus.awaitingBank.name,
        });

        return iDEALPaymentResult(
          paymentId: paymentId,
          providerPaymentId: providerPaymentId,
          checkoutUrl: bankUrl,
          status: PaymentStatus.awaitingBank,
          selectedBank: iDEALBank(
            bic: bankBIC,
            name: _supportedBanks[bankBIC]!,
            countryCode: 'NL',
          ),
        );
      } else {
        throw PaymentException(
          'Bank selectie mislukt: ${response.statusMessage}',
          PaymentErrorCode.bankSelectionFailed,
        );
      }

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_BANK_SELECTION_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId, 'bank_bic': bankBIC},
      );
      rethrow;
    }
  }

  /// Handle webhook notification from iDEAL provider
  Future<void> handleWebhook({
    required String paymentId,
    required Map<String, dynamic> webhookData,
    required String signature,
  }) async {
    try {
      // Verify webhook signature
      if (!await _verifyWebhookSignature(webhookData, signature)) {
        throw PaymentException(
          'Ongeldige webhook signature',
          PaymentErrorCode.invalidWebhookSignature,
        );
      }

      final providerPaymentId = webhookData['id'];
      final status = _parsePaymentStatus(webhookData['status']);

      // Get payment record
      final paymentsQuery = await _firestore
          .collection('ideal_payments')
          .where('provider_payment_id', isEqualTo: providerPaymentId)
          .get();

      if (paymentsQuery.docs.isEmpty) {
        throw PaymentException(
          'Payment not found for webhook: $providerPaymentId',
          PaymentErrorCode.paymentNotFound,
        );
      }

      final paymentDoc = paymentsQuery.docs.first;
      final localPaymentId = paymentDoc.id;

      // Update payment status
      await _updateiDEALPayment(localPaymentId, {
        'status': status.name,
        'updated_at': Timestamp.now(),
        'webhook_data': webhookData,
      });

      // Handle status-specific actions
      await _handlePaymentStatusChange(localPaymentId, status, webhookData);

      // Log webhook processing
      await _auditService.logWebhookReceived(
        paymentId: localPaymentId,
        providerPaymentId: providerPaymentId,
        status: status,
        webhookData: webhookData,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_WEBHOOK_ERROR',
        error: e.toString(),
        metadata: {'webhook_data': webhookData},
      );
      rethrow;
    }
  }

  /// Get payment status by ID
  Future<PaymentStatus> getPaymentStatus(String paymentId) async {
    try {
      final doc = await _firestore.collection('ideal_payments').doc(paymentId).get();
      
      if (!doc.exists) {
        throw PaymentException(
          'Betaling niet gevonden: $paymentId',
          PaymentErrorCode.paymentNotFound,
        );
      }

      final status = doc.data()!['status'] as String;
      return PaymentStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => PaymentStatus.unknown,
      );

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_STATUS_QUERY_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId},
      );
      return PaymentStatus.unknown;
    }
  }

  /// Create refund for completed iDEAL payment
  Future<RefundResult> createRefund({
    required String paymentId,
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get original payment
      final paymentDoc = await _firestore.collection('ideal_payments').doc(paymentId).get();
      
      if (!paymentDoc.exists) {
        throw PaymentException(
          'Originele betaling niet gevonden: $paymentId',
          PaymentErrorCode.paymentNotFound,
        );
      }

      final paymentData = paymentDoc.data()!;
      final originalAmount = paymentData['amount'] as double;
      
      if (amount > originalAmount) {
        throw PaymentException(
          'Terugbetaling kan niet hoger zijn dan originele betaling',
          PaymentErrorCode.refundAmountTooHigh,
        );
      }

      final providerPaymentId = paymentData['provider_payment_id'];

      // Create refund request
      final refundRequest = {
        'amount': {
          'value': (amount * 100).round(), // Convert to cents
          'currency': 'EUR',
        },
        'description': description,
        'metadata': {
          'original_payment_id': paymentId,
          ...metadata ?? {},
        },
      };

      final response = await _httpClient.post(
        '/payments/$providerPaymentId/refunds',
        data: refundRequest,
      );

      if (response.statusCode == 201) {
        final refundData = response.data;
        
        // Store refund record
        final refundId = const Uuid().v4();
        await _firestore.collection('payment_refunds').doc(refundId).set({
          'id': refundId,
          'original_payment_id': paymentId,
          'provider_refund_id': refundData['id'],
          'amount': amount,
          'currency': 'EUR',
          'description': description,
          'status': refundData['status'],
          'created_at': Timestamp.now(),
          'metadata': metadata ?? {},
        });

        // Log refund creation
        await _auditService.logRefundCreated(
          refundId: refundId,
          originalPaymentId: paymentId,
          amount: amount,
          description: description,
        );

        return RefundResult(
          refundId: refundId,
          providerRefundId: refundData['id'],
          status: _parseRefundStatus(refundData['status']),
          amount: amount,
          createdAt: DateTime.parse(refundData['createdAt']),
        );
      } else {
        throw PaymentException(
          'Terugbetaling aanmaken mislukt: ${response.statusMessage}',
          PaymentErrorCode.refundCreationFailed,
        );
      }

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_REFUND_ERROR',
        error: e.toString(),
        metadata: {'payment_id': paymentId, 'refund_amount': amount},
      );
      rethrow;
    }
  }

  /// Get payment history for user
  Future<List<iDEALPayment>> getUserPaymentHistory({
    required String userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection('ideal_payments')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true);

      if (startDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return iDEALPayment(
          id: doc.id,
          userId: data['user_id'],
          amount: data['amount'].toDouble(),
          currency: data['currency'],
          description: data['description'],
          paymentType: PaymentType.values.firstWhere(
            (t) => t.name == data['payment_type'],
            orElse: () => PaymentType.expense,
          ),
          status: PaymentStatus.values.firstWhere(
            (s) => s.name == data['status'],
            orElse: () => PaymentStatus.unknown,
          ),
          returnUrl: data['return_url'],
          webhookUrl: data['webhook_url'],
          createdAt: (data['created_at'] as Timestamp).toDate(),
          metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        );
      }).toList();

    } catch (e) {
      await _auditService.logPaymentError(
        type: 'IDEAL_HISTORY_ERROR',
        error: e.toString(),
        metadata: {'user_id': userId},
      );
      return [];
    }
  }

  /// Private helper methods

  /// Validate iDEAL payment request
  Future<void> _validateiDEALPayment({
    required double amount,
    required String description,
    required String returnUrl,
  }) async {
    if (amount < _minPaymentAmount || amount > _maxPaymentAmount) {
      throw PaymentException(
        'Bedrag moet tussen €${_minPaymentAmount.toStringAsFixed(2)} en €${_maxPaymentAmount.toStringAsFixed(2)} liggen',
        PaymentErrorCode.invalidAmount,
      );
    }

    if (description.trim().isEmpty || description.length > 35) {
      throw PaymentException(
        'Omschrijving moet tussen 1 en 35 karakters bevatten',
        PaymentErrorCode.invalidDescription,
      );
    }

    final uri = Uri.tryParse(returnUrl);
    if (uri == null || !uri.hasAbsolutePath) {
      throw PaymentException(
        'Ongeldige return URL',
        PaymentErrorCode.invalidReturnUrl,
      );
    }
  }

  /// Store encrypted iDEAL payment record
  Future<void> _storeiDEALPaymentRecord(iDEALPayment payment) async {
    final encryptedData = await _encryptionService.encryptPaymentData({
      'id': payment.id,
      'user_id': payment.userId,
      'amount': payment.amount,
      'description': payment.description,
      'return_url': payment.returnUrl,
      'webhook_url': payment.webhookUrl,
    });

    await _firestore.collection('ideal_payments').doc(payment.id).set({
      'user_id': payment.userId,
      'amount': payment.amount,
      'currency': payment.currency,
      'description': payment.description,
      'payment_type': payment.paymentType.name,
      'status': payment.status.name,
      'return_url': payment.returnUrl,
      'webhook_url': payment.webhookUrl,
      'created_at': Timestamp.fromDate(payment.createdAt),
      'updated_at': Timestamp.fromDate(payment.createdAt),
      'encrypted_data': encryptedData,
      'metadata': payment.metadata,
    });
  }

  /// Update iDEAL payment record
  Future<void> _updateiDEALPayment(String paymentId, Map<String, dynamic> updates) async {
    await _firestore.collection('ideal_payments').doc(paymentId).update({
      ...updates,
      'updated_at': Timestamp.now(),
    });
  }

  /// Get supported banks list
  List<iDEALBank> _getSupportedBanksList() {
    return _supportedBanks.entries.map((entry) => iDEALBank(
      bic: entry.key,
      name: entry.value,
      countryCode: 'NL',
    )).toList();
  }

  /// Parse payment status from provider response
  PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return PaymentStatus.completed;
      case 'pending':
        return PaymentStatus.awaitingBank;
      case 'open':
        return PaymentStatus.pending;
      case 'canceled':
        return PaymentStatus.cancelled;
      case 'failed':
        return PaymentStatus.failed;
      case 'expired':
        return PaymentStatus.expired;
      default:
        return PaymentStatus.unknown;
    }
  }

  /// Parse refund status
  RefundStatus _parseRefundStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RefundStatus.pending;
      case 'processing':
        return RefundStatus.processing;
      case 'refunded':
        return RefundStatus.completed;
      case 'failed':
        return RefundStatus.failed;
      default:
        return RefundStatus.unknown;
    }
  }

  /// Handle payment status changes
  Future<void> _handlePaymentStatusChange(
    String paymentId,
    PaymentStatus status,
    Map<String, dynamic> webhookData,
  ) async {
    switch (status) {
      case PaymentStatus.completed:
        await _processCompletedPayment(paymentId, webhookData);
        break;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.expired:
        await _processFailedPayment(paymentId, webhookData);
        break;
      default:
        // No additional processing needed
        break;
    }
  }

  /// Process completed payment
  Future<void> _processCompletedPayment(String paymentId, Map<String, dynamic> webhookData) async {
    // Update user balance, send notifications, etc.
    final paymentDoc = await _firestore.collection('ideal_payments').doc(paymentId).get();
    
    if (paymentDoc.exists) {
      final paymentData = paymentDoc.data()!;
      final userId = paymentData['user_id'];
      final amount = paymentData['amount'].toDouble();
      
      // Log completed payment
      await _auditService.logPaymentCompleted(
        paymentId: paymentId,
        userId: userId,
        amount: amount,
      );
    }
  }

  /// Process failed payment
  Future<void> _processFailedPayment(String paymentId, Map<String, dynamic> webhookData) async {
    // Log failure reason, send notifications, etc.
    await _auditService.logPaymentFailed(
      paymentId: paymentId,
      reason: webhookData['details']?['failureReason'] ?? 'Unknown',
    );
  }

  /// Verify webhook signature
  Future<bool> _verifyWebhookSignature(Map<String, dynamic> data, String signature) async {
    try {
      final payload = jsonEncode(data);
      final secret = await _getWebhookSecret();
      final expectedSignature = _generateSignature(payload, secret);
      
      return signature == expectedSignature;
    } catch (e) {
      return false;
    }
  }

  /// Generate HMAC signature for webhook verification
  String _generateSignature(String payload, String secret) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return 'sha256=${digest.toString()}';
  }

  /// Handle iDEAL errors
  Future<void> _handleiDEALError(String userId, dynamic error) async {
    await _auditService.logPaymentError(
      type: 'IDEAL_PAYMENT_ERROR',
      error: error.toString(),
      metadata: {'user_id': userId},
    );
  }

  /// Get API key from secure configuration
  Future<String> _getApiKey() async {
    // In production, this would come from encrypted environment variables
    return 'Bearer test_api_key_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get merchant ID from configuration
  String _getMerchantId() {
    // In production, this would come from secure configuration
    return 'securyflex_merchant_id';
  }

  /// Get webhook secret for signature verification
  Future<String> _getWebhookSecret() async {
    // In production, this would come from encrypted environment variables
    return 'webhook_secret_key';
  }

  /// Generate QR code for mobile payments
  Future<String?> generateQRCode(String paymentId) async {
    try {
      final doc = await _firestore.collection('ideal_payments').doc(paymentId).get();
      
      if (!doc.exists) {
        return null;
      }

      final checkoutUrl = doc.data()!['checkout_url'] as String?;
      return checkoutUrl;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to generate QR code: $e');
      }
      return null;
    }
  }

  /// Cleanup and dispose resources
  void dispose() {
    _httpClient.close();
  }
}