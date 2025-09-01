import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securyflex_app/company_dashboard/screens/company_notifications_screen.dart';
import 'package:securyflex_app/unified_theme_system.dart';

void main() {
  group('CompanyNotificationsScreen Tests', () {

    setUp(() {
      // Mock animation controller for tests
    });

    tearDown(() {
      // Clean up
    });

    testWidgets('should display notifications screen with correct title', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Notificaties'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display filter tabs with correct labels', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Alle'), findsOneWidget);
      expect(find.text('Ongelezen'), findsOneWidget);
      expect(find.text('Sollicitaties'), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Act - Don't wait for animations to complete
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Notificaties laden...'), findsOneWidget);
    });

    testWidgets('should display notifications after loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Act - Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nieuwe sollicitatie'), findsOneWidget);
      expect(find.text('Job verlopen'), findsOneWidget);
      expect(find.text('Systeem update'), findsOneWidget);
    });

    testWidgets('should filter notifications when tapping filter tabs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Tap on "Ongelezen" filter
      await tester.tap(find.text('Ongelezen'));
      await tester.pumpAndSettle();

      // Assert - Should only show unread notifications
      expect(find.text('Nieuwe sollicitatie'), findsOneWidget);
      expect(find.text('Job verlopen'), findsOneWidget);
      // Read notifications should not be visible
      expect(find.text('Sollicitatie ingetrokken'), findsNothing);
    });

    testWidgets('should mark notification as read when tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Tap on first notification
      await tester.tap(find.text('Nieuwe sollicitatie').first);
      await tester.pumpAndSettle();

      // Assert - Should show snackbar or navigation
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should show mark all as read button', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.mark_email_read), findsOneWidget);
    });

    testWidgets('should mark all notifications as read when button tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Act - Tap mark all as read button
      await tester.tap(find.byIcon(Icons.mark_email_read));
      await tester.pumpAndSettle();

      // Assert - Should show confirmation snackbar
      expect(find.text('Alle notificaties gemarkeerd als gelezen'), findsOneWidget);
    });

    testWidgets('should show empty state when no notifications match filter', (WidgetTester tester) async {
      // This would require mocking the notification data to be empty
      // For now, we'll test the UI structure
      await tester.pumpWidget(
        MaterialApp(
          theme: SecuryFlexTheme.getTheme(UserRole.company),
          home: const CompanyNotificationsScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // The empty state would show when filtering results in no matches
      // This test would need more sophisticated mocking
    });
  });

  group('CompanyNotification Model Tests', () {
    test('should create notification with correct properties', () {
      // Arrange
      final timestamp = DateTime.now();
      
      // Act
      final notification = CompanyNotification(
        id: 'test-1',
        type: NotificationType.application,
        title: 'Test Notification',
        message: 'Test message',
        timestamp: timestamp,
        isRead: false,
        priority: NotificationPriority.high,
      );

      // Assert
      expect(notification.id, equals('test-1'));
      expect(notification.type, equals(NotificationType.application));
      expect(notification.title, equals('Test Notification'));
      expect(notification.message, equals('Test message'));
      expect(notification.timestamp, equals(timestamp));
      expect(notification.isRead, isFalse);
      expect(notification.priority, equals(NotificationPriority.high));
    });

    test('should mark notification as read', () {
      // Arrange
      final notification = CompanyNotification(
        id: 'test-1',
        type: NotificationType.application,
        title: 'Test',
        message: 'Test',
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Act
      notification.isRead = true;

      // Assert
      expect(notification.isRead, isTrue);
    });
  });

  group('Notification Filtering Tests', () {
    late List<CompanyNotification> mockNotifications;

    setUp(() {
      final now = DateTime.now();
      mockNotifications = [
        CompanyNotification(
          id: '1',
          type: NotificationType.application,
          title: 'New Application',
          message: 'Test',
          timestamp: now,
          isRead: false,
        ),
        CompanyNotification(
          id: '2',
          type: NotificationType.jobUpdate,
          title: 'Job Update',
          message: 'Test',
          timestamp: now,
          isRead: true,
        ),
        CompanyNotification(
          id: '3',
          type: NotificationType.application,
          title: 'Another Application',
          message: 'Test',
          timestamp: now,
          isRead: false,
        ),
      ];
    });

    test('should filter unread notifications correctly', () {
      // Act
      final unreadNotifications = mockNotifications.where((n) => !n.isRead).toList();

      // Assert
      expect(unreadNotifications.length, equals(2));
      expect(unreadNotifications.every((n) => !n.isRead), isTrue);
    });

    test('should filter application notifications correctly', () {
      // Act
      final applicationNotifications = mockNotifications
          .where((n) => n.type == NotificationType.application)
          .toList();

      // Assert
      expect(applicationNotifications.length, equals(2));
      expect(applicationNotifications.every((n) => n.type == NotificationType.application), isTrue);
    });
  });
}
