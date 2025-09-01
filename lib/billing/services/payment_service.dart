import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../beveiliger_dashboard/services/enhanced_earnings_service.dart';
import '../../beveiliger_dashboard/models/enhanced_dashboard_data.dart';
import '../../schedule/services/payroll_export_service.dart';
import '../models/payment_models.dart';

/// Core payment service integrating with existing SecuryFlex earnings system
/// 
/// Features:
/// - SEPA payments for guard salaries
/// - iDEAL payments for expenses/reimbursements
/// - Integration with existing EnhancedEarningsService
/// - Dutch banking compliance (IBAN validation, BTW calculations)
/// - CAO arbeidsrecht compliance
/// - Real-time payment tracking
class PaymentService {
  final FirebaseFirestore _firestore;
  final EnhancedEarningsService _earningsService;
  
  // Payment processing streams
  final StreamController<PaymentTransaction> _paymentController = 
      StreamController<PaymentTransaction>.broadcast();
  
  // Dutch banking configuration
  static const String _dutchIBANPrefix = 'NL';
  static const int _dutchIBANLength = 18;
  static const double _btwRate = 0.21; // 21% Dutch VAT
  static const double _vakantiegeldRate = 0.08; // 8% holiday allowance
  static const double _pensionRate = 0.055; // 5.5% pension contribution
  static const double _socialSecurityRate = 0.20; // 20% employer social security

  PaymentService({
    FirebaseFirestore? firestore,
    required EnhancedEarningsService earningsService,
    required PayrollExportService payrollService,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _earningsService = earningsService;

  /// Stream for real-time payment updates
  Stream<PaymentTransaction> get paymentStream => _paymentController.stream;

  /// Process salary payment based on existing earnings data
  Future<PaymentTransaction> processSalaryPayment({
    required String guardId,
    required String recipientIBAN,
    PaymentMethod method = PaymentMethod.sepa,
    String? companyId,
    bool includeVakantiegeld = true,
    bool applyBTWDeduction = false,
  }) async {
    try {
      // Validate IBAN format
      if (!_validateDutchIBAN(recipientIBAN)) {
        throw PaymentException(
          message: 'Ongeldig IBAN formaat: $recipientIBAN',
          type: PaymentErrorType.invalidIBAN,
          details: 'IBAN moet Nederlandse indeling hebben (NL## BANK ########)',
        );
      }

      // Get current earnings data from existing service
      final earnings = await _earningsService.getEnhancedEarningsData();
      
      // Validate minimum payment requirements
      if (earnings.totalWeek < 50.0) {
        throw PaymentException(
          message: 'Minimum uitbetaling bedrag niet bereikt (€50.00)',
          type: PaymentErrorType.invalidAmount,
          details: 'Huidige verdiensten: ${earnings.dutchFormattedWeek}',
        );
      }

      // Create payment transaction from earnings
      final payment = PaymentTransaction.fromEarningsData(
        guardId: guardId,
        earnings: earnings,
        type: PaymentType.salaryPayment,
        method: method,
        recipientIBAN: recipientIBAN,
        companyId: companyId,
      );

      // Process payment based on method
      PaymentTransaction processedPayment;
      switch (method) {
        case PaymentMethod.sepa:
          processedPayment = await _processSEPAPayment(payment);
          break;
        case PaymentMethod.ideal:
          throw PaymentException(
            message: 'iDEAL niet ondersteund voor salaris uitbetalingen',
            type: PaymentErrorType.invalidAmount,
            details: 'Gebruik SEPA voor salaris betalingen',
          );
        case PaymentMethod.bankTransfer:
          processedPayment = await _processBankTransfer(payment);
          break;
        default:
          throw PaymentException(
            message: 'Betaalmethode niet ondersteund: ${method.dutchName}',
            type: PaymentErrorType.invalidAmount,
          );
      }

      // Save payment to Firestore
      await _savePaymentTransaction(processedPayment);

      // Link payment to earnings record
      await _linkPaymentToEarnings(processedPayment.id, earnings);

      // Generate invoice if needed
      if (earnings.isFreelance) {
        await _generatePaymentInvoice(processedPayment);
      }

      // Emit payment update
      _paymentController.add(processedPayment);

      return processedPayment;

    } catch (e) {
      final errorPayment = PaymentTransaction.fromEarningsData(
        guardId: guardId,
        earnings: await _earningsService.getEnhancedEarningsData(),
        type: PaymentType.salaryPayment,
        method: method,
        recipientIBAN: recipientIBAN,
        companyId: companyId,
      ).copyWith(
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );

      await _savePaymentTransaction(errorPayment);
      _paymentController.add(errorPayment);

      rethrow;
    }
  }

  /// Process expense reimbursement via iDEAL
  Future<PaymentTransaction> processExpenseReimbursement({
    required String guardId,
    required double amount,
    required String description,
    String? companyId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Validate amount
      if (amount < 1.0 || amount > 1000.0) {
        throw PaymentException(
          message: 'Ongeldig bedrag voor onkosten vergoeding: €${amount.toStringAsFixed(2)}',
          type: PaymentErrorType.invalidAmount,
          details: 'Bedrag moet tussen €1.00 en €1000.00 zijn',
        );
      }

      final now = DateTime.now();
      final paymentId = 'exp_${guardId}_${now.millisecondsSinceEpoch}';

      // Create expense reimbursement transaction
      final payment = PaymentTransaction(
        id: paymentId,
        guardId: guardId,
        companyId: companyId,
        type: PaymentType.expenseReimbursement,
        method: PaymentMethod.ideal,
        status: PaymentStatus.pending,
        amount: amount,
        grossAmount: amount,
        netAmount: amount,
        btwAmount: amount * _btwRate, // BTW calculated for expense
        vakantiegeldAmount: 0.0,
        pensionDeduction: 0.0,
        inkomstenbelastingAmount: 0.0,
        dutchFormattedAmount: _formatDutchCurrency(amount),
        reference: 'EXP-${now.millisecondsSinceEpoch}',
        description: description,
        createdAt: now,
        isCAOCompliant: true,
        complianceData: {
          'expenseType': 'reimbursement',
          'originalAmount': amount,
          'btwIncluded': true,
          'metadata': metadata,
        },
        auditTrail: {
          'createdFrom': 'expense_reimbursement',
          'requestedAt': now.toIso8601String(),
        },
      );

      // Process iDEAL payment
      final processedPayment = await _processiDEALPayment(payment);

      // Save payment
      await _savePaymentTransaction(processedPayment);

      // Generate expense invoice
      await _generateExpenseInvoice(processedPayment);

      _paymentController.add(processedPayment);

      return processedPayment;

    } catch (e) {
      throw PaymentException(
        message: 'Onkosten vergoeding mislukt: ${e.toString()}',
        type: PaymentErrorType.networkError,
        context: {'guardId': guardId, 'amount': amount},
      );
    }
  }

  /// Calculate payment amount based on existing earnings
  Future<PaymentCalculationResult> calculatePaymentAmount({
    required String guardId,
    required PaymentType type,
    bool includeVakantiegeld = true,
    bool applyBTWDeduction = false,
  }) async {
    try {
      // Get earnings from existing service
      final earnings = await _earningsService.getEnhancedEarningsData();

      // Calculate based on payment type
      double grossAmount = 0.0;
      switch (type) {
        case PaymentType.salaryPayment:
          grossAmount = earnings.totalWeek;
          break;
        case PaymentType.overtimePayment:
          grossAmount = earnings.overtimeHours * earnings.overtimeRate;
          break;
        case PaymentType.bonusPayment:
          grossAmount = earnings.totalWeek * 0.1; // 10% bonus example
          break;
        case PaymentType.holidayPayment:
          grossAmount = earnings.vakantiegeld;
          includeVakantiegeld = false; // Already included in amount
          break;
        default:
          grossAmount = earnings.totalWeek;
      }

      // Calculate deductions and additions
      final vakantiegeld = includeVakantiegeld ? (grossAmount * _vakantiegeldRate) : 0.0;
      final btwAmount = applyBTWDeduction ? (grossAmount * _btwRate) : 0.0;
      final pensionDeduction = grossAmount * _pensionRate;
      final socialSecurityCost = grossAmount * _socialSecurityRate;
      final netAmount = grossAmount + vakantiegeld - btwAmount - pensionDeduction;
      final totalEmployerCost = grossAmount + vakantiegeld + socialSecurityCost;

      return PaymentCalculationResult(
        grossAmount: grossAmount,
        netAmount: netAmount,
        btwAmount: btwAmount,
        vakantiegeld: vakantiegeld,
        pensionDeduction: pensionDeduction,
        socialSecurityCost: socialSecurityCost,
        totalEmployerCost: totalEmployerCost,
        dutchFormattedNet: _formatDutchCurrency(netAmount),
        isCAOCompliant: earnings.isOvertimeCompliant,
        breakdown: {
          'grossPay': grossAmount,
          'vakantiegeld': vakantiegeld,
          'btwDeduction': btwAmount,
          'pensionDeduction': pensionDeduction,
          'socialSecurity': socialSecurityCost,
          'netPay': netAmount,
          'employerTotal': totalEmployerCost,
          'hoursWorked': earnings.hoursWorkedWeek,
          'overtimeHours': earnings.overtimeHours,
          'hourlyRate': earnings.hourlyRate,
        },
      );

    } catch (e) {
      throw PaymentException(
        message: 'Berekening betaling mislukt: ${e.toString()}',
        type: PaymentErrorType.networkError,
        context: {'guardId': guardId, 'type': type.name},
      );
    }
  }

  /// Get payment history for guard
  Future<List<PaymentTransaction>> getPaymentHistory({
    required String guardId,
    int limit = 50,
    PaymentType? filterType,
    PaymentStatus? filterStatus,
  }) async {
    try {
      Query query = _firestore
          .collection('payments')
          .where('guardId', isEqualTo: guardId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.name);
      }

      if (filterStatus != null) {
        query = query.where('status', isEqualTo: filterStatus.name);
      }

      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _paymentFromFirestore(data);
      }).toList();

    } catch (e) {
      throw PaymentException(
        message: 'Ophalen betaal geschiedenis mislukt: ${e.toString()}',
        type: PaymentErrorType.networkError,
        context: {'guardId': guardId},
      );
    }
  }

  /// Get payment by ID
  Future<PaymentTransaction?> getPayment(String paymentId) async {
    try {
      final doc = await _firestore.collection('payments').doc(paymentId).get();
      
      if (!doc.exists) return null;
      
      return _paymentFromFirestore(doc.data()!);

    } catch (e) {
      throw PaymentException(
        message: 'Ophalen betaling mislukt: ${e.toString()}',
        type: PaymentErrorType.networkError,
        context: {'paymentId': paymentId},
      );
    }
  }

  /// Watch payments in real-time
  Stream<List<PaymentTransaction>> watchPayments({
    required String guardId,
    PaymentStatus? statusFilter,
  }) {
    Query query = _firestore
        .collection('payments')
        .where('guardId', isEqualTo: guardId)
        .orderBy('createdAt', descending: true)
        .limit(20);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _paymentFromFirestore(data);
      }).toList();
    });
  }

  /// Process SEPA payment (integration with Dutch banking)
  Future<PaymentTransaction> _processSEPAPayment(PaymentTransaction payment) async {
    // In production, integrate with Dutch banking API (ABN AMRO, ING, Rabobank)
    // For now, simulate processing
    
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
    
    // Validate SEPA requirements
    if (!_validateSEPAPayment(payment)) {
      throw PaymentException(
        message: 'SEPA betaling niet conform Nederlandse bankregels',
        type: PaymentErrorType.complianceViolation,
      );
    }

    // Simulate successful processing
    final processedAt = DateTime.now();
    final sepaReference = 'SEPA${processedAt.millisecondsSinceEpoch}';
    
    return payment.copyWith(
      status: PaymentStatus.processing,
      processedAt: processedAt,
      auditTrail: {
        ...payment.auditTrail,
        'sepaProcessed': processedAt.toIso8601String(),
        'sepaReference': sepaReference,
        'bankingRoute': 'dutch_sepa_network',
      },
    );
  }

  /// Process iDEAL payment (Dutch online banking)
  Future<PaymentTransaction> _processiDEALPayment(PaymentTransaction payment) async {
    // In production, integrate with iDEAL provider (Mollie, Stripe, etc.)
    // For now, simulate processing
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate processing time
    
    final processedAt = DateTime.now();
    final idealTransactionId = 'iDEAL${processedAt.millisecondsSinceEpoch}';
    
    return payment.copyWith(
      status: PaymentStatus.processing,
      processedAt: processedAt,
      auditTrail: {
        ...payment.auditTrail,
        'idealProcessed': processedAt.toIso8601String(),
        'idealTransactionId': idealTransactionId,
        'paymentMethod': 'ideal_dutch_banking',
      },
    );
  }

  /// Process traditional bank transfer
  Future<PaymentTransaction> _processBankTransfer(PaymentTransaction payment) async {
    // Traditional bank transfer processing
    await Future.delayed(const Duration(seconds: 3));
    
    return payment.copyWith(
      status: PaymentStatus.processing,
      processedAt: DateTime.now(),
    );
  }

  /// Validate Dutch IBAN format
  bool _validateDutchIBAN(String iban) {
    if (!iban.startsWith(_dutchIBANPrefix)) return false;
    if (iban.length != _dutchIBANLength) return false;
    
    // Remove spaces and convert to uppercase
    final cleanIBAN = iban.replaceAll(' ', '').toUpperCase();
    
    // Basic IBAN checksum validation (simplified)
    return _validateIBANChecksum(cleanIBAN);
  }

  /// Validate IBAN checksum (simplified version)
  bool _validateIBANChecksum(String iban) {
    // Move first 4 characters to end
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    
    // Convert letters to numbers (A=10, B=11, etc.)
    String numericString = '';
    for (int i = 0; i < rearranged.length; i++) {
      final char = rearranged[i];
      if (char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90) {
        numericString += (char.codeUnitAt(0) - 55).toString();
      } else {
        numericString += char;
      }
    }
    
    // Calculate modulo 97
    int remainder = 0;
    for (int i = 0; i < numericString.length; i++) {
      remainder = (remainder * 10 + int.parse(numericString[i])) % 97;
    }
    
    return remainder == 1;
  }

  /// Validate SEPA payment requirements
  bool _validateSEPAPayment(PaymentTransaction payment) {
    // Check amount limits
    if (payment.netAmount > 999999.99) return false; // SEPA limit
    if (payment.netAmount < 0.01) return false;
    
    // Check IBAN
    if (payment.recipientIBAN == null || !_validateDutchIBAN(payment.recipientIBAN!)) {
      return false;
    }
    
    // Check CAO compliance for salary payments
    if (payment.type == PaymentType.salaryPayment && !payment.isCAOCompliant) {
      return false;
    }
    
    return true;
  }

  /// Save payment transaction to Firestore
  Future<void> _savePaymentTransaction(PaymentTransaction payment) async {
    await _firestore.collection('payments').doc(payment.id).set({
      'id': payment.id,
      'guardId': payment.guardId,
      'companyId': payment.companyId,
      'type': payment.type.name,
      'method': payment.method.name,
      'status': payment.status.name,
      'grossAmount': payment.grossAmount,
      'netAmount': payment.netAmount,
      'btwAmount': payment.btwAmount,
      'vakantiegeldAmount': payment.vakantiegeldAmount,
      'pensionDeduction': payment.pensionDeduction,
      'dutchFormattedAmount': payment.dutchFormattedAmount,
      'relatedEarningsId': payment.relatedEarningsId,
      'payrollEntryId': payment.payrollEntryId,
      'reference': payment.reference,
      'description': payment.description,
      'createdAt': Timestamp.fromDate(payment.createdAt),
      'processedAt': payment.processedAt != null ? Timestamp.fromDate(payment.processedAt!) : null,
      'completedAt': payment.completedAt != null ? Timestamp.fromDate(payment.completedAt!) : null,
      'recipientIBAN': payment.recipientIBAN,
      'recipientName': payment.recipientName,
      'paymentReference': payment.paymentReference,
      'isCAOCompliant': payment.isCAOCompliant,
      'complianceData': payment.complianceData,
      'auditTrail': payment.auditTrail,
      'errorMessage': payment.errorMessage,
      'retryCount': payment.retryCount,
    });
  }

  /// Link payment to existing earnings record
  Future<void> _linkPaymentToEarnings(String paymentId, EnhancedEarningsData earnings) async {
    // Create a link record for audit trail
    await _firestore.collection('payment_earnings_links').add({
      'paymentId': paymentId,
      'earningsCalculationTime': Timestamp.fromDate(earnings.lastCalculated),
      'earningsData': {
        'totalWeek': earnings.totalWeek,
        'hoursWorked': earnings.hoursWorkedWeek,
        'hourlyRate': earnings.hourlyRate,
        'overtimeHours': earnings.overtimeHours,
        'vakantiegeld': earnings.vakantiegeld,
        'btwAmount': earnings.btwAmount,
        'isCAOCompliant': earnings.isOvertimeCompliant,
      },
      'linkedAt': Timestamp.now(),
    });
  }

  /// Generate payment invoice using existing payroll service
  Future<void> _generatePaymentInvoice(PaymentTransaction payment) async {
    // This would integrate with existing PayrollExportService
    // For now, create a basic invoice record
    
    final invoiceNumber = await _generateInvoiceNumber();
    final now = DateTime.now();
    
    final invoice = InvoiceDocument(
      invoiceNumber: invoiceNumber,
      guardId: payment.guardId,
      companyId: payment.companyId,
      type: payment.type == PaymentType.salaryPayment ? 
          InvoiceType.salaryInvoice : InvoiceType.serviceInvoice,
      issueDate: now,
      dueDate: now.add(const Duration(days: 30)), // 30 dagen betaaltermijn
      subtotal: payment.grossAmount,
      btwAmount: payment.btwAmount,
      totalAmount: payment.grossAmount + payment.btwAmount,
      dutchFormattedTotal: _formatDutchCurrency(payment.grossAmount + payment.btwAmount),
      kvkNumber: '12345678', // Company KvK
      btwNumber: 'NL123456789B01', // Company BTW number
      lineItems: [
        InvoiceLineItem(
          description: payment.description,
          quantity: 1.0,
          unit: 'dienst',
          unitPrice: payment.grossAmount,
          lineTotal: payment.grossAmount,
          btwRate: _btwRate,
          dutchFormattedTotal: payment.dutchFormattedAmount,
        ),
      ],
      paymentIBAN: 'NL91ABNA0417164300', // Company IBAN
      paymentReference: payment.reference,
      paymentInstructions: 'Gelieve binnen 30 dagen over te maken naar bovenstaand rekeningnummer',
      relatedPaymentId: payment.id,
      createdAt: now,
    );

    // Save invoice to Firestore
    await _firestore.collection('invoices').add({
      'invoiceNumber': invoice.invoiceNumber,
      'guardId': invoice.guardId,
      'companyId': invoice.companyId,
      'type': invoice.type.name,
      'issueDate': Timestamp.fromDate(invoice.issueDate),
      'dueDate': Timestamp.fromDate(invoice.dueDate),
      'subtotal': invoice.subtotal,
      'btwAmount': invoice.btwAmount,
      'totalAmount': invoice.totalAmount,
      'dutchFormattedTotal': invoice.dutchFormattedTotal,
      'kvkNumber': invoice.kvkNumber,
      'btwNumber': invoice.btwNumber,
      'paymentIBAN': invoice.paymentIBAN,
      'paymentReference': invoice.paymentReference,
      'paymentInstructions': invoice.paymentInstructions,
      'relatedPaymentId': invoice.relatedPaymentId,
      'createdAt': Timestamp.fromDate(invoice.createdAt),
    });
  }

  /// Generate expense invoice
  Future<void> _generateExpenseInvoice(PaymentTransaction payment) async {
    // Similar to payment invoice but for expenses
    // Implementation would be similar to _generatePaymentInvoice
  }

  /// Generate sequential invoice number
  Future<String> _generateInvoiceNumber() async {
    final year = DateTime.now().year;
    final counterDoc = await _firestore.collection('counters').doc('invoices_$year').get();
    
    int nextNumber = 1;
    if (counterDoc.exists) {
      nextNumber = (counterDoc.data()!['count'] as int) + 1;
    }
    
    await _firestore.collection('counters').doc('invoices_$year').set({
      'count': nextNumber,
      'year': year,
      'updatedAt': Timestamp.now(),
    });
    
    return '$year${nextNumber.toString().padLeft(4, '0')}';
  }

  /// Convert Firestore data to PaymentTransaction
  PaymentTransaction _paymentFromFirestore(Map<String, dynamic> data) {
    return PaymentTransaction(
      id: data['id'],
      guardId: data['guardId'],
      companyId: data['companyId'],
      type: PaymentType.values.firstWhere((t) => t.name == data['type']),
      method: PaymentMethod.values.firstWhere((m) => m.name == data['method']),
      status: PaymentStatus.values.firstWhere((s) => s.name == data['status']),
      amount: (data['amount'] as num?)?.toDouble() ?? (data['grossAmount'] as num).toDouble(),
      grossAmount: (data['grossAmount'] as num).toDouble(),
      netAmount: (data['netAmount'] as num).toDouble(),
      btwAmount: (data['btwAmount'] as num).toDouble(),
      vakantiegeldAmount: (data['vakantiegeldAmount'] as num).toDouble(),
      pensionDeduction: (data['pensionDeduction'] as num).toDouble(),
      inkomstenbelastingAmount: (data['inkomstenbelastingAmount'] as num?)?.toDouble() ?? 0.0,
      dutchFormattedAmount: data['dutchFormattedAmount'],
      relatedEarningsId: data['relatedEarningsId'],
      payrollEntryId: data['payrollEntryId'],
      reference: data['reference'],
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: data['processedAt'] != null ? 
          (data['processedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? 
          (data['completedAt'] as Timestamp).toDate() : null,
      recipientIBAN: data['recipientIBAN'],
      recipientName: data['recipientName'],
      paymentReference: data['paymentReference'],
      isCAOCompliant: data['isCAOCompliant'] ?? true,
      complianceData: Map<String, dynamic>.from(data['complianceData'] ?? {}),
      auditTrail: Map<String, dynamic>.from(data['auditTrail'] ?? {}),
      errorMessage: data['errorMessage'],
      retryCount: data['retryCount'] ?? 0,
    );
  }

  /// Format currency in Dutch format (€1.234,56)
  String _formatDutchCurrency(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    // Add thousand separators (dots in Dutch format)
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }

  /// Dispose resources
  void dispose() {
    _paymentController.close();
  }
}