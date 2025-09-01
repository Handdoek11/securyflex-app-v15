import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:securyflex_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Beveiliger Workflow Integration Tests', () {
    testWidgets('complete beveiliger dashboard workflow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to fully load
      await tester.pump(const Duration(seconds: 2));

      // Verify app starts correctly
      expect(find.byType(MaterialApp), findsOneWidget);

      // Look for main navigation or login screen
      // This will depend on your app's initial state
      await tester.pumpAndSettle();

      // If there's a login screen, handle it
      if (find.text('Login').evaluate().isNotEmpty) {
        await _performLogin(tester);
      }

      // Navigate to beveiliger dashboard
      await _navigateToDashboard(tester);

      // Test dashboard interactions
      await _testDashboardInteractions(tester);

      // Test navigation between tabs
      await _testTabNavigation(tester);

      // Test marketplace functionality
      await _testMarketplaceWorkflow(tester);

      // Test profile functionality
      await _testProfileWorkflow(tester);
    });

    testWidgets('beveiliger shift management workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to dashboard
      await _navigateToDashboard(tester);

      // Test shift control widget
      await _testShiftControlWorkflow(tester);

      // Test active jobs interaction
      await _testActiveJobsWorkflow(tester);

      // Test earnings tracking
      await _testEarningsWorkflow(tester);
    });

    testWidgets('beveiliger job application workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to marketplace
      await _navigateToMarketplace(tester);

      // Test job browsing
      await _testJobBrowsing(tester);

      // Test job application process
      await _testJobApplication(tester);

      // Test favorites functionality
      await _testFavoritesWorkflow(tester);
    });

    testWidgets('beveiliger profile management workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to profile
      await _navigateToProfile(tester);

      // Test profile viewing
      await _testProfileViewing(tester);

      // Test profile editing
      await _testProfileEditing(tester);

      // Test certification management
      await _testCertificationManagement(tester);
    });
  });
}

/// Helper function to perform login if needed
Future<void> _performLogin(WidgetTester tester) async {
  // Look for email/username field
  final emailField = find.byType(TextField).first;
  if (emailField.evaluate().isNotEmpty) {
    await tester.enterText(emailField, 'guard@securyflex.nl');
    await tester.pump();
  }

  // Look for password field
  final passwordFields = find.byType(TextField);
  if (passwordFields.evaluate().length > 1) {
    await tester.enterText(passwordFields.at(1), 'guard123');
    await tester.pump();
  }

  // Tap login button
  final loginButton = find.text('Login').first;
  if (loginButton.evaluate().isNotEmpty) {
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }
}

/// Helper function to navigate to dashboard
Future<void> _navigateToDashboard(WidgetTester tester) async {
  // Look for dashboard tab or navigation
  final dashboardTab = find.text('Dashboard');
  if (dashboardTab.evaluate().isNotEmpty) {
    await tester.tap(dashboardTab);
    await tester.pumpAndSettle();
  }

  // Verify we're on the dashboard
  expect(find.text('Dashboard'), findsWidgets);
}

/// Helper function to test dashboard interactions
Future<void> _testDashboardInteractions(WidgetTester tester) async {
  // Test shift control widget interaction
  final shiftButton = find.text('SHIFT STARTEN');
  if (shiftButton.evaluate().isNotEmpty) {
    await tester.tap(shiftButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // Test quick actions
  final quickActionButtons = find.byType(InkWell);
  if (quickActionButtons.evaluate().isNotEmpty) {
    await tester.tap(quickActionButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Test earnings card interaction
  final earningsCard = find.textContaining('€');
  if (earningsCard.evaluate().isNotEmpty) {
    await tester.tap(earningsCard.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Scroll through dashboard
  await tester.drag(find.byType(ListView), const Offset(0, -200));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Helper function to test tab navigation
Future<void> _testTabNavigation(WidgetTester tester) async {
  final tabs = ['Dashboard', 'Planning', 'Jobs', 'Chat', 'Profiel'];
  
  for (final tabName in tabs) {
    final tab = find.text(tabName);
    if (tab.evaluate().isNotEmpty) {
      await tester.tap(tab);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      
      // Verify we're on the correct tab
      expect(find.text(tabName), findsWidgets);
    }
  }
}

/// Helper function to navigate to marketplace
Future<void> _navigateToMarketplace(WidgetTester tester) async {
  final jobsTab = find.text('Jobs');
  if (jobsTab.evaluate().isNotEmpty) {
    await tester.tap(jobsTab);
    await tester.pumpAndSettle();
  }
}

/// Helper function to test marketplace workflow
Future<void> _testMarketplaceWorkflow(WidgetTester tester) async {
  await _navigateToMarketplace(tester);

  // Test job browsing
  await _testJobBrowsing(tester);

  // Test search functionality
  final searchField = find.byType(TextField);
  if (searchField.evaluate().isNotEmpty) {
    await tester.enterText(searchField.first, 'beveiliging');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  // Test filter functionality
  final filterButton = find.byIcon(Icons.filter_list);
  if (filterButton.evaluate().isNotEmpty) {
    await tester.tap(filterButton);
    await tester.pumpAndSettle();
    
    // Close filter if opened
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to test job browsing
Future<void> _testJobBrowsing(WidgetTester tester) async {
  // Scroll through job list
  final jobList = find.byType(ListView);
  if (jobList.evaluate().isNotEmpty) {
    await tester.drag(jobList, const Offset(0, -100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Tap on a job card
  final jobCards = find.byType(InkWell);
  if (jobCards.evaluate().isNotEmpty) {
    await tester.tap(jobCards.first);
    await tester.pumpAndSettle();
    
    // Go back if job details opened
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to test job application
Future<void> _testJobApplication(WidgetTester tester) async {
  // Look for apply button
  final applyButton = find.text('Solliciteren');
  if (applyButton.evaluate().isNotEmpty) {
    await tester.tap(applyButton.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Helper function to test favorites workflow
Future<void> _testFavoritesWorkflow(WidgetTester tester) async {
  // Test favorite button
  final favoriteButton = find.byIcon(Icons.favorite_border);
  if (favoriteButton.evaluate().isNotEmpty) {
    await tester.tap(favoriteButton.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Navigate to favorites screen
  final favoritesButton = find.byIcon(Icons.favorite);
  if (favoritesButton.evaluate().isNotEmpty) {
    await tester.tap(favoritesButton);
    await tester.pumpAndSettle();
    
    // Go back
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to navigate to profile
Future<void> _navigateToProfile(WidgetTester tester) async {
  final profileTab = find.text('Profiel');
  if (profileTab.evaluate().isNotEmpty) {
    await tester.tap(profileTab);
    await tester.pumpAndSettle();
  }
}

/// Helper function to test profile workflow
Future<void> _testProfileWorkflow(WidgetTester tester) async {
  await _navigateToProfile(tester);
  await _testProfileViewing(tester);
  await _testProfileEditing(tester);
}

/// Helper function to test profile viewing
Future<void> _testProfileViewing(WidgetTester tester) async {
  // Scroll through profile
  final profileList = find.byType(ListView);
  if (profileList.evaluate().isNotEmpty) {
    await tester.drag(profileList, const Offset(0, -100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Verify profile sections are visible
  expect(find.textContaining('Persoonlijke'), findsWidgets);
  expect(find.textContaining('Prestatie'), findsWidgets);
}

/// Helper function to test profile editing
Future<void> _testProfileEditing(WidgetTester tester) async {
  // Look for edit buttons
  final editButtons = find.text('Bewerken');
  if (editButtons.evaluate().isNotEmpty) {
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();
    
    // Go back if edit screen opened
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }
}

/// Helper function to test certification management
Future<void> _testCertificationManagement(WidgetTester tester) async {
  // Look for certification section
  final certificationSection = find.textContaining('Certificering');
  if (certificationSection.evaluate().isNotEmpty) {
    await tester.tap(certificationSection.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Helper function to test shift control workflow
Future<void> _testShiftControlWorkflow(WidgetTester tester) async {
  // Test shift start/stop
  final shiftButton = find.textContaining('SHIFT');
  if (shiftButton.evaluate().isNotEmpty) {
    await tester.tap(shiftButton.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    
    // Test shift stop if it started
    final stopButton = find.text('SHIFT BEËINDIGEN');
    if (stopButton.evaluate().isNotEmpty) {
      await tester.tap(stopButton);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  }
}

/// Helper function to test active jobs workflow
Future<void> _testActiveJobsWorkflow(WidgetTester tester) async {
  // Look for active jobs section
  final activeJobsSection = find.textContaining('Actieve');
  if (activeJobsSection.evaluate().isNotEmpty) {
    await tester.tap(activeJobsSection.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Helper function to test earnings workflow
Future<void> _testEarningsWorkflow(WidgetTester tester) async {
  // Look for earnings section
  final earningsSection = find.textContaining('Verdiensten');
  if (earningsSection.evaluate().isNotEmpty) {
    await tester.tap(earningsSection.first);
    await tester.pumpAndSettle();
    
    // Go back if earnings details opened
    final backButton = find.byIcon(Icons.arrow_back);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }
}
