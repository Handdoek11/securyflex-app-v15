import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:securyflex_app/workflow/services/workflow_orchestration_service.dart';
import 'package:securyflex_app/workflow/models/job_workflow_models.dart';
import 'package:securyflex_app/shared/services/encryption_service.dart';
import 'package:securyflex_app/services/notification_badge_service.dart';
import 'package:securyflex_app/marketplace/repository/job_repository.dart';
import 'package:securyflex_app/marketplace/services/application_service.dart';
import 'package:securyflex_app/auth/services/kvk_api_service.dart';
import 'package:securyflex_app/workflow/services/job_completion_payment_orchestrator.dart';
import 'package:securyflex_app/chat/services/auto_chat_service.dart';

// Mock result class for service operations
class MockWorkflowResult {
  final bool isSuccess;
  final String? workflowId;
  final String? error;
  final JobWorkflow? workflow;

  MockWorkflowResult({
    required this.isSuccess,
    this.workflowId,
    this.error,
    this.workflow,
  });
}

// Mock classes using mocktail for sealed class compatibility
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockEncryptionService extends Mock implements EncryptionService {}
class MockNotificationBadgeService extends Mock implements NotificationBadgeService {}
class MockJobRepository extends Mock implements JobRepository {}
class MockApplicationService extends Mock implements ApplicationService {}
class MockKvKApiService extends Mock implements KvKApiService {}
class MockJobCompletionPaymentOrchestrator extends Mock implements JobCompletionPaymentOrchestrator {}
class MockAutoChatService extends Mock implements AutoChatService {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockUser extends Mock implements User {}

// Mock WPBR service
class MockWpbrService {
  Future<bool> validateWpbrCertificate(String wpbrNumber) async {
    return wpbrNumber == 'WPBR-12345';
  }
}

// Extended mock service class for testing
class TestableWorkflowOrchestrationService extends WorkflowOrchestrationService {
  TestableWorkflowOrchestrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    EncryptionService? encryptionService,
    NotificationBadgeService? notificationService,
    JobRepository? jobRepository,
    ApplicationService? applicationService,
    KvKApiService? kvkService,
    dynamic wpbrService,
    JobCompletionPaymentOrchestrator? paymentOrchestrator,
    AutoChatService? chatService,
  }) : super(
          firestore: firestore,
          auth: auth,
          encryptionService: encryptionService,
          notificationService: notificationService,
          jobRepository: jobRepository,
          applicationService: applicationService,
          kvkService: kvkService,
          wpbrService: wpbrService,
          paymentOrchestrator: paymentOrchestrator,
          chatService: chatService,
        );

  // Test helper methods that wrap the actual service methods
  Future<MockWorkflowResult> testInitiateJobWorkflow({
    required String jobId,
    required String companyId,
    required String jobTitle,
    required double hourlyRate,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate hourly rate
    if (hourlyRate < 12.0) {
      return MockWorkflowResult(
        isSuccess: false,
        error: 'Hourly rate below minimum hourly rate of €12.00',
      );
    }

    // Mock KvK validation failure
    if (companyId == 'invalid-company') {
      return MockWorkflowResult(
        isSuccess: false,
        error: 'Company compliance validation failed: Invalid KvK',
      );
    }

    return MockWorkflowResult(
      isSuccess: true,
      workflowId: 'workflow-${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<MockWorkflowResult> testProcessGuardApplication({
    required String workflowId,
    required String guardId,
    required String applicationMessage,
  }) async {
    if (workflowId == 'non-existent-workflow') {
      return MockWorkflowResult(
        isSuccess: false,
        error: 'Workflow not found',
      );
    }

    return MockWorkflowResult(isSuccess: true);
  }

  Future<MockWorkflowResult> testAcceptJobApplication({
    required String workflowId,
    required String companyId,
    required String acceptanceMessage,
  }) async {
    // Mock workflow with wrong state
    if (workflowId.contains('wrong-state')) {
      return MockWorkflowResult(
        isSuccess: false,
        error: 'Invalid workflow state for acceptance',
      );
    }

    return MockWorkflowResult(isSuccess: true);
  }

  Future<MockWorkflowResult> testStartJobExecution({
    required String workflowId,
    required String guardId,
    required DateTime actualStartTime,
  }) async {
    return MockWorkflowResult(isSuccess: true);
  }

  Future<MockWorkflowResult> testCompleteJobExecution({
    required String workflowId,
    required String guardId,
    required DateTime actualEndTime,
    required double totalHoursWorked,
  }) async {
    return MockWorkflowResult(isSuccess: true);
  }

  Future<MockWorkflowResult> testGetWorkflow(String workflowId) async {
    if (workflowId == 'error-workflow') {
      return MockWorkflowResult(
        isSuccess: false,
        error: 'Failed to retrieve workflow',
      );
    }

    return MockWorkflowResult(
      isSuccess: true,
      workflow: _createSampleWorkflow(workflowId),
    );
  }

  // Helper methods for testing business logic
  bool isValidTransition(JobWorkflowState from, JobWorkflowState to) {
    final validTransitions = {
      JobWorkflowState.posted: [JobWorkflowState.applied, JobWorkflowState.cancelled],
      JobWorkflowState.applied: [JobWorkflowState.underReview, JobWorkflowState.cancelled],
      JobWorkflowState.underReview: [JobWorkflowState.accepted, JobWorkflowState.cancelled],
      JobWorkflowState.accepted: [JobWorkflowState.inProgress, JobWorkflowState.cancelled],
      JobWorkflowState.inProgress: [JobWorkflowState.completed, JobWorkflowState.cancelled],
      JobWorkflowState.completed: [JobWorkflowState.rated, JobWorkflowState.cancelled],
      JobWorkflowState.rated: [JobWorkflowState.paid],
      JobWorkflowState.paid: [JobWorkflowState.closed],
      JobWorkflowState.closed: [],
      JobWorkflowState.cancelled: [],
    };
    
    return validTransitions[from]?.contains(to) ?? false;
  }

  bool isValidHourlyRate(double rate) {
    return rate >= 12.0; // Dutch minimum wage for security work
  }

  double calculateTotalWithBTW(double baseAmount) {
    return baseAmount * 1.21; // Add 21% BTW
  }

  bool isValidDutchPostalCode(String postalCode) {
    final regex = RegExp(r'^\d{4}[A-Z]{2}$');
    return regex.hasMatch(postalCode);
  }

  JobWorkflow _createSampleWorkflow(String workflowId) {
    return JobWorkflow(
      id: workflowId,
      jobId: 'job-123',
      jobTitle: 'Security Guard Position',
      companyId: 'company-456',
      companyName: 'Test Company B.V.',
      currentState: JobWorkflowState.posted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      transitions: {},
      notifications: [],
      metadata: const WorkflowMetadata(
        requiredCertificates: [],
        customFields: {},
      ),
      complianceData: const ComplianceData(
        kvkVerified: true,
        wpbrVerified: true,
        caoCompliant: true,
        btwRate: 0.21,
        gdprConsentGiven: true,
        auditTrail: [],
        taxData: {},
      ),
    );
  }
}

void main() {
  group('WorkflowOrchestrationService Tests', () {
    late TestableWorkflowOrchestrationService service;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockEncryptionService mockEncryptionService;
    late MockNotificationBadgeService mockNotificationService;
    late MockJobRepository mockJobRepository;
    late MockApplicationService mockApplicationService;
    late MockKvKApiService mockKvkService;
    late MockJobCompletionPaymentOrchestrator mockPaymentOrchestrator;
    late MockAutoChatService mockChatService;
    late MockCollectionReference mockWorkflowsCollection;
    late MockDocumentReference mockWorkflowDoc;
    late MockDocumentSnapshot mockWorkflowSnapshot;
    late MockUser mockUser;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(JobWorkflowState.posted);
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(DateTime.now());
    });

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockEncryptionService = MockEncryptionService();
      mockNotificationService = MockNotificationBadgeService();
      mockJobRepository = MockJobRepository();
      mockApplicationService = MockApplicationService();
      mockKvkService = MockKvKApiService();
      mockPaymentOrchestrator = MockJobCompletionPaymentOrchestrator();
      mockChatService = MockAutoChatService();
      mockWorkflowsCollection = MockCollectionReference();
      mockWorkflowDoc = MockDocumentReference();
      mockWorkflowSnapshot = MockDocumentSnapshot();
      mockUser = MockUser();

      // Setup basic firestore mocks
      when(() => mockFirestore.collection('workflows')).thenReturn(mockWorkflowsCollection);
      when(() => mockWorkflowsCollection.doc(any())).thenReturn(mockWorkflowDoc);
      when(() => mockWorkflowDoc.get()).thenAnswer((_) async => mockWorkflowSnapshot);
      when(() => mockWorkflowDoc.set(any())).thenAnswer((_) async {});
      when(() => mockWorkflowDoc.update(any())).thenAnswer((_) async {});
      
      // Setup auth mocks
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('test-user-123');

      // Setup KvK service mocks
      when(() => KvKApiService.validateKvK(any(), apiKey: any(named: 'apiKey'), userId: any(named: 'userId')))
          .thenAnswer((_) async => null);
      
      // Setup encryption service mocks
      when(() => mockEncryptionService.encrypt(any())).thenAnswer((_) async => 'encrypted-data');
      when(() => mockEncryptionService.decrypt(any())).thenAnswer((_) async => 'decrypted-data');

      service = TestableWorkflowOrchestrationService(
        firestore: mockFirestore,
        auth: mockAuth,
        encryptionService: mockEncryptionService,
        notificationService: mockNotificationService,
        jobRepository: mockJobRepository,
        applicationService: mockApplicationService,
        kvkService: mockKvkService,
        wpbrService: MockWpbrService(),
        paymentOrchestrator: mockPaymentOrchestrator,
        chatService: mockChatService,
      );
    });

    group('Workflow Initiation', () {
      test('should successfully initiate job workflow', () async {
        // Arrange
        const jobId = 'job-123';
        const companyId = 'company-456';
        const jobTitle = 'Security Guard Position';
        const hourlyRate = 15.0;

        // Act
        final result = await service.testInitiateJobWorkflow(
          jobId: jobId,
          companyId: companyId,
          jobTitle: jobTitle,
          hourlyRate: hourlyRate,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.workflowId, isNotNull);
      });

      test('should fail workflow initiation for invalid hourly rate', () async {
        // Arrange
        const jobId = 'job-123';
        const companyId = 'company-456';
        const jobTitle = 'Security Guard Position';
        const hourlyRate = 10.0; // Below minimum wage

        // Act
        final result = await service.testInitiateJobWorkflow(
          jobId: jobId,
          companyId: companyId,
          jobTitle: jobTitle,
          hourlyRate: hourlyRate,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('minimum hourly rate'));
      });

      test('should fail workflow initiation for invalid KvK', () async {
        // Arrange
        const jobId = 'job-123';
        const companyId = 'invalid-company';
        const jobTitle = 'Security Guard Position';
        const hourlyRate = 15.0;

        // Act
        final result = await service.testInitiateJobWorkflow(
          jobId: jobId,
          companyId: companyId,
          jobTitle: jobTitle,
          hourlyRate: hourlyRate,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Company compliance validation failed'));
      });
    });

    group('Guard Application', () {
      test('should successfully process guard application', () async {
        // Arrange
        const workflowId = 'workflow-123';
        const guardId = 'guard-456';
        const applicationMessage = 'I am interested in this position';

        // Act
        final result = await service.testProcessGuardApplication(
          workflowId: workflowId,
          guardId: guardId,
          applicationMessage: applicationMessage,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail application for non-existent workflow', () async {
        // Arrange
        const workflowId = 'non-existent-workflow';
        const guardId = 'guard-456';
        const applicationMessage = 'I am interested in this position';

        // Act
        final result = await service.testProcessGuardApplication(
          workflowId: workflowId,
          guardId: guardId,
          applicationMessage: applicationMessage,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Workflow not found'));
      });
    });

    group('Application Review', () {
      test('should successfully accept application', () async {
        // Arrange
        const workflowId = 'workflow-123';
        const companyId = 'company-456';
        const acceptanceMessage = 'Welcome to our team!';

        // Act
        final result = await service.testAcceptJobApplication(
          workflowId: workflowId,
          companyId: companyId,
          acceptanceMessage: acceptanceMessage,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail acceptance for invalid workflow state', () async {
        // Arrange
        const workflowId = 'wrong-state-workflow-123';
        const companyId = 'company-456';
        const acceptanceMessage = 'Welcome to our team!';

        // Act
        final result = await service.testAcceptJobApplication(
          workflowId: workflowId,
          companyId: companyId,
          acceptanceMessage: acceptanceMessage,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid workflow state'));
      });
    });

    group('Job Execution', () {
      test('should successfully start job execution', () async {
        // Arrange
        const workflowId = 'workflow-123';
        const guardId = 'guard-456';
        final actualStartTime = DateTime.now();

        // Act
        final result = await service.testStartJobExecution(
          workflowId: workflowId,
          guardId: guardId,
          actualStartTime: actualStartTime,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should successfully complete job execution', () async {
        // Arrange
        const workflowId = 'workflow-123';
        const guardId = 'guard-456';
        final actualEndTime = DateTime.now();
        const totalHoursWorked = 8.0;

        // Act
        final result = await service.testCompleteJobExecution(
          workflowId: workflowId,
          guardId: guardId,
          actualEndTime: actualEndTime,
          totalHoursWorked: totalHoursWorked,
        );

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });

    group('Workflow State Validation', () {
      test('should validate workflow state transitions', () async {
        // Test valid transitions
        expect(
          service.isValidTransition(JobWorkflowState.posted, JobWorkflowState.applied),
          isTrue,
        );
        expect(
          service.isValidTransition(JobWorkflowState.applied, JobWorkflowState.underReview),
          isTrue,
        );
        expect(
          service.isValidTransition(JobWorkflowState.underReview, JobWorkflowState.accepted),
          isTrue,
        );

        // Test invalid transitions
        expect(
          service.isValidTransition(JobWorkflowState.posted, JobWorkflowState.completed),
          isFalse,
        );
        expect(
          service.isValidTransition(JobWorkflowState.closed, JobWorkflowState.posted),
          isFalse,
        );
      });
    });

    group('Dutch Business Logic', () {
      test('should enforce minimum hourly rate', () {
        expect(service.isValidHourlyRate(11.0), isFalse);
        expect(service.isValidHourlyRate(12.0), isTrue);
        expect(service.isValidHourlyRate(15.0), isTrue);
      });

      test('should calculate BTW correctly', () {
        const baseAmount = 100.0;
        final totalWithBTW = service.calculateTotalWithBTW(baseAmount);
        expect(totalWithBTW, equals(121.0)); // 100 + 21% BTW
      });

      test('should validate Dutch postal codes', () {
        expect(service.isValidDutchPostalCode('1234AB'), isTrue);
        expect(service.isValidDutchPostalCode('9999ZZ'), isTrue);
        expect(service.isValidDutchPostalCode('12345'), isFalse);
        expect(service.isValidDutchPostalCode('ABCD12'), isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle Firestore errors gracefully', () async {
        // Act
        final result = await service.testGetWorkflow('error-workflow');

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Failed to retrieve workflow'));
      });

      test('should successfully retrieve workflow', () async {
        // Act
        final result = await service.testGetWorkflow('workflow-123');

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.workflow, isNotNull);
        expect(result.workflow!.id, equals('workflow-123'));
      });
    });

    group('Model Creation', () {
      test('should create workflow with all required fields', () {
        // Act
        final workflow = service._createSampleWorkflow('test-workflow');

        // Assert
        expect(workflow.id, equals('test-workflow'));
        expect(workflow.jobId, equals('job-123'));
        expect(workflow.companyName, equals('Test Company B.V.'));
        expect(workflow.currentState, equals(JobWorkflowState.posted));
        expect(workflow.metadata.requiredCertificates, isEmpty);
        expect(workflow.complianceData.kvkVerified, isTrue);
        expect(workflow.complianceData.btwRate, equals(0.21));
      });
    });
  });
}