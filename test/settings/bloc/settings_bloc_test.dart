import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:securyflex_app/settings/bloc/settings_bloc.dart';
import 'package:securyflex_app/settings/bloc/settings_event.dart';
import 'package:securyflex_app/settings/bloc/settings_state.dart';
import 'package:securyflex_app/settings/repository/settings_repository.dart';

// Mock classes
class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  group('SettingsBloc Tests', () {
    late MockSettingsRepository mockRepository;
    late SettingsLoaded mockSettings;

    setUpAll(() {
      // Register fallback value for SettingsLoaded
      registerFallbackValue(SettingsLoaded(
        notificationSettings: const NotificationSettings(),
        appPreferences: const AppPreferences(),
        privacySettings: const PrivacySettings(),
        securitySettings: const SecuritySettings(),
        dataUsageSettings: const DataUsageSettings(),
        lastUpdated: DateTime.now(),
      ));
    });

    setUp(() {
      mockRepository = MockSettingsRepository();
      
      // Create mock settings
      mockSettings = SettingsLoaded(
        notificationSettings: const NotificationSettings(
          notificationsEnabled: true,
          messageNotifications: true,
          fileNotifications: true,
          systemNotifications: true,
          soundEnabled: true,
          vibrationEnabled: true,
          showPreview: true,
          quietHoursEnabled: false,
        ),
        appPreferences: const AppPreferences(
          language: 'nl',
          theme: 'system',
          darkMode: false,
          autoSync: true,
          offlineMode: false,
          syncInterval: 300,
        ),
        privacySettings: const PrivacySettings(
          readReceipts: true,
          typingIndicators: true,
          lastSeenVisible: true,
          profilePhotoVisible: true,
          statusVisible: true,
          analyticsEnabled: true,
          crashReportsEnabled: true,
        ),
        securitySettings: const SecuritySettings(
          biometricEnabled: false,
          pinEnabled: false,
          autoLockEnabled: false,
          autoLockTimeout: 300,
          screenCaptureBlocked: false,
        ),
        dataUsageSettings: const DataUsageSettings(
          wifiOnlyDownloads: false,
          autoDownloadImages: true,
          autoDownloadVideos: false,
          autoDownloadDocuments: true,
          maxFileSize: 10485760,
          compressImages: true,
          lowDataMode: false,
        ),
        lastUpdated: DateTime.now(),
      );
      
      // Setup default mock returns
      when(() => mockRepository.loadSettings()).thenAnswer((_) async => mockSettings);
      when(() => mockRepository.saveSettings(any())).thenAnswer((_) async {});
      when(() => mockRepository.resetSettings()).thenAnswer((_) async {});
    });

    test('initial state is SettingsInitial', () {
      final settingsBloc = SettingsBloc(repository: mockRepository);
      expect(settingsBloc.state, equals(const SettingsInitial()));
      settingsBloc.close();
    });

    group('SettingsInitialize', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when initialization succeeds',
        build: () => SettingsBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const SettingsInitialize()),
        expect: () => [
          const SettingsLoading(loadingMessage: 'Instellingen laden...'),
          isA<SettingsLoaded>()
              .having((state) => state.notificationSettings.notificationsEnabled, 'notificationsEnabled', true)
              .having((state) => state.appPreferences.language, 'language', 'nl')
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', false),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsError] when initialization fails',
        build: () {
          when(() => mockRepository.loadSettings()).thenThrow(Exception('Load failed'));
          return SettingsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const SettingsInitialize()),
        expect: () => [
          const SettingsLoading(loadingMessage: 'Instellingen laden...'),
          isA<SettingsError>(),
        ],
      );
    });

    group('LoadSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when loading succeeds',
        build: () => SettingsBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [
          const SettingsLoading(loadingMessage: 'Instellingen laden...'),
          isA<SettingsLoaded>(),
        ],
      );
    });

    group('SaveSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsSaved, SettingsLoaded] when saving succeeds',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings.copyWith(hasUnsavedChanges: true),
        act: (bloc) => bloc.add(const SaveSettings()),
        wait: const Duration(milliseconds: 200), // Wait for delayed state emission
        expect: () => [
          isA<SettingsSaved>()
              .having((state) => state.updatedSettings.hasUnsavedChanges, 'hasUnsavedChanges', false),
          isA<SettingsLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', false),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsError when saving fails',
        build: () {
          when(() => mockRepository.saveSettings(any())).thenThrow(Exception('Save failed'));
          return SettingsBloc(repository: mockRepository);
        },
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const SaveSettings()),
        expect: () => [
          isA<SettingsError>(),
        ],
      );
    });

    group('ResetSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when reset succeeds',
        build: () => SettingsBloc(repository: mockRepository),
        act: (bloc) => bloc.add(const ResetSettings()),
        expect: () => [
          const SettingsLoading(loadingMessage: 'Instellingen resetten...'),
          isA<SettingsLoaded>()
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', false),
        ],
      );
    });

    group('UpdateNotificationSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates notification settings and marks as unsaved',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const UpdateNotificationSettings(
          notificationsEnabled: false,
          soundEnabled: false,
        )),
        expect: () => [
          isA<SettingsLoaded>()
              .having((state) => state.notificationSettings.notificationsEnabled, 'notificationsEnabled', false)
              .having((state) => state.notificationSettings.soundEnabled, 'soundEnabled', false)
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateQuietHours', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates quiet hours settings',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const UpdateQuietHours(
          quietHoursEnabled: true,
          startHour: 23,
          startMinute: 30,
          endHour: 7,
          endMinute: 0,
        )),
        expect: () => [
          isA<SettingsLoaded>()
              .having((state) => state.notificationSettings.quietHoursEnabled, 'quietHoursEnabled', true)
              .having((state) => state.notificationSettings.quietHoursStartHour, 'startHour', 23)
              .having((state) => state.notificationSettings.quietHoursStartMinute, 'startMinute', 30)
              .having((state) => state.notificationSettings.quietHoursEndHour, 'endHour', 7)
              .having((state) => state.notificationSettings.quietHoursEndMinute, 'endMinute', 0)
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateAppPreferences', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates app preferences',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const UpdateAppPreferences(
          language: 'en',
          theme: 'dark',
          darkMode: true,
        )),
        expect: () => [
          isA<SettingsLoaded>()
              .having((state) => state.appPreferences.language, 'language', 'en')
              .having((state) => state.appPreferences.theme, 'theme', 'dark')
              .having((state) => state.appPreferences.darkMode, 'darkMode', true)
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdatePrivacySettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates privacy settings',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const UpdatePrivacySettings(
          readReceipts: false,
          analyticsEnabled: false,
        )),
        expect: () => [
          isA<SettingsLoaded>()
              .having((state) => state.privacySettings.readReceipts, 'readReceipts', false)
              .having((state) => state.privacySettings.analyticsEnabled, 'analyticsEnabled', false)
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateSecuritySettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates security settings',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const UpdateSecuritySettings(
          biometricEnabled: true,
          pinEnabled: true,
          autoLockEnabled: true,
          autoLockTimeout: 600,
        )),
        expect: () => [
          isA<SettingsLoaded>()
              .having((state) => state.securitySettings.biometricEnabled, 'biometricEnabled', true)
              .having((state) => state.securitySettings.pinEnabled, 'pinEnabled', true)
              .having((state) => state.securitySettings.autoLockEnabled, 'autoLockEnabled', true)
              .having((state) => state.securitySettings.autoLockTimeout, 'autoLockTimeout', 600)
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('UpdateDataUsageSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates data usage settings',
        build: () => SettingsBloc(repository: mockRepository),
        seed: () => mockSettings,
        act: (bloc) => bloc.add(const UpdateDataUsageSettings(
          wifiOnlyDownloads: true,
          autoDownloadVideos: true,
          lowDataMode: true,
        )),
        expect: () => [
          isA<SettingsLoaded>()
              .having((state) => state.dataUsageSettings.wifiOnlyDownloads, 'wifiOnlyDownloads', true)
              .having((state) => state.dataUsageSettings.autoDownloadVideos, 'autoDownloadVideos', true)
              .having((state) => state.dataUsageSettings.lowDataMode, 'lowDataMode', true)
              .having((state) => state.hasUnsavedChanges, 'hasUnsavedChanges', true),
        ],
      );
    });

    group('ExportSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits SettingsExported when export succeeds',
        build: () {
          when(() => mockRepository.exportSettings()).thenAnswer((_) async => {
            'version': 1,
            'notifications': {'notificationsEnabled': true},
          });
          return SettingsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const ExportSettings()),
        expect: () => [
          isA<SettingsExported>()
              .having((state) => state.exportedData.containsKey('version'), 'has version', true),
        ],
      );
    });

    group('ImportSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsImported, SettingsLoaded] when import succeeds',
        build: () {
          when(() => mockRepository.importSettings(any())).thenAnswer((_) async => mockSettings);
          return SettingsBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(ImportSettings(const {
          'version': 1,
          'notifications': {'notificationsEnabled': true},
        })),
        wait: const Duration(milliseconds: 200),
        expect: () => [
          const SettingsLoading(loadingMessage: 'Instellingen importeren...'),
          isA<SettingsImported>()
              .having((state) => state.importedCount, 'importedCount', 1),
          isA<SettingsLoaded>(),
        ],
      );
    });

    group('Convenience Getters', () {
      test('isLoaded returns true when state is SettingsLoaded', () {
        final settingsBloc = SettingsBloc(repository: mockRepository);
        settingsBloc.emit(mockSettings);
        
        expect(settingsBloc.isLoaded, isTrue);
        settingsBloc.close();
      });

      test('isLoading returns true when state is SettingsLoading', () {
        final settingsBloc = SettingsBloc(repository: mockRepository);
        settingsBloc.emit(const SettingsLoading());
        
        expect(settingsBloc.isLoading, isTrue);
        settingsBloc.close();
      });

      test('hasUnsavedChanges returns correct value', () {
        final settingsBloc = SettingsBloc(repository: mockRepository);
        settingsBloc.emit(mockSettings.copyWith(hasUnsavedChanges: true));
        
        expect(settingsBloc.hasUnsavedChanges, isTrue);
        settingsBloc.close();
      });

      test('notificationSettings returns correct settings', () {
        final settingsBloc = SettingsBloc(repository: mockRepository);
        settingsBloc.emit(mockSettings);
        
        expect(settingsBloc.notificationSettings.notificationsEnabled, isTrue);
        settingsBloc.close();
      });
    });

    group('Dutch Localization', () {
      test('SettingsLoaded provides correct Dutch status messages', () {
        final settingsWithNotificationsOff = mockSettings.copyWith(
          notificationSettings: mockSettings.notificationSettings.copyWith(
            notificationsEnabled: false,
          ),
        );
        
        expect(settingsWithNotificationsOff.settingsSummary, contains('Notificaties uitgeschakeld'));
        
        final settingsWithQuietHours = mockSettings.copyWith(
          notificationSettings: mockSettings.notificationSettings.copyWith(
            quietHoursEnabled: true,
          ),
        );
        
        expect(settingsWithQuietHours.settingsSummary, contains('Stille uren actief'));
      });

      test('SettingsSaved provides Dutch success message', () {
        final savedState = SettingsSaved(
          updatedSettings: SettingsLoaded(
            notificationSettings: const NotificationSettings(),
            appPreferences: const AppPreferences(),
            privacySettings: const PrivacySettings(),
            securitySettings: const SecuritySettings(),
            dataUsageSettings: const DataUsageSettings(),
            lastUpdated: DateTime.now(),
          ),
        );
        
        expect(savedState.localizedSuccessMessage, equals('Instellingen opgeslagen'));
      });

      test('SettingsExported provides Dutch success message', () {
        const exportedState = SettingsExported(
          exportPath: '/test/path',
          exportedData: {},
        );
        
        expect(exportedState.localizedSuccessMessage, contains('Instellingen geëxporteerd naar'));
      });

      test('SettingsImported provides Dutch success message', () {
        final importedState = SettingsImported(
          importedSettings: SettingsLoaded(
            notificationSettings: const NotificationSettings(),
            appPreferences: const AppPreferences(),
            privacySettings: const PrivacySettings(),
            securitySettings: const SecuritySettings(),
            dataUsageSettings: const DataUsageSettings(),
            lastUpdated: DateTime.now(),
          ),
          importedCount: 5,
        );
        
        expect(importedState.localizedSuccessMessage, equals('5 instellingen succesvol geïmporteerd'));
      });
    });
  });
}
