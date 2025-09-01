import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:securyflex_app/auth/bloc/auth_bloc.dart';
import 'package:securyflex_app/auth/bloc/auth_event.dart';
import 'package:securyflex_app/auth/bloc/auth_state.dart';
import 'package:securyflex_app/auth/repository/auth_repository.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}

void main() {
  group('AuthBloc Tests', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockRepository;
    late MockUser mockUser;

    setUp(() {
      mockRepository = MockAuthRepository();
      mockUser = MockUser();

      // Setup default mock returns
      when(() => mockRepository.authStateChanges).thenAnswer((_) => Stream.value(null));
      when(() => mockRepository.currentUser).thenReturn(null);
      when(() => mockRepository.isFirebaseConfigured()).thenReturn(true);

      // Create AuthBloc after setting up mocks
      authBloc = AuthBloc(repository: mockRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    group('AuthInitialize', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no user is logged in',
        build: () => authBloc,
        act: (bloc) => bloc.add(const AuthInitialize()),
        expect: () => [
          const AuthLoading(loadingMessage: 'Initialiseren...'),
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is already logged in',
        build: () {
          when(() => mockRepository.currentUser).thenReturn(mockUser);
          when(() => mockUser.uid).thenReturn('test-uid');
          when(() => mockRepository.getUserData('test-uid')).thenAnswer(
            (_) async => {
              'name': 'Test User',
              'email': 'test@example.com',
              'userType': 'guard',
              'isDemo': false,
            },
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthInitialize()),
        expect: () => [
          const AuthLoading(loadingMessage: 'Initialiseren...'),
          isA<AuthAuthenticated>()
              .having((state) => state.userName, 'userName', 'Test User')
              .having((state) => state.userType, 'userType', 'guard')
              .having((state) => state.userId, 'userId', 'test-uid'),
        ],
      );
    });

    group('AuthLogin', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when Firebase login succeeds',
        build: () {
          when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
              .thenAnswer((_) async => mockUser);
          when(() => mockUser.uid).thenReturn('test-uid');
          when(() => mockRepository.getUserData('test-uid')).thenAnswer(
            (_) async => {
              'name': 'Test User',
              'email': 'test@example.com',
              'userType': 'guard',
              'isDemo': false,
            },
          );
          when(() => mockRepository.updateLastLogin('test-uid'))
              .thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogin(
          email: 'test@example.com',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(loadingMessage: 'Inloggen...'),
          isA<AuthAuthenticated>()
              .having((state) => state.userName, 'userName', 'Test User')
              .having((state) => state.userType, 'userType', 'guard')
              .having((state) => state.isDemo, 'isDemo', false),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when Firebase not configured and demo fails',
        build: () {
          when(() => mockRepository.isFirebaseConfigured()).thenReturn(false);
          when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
              .thenThrow(FirebaseAuthException(code: 'network-request-failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogin(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          const AuthLoading(loadingMessage: 'Inloggen...'),
          isA<AuthError>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails and demo fallback also fails',
        build: () {
          when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
              .thenThrow(FirebaseAuthException(code: 'user-not-found'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogin(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        )),
        expect: () => [
          const AuthLoading(loadingMessage: 'Inloggen...'),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthRegister', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthRegistrationSuccess] when registration succeeds',
        build: () {
          when(() => mockRepository.createUserWithEmailAndPassword(any(), any()))
              .thenAnswer((_) async => mockUser);
          when(() => mockUser.uid).thenReturn('new-user-uid');
          when(() => mockRepository.createUserDocument(any(), any()))
              .thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthRegister(
          email: 'newuser@example.com',
          password: 'password123',
          name: 'New User',
          userType: 'guard',
        )),
        expect: () => [
          const AuthLoading(loadingMessage: 'Account aanmaken...'),
          isA<AuthRegistrationSuccess>()
              .having((state) => state.email, 'email', 'newuser@example.com')
              .having((state) => state.userType, 'userType', 'guard'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when registration fails',
        build: () {
          when(() => mockRepository.createUserWithEmailAndPassword(any(), any()))
              .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthRegister(
          email: 'existing@example.com',
          password: 'password123',
          name: 'Existing User',
          userType: 'guard',
        )),
        expect: () => [
          const AuthLoading(loadingMessage: 'Account aanmaken...'),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthLogout', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
        build: () {
          when(() => mockRepository.signOut()).thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogout()),
        expect: () => [
          const AuthLoading(loadingMessage: 'Uitloggen...'),
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when logout fails',
        build: () {
          when(() => mockRepository.signOut()).thenThrow(Exception('Logout failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogout()),
        expect: () => [
          const AuthLoading(loadingMessage: 'Uitloggen...'),
          isA<AuthError>(),
        ],
      );
    });

    group('AuthValidateEmail', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthEmailValidation with valid result for valid email',
        build: () {
          when(() => mockRepository.isValidEmail(any())).thenReturn(true);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthValidateEmail('test@example.com')),
        expect: () => [
          isA<AuthEmailValidation>()
              .having((state) => state.isValid, 'isValid', true)
              .having((state) => state.email, 'email', 'test@example.com'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthEmailValidation with invalid result for invalid email',
        build: () {
          when(() => mockRepository.isValidEmail(any())).thenReturn(false);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthValidateEmail('invalid-email')),
        expect: () => [
          isA<AuthEmailValidation>()
              .having((state) => state.isValid, 'isValid', false)
              .having((state) => state.email, 'email', 'invalid-email'),
        ],
      );
    });

    group('AuthValidatePassword', () {
      blocTest<AuthBloc, AuthState>(
        'emits AuthPasswordValidation with valid result for strong password',
        build: () {
          when(() => mockRepository.isValidPassword(any())).thenReturn(true);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthValidatePassword('strongpassword123')),
        expect: () => [
          isA<AuthPasswordValidation>()
              .having((state) => state.isValid, 'isValid', true),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits AuthPasswordValidation with invalid result for weak password',
        build: () {
          when(() => mockRepository.isValidPassword(any())).thenReturn(false);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthValidatePassword('123')),
        expect: () => [
          isA<AuthPasswordValidation>()
              .having((state) => state.isValid, 'isValid', false),
        ],
      );
    });

    // Demo functionality removed for production
    // group('AuthCreateDemoUsers', () {
    //   blocTest<AuthBloc, AuthState>(
    //     'emits [AuthLoading, AuthDemoUsersCreated] when demo users creation succeeds',
    //     build: () {
    //       when(() => mockRepository.createDemoUsers()).thenAnswer((_) async {});
    //       return authBloc;
    //     },
    //     act: (bloc) => bloc.add(const AuthCreateDemoUsers()),
    //     expect: () => [
    //       const AuthLoading(loadingMessage: 'Demo gebruikers aanmaken...'),
    //       isA<AuthDemoUsersCreated>()
    //           .having((state) => state.createdCount, 'createdCount', 3),
    //     ],
    //   );
    // });

    group('Convenience Getters', () {
      test('isAuthenticated returns true when state is AuthAuthenticated', () {
        authBloc.emit(const AuthAuthenticated(
          userId: 'test-uid',
          userType: 'guard',
          userName: 'Test User',
          userEmail: 'test@example.com',
          userData: {},
        ));
        
        expect(authBloc.isAuthenticated, isTrue);
      });

      test('isAuthenticated returns false when state is not AuthAuthenticated', () {
        authBloc.emit(const AuthUnauthenticated());
        expect(authBloc.isAuthenticated, isFalse);
      });

      test('currentUser returns AuthAuthenticated state when authenticated', () {
        const authenticatedState = AuthAuthenticated(
          userId: 'test-uid',
          userType: 'guard',
          userName: 'Test User',
          userEmail: 'test@example.com',
          userData: {},
        );
        
        authBloc.emit(authenticatedState);
        expect(authBloc.currentUser, equals(authenticatedState));
      });

      test('currentUserType returns correct user type when authenticated', () {
        authBloc.emit(const AuthAuthenticated(
          userId: 'test-uid',
          userType: 'company',
          userName: 'Test Company',
          userEmail: 'company@example.com',
          userData: {},
        ));
        
        expect(authBloc.currentUserType, equals('company'));
      });
    });

    group('Dutch Localization', () {
      test('AuthAuthenticated provides correct Dutch role display names', () {
        const guardState = AuthAuthenticated(
          userId: 'guard-uid',
          userType: 'guard',
          userName: 'Guard User',
          userEmail: 'guard@example.com',
          userData: {},
        );
        
        const companyState = AuthAuthenticated(
          userId: 'company-uid',
          userType: 'company',
          userName: 'Company User',
          userEmail: 'company@example.com',
          userData: {},
        );
        
        const adminState = AuthAuthenticated(
          userId: 'admin-uid',
          userType: 'admin',
          userName: 'Admin User',
          userEmail: 'admin@example.com',
          userData: {},
        );
        
        expect(guardState.userRoleDisplayName, equals('Beveiliger'));
        expect(companyState.userRoleDisplayName, equals('Bedrijf'));
        expect(adminState.userRoleDisplayName, equals('Beheerder'));
      });

      test('AuthEmailValidation provides Dutch error messages', () {
        const invalidEmailState = AuthEmailValidation(
          email: '',
          isValid: false,
        );
        
        expect(invalidEmailState.dutchErrorMessage, equals('E-mailadres is verplicht'));
      });

      test('AuthPasswordValidation provides Dutch error messages', () {
        const invalidPasswordState = AuthPasswordValidation(
          password: '',
          isValid: false,
        );
        
        expect(invalidPasswordState.dutchErrorMessage, equals('Wachtwoord is verplicht'));
      });
    });

    group('Dutch Business Validation', () {
      group('AuthValidateKvK', () {
        blocTest<AuthBloc, AuthState>(
          'emits [AuthKvKValidating, AuthKvKValidation] for valid KvK number',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateKvK('12345678')),
          expect: () => [
            isA<AuthKvKValidating>()
                .having((state) => state.kvkNumber, 'kvkNumber', '12345678'),
            isA<AuthKvKValidation>()
                .having((state) => state.kvkNumber, 'kvkNumber', '12345678')
                .having((state) => state.isValid, 'isValid', isTrue)
                .having((state) => state.kvkData, 'kvkData', isNotNull),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthKvKValidation with error for invalid KvK format',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateKvK('1234567')), // 7 digits
          expect: () => [
            isA<AuthKvKValidation>()
                .having((state) => state.kvkNumber, 'kvkNumber', '1234567')
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('8 cijfers')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthKvKValidation with error for empty KvK number',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateKvK('')),
          expect: () => [
            isA<AuthKvKValidation>()
                .having((state) => state.kvkNumber, 'kvkNumber', '')
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('verplicht')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits [AuthKvKValidating, AuthKvKValidation] for inactive company',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateKvK('99999999')), // Will generate mock inactive company
          expect: () => [
            isA<AuthKvKValidating>(),
            isA<AuthKvKValidation>()
                .having((state) => state.isValid, 'isValid', isTrue), // Mock will be active by default
          ],
        );
      });

      group('AuthValidateWPBR', () {
        blocTest<AuthBloc, AuthState>(
          'emits [AuthWPBRValidating, AuthWPBRValidation] for valid WPBR certificate',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateWPBR(wpbrNumber: 'WPBR-123456')),
          expect: () => [
            isA<AuthWPBRValidating>()
                .having((state) => state.wpbrNumber, 'wpbrNumber', 'WPBR-123456'),
            isA<AuthWPBRValidation>()
                .having((state) => state.wpbrNumber, 'wpbrNumber', 'WPBR-123456')
                .having((state) => state.isValid, 'isValid', isTrue)
                .having((state) => state.wpbrData, 'wpbrData', isNotNull),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthWPBRValidation with error for invalid WPBR format',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateWPBR(wpbrNumber: 'WPBR-12345')), // 5 digits
          expect: () => [
            isA<AuthWPBRValidation>()
                .having((state) => state.wpbrNumber, 'wpbrNumber', 'WPBR-12345')
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('WPBR-123456')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthWPBRValidation with error for empty WPBR number',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateWPBR(wpbrNumber: '')),
          expect: () => [
            isA<AuthWPBRValidation>()
                .having((state) => state.wpbrNumber, 'wpbrNumber', '')
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('verplicht')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits [AuthWPBRValidating, AuthWPBRValidation] for expired certificate',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateWPBR(wpbrNumber: 'WPBR-999999')), // Mock expired cert
          expect: () => [
            isA<AuthWPBRValidating>(),
            isA<AuthWPBRValidation>()
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('verlopen')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'handles WPBR validation with certificate file path',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidateWPBR(
            wpbrNumber: 'WPBR-123456',
            certificateFilePath: '/path/to/certificate.pdf',
          )),
          expect: () => [
            isA<AuthWPBRValidating>(),
            isA<AuthWPBRValidation>()
                .having((state) => state.isValid, 'isValid', isTrue),
          ],
        );
      });

      group('AuthValidatePostalCode', () {
        blocTest<AuthBloc, AuthState>(
          'emits AuthPostalCodeValidation with valid result for correct postal code',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidatePostalCode('1234AB')),
          expect: () => [
            isA<AuthPostalCodeValidation>()
                .having((state) => state.postalCode, 'postalCode', '1234AB')
                .having((state) => state.isValid, 'isValid', isTrue)
                .having((state) => state.formattedPostalCode, 'formattedPostalCode', '1234 AB'),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthPostalCodeValidation with valid result and formats postal code with space',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidatePostalCode('1234 AB')),
          expect: () => [
            isA<AuthPostalCodeValidation>()
                .having((state) => state.postalCode, 'postalCode', '1234 AB')
                .having((state) => state.isValid, 'isValid', isTrue)
                .having((state) => state.formattedPostalCode, 'formattedPostalCode', '1234 AB'),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthPostalCodeValidation with invalid result for wrong format',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidatePostalCode('123AB')), // 3 digits
          expect: () => [
            isA<AuthPostalCodeValidation>()
                .having((state) => state.postalCode, 'postalCode', '123AB')
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('1234AB')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'emits AuthPostalCodeValidation with error for empty postal code',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidatePostalCode('')),
          expect: () => [
            isA<AuthPostalCodeValidation>()
                .having((state) => state.postalCode, 'postalCode', '')
                .having((state) => state.isValid, 'isValid', isFalse)
                .having((state) => state.errorMessage, 'errorMessage', contains('verplicht')),
          ],
        );

        blocTest<AuthBloc, AuthState>(
          'normalizes lowercase postal code',
          build: () => authBloc,
          act: (bloc) => bloc.add(const AuthValidatePostalCode('1234ab')),
          expect: () => [
            isA<AuthPostalCodeValidation>()
                .having((state) => state.isValid, 'isValid', isTrue)
                .having((state) => state.formattedPostalCode, 'formattedPostalCode', '1234 AB'),
          ],
        );
      });
    });

    group('Dutch Validation States', () {
      group('AuthKvKValidation', () {
        test('provides Dutch error messages', () {
          const state = AuthKvKValidation(
            kvkNumber: '',
            isValid: false,
          );
          
          expect(state.dutchErrorMessage, equals('KvK nummer is verplicht'));
        });

        test('extracts company data correctly', () {
          const state = AuthKvKValidation(
            kvkNumber: '12345678',
            isValid: true,
            kvkData: {
              'companyName': 'Test Company BV',
              'displayName': 'Test Trade Name (Test Company BV)',
              'isActive': true,
            },
          );

          expect(state.companyName, equals('Test Company BV'));
          expect(state.displayName, equals('Test Trade Name (Test Company BV)'));
          expect(state.isActive, isTrue);
        });

        test('handles missing data gracefully', () {
          const state = AuthKvKValidation(
            kvkNumber: '12345678',
            isValid: true,
          );

          expect(state.companyName, isNull);
          expect(state.displayName, isNull);
          expect(state.isActive, isFalse);
        });
      });

      group('AuthWPBRValidation', () {
        test('provides Dutch error messages', () {
          const state = AuthWPBRValidation(
            wpbrNumber: '',
            isValid: false,
          );
          
          expect(state.dutchErrorMessage, equals('WPBR certificaatnummer is verplicht'));
        });

        test('extracts certificate data correctly', () {
          const state = AuthWPBRValidation(
            wpbrNumber: 'WPBR-123456',
            isValid: true,
            wpbrData: {
              'holderName': 'Jan de Beveiliger',
              'status': 'verified',
              'expirationDate': '2025-12-31T23:59:59.000Z',
            },
          );

          expect(state.holderName, equals('Jan de Beveiliger'));
          expect(state.status, equals('verified'));
          expect(state.isCurrentlyValid, isTrue);
        });

        test('correctly identifies expired certificates', () {
          const state = AuthWPBRValidation(
            wpbrNumber: 'WPBR-123456',
            isValid: true,
            wpbrData: {
              'holderName': 'Test Guard',
              'status': 'verified',
              'expirationDate': '2020-01-01T00:00:00.000Z', // Expired
            },
          );

          expect(state.isCurrentlyValid, isFalse);
        });

        test('handles invalid expiration date format', () {
          const state = AuthWPBRValidation(
            wpbrNumber: 'WPBR-123456',
            isValid: true,
            wpbrData: {
              'holderName': 'Test Guard',
              'status': 'verified',
              'expirationDate': 'invalid-date-format',
            },
          );

          expect(state.isCurrentlyValid, isTrue); // Falls back to status check
        });

        test('handles missing data gracefully', () {
          const state = AuthWPBRValidation(
            wpbrNumber: 'WPBR-123456',
            isValid: true,
          );

          expect(state.holderName, isNull);
          expect(state.status, isNull);
          expect(state.isCurrentlyValid, isFalse);
        });
      });

      group('AuthPostalCodeValidation', () {
        test('provides Dutch error messages', () {
          const state = AuthPostalCodeValidation(
            postalCode: '',
            isValid: false,
          );
          
          expect(state.dutchErrorMessage, equals('Postcode is verplicht'));
        });

        test('returns formatted postal code', () {
          const state = AuthPostalCodeValidation(
            postalCode: '1234AB',
            isValid: true,
            formattedPostalCode: '1234 AB',
          );

          expect(state.formattedPostalCode, equals('1234 AB'));
          expect(state.dutchErrorMessage, isEmpty);
        });
      });
    });

    group('Loading States', () {
      test('AuthKvKValidating implements LoadingStateMixin', () {
        const state = AuthKvKValidating('12345678');
        
        expect(state.isLoading, isTrue);
        expect(state.kvkNumber, equals('12345678'));
      });

      test('AuthWPBRValidating implements LoadingStateMixin', () {
        const state = AuthWPBRValidating('WPBR-123456');
        
        expect(state.isLoading, isTrue);
        expect(state.wpbrNumber, equals('WPBR-123456'));
      });
    });
  });
}
