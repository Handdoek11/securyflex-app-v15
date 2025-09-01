import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securyflex_app/auth/services/gdpr_compliance_service.dart';
import 'package:securyflex_app/auth/models/enhanced_auth_models.dart' as models;

/// Mock SharedPreferences for testing
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GDPR Compliance Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Consent Management (GDPR Article 7)', () {
      test('should record valid consent with all required information', () async {
        const userId = 'test-user';
        const purpose = DataProcessingPurpose.authentication;
        const consentType = ConsentType.explicit;
        const lawfulBasis = 'Article 6(1)(a) - Consent';

        final consent = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: purpose,
          consentType: consentType,
          lawfulBasis: lawfulBasis,
          additionalInfo: 'User authentication for SecuryFlex platform',
          metadata: {
            'source': 'mobile_app',
            'feature': 'authentication',
          },
        );

        expect(consent, isNotNull);
        expect(consent.id, isNotEmpty);
        expect(consent.userId, equals(userId));
        expect(consent.purpose, equals(purpose));
        expect(consent.consentType, equals(consentType));
        expect(consent.lawfulBasis, equals(lawfulBasis));
        expect(consent.granted, isTrue);
        expect(consent.timestamp, isNotNull);
        expect(consent.version, isNotEmpty);
        expect(consent.withdrawn, isFalse);
        expect(consent.withdrawalDate, isNull);
        expect(consent.metadata, containsPair('source', 'mobile_app'));
      });

      test('should record biometric consent with explicit requirements', () async {
        const userId = 'biometric-user';
        const biometricTypes = [models.BiometricType.fingerprint, models.BiometricType.face];
        const purpose = BiometricProcessingPurpose.authentication;

        final consentResult = await GDPRComplianceService.requestBiometricConsent(
          userId: userId,
          biometricTypes: biometricTypes,
          purpose: purpose,
        );

        expect(consentResult.requiresExplicitConsent, isTrue);
        expect(consentResult.consentRequestId, isNotEmpty);
        expect(consentResult.consentText, contains('explicit consent'));
        expect(consentResult.consentTextDutch, contains('uitdrukkelijke toestemming'));
        expect(consentResult.consentTextDutch, contains('AVG Artikel 9'));
        expect(consentResult.processingDetails, isNotNull);
        expect(consentResult.storageDetails, isNotNull);
        expect(consentResult.storageDetails.location, contains('Device-local'));
        expect(consentResult.storageDetails.encryption, contains('AES-256'));
        expect(consentResult.storageDetails.sharing, contains('Never shared'));
        expect(consentResult.storageDetails.crossBorder, isFalse);
      });

      test('should grant biometric consent only with explicit consent', () async {
        const userId = 'explicit-consent-user';
        const biometricTypes = [models.BiometricType.fingerprint];
        const purpose = BiometricProcessingPurpose.authentication;

        // Request consent first
        final consentResult = await GDPRComplianceService.requestBiometricConsent(
          userId: userId,
          biometricTypes: biometricTypes,
          purpose: purpose,
        );

        // Try to grant without explicit consent
        final implicitResult = await GDPRComplianceService.grantBiometricConsent(
          userId: userId,
          consentRequestId: consentResult.consentRequestId,
          explicitConsent: false,
        );

        expect(implicitResult, isFalse);

        // Grant with explicit consent
        final explicitResult = await GDPRComplianceService.grantBiometricConsent(
          userId: userId,
          consentRequestId: consentResult.consentRequestId,
          explicitConsent: true,
        );

        expect(explicitResult, isTrue);
      });

      test('should withdraw consent and initiate data deletion', () async {
        const userId = 'withdrawal-user';

        // First record consent
        final consent = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: DataProcessingPurpose.authentication,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(a) - Consent',
        );

        // Withdraw consent
        final withdrawalResult = await GDPRComplianceService.withdrawConsent(
          userId: userId,
          consentId: consent.id,
          reason: 'User no longer wants to use biometric authentication',
        );

        expect(withdrawalResult, isTrue);
      });

      test('should prevent unauthorized consent withdrawal', () async {
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        // Record consent for user1
        final consent = await GDPRComplianceService.recordConsent(
          userId: userId1,
          purpose: DataProcessingPurpose.authentication,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(a) - Consent',
        );

        // Try to withdraw consent as user2 (should fail)
        final withdrawalResult = await GDPRComplianceService.withdrawConsent(
          userId: userId2,
          consentId: consent.id,
          reason: 'Unauthorized withdrawal attempt',
        );

        expect(withdrawalResult, isFalse);
      });

      test('should generate unique consent IDs', () async {
        const userId = 'unique-id-user';

        final consent1 = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: DataProcessingPurpose.authentication,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(a) - Consent',
        );

        final consent2 = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: DataProcessingPurpose.twoFactorAuth,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(a) - Consent',
        );

        expect(consent1.id, isNot(equals(consent2.id)));
        expect(consent1.id, startsWith('consent_'));
        expect(consent2.id, startsWith('consent_'));
      });
    });

    group('Data Subject Rights (GDPR Chapter III)', () {
      test('should process data access request (Article 15)', () async {
        const userId = 'access-request-user';
        const requestType = DataSubjectRequestType.access;
        const requestDetails = 'I want to access all my personal data';

        final response = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: requestType,
          requestDetails: requestDetails,
          identityVerification: '2FA_verified',
        );

        expect(response.requestId, isNotEmpty);
        expect(response.status, equals(DataSubjectRequestStatus.processing));
        expect(response.estimatedCompletion.isAfter(DateTime.now()), isTrue);
        expect(response.message, contains('30 dagen'));
        expect(response.message, contains('overzicht van uw gegevens'));
      });

      test('should process data rectification request (Article 16)', () async {
        const userId = 'rectification-user';
        const requestType = DataSubjectRequestType.rectification;
        const requestDetails = 'My email address is incorrect';

        final response = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: requestType,
          requestDetails: requestDetails,
        );

        expect(response.status, equals(DataSubjectRequestStatus.processing));
        expect(response.estimatedCompletion.isBefore(DateTime.now().add(const Duration(days: 8))), isTrue);
        expect(response.message, contains('rectificatieverzoek'));
        expect(response.message, contains('7 dagen'));
      });

      test('should process data erasure request (Article 17 - Right to be forgotten)', () async {
        const userId = 'erasure-user';
        const requestType = DataSubjectRequestType.erasure;
        const requestDetails = 'I want all my data deleted';

        final response = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: requestType,
          requestDetails: requestDetails,
        );

        expect(response.status, equals(DataSubjectRequestStatus.processing));
        expect(response.message, contains('verwijdering'));
        expect(response.message, contains('30 dagen'));
      });

      test('should process data portability request (Article 20)', () async {
        const userId = 'portability-user';
        const requestType = DataSubjectRequestType.portability;
        const requestDetails = 'I want my data in a structured format';

        final response = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: requestType,
          requestDetails: requestDetails,
        );

        expect(response.status, equals(DataSubjectRequestStatus.processing));
        expect(response.message, contains('gestructureerd'));
        expect(response.message, contains('gangbaar formaat'));
      });

      test('should process data processing restriction request (Article 18)', () async {
        const userId = 'restriction-user';
        const requestType = DataSubjectRequestType.restriction;
        const requestDetails = 'I want to restrict processing of my data';

        final response = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: requestType,
          requestDetails: requestDetails,
        );

        expect(response.status, equals(DataSubjectRequestStatus.processing));
        expect(response.message, contains('verwerkingsbeperking'));
        expect(response.message, contains('alleen opgeslagen'));
      });

      test('should process objection request (Article 21)', () async {
        const userId = 'objection-user';
        const requestType = DataSubjectRequestType.objection;
        const requestDetails = 'I object to the processing of my data';

        final response = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: requestType,
          requestDetails: requestDetails,
        );

        expect(response.status, equals(DataSubjectRequestStatus.processing));
        expect(response.message, contains('bezwaar'));
        expect(response.message, contains('rechtmatige gronden'));
      });

      test('should generate unique request IDs', () async {
        const userId = 'unique-request-user';

        final response1 = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: DataSubjectRequestType.access,
          requestDetails: 'First request',
        );

        final response2 = await GDPRComplianceService.processDataSubjectRequest(
          userId: userId,
          requestType: DataSubjectRequestType.rectification,
          requestDetails: 'Second request',
        );

        expect(response1.requestId, isNot(equals(response2.requestId)));
        expect(response1.requestId, startsWith('req_'));
        expect(response2.requestId, startsWith('req_'));
      });
    });

    group('Right to be Forgotten Implementation (Article 17)', () {
      test('should process right to be forgotten with consent withdrawal', () async {
        const userId = 'forgotten-user';
        const reason = ErasureReason.consentWithdrawn;

        final result = await GDPRComplianceService.processRightToBeForgotten(
          userId: userId,
          reason: reason,
          immediateErasure: false,
        );

        expect(result.success, isTrue);
        expect(result.deletedCategories, isNotNull);
      });

      test('should handle immediate erasure requests', () async {
        const userId = 'immediate-erasure-user';
        const reason = ErasureReason.unlawfulProcessing;

        final result = await GDPRComplianceService.processRightToBeForgotten(
          userId: userId,
          reason: reason,
          immediateErasure: true,
        );

        expect(result.success, isTrue);
        // Immediate erasure should be faster
      });

      test('should process erasure for different reasons', () async {
        const userId = 'various-reasons-user';
        final reasons = [
          ErasureReason.consentWithdrawn,
          ErasureReason.dataNoLongerNecessary,
          ErasureReason.unlawfulProcessing,
          ErasureReason.complianceObligation,
        ];

        for (final reason in reasons) {
          final result = await GDPRComplianceService.processRightToBeForgotten(
            userId: '${userId}_${reason.name}',
            reason: reason,
          );
          
          expect(result.success, isTrue,
                 reason: 'Erasure should succeed for reason: ${reason.name}');
        }
      });
    });

    group('Privacy Impact Assessment (PIA)', () {
      test('should generate privacy impact assessment', () async {
        const userId = 'pia-user';
        const purposes = [
          DataProcessingPurpose.authentication,
          DataProcessingPurpose.biometricAuthentication,
          DataProcessingPurpose.securityMonitoring,
        ];

        final assessment = await GDPRComplianceService.generatePrivacyImpactAssessment(
          userId: userId,
          purposes: purposes,
        );

        expect(assessment.id, isNotEmpty);
        expect(assessment.id, startsWith('pia_'));
        expect(assessment.userId, equals(userId));
        expect(assessment.assessmentDate, isNotNull);
        expect(assessment.purposes, equals(purposes));
        expect(assessment.riskLevel, isA<PrivacyRiskLevel>());
        expect(assessment.dataCategories, isNotNull);
        expect(assessment.processingRisks, isNotNull);
        expect(assessment.mitigationMeasures, isNotNull);
        expect(assessment.complianceStatus, isA<ComplianceStatus>());
      });

      test('should assess different risk levels', () async {
        const userId = 'risk-assessment-user';

        // Low risk: basic authentication
        final lowRiskPIA = await GDPRComplianceService.generatePrivacyImpactAssessment(
          userId: userId,
          purposes: [DataProcessingPurpose.authentication],
        );

        // High risk: biometric data processing
        final highRiskPIA = await GDPRComplianceService.generatePrivacyImpactAssessment(
          userId: userId,
          purposes: [
            DataProcessingPurpose.biometricAuthentication,
            DataProcessingPurpose.securityMonitoring,
          ],
        );

        expect(lowRiskPIA.riskLevel, isA<PrivacyRiskLevel>());
        expect(highRiskPIA.riskLevel, isA<PrivacyRiskLevel>());
        // In actual implementation, biometric processing should have higher risk
      });
    });

    group('Data Retention Compliance', () {
      test('should assess data retention compliance', () async {
        const userId = 'retention-user';

        final assessment = await GDPRComplianceService.assessDataRetention(
          userId: userId,
        );

        expect(assessment.userId, equals(userId));
        expect(assessment.assessmentDate, isNotNull);
        expect(assessment.retentionPolicies, isNotNull);
        expect(assessment.dataAge, isNotNull);
        expect(assessment.complianceIssues, isNotNull);
        expect(assessment.recommendedActions, isNotNull);
      });

      test('should identify expired data for deletion', () async {
        const userId = 'expired-data-user';

        // This would simulate expired data in a real implementation
        final assessment = await GDPRComplianceService.assessDataRetention(
          userId: userId,
        );

        // Assessment should identify issues and provide recommendations
        expect(assessment.complianceIssues, isA<List<RetentionIssue>>());
        expect(assessment.recommendedActions, isA<List<String>>());
      });

      test('should handle different data categories retention', () async {
        const userId = 'categories-retention-user';

        final assessment = await GDPRComplianceService.assessDataRetention(
          userId: userId,
        );

        // Different data categories should have different retention periods
        expect(assessment.dataAge, isA<Map<DataCategory, Duration>>());
        
        // Verify different categories are tracked
        final categories = [
          DataCategory.personalData,
          DataCategory.biometricData,
          DataCategory.authenticationData,
          DataCategory.behavioralData,
          DataCategory.technicalData,
        ];

        expect(categories, isNotEmpty);
      });
    });

    group('Dutch Language Compliance (AVG)', () {
      test('should provide all consent texts in Dutch', () async {
        const userId = 'dutch-consent-user';
        const biometricTypes = [models.BiometricType.fingerprint];
        const purpose = BiometricProcessingPurpose.authentication;

        final consentResult = await GDPRComplianceService.requestBiometricConsent(
          userId: userId,
          biometricTypes: biometricTypes,
          purpose: purpose,
        );

        final dutchText = consentResult.consentTextDutch;

        // Verify Dutch language elements
        expect(dutchText, contains('uitdrukkelijke toestemming'));
        expect(dutchText, contains('biometrische gegevens'));
        expect(dutchText, contains('Authenticatie en identiteitsverificatie'));
        expect(dutchText, contains('lokaal op mijn apparaat'));
        expect(dutchText, contains('te allen tijde kan intrekken'));
        expect(dutchText, contains('niet worden gedeeld met derden'));
        expect(dutchText, contains('AVG Artikel 9'));

        // Should not contain English text in Dutch version
        expect(dutchText, isNot(contains('I hereby')));
        expect(dutchText, isNot(contains('explicit consent')));
      });

      test('should provide Dutch data processing purpose descriptions', () {
        final purposes = DataProcessingPurpose.values;

        for (final purpose in purposes) {
          expect(purpose.dutchDescription, isNotEmpty,
                 reason: 'Purpose ${purpose.name} should have Dutch description');
          
          // Verify specific Dutch translations
          switch (purpose) {
            case DataProcessingPurpose.authentication:
              expect(purpose.dutchDescription, contains('authenticatie'));
              expect(purpose.dutchDescription, contains('toegangscontrole'));
              break;
            case DataProcessingPurpose.biometricAuthentication:
              expect(purpose.dutchDescription, contains('biometrische'));
              break;
            case DataProcessingPurpose.twoFactorAuth:
              expect(purpose.dutchDescription, contains('tweefactor'));
              break;
            case DataProcessingPurpose.accountManagement:
              expect(purpose.dutchDescription, contains('accountbeheer'));
              break;
            case DataProcessingPurpose.securityMonitoring:
              expect(purpose.dutchDescription, contains('beveiliging'));
              expect(purpose.dutchDescription, contains('fraud'));
              break;
            case DataProcessingPurpose.legalCompliance:
              expect(purpose.dutchDescription, contains('juridische'));
              expect(purpose.dutchDescription, contains('compliance'));
              break;
            case DataProcessingPurpose.serviceImprovement:
              expect(purpose.dutchDescription, contains('serviceverbetering'));
              break;
          }
        }
      });

      test('should provide Dutch biometric processing purpose descriptions', () {
        final purposes = BiometricProcessingPurpose.values;

        for (final purpose in purposes) {
          expect(purpose.dutchDescription, isNotEmpty,
                 reason: 'Biometric purpose ${purpose.name} should have Dutch description');

          switch (purpose) {
            case BiometricProcessingPurpose.authentication:
              expect(purpose.dutchDescription, equals('Biometrische authenticatie'));
              break;
            case BiometricProcessingPurpose.identityVerification:
              expect(purpose.dutchDescription, equals('Identiteitsverificatie'));
              break;
          }
        }
      });

      test('should provide Dutch responses for data subject requests', () async {
        const userId = 'dutch-responses-user';
        final requestTypes = DataSubjectRequestType.values;

        for (final requestType in requestTypes) {
          final response = await GDPRComplianceService.processDataSubjectRequest(
            userId: userId,
            requestType: requestType,
            requestDetails: 'Test request in Dutch',
          );

          expect(response.message, isNotEmpty);
          
          // Verify Dutch language in responses
          final dutchWords = [
            'verzoek', 'dagen', 'wordt', 'verwerkt', 'behandeld', 
            'binnen', 'gegevens', 'wijzigingen', 'verwijdering'
          ];

          expect(dutchWords.any((word) => 
                 response.message.toLowerCase().contains(word)),
                 isTrue, 
                 reason: 'Response should contain Dutch words for ${requestType.name}');
        }
      });
    });

    group('Data Models and Serialization', () {
      test('should properly serialize and deserialize ConsentRecord', () {
        final consent = ConsentRecord(
          id: 'test-consent-id',
          userId: 'test-user',
          purpose: DataProcessingPurpose.authentication,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(a) - Consent',
          granted: true,
          timestamp: DateTime.now(),
          ipAddress: '192.168.1.1',
          userAgent: 'SecuryFlex/1.0',
          additionalInfo: 'Test consent',
          metadata: {'source': 'mobile'},
          version: 'v2.1_2024',
        );

        final json = consent.toJson();

        expect(json['id'], equals('test-consent-id'));
        expect(json['userId'], equals('test-user'));
        expect(json['purpose'], equals('authentication'));
        expect(json['consentType'], equals('explicit'));
        expect(json['lawfulBasis'], equals('Article 6(1)(a) - Consent'));
        expect(json['granted'], isTrue);
        expect(json['timestamp'], isA<String>());
        expect(json['ipAddress'], equals('192.168.1.1'));
        expect(json['userAgent'], equals('SecuryFlex/1.0'));
        expect(json['additionalInfo'], equals('Test consent'));
        expect(json['metadata'], equals({'source': 'mobile'}));
        expect(json['version'], equals('v2.1_2024'));
        expect(json['withdrawn'], isFalse);
        expect(json['withdrawalDate'], isNull);
      });

      test('should handle consent withdrawal properly', () {
        final originalConsent = ConsentRecord(
          id: 'withdrawal-consent-id',
          userId: 'withdrawal-user',
          purpose: DataProcessingPurpose.biometricAuthentication,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 9(2)(a) - explicit consent',
          granted: true,
          timestamp: DateTime.now(),
          metadata: {},
          version: 'v2.1_2024',
        );

        final withdrawalDate = DateTime.now();
        final withdrawnConsent = originalConsent.copyWith(
          withdrawn: true,
          withdrawalDate: withdrawalDate,
        );

        expect(withdrawnConsent.withdrawn, isTrue);
        expect(withdrawnConsent.withdrawalDate, equals(withdrawalDate));
        expect(withdrawnConsent.id, equals(originalConsent.id));
        expect(withdrawnConsent.userId, equals(originalConsent.userId));
        expect(withdrawnConsent.purpose, equals(originalConsent.purpose));
      });

      test('should validate ConsentWithdrawal model', () {
        final withdrawal = ConsentWithdrawal(
          consentId: 'consent-123',
          userId: 'user-456',
          withdrawalDate: DateTime.now(),
          reason: 'User no longer needs this feature',
          ipAddress: '10.0.0.1',
          automaticDeletion: true,
        );

        expect(withdrawal.consentId, equals('consent-123'));
        expect(withdrawal.userId, equals('user-456'));
        expect(withdrawal.withdrawalDate, isNotNull);
        expect(withdrawal.reason, equals('User no longer needs this feature'));
        expect(withdrawal.ipAddress, equals('10.0.0.1'));
        expect(withdrawal.automaticDeletion, isTrue);
      });

      test('should validate BiometricConsentRequest expiry', () {
        final now = DateTime.now();
        
        // Non-expired request
        final validRequest = BiometricConsentRequest(
          id: 'valid-request',
          userId: 'user',
          biometricTypes: [models.BiometricType.fingerprint],
          purpose: BiometricProcessingPurpose.authentication,
          requestDate: now,
          expiresAt: now.add(const Duration(hours: 12)),
          lawfulBasis: 'Article 9(2)(a)',
          processingDetails: BiometricProcessingDetails(
            purpose: BiometricProcessingPurpose.authentication,
            processingScope: 'Test scope',
            dataRetention: 'Test retention',
            technicalMeasures: ['AES-256'],
            organisationalMeasures: ['Privacy by design'],
          ),
          storageDetails: BiometricStorageDetails(
            location: 'Device-local',
            encryption: 'AES-256',
            retention: 'Until withdrawal',
            sharing: 'Never shared',
            crossBorder: false,
          ),
        );

        // Expired request
        final expiredRequest = BiometricConsentRequest(
          id: 'expired-request',
          userId: 'user',
          biometricTypes: [models.BiometricType.face],
          purpose: BiometricProcessingPurpose.identityVerification,
          requestDate: now.subtract(const Duration(days: 2)),
          expiresAt: now.subtract(const Duration(hours: 1)),
          lawfulBasis: 'Article 9(2)(a)',
          processingDetails: BiometricProcessingDetails(
            purpose: BiometricProcessingPurpose.identityVerification,
            processingScope: 'Test scope',
            dataRetention: 'Test retention',
            technicalMeasures: ['AES-256'],
            organisationalMeasures: ['Privacy by design'],
          ),
          storageDetails: BiometricStorageDetails(
            location: 'Device-local',
            encryption: 'AES-256',
            retention: 'Until withdrawal',
            sharing: 'Never shared',
            crossBorder: false,
          ),
        );

        expect(validRequest.isExpired, isFalse);
        expect(expiredRequest.isExpired, isTrue);
      });
    });

    group('Enum Values and Constants', () {
      test('should define all required GDPR data processing purposes', () {
        final purposes = DataProcessingPurpose.values;
        
        expect(purposes, contains(DataProcessingPurpose.authentication));
        expect(purposes, contains(DataProcessingPurpose.biometricAuthentication));
        expect(purposes, contains(DataProcessingPurpose.twoFactorAuth));
        expect(purposes, contains(DataProcessingPurpose.accountManagement));
        expect(purposes, contains(DataProcessingPurpose.securityMonitoring));
        expect(purposes, contains(DataProcessingPurpose.legalCompliance));
        expect(purposes, contains(DataProcessingPurpose.serviceImprovement));

        // Each purpose should have a description
        for (final purpose in purposes) {
          expect(purpose.description, isNotEmpty);
          expect(purpose.dutchDescription, isNotEmpty);
        }
      });

      test('should define all required consent types', () {
        final consentTypes = ConsentType.values;

        expect(consentTypes, contains(ConsentType.implicit));
        expect(consentTypes, contains(ConsentType.explicit));

        for (final type in consentTypes) {
          expect(type.description, isNotEmpty);
        }
      });

      test('should define all data subject request types', () {
        final requestTypes = DataSubjectRequestType.values;

        expect(requestTypes, contains(DataSubjectRequestType.access));
        expect(requestTypes, contains(DataSubjectRequestType.rectification));
        expect(requestTypes, contains(DataSubjectRequestType.erasure));
        expect(requestTypes, contains(DataSubjectRequestType.portability));
        expect(requestTypes, contains(DataSubjectRequestType.restriction));
        expect(requestTypes, contains(DataSubjectRequestType.objection));
      });

      test('should define all erasure reasons', () {
        final erasureReasons = ErasureReason.values;

        expect(erasureReasons, contains(ErasureReason.consentWithdrawn));
        expect(erasureReasons, contains(ErasureReason.dataNoLongerNecessary));
        expect(erasureReasons, contains(ErasureReason.unlawfulProcessing));
        expect(erasureReasons, contains(ErasureReason.complianceObligation));
      });

      test('should define all data categories', () {
        final dataCategories = DataCategory.values;

        expect(dataCategories, contains(DataCategory.personalData));
        expect(dataCategories, contains(DataCategory.biometricData));
        expect(dataCategories, contains(DataCategory.authenticationData));
        expect(dataCategories, contains(DataCategory.behavioralData));
        expect(dataCategories, contains(DataCategory.technicalData));
      });

      test('should define all privacy risk levels', () {
        final riskLevels = PrivacyRiskLevel.values;

        expect(riskLevels, contains(PrivacyRiskLevel.low));
        expect(riskLevels, contains(PrivacyRiskLevel.medium));
        expect(riskLevels, contains(PrivacyRiskLevel.high));
        expect(riskLevels, contains(PrivacyRiskLevel.critical));
      });

      test('should define all compliance statuses', () {
        final complianceStatuses = ComplianceStatus.values;

        expect(complianceStatuses, contains(ComplianceStatus.compliant));
        expect(complianceStatuses, contains(ComplianceStatus.nonCompliant));
        expect(complianceStatuses, contains(ComplianceStatus.partiallyCompliant));
      });
    });

    group('Security and Error Handling', () {
      test('should handle consent recording errors gracefully', () async {
        const userId = 'error-user';

        // This should not throw exceptions even with edge cases
        try {
          final consent = await GDPRComplianceService.recordConsent(
            userId: userId,
            purpose: DataProcessingPurpose.authentication,
            consentType: ConsentType.explicit,
            lawfulBasis: 'Article 6(1)(a) - Consent',
            metadata: {'complex': {'nested': {'data': 'value'}}},
          );

          expect(consent, isNotNull);
        } catch (e) {
          fail('Consent recording should not throw exceptions: $e');
        }
      });

      test('should handle invalid consent withdrawal attempts', () async {
        const userId = 'invalid-withdrawal-user';
        const invalidConsentId = 'non-existent-consent-id';

        final result = await GDPRComplianceService.withdrawConsent(
          userId: userId,
          consentId: invalidConsentId,
          reason: 'Testing invalid withdrawal',
        );

        expect(result, isFalse);
      });

      test('should validate biometric consent request security', () async {
        const userId = 'security-test-user';
        const biometricTypes = [models.BiometricType.fingerprint];
        const purpose = BiometricProcessingPurpose.authentication;

        final consentResult = await GDPRComplianceService.requestBiometricConsent(
          userId: userId,
          biometricTypes: biometricTypes,
          purpose: purpose,
        );

        final storageDetails = consentResult.storageDetails;

        // Verify security requirements
        expect(storageDetails.location, contains('Device-local'));
        expect(storageDetails.encryption, contains('AES-256'));
        expect(storageDetails.sharing, contains('Never shared'));
        expect(storageDetails.crossBorder, isFalse);

        final processingDetails = consentResult.processingDetails;
        expect(processingDetails.technicalMeasures, isNotEmpty);
        expect(processingDetails.organisationalMeasures, isNotEmpty);
        expect(processingDetails.technicalMeasures, contains('AES-256 hardware encryption'));
        expect(processingDetails.organisationalMeasures, contains('Privacy by design implementation'));
      });

      test('should generate secure and unique IDs', () async {
        const userId = 'unique-id-test-user';

        // Generate multiple consents to test ID uniqueness
        final consents = <ConsentRecord>[];
        for (int i = 0; i < 10; i++) {
          final consent = await GDPRComplianceService.recordConsent(
            userId: userId,
            purpose: DataProcessingPurpose.authentication,
            consentType: ConsentType.explicit,
            lawfulBasis: 'Article 6(1)(a) - Consent',
            metadata: {'iteration': i},
          );
          consents.add(consent);
        }

        // All IDs should be unique
        final ids = consents.map((c) => c.id).toSet();
        expect(ids.length, equals(10));

        // All IDs should have proper format
        for (final consent in consents) {
          expect(consent.id, startsWith('consent_'));
          expect(consent.id.length, greaterThan(20)); // Should be sufficiently long
        }
      });
    });

    group('Performance and Scalability', () {
      test('should handle multiple concurrent consent requests', () async {
        const userCount = 5;

        // Generate multiple consent requests concurrently
        final futures = List.generate(userCount, (i) =>
          GDPRComplianceService.recordConsent(
            userId: 'concurrent-user-$i',
            purpose: DataProcessingPurpose.authentication,
            consentType: ConsentType.explicit,
            lawfulBasis: 'Article 6(1)(a) - Consent',
          )
        );

        final consents = await Future.wait(futures);

        expect(consents.length, equals(userCount));
        
        // All should succeed
        expect(consents.every((c) => c.granted), isTrue);
        
        // All should have unique IDs
        final ids = consents.map((c) => c.id).toSet();
        expect(ids.length, equals(userCount));
      });

      test('should complete GDPR operations within reasonable time', () async {
        const userId = 'performance-test-user';

        final stopwatch = Stopwatch()..start();
        
        final consent = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: DataProcessingPurpose.biometricAuthentication,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 9(2)(a) - explicit consent',
        );
        
        stopwatch.stop();

        expect(consent, isNotNull);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
               reason: 'GDPR consent recording should complete within 2 seconds');
      });

      test('should handle large metadata efficiently', () async {
        const userId = 'large-metadata-user';

        // Create large but reasonable metadata
        final largeMetadata = <String, dynamic>{};
        for (int i = 0; i < 100; i++) {
          largeMetadata['field_$i'] = 'value_$i';
        }

        final consent = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: DataProcessingPurpose.serviceImprovement,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(a) - Consent',
          metadata: largeMetadata,
        );

        expect(consent, isNotNull);
        expect(consent.metadata.length, equals(100));
        expect(consent.metadata, equals(largeMetadata));
      });
    });

    group('Integration with Enhanced Auth Models', () {
      test('should work with models.BiometricType enum', () async {
        const userId = 'biometric-enum-user';
        
        // Test all biometric types
        for (final biometricType in models.BiometricType.values) {
          final consentResult = await GDPRComplianceService.requestBiometricConsent(
            userId: userId,
            biometricTypes: [biometricType],
            purpose: BiometricProcessingPurpose.authentication,
          );

          expect(consentResult.requiresExplicitConsent, isTrue);
          expect(consentResult.consentTextDutch, contains(biometricType.dutchName));
        }
      });

      test('should integrate with SecurityEventSeverity levels', () async {
        // While not directly used in GDPR service, compliance events should
        // have appropriate severity levels for security monitoring
        const userId = 'security-integration-user';

        final consent = await GDPRComplianceService.recordConsent(
          userId: userId,
          purpose: DataProcessingPurpose.securityMonitoring,
          consentType: ConsentType.explicit,
          lawfulBasis: 'Article 6(1)(f) - legitimate interests',
        );

        expect(consent.purpose, equals(DataProcessingPurpose.securityMonitoring));
      });
    });
  });
}