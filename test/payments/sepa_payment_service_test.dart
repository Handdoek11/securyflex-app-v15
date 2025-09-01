import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import 'package:securyflex_app/payments/services/sepa_payment_service.dart';
import 'package:securyflex_app/payments/models/payment_models.dart';
import 'package:securyflex_app/payments/security/payment_encryption_service.dart';
import 'package:securyflex_app/payments/services/payment_audit_service.dart';

// Mock classes
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockDio extends Mock implements Dio {}
class MockPaymentEncryptionService extends Mock implements PaymentEncryptionService {}
class MockPaymentAuditService extends Mock implements PaymentAuditService {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockResponse extends Mock implements Response {}

void main() {
  group('SepaPaymentService', () {
    late SepaPaymentService sepaService;
    late MockFirebaseFirestore mockFirestore;
    late MockDio mockHttpClient;
    late MockPaymentEncryptionService mockEncryption;
    late MockPaymentAuditService mockAudit;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockHttpClient = MockDio();
      mockEncryption = MockPaymentEncryptionService();
      mockAudit = MockPaymentAuditService();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();

      // Setup mock collection and document references
      when(() => mockFirestore.collection('payments')).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDocument);
      when(() => mockDocument.set(any())).thenAnswer((_) async => {});

      sepaService = SepaPaymentService(
        firestore: mockFirestore,
        httpClient: mockHttpClient,
        encryptionService: mockEncryption,
        auditService: mockAudit,
      );

      // Register fallback values
      registerFallbackValue(<String, dynamic>{});
    });

    group('processGuardPayment', () {
      test('should process successful SEPA payment', () async {
        // Arrange
        const guardId = 'guard123';
        const amount = 1500.0;
        const currency = 'EUR';
        const recipientIBAN = 'NL91ABNA0417164300';
        const recipientName = 'Jan de Vries';
        const description = 'Salaris augustus 2024';

        when(() => mockEncryption.encryptPaymentData(any()))
            .thenAnswer((_) async => 'encrypted_data');

        when(() => mockAudit.logPaymentTransaction(
          paymentId: any(named: 'paymentId'),
          type: any(named: 'type'),
          amount: any(named: 'amount'),
          status: any(named: 'status'),
          guardId: any(named: 'guardId'),
        )).thenAnswer((_) async => {});

        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(201);
        when(() => mockResponse.data).thenReturn('''<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <TxSts>ACCC</TxSts>
  <TxId>TXN123456</TxId>
  <EndToEndId>payment_id</EndToEndId>
</Response>''');

        when(() => mockHttpClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await sepaService.processGuardPayment(
          guardId: guardId,
          amount: amount,
          currency: currency,
          recipientIBAN: recipientIBAN,
          recipientName: recipientName,
          description: description,
        );

        // Assert
        expect(result.status, equals(PaymentStatus.completed));
        expect(result.transactionId, equals('TXN123456'));

        verify(() => mockEncryption.encryptPaymentData(any())).called(1);
        verify(() => mockDocument.set(any())).called(1);
        verify(() => mockAudit.logPaymentTransaction(
          paymentId: any(named: 'paymentId'),
          type: PaymentType.sepaTransfer,
          amount: amount,
          status: PaymentStatus.completed,
          guardId: guardId,
        )).called(1);
      });

      test('should validate payment parameters', () async {
        // Arrange - invalid amount
        const guardId = 'guard123';
        const amount = 0.0;
        const currency = 'EUR';
        const recipientIBAN = 'NL91ABNA0417164300';
        const recipientName = 'Jan de Vries';
        const description = 'Test payment';

        // Act & Assert
        expect(
          () => sepaService.processGuardPayment(
            guardId: guardId,
            amount: amount,
            currency: currency,
            recipientIBAN: recipientIBAN,
            recipientName: recipientName,
            description: description,
          ),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.invalidAmount,
          )),
        );
      });

      test('should validate Dutch IBAN format', () async {
        // Arrange - invalid Dutch IBAN
        const guardId = 'guard123';
        const amount = 100.0;
        const currency = 'EUR';
        const recipientIBAN = 'NL91INVALID';
        const recipientName = 'Jan de Vries';
        const description = 'Test payment';

        // Act & Assert
        expect(
          () => sepaService.processGuardPayment(
            guardId: guardId,
            amount: amount,
            currency: currency,
            recipientIBAN: recipientIBAN,
            recipientName: recipientName,
            description: description,
          ),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.invalidIBAN,
          )),
        );
      });

      test('should handle payment API errors', () async {
        // Arrange
        const guardId = 'guard123';
        const amount = 100.0;
        const currency = 'EUR';
        const recipientIBAN = 'NL91ABNA0417164300';
        const recipientName = 'Jan de Vries';
        const description = 'Test payment';

        when(() => mockEncryption.encryptPaymentData(any()))
            .thenAnswer((_) async => 'encrypted_data');

        when(() => mockHttpClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
        ));

        when(() => mockAudit.logPaymentTransaction(
          paymentId: any(named: 'paymentId'),
          type: any(named: 'type'),
          amount: any(named: 'amount'),
          status: any(named: 'status'),
          guardId: any(named: 'guardId'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await sepaService.processGuardPayment(
          guardId: guardId,
          amount: amount,
          currency: currency,
          recipientIBAN: recipientIBAN,
          recipientName: recipientName,
          description: description,
        );

        // Assert
        expect(result.status, equals(PaymentStatus.failed));
        expect(result.errorMessage, contains('SEPA overdracht mislukt'));

        verify(() => mockDocument.set(any())).called(1);
        verify(() => mockAudit.logPaymentTransaction(
          paymentId: any(named: 'paymentId'),
          type: PaymentType.sepaTransfer,
          amount: amount,
          status: PaymentStatus.failed,
          guardId: guardId,
        )).called(1);
      });
    });

    group('processBulkGuardPayments', () {
      test('should process successful bulk SEPA payments', () async {
        // Arrange
        final paymentRequests = [
          const GuardPaymentRequest(
            guardId: 'guard1',
            amount: 1500.0,
            recipientIBAN: 'NL91ABNA0417164300',
            recipientName: 'Jan de Vries',
            description: 'Salaris augustus 2024',
            paymentType: PaymentType.salary,
            metadata: {},
          ),
          const GuardPaymentRequest(
            guardId: 'guard2',
            amount: 1800.0,
            recipientIBAN: 'NL91RABO0315273637',
            recipientName: 'Marie Jansen',
            description: 'Salaris augustus 2024',
            paymentType: PaymentType.salary,
            metadata: {},
          ),
        ];
        const batchDescription = 'Salaris uitbetaling augustus 2024';

        when(() => mockEncryption.encryptPaymentData(any()))
            .thenAnswer((_) async => 'encrypted_data');

        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(201);
        when(() => mockResponse.data).thenReturn('''<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <PmtInfId>BATCH123</PmtInfId>
  <CdtTrfTxInf>
    <EndToEndId>guard1_payment</EndToEndId>
    <TxSts>ACCC</TxSts>
  </CdtTrfTxInf>
  <CdtTrfTxInf>
    <EndToEndId>guard2_payment</EndToEndId>
    <TxSts>ACCC</TxSts>
  </CdtTrfTxInf>
</Response>''');

        when(() => mockHttpClient.post(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => mockResponse);

        when(() => mockAudit.logBulkPayment(
          batchId: any(named: 'batchId'),
          paymentCount: any(named: 'paymentCount'),
          totalAmount: any(named: 'totalAmount'),
          status: any(named: 'status'),
        )).thenAnswer((_) async => {});

        // Act
        final result = await sepaService.processBulkGuardPayments(
          paymentRequests: paymentRequests,
          batchDescription: batchDescription,
        );

        // Assert
        expect(result.overallStatus, equals(PaymentStatus.completed));
        expect(result.individualResults.length, equals(2));
        expect(result.successfulPayments, equals(2));
        expect(result.failedPayments, equals(0));

        verify(() => mockDocument.set(any())).called(2); // One for each payment
        verify(() => mockAudit.logBulkPayment(
          batchId: any(named: 'batchId'),
          paymentCount: 2,
          totalAmount: 3300.0,
          status: PaymentStatus.completed,
        )).called(1);
      });

      test('should reject bulk payments exceeding limits', () async {
        // Arrange - too many payments
        final paymentRequests = List.generate(
          501, // Exceeds max limit of 500
          (index) => GuardPaymentRequest(
            guardId: 'guard$index',
            amount: 100.0,
            recipientIBAN: 'NL91ABNA0417164300',
            recipientName: 'Guard $index',
            description: 'Payment $index',
            paymentType: PaymentType.salary,
            metadata: const {},
          ),
        );

        // Act & Assert
        expect(
          () => sepaService.processBulkGuardPayments(
            paymentRequests: paymentRequests,
            batchDescription: 'Test bulk',
          ),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.bulkLimitExceeded,
          )),
        );
      });

      test('should reject bulk payments exceeding amount limits', () async {
        // Arrange - total amount too high
        final paymentRequests = [
          const GuardPaymentRequest(
            guardId: 'guard1',
            amount: 150000.0, // Exceeds max bulk amount
            recipientIBAN: 'NL91ABNA0417164300',
            recipientName: 'Jan de Vries',
            description: 'High amount payment',
            paymentType: PaymentType.salary,
            metadata: {},
          ),
        ];

        // Act & Assert
        expect(
          () => sepaService.processBulkGuardPayments(
            paymentRequests: paymentRequests,
            batchDescription: 'High amount bulk',
          ),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.amountLimitExceeded,
          )),
        );
      });
    });

    group('validateGuardPayment', () {
      test('should validate guard exists and has IBAN', () async {
        // Arrange
        const guardId = 'guard123';
        const amount = 1500.0;

        final mockDoc = MockDocumentSnapshot();
        when(() => mockDoc.exists).thenReturn(true);
        when(() => mockDoc.data()).thenReturn({
          'displayName': 'Jan de Vries',
          'email': 'jan@example.com',
          'iban': 'NL91ABNA0417164300',
          'hourlyRate': 15.0,
        });

        when(() => mockFirestore.collection('users').doc(guardId).get())
            .thenAnswer((_) async => mockDoc);

        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockQuerySnapshot.docs).thenReturn([]);

        final mockQuery = MockQuery();
        when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuery.where(any(), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo')))
            .thenReturn(mockQuery);

        when(() => mockCollection.where('guard_id', isEqualTo: guardId))
            .thenReturn(mockQuery);

        // Act & Assert - should not throw
        await expectLater(
          sepaService.validateGuardPayment(guardId: guardId, amount: amount),
          completes,
        );

        verify(() => mockFirestore.collection('users').doc(guardId).get()).called(1);
      });

      test('should reject payment for non-existent guard', () async {
        // Arrange
        const guardId = 'nonexistent';
        const amount = 1500.0;

        final mockDoc = MockDocumentSnapshot();
        when(() => mockDoc.exists).thenReturn(false);

        when(() => mockFirestore.collection('users').doc(guardId).get())
            .thenAnswer((_) async => mockDoc);

        // Act & Assert
        expect(
          () => sepaService.validateGuardPayment(guardId: guardId, amount: amount),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.guardNotFound,
          )),
        );
      });

      test('should reject payment for guard without IBAN', () async {
        // Arrange
        const guardId = 'guard123';
        const amount = 1500.0;

        final mockDoc = MockDocumentSnapshot();
        when(() => mockDoc.exists).thenReturn(true);
        when(() => mockDoc.data()).thenReturn({
          'displayName': 'Jan de Vries',
          'email': 'jan@example.com',
          // No IBAN field
        });

        when(() => mockFirestore.collection('users').doc(guardId).get())
            .thenAnswer((_) async => mockDoc);

        // Act & Assert
        expect(
          () => sepaService.validateGuardPayment(guardId: guardId, amount: amount),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.missingBankDetails,
          )),
        );
      });

      test('should reject payment exceeding monthly limit', () async {
        // Arrange
        const guardId = 'guard123';
        const amount = 30000.0; // This plus existing payments would exceed limit

        final mockDoc = MockDocumentSnapshot();
        when(() => mockDoc.exists).thenReturn(true);
        when(() => mockDoc.data()).thenReturn({
          'displayName': 'Jan de Vries',
          'email': 'jan@example.com',
          'iban': 'NL91ABNA0417164300',
        });

        when(() => mockFirestore.collection('users').doc(guardId).get())
            .thenAnswer((_) async => mockDoc);

        // Mock existing payments that sum to 20000
        final mockPaymentDoc = MockQueryDocumentSnapshot();
        when(() => mockPaymentDoc.data()).thenReturn({'amount_eur': 20000.0});

        final mockQuerySnapshot = MockQuerySnapshot();
        when(() => mockQuerySnapshot.docs).thenReturn([mockPaymentDoc]);

        final mockQuery = MockQuery();
        when(() => mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(() => mockQuery.where(any(), isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo')))
            .thenReturn(mockQuery);

        when(() => mockCollection.where('guard_id', isEqualTo: guardId))
            .thenReturn(mockQuery);

        // Act & Assert
        expect(
          () => sepaService.validateGuardPayment(guardId: guardId, amount: amount),
          throwsA(isA<PaymentException>().having(
            (e) => e.errorCode,
            'errorCode',
            PaymentErrorCode.monthlyLimitExceeded,
          )),
        );
      });
    });
  });
}

// Additional mock classes for Firestore
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}