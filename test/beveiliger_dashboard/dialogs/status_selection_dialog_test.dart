import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/beveiliger_dashboard/dialogs/status_selection_dialog.dart';
import 'package:securyflex_app/shared/models/guard_status.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('StatusSelectionDialog Tests', () {
    testWidgets('should display dialog with current status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStatusSelectionDialog(
                  context: context,
                  currentStatus: GuardStatus.beschikbaar,
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Status Wijzigen'), findsOneWidget);
      expect(find.text('Kies je huidige beschikbaarheidsstatus'), findsOneWidget);
      
      // Verify current status is marked
      expect(find.text('Huidig'), findsOneWidget);
      expect(find.text('Beschikbaar'), findsWidgets);
    });

    testWidgets('should display all available status options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStatusSelectionDialog(
                  context: context,
                  currentStatus: GuardStatus.beschikbaar,
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify all status options are present
      expect(find.text('Beschikbaar'), findsWidgets);
      expect(find.text('Bezet'), findsOneWidget);
      expect(find.text('Niet Beschikbaar'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      
      // Verify 'Geschorst' is not shown (admin-only)
      expect(find.text('Geschorst'), findsNothing);
    });

    testWidgets('should allow status selection', (WidgetTester tester) async {
      GuardStatus? selectedStatus;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedStatus = await showStatusSelectionDialog(
                    context: context,
                    currentStatus: GuardStatus.beschikbaar,
                  );
                },
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Select 'Bezet' status
      await tester.tap(find.text('Bezet'));
      await tester.pumpAndSettle();

      // Verify selection is highlighted
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tap update button
      await tester.tap(find.text('Wijzigen'));
      await tester.pumpAndSettle();

      // Verify the selected status was captured
      expect(selectedStatus, isNotNull);
      // Note: In a real test, we would mock the service call
    });

    testWidgets('should show error message on update failure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: StatusSelectionDialog(
              currentStatus: GuardStatus.beschikbaar,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select different status
      await tester.tap(find.text('Bezet'));
      await tester.pumpAndSettle();

      // Try to update (will fail in test environment)
      await tester.tap(find.text('Wijzigen'));
      await tester.pumpAndSettle();

      // Wait for error to appear
      await tester.pump(Duration(seconds: 1));

      // Verify error message appears
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should disable update button when no changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: StatusSelectionDialog(
              currentStatus: GuardStatus.beschikbaar,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the update button
      final updateButton = find.text('Status Wijzigen');
      expect(updateButton, findsOneWidget);

      // Button should be disabled when no changes are made
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: updateButton,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('should close dialog on cancel', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStatusSelectionDialog(
                  context: context,
                  currentStatus: GuardStatus.beschikbaar,
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Status Wijzigen'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Status Wijzigen'), findsNothing);
    });

    testWidgets('should close dialog on close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStatusSelectionDialog(
                  context: context,
                  currentStatus: GuardStatus.beschikbaar,
                ),
                child: Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Status Wijzigen'), findsOneWidget);

      // Tap close button (X)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Status Wijzigen'), findsNothing);
    });

    testWidgets('should show loading state during update', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.guard),
          home: Scaffold(
            body: StatusSelectionDialog(
              currentStatus: GuardStatus.beschikbaar,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select different status
      await tester.tap(find.text('Bezet'));
      await tester.pumpAndSettle();

      // Tap update button
      await tester.tap(find.text('Status Wijzigen'));
      await tester.pump(); // Don't settle to catch loading state

      // Verify loading state
      expect(find.text('Bijwerken...'), findsOneWidget);
    });

    group('Status Descriptions', () {
      testWidgets('should show correct descriptions for each status', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: StatusSelectionDialog(
                currentStatus: GuardStatus.beschikbaar,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify status descriptions
        expect(find.text('Je bent beschikbaar voor nieuwe opdrachten'), findsOneWidget);
        expect(find.text('Je bent momenteel bezig met een opdracht'), findsOneWidget);
        expect(find.text('Je bent tijdelijk niet beschikbaar'), findsOneWidget);
        expect(find.text('Je bent offline en niet zichtbaar voor bedrijven'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: SecuryFlexTheme.getTheme(UserRole.guard),
            home: Scaffold(
              body: StatusSelectionDialog(
                currentStatus: GuardStatus.beschikbaar,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify dialog has proper semantics
        expect(find.byType(Dialog), findsOneWidget);
        
        // Verify buttons are accessible
        expect(find.text('Annuleren'), findsOneWidget);
        expect(find.text('Status Wijzigen'), findsOneWidget);
      });
    });
  });
}
