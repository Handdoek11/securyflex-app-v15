import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/exceptions.dart';
import '../../shared/utils/dutch_formatting.dart';
import '../../shared/services/encryption_service.dart';

/// iDEAL Payment Service for Dutch expense reimbursements
/// Integrates with Mollie and Stripe for real Dutch banking
class IdealPaymentService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final http.Client _httpClient;

  // Dutch payment provider endpoints
  static const String _mollieApiBase = 'https://api.mollie.com/v2';
  static const String _stripeApiBase = 'https://api.stripe.com/v1';

  IdealPaymentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        _httpClient = httpClient ?? http.Client();

  /// Create iDEAL payment for expense reimbursement
  Future<IdealPaymentResult> createExpensePayment({
    required String guardId,
    required String companyId,
    required double amount,
    required String description,
    required ExpenseType expenseType,
    required String returnUrl,
    String? receiptImageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw const AuthenticationException('Gebruiker niet geauthenticeerd');
      }

      // Validate expense amount (Dutch labor law limits)
      if (amount < 0.01 || amount > 2500.00) {
        throw ValidationException(
          field: 'amount',
          message: 'Expense amount must be between €0.01 and €2,500.00',
          dutchMessage: 'Onkostenbedrag moet tussen €0,01 en €2.500,00 zijn',
        );
      }

      // Get company payment settings
      final paymentSettings = await _getCompanyPaymentSettings(companyId);
      final provider = paymentSettings['ideal_provider'] ?? 'mollie';

      // Create expense tracking record first
      final expenseId = await _createExpenseRecord(
        guardId: guardId,
        companyId: companyId,
        amount: amount,
        description: description,
        expenseType: expenseType,
        receiptImageUrl: receiptImageUrl,
        metadata: metadata,
      );

      // Create iDEAL payment via provider
      final paymentResult = await _createIdealPayment(
        provider: provider,
        amount: amount,
        description: description,
        returnUrl: returnUrl,
        webhookUrl: 'https://securyflex.nl/webhooks/ideal/$provider',
        expenseId: expenseId,
        apiCredentials: paymentSettings['encrypted_credentials'],
      );

      // Update expense record with payment info
      await _updateExpenseWithPayment(expenseId, paymentResult);

      // Create audit trail
      await _createExpenseAuditTrail(
        action: 'IDEAL_PAYMENT_CREATED',
        guardId: guardId,
        companyId: companyId,
        expenseId: expenseId,
        amount: amount,
        provider: provider,
        paymentId: paymentResult.paymentId,
      );

      return paymentResult;
    } catch (e) {
      await _logExpenseError(guardId, companyId, e);
      rethrow;
    }
  }

  /// Create expense record in Firestore
  Future<String> _createExpenseRecord({
    required String guardId,
    required String companyId,
    required double amount,
    required String description,
    required ExpenseType expenseType,
    String? receiptImageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final expenseId = 'exp_${guardId}_${now.millisecondsSinceEpoch}';

    final expenseData = {
      'id': expenseId,
      'guard_id': guardId,
      'company_id': companyId,
      'amount': amount,
      'dutch_formatted_amount': DutchFormatting.formatCurrency(amount),
      'description': description,
      'expense_type': expenseType.name,
      'status': 'pending_payment',
      'created_at': FieldValue.serverTimestamp(),
      'receipt_image_url': receiptImageUrl,
      'metadata': metadata ?? {},
      'payment_method': 'ideal',
      'btw_amount': _calculateBTW(amount, expenseType),
      'btw_deductible': _isBTWDeductible(expenseType),
      'compliance_data': {
        'dutch_tax_category': _getTaxCategory(expenseType),
        'reimbursement_eligible': true,
        'max_reimbursement': _getMaxReimbursement(expenseType),
        'documentation_required': _requiresDocumentation(expenseType),
      },
    };

    // Encrypt sensitive data
    final encryptedData = await _encryptionService.encryptPaymentData(expenseData);

    await _firestore.collection('expenses').doc(expenseId).set(encryptedData);

    // Also add to guard's expense history
    await _firestore
        .collection('guards')
        .doc(guardId)
        .collection('expenses')
        .doc(expenseId)
        .set({
      'expense_id': expenseId,
      'amount': amount,
      'status': 'pending_payment',
      'created_at': FieldValue.serverTimestamp(),
      'dutch_formatted_amount': DutchFormatting.formatCurrency(amount),
    });

    return expenseId;
  }

  /// Create iDEAL payment via provider (Mollie or Stripe)
  Future<IdealPaymentResult> _createIdealPayment({
    required String provider,
    required double amount,
    required String description,
    required String returnUrl,
    required String webhookUrl,
    required String expenseId,
    required String apiCredentials,
  }) async {
    switch (provider.toLowerCase()) {
      case 'mollie':
        return await _createMolliePayment(
          amount: amount,
          description: description,
          returnUrl: returnUrl,
          webhookUrl: webhookUrl,
          expenseId: expenseId,
          apiKey: await _encryptionService.decrypt(apiCredentials),
        );
      case 'stripe':
        return await _createStripePayment(
          amount: amount,
          description: description,
          returnUrl: returnUrl,
          webhookUrl: webhookUrl,
          expenseId: expenseId,
          apiKey: await _encryptionService.decrypt(apiCredentials),
        );
      default:
        throw BusinessLogicException(
          'Niet-ondersteunde iDEAL provider: $provider',
          errorCode: 'UNSUPPORTED_IDEAL_PROVIDER',
        );
    }
  }

  /// Create Mollie iDEAL payment
  Future<IdealPaymentResult> _createMolliePayment({
    required double amount,
    required String description,
    required String returnUrl,
    required String webhookUrl,
    required String expenseId,
    required String apiKey,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final paymentData = {
        'amount': {
          'currency': 'EUR',
          'value': amount.toStringAsFixed(2),
        },
        'description': description,
        'redirectUrl': returnUrl,
        'webhookUrl': webhookUrl,
        'method': 'ideal',
        'metadata': {
          'expense_id': expenseId,
          'platform': 'SecuryFlex',
          'type': 'expense_reimbursement',
        },
      };

      final response = await _httpClient.post(
        Uri.parse('$_mollieApiBase/payments'),
        headers: headers,
        body: json.encode(paymentData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        return IdealPaymentResult(
          success: true,
          paymentId: responseData['id'],
          checkoutUrl: responseData['_links']['checkout']['href'],
          status: IdealPaymentStatus.open,
          amount: amount,
          provider: 'mollie',
          expiresAt: DateTime.parse(responseData['expiresAt']),
          metadata: {
            'mollie_payment_id': responseData['id'],
            'expense_id': expenseId,
          },
        );
      } else {
        final errorData = json.decode(response.body);
        throw PaymentException(
          'Mollie payment creation failed: ${errorData['detail']}',
          errorCode: 'MOLLIE_API_ERROR',
        );
      }
    } catch (e) {
      throw NetworkException('Mollie API error: ${e.toString()}');
    }
  }

  /// Create Stripe iDEAL payment
  Future<IdealPaymentResult> _createStripePayment({
    required double amount,
    required String description,
    required String returnUrl,
    required String webhookUrl,
    required String expenseId,
    required String apiKey,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // Convert amount to cents for Stripe
      final amountInCents = (amount * 100).round();

      final paymentData = {
        'amount': amountInCents.toString(),
        'currency': 'eur',
        'payment_method_types[]': 'ideal',
        'success_url': returnUrl,
        'cancel_url': returnUrl,
        'metadata[expense_id]': expenseId,
        'metadata[platform]': 'SecuryFlex',
        'metadata[type]': 'expense_reimbursement',
      };

      final body = paymentData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _httpClient.post(
        Uri.parse('$_stripeApiBase/checkout/sessions'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        return IdealPaymentResult(
          success: true,
          paymentId: responseData['id'],
          checkoutUrl: responseData['url'],
          status: IdealPaymentStatus.open,
          amount: amount,
          provider: 'stripe',
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          metadata: {
            'stripe_session_id': responseData['id'],
            'expense_id': expenseId,
          },
        );
      } else {
        final errorData = json.decode(response.body);
        throw PaymentException(
          'Stripe payment creation failed: ${errorData['error']['message']}',
          errorCode: 'STRIPE_API_ERROR',
        );
      }
    } catch (e) {
      throw NetworkException('Stripe API error: ${e.toString()}');
    }
  }

  /// Get available iDEAL banks for selection
  Future<List<IdealBank>> getAvailableBanks() async {
    // Standard Dutch iDEAL banks
    return const [
      IdealBank(
        id: 'ideal_ABNANL2A',
        name: 'ABN AMRO',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/abnamro.svg',
      ),
      IdealBank(
        id: 'ideal_ASNBNL21',
        name: 'ASN Bank',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/asn.svg',
      ),
      IdealBank(
        id: 'ideal_BUNQNL2A',
        name: 'Bunq',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/bunq.svg',
      ),
      IdealBank(
        id: 'ideal_INGBNL2A',
        name: 'ING',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/ing.svg',
      ),
      IdealBank(
        id: 'ideal_KNABNL2H',
        name: 'Knab',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/knab.svg',
      ),
      IdealBank(
        id: 'ideal_RABONL2U',
        name: 'Rabobank',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/rabobank.svg',
      ),
      IdealBank(
        id: 'ideal_RBRBNL21',
        name: 'RegioBank',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/regiobank.svg',
      ),
      IdealBank(
        id: 'ideal_SNSBNL2A',
        name: 'SNS Bank',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/sns.svg',
      ),
      IdealBank(
        id: 'ideal_TRIONL2U',
        name: 'Triodos Bank',
        imageSvg: 'https://www.mollie.com/external/icons/ideal-issuers/triodos.svg',
      ),
    ];
  }

  /// Check payment status
  Future<IdealPaymentStatus> getPaymentStatus(String paymentId, String provider) async {
    try {
      switch (provider.toLowerCase()) {
        case 'mollie':
          return await _getMolliePaymentStatus(paymentId);
        case 'stripe':
          return await _getStripePaymentStatus(paymentId);
        default:
          return IdealPaymentStatus.unknown;
      }
    } catch (e) {
      return IdealPaymentStatus.failed;
    }
  }

  /// Get company payment settings
  Future<Map<String, dynamic>> _getCompanyPaymentSettings(String companyId) async {
    final doc = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('settings')
        .doc('payment_providers')
        .get();

    if (!doc.exists) {
      throw BusinessLogicException(
        'Geen iDEAL payment provider geconfigureerd voor bedrijf',
        errorCode: 'NO_IDEAL_PROVIDER',
      );
    }

    return doc.data()!;
  }

  /// Calculate BTW for expense type
  double _calculateBTW(double amount, ExpenseType expenseType) {
    // Different BTW rates for different expense types
    switch (expenseType) {
      case ExpenseType.travel:
        return amount * 0.21; // 21% BTW on travel
      case ExpenseType.meals:
        return amount * 0.09; // 9% BTW on meals
      case ExpenseType.accommodation:
        return amount * 0.21; // 21% BTW on accommodation
      case ExpenseType.equipment:
        return amount * 0.21; // 21% BTW on equipment
      case ExpenseType.training:
        return amount * 0.21; // 21% BTW on training
      case ExpenseType.other:
        return amount * 0.21; // Default 21% BTW
    }
  }

  /// Check if BTW is deductible for expense type
  bool _isBTWDeductible(ExpenseType expenseType) {
    switch (expenseType) {
      case ExpenseType.travel:
      case ExpenseType.accommodation:
      case ExpenseType.equipment:
      case ExpenseType.training:
        return true; // Business-related expenses
      case ExpenseType.meals:
        return false; // Meals are typically not fully deductible
      case ExpenseType.other:
        return false; // Unknown expenses default to not deductible
    }
  }

  /// Get Dutch tax category for expense type
  String _getTaxCategory(ExpenseType expenseType) {
    switch (expenseType) {
      case ExpenseType.travel:
        return 'reiskosten';
      case ExpenseType.meals:
        return 'maaltijdkosten';
      case ExpenseType.accommodation:
        return 'verblijfkosten';
      case ExpenseType.equipment:
        return 'werkuitrusting';
      case ExpenseType.training:
        return 'opleidingskosten';
      case ExpenseType.other:
        return 'overige_kosten';
    }
  }

  /// Get maximum reimbursement for expense type (Dutch labor law)
  double _getMaxReimbursement(ExpenseType expenseType) {
    switch (expenseType) {
      case ExpenseType.travel:
        return 0.21; // €0.21 per km for 2024
      case ExpenseType.meals:
        return 25.00; // Max €25 per day for meals
      case ExpenseType.accommodation:
        return 150.00; // Max €150 per night
      case ExpenseType.equipment:
        return 500.00; // Max €500 per item
      case ExpenseType.training:
        return 1000.00; // Max €1000 per course
      case ExpenseType.other:
        return 100.00; // Default €100 max
    }
  }

  /// Check if documentation is required
  bool _requiresDocumentation(ExpenseType expenseType) {
    switch (expenseType) {
      case ExpenseType.travel:
        return false; // Travel can be based on distance
      case ExpenseType.meals:
      case ExpenseType.accommodation:
      case ExpenseType.equipment:
      case ExpenseType.training:
      case ExpenseType.other:
        return true; // Receipts required
    }
  }

  /// Update expense with payment information
  Future<void> _updateExpenseWithPayment(
    String expenseId,
    IdealPaymentResult paymentResult,
  ) async {
    await _firestore.collection('expenses').doc(expenseId).update({
      'payment_id': paymentResult.paymentId,
      'payment_provider': paymentResult.provider,
      'payment_status': paymentResult.status.name,
      'checkout_url': paymentResult.checkoutUrl,
      'payment_expires_at': paymentResult.expiresAt,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Create audit trail for expense operations
  Future<void> _createExpenseAuditTrail({
    required String action,
    required String guardId,
    required String companyId,
    required String expenseId,
    required double amount,
    required String provider,
    required String paymentId,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'user_id': _auth.currentUser?.uid,
      'guard_id': guardId,
      'company_id': companyId,
      'expense_id': expenseId,
      'payment_id': paymentId,
      'amount': amount,
      'provider': provider,
      'timestamp': FieldValue.serverTimestamp(),
      'compliance_flags': {
        'expense_tracking': true,
        'btw_calculated': true,
        'dutch_tax_compliant': true,
      },
    });
  }

  /// Get Mollie payment status
  Future<IdealPaymentStatus> _getMolliePaymentStatus(String paymentId) async {
    // Implementation would call Mollie API to check status
    // This is a placeholder
    return IdealPaymentStatus.pending;
  }

  /// Get Stripe payment status
  Future<IdealPaymentStatus> _getStripePaymentStatus(String sessionId) async {
    // Implementation would call Stripe API to check status
    // This is a placeholder
    return IdealPaymentStatus.pending;
  }

  /// Log expense errors
  Future<void> _logExpenseError(String guardId, String companyId, dynamic error) async {
    await _firestore.collection('expense_errors').add({
      'guard_id': guardId,
      'company_id': companyId,
      'error_message': error.toString(),
      'error_type': error.runtimeType.toString(),
      'timestamp': FieldValue.serverTimestamp(),
      'stack_trace': StackTrace.current.toString(),
    });
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Expense types for Dutch tax compliance
enum ExpenseType {
  travel('Reiskosten'),
  meals('Maaltijden'),
  accommodation('Verblijf'),
  equipment('Werkuitrusting'),
  training('Opleiding'),
  other('Overig');

  const ExpenseType(this.dutchName);
  final String dutchName;
}

/// iDEAL payment result
class IdealPaymentResult {
  final bool success;
  final String paymentId;
  final String checkoutUrl;
  final IdealPaymentStatus status;
  final double amount;
  final String provider;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;

  const IdealPaymentResult({
    required this.success,
    required this.paymentId,
    required this.checkoutUrl,
    required this.status,
    required this.amount,
    required this.provider,
    required this.expiresAt,
    required this.metadata,
  });
}

/// iDEAL payment status
enum IdealPaymentStatus {
  open('Open'),
  pending('In Behandeling'),
  paid('Betaald'),
  failed('Mislukt'),
  canceled('Geannuleerd'),
  expired('Verlopen'),
  unknown('Onbekend');

  const IdealPaymentStatus(this.dutchName);
  final String dutchName;
}

/// Dutch iDEAL bank information
class IdealBank {
  final String id;
  final String name;
  final String imageSvg;

  const IdealBank({
    required this.id,
    required this.name,
    required this.imageSvg,
  });
}

/// Payment exception specific to iDEAL
class PaymentException extends SecuryFlexException {
  const PaymentException(super.message, {super.errorCode});
}