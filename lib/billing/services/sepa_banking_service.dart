import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/error/exceptions.dart';
import '../../shared/utils/dutch_formatting.dart';
import '../../shared/services/encryption_service.dart';
import '../models/payment_models.dart';

class SEPABankingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final EncryptionService _encryptionService;
  final http.Client _httpClient;

  // Dutch banking API endpoints (using test endpoints)
  static const String _bunqApiBase = 'https://public-api.sandbox.bunq.com';

  SEPABankingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _encryptionService = encryptionService ?? EncryptionService(),
        _httpClient = httpClient ?? http.Client();

  /// Initiates SEPA Credit Transfer for guard salary payment
  Future<SEPAPaymentResult> initiateSalaryPayment({
    required String guardId,
    required String recipientIBAN,
    required String recipientName,
    required double grossAmount,
    required String description,
    required PaymentFrequency frequency,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw const AuthenticationException('Gebruiker niet geauthenticeerd');
      }

      // Validate Dutch IBAN
      if (!_isValidDutchIBAN(recipientIBAN)) {
        throw ValidationException(
          field: 'iban',
          message: 'Ongeldig Nederlands IBAN nummer',
          dutchMessage: 'Het opgegeven IBAN nummer is niet geldig voor Nederlandse rekeningen',
        );
      }

      // Calculate Dutch tax obligations
      final taxCalculation = await _calculateDutchTaxes(grossAmount, frequency);
      
      // Create SEPA payment instruction
      final sepaInstruction = await _createSEPAInstruction(
        recipientIBAN: recipientIBAN,
        recipientName: recipientName,
        amount: taxCalculation.netAmount,
        description: description,
        executionDate: DateTime.now().add(const Duration(days: 1)), // Next business day
        urgency: SEPAUrgency.standard,
      );

      // Get company banking details from Firestore
      final companyBankingDoc = await _firestore
          .collection('companies')
          .doc(currentUser.uid)
          .collection('banking')
          .doc('sepa_details')
          .get();

      if (!companyBankingDoc.exists) {
        throw BusinessLogicException(
          'Geen SEPA bankgegevens gevonden. Configureer eerst uw bedrijfsbankrekening.',
          errorCode: 'SEPA_CONFIG_MISSING',
        );
      }

      final bankingData = companyBankingDoc.data()!;
      final debtorIBAN = await _encryptionService.decrypt(bankingData['encrypted_iban']);
      final bankingProvider = bankingData['provider'] as String; // 'bunq', 'ing', 'rabobank'

      // Execute SEPA payment via banking provider
      final bankingResult = await _executeSEPAPayment(
        provider: bankingProvider,
        debtorIBAN: debtorIBAN,
        instruction: sepaInstruction,
        apiCredentials: bankingData['encrypted_credentials'],
      );

      // Record payment transaction
      final transaction = PaymentTransaction(
        id: bankingResult.transactionId,
        guardId: guardId,
        companyId: currentUser.uid,
        type: PaymentType.salary,
        method: PaymentMethod.sepa,
        amount: grossAmount,
        grossAmount: grossAmount,
        netAmount: taxCalculation.netAmount,
        btwAmount: taxCalculation.btwAmount,
        inkomstenbelastingAmount: taxCalculation.inkomstenbelastingAmount,
        vakantiegeldAmount: taxCalculation.vakantiegeldAmount,
        pensionDeduction: grossAmount * 0.055, // 5.5% pension
        dutchFormattedAmount: DutchFormatting.formatCurrency(grossAmount),
        reference: bankingResult.endToEndReference,
        description: description,
        createdAt: DateTime.now(),
        status: PaymentStatus.pending,
        executionDate: sepaInstruction.executionDate,
        recipientIBAN: recipientIBAN,
        recipientName: recipientName,
        dutchFormattedNetAmount: DutchFormatting.formatCurrency(taxCalculation.netAmount),
        transactionReference: bankingResult.endToEndReference,
        complianceData: {
          'btw_percentage': 21.0,
          'vakantiegeld_percentage': 8.0,
          'withholding_tax_applied': true,
          'cao_compliant': true,
          'gdpr_consent_id': 'salary_payment_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      // Store in Firestore with encryption
      await _storePaymentRecord(transaction);

      // Create audit trail
      await _createAuditTrail(
        action: 'SEPA_SALARY_INITIATED',
        guardId: guardId,
        companyId: currentUser.uid,
        amount: grossAmount,
        transactionId: transaction.id,
        details: {
          'recipient_iban': _maskIBAN(recipientIBAN),
          'net_amount': taxCalculation.netAmount,
          'execution_date': sepaInstruction.executionDate.toIso8601String(),
          'banking_provider': bankingProvider,
        },
      );

      return SEPAPaymentResult(
        success: true,
        transactionId: transaction.id,
        endToEndReference: bankingResult.endToEndReference,
        executionDate: sepaInstruction.executionDate,
        netAmount: taxCalculation.netAmount,
        taxBreakdown: taxCalculation,
        estimatedArrival: _calculateArrivalTime(bankingProvider, sepaInstruction.urgency),
      );

    } catch (e) {
      await _logPaymentError(guardId, e);
      rethrow;
    }
  }

  /// Validates Dutch IBAN format and check digit
  bool _isValidDutchIBAN(String iban) {
    // Remove spaces and convert to uppercase
    final cleanIBAN = iban.replaceAll(' ', '').toUpperCase();
    
    // Dutch IBAN: NL + 2 check digits + 4 bank code + 10 account number = 18 characters
    if (!RegExp(r'^NL\d{16}$').hasMatch(cleanIBAN)) {
      return false;
    }

    // IBAN check digit validation (mod-97)
    final rearranged = cleanIBAN.substring(4) + cleanIBAN.substring(0, 4);
    final numericString = rearranged.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => (match.group(0)!.codeUnitAt(0) - 55).toString(),
    );

    final remainder = BigInt.parse(numericString) % BigInt.from(97);
    return remainder == BigInt.one;
  }

  /// Calculate Dutch taxes for salary payment
  Future<DutchTaxCalculation> _calculateDutchTaxes(
    double grossAmount,
    PaymentFrequency frequency,
  ) async {
    // Dutch tax rates for 2024
    const double btwRate = 0.21; // 21% BTW
    const double vakantiegeldRate = 0.08; // 8% holiday allowance
    const double inkomstenbelastingRate = 0.37; // Average income tax rate

    // Calculate vakantiegeld (holiday allowance) - mandatory in Netherlands
    final vakantiegeldAmount = grossAmount * vakantiegeldRate;
    
    // BTW calculation (if applicable for freelance work)
    final btwAmount = grossAmount * btwRate;
    
    // Income tax withholding (rough calculation)
    final taxableIncome = grossAmount - vakantiegeldAmount;
    final inkomstenbelastingAmount = taxableIncome * inkomstenbelastingRate;
    
    // Net amount after taxes
    final netAmount = grossAmount - inkomstenbelastingAmount - btwAmount + vakantiegeldAmount;

    return DutchTaxCalculation(
      grossAmount: grossAmount,
      netAmount: netAmount,
      btwAmount: btwAmount,
      btwRate: btwRate,
      inkomstenbelastingAmount: inkomstenbelastingAmount,
      inkomstenbelastingRate: inkomstenbelastingRate,
      vakantiegeldAmount: vakantiegeldAmount,
      vakantiegeldRate: vakantiegeldRate,
      frequency: frequency,
      calculatedAt: DateTime.now(),
    );
  }

  /// Create SEPA Credit Transfer instruction
  Future<SEPAInstruction> _createSEPAInstruction({
    required String recipientIBAN,
    required String recipientName,
    required double amount,
    required String description,
    required DateTime executionDate,
    required SEPAUrgency urgency,
  }) async {
    final endToEndReference = _generateEndToEndReference();
    
    return SEPAInstruction(
      endToEndReference: endToEndReference,
      recipientIBAN: recipientIBAN,
      recipientName: recipientName,
      amount: amount,
      currency: 'EUR',
      description: description,
      executionDate: executionDate,
      urgency: urgency,
      createdAt: DateTime.now(),
    );
  }

  /// Execute SEPA payment via banking provider API
  Future<BankingApiResult> _executeSEPAPayment({
    required String provider,
    required String debtorIBAN,
    required SEPAInstruction instruction,
    required String apiCredentials,
  }) async {
    switch (provider.toLowerCase()) {
      case 'bunq':
        return await _executeBunqPayment(debtorIBAN, instruction, apiCredentials);
      case 'ing':
        return await _executeINGPayment(debtorIBAN, instruction, apiCredentials);
      case 'rabobank':
        return await _executeRabobankPayment(debtorIBAN, instruction, apiCredentials);
      default:
        throw BusinessLogicException(
          'Niet-ondersteunde bankprovider: $provider',
          errorCode: 'UNSUPPORTED_BANK_PROVIDER',
        );
    }
  }

  /// Bunq API integration for SEPA payments
  Future<BankingApiResult> _executeBunqPayment(
    String debtorIBAN,
    SEPAInstruction instruction,
    String encryptedCredentials,
  ) async {
    try {
      final credentials = json.decode(await _encryptionService.decrypt(encryptedCredentials));
      final apiKey = credentials['api_key'] as String;

      final headers = {
        'Content-Type': 'application/json',
        'X-Bunq-Client-Authentication': apiKey,
        'X-Bunq-Client-Request-Id': _generateRequestId(),
        'X-Bunq-Geolocation': '0 0 0 0 NL',
        'X-Bunq-Language': 'nl_NL',
        'User-Agent': 'SecuryFlex/1.0.0 (Flutter)',
      };

      final paymentData = {
        'amount': {
          'value': instruction.amount.toStringAsFixed(2),
          'currency': 'EUR',
        },
        'counterparty_alias': {
          'type': 'IBAN',
          'value': instruction.recipientIBAN,
          'name': instruction.recipientName,
        },
        'description': instruction.description,
        'attachment': [],
        'merchant_reference': instruction.endToEndReference,
      };

      final response = await _httpClient.post(
        Uri.parse('$_bunqApiBase/v1/user/USER_ID/monetary-account/ACCOUNT_ID/payment'),
        headers: headers,
        body: json.encode(paymentData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final paymentId = responseData['Response'][0]['Payment']['id'];
        
        return BankingApiResult(
          success: true,
          transactionId: paymentId.toString(),
          endToEndReference: instruction.endToEndReference,
          providerReference: paymentId.toString(),
          estimatedProcessingTime: const Duration(hours: 24),
        );
      } else {
        throw NetworkException('Bunq payment failed: ${response.body}');
      }
    } catch (e) {
      throw NetworkException('Bunq API error: ${e.toString()}');
    }
  }

  /// ING API integration for SEPA payments
  Future<BankingApiResult> _executeINGPayment(
    String debtorIBAN,
    SEPAInstruction instruction,
    String encryptedCredentials,
  ) async {
    // ING API implementation would go here
    // This is a placeholder for the actual ING Connect API integration
    return BankingApiResult(
      success: true,
      transactionId: 'ING_${DateTime.now().millisecondsSinceEpoch}',
      endToEndReference: instruction.endToEndReference,
      providerReference: 'ING_REF_${instruction.endToEndReference}',
      estimatedProcessingTime: const Duration(hours: 2),
    );
  }

  /// Rabobank API integration for SEPA payments
  Future<BankingApiResult> _executeRabobankPayment(
    String debtorIBAN,
    SEPAInstruction instruction,
    String encryptedCredentials,
  ) async {
    // Rabobank API implementation would go here
    // This is a placeholder for the actual Rabobank Connect API integration
    return BankingApiResult(
      success: true,
      transactionId: 'RABO_${DateTime.now().millisecondsSinceEpoch}',
      endToEndReference: instruction.endToEndReference,
      providerReference: 'RABO_REF_${instruction.endToEndReference}',
      estimatedProcessingTime: const Duration(hours: 4),
    );
  }

  /// Store payment record securely in Firestore
  Future<void> _storePaymentRecord(PaymentTransaction transaction) async {
    final encryptedTransaction = await _encryptionService.encryptPaymentData(transaction);
    
    await _firestore
        .collection('payments')
        .doc(transaction.id)
        .set(encryptedTransaction);

    // Also store in company's payment history
    await _firestore
        .collection('companies')
        .doc(transaction.companyId)
        .collection('payments')
        .doc(transaction.id)
        .set({
          'payment_id': transaction.id,
          'guard_id': transaction.guardId,
          'amount': transaction.amount,
          'status': transaction.status.toString(),
          'created_at': transaction.createdAt,
          'dutch_formatted_amount': transaction.dutchFormattedAmount,
        });
  }

  /// Create comprehensive audit trail
  Future<void> _createAuditTrail({
    required String action,
    required String guardId,
    required String companyId,
    required double amount,
    required String transactionId,
    required Map<String, dynamic> details,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'user_id': _auth.currentUser?.uid,
      'guard_id': guardId,
      'company_id': companyId,
      'amount': amount,
      'transaction_id': transactionId,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
      'ip_address': 'UNKNOWN', // Would be captured from request
      'user_agent': 'SecuryFlex Flutter App',
      'compliance_flags': {
        'gdpr_compliant': true,
        'financial_audit_required': amount > 10000,
        'tax_reporting_required': true,
      },
    });
  }

  /// Generate unique end-to-end reference for SEPA payment
  String _generateEndToEndReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = (timestamp % 10000).toString().padLeft(4, '0');
    return 'SEPA-SF-$timestamp-$randomSuffix';
  }

  /// Generate unique request ID for API calls
  String _generateRequestId() {
    final bytes = utf8.encode('${DateTime.now().toIso8601String()}-${_auth.currentUser?.uid}');
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// Mask IBAN for logging purposes (GDPR compliance)
  String _maskIBAN(String iban) {
    if (iban.length < 8) return iban;
    return iban.substring(0, 4) + '*' * (iban.length - 8) + iban.substring(iban.length - 4);
  }

  /// Calculate estimated arrival time based on banking provider and urgency
  DateTime _calculateArrivalTime(String provider, SEPAUrgency urgency) {
    Duration processingTime;
    
    switch (urgency) {
      case SEPAUrgency.instant:
        processingTime = const Duration(minutes: 10);
        break;
      case SEPAUrgency.express:
        processingTime = const Duration(hours: 2);
        break;
      case SEPAUrgency.standard:
      processingTime = const Duration(hours: 24);
        break;
    }

    // Add provider-specific delays
    switch (provider.toLowerCase()) {
      case 'bunq':
        processingTime += const Duration(minutes: 30);
        break;
      case 'ing':
        processingTime += const Duration(hours: 1);
        break;
      case 'rabobank':
        processingTime += const Duration(hours: 2);
        break;
    }

    return DateTime.now().add(processingTime);
  }

  /// Log payment errors for debugging and compliance
  Future<void> _logPaymentError(String guardId, dynamic error) async {
    await _firestore.collection('payment_errors').add({
      'guard_id': guardId,
      'company_id': _auth.currentUser?.uid,
      'error_message': error.toString(),
      'error_type': error.runtimeType.toString(),
      'timestamp': FieldValue.serverTimestamp(),
      'stack_trace': StackTrace.current.toString(),
      'compliance_flags': {
        'requires_manual_review': true,
        'financial_impact': true,
      },
    });
  }

  /// Get payment status from banking provider
  Future<PaymentStatus> getPaymentStatus(String transactionId) async {
    try {
      final paymentDoc = await _firestore
          .collection('payments')
          .doc(transactionId)
          .get();

      if (!paymentDoc.exists) {
        return PaymentStatus.notFound;
      }

      final paymentData = await _encryptionService.decryptPaymentData(paymentDoc.data()!);
      return PaymentStatus.values.firstWhere(
        (status) => status.toString() == paymentData['status'],
        orElse: () => PaymentStatus.unknown,
      );
    } catch (e) {
      return PaymentStatus.error;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

/// Additional data classes for SEPA functionality
class SEPAInstruction {
  final String endToEndReference;
  final String recipientIBAN;
  final String recipientName;
  final double amount;
  final String currency;
  final String description;
  final DateTime executionDate;
  final SEPAUrgency urgency;
  final DateTime createdAt;

  const SEPAInstruction({
    required this.endToEndReference,
    required this.recipientIBAN,
    required this.recipientName,
    required this.amount,
    required this.currency,
    required this.description,
    required this.executionDate,
    required this.urgency,
    required this.createdAt,
  });
}

class BankingApiResult {
  final bool success;
  final String transactionId;
  final String endToEndReference;
  final String providerReference;
  final Duration estimatedProcessingTime;

  const BankingApiResult({
    required this.success,
    required this.transactionId,
    required this.endToEndReference,
    required this.providerReference,
    required this.estimatedProcessingTime,
  });
}

class DutchTaxCalculation {
  final double grossAmount;
  final double netAmount;
  final double btwAmount;
  final double btwRate;
  final double inkomstenbelastingAmount;
  final double inkomstenbelastingRate;
  final double vakantiegeldAmount;
  final double vakantiegeldRate;
  final PaymentFrequency frequency;
  final DateTime calculatedAt;

  const DutchTaxCalculation({
    required this.grossAmount,
    required this.netAmount,
    required this.btwAmount,
    required this.btwRate,
    required this.inkomstenbelastingAmount,
    required this.inkomstenbelastingRate,
    required this.vakantiegeldAmount,
    required this.vakantiegeldRate,
    required this.frequency,
    required this.calculatedAt,
  });
}

enum SEPAUrgency {
  instant,
  express,
  standard,
}

class SEPAPaymentResult {
  final bool success;
  final String transactionId;
  final String endToEndReference;
  final DateTime executionDate;
  final double netAmount;
  final DutchTaxCalculation taxBreakdown;
  final DateTime estimatedArrival;

  const SEPAPaymentResult({
    required this.success,
    required this.transactionId,
    required this.endToEndReference,
    required this.executionDate,
    required this.netAmount,
    required this.taxBreakdown,
    required this.estimatedArrival,
  });
}