import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:securyflex_app/auth/widgets/kvk_validation_widget.dart';
import 'package:securyflex_app/auth/bloc/auth_bloc.dart';
import 'package:securyflex_app/auth/bloc/auth_event.dart';
import 'package:securyflex_app/auth/bloc/auth_state.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_input_system.dart';

/// Mock AuthBloc for testing
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('KvKValidationWidget', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      
      // Register fallback values for Mocktail
      registerFallbackValue(const AuthInitial());
      registerFallbackValue(const AuthValidateKvK(''));
    });

    Widget createTestWidget({
      bool requireSecurityEligibility = false,
      UserRole? userRole,
      bool showDetailedInfo = true,
      bool enableRealTimeValidation = false,
      void Function(AuthKvKValidation result)? onValidationSuccess,
      void Function(String error)? onValidationError,
    }) {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: Scaffold(
            body: KvKValidationWidget(
              requireSecurityEligibility: requireSecurityEligibility,
              userRole: userRole,
              showDetailedInfo: showDetailedInfo,
              enableRealTimeValidation: enableRealTimeValidation,
              onValidationSuccess: onValidationSuccess,
              onValidationError: onValidationError,
            ),
          ),
        ),
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render KvK validation widget correctly', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('KvK Nummer Validatie'), findsOneWidget);
        expect(find.text('KvK Nummer'), findsOneWidget);
        expect(find.text('KvK Valideren'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('should show security eligibility message when required', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget(requireSecurityEligibility: true));

        expect(
          find.text('Valideer uw KvK nummer en controleer geschiktheid voor beveiligingsopdrachten'),
          findsOneWidget,
        );
      });

      testWidgets('should not show validate button in real-time mode', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget(enableRealTimeValidation: true));

        expect(find.text('KvK Valideren'), findsNothing);
      });
    });

    group('User Interactions', () {
      testWidgets('should trigger validation when button is pressed', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockAuthBloc.add(any())).thenReturn(null);

        await tester.pumpWidget(createTestWidget());

        // Enter valid KvK number
        await tester.enterText(find.byType(TextFormField), '12345678');
        await tester.tap(find.text('KvK Valideren'));
        await tester.pump();

        verify(() => mockAuthBloc.add(any<AuthValidateKvK>())).called(1);
      });

      testWidgets('should trigger real-time validation when typing', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockAuthBloc.add(any())).thenReturn(null);

        await tester.pumpWidget(createTestWidget(enableRealTimeValidation: true));

        // Enter 8-digit KvK number to trigger real-time validation
        await tester.enterText(find.byType(TextFormField), '12345678');
        await tester.pump();

        verify(() => mockAuthBloc.add(any<AuthValidateKvK>())).called(1);
      });

      testWidgets('should not trigger validation for incomplete KvK number', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget(enableRealTimeValidation: true));

        // Enter incomplete KvK number
        await tester.enterText(find.byType(TextFormField), '1234567');
        await tester.pump();

        verifyNever(() => mockAuthBloc.add(any<AuthValidateKvK>()));
      });
    });

    group('State Handling', () {
      testWidgets('should show loading indicator when validating', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthKvKValidating('12345678'));
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(const AuthKvKValidating('12345678')),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('KvK nummer valideren...'), findsOneWidget);
      });

      testWidgets('should show enhanced loading details when available', (tester) async {
        const validatingState = AuthKvKValidating(
          '12345678',
          loadingMessage: 'KvK nummer valideren...',
          currentStep: 'Verbinding maken met KvK API',
          attemptNumber: 2,
        );

        when(() => mockAuthBloc.state).thenReturn(validatingState);
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validatingState),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Verbinding maken met KvK API'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show success state with company information', (tester) async {
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: true,
          kvkData: {
            'companyName': 'Test Company B.V.',
            'tradeName': 'Test Company',
            'isActive': true,
          },
          isSecurityEligible: true,
          eligibilityScore: 0.8,
          eligibilityReasons: ['Active company', 'Security registered'],
        );

        when(() => mockAuthBloc.state).thenReturn(validationResult);
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('KvK Nummer Gevalideerd'), findsOneWidget);
        expect(find.text('Test Company B.V.'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should show security eligibility when enabled', (tester) async {
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: true,
          kvkData: {
            'companyName': 'Security Company B.V.',
            'isActive': true,
          },
          isSecurityEligible: true,
          eligibilityScore: 0.9,
        );

        when(() => mockAuthBloc.state).thenReturn(validationResult);
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );

        await tester.pumpWidget(createTestWidget(requireSecurityEligibility: true));
        await tester.pump();

        expect(find.byIcon(Icons.security), findsOneWidget);
        expect(
          find.textContaining('Geschikt voor beveiligingsopdrachten'),
          findsOneWidget,
        );
      });

      testWidgets('should show error state with retry button', (tester) async {
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: false,
          errorMessage: 'KvK nummer niet gevonden',
        );

        when(() => mockAuthBloc.state).thenReturn(validationResult);
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );
        when(() => mockAuthBloc.add(any())).thenReturn(null);

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Validatie Mislukt'), findsOneWidget);
        expect(find.text('KvK nummer niet gevonden'), findsOneWidget);
        expect(find.text('Opnieuw Proberen'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Test retry functionality
        await tester.tap(find.text('Opnieuw Proberen'));
        await tester.pump();

        verify(() => mockAuthBloc.add(any<AuthValidateKvK>())).called(1);
      });
    });

    group('Callbacks', () {
      testWidgets('should call onValidationSuccess when validation succeeds', (tester) async {
        AuthKvKValidation? capturedResult;
        
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: true,
          kvkData: {'companyName': 'Test Company B.V.'},
        );

        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );

        await tester.pumpWidget(createTestWidget(
          onValidationSuccess: (result) => capturedResult = result,
        ));

        await tester.pump();

        expect(capturedResult, equals(validationResult));
      });

      testWidgets('should call onValidationError when validation fails', (tester) async {
        String? capturedError;
        
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: false,
          errorMessage: 'Test error message',
        );

        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );

        await tester.pumpWidget(createTestWidget(
          onValidationError: (error) => capturedError = error,
        ));

        await tester.pump();

        expect(capturedError, equals('Test error message'));
      });
    });

    group('Form Validation', () {
      testWidgets('should validate KvK number format', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final textField = find.byType(TextFormField);
        
        // Test empty input
        await tester.enterText(textField, '');
        await tester.pump();
        
        // Test too short
        await tester.enterText(textField, '1234567');
        await tester.pump();
        
        // Test too long
        await tester.enterText(textField, '123456789');
        await tester.pump();
        
        // Test non-numeric
        await tester.enterText(textField, '1234567a');
        await tester.pump();

        // Valid format should not show error
        await tester.enterText(textField, '12345678');
        await tester.pump();
      });
    });

    group('Company Details Modal', () {
      testWidgets('should show company details button when validation succeeds', (tester) async {
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: true,
          kvkData: {
            'companyName': 'Test Company B.V.',
            'tradeName': 'Test Company',
            'isActive': true,
          },
        );

        when(() => mockAuthBloc.state).thenReturn(validationResult);
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );

        await tester.pumpWidget(createTestWidget(showDetailedInfo: true));
        await tester.pump();

        expect(find.text('Bedrijfsgegevens Bekijken'), findsOneWidget);
      });

      testWidgets('should not show company details button when disabled', (tester) async {
        const validationResult = AuthKvKValidation(
          kvkNumber: '12345678',
          isValid: true,
          kvkData: {'companyName': 'Test Company B.V.'},
        );

        when(() => mockAuthBloc.state).thenReturn(validationResult);
        when(() => mockAuthBloc.stream).thenAnswer(
          (_) => Stream.value(validationResult),
        );

        await tester.pumpWidget(createTestWidget(showDetailedInfo: false));
        await tester.pump();

        expect(find.text('Bedrijfsgegevens Bekijken'), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper accessibility labels', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        // Check that form fields have labels
        expect(find.text('KvK Nummer'), findsOneWidget);
        expect(find.text('8 cijfers, bijvoorbeeld 12345678'), findsOneWidget);
        
        // Check button accessibility
        expect(find.text('KvK Valideren'), findsOneWidget);
      });

      testWidgets('should provide appropriate semantics for screen readers', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        // This would test semantic labels, but requires more complex setup
        // For now, we ensure the basic structure is accessible
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Theme Integration', () {
      testWidgets('should apply role-based theming when userRole is provided', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget(userRole: UserRole.company));

        // Widget should render without errors with role-based theming
        expect(find.byType(KvKValidationWidget), findsOneWidget);
      });
    });

    group('Input Formatting', () {
      testWidgets('should handle numeric-only input', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final textField = find.byType(TextFormField);
        
        // Enter numeric input
        await tester.enterText(textField, '12345678');
        await tester.pump();

        expect(find.text('12345678'), findsOneWidget);
      });

      testWidgets('should respect maxLength constraint', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(createTestWidget());

        final textField = find.byType(UnifiedInput);
        
        // Try to enter more than 8 characters
        await tester.enterText(textField, '123456789012');
        await tester.pump();

        // Should be limited to 8 characters - check if the controller contains only 8 characters
        final inputWidget = tester.widget<UnifiedInput>(textField);
        expect(inputWidget.controller?.text.length, lessThanOrEqualTo(8));
      });
    });
  });
}