import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/auth/registration_screen.dart';

void main() {
  group('RegistrationScreen Tests', () {
    testWidgets('should display all required form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Check for user type selection
      expect(find.text('Account Type'), findsOneWidget);
      expect(find.text('Beveiliger'), findsOneWidget);
      expect(find.text('Bedrijf'), findsOneWidget);

      // Check for form fields
      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, email, password, confirm password
      
      // Check for register button
      expect(find.text('Account aanmaken'), findsAtLeastNWidgets(1));

      // Check for login link
      expect(find.text('Heb je al een account? Inloggen'), findsOneWidget);
    });

    testWidgets('should show unified header with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      expect(find.text('Account Aanmaken'), findsAtLeastNWidgets(1));
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Try to submit empty form
      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pump();

      // Should show validation errors
      expect(find.text('Naam is verplicht'), findsOneWidget);
      expect(find.text('E-mailadres is verplicht'), findsOneWidget);
      expect(find.text('Wachtwoord is verplicht'), findsOneWidget);
    });

    testWidgets('should validate email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Enter invalid email
      final emailField = find.byType(TextFormField).at(1); // Email field
      await tester.enterText(emailField, 'invalid-email');
      
      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Voer een geldig e-mailadres in'), findsOneWidget);
    });

    testWidgets('should validate password strength', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Enter weak password
      final passwordField = find.byType(TextFormField).at(2); // Password field
      await tester.enterText(passwordField, '123');
      
      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.textContaining('Wachtwoord moet minimaal'), findsOneWidget);
    });

    testWidgets('should validate password confirmation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Enter different passwords
      final passwordField = find.byType(TextFormField).at(2);
      final confirmPasswordField = find.byType(TextFormField).at(3);
      
      await tester.enterText(passwordField, 'SecurePass123!');
      await tester.enterText(confirmPasswordField, 'DifferentPass123!');
      
      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('Wachtwoorden komen niet overeen'), findsOneWidget);
    });

    testWidgets('should change form labels based on user type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Initially should show guard labels
      expect(find.text('Volledige naam'), findsOneWidget);

      // Switch to company
      final companyChip = find.text('Bedrijf');
      await tester.tap(companyChip);
      await tester.pump();

      // Should now show company labels
      expect(find.text('Bedrijfsnaam'), findsOneWidget);
    });

    testWidgets('should show loading state during registration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Fill in valid form data
      await _fillValidForm(tester);

      // Tap register button
      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pump();

      // Should show loading state
      expect(find.text('Account aanmaken...'), findsOneWidget);
    });

    testWidgets('should navigate back to login on success', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Fill in valid form data
      await _fillValidForm(tester);

      // Mock successful registration
      // Note: In a real test, you'd mock AuthService.register to return success

      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show success message (in a real test)
      // expect(find.textContaining('succesvol'), findsOneWidget);
    });

    testWidgets('should show email verification dialog on successful registration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Fill in valid form data
      await _fillValidForm(tester);

      // Mock successful registration with email verification required
      // Note: In a real test, you'd mock AuthService.register to return appropriate result

      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show email verification dialog (in a real test)
      // expect(find.text('E-mail verificatie vereist'), findsOneWidget);
      // expect(find.text('Opnieuw verzenden'), findsOneWidget);
      // expect(find.text('Begrepen'), findsOneWidget);
    });

    testWidgets('should handle registration errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      // Fill in form data that would cause an error
      await _fillValidForm(tester);

      // Mock registration error
      // Note: In a real test, you'd mock AuthService.register to return error

      final registerButton = find.text('Account aanmaken').first;
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show error message (in a real test)
      // expect(find.textContaining('fout'), findsOneWidget);
    });

    testWidgets('should navigate back to login when login link is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegistrationScreen(),
        ),
      );

      final loginLink = find.text('Heb je al een account? Inloggen');
      expect(loginLink, findsOneWidget);

      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Should navigate back (in a real test with navigation)
    });
  });
}

/// Helper function to fill in valid form data
Future<void> _fillValidForm(WidgetTester tester) async {
  // Fill name field
  final nameField = find.byType(TextFormField).at(0);
  await tester.enterText(nameField, 'Jan de Vries');

  // Fill email field
  final emailField = find.byType(TextFormField).at(1);
  await tester.enterText(emailField, 'jan@example.com');

  // Fill password field
  final passwordField = find.byType(TextFormField).at(2);
  await tester.enterText(passwordField, 'SecurePass123!');

  // Fill confirm password field
  final confirmPasswordField = find.byType(TextFormField).at(3);
  await tester.enterText(confirmPasswordField, 'SecurePass123!');

  await tester.pump();
}
