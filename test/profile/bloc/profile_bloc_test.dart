import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:securyflex_app/profile/bloc/profile_bloc.dart';
import 'package:securyflex_app/profile/bloc/profile_event.dart';
import 'package:securyflex_app/profile/bloc/profile_state.dart';
import 'package:securyflex_app/profile/repository/profile_repository.dart';

// Mock classes
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileBloc Tests', () {
    late MockProfileRepository mockRepository;
    late ProfileLoaded mockGuardProfile;
    late ProfileLoaded mockCompanyProfile;

    setUpAll(() {
      // Register fallback values for ProfileLoaded and ProfileData
      registerFallbackValue(ProfileLoaded(
        userId: 'test-user',
        userType: 'guard',
        profileData: ProfileData(
          basicInfo: const BasicInfo(
            name: 'Test User',
            email: 'test@example.com',
            phone: '06-12345678',
            address: 'Test Street 1',
            postalCode: '1234AB',
            city: 'Amsterdam',
          ),
          statistics: ProfileStatistics(activeSince: DateTime.now()),
          verificationStatus: const VerificationStatus(),
          privacySettings: const PrivacySettings(),
        ),
        completenessPercentage: 50.0,
        lastUpdated: DateTime.now(),
      ));
      
      registerFallbackValue(ProfileData(
        basicInfo: const BasicInfo(
          name: 'Test User',
          email: 'test@example.com',
          phone: '06-12345678',
          address: 'Test Street 1',
          postalCode: '1234AB',
          city: 'Amsterdam',
        ),
        statistics: ProfileStatistics(activeSince: DateTime.now()),
        verificationStatus: const VerificationStatus(),
        privacySettings: const PrivacySettings(),
      ));
      
      registerFallbackValue(Certificate(
        id: 'test-cert',
        name: 'Test Certificate',
        issuingOrganization: 'Test Org',
        issueDate: DateTime.now(),
      ));
    });

    setUp(() {
      mockRepository = MockProfileRepository();
      
      // Create mock guard profile
      mockGuardProfile = ProfileLoaded(
        userId: 'guard-123',
        userType: 'guard',
        profileData: ProfileData(
          basicInfo: const BasicInfo(
            name: 'Jan de Beveiliger',
            email: 'jan@securyflex.nl',
            phone: '06-12345678',
            address: 'Hoofdstraat 123',
            postalCode: '1234AB',
            city: 'Amsterdam',
            bio: 'Ervaren beveiliger',
            nationality: 'Nederlandse',
          ),
          professionalInfo: const ProfessionalInfo(
            experienceYears: 5,
            specializations: ['Evenementenbeveiliging', 'Winkelbeveiliging'],
            languages: ['Nederlands', 'Engels'],
            skills: ['Communicatie', 'Observatie'],
            hasDriversLicense: true,
          ),
          certificates: [
            Certificate(
              id: 'cert-1',
              name: 'Beveiligingsdiploma',
              issuingOrganization: 'PBSA',
              issueDate: DateTime(2020, 1, 1),
              expiryDate: DateTime(2025, 1, 1),
            ),
          ],
          availability: const {
            'monday': ['09:00-17:00'],
            'tuesday': ['09:00-17:00'],
          },
          statistics: ProfileStatistics(
            completedJobs: 25,
            averageRating: 4.5,
            totalEarned: 5000.0,
            activeSince: DateTime(2020, 1, 1),
            successPercentage: 95.0,
            repeatClients: 10,
          ),
          verificationStatus: const VerificationStatus(
            identityVerified: true,
            addressVerified: true,
          ),
          privacySettings: const PrivacySettings(),
          status: 'active',
        ),
        completenessPercentage: 85.0,
        lastUpdated: DateTime.now(),
      );
      
      // Create mock company profile
      mockCompanyProfile = ProfileLoaded(
        userId: 'company-456',
        userType: 'company',
        profileData: ProfileData(
          basicInfo: const BasicInfo(
            name: 'SecuryFlex BV',
            email: 'info@securyflex.nl',
            phone: '020-1234567',
            address: 'Bedrijfsweg 1',
            postalCode: '5678CD',
            city: 'Rotterdam',
            bio: 'Professionele beveiligingsdiensten',
          ),
          companyInfo: CompanyInfo(
            companyName: 'SecuryFlex BV',
            kvkNumber: '12345678',
            vatNumber: 'NL123456789B01',
            industry: 'Beveiliging',
            website: 'https://securyflex.nl',
            description: 'Marktleider in beveiligingsdiensten',
            employeeCount: 50,
            foundedDate: DateTime(2015, 1, 1),
          ),
          statistics: ProfileStatistics(
            completedJobs: 100,
            averageRating: 4.8,
            activeSince: DateTime(2015, 1, 1),
          ),
          verificationStatus: const VerificationStatus(
            identityVerified: true,
            addressVerified: true,
          ),
          privacySettings: const PrivacySettings(),
          status: 'active',
        ),
        completenessPercentage: 90.0,
        lastUpdated: DateTime.now(),
      );
      
      // Setup default mock returns
      when(() => mockRepository.loadProfile(any(), any())).thenAnswer((_) async => mockGuardProfile);
      when(() => mockRepository.saveProfile(any())).thenAnswer((_) async {});
      when(() => mockRepository.updateBasicInfo(any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.updateProfessionalInfo(any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.updateCompanyInfo(any(), any())).thenAnswer((_) async => mockCompanyProfile.profileData);
      when(() => mockRepository.addCertificate(any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.removeCertificate(any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.updateCertificate(any(), any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.updateAvailability(any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.updateStatus(any(), any())).thenAnswer((_) async => mockGuardProfile.profileData);
      when(() => mockRepository.uploadProfilePhoto(any())).thenAnswer((_) async => 'https://example.com/photo.jpg');
      when(() => mockRepository.verifyProfile(any(), any())).thenAnswer((_) async => const VerificationStatus(identityVerified: true));
      when(() => mockRepository.exportProfile(any())).thenAnswer((_) async => {'test': 'data'});
      when(() => mockRepository.deleteProfile(any())).thenAnswer((_) async {});
    });

    test('initial state is ProfileInitial', () {
      final profileBloc = ProfileBloc(repository: mockRepository);
      expect(profileBloc.state, equals(const ProfileInitial()));
      profileBloc.close();
    });

    group('ProfileInitialize', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when initialization succeeds for guard',
        build: () => ProfileBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const ProfileInitialize(
          userId: 'guard-123',
          userType: 'guard',
        )),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Profiel laden...'),
          isA<ProfileLoaded>()
              .having((state) => state.userId, 'userId', 'guard-123')
              .having((state) => state.userType, 'userType', 'guard')
              .having((state) => state.profileData.basicInfo.name, 'name', 'Jan de Beveiliger')
              .having((state) => state.completenessPercentage, 'completeness', 85.0),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when initialization succeeds for company',
        build: () {
          when(() => mockRepository.loadProfile('company-456', 'company')).thenAnswer((_) async => mockCompanyProfile);
          return ProfileBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const ProfileInitialize(
          userId: 'company-456',
          userType: 'company',
        )),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Profiel laden...'),
          isA<ProfileLoaded>()
              .having((state) => state.userId, 'userId', 'company-456')
              .having((state) => state.userType, 'userType', 'company')
              .having((state) => state.profileData.basicInfo.name, 'name', 'SecuryFlex BV')
              .having((state) => state.completenessPercentage, 'completeness', 90.0),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileError] when initialization fails',
        build: () {
          when(() => mockRepository.loadProfile(any(), any())).thenThrow(Exception('Load failed'));
          return ProfileBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const ProfileInitialize(
          userId: 'test-user',
          userType: 'guard',
        )),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Profiel laden...'),
          isA<ProfileError>(),
        ],
      );
    });

    group('LoadProfile', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileLoaded] when loading succeeds',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const LoadProfile()),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Profiel laden...'),
          isA<ProfileLoaded>(),
        ],
      );
    });

    group('RefreshProfile', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileLoaded when refresh succeeds',
        build: () {
          // Return a slightly different profile to ensure state change
          final refreshedProfile = mockGuardProfile.copyWith(
            completenessPercentage: 86.0,
            lastUpdated: DateTime.now().add(const Duration(minutes: 1)),
          );
          when(() => mockRepository.loadProfile('guard-123', 'guard')).thenAnswer((_) async => refreshedProfile);
          return ProfileBloc(repository: mockRepository);
        },
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const RefreshProfile()),
        expect: () => [
          isA<ProfileLoaded>()
              .having((state) => state.completenessPercentage, 'completeness', 86.0),
        ],
      );
    });

    group('UpdateBasicInfo', () {
      blocTest<ProfileBloc, ProfileState>(
        'updates basic info and marks as unsaved',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const UpdateBasicInfo(
          name: 'Updated Name',
          email: 'updated@example.com',
          phone: '06-87654321',
        )),
        expect: () => [
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateProfessionalInfo', () {
      blocTest<ProfileBloc, ProfileState>(
        'updates professional info for guard user',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const UpdateProfessionalInfo(
          experienceYears: 10,
          specializations: ['Objectbeveiliging', 'Personenbeveiliging'],
        )),
        expect: () => [
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when trying to update professional info for company user',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockCompanyProfile,
        act: (bloc) => bloc.add(const UpdateProfessionalInfo(
          experienceYears: 10,
        )),
        expect: () => [
          isA<ProfileError>()
              .having((state) => state.error.code, 'error code', 'invalid_user_type'),
        ],
      );
    });

    group('UpdateCompanyInfo', () {
      blocTest<ProfileBloc, ProfileState>(
        'updates company info for company user',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockCompanyProfile,
        act: (bloc) => bloc.add(const UpdateCompanyInfo(
          companyName: 'Updated Company BV',
          kvkNumber: '87654321',
        )),
        expect: () => [
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when trying to update company info for guard user',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const UpdateCompanyInfo(
          companyName: 'Test Company',
        )),
        expect: () => [
          isA<ProfileError>()
              .having((state) => state.error.code, 'error code', 'invalid_user_type'),
        ],
      );
    });

    group('AddCertificate', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdateSuccess, ProfileLoaded] when certificate is added',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(AddCertificate(
          name: 'Nieuwe Certificaat',
          issuingOrganization: 'Test Organisatie',
          issueDate: DateTime(2023, 1, 1),
        )),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<ProfileUpdateSuccess>()
              .having((state) => state.updateType, 'updateType', 'certificate')
              .having((state) => state.successMessage, 'message', contains('Nieuwe Certificaat')),
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('RemoveCertificate', () {
      blocTest<ProfileBloc, ProfileState>(
        'removes certificate and marks as unsaved',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const RemoveCertificate('cert-1')),
        expect: () => [
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateAvailability', () {
      blocTest<ProfileBloc, ProfileState>(
        'updates availability and marks as unsaved',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const UpdateAvailability({
          'monday': ['08:00-16:00'],
          'tuesday': ['08:00-16:00'],
          'wednesday': ['08:00-16:00'],
        })),
        expect: () => [
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateProfileStatus', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileUpdateSuccess, ProfileLoaded] when status is updated',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const UpdateProfileStatus('busy')),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<ProfileUpdateSuccess>()
              .having((state) => state.updateType, 'updateType', 'status')
              .having((state) => state.successMessage, 'message', contains('Bezet')),
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UploadProfilePhoto', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileUpdateSuccess, ProfileLoaded] when photo upload succeeds',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const UploadProfilePhoto('/path/to/photo.jpg')),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Foto uploaden...'),
          isA<ProfileUpdateSuccess>()
              .having((state) => state.updateType, 'updateType', 'photo'),
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('VerifyProfile', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileVerificationInProgress, ProfileVerificationCompleted, ProfileLoaded] when verification succeeds',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const VerifyProfile(
          verificationType: 'identity',
          verificationData: {'document': 'passport'},
        )),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          isA<ProfileVerificationInProgress>()
              .having((state) => state.verificationType, 'verificationType', 'identity'),
          isA<ProfileVerificationCompleted>()
              .having((state) => state.verificationType, 'verificationType', 'identity')
              .having((state) => state.verificationResult, 'verificationResult', true),
          isA<ProfileLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('ExportProfileData', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileDataExported] when export succeeds',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const ExportProfileData()),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Profielgegevens exporteren...'),
          isA<ProfileDataExported>()
              .having((state) => state.exportedData.containsKey('test'), 'has test data', true),
        ],
      );
    });

    group('DeleteProfile', () {
      blocTest<ProfileBloc, ProfileState>(
        'emits [ProfileLoading, ProfileInitial] when deletion succeeds with correct confirmation',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const DeleteProfile('verwijder profiel')),
        expect: () => [
          const ProfileLoading(loadingMessage: 'Profiel verwijderen...'),
          const ProfileInitial(),
        ],
      );

      blocTest<ProfileBloc, ProfileState>(
        'emits ProfileError when confirmation text is incorrect',
        build: () => ProfileBloc(repository: mockRepository),
        seed: () => mockGuardProfile,
        act: (bloc) => bloc.add(const DeleteProfile('wrong text')),
        expect: () => [
          isA<ProfileError>()
              .having((state) => state.error.code, 'error code', 'invalid_confirmation'),
        ],
      );
    });

    group('Convenience Getters', () {
      test('isLoaded returns true when state is ProfileLoaded', () {
        final profileBloc = ProfileBloc(repository: mockRepository);
        profileBloc.emit(mockGuardProfile);
        
        expect(profileBloc.isLoaded, isTrue);
        expect(profileBloc.currentProfile, equals(mockGuardProfile));
        expect(profileBloc.profileData, equals(mockGuardProfile.profileData));
        expect(profileBloc.completenessPercentage, equals(85.0));
        expect(profileBloc.userType, equals('guard'));
        expect(profileBloc.userId, equals('guard-123'));
        
        profileBloc.close();
      });

      test('isLoading returns true when state is ProfileLoading', () {
        final profileBloc = ProfileBloc(repository: mockRepository);
        profileBloc.emit(const ProfileLoading());
        
        expect(profileBloc.isLoading, isTrue);
        profileBloc.close();
      });

      test('hasUnsavedChanges returns correct value', () {
        final profileBloc = ProfileBloc(repository: mockRepository);
        profileBloc.emit(mockGuardProfile.copyWith(hasUnsavedChanges: true));
        
        expect(profileBloc.hasUnsavedChanges, isTrue);
        profileBloc.close();
      });
    });

    group('Dutch Localization', () {
      test('ProfileLoaded provides correct Dutch role display names', () {
        expect(mockGuardProfile.userRoleDisplayName, equals('Beveiliger'));
        expect(mockCompanyProfile.userRoleDisplayName, equals('Bedrijf'));
      });

      test('ProfileLoaded provides correct Dutch completeness status', () {
        final incompleteProfile = mockGuardProfile.copyWith(completenessPercentage: 30.0);
        final partialProfile = mockGuardProfile.copyWith(completenessPercentage: 60.0);
        final almostCompleteProfile = mockGuardProfile.copyWith(completenessPercentage: 80.0);
        final completeProfile = mockGuardProfile.copyWith(completenessPercentage: 95.0);
        
        expect(incompleteProfile.completenessStatus, equals('Profiel incompleet'));
        expect(partialProfile.completenessStatus, equals('Gedeeltelijk ingevuld'));
        expect(almostCompleteProfile.completenessStatus, equals('Bijna compleet'));
        expect(completeProfile.completenessStatus, equals('Profiel compleet'));
      });

      test('ProfileLoaded provides correct Dutch verification status', () {
        final unverifiedProfile = mockGuardProfile.copyWith(
          profileData: mockGuardProfile.profileData.copyWith(
            verificationStatus: const VerificationStatus(),
          ),
        );
        
        final partiallyVerifiedProfile = mockGuardProfile.copyWith(
          profileData: mockGuardProfile.profileData.copyWith(
            verificationStatus: const VerificationStatus(identityVerified: true),
          ),
        );
        
        expect(unverifiedProfile.verificationStatus, equals('Niet geverifieerd'));
        expect(partiallyVerifiedProfile.verificationStatus, equals('Gedeeltelijk geverifieerd'));
        expect(mockGuardProfile.verificationStatus, equals('Geverifieerd'));
      });

      test('ProfileUpdateSuccess provides Dutch success messages', () {
        final basicInfoSuccess = ProfileUpdateSuccess(
          updatedProfile: ProfileLoaded(
            userId: 'test',
            userType: 'guard',
            profileData: ProfileData(
              basicInfo: const BasicInfo(name: '', email: '', phone: '', address: '', postalCode: '', city: ''),
              statistics: ProfileStatistics(activeSince: DateTime.now()),
              verificationStatus: const VerificationStatus(),
              privacySettings: const PrivacySettings(),
            ),
            completenessPercentage: 0,
            lastUpdated: DateTime.now(),
          ),
          updateType: 'basic_info',
        );

        expect(basicInfoSuccess.localizedSuccessMessage, equals('Basisgegevens succesvol bijgewerkt'));

        final certificateSuccess = ProfileUpdateSuccess(
          updatedProfile: ProfileLoaded(
            userId: 'test',
            userType: 'guard',
            profileData: ProfileData(
              basicInfo: const BasicInfo(name: '', email: '', phone: '', address: '', postalCode: '', city: ''),
              statistics: ProfileStatistics(activeSince: DateTime.now()),
              verificationStatus: const VerificationStatus(),
              privacySettings: const PrivacySettings(),
            ),
            completenessPercentage: 0,
            lastUpdated: DateTime.now(),
          ),
          updateType: 'certificate',
        );
        
        expect(certificateSuccess.localizedSuccessMessage, equals('Certificaat succesvol toegevoegd'));
      });
    });
  });
}
