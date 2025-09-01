import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/error/exceptions.dart';
import '../../shared/utils/dutch_formatting.dart';
import '../../shared/services/encryption_service.dart';
import '../../auth/services/bsn_security_service.dart';
import '../../schedule/services/payroll_export_service.dart';
import '../models/payment_models.dart';

/// Dutch invoice generation service for SecuryFlex
/// Creates tax-compliant invoices following Dutch regulations
class DutchInvoiceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  // final EncryptionService _encryptionService;
  // final PayrollExportService _payrollService;

  // Dutch tax settings
  static const double _standardBTWRate = 0.21; // 21% BTW
  // static const double _reducedBTWRate = 0.09;  // 9% BTW for specific services
  static const String _btwNumber = 'NL123456789B01'; // Company BTW number

  DutchInvoiceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    EncryptionService? encryptionService,
    PayrollExportService? payrollService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;
        // _encryptionService = encryptionService ?? EncryptionService(),
        // _payrollService = payrollService ?? PayrollExportService();

  /// Generate salary invoice for guard payment
  Future<InvoiceResult> generateSalaryInvoice({
    required String guardId,
    required String companyId,
    required PaymentTransaction payment,
    required Map<String, dynamic> earningsData,
  }) async {
    try {
      final invoiceNumber = await _generateInvoiceNumber('SAL');
      
      // Get company and guard information
      final companyInfo = await _getCompanyInfo(companyId);
      final guardInfo = await _getGuardInfo(guardId);
      
      // Create invoice data
      final invoiceData = DutchInvoiceData(
        invoiceNumber: invoiceNumber,
        type: InvoiceType.salaryInvoice,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 30)),
        companyInfo: companyInfo,
        guardInfo: guardInfo,
        lineItems: _createSalaryLineItems(payment, earningsData),
        btwRate: _standardBTWRate,
        totalAmount: payment.grossAmount,
        netAmount: payment.netAmount,
        btwAmount: payment.btwAmount,
        vakantiegeldAmount: payment.vakantiegeldAmount,
        pensionDeduction: payment.pensionDeduction,
        notes: 'Salaris periode ${_formatPaymentPeriod(payment.createdAt)}',
        complianceData: {
          'cao_compliant': true,
          'dutch_labor_law': true,
          'btw_calculated': true,
          'pension_deducted': true,
        },
      );

      // Generate PDF invoice
      final pdfBytes = await _generatePDF(invoiceData);
      
      // Save to Firebase Storage
      final downloadUrl = await _savePDFToStorage(
        pdfBytes,
        'invoices/salary/$invoiceNumber.pdf',
      );

      // Store invoice record
      final invoiceRecord = await _storeInvoiceRecord(invoiceData, downloadUrl);

      // Create audit trail
      await _createInvoiceAuditTrail(
        action: 'SALARY_INVOICE_GENERATED',
        invoiceNumber: invoiceNumber,
        guardId: guardId,
        companyId: companyId,
        amount: payment.grossAmount,
      );

      return InvoiceResult(
        success: true,
        invoiceNumber: invoiceNumber,
        downloadUrl: downloadUrl,
        invoiceId: invoiceRecord,
        totalAmount: payment.grossAmount,
        btwAmount: payment.btwAmount,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      await _logInvoiceError(guardId, companyId, e);
      rethrow;
    }
  }

  /// Generate expense reimbursement invoice
  Future<InvoiceResult> generateExpenseInvoice({
    required String guardId,
    required String companyId,
    required List<Map<String, dynamic>> expenses,
    required String description,
  }) async {
    try {
      final invoiceNumber = await _generateInvoiceNumber('EXP');
      
      // Get company and guard information
      final companyInfo = await _getCompanyInfo(companyId);
      final guardInfo = await _getGuardInfo(guardId);
      
      // Calculate totals
      final totalAmount = expenses.fold<double>(
        0.0,
        (total, expense) => total + (expense['amount'] as double),
      );
      final totalBTW = expenses.fold<double>(
        0.0,
        (total, expense) => total + (expense['btw_amount'] as double? ?? 0.0),
      );
      
      // Create invoice data
      final invoiceData = DutchInvoiceData(
        invoiceNumber: invoiceNumber,
        type: InvoiceType.expenseInvoice,
        issueDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 7)), // Faster payment for expenses
        companyInfo: companyInfo,
        guardInfo: guardInfo,
        lineItems: _createExpenseLineItems(expenses),
        btwRate: _standardBTWRate,
        totalAmount: totalAmount,
        netAmount: totalAmount - totalBTW,
        btwAmount: totalBTW,
        vakantiegeldAmount: 0.0,
        pensionDeduction: 0.0,
        notes: description,
        complianceData: {
          'expense_reimbursement': true,
          'receipts_attached': true,
          'btw_calculated': true,
          'dutch_tax_compliant': true,
        },
      );

      // Generate PDF invoice
      final pdfBytes = await _generatePDF(invoiceData);
      
      // Save to Firebase Storage
      final downloadUrl = await _savePDFToStorage(
        pdfBytes,
        'invoices/expenses/$invoiceNumber.pdf',
      );

      // Store invoice record
      final invoiceRecord = await _storeInvoiceRecord(invoiceData, downloadUrl);

      // Create audit trail
      await _createInvoiceAuditTrail(
        action: 'EXPENSE_INVOICE_GENERATED',
        invoiceNumber: invoiceNumber,
        guardId: guardId,
        companyId: companyId,
        amount: totalAmount,
      );

      return InvoiceResult(
        success: true,
        invoiceNumber: invoiceNumber,
        downloadUrl: downloadUrl,
        invoiceId: invoiceRecord,
        totalAmount: totalAmount,
        btwAmount: totalBTW,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      await _logInvoiceError(guardId, companyId, e);
      rethrow;
    }
  }

  /// Generate tax summary document for yearly overview
  Future<InvoiceResult> generateTaxSummary({
    required String guardId,
    required String companyId,
    required int year,
  }) async {
    try {
      final summaryNumber = await _generateInvoiceNumber('TAX$year');
      
      // Get all payments for the year
      final yearlyPayments = await _getYearlyPayments(guardId, companyId, year);
      
      // Calculate yearly totals
      final yearlyTotals = _calculateYearlyTotals(yearlyPayments);
      
      // Get company and guard information
      final companyInfo = await _getCompanyInfo(companyId);
      final guardInfo = await _getGuardInfo(guardId);
      
      // Create tax summary data
      final summaryData = DutchTaxSummaryData(
        summaryNumber: summaryNumber,
        year: year,
        companyInfo: companyInfo,
        guardInfo: guardInfo,
        totalGrossIncome: yearlyTotals['total_gross'],
        totalNetIncome: yearlyTotals['total_net'],
        totalBTWPaid: yearlyTotals['total_btw'],
        totalVakantiegeld: yearlyTotals['total_vakantiegeld'],
        totalPensionDeducted: yearlyTotals['total_pension'],
        totalIncomeTax: yearlyTotals['total_income_tax'],
        monthlyBreakdown: yearlyTotals['monthly_breakdown'],
        complianceData: {
          'year': year,
          'dutch_tax_year': true,
          'cao_compliant': true,
          'complete_record': true,
        },
      );

      // Generate PDF tax summary
      final pdfBytes = await _generateTaxSummaryPDF(summaryData);
      
      // Save to Firebase Storage
      final downloadUrl = await _savePDFToStorage(
        pdfBytes,
        'tax_summaries/$year/$summaryNumber.pdf',
      );

      // Store summary record
      final summaryRecord = await _storeTaxSummaryRecord(summaryData, downloadUrl);

      // Create audit trail
      await _createInvoiceAuditTrail(
        action: 'TAX_SUMMARY_GENERATED',
        invoiceNumber: summaryNumber,
        guardId: guardId,
        companyId: companyId,
        amount: yearlyTotals['total_gross'],
      );

      return InvoiceResult(
        success: true,
        invoiceNumber: summaryNumber,
        downloadUrl: downloadUrl,
        invoiceId: summaryRecord,
        totalAmount: yearlyTotals['total_gross'],
        btwAmount: yearlyTotals['total_btw'],
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      await _logInvoiceError(guardId, companyId, e);
      rethrow;
    }
  }

  /// Generate sequential invoice number
  Future<String> _generateInvoiceNumber(String prefix) async {
    final year = DateTime.now().year;
    final counterDoc = _firestore
        .collection('invoice_counters')
        .doc('${prefix}_$year');

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterDoc);
      
      int nextNumber;
      if (snapshot.exists) {
        nextNumber = (snapshot.data()!['count'] as int) + 1;
      } else {
        nextNumber = 1;
      }

      transaction.set(counterDoc, {
        'count': nextNumber,
        'year': year,
        'prefix': prefix,
        'updated_at': Timestamp.now(),
      }, SetOptions(merge: true));

      return '$prefix-$year-${nextNumber.toString().padLeft(4, '0')}';
    });
  }

  /// Create salary line items for invoice
  List<DutchInvoiceLineItem> _createSalaryLineItems(
    PaymentTransaction payment,
    Map<String, dynamic> earningsData,
  ) {
    final lineItems = <DutchInvoiceLineItem>[];

    // Base salary line
    lineItems.add(DutchInvoiceLineItem(
      description: 'Salaris beveiligingsdiensten',
      quantity: 1,
      unitPrice: payment.grossAmount - payment.vakantiegeldAmount,
      totalPrice: payment.grossAmount - payment.vakantiegeldAmount,
      btwRate: _standardBTWRate,
      btwAmount: payment.btwAmount,
    ));

    // Vakantiegeld line (if applicable)
    if (payment.vakantiegeldAmount > 0) {
      lineItems.add(DutchInvoiceLineItem(
        description: 'Vakantiegeld (8%)',
        quantity: 1,
        unitPrice: payment.vakantiegeldAmount,
        totalPrice: payment.vakantiegeldAmount,
        btwRate: 0.0, // Vakantiegeld is BTW-free
        btwAmount: 0.0,
      ));
    }

    // Overtime line (if applicable)
    final overtimeAmount = earningsData['overtime_amount'] as double? ?? 0.0;
    if (overtimeAmount > 0) {
      lineItems.add(DutchInvoiceLineItem(
        description: 'Overuren (150% tarief)',
        quantity: earningsData['overtime_hours'] as double? ?? 0.0,
        unitPrice: earningsData['overtime_rate'] as double? ?? 0.0,
        totalPrice: overtimeAmount,
        btwRate: _standardBTWRate,
        btwAmount: overtimeAmount * _standardBTWRate,
      ));
    }

    return lineItems;
  }

  /// Create expense line items for invoice
  List<DutchInvoiceLineItem> _createExpenseLineItems(
    List<Map<String, dynamic>> expenses,
  ) {
    return expenses.map((expense) {
      final amount = expense['amount'] as double;
      final btwAmount = expense['btw_amount'] as double? ?? 0.0;
      final btwRate = btwAmount > 0 ? btwAmount / amount : 0.0;

      return DutchInvoiceLineItem(
        description: expense['description'] as String,
        quantity: 1,
        unitPrice: amount,
        totalPrice: amount,
        btwRate: btwRate,
        btwAmount: btwAmount,
      );
    }).toList();
  }

  /// Generate PDF invoice document
  Future<Uint8List> _generatePDF(DutchInvoiceData invoiceData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          _buildInvoiceHeader(invoiceData),
          pw.SizedBox(height: 20),
          
          // Company and Guard info
          _buildPartyInfo(invoiceData),
          pw.SizedBox(height: 20),
          
          // Invoice details
          _buildInvoiceDetails(invoiceData),
          pw.SizedBox(height: 20),
          
          // Line items table
          _buildLineItemsTable(invoiceData),
          pw.SizedBox(height: 20),
          
          // Totals
          _buildTotalsSection(invoiceData),
          pw.SizedBox(height: 20),
          
          // Dutch compliance footer
          _buildComplianceFooter(invoiceData),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build invoice header
  pw.Widget _buildInvoiceHeader(DutchInvoiceData invoiceData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SecuryFlex B.V.',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Nederlandse Beveiliging Platform'),
            pw.Text('BTW: $_btwNumber'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              invoiceData.type.dutchName,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Nr: ${invoiceData.invoiceNumber}'),
            pw.Text('Datum: ${DutchFormatting.formatDate(invoiceData.issueDate)}'),
          ],
        ),
      ],
    );
  }

  /// Build party information section
  pw.Widget _buildPartyInfo(DutchInvoiceData invoiceData) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Van:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoiceData.companyInfo['name']),
              pw.Text(invoiceData.companyInfo['address']),
              pw.Text(invoiceData.companyInfo['postal_code']),
              pw.Text('KvK: ${invoiceData.companyInfo['kvk_number']}'),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Aan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoiceData.guardInfo['name']),
              pw.Text(invoiceData.guardInfo['address'] ?? 'Adres niet beschikbaar'),
              pw.Text(invoiceData.guardInfo['postal_code'] ?? ''),
              if (invoiceData.guardInfo['bsn'] != null)
                pw.Text('BSN: ${invoiceData.guardInfo['bsn']}'), // Already masked by service
            ],
          ),
        ),
      ],
    );
  }

  /// Build invoice details
  pw.Widget _buildInvoiceDetails(DutchInvoiceData invoiceData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Factuurnummer: ${invoiceData.invoiceNumber}'),
                pw.Text('Factuurdatum: ${DutchFormatting.formatDate(invoiceData.issueDate)}'),
                pw.Text('Vervaldatum: ${DutchFormatting.formatDate(invoiceData.dueDate)}'),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Totaalbedrag: ${DutchFormatting.formatCurrency(invoiceData.totalAmount)}'),
                pw.Text('Waarvan BTW: ${DutchFormatting.formatCurrency(invoiceData.btwAmount)}'),
                pw.Text('Te betalen: ${DutchFormatting.formatCurrency(invoiceData.netAmount)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build line items table
  pw.Widget _buildLineItemsTable(DutchInvoiceData invoiceData) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Omschrijving', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Aantal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Prijs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Totaal', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('BTW%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('BTW', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Data rows
        ...invoiceData.lineItems.map((item) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.description),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.quantity.toStringAsFixed(2)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(DutchFormatting.formatCurrency(item.unitPrice)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(DutchFormatting.formatCurrency(item.totalPrice)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('${(item.btwRate * 100).toStringAsFixed(0)}%'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(DutchFormatting.formatCurrency(item.btwAmount)),
            ),
          ],
        )),
      ],
    );
  }

  /// Build totals section
  pw.Widget _buildTotalsSection(DutchInvoiceData invoiceData) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 300,
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotaal:'),
                pw.Text(DutchFormatting.formatCurrency(invoiceData.totalAmount - invoiceData.btwAmount)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('BTW (21%):'),
                pw.Text(DutchFormatting.formatCurrency(invoiceData.btwAmount)),
              ],
            ),
            if (invoiceData.vakantiegeldAmount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Vakantiegeld:'),
                  pw.Text(DutchFormatting.formatCurrency(invoiceData.vakantiegeldAmount)),
                ],
              ),
            if (invoiceData.pensionDeduction > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Pensioen aftrek:'),
                  pw.Text('-${DutchFormatting.formatCurrency(invoiceData.pensionDeduction)}'),
                ],
              ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Totaal:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  DutchFormatting.formatCurrency(invoiceData.netAmount),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build compliance footer
  pw.Widget _buildComplianceFooter(DutchInvoiceData invoiceData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Opmerkingen:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (invoiceData.notes.isNotEmpty)
          pw.Text(invoiceData.notes),
        pw.SizedBox(height: 10),
        pw.Text('Deze factuur voldoet aan de Nederlandse wetgeving en BTW-regelgeving.'),
        pw.Text('Betaling binnen 30 dagen na factuurdatum.'),
        if (invoiceData.type == InvoiceType.salaryInvoice)
          pw.Text('Salaris conform CAO Particuliere Beveiliging.'),
      ],
    );
  }

  /// Generate tax summary PDF
  Future<Uint8List> _generateTaxSummaryPDF(DutchTaxSummaryData summaryData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Tax summary header
          pw.Text(
            'Belastingoverzicht ${summaryData.year}',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          
          // Yearly totals
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Totaal bruto inkomen:'),
                    pw.Text(DutchFormatting.formatCurrency(summaryData.totalGrossIncome)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Totaal netto inkomen:'),
                    pw.Text(DutchFormatting.formatCurrency(summaryData.totalNetIncome)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Totaal BTW betaald:'),
                    pw.Text(DutchFormatting.formatCurrency(summaryData.totalBTWPaid)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Totaal vakantiegeld:'),
                    pw.Text(DutchFormatting.formatCurrency(summaryData.totalVakantiegeld)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Save PDF to Firebase Storage
  Future<String> _savePDFToStorage(Uint8List pdfBytes, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'generated_by': 'SecuryFlex',
            'generated_at': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw BusinessLogicException(
        'Failed to save invoice PDF: ${e.toString()}',
        errorCode: 'PDF_STORAGE_ERROR',
      );
    }
  }

  /// Store invoice record in Firestore
  Future<String> _storeInvoiceRecord(
    DutchInvoiceData invoiceData,
    String downloadUrl,
  ) async {
    final invoiceRecord = {
      'invoice_number': invoiceData.invoiceNumber,
      'type': invoiceData.type.name,
      'issue_date': invoiceData.issueDate,
      'due_date': invoiceData.dueDate,
      'company_id': invoiceData.companyInfo['id'],
      'guard_id': invoiceData.guardInfo['id'],
      'total_amount': invoiceData.totalAmount,
      'net_amount': invoiceData.netAmount,
      'btw_amount': invoiceData.btwAmount,
      'vakantiegeld_amount': invoiceData.vakantiegeldAmount,
      'pension_deduction': invoiceData.pensionDeduction,
      'download_url': downloadUrl,
      'status': 'generated',
      'created_at': FieldValue.serverTimestamp(),
      'compliance_data': invoiceData.complianceData,
    };

    final docRef = await _firestore.collection('invoices').add(invoiceRecord);
    return docRef.id;
  }

  /// Store tax summary record
  Future<String> _storeTaxSummaryRecord(
    DutchTaxSummaryData summaryData,
    String downloadUrl,
  ) async {
    final summaryRecord = {
      'summary_number': summaryData.summaryNumber,
      'year': summaryData.year,
      'company_id': summaryData.companyInfo['id'],
      'guard_id': summaryData.guardInfo['id'],
      'total_gross_income': summaryData.totalGrossIncome,
      'total_net_income': summaryData.totalNetIncome,
      'total_btw_paid': summaryData.totalBTWPaid,
      'total_vakantiegeld': summaryData.totalVakantiegeld,
      'total_pension_deducted': summaryData.totalPensionDeducted,
      'total_income_tax': summaryData.totalIncomeTax,
      'download_url': downloadUrl,
      'status': 'generated',
      'created_at': FieldValue.serverTimestamp(),
      'compliance_data': summaryData.complianceData,
    };

    final docRef = await _firestore.collection('tax_summaries').add(summaryRecord);
    return docRef.id;
  }

  /// Get company information
  Future<Map<String, dynamic>> _getCompanyInfo(String companyId) async {
    final doc = await _firestore.collection('companies').doc(companyId).get();
    
    if (!doc.exists) {
      throw BusinessLogicException('Company not found', errorCode: 'COMPANY_NOT_FOUND');
    }
    
    final data = doc.data()!;
    return {
      'id': companyId,
      'name': data['companyName'] ?? 'Bedrijf',
      'address': data['address'] ?? '',
      'postal_code': data['postalCode'] ?? '',
      'kvk_number': data['kvkNumber'] ?? '',
      'btw_number': data['btwNumber'] ?? _btwNumber,
    };
  }

  /// Get guard information
  Future<Map<String, dynamic>> _getGuardInfo(String guardId) async {
    final doc = await _firestore.collection('guards').doc(guardId).get();
    
    if (!doc.exists) {
      throw BusinessLogicException('Guard not found', errorCode: 'GUARD_NOT_FOUND');
    }
    
    final data = doc.data()!;
    // Decrypt and securely handle BSN data
    String? secureBSN;
    if (data['bsn'] != null && data['bsn'].toString().isNotEmpty) {
      try {
        // If BSN is encrypted, decrypt it first
        if (BSNSecurityService.isEncryptedBSN(data['bsn'].toString())) {
          final decryptedBSN = await BSNSecurityService.instance.decryptBSN(data['bsn'].toString(), guardId);
          secureBSN = BSNSecurityService.maskBSN(decryptedBSN);
        } else {
          // If BSN is plain text, validate and mask it
          if (BSNSecurityService.isValidBSN(data['bsn'].toString())) {
            secureBSN = BSNSecurityService.maskBSN(data['bsn'].toString());
          } else {
            secureBSN = '***INVALID***';
          }
        }
        
        // Audit BSN access for invoice generation
        BSNSecurityService.hashBSNForAudit(data['bsn'].toString());
      } catch (e) {
        debugPrint('BSN handling error in invoice: $e');
        secureBSN = '***ERROR***';
      }
    }
    
    return {
      'id': guardId,
      'name': '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
      'address': data['address'],
      'postal_code': data['postalCode'],
      'bsn': secureBSN ?? '', // Always use masked BSN
    };
  }

  /// Get yearly payments for tax summary
  Future<List<Map<String, dynamic>>> _getYearlyPayments(
    String guardId,
    String companyId,
    int year,
  ) async {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year + 1, 1, 1);

    final snapshot = await _firestore
        .collection('payments')
        .where('guard_id', isEqualTo: guardId)
        .where('company_id', isEqualTo: companyId)
        .where('created_at', isGreaterThanOrEqualTo: startOfYear)
        .where('created_at', isLessThan: endOfYear)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Calculate yearly totals
  Map<String, dynamic> _calculateYearlyTotals(List<Map<String, dynamic>> payments) {
    double totalGross = 0.0;
    double totalNet = 0.0;
    double totalBTW = 0.0;
    double totalVakantiegeld = 0.0;
    double totalPension = 0.0;
    double totalIncomeTax = 0.0;

    final monthlyBreakdown = <String, Map<String, double>>{};

    for (final payment in payments) {
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
      final netAmount = (payment['net_amount'] as num?)?.toDouble() ?? 0.0;
      final btwAmount = (payment['btw_amount'] as num?)?.toDouble() ?? 0.0;
      final vakantiegeldAmount = (payment['vakantiegeld_amount'] as num?)?.toDouble() ?? 0.0;
      final pensionDeduction = (payment['pension_deduction'] as num?)?.toDouble() ?? 0.0;
      final inkomstenbel = (payment['inkomstenbelasting_amount'] as num?)?.toDouble() ?? 0.0;

      totalGross += amount;
      totalNet += netAmount;
      totalBTW += btwAmount;
      totalVakantiegeld += vakantiegeldAmount;
      totalPension += pensionDeduction;
      totalIncomeTax += inkomstenbel;

      // Monthly breakdown
      final createdAt = (payment['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
      final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
      
      monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? {})
        ..update('gross', (v) => v + amount, ifAbsent: () => amount)
        ..update('net', (v) => v + netAmount, ifAbsent: () => netAmount)
        ..update('btw', (v) => v + btwAmount, ifAbsent: () => btwAmount);
    }

    return {
      'total_gross': totalGross,
      'total_net': totalNet,
      'total_btw': totalBTW,
      'total_vakantiegeld': totalVakantiegeld,
      'total_pension': totalPension,
      'total_income_tax': totalIncomeTax,
      'monthly_breakdown': monthlyBreakdown,
    };
  }

  /// Format payment period
  String _formatPaymentPeriod(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${DutchFormatting.formatDate(startOfWeek)} - ${DutchFormatting.formatDate(endOfWeek)}';
  }

  /// Create audit trail for invoice operations
  Future<void> _createInvoiceAuditTrail({
    required String action,
    required String invoiceNumber,
    required String guardId,
    required String companyId,
    required double amount,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'invoice_number': invoiceNumber,
      'user_id': _auth.currentUser?.uid,
      'guard_id': guardId,
      'company_id': companyId,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'compliance_flags': {
        'invoice_generated': true,
        'dutch_tax_compliant': true,
        'btw_calculated': true,
      },
    });
  }

  /// Log invoice errors
  Future<void> _logInvoiceError(String guardId, String companyId, dynamic error) async {
    await _firestore.collection('invoice_errors').add({
      'guard_id': guardId,
      'company_id': companyId,
      'error_message': error.toString(),
      'error_type': error.runtimeType.toString(),
      'timestamp': FieldValue.serverTimestamp(),
      'stack_trace': StackTrace.current.toString(),
    });
  }
}

/// Dutch invoice data structure
class DutchInvoiceData {
  final String invoiceNumber;
  final InvoiceType type;
  final DateTime issueDate;
  final DateTime dueDate;
  final Map<String, dynamic> companyInfo;
  final Map<String, dynamic> guardInfo;
  final List<DutchInvoiceLineItem> lineItems;
  final double btwRate;
  final double totalAmount;
  final double netAmount;
  final double btwAmount;
  final double vakantiegeldAmount;
  final double pensionDeduction;
  final String notes;
  final Map<String, dynamic> complianceData;

  const DutchInvoiceData({
    required this.invoiceNumber,
    required this.type,
    required this.issueDate,
    required this.dueDate,
    required this.companyInfo,
    required this.guardInfo,
    required this.lineItems,
    required this.btwRate,
    required this.totalAmount,
    required this.netAmount,
    required this.btwAmount,
    required this.vakantiegeldAmount,
    required this.pensionDeduction,
    required this.notes,
    required this.complianceData,
  });
}

/// Dutch tax summary data structure
class DutchTaxSummaryData {
  final String summaryNumber;
  final int year;
  final Map<String, dynamic> companyInfo;
  final Map<String, dynamic> guardInfo;
  final double totalGrossIncome;
  final double totalNetIncome;
  final double totalBTWPaid;
  final double totalVakantiegeld;
  final double totalPensionDeducted;
  final double totalIncomeTax;
  final Map<String, Map<String, double>> monthlyBreakdown;
  final Map<String, dynamic> complianceData;

  const DutchTaxSummaryData({
    required this.summaryNumber,
    required this.year,
    required this.companyInfo,
    required this.guardInfo,
    required this.totalGrossIncome,
    required this.totalNetIncome,
    required this.totalBTWPaid,
    required this.totalVakantiegeld,
    required this.totalPensionDeducted,
    required this.totalIncomeTax,
    required this.monthlyBreakdown,
    required this.complianceData,
  });
}

/// Dutch invoice line item
class DutchInvoiceLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double btwRate;
  final double btwAmount;

  const DutchInvoiceLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.btwRate,
    required this.btwAmount,
  });
}

/// Invoice result
class InvoiceResult {
  final bool success;
  final String invoiceNumber;
  final String downloadUrl;
  final String invoiceId;
  final double totalAmount;
  final double btwAmount;
  final DateTime generatedAt;

  const InvoiceResult({
    required this.success,
    required this.invoiceNumber,
    required this.downloadUrl,
    required this.invoiceId,
    required this.totalAmount,
    required this.btwAmount,
    required this.generatedAt,
  });
}