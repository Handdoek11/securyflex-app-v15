import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:securyflex_app/reputation/services/reputation_calculation_service.dart';
import 'package:securyflex_app/reputation/models/reputation_data.dart';
import 'package:securyflex_app/workflow/services/job_completion_rating_service.dart';
import 'package:securyflex_app/shared/services/encryption_service.dart';

import 'reputation_calculation_service_test.mocks.dart';

@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  JobCompletionRatingService,
  EncryptionService,
])
void main() {
  group('ReputationCalculationService Tests', () {
    late ReputationCalculationService service;

    setUp(() {
      service = ReputationCalculationService();
    });

    group('ReputationCalculationService Basic Tests', () {
      test('should create service instance', () {
        expect(service, isNotNull);
        expect(service, isA<ReputationCalculationService>());
      });
      
      test('should have calculateReputation method', () {
        expect(service.calculateReputation, isA<Function>());
      });
      
      test('should have instance property', () {
        expect(ReputationCalculationService.instance, isA<ReputationCalculationService>());
      });
    });

    group('ReputationData Model Tests', () {
      test('should create initial reputation data', () {
        final reputation = ReputationData.initial(
          userId: 'test-123',
          userRole: 'guard',
        );
        
        expect(reputation.userId, equals('test-123'));
        expect(reputation.userRole, equals('guard'));
        expect(reputation.overallScore, equals(50.0));
        expect(reputation.totalJobsCompleted, equals(0));
      });

      test('should calculate reputation level based on score', () {
        final highReputation = ReputationData.initial(
          userId: 'test-123',
          userRole: 'guard',
        ).copyWith(overallScore: 85.0);
        
        final lowReputation = ReputationData.initial(
          userId: 'test-456', 
          userRole: 'guard',
        ).copyWith(overallScore: 45.0);
        
        expect(highReputation.reputationLevel.dutchTitle, contains('Uitstekend'));
        expect(lowReputation.reputationLevel.dutchTitle, contains('gemiddeld'));
      });
    });
  });
}