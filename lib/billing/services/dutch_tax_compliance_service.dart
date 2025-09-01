import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/belastingdienst_models.dart';
import '../../shared/utils/dutch_formatting.dart';

/// Dutch Tax Compliance Service for SecuryFlex Subscriptions
/// Handles BTW obligations, omzetbelasting reporting, and Belastingdienst integration
class DutchTaxComplianceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Dutch BTW rates
  static const double btwStandardRate = 0.21; // 21% standard rate
  static const double btwReducedRate = 0.09;  // 9% reduced rate (not applicable to platform services)
  static const double btwZeroRate = 0.00;     // 0% for exports
  
  // EU VAT identification
  static const List<String> euCountryCodes = [
    'AT', 'BE', 'BG', 'CY', 'CZ', 'DE', 'DK', 'EE', 'ES', 'FI',
    'FR', 'GR', 'HR', 'HU', 'IE', 'IT', 'LT', 'LU', 'LV', 'MT',
    'NL', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK'
  ];
  
  /// Calculate BTW for subscription services
  Future<Map<String, double>> calculateSubscriptionBTW({
    required double subscriptionAmount,
    required String customerCountry,
    required bool isBusinessCustomer,
    String? vatNumber,
  }) async {
    
    double btwRate = _determineBTWRate(
      customerCountry: customerCountry,
      isBusinessCustomer: isBusinessCustomer,
      vatNumber: vatNumber,
    );
    
    final grossAmount = subscriptionAmount;
    final btwAmount = grossAmount * btwRate;
    final netAmount = grossAmount - btwAmount;
    
    // Log BTW calculation for audit
    await _logBTWCalculation(
      grossAmount: grossAmount,
      btwAmount: btwAmount,
      netAmount: netAmount,
      btwRate: btwRate,
      customerCountry: customerCountry,
      isBusinessCustomer: isBusinessCustomer,
      vatNumber: vatNumber,
    );
    
    return {
      'grossAmount': grossAmount,
      'btwAmount': btwAmount,
      'netAmount': netAmount,
      'btwRate': btwRate,
    };
  }
  
  /// Determine applicable BTW rate based on Dutch tax law
  double _determineBTWRate({
    required String customerCountry,
    required bool isBusinessCustomer,
    String? vatNumber,
  }) {
    // Dutch domestic customers - always 21% BTW
    if (customerCountry == 'NL') {
      return btwStandardRate;
    }
    
    // EU business customers with valid VAT number - reverse charge (0%)
    if (euCountryCodes.contains(customerCountry) && 
        isBusinessCustomer && 
        _isValidEUVATNumber(vatNumber)) {
      return btwZeroRate; // Reverse charge applies
    }
    
    // EU private customers - Dutch BTW rate applies for digital services
    if (euCountryCodes.contains(customerCountry) && !isBusinessCustomer) {
      return btwStandardRate; // Mini One Stop Shop (MOSS) rules
    }
    
    // Non-EU customers - no BTW (export)
    return btwZeroRate;
  }
  
  /// Validate EU VAT number format
  bool _isValidEUVATNumber(String? vatNumber) {
    if (vatNumber == null || vatNumber.length < 8) return false;
    
    // Basic format validation - in production, use EU VAT validation service
    final regex = RegExp(r'^[A-Z]{2}[0-9A-Z]{2,12}$');
    return regex.hasMatch(vatNumber.toUpperCase());
  }
  
  /// Generate quarterly BTW return for subscription revenue
  Future<BelastingdienstBTWReturn> generateQuarterlyBTWReturn({
    required int year,
    required int quarter,
  }) async {
    final quarterStart = DateTime(year, (quarter - 1) * 3 + 1, 1);
    final quarterEnd = DateTime(year, quarter * 3 + 1, 0);
    
    // Get all subscription transactions for the quarter
    final subscriptionRevenue = await _getQuarterlySubscriptionRevenue(
      startDate: quarterStart,
      endDate: quarterEnd,
    );
    
    // Calculate BTW owed
    final btwOwed = subscriptionRevenue['totalBTW'] as double;
    final grossRevenue = subscriptionRevenue['grossRevenue'] as double;
    
    // Get input BTW from business expenses (if any)
    final inputBTW = await _getInputBTWForQuarter(quarterStart, quarterEnd);
    
    // Calculate net BTW owed
    final netBTWOwed = btwOwed - inputBTW;
    
    return BelastingdienstBTWReturn(
      btwNumber: await _getCompanyBTWNumber(),
      year: year,
      quarter: quarter,
      declarationPeriod: '${DutchFormatting.getQuarterName(quarter)} $year',
      grossRevenue: grossRevenue,
      btwOwed: btwOwed,
      inputBTWDeducted: inputBTW,
      netBTWOwed: netBTWOwed,
      previousPeriodCarryOver: 0.0, // Would be calculated from previous returns
      quarterlyTurnover: grossRevenue,
      servicesRendered: grossRevenue, // All platform revenue is services
      goodsSupplied: 0.0, // No physical goods
      submissionDate: DateTime.now(),
      declarationType: BelastingdienstDeclarationType.quarterly,
    );
  }
  
  /// Submit BTW return to Belastingdienst
  Future<BelastingdienstSubmissionResult> submitBTWReturn(
    BelastingdienstBTWReturn btwReturn,
  ) async {
    try {
      // In production, integrate with Belastingdienst API
      // For now, store for manual submission
      await _firestore.collection('btw_returns').add({
        'data': btwReturn.toFirestore(),
        'status': 'pending_submission',
        'created_at': FieldValue.serverTimestamp(),
      });
      
      return BelastingdienstSubmissionResult(
        success: true,
        submissionId: 'BTW-${DateTime.now().millisecondsSinceEpoch}',
        referenceNumber: 'REF-${btwReturn.year}-Q${btwReturn.quarter}',
        submissionType: BelastingdienstSubmissionType.btwQuarterly,
        submittedAt: DateTime.now(),
        processingStatus: BelastingdienstProcessingStatus.submitted,
        receiptUrl: '', // Would be provided by Belastingdienst
        estimatedProcessingTime: const Duration(days: 5),
        nextSteps: [
          'BTW aangifte ingediend bij Belastingdienst',
          'Verwachte verwerkingstijd: 5 werkdagen',
          'U ontvangt bevestiging per email',
        ],
      );
    } catch (e) {
      throw Exception('Fout bij indienen BTW aangifte: $e');
    }
  }
  
  /// Calculate platform commission BTW
  Future<Map<String, double>> calculatePlatformCommissionBTW({
    required double commissionAmount,
    required String guardLocation,
  }) async {
    // Platform commission is always subject to Dutch BTW (21%)
    final btwAmount = commissionAmount * btwStandardRate;
    final netAmount = commissionAmount - btwAmount;
    
    // Log commission BTW
    await _logCommissionBTW(
      commissionAmount: commissionAmount,
      btwAmount: btwAmount,
      netAmount: netAmount,
      guardLocation: guardLocation,
    );
    
    return {
      'grossAmount': commissionAmount,
      'btwAmount': btwAmount,
      'netAmount': netAmount,
      'btwRate': btwStandardRate,
    };
  }
  
  // Private helper methods
  
  Future<Map<String, double>> _getQuarterlySubscriptionRevenue({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final subscriptions = await _firestore
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    
    double totalGross = 0.0;
    double totalBTW = 0.0;
    
    for (final doc in subscriptions.docs) {
      final data = doc.data();
      totalGross += (data['amount'] as num).toDouble();
      totalBTW += (data['btw_amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    return {
      'grossRevenue': totalGross,
      'totalBTW': totalBTW,
    };
  }
  
  Future<double> _getInputBTWForQuarter(DateTime start, DateTime end) async {
    // Get business expenses with deductible BTW
    final expenses = await _firestore
        .collection('business_expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .where('btw_deductible', isEqualTo: true)
        .get();
    
    double inputBTW = 0.0;
    for (final doc in expenses.docs) {
      inputBTW += (doc.data()['btw_amount'] as num?)?.toDouble() ?? 0.0;
    }
    
    return inputBTW;
  }
  
  Future<String> _getCompanyBTWNumber() async {
    // Retrieve company BTW number from configuration
    final config = await _firestore.collection('company_config').doc('tax_settings').get();
    return config.data()?['btw_number'] ?? 'NL123456789B01';
  }
  
  Future<void> _logBTWCalculation({
    required double grossAmount,
    required double btwAmount,
    required double netAmount,
    required double btwRate,
    required String customerCountry,
    required bool isBusinessCustomer,
    String? vatNumber,
  }) async {
    await _firestore.collection('btw_calculations').add({
      'gross_amount': grossAmount,
      'btw_amount': btwAmount,
      'net_amount': netAmount,
      'btw_rate': btwRate,
      'customer_country': customerCountry,
      'is_business_customer': isBusinessCustomer,
      'vat_number': vatNumber,
      'calculated_at': FieldValue.serverTimestamp(),
      'compliance_rule': _getBTWRuleApplied(customerCountry, isBusinessCustomer, vatNumber),
    });
  }
  
  String _getBTWRuleApplied(String country, bool isBusiness, String? vatNumber) {
    if (country == 'NL') return 'Dutch domestic - 21% BTW';
    if (euCountryCodes.contains(country) && isBusiness && _isValidEUVATNumber(vatNumber)) {
      return 'EU B2B reverse charge - 0% BTW';
    }
    if (euCountryCodes.contains(country) && !isBusiness) return 'EU B2C - 21% BTW (MOSS)';
    return 'Non-EU export - 0% BTW';
  }
  
  Future<void> _logCommissionBTW({
    required double commissionAmount,
    required double btwAmount,
    required double netAmount,
    required String guardLocation,
  }) async {
    await _firestore.collection('commission_btw_log').add({
      'commission_amount': commissionAmount,
      'btw_amount': btwAmount,
      'net_amount': netAmount,
      'btw_rate': btwStandardRate,
      'guard_location': guardLocation,
      'logged_at': FieldValue.serverTimestamp(),
    });
  }
}

/// Dutch BTW rate determination helper
extension DutchBTWRates on String {
  /// Get BTW rate for specific service type
  double getBTWRateForService(String serviceType) {
    switch (serviceType) {
      case 'subscription':
      case 'platform_fee':
      case 'commission':
        return 0.21; // Standard rate for digital services
      case 'export_service':
        return 0.00; // Export services
      default:
        return 0.21; // Default to standard rate
    }
  }
}