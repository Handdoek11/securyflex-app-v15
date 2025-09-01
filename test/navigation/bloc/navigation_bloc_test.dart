import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:securyflex_app/navigation/bloc/navigation_bloc.dart';
import 'package:securyflex_app/navigation/bloc/navigation_event.dart';
import 'package:securyflex_app/navigation/bloc/navigation_state.dart';
import 'package:securyflex_app/auth/bloc/auth_bloc.dart';
import 'package:securyflex_app/auth/bloc/auth_state.dart';

// Mock classes
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('NavigationBloc Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      
      // Setup default mock returns
      when(() => mockAuthBloc.stream).thenAnswer((_) => Stream.value(const AuthUnauthenticated()));
      when(() => mockAuthBloc.state).thenReturn(const AuthUnauthenticated());
    });

    test('initial state is NavigationInitial', () {
      final navigationBloc = NavigationBloc();
      expect(navigationBloc.state, equals(const NavigationInitial()));
      navigationBloc.close();
    });

    group('NavigationInitialize', () {
      blocTest<NavigationBloc, NavigationState>(
        'emits [NavigationLoading, NavigationReady] when initialization succeeds for guard',
        build: () => NavigationBloc(), // No AuthBloc to avoid auto-reset
        act: (bloc) => bloc.add(const NavigationInitialize(
          userRole: 'guard',
          userId: 'test-guard-id',
        )),
        expect: () => [
          const NavigationLoading(loadingMessage: 'Navigatie initialiseren...'),
          isA<NavigationReady>()
              .having((state) => state.userRole, 'userRole', 'guard')
              .having((state) => state.userId, 'userId', 'test-guard-id')
              .having((state) => state.currentTabIndex, 'currentTabIndex', 0)
              .having((state) => state.tabs.length, 'tabs.length', 5), // Guard has 5 tabs
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits [NavigationLoading, NavigationReady] when initialization succeeds for company',
        build: () => NavigationBloc(),
        act: (bloc) => bloc.add(const NavigationInitialize(
          userRole: 'company',
          userId: 'test-company-id',
        )),
        expect: () => [
          const NavigationLoading(loadingMessage: 'Navigatie initialiseren...'),
          isA<NavigationReady>()
              .having((state) => state.userRole, 'userRole', 'company')
              .having((state) => state.userId, 'userId', 'test-company-id')
              .having((state) => state.tabs.length, 'tabs.length', 5), // Company has 5 tabs
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits [NavigationLoading, NavigationReady] when initialization succeeds for admin',
        build: () => NavigationBloc(),
        act: (bloc) => bloc.add(const NavigationInitialize(
          userRole: 'admin',
          userId: 'test-admin-id',
        )),
        expect: () => [
          const NavigationLoading(loadingMessage: 'Navigatie initialiseren...'),
          isA<NavigationReady>()
              .having((state) => state.userRole, 'userRole', 'admin')
              .having((state) => state.userId, 'userId', 'test-admin-id')
              .having((state) => state.tabs.length, 'tabs.length', 5), // Admin has 5 tabs
        ],
      );
    });

    group('NavigateToTab', () {
      blocTest<NavigationBloc, NavigationState>(
        'navigates to valid tab index',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ),
        act: (bloc) => bloc.add(const NavigateToTab(tabIndex: 2)),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.currentTabIndex, 'currentTabIndex', 2)
              .having((state) => state.navigationHistory.length, 'navigationHistory.length', 0), // History cleared on tab switch
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'emits NavigationError for invalid tab index',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ),
        act: (bloc) => bloc.add(const NavigateToTab(tabIndex: 10)), // Invalid index
        expect: () => [
          isA<NavigationError>()
              .having((state) => state.error.code, 'error.code', 'invalid_tab_index'),
        ],
      );
    });

    group('NavigateToScreen', () {
      blocTest<NavigationBloc, NavigationState>(
        'navigates to screen and updates history',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
          currentScreenName: 'guard_dashboard',
        ),
        act: (bloc) => bloc.add(const NavigateToScreen(
          screenName: 'job_details',
          arguments: {'jobId': 'SJ001'},
        )),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.currentScreenName, 'currentScreenName', 'job_details')
              .having((state) => state.currentScreenArguments?['jobId'], 'jobId', 'SJ001')
              .having((state) => state.navigationHistory.length, 'navigationHistory.length', 1),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'replaces current route when replaceCurrentRoute is true',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
          currentScreenName: 'guard_dashboard',
        ),
        act: (bloc) => bloc.add(const NavigateToScreen(
          screenName: 'job_details',
          arguments: {'jobId': 'SJ001'},
          replaceCurrentRoute: true,
        )),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.currentScreenName, 'currentScreenName', 'job_details')
              .having((state) => state.navigationHistory.length, 'navigationHistory.length', 0), // No history added
        ],
      );
    });

    group('NavigateBack', () {
      blocTest<NavigationBloc, NavigationState>(
        'navigates back to previous screen',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: [
            NavigationHistoryItem(
              screenName: 'guard_dashboard',
              displayName: 'Dashboard',
              timestamp: DateTime.now(),
            ),
          ],
          currentScreenName: 'job_details',
        ),
        act: (bloc) => bloc.add(const NavigateBack()),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.currentScreenName, 'currentScreenName', 'guard_dashboard')
              .having((state) => state.navigationHistory.length, 'navigationHistory.length', 0),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'does nothing when no history available',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
          currentScreenName: 'guard_dashboard',
        ),
        act: (bloc) => bloc.add(const NavigateBack()),
        expect: () => [], // No state change
      );
    });

    group('UpdateTabBadge', () {
      blocTest<NavigationBloc, NavigationState>(
        'updates badge count for specific tab',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ),
        act: (bloc) => bloc.add(const UpdateTabBadge(
          tabIndex: 2,
          badgeCount: 5,
        )),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.tabBadgeCounts[2], 'tabBadgeCounts[2]', 5)
              .having((state) => state.totalBadgeCount, 'totalBadgeCount', 5),
        ],
      );

      blocTest<NavigationBloc, NavigationState>(
        'removes badge when count is 0',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {2: 5},
          navigationHistory: const [],
        ),
        act: (bloc) => bloc.add(const UpdateTabBadge(
          tabIndex: 2,
          badgeCount: 0,
        )),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.tabBadgeCounts.containsKey(2), 'tabBadgeCounts contains key 2', false)
              .having((state) => state.totalBadgeCount, 'totalBadgeCount', 0),
        ],
      );
    });

    group('UpdateNotificationBadges', () {
      blocTest<NavigationBloc, NavigationState>(
        'updates badges based on notification types',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ),
        act: (bloc) => bloc.add(const UpdateNotificationBadges({
          'chat': 3,
          'job': 2,
        })),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.getBadgeCount(2), 'chat badge count', 3) // Chat is index 2
              .having((state) => state.getBadgeCount(1), 'jobs badge count', 2) // Jobs is index 1
              .having((state) => state.totalBadgeCount, 'totalBadgeCount', 5),
        ],
      );
    });

    group('HandleDeepLink', () {
      blocTest<NavigationBloc, NavigationState>(
        'handles deep link and navigates to screen',
        build: () => NavigationBloc(),
        seed: () => NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ),
        act: (bloc) => bloc.add(const HandleDeepLink(
          deepLink: 'securyflex://job_details?jobId=SJ001',
        )),
        expect: () => [
          isA<NavigationReady>()
              .having((state) => state.currentScreenName, 'currentScreenName', 'job_details')
              .having((state) => state.currentScreenArguments?['jobId'], 'jobId', 'SJ001'),
        ],
      );
    });

    group('Convenience Getters', () {
      test('isReady returns true when state is NavigationReady', () {
        final navigationBloc = NavigationBloc();
        navigationBloc.emit(NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ));

        expect(navigationBloc.isReady, isTrue);
        navigationBloc.close();
      });

      test('isLoading returns true when state is NavigationLoading', () {
        final navigationBloc = NavigationBloc();
        navigationBloc.emit(const NavigationLoading());

        expect(navigationBloc.isLoading, isTrue);
        navigationBloc.close();
      });

      test('currentTabIndex returns correct tab index', () {
        final navigationBloc = NavigationBloc();
        navigationBloc.emit(NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 2,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        ));

        expect(navigationBloc.currentTabIndex, equals(2));
        navigationBloc.close();
      });

      test('canNavigateBack returns correct value', () {
        final navigationBloc = NavigationBloc();
        navigationBloc.emit(NavigationReady(
          userRole: 'guard',
          userId: 'test-user-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: [
            NavigationHistoryItem(
              screenName: 'previous_screen',
              displayName: 'Previous',
              timestamp: DateTime.now(),
            ),
          ],
        ));

        expect(navigationBloc.canNavigateBack, isTrue);
        navigationBloc.close();
      });
    });

    group('Dutch Localization', () {
      test('NavigationReady provides correct Dutch role display names', () {
        final guardState = NavigationReady(
          userRole: 'guard',
          userId: 'guard-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getGuardTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        );
        
        final companyState = NavigationReady(
          userRole: 'company',
          userId: 'company-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getCompanyTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        );
        
        final adminState = NavigationReady(
          userRole: 'admin',
          userId: 'admin-id',
          currentTabIndex: 0,
          tabs: NavigationConfig.getAdminTabs(),
          tabBadgeCounts: const {},
          navigationHistory: const [],
        );
        
        expect(guardState.userRoleDisplayName, equals('Beveiliger'));
        expect(companyState.userRoleDisplayName, equals('Bedrijf'));
        expect(adminState.userRoleDisplayName, equals('Beheerder'));
      });

      test('NavigationConfig provides correct Dutch tab labels', () {
        final guardTabs = NavigationConfig.getGuardTabs();
        final companyTabs = NavigationConfig.getCompanyTabs();
        final adminTabs = NavigationConfig.getAdminTabs();
        
        // Check guard tabs
        expect(guardTabs[0].dutchLabel, equals('Dashboard'));
        expect(guardTabs[1].dutchLabel, equals('Opdrachten'));
        expect(guardTabs[2].dutchLabel, equals('Chat'));
        expect(guardTabs[3].dutchLabel, equals('Planning'));
        expect(guardTabs[4].dutchLabel, equals('Profiel'));
        
        // Check company tabs
        expect(companyTabs[0].dutchLabel, equals('Dashboard'));
        expect(companyTabs[1].dutchLabel, equals('Opdrachten'));
        expect(companyTabs[2].dutchLabel, equals('Beveiligers'));
        expect(companyTabs[3].dutchLabel, equals('Chat'));
        expect(companyTabs[4].dutchLabel, equals('Profiel'));
        
        // Check admin tabs
        expect(adminTabs[0].dutchLabel, equals('Dashboard'));
        expect(adminTabs[1].dutchLabel, equals('Gebruikers'));
        expect(adminTabs[2].dutchLabel, equals('Opdrachten'));
        expect(adminTabs[3].dutchLabel, equals('Analytics'));
        expect(adminTabs[4].dutchLabel, equals('Instellingen'));
      });
    });
  });
}
