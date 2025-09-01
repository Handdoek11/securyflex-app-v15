import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:securyflex_app/payments/bloc/payment_bloc.dart';
import 'package:securyflex_app/payments/models/payment_models.dart';
import 'package:securyflex_app/payments/repository/payment_repository.dart';
import 'package:securyflex_app/payments/services/ideal_payment_service.dart';
import 'package:securyflex_app/payments/services/sepa_payment_service.dart';
import 'package:securyflex_app/payments/services/dutch_invoice_service.dart';
import 'package:securyflex_app/payments/services/payment_audit_service.dart';

// Mock classes
class MockPaymentRepository extends Mock implements PaymentRepository {}
class MockiDEALPaymentService extends Mock implements iDEALPaymentService {}
class MockSepaPaymentService extends Mock implements SepaPaymentService {}
class MockDutchInvoiceService extends Mock implements DutchInvoiceService {}
class MockPaymentAuditService extends Mock implements PaymentAuditService {}

void main() {
  group('PaymentBloc', () {
    late PaymentBloc paymentBloc;
    late MockPaymentRepository mockRepository;
    late MockiDEALPaymentService mockIdealService;
    late MockSepaPaymentService mockSepaService;
    late MockDutchInvoiceService mockInvoiceService;
    late MockPaymentAuditService mockAuditService;

    setUp(() {
      mockRepository = MockPaymentRepository();
      mockIdealService = MockiDEALPaymentService();
      mockSepaService = MockSepaPaymentService();
      mockInvoiceService = MockDutchInvoiceService();
      mockAuditService = MockPaymentAuditService();

      paymentBloc = PaymentBloc(
        paymentRepository: mockRepository,
        idealService: mockIdealService,
        sepaService: mockSepaService,
        invoiceService: mockInvoiceService,
        auditService: mockAuditService,
      );
    });

    tearDown(() {
      paymentBloc.close();
    });

    group('ProcessSEPAPayment', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, SEPAPaymentCreated] when SEPA payment succeeds',
        build: () {
          final mockResult = PaymentResult(
            paymentId: 'payment123',
            status: PaymentStatus.completed,
            processingTime: DateTime.now(),
            transactionId: 'txn123',
            metadata: {},
          );

          when(() => mockSepaService.processGuardPayment(
            guardId: any(named: 'guardId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            recipientIBAN: any(named: 'recipientIBAN'),
            recipientName: any(named: 'recipientName'),
            description: any(named: 'description'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => mockResult);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(const ProcessSEPAPayment(
          guardId: 'guard123',
          amount: 1500.0,
          recipientIBAN: 'NL91ABNA0417164300',
          recipientName: 'Jan de Vries',
          description: 'Salaris augustus 2024',
          metadata: {'period': '2024-08'},
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'SEPA_PAYMENT',
            message: 'SEPA betaling wordt verwerkt...',
          ),
          isA<SEPAPaymentCreated>()
              .having((state) => state.result.status, 'status', PaymentStatus.completed)
              .having((state) => state.result.paymentId, 'paymentId', 'payment123'),
        ],
        verify: (bloc) {
          verify(() => mockSepaService.processGuardPayment(
            guardId: 'guard123',
            amount: 1500.0,
            currency: 'EUR',
            recipientIBAN: 'NL91ABNA0417164300',
            recipientName: 'Jan de Vries',
            description: 'Salaris augustus 2024',
            metadata: {'period': '2024-08'},
          )).called(1);
        },
      );

      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, PaymentError] when SEPA payment fails',
        build: () {
          when(() => mockSepaService.processGuardPayment(
            guardId: any(named: 'guardId'),
            amount: any(named: 'amount'),
            currency: any(named: 'currency'),
            recipientIBAN: any(named: 'recipientIBAN'),
            recipientName: any(named: 'recipientName'),
            description: any(named: 'description'),
            metadata: any(named: 'metadata'),
          )).thenThrow(const PaymentException(
            'IBAN ongeldig',
            PaymentErrorCode.invalidIBAN,
          ));

          when(() => mockAuditService.logPaymentError(
            type: any(named: 'type'),
            error: any(named: 'error'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async {});

          return paymentBloc;
        },
        act: (bloc) => bloc.add(const ProcessSEPAPayment(
          guardId: 'guard123',
          amount: 1500.0,
          recipientIBAN: 'INVALID_IBAN',
          recipientName: 'Jan de Vries',
          description: 'Test payment',
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'SEPA_PAYMENT',
            message: 'SEPA betaling wordt verwerkt...',
          ),
          isA<PaymentError>()
              .having((state) => state.error, 'error', 'IBAN ongeldig')
              .having((state) => state.operationType, 'operationType', 'SEPA_PAYMENT')
              .having((state) => state.errorCode, 'errorCode', PaymentErrorCode.invalidIBAN),
        ],
        verify: (bloc) {
          verify(() => mockAuditService.logPaymentError(
            type: 'SEPA_PAYMENT_BLOC_ERROR',
            error: 'IBAN ongeldig',
            metadata: any(named: 'metadata'),
          )).called(1);
        },
      );
    });

    group('ProcessBulkSEPAPayments', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, BulkSEPAPaymentCreated] when bulk payment succeeds',
        build: () {
          final mockResult = BulkPaymentResult(
            batchId: 'batch123',
            overallStatus: PaymentStatus.completed,
            individualResults: [
              PaymentResult(
                paymentId: 'payment1',
                status: PaymentStatus.completed,
                processingTime: DateTime.now(),
                metadata: {},
              ),
              PaymentResult(
                paymentId: 'payment2',
                status: PaymentStatus.completed,
                processingTime: DateTime.now(),
                metadata: {},
              ),
            ],
            processingTime: DateTime.now(),
            metadata: {},
          );

          when(() => mockSepaService.processBulkGuardPayments(
            paymentRequests: any(named: 'paymentRequests'),
            batchDescription: any(named: 'batchDescription'),
          )).thenAnswer((_) async => mockResult);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(ProcessBulkSEPAPayments(
          paymentRequests: const [
            GuardPaymentRequest(
              guardId: 'guard1',
              amount: 1500.0,
              recipientIBAN: 'NL91ABNA0417164300',
              recipientName: 'Jan de Vries',
              description: 'Salaris',
              paymentType: PaymentType.salary,
              metadata: {},
            ),
            GuardPaymentRequest(
              guardId: 'guard2',
              amount: 1800.0,
              recipientIBAN: 'NL91RABO0315273637',
              recipientName: 'Marie Jansen',
              description: 'Salaris',
              paymentType: PaymentType.salary,
              metadata: {},
            ),
          ],
          batchDescription: 'Salaris uitbetaling augustus 2024',
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'BULK_SEPA_PAYMENT',
            message: 'Bulk SEPA betalingen worden verwerkt...',
          ),
          isA<BulkSEPAPaymentCreated>()
              .having((state) => state.result.batchId, 'batchId', 'batch123')
              .having((state) => state.result.overallStatus, 'overallStatus', PaymentStatus.completed)
              .having((state) => state.result.successfulPayments, 'successfulPayments', 2),
        ],
      );
    });

    group('CreateiDEALPayment', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, iDEALPaymentCreated] when iDEAL payment creation succeeds',
        build: () {
          final mockResult = iDEALPaymentResult(
            paymentId: 'ideal123',
            providerPaymentId: 'provider123',
            checkoutUrl: 'https://ideal.example.com/checkout',
            status: PaymentStatus.awaitingBank,
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          );

          when(() => mockIdealService.createPayment(
            userId: any(named: 'userId'),
            amount: any(named: 'amount'),
            description: any(named: 'description'),
            returnUrl: any(named: 'returnUrl'),
            webhookUrl: any(named: 'webhookUrl'),
            paymentType: any(named: 'paymentType'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => mockResult);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(const CreateiDEALPayment(
          userId: 'user123',
          amount: 250.0,
          description: 'Onkostenvergoeding',
          paymentType: PaymentType.expense,
          returnUrl: 'https://app.securyflex.nl/return',
          webhookUrl: 'https://app.securyflex.nl/webhook',
          metadata: {'expense_id': 'exp123'},
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'IDEAL_PAYMENT',
            message: 'iDEAL betaling wordt aangemaakt...',
          ),
          isA<iDEALPaymentCreated>()
              .having((state) => state.result.paymentId, 'paymentId', 'ideal123')
              .having((state) => state.result.status, 'status', PaymentStatus.awaitingBank)
              .having((state) => state.result.checkoutUrl, 'checkoutUrl', 'https://ideal.example.com/checkout'),
        ],
      );
    });

    group('GetiDEALBanks', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, iDEALBanksLoaded] when banks are loaded successfully',
        build: () {
          final mockBanks = [
            const iDEALBank(
              bic: 'ABNANL2A',
              name: 'ABN AMRO',
              countryCode: 'NL',
            ),
            const iDEALBank(
              bic: 'INGBNL2A',
              name: 'ING',
              countryCode: 'NL',
            ),
            const iDEALBank(
              bic: 'RABONL2U',
              name: 'Rabobank',
              countryCode: 'NL',
            ),
          ];

          when(() => mockIdealService.getAvailableBanks())
              .thenAnswer((_) async => mockBanks);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(const GetiDEALBanks()),
        expect: () => [
          const PaymentLoading(
            operationType: 'IDEAL_BANKS',
            message: 'Beschikbare banken laden...',
          ),
          isA<iDEALBanksLoaded>()
              .having((state) => state.banks.length, 'banksCount', 3)
              .having((state) => state.banks.first.name, 'firstBankName', 'ABN AMRO'),
        ],
      );
    });

    group('LoadSEPAPaymentsForGuard', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, PaymentsLoaded] when SEPA payments are loaded',
        build: () {
          final mockPayments = [
            SEPAPayment(
              id: 'sepa1',
              guardId: 'guard123',
              amount: 1500.0,
              currency: 'EUR',
              recipientIBAN: 'NL91ABNA0417164300',
              recipientName: 'Jan de Vries',
              description: 'Salaris augustus',
              status: PaymentStatus.completed,
              createdAt: DateTime.now(),
              metadata: const {},
            ),
            SEPAPayment(
              id: 'sepa2',
              guardId: 'guard123',
              amount: 1800.0,
              currency: 'EUR',
              recipientIBAN: 'NL91ABNA0417164300',
              recipientName: 'Jan de Vries',
              description: 'Salaris september',
              status: PaymentStatus.pending,
              createdAt: DateTime.now(),
              metadata: const {},
            ),
          ];

          when(() => mockRepository.getSEPAPaymentsForGuard('guard123', limit: 50))
              .thenAnswer((_) async => mockPayments);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(const LoadSEPAPaymentsForGuard(
          guardId: 'guard123',
          limit: 50,
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'LOAD_SEPA_PAYMENTS',
            message: 'SEPA betalingen laden...',
          ),
          isA<PaymentsLoaded>()
              .having((state) => state.payments.length, 'paymentsCount', 2)
              .having((state) => state.paymentType, 'paymentType', PaymentType.sepaTransfer),
        ],
      );
    });

    group('LoadPaymentAnalytics', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, PaymentAnalyticsLoaded] when analytics are loaded',
        build: () {
          final startDate = DateTime(2024, 8, 1);
          final endDate = DateTime(2024, 8, 31);
          
          final mockAnalytics = PaymentAnalytics(
            period: startDate,
            totalVolume: 15750.0,
            totalTransactions: 10,
            averageTransaction: 1575.0,
            successfulTransactions: 9,
            failedTransactions: 1,
            successRate: 0.9,
            volumeByType: const {
              PaymentType.sepaTransfer: 12000.0,
              PaymentType.idealPayment: 3750.0,
            },
            transactionsByStatus: const {
              PaymentStatus.completed: 9,
              PaymentStatus.failed: 1,
            },
            dailySummaries: [
              DailyPaymentSummary(
                date: DateTime(2024, 8, 15),
                volume: 5250.0,
                transactions: 3,
                successRate: 1.0,
              ),
            ],
          );

          when(() => mockRepository.getPaymentAnalytics(startDate, endDate))
              .thenAnswer((_) async => mockAnalytics);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(LoadPaymentAnalytics(
          startDate: DateTime(2024, 8, 1),
          endDate: DateTime(2024, 8, 31),
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'LOAD_ANALYTICS',
            message: 'Betalingsanalyses laden...',
          ),
          isA<PaymentAnalyticsLoaded>()
              .having((state) => state.analytics.totalVolume, 'totalVolume', 15750.0)
              .having((state) => state.analytics.successRate, 'successRate', 0.9)
              .having((state) => state.analytics.totalTransactions, 'totalTransactions', 10),
        ],
      );
    });

    group('ClearPaymentError', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentInitial] when error is cleared',
        build: () => paymentBloc,
        seed: () => const PaymentError(
          error: 'Test error',
          operationType: 'TEST',
        ),
        act: (bloc) => bloc.add(const ClearPaymentError()),
        expect: () => [const PaymentInitial()],
      );
    });

    group('CreateRefund', () {
      blocTest<PaymentBloc, PaymentState>(
        'emits [PaymentLoading, RefundCreated] when refund is created successfully',
        build: () {
          final mockResult = RefundResult(
            refundId: 'refund123',
            providerRefundId: 'provider_refund_123',
            status: RefundStatus.pending,
            amount: 100.0,
            createdAt: DateTime.now(),
          );

          when(() => mockIdealService.createRefund(
            paymentId: any(named: 'paymentId'),
            amount: any(named: 'amount'),
            description: any(named: 'description'),
            metadata: any(named: 'metadata'),
          )).thenAnswer((_) async => mockResult);

          return paymentBloc;
        },
        act: (bloc) => bloc.add(const CreateRefund(
          paymentId: 'payment123',
          amount: 100.0,
          description: 'Terugbetaling onkostenvergoeding',
          metadata: {'reason': 'duplicate_payment'},
        )),
        expect: () => [
          const PaymentLoading(
            operationType: 'CREATE_REFUND',
            message: 'Terugbetaling wordt verwerkt...',
          ),
          isA<RefundCreated>()
              .having((state) => state.result.refundId, 'refundId', 'refund123')
              .having((state) => state.result.amount, 'amount', 100.0)
              .having((state) => state.result.status, 'status', RefundStatus.pending),
        ],
      );
    });
  });
}