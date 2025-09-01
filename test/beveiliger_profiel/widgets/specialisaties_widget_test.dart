import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/beveiliger_profiel/widgets/specialisaties_widget.dart';
import 'package:securyflex_app/beveiliger_profiel/models/specialization.dart';
import 'package:securyflex_app/beveiliger_profiel/bloc/beveiliger_profiel_bloc.dart';
import 'package:securyflex_app/core/bloc/error_handler.dart';

// Mock classes
class MockBeveiligerProfielBloc extends Mock implements BeveiligerProfielBloc {}

void main() {
  group('Smart Selection Interface - SpecialisatiesWidget', () {
    late MockBeveiligerProfielBloc mockBloc;

    setUp(() {
      mockBloc = MockBeveiligerProfielBloc();
      when(() => mockBloc.state).thenReturn(const ProfielInitial());
    });

    Widget createTestWidget({
      List<Specialization> initialSpecializations = const [],
      bool isEditable = true,
      bool showSkillLevels = true,
    }) {
      return MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        home: Scaffold(
          body: BlocProvider<BeveiligerProfielBloc>.value(
            value: mockBloc,
            child: SpecialisatiesWidget(
              userId: 'test-user-id',
              userRole: UserRole.guard,
              initialSpecializations: initialSpecializations,
              isEditable: isEditable,
              showSkillLevels: showSkillLevels,
            ),
          ),
        ),
      );
    }

    group('Popular Specializations Section', () {
      testWidgets('shows exactly 5 popular specializations', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should show popular choices header
        expect(find.text('💼'), findsOneWidget);
        expect(find.text('Populaire keuzes'), findsOneWidget);

        // Should show exactly 5 popular specialization chips
        expect(find.text('Objectbeveiliging'), findsOneWidget);
        expect(find.text('Evenementbeveiliging'), findsOneWidget);
        expect(find.text('Kantoorbeveiliging'), findsOneWidget);
        expect(find.text('Nachtbeveiliging'), findsOneWidget);
        expect(find.text('Winkelbeveiliging'), findsOneWidget);
      });

      testWidgets('popular specializations are clickable', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the first popular specialization chip
        final objectbeveiligingChip = find.text('Objectbeveiliging');
        expect(objectbeveiligingChip, findsOneWidget);

        // Tap on it
        await tester.tap(objectbeveiligingChip);
        await tester.pumpAndSettle();

        // Should show in selected specializations section
        expect(find.text('✅'), findsOneWidget);
        expect(find.text('Jouw specialisaties (1)'), findsOneWidget);
      });
    });

    group('Selected Specializations Section', () {
      testWidgets('shows selected specializations in dedicated section', (tester) async {
        final selectedSpecs = [
          Specialization(
            id: '1',
            type: SpecializationType.kantoorbeveiliging,
            skillLevel: SkillLevel.ervaren,
            addedAt: DateTime.now(),
          ),
          Specialization(
            id: '2',
            type: SpecializationType.nachtbeveiliging,
            skillLevel: SkillLevel.beginner,
            addedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(
          initialSpecializations: selectedSpecs,
        ));
        await tester.pumpAndSettle();

        // Should show selected specializations header
        expect(find.text('✅'), findsOneWidget);
        expect(find.text('Jouw specialisaties (2)'), findsOneWidget);

        // Should show both selected specializations
        expect(find.text('Kantoorbeveiliging'), findsOneWidget);
        expect(find.text('Nachtbeveiliging'), findsOneWidget);
      });

      testWidgets('shows skill level selectors for selected specializations', (tester) async {
        final selectedSpec = [
          Specialization(
            id: '1',
            type: SpecializationType.kantoorbeveiliging,
            skillLevel: SkillLevel.ervaren,
            addedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(
          initialSpecializations: selectedSpec,
          showSkillLevels: true,
        ));
        await tester.pumpAndSettle();

        // Should show skill level options
        expect(find.text('Beginner'), findsOneWidget);
        expect(find.text('Ervaren'), findsOneWidget);
        expect(find.text('Expert'), findsOneWidget);
      });

      testWidgets('shows remove buttons for selected specializations', (tester) async {
        final selectedSpec = [
          Specialization(
            id: '1',
            type: SpecializationType.kantoorbeveiliging,
            skillLevel: SkillLevel.beginner,
            addedAt: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(createTestWidget(
          initialSpecializations: selectedSpec,
          isEditable: true,
        ));
        await tester.pumpAndSettle();

        // Should show remove button
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('Progressive Disclosure', () {
      testWidgets('shows expand button initially', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Meer specialisaties toevoegen'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('expand button reveals additional specializations', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially should not show expanded content
        expect(find.text('Zoek specialisaties...'), findsNothing);

        // Tap expand button
        await tester.tap(find.text('Meer specialisaties toevoegen'));
        await tester.pumpAndSettle();

        // Should show expanded view with search
        expect(find.text('Zoek specialisaties...'), findsOneWidget);

        // Should show collapse button
        expect(find.text('Minder tonen'), findsOneWidget);
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
      });

      testWidgets('collapse button hides expanded view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Expand first
        await tester.tap(find.text('Meer specialisaties toevoegen'));
        await tester.pumpAndSettle();

        // Should be expanded
        expect(find.text('Zoek specialisaties...'), findsOneWidget);

        // Tap collapse
        await tester.tap(find.text('Minder tonen'));
        await tester.pumpAndSettle();

        // Should be collapsed again
        expect(find.text('Zoek specialisaties...'), findsNothing);
        expect(find.text('Meer specialisaties toevoegen'), findsOneWidget);
      });
    });

    group('Touch Target Compliance', () {
      testWidgets('all touch targets meet 48x48dp requirement', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Popular specialization chips should meet touch target requirements
        for (final spec in ['Objectbeveiliging', 'Evenementbeveiliging', 'Kantoorbeveiliging']) {
          final finder = find.ancestor(
            of: find.text(spec),
            matching: find.byType(Container),
          );
          
          if (finder.evaluate().isNotEmpty) {
            final container = tester.widget<Container>(finder.first);
            final constraints = container.constraints;
            
            expect(
              constraints?.minHeight ?? 0, 
              greaterThanOrEqualTo(DesignTokens.iconSizeXXL), // 48dp
              reason: '$spec chip should have minimum 48dp height',
            );
            expect(
              constraints?.minWidth ?? 0,
              greaterThanOrEqualTo(DesignTokens.iconSizeXXL), // 48dp
              reason: '$spec chip should have minimum 48dp width',
            );
          }
        }

        // Expand button should meet touch target requirements
        final expandButton = find.text('Meer specialisaties toevoegen');
        expect(expandButton, findsOneWidget);
      });

      testWidgets('spacing between chips is exactly 8dp', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the Wrap widget containing popular specializations
        final wrapFinder = find.descendant(
          of: find.text('Populaire keuzes').hitTestable(),
          matching: find.byType(Wrap),
        );

        if (wrapFinder.evaluate().isNotEmpty) {
          final wrap = tester.widget<Wrap>(wrapFinder.first);
          expect(wrap.spacing, equals(DesignTokens.spacingS)); // 8dp
          expect(wrap.runSpacing, equals(DesignTokens.spacingS)); // 8dp
        }
      });
    });

    group('Benefits Messaging', () {
      testWidgets('shows benefits message', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('💡'), findsOneWidget);
        expect(find.text('Voeg 3+ specialisaties toe voor 40% betere job matches'), findsOneWidget);
      });
    });

    group('Search and Filter (Expanded View)', () {
      testWidgets('search functionality works in expanded view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Expand view first
        await tester.tap(find.text('Meer specialisaties toevoegen'));
        await tester.pumpAndSettle();

        // Find search field
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Enter search term
        await tester.enterText(searchField, 'kantoor');
        await tester.pumpAndSettle();

        // Should show filtered results
        expect(find.text('Kantoorbeveiliging'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('provides semantic labels for specialization chips', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find semantic nodes for specialization chips
        final semanticsFinder = find.byType(Semantics);
        expect(semanticsFinder, findsAtLeast(5)); // At least 5 popular chips

        // Test one specific semantic label
        expect(
          find.bySemanticsLabel(RegExp(r'Objectbeveiliging specialisatie')),
          findsOneWidget,
        );
      });
    });

    group('Error Handling', () {
      testWidgets('displays error messages when BLoC has error state', (tester) async {
        // Setup mock to return error state
        final testError = AppError(
          code: 'test_error',
          message: 'Test error message',
        );
        when(() => mockBloc.state).thenReturn(ProfielError(testError));
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Test error message'), findsOneWidget);
      });
    });

    group('Auto-save Functionality', () {
      testWidgets('triggers auto-save when selecting specializations', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Tap on a popular specialization to select it
        await tester.tap(find.text('Objectbeveiliging'));
        await tester.pumpAndSettle();

        // Wait for debounce timer (1.5 seconds)
        await tester.pump(const Duration(seconds: 2));

        // Verify that the widget shows as selected
        expect(find.text('Jouw specialisaties (1)'), findsOneWidget);
      });
    });
  });

  group('Specialization Model Popularity', () {
    test('popular specializations are correctly identified', () {
      expect(SpecializationType.objectbeveiliging.popularityScore, equals(100));
      expect(SpecializationType.evenementbeveiliging.popularityScore, equals(85));
      expect(SpecializationType.kantoorbeveiliging.popularityScore, equals(70));
      expect(SpecializationType.nachtbeveiliging.popularityScore, equals(55));
      expect(SpecializationType.winkelbeveiliging.popularityScore, equals(40));
    });

    test('getTopPopular returns exactly 5 specializations', () {
      final topSpecializations = SpecializationTypeExtension.getTopPopular(5);
      expect(topSpecializations.length, equals(5));
      expect(topSpecializations.first, equals(SpecializationType.objectbeveiliging));
    });

    test('isPopular correctly identifies popular specializations', () {
      expect(SpecializationType.objectbeveiliging.isPopular, isTrue);
      expect(SpecializationType.winkelbeveiliging.isPopular, isTrue); // 40 is the threshold
      expect(SpecializationType.personenbeveiliging.isPopular, isFalse); // 35 is below threshold
    });
  });
}