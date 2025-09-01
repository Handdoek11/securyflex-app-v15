import 'package:flutter_test/flutter_test.dart';

import 'package:securyflex_app/workflow/services/job_completion_rating_service.dart';
import 'package:securyflex_app/workflow/models/job_workflow_models.dart';
import 'package:securyflex_app/workflow/localization/job_completion_rating_nl.dart';

void main() {
  group('JobReviewSubmissionResult Tests', () {
    test('should create successful result', () {
      // Arrange & Act
      final result = JobReviewSubmissionResult(
        isSuccess: true,
        reviewId: 'review_123',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.reviewId, equals('review_123'));
      expect(result.errorMessage, isNull);
    });

    test('should create error result', () {
      // Arrange & Act
      final result = JobReviewSubmissionResult(
        isSuccess: false,
        errorMessage: 'Test error message',
      );

      // Assert
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, equals('Test error message'));
      expect(result.reviewId, isNull);
    });
  });

  group('JobReview Model Tests', () {
    test('should create JobReview for job completion', () {
      // Arrange
      const workflowId = 'test_workflow_123';
      const reviewerId = 'test_reviewer_123';
      const reviewerRole = 'guard';
      const rating = 4.5;
      const comment = 'Goede samenwerking!';

      // Act
      final jobReview = JobReview.forJobCompletion(
        workflowId: workflowId,
        reviewerId: reviewerId,
        reviewerRole: reviewerRole,
        rating: rating,
        comment: comment,
      );

      // Assert
      expect(jobReview.workflowId, equals(workflowId));
      expect(jobReview.reviewerId, equals(reviewerId));
      expect(jobReview.reviewerRole, equals(reviewerRole));
      expect(jobReview.rating, equals(rating));
      expect(jobReview.comment, equals(comment));
      expect(jobReview.isJobCompletionRating, isTrue);
      expect(jobReview.metadata['type'], equals('job_completion'));
      expect(jobReview.metadata['source'], equals('mobile_app'));
    });

    test('should get correct Dutch rating description', () {
      // Arrange & Act & Assert
      final excellentReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 4.8
      );
      expect(excellentReview.dutchRatingDescription, equals('Uitstekend'));

      final goodReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 4.2
      );
      expect(goodReview.dutchRatingDescription, equals('Goed'));

      final satisfactoryReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 3.7
      );
      expect(satisfactoryReview.dutchRatingDescription, equals('Voldoende'));

      final poorReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 2.1
      );
      expect(poorReview.dutchRatingDescription, equals('Matig'));

      final badReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 1.5
      );
      expect(badReview.dutchRatingDescription, equals('Onvoldoende'));
    });

    test('should get correct rating color hex', () {
      // Arrange & Act & Assert
      final excellentReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 4.8
      );
      expect(excellentReview.ratingColorHex, equals('#4CAF50')); // Green

      final goodReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 4.2
      );
      expect(goodReview.ratingColorHex, equals('#FF9800')); // Orange

      final satisfactoryReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 3.7
      );
      expect(satisfactoryReview.ratingColorHex, equals('#2196F3')); // Blue

      final poorReview = JobReview.forJobCompletion(
        workflowId: 'test', reviewerId: 'test', reviewerRole: 'guard', rating: 1.5
      );
      expect(poorReview.ratingColorHex, equals('#F44336')); // Red
    });
  });

  group('JobCompletionRatingLocalizationNL Tests', () {
    test('should return correct Dutch rating descriptions', () {
      expect(JobCompletionRatingLocalizationNL.getRatingDescription(5.0), equals('Uitstekend!'));
      expect(JobCompletionRatingLocalizationNL.getRatingDescription(4.5), equals('Goed'));
      expect(JobCompletionRatingLocalizationNL.getRatingDescription(3.5), equals('Voldoende'));
      expect(JobCompletionRatingLocalizationNL.getRatingDescription(2.5), equals('Matig'));
      expect(JobCompletionRatingLocalizationNL.getRatingDescription(1.0), equals('Onvoldoende'));
    });

    test('should format rating correctly', () {
      expect(JobCompletionRatingLocalizationNL.formatRating(4.5), equals('4.5 sterren'));
      expect(JobCompletionRatingLocalizationNL.formatRating(3.0), equals('3.0 sterren'));
      expect(JobCompletionRatingLocalizationNL.formatRating(5.0), equals('5.0 sterren'));
    });

    test('should format rating count correctly', () {
      expect(JobCompletionRatingLocalizationNL.formatRatingCount(0), equals('Geen beoordelingen'));
      expect(JobCompletionRatingLocalizationNL.formatRatingCount(1), equals('1 beoordeling'));
      expect(JobCompletionRatingLocalizationNL.formatRatingCount(5), equals('5 beoordelingen'));
      expect(JobCompletionRatingLocalizationNL.formatRatingCount(100), equals('100 beoordelingen'));
    });

    test('should get correct performance category', () {
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceCategory(4.8, 96.0), 
        equals('Uitstekend')
      );
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceCategory(4.2, 87.0), 
        equals('Goed')
      );
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceCategory(3.7, 78.0), 
        equals('Voldoende')
      );
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceCategory(3.0, 65.0), 
        equals('Kan beter')
      );
    });

    test('should get correct performance advice', () {
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceAdvice(4.8, 96.0),
        equals('Uitstekend werk! Je bent een topbeveiliger.')
      );
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceAdvice(4.2, 87.0),
        equals('Sterke prestaties! Behoud dit niveau.')
      );
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceAdvice(3.7, 78.0),
        equals('Je doet het goed! Probeer je beoordelingen te verbeteren.')
      );
      expect(
        JobCompletionRatingLocalizationNL.getPerformanceAdvice(3.0, 65.0),
        equals('Focus op het verbeteren van je beoordelingen en voltooiingspercentage.')
      );
    });
  });

  group('Integration Tests', () {
    test('should integrate rating with existing workflow states', () {
      // Test that rating transitions workflow from completed to rated
      final workflow = JobWorkflow(
        id: 'workflow_123',
        jobId: 'job_123',
        jobTitle: 'Test Beveiligingsopdracht',
        companyId: 'company_123',
        companyName: 'Test Bedrijf BV',
        selectedGuardId: 'guard_123',
        selectedGuardName: 'Jan de Vries',
        currentState: JobWorkflowState.completed,
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

      // Assert initial state
      expect(workflow.currentState, equals(JobWorkflowState.completed));
      expect(workflow.currentState.displayNameNL, equals('Voltooid'));

      // Simulate rating submitted
      final updatedWorkflow = workflow.copyWith(
        currentState: JobWorkflowState.rated,
        updatedAt: DateTime.now(),
      );

      expect(updatedWorkflow.currentState, equals(JobWorkflowState.rated));
      expect(updatedWorkflow.currentState.displayNameNL, equals('Beoordeeld'));
    });
  });
}