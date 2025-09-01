import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:securyflex_app/auth/widgets/advanced_auth_widgets.dart';
import 'package:securyflex_app/auth/models/enhanced_auth_models.dart';
import 'package:securyflex_app/unified_design_tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Advanced Authentication Widgets Tests', () {
    
    group('TwoFactorSetupWidget Tests', () {
      late List<BackupCode> mockBackupCodes;
      late String mockSecret;
      late String mockQrCodeData;
      const mockUserEmail = 'test@securyflex.nl';

      setUp(() {
        mockSecret = 'JBSWY3DPEHPK3PXP';
        mockQrCodeData = 'otpauth://totp/SecuryFlex:$mockUserEmail?secret=$mockSecret&issuer=SecuryFlex&digits=6&period=30';
        mockBackupCodes = List.generate(10, (i) => BackupCode.generate());
      });

      testWidgets('should display initial step with QR code', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Verify header
        expect(find.text('Tweefactor Authenticatie Instellen'), findsOneWidget);
        expect(find.byIcon(Icons.security), findsOneWidget);

        // Verify QR code step is displayed
        expect(find.text('Stap 1: Scan QR Code'), findsOneWidget);
        expect(find.text('Scan deze QR code met je authenticator app (Google Authenticator, Authy, enz.):'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);

        // Verify stepper shows current step
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);

        // Verify action button
        expect(find.text('Volgende'), findsOneWidget);
      });

      testWidgets('should show manual entry when expansion tile is opened', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Tap expansion tile
        await tester.tap(find.text('Handmatige invoer'));
        await tester.pumpAndSettle();

        // Verify manual entry is shown
        expect(find.text('Als je de QR code niet kunt scannen, voer dan handmatig deze code in:'), findsOneWidget);
        expect(find.text(mockSecret), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsOneWidget);
      });

      testWidgets('should copy secret to clipboard', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Open manual entry
        await tester.tap(find.text('Handmatige invoer'));
        await tester.pumpAndSettle();

        // Tap copy button
        await tester.tap(find.byIcon(Icons.copy));
        await tester.pump();

        // Verify copied state
        expect(find.byIcon(Icons.check), findsWidgets);
        expect(find.byTooltip('Gekopieerd!'), findsOneWidget);
      });

      testWidgets('should navigate through steps correctly', (tester) async {
        String? verifiedCode;
        bool completed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
                onVerifyCode: (code) => verifiedCode = code,
                onComplete: () => completed = true,
              ),
            ),
          ),
        );

        // Navigate to step 2
        await tester.tap(find.text('Volgende'));
        await tester.pumpAndSettle();

        // Verify verification step
        expect(find.text('Stap 2: Verificeer Authenticator'), findsOneWidget);
        expect(find.text('Voer de 6-cijferige code in die wordt weergegeven in je authenticator app:'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // Enter verification code
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        // Verify button changes to "Verifiëren"
        expect(find.text('Verifiëren'), findsOneWidget);

        // Navigate to step 3
        await tester.tap(find.text('Verifiëren'));
        await tester.pumpAndSettle();

        // Verify backup codes step
        expect(find.text('Stap 3: Bewaar Backup Codes'), findsOneWidget);
        expect(find.text('Bewaar deze backup codes op een veilige plaats. Elke code kan maar één keer gebruikt worden.'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);

        // Verify backup codes are displayed
        for (final code in mockBackupCodes) {
          expect(find.text(code.formattedCode), findsOneWidget);
        }

        // Download backup codes
        await tester.tap(find.byIcon(Icons.download));
        await tester.pumpAndSettle();

        // Verify download state and complete
        expect(find.byIcon(Icons.check), findsWidgets);
        expect(find.text('Voltooien'), findsOneWidget);

        // Complete setup
        await tester.tap(find.text('Voltooien'));
        await tester.pump();

        // Verify callbacks were called
        expect(verifiedCode, equals('123456'));
        expect(completed, isTrue);
      });

      testWidgets('should handle cancel action', (tester) async {
        bool cancelled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        );

        // Tap cancel button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(cancelled, isTrue);
      });

      testWidgets('should validate code input format', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Navigate to verification step
        await tester.tap(find.text('Volgende'));
        await tester.pumpAndSettle();

        final textField = find.byType(TextField);
        
        // Verify input formatters
        await tester.enterText(textField, 'abcdef');
        await tester.pump();
        
        // Should only contain digits (empty since letters are filtered)
        expect(tester.widget<TextField>(textField).controller?.text, isEmpty);

        // Enter valid digits
        await tester.enterText(textField, '1234567890');
        await tester.pump();

        // Should be limited to 6 digits
        expect(tester.widget<TextField>(textField).controller?.text, equals('123456'));
      });

      testWidgets('should disable continue button when conditions not met', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: mockSecret,
                qrCodeData: mockQrCodeData,
                userEmail: mockUserEmail,
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Navigate to verification step
        await tester.tap(find.text('Volgende'));
        await tester.pumpAndSettle();

        // Button should be disabled with incomplete code
        final button = find.text('Verifiëren');
        expect(tester.widget<ElevatedButton>(find.ancestor(
          of: button, 
          matching: find.byType(ElevatedButton)
        )).onPressed, isNull);

        // Enter complete code
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        // Button should now be enabled
        expect(tester.widget<ElevatedButton>(find.ancestor(
          of: button, 
          matching: find.byType(ElevatedButton)
        )).onPressed, isNotNull);
      });
    });

    group('SMSVerificationWidget Tests', () {
      const mockPhoneNumber = '+31612345678';
      const mockVerificationId = 'test-verification-id';

      testWidgets('should display SMS verification form', (tester) async {
        String? verifiedCode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: mockPhoneNumber,
                verificationId: mockVerificationId,
                onVerifyCode: (code) => verifiedCode = code,
              ),
            ),
          ),
        );

        // Verify header
        expect(find.text('SMS Verificatie'), findsOneWidget);
        expect(find.byIcon(Icons.sms), findsOneWidget);

        // Verify description
        expect(find.text('We hebben een verificatiecode verzonden naar:'), findsOneWidget);
        expect(find.text(mockPhoneNumber), findsOneWidget);

        // Verify code input
        expect(find.text('Voer de 6-cijferige code in:'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        // Verify verify button
        expect(find.text('Verifiëren'), findsOneWidget);

        // Verify callback is set up (variable should be null initially)
        expect(verifiedCode, isNull);
      });

      testWidgets('should handle code input and verification', (tester) async {
        String? verifiedCode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: mockPhoneNumber,
                verificationId: mockVerificationId,
                onVerifyCode: (code) => verifiedCode = code,
              ),
            ),
          ),
        );

        // Enter code
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        // Code should auto-trigger verification
        expect(verifiedCode, equals('123456'));

        // Manual verification should also work
        verifiedCode = null;
        await tester.tap(find.text('Verifiëren'));
        await tester.pump();

        expect(verifiedCode, equals('123456'));
      });

      testWidgets('should display countdown timer', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: mockPhoneNumber,
                verificationId: mockVerificationId,
                onVerifyCode: (code) {},
                initialCooldownSeconds: 10,
              ),
            ),
          ),
        );

        // Verify countdown is displayed
        expect(find.text('Nieuwe code aanvragen over: '), findsOneWidget);
        expect(find.textContaining('s'), findsOneWidget);

        // Wait for countdown to progress
        await tester.pump(const Duration(seconds: 1));
        
        // Timer should be counting down
        expect(find.textContaining('s'), findsOneWidget);
      });

      testWidgets('should show resend option after cooldown', (tester) async {
        bool resendCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: mockPhoneNumber,
                verificationId: mockVerificationId,
                onVerifyCode: (code) {},
                onResendCode: () => resendCalled = true,
                initialCooldownSeconds: 0, // No cooldown for testing
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show resend option
        expect(find.text('Code opnieuw versturen'), findsOneWidget);

        // Tap resend
        await tester.tap(find.text('Code opnieuw versturen'));
        await tester.pump();

        expect(resendCalled, isTrue);
      });

      testWidgets('should validate input format', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: mockPhoneNumber,
                verificationId: mockVerificationId,
                onVerifyCode: (code) {},
              ),
            ),
          ),
        );

        final textField = find.byType(TextField);

        // Test digit-only input
        await tester.enterText(textField, 'abc123');
        await tester.pump();
        expect(tester.widget<TextField>(textField).controller?.text, equals('123'));

        // Test length limiting
        await tester.enterText(textField, '1234567890');
        await tester.pump();
        expect(tester.widget<TextField>(textField).controller?.text, equals('123456'));
      });

      testWidgets('should handle cancel action', (tester) async {
        bool cancelled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: mockPhoneNumber,
                verificationId: mockVerificationId,
                onVerifyCode: (code) {},
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(cancelled, isTrue);
      });
    });

    group('BiometricSetupWidget Tests', () {
      late BiometricConfig mockConfig;
      late List<BiometricType> mockAvailableTypes;

      setUp(() {
        mockConfig = const BiometricConfig(
          isEnabled: false,
          isSupported: true,
          availableTypes: [BiometricType.fingerprint, BiometricType.face],
          enabledTypes: [],
        );
        mockAvailableTypes = [BiometricType.fingerprint, BiometricType.face];
      });

      testWidgets('should display biometric setup options', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: mockConfig,
                availableTypes: mockAvailableTypes,
              ),
            ),
          ),
        );

        // Verify header
        expect(find.text('Biometrische Authenticatie'), findsOneWidget);
        expect(find.byIcon(Icons.fingerprint), findsOneWidget);

        // Verify available types section
        expect(find.text('Beschikbare biometrische methoden:'), findsOneWidget);
        expect(find.text('Vingerafdruk'), findsOneWidget);
        expect(find.text('Gezichtsherkenning'), findsOneWidget);

        // Verify descriptions
        expect(find.text('Gebruik je vingerafdruk om in te loggen'), findsOneWidget);
        expect(find.text('Gebruik gezichtsherkenning om in te loggen'), findsOneWidget);

        // Verify security info
        expect(find.text('Biometrische beveiliging'), findsOneWidget);
        expect(find.text('Biometrische gegevens worden alleen lokaal op je apparaat opgeslagen en nooit naar onze servers verzonden.'), findsOneWidget);
      });

      testWidgets('should handle biometric type selection', (tester) async {
        List<BiometricType>? selectedTypes;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: mockConfig,
                availableTypes: mockAvailableTypes,
                onSetupBiometric: (types) => selectedTypes = types,
              ),
            ),
          ),
        );

        // Select fingerprint
        await tester.tap(find.text('Vingerafdruk'));
        await tester.pump();

        // Verify checkbox is checked
        final fingerprintCheckbox = find.ancestor(
          of: find.text('Vingerafdruk'),
          matching: find.byType(CheckboxListTile),
        );
        expect(tester.widget<CheckboxListTile>(fingerprintCheckbox).value, isTrue);

        // Select face recognition
        await tester.tap(find.text('Gezichtsherkenning'));
        await tester.pump();

        // Setup biometric
        await tester.tap(find.text('Biometrische Authenticatie Inschakelen'));
        await tester.pump();

        expect(selectedTypes, isNotNull);
        expect(selectedTypes, contains(BiometricType.fingerprint));
        expect(selectedTypes, contains(BiometricType.face));
      });

      testWidgets('should show message when no types selected', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: mockConfig,
                availableTypes: mockAvailableTypes,
              ),
            ),
          ),
        );

        // Should show selection message
        expect(find.text('Selecteer minimaal één biometrische methode om door te gaan.'), findsOneWidget);

        // Setup button should not be visible
        expect(find.text('Biometrische Authenticatie Inschakelen'), findsNothing);
      });

      testWidgets('should show test button when available', (tester) async {
        bool testCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: mockConfig,
                availableTypes: mockAvailableTypes,
                onTestBiometric: () => testCalled = true,
              ),
            ),
          ),
        );

        // Select a type first
        await tester.tap(find.text('Vingerafdruk'));
        await tester.pump();

        // Test button should be visible
        expect(find.text('Test Biometrische Authenticatie'), findsOneWidget);

        // Tap test button
        await tester.tap(find.text('Test Biometrische Authenticatie'));
        await tester.pump();

        expect(testCalled, isTrue);
      });

      testWidgets('should display not supported message', (tester) async {
        final unsupportedConfig = mockConfig.copyWith(
          isSupported: false,
          availableTypes: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: unsupportedConfig,
                availableTypes: [],
              ),
            ),
          ),
        );

        // Should show not supported message
        expect(find.text('Biometrische authenticatie niet ondersteund'), findsOneWidget);
        expect(find.text('Je apparaat ondersteunt geen biometrische authenticatie of er zijn geen biometrische gegevens ingesteld.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Should not show setup options
        expect(find.text('Beschikbare biometrische methoden:'), findsNothing);
      });

      testWidgets('should handle cancel action', (tester) async {
        bool cancelled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: mockConfig,
                availableTypes: mockAvailableTypes,
                onCancel: () => cancelled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(cancelled, isTrue);
      });
    });

    group('BackupCodesWidget Tests', () {
      late List<BackupCode> mockBackupCodes;

      setUp(() {
        mockBackupCodes = [
          BackupCode.generate(),
          BackupCode.generate(),
          BackupCode.generate().markAsUsed(),
          ...List.generate(7, (i) => BackupCode.generate()),
        ];
      });

      testWidgets('should display backup codes with status', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BackupCodesWidget(
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Verify header
        expect(find.text('Backup Codes'), findsOneWidget);
        expect(find.byIcon(Icons.security), findsOneWidget);

        // Verify status (9 remaining out of 10, 1 used)
        expect(find.text('9 van 10 codes beschikbaar'), findsOneWidget);

        // Verify instructions
        expect(find.text('Belangrijke informatie:'), findsOneWidget);
        expect(find.text('• Elke code kan maar één keer gebruikt worden'), findsOneWidget);
        expect(find.text('• Bewaar deze codes op een veilige plaats'), findsOneWidget);

        // Verify codes section (initially hidden)
        expect(find.text('Je backup codes:'), findsOneWidget);
        expect(find.text('Tonen'), findsOneWidget);
        expect(find.text('Backup codes verborgen voor beveiliging'), findsOneWidget);
      });

      testWidgets('should toggle code visibility', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BackupCodesWidget(
                backupCodes: mockBackupCodes,
              ),
            ),
          ),
        );

        // Tap show button
        await tester.tap(find.text('Tonen'));
        await tester.pumpAndSettle();

        // Codes should now be visible
        expect(find.text('Verbergen'), findsOneWidget);
        
        for (final code in mockBackupCodes) {
          expect(find.text(code.formattedCode), findsOneWidget);
        }

        // Used codes should be shown with strikethrough and checkmark
        expect(find.text('Gebruikt'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);

        // Hide codes again
        await tester.tap(find.text('Verbergen'));
        await tester.pumpAndSettle();

        expect(find.text('Tonen'), findsOneWidget);
        expect(find.text('Backup codes verborgen voor beveiliging'), findsOneWidget);
      });

      testWidgets('should handle download action', (tester) async {
        bool downloadCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BackupCodesWidget(
                backupCodes: mockBackupCodes,
                onDownload: () => downloadCalled = true,
              ),
            ),
          ),
        );

        // Tap download button
        await tester.tap(find.text('Download'));
        await tester.pump();

        expect(downloadCalled, isTrue);
      });

      testWidgets('should show warning when codes are running low', (tester) async {
        // Create codes with only 2 remaining
        final lowCodes = [
          ...List.generate(8, (i) => BackupCode.generate().markAsUsed()),
          BackupCode.generate(),
          BackupCode.generate(),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BackupCodesWidget(
                backupCodes: lowCodes,
                onGenerateNew: () {},
              ),
            ),
          ),
        );

        // Status should show warning color
        expect(find.text('2 van 10 codes beschikbaar'), findsOneWidget);

        // Generate new button should be enabled
        final generateButton = find.text('Nieuwe Codes');
        expect(generateButton, findsOneWidget);

        // Button should be enabled (not null onPressed)
        expect(tester.widget<ElevatedButton>(find.ancestor(
          of: generateButton,
          matching: find.byType(ElevatedButton),
        )).onPressed, isNotNull);
      });

      testWidgets('should disable generate new codes when enough remaining', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BackupCodesWidget(
                backupCodes: mockBackupCodes, // 9 remaining
                onGenerateNew: () {},
              ),
            ),
          ),
        );

        // Generate new button should be disabled
        final generateButton = find.text('Nieuwe Codes');
        expect(generateButton, findsOneWidget);

        expect(tester.widget<ElevatedButton>(find.ancestor(
          of: generateButton,
          matching: find.byType(ElevatedButton),
        )).onPressed, isNull);
      });

      testWidgets('should handle generate new codes action', (tester) async {
        bool generateCalled = false;

        // Create codes with only 1 remaining to enable the button
        final lowCodes = [
          ...List.generate(9, (i) => BackupCode.generate().markAsUsed()),
          BackupCode.generate(),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BackupCodesWidget(
                backupCodes: lowCodes,
                onGenerateNew: () => generateCalled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Nieuwe Codes'));
        await tester.pump();

        expect(generateCalled, isTrue);
      });
    });

    group('SecurityLevelIndicator Tests', () {
      testWidgets('should display basic security level', (tester) async {
        const level = AuthenticationLevel.basic;
        const recommendations = [
          'Schakel tweefactor authenticatie in',
          'Stel biometrische authenticatie in',
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SecurityLevelIndicator(
                currentLevel: level,
                recommendations: recommendations,
              ),
            ),
          ),
        );

        // Verify header
        expect(find.text('Beveiligingsniveau'), findsOneWidget);
        expect(find.byIcon(Icons.security), findsOneWidget);

        // Verify level indicator
        expect(find.text('1/4'), findsOneWidget);
        expect(find.text('Basis'), findsOneWidget);
        expect(find.text('Alleen wachtwoord'), findsOneWidget);

        // Verify progress bar
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // Verify recommendations
        expect(find.text('Aanbevelingen:'), findsOneWidget);
        expect(find.text('Schakel tweefactor authenticatie in'), findsOneWidget);
        expect(find.text('Stel biometrische authenticatie in'), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsAtLeastNWidgets(2));
      });

      testWidgets('should display different security levels correctly', (tester) async {
        final testCases = [
          (AuthenticationLevel.basic, 'Basis', '1/4'),
          (AuthenticationLevel.twoFactor, 'Tweefactor', '2/4'),
          (AuthenticationLevel.biometric, 'Biometrisch', '3/4'),
          (AuthenticationLevel.combined, 'Gecombineerd', '4/4'),
        ];

        for (final (level, dutchName, levelText) in testCases) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SecurityLevelIndicator(
                  currentLevel: level,
                ),
              ),
            ),
          );

          expect(find.text(dutchName), findsOneWidget);
          expect(find.text(levelText), findsOneWidget);

          // Verify description
          expect(find.text(level.descriptionDutch), findsOneWidget);
        }
      });

      testWidgets('should show improve button when provided', (tester) async {
        bool improveCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SecurityLevelIndicator(
                currentLevel: AuthenticationLevel.basic,
                onImprove: () => improveCalled = true,
              ),
            ),
          ),
        );

        // Verify improve button
        expect(find.text('Beveiliging Verbeteren'), findsOneWidget);

        await tester.tap(find.text('Beveiliging Verbeteren'));
        await tester.pump();

        expect(improveCalled, isTrue);
      });

      testWidgets('should use appropriate colors for different levels', (tester) async {
        final testCases = [
          (AuthenticationLevel.basic, DesignTokens.colorError),
          (AuthenticationLevel.twoFactor, DesignTokens.colorWarning),
          (AuthenticationLevel.biometric, DesignTokens.colorInfo),
          (AuthenticationLevel.combined, DesignTokens.colorSuccess),
        ];

        for (final (level, expectedColor) in testCases) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SecurityLevelIndicator(
                  currentLevel: level,
                  onImprove: () {},
                ),
              ),
            ),
          );

          // Find improve button to check color
          final improveButton = find.ancestor(
            of: find.text('Beveiliging Verbeteren'),
            matching: find.byType(ElevatedButton),
          );

          expect(
            tester.widget<ElevatedButton>(improveButton).style?.backgroundColor?.resolve({}),
            equals(expectedColor),
          );
        }
      });

      testWidgets('should not show recommendations section when empty', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SecurityLevelIndicator(
                currentLevel: AuthenticationLevel.combined,
                recommendations: [],
              ),
            ),
          ),
        );

        // Should not show recommendations section
        expect(find.text('Aanbevelingen:'), findsNothing);
        expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      });
    });

    group('Widget Integration and Accessibility', () {
      testWidgets('should provide proper accessibility labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwoFactorSetupWidget(
                secret: 'TESTSECRET',
                qrCodeData: 'otpauth://totp/test',
                userEmail: 'test@test.com',
                backupCodes: [BackupCode.generate()],
              ),
            ),
          ),
        );

        // Check for semantic labels
        expect(find.byTooltip('Annuleren'), findsOneWidget);
        expect(find.byTooltip('Kopiëren'), findsOneWidget);
      });

      testWidgets('should handle keyboard navigation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: '+31612345678',
                verificationId: 'test-id',
                onVerifyCode: (code) {},
              ),
            ),
          ),
        );

        // Focus on text field
        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Enter text via keyboard simulation
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        // Verify text is entered
        expect(find.text('123456'), findsOneWidget);
      });

      testWidgets('should maintain proper widget state during rebuilds', (tester) async {
        String currentSecret = 'INITIALSECRET';

        late StateSetter setSecret;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setSecret = setState;
                return Scaffold(
                  body: TwoFactorSetupWidget(
                    secret: currentSecret,
                    qrCodeData: 'otpauth://totp/test',
                    userEmail: 'test@test.com',
                    backupCodes: [BackupCode.generate()],
                  ),
                );
              },
            ),
          ),
        );

        // Navigate to step 2
        await tester.tap(find.text('Volgende'));
        await tester.pumpAndSettle();

        // Enter some text
        await tester.enterText(find.byType(TextField), '123');
        await tester.pump();

        // Trigger rebuild with new secret
        setSecret(() {
          currentSecret = 'NEWSECRET';
        });
        await tester.pump();

        // Text field should maintain its state
        expect(find.text('123'), findsOneWidget);
        
        // But if we go back to step 1, new secret should be shown
        await tester.tap(find.text('Vorige'));
        await tester.pumpAndSettle();

        // Open manual entry to see secret
        await tester.tap(find.text('Handmatige invoer'));
        await tester.pumpAndSettle();

        expect(find.text(currentSecret), findsOneWidget);
      });

      testWidgets('should handle rapid user interactions gracefully', (tester) async {
        int verifyCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: '+31612345678',
                verificationId: 'test-id',
                onVerifyCode: (code) => verifyCount++,
              ),
            ),
          ),
        );

        // Enter code
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        // Rapid button taps
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('Verifiëren'));
        }
        await tester.pump();

        // Should handle rapid interactions without errors
        expect(verifyCount, greaterThan(0));
      });
    });

    group('Dutch Language and Localization', () {
      testWidgets('should display all text in Dutch', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TwoFactorSetupWidget(
                    secret: 'TEST',
                    qrCodeData: 'test',
                    userEmail: 'test@test.com',
                    backupCodes: [BackupCode.generate()],
                  ),
                  SMSVerificationWidget(
                    phoneNumber: '+31612345678',
                    verificationId: 'test',
                    onVerifyCode: (code) {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify Dutch text in widgets
        final dutchTexts = [
          'Tweefactor Authenticatie Instellen',
          'SMS Verificatie',
          'Scan QR Code',
          'Handmatige invoer',
          'Volgende',
          'Verifiëren',
          'Annuleren',
          'We hebben een verificatiecode verzonden naar:',
          'Voer de 6-cijferige code in:',
        ];

        for (final text in dutchTexts) {
          expect(find.text(text), findsOneWidget,
                 reason: 'Dutch text "$text" should be found');
        }
      });

      testWidgets('should use proper Dutch formatting for phone numbers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SMSVerificationWidget(
                phoneNumber: '+31612345678',
                verificationId: 'test',
                onVerifyCode: (code) {},
              ),
            ),
          ),
        );

        // Phone number should be displayed as provided (properly formatted)
        expect(find.text('+31612345678'), findsOneWidget);
      });

      testWidgets('should provide Dutch tooltips and help text', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BiometricSetupWidget(
                config: const BiometricConfig(
                  isSupported: true,
                  availableTypes: [BiometricType.fingerprint],
                ),
                availableTypes: const [BiometricType.fingerprint],
                onCancel: () {},
              ),
            ),
          ),
        );

        // Verify Dutch tooltips
        expect(find.byTooltip('Annuleren'), findsOneWidget);
        
        // Verify Dutch biometric descriptions
        expect(find.text('Vingerafdruk'), findsOneWidget);
        expect(find.text('Gebruik je vingerafdruk om in te loggen'), findsOneWidget);
      });
    });
  });
}