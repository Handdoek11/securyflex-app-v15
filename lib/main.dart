import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'auth/auth_service.dart';
import 'auth/services/bsn_security_service.dart';
import 'auth/enhanced_glassmorphic_login_screen.dart';
import 'beveiliger_dashboard/beveiliger_dashboard_home.dart';
import 'company_dashboard/company_dashboard_home.dart';
import 'unified_theme_system.dart';
import 'chat/bloc/chat_bloc.dart';
import 'routing/app_router.dart';
import 'chat/services/notification_service.dart';
import 'chat/services/presence_service.dart';
import 'chat/services/assignment_integration_service.dart';
import 'chat/services/background_message_handler.dart';
import 'core/bloc/bloc_observer.dart';
import 'core/performance/app_performance_optimizer.dart';
import 'core/memory_leak_monitoring_system.dart';
import 'core/firebase_security_service.dart';
import 'core/firebase_app_check_service.dart';
import 'core/services/firebase_analytics_service.dart';
import 'core/platform_intelligence/adaptive_ui_service.dart';
import 'core/caching/platform_cache_manager.dart';
import 'core/performance/platform_performance_monitor.dart';
import 'beveiliger_notificaties/services/certificate_alert_service.dart';
import 'unified_design_tokens.dart';
import 'core/responsive/responsive_provider.dart';
import 'core/responsive/responsive_performance_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance and memory monitoring
  final performanceOptimizer = AppPerformanceOptimizer();
  performanceOptimizer.initialize();
  
  // Initialize memory leak monitoring system
  MemoryLeakMonitoringSystem.instance.initialize();
  
  // Initialize responsive performance monitoring
  ResponsivePerformanceMonitor.instance.initialize();


  // Optimize app startup performance
  await AppPerformanceOptimizer.optimizeAppStartup();

  // Set up BLoC observer for comprehensive logging and analytics
  Bloc.observer = SecuryFlexBlocObserver();

  // Initialize Firebase with Dutch locale support (prevent duplicate initialization)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized, continuing...');
    } else {
      rethrow;
    }
  }

  // Initialize Firebase App Check BEFORE any other Firebase services
  // NOTE: Temporarily disabled during development due to ReCAPTCHA configuration
  if (!kDebugMode) {
    try {
      await FirebaseAppCheckService.instance.initialize();
    } catch (e) {
      debugPrint('Firebase App Check initialization failed: $e');
      throw Exception('Critical security error: App Check failed to initialize');
    }
  } else {
    debugPrint('🛡️ Firebase App Check SKIPPED in development mode');
  }

  // Initialize Firebase security validation
  try {
    await FirebaseSecurityService.initialize();
  } catch (e) {
    debugPrint('Firebase security validation failed: $e');
    // In production, this should halt the app
    // In development, continue with warnings
  }

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Dutch locale data for date formatting
  await initializeDateFormatting('nl_NL', null);

  // Initialize authentication state
  await AuthService.initialize();

  // Initialize BSN Security Service for GDPR compliance
  try {
    await BSNSecurityService.initialize();
  } catch (e) {
    debugPrint('BSN Security Service initialization failed: $e');
    // Continue app startup - BSN service will use fallback modes
  }

  // Initialize Firebase Analytics for user behavior tracking
  try {
    await FirebaseAnalyticsService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase Analytics initialization failed: $e');
    // Continue app startup - analytics is optional
  }

  // Initialize Platform Intelligence, Caching, and Performance Monitoring
  try {
    await AdaptiveUIService.instance.initialize();
    await PlatformCacheManager.instance.initialize();
    await PlatformPerformanceMonitor.instance.initialize();
    debugPrint('✅ Platform intelligence, caching, and performance monitoring initialized');
  } catch (e) {
    debugPrint('Platform services initialization failed: $e');
    // Continue app startup - platform optimizations are optional
  }

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize the GoRouter
  AppRouter.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  /// Initialize notification and presence services
  void _initializeNotifications() {
    if (AuthService.isLoggedIn) {
      // Initialize notifications
      NotificationService.instance.initialize(
        onMessageTap: (conversationId, messageId) {
          // Navigate to specific message in conversation
          // This would be implemented with proper navigation
          debugPrint('Navigate to message $messageId in conversation $conversationId');
        },
        onConversationTap: (conversationId) {
          // Navigate to conversation
          // This would be implemented with proper navigation
          debugPrint('Navigate to conversation $conversationId');
        },
      );

      // Initialize presence service
      PresenceService.instance.initialize();

      // Initialize assignment integration service
      AssignmentIntegrationService.instance.initialize();

      // Initialize certificate alert service for all authenticated users
      _initializeCertificateAlerts();
    }
  }

  /// Initialize certificate alert service with daily monitoring
  void _initializeCertificateAlerts() async {
    try {
      // Import certificate alert service
      final certificateAlertService = CertificateAlertService.instance;
      
      // Initialize with background daily checks
      await certificateAlertService.initialize();
      
      debugPrint('Certificate alert service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing certificate alert service: $e');
      // Don't block app initialization if certificate alerts fail
    }
  }

  /// Get appropriate home screen based on user role
  Widget _getHomeForUserRole() {
    switch (AuthService.currentUserType.toLowerCase()) {
      case 'guard':
        return BeveiligerDashboardHome();
      case 'company':
        return CompanyDashboardHome();
      case 'admin':
        return BeveiligerDashboardHome();
      default:
        return BeveiligerDashboardHome();
    }
  }

  /// Get appropriate theme based on user role
  UserRole _getUserRole() {
    if (!AuthService.isLoggedIn) return UserRole.guard;

    switch (AuthService.currentUserType.toLowerCase()) {
      case 'company':
        return UserRole.company;
      case 'admin':
        return UserRole.admin;
      case 'guard':
      default:
        return UserRole.guard;
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: !kIsWeb && Platform.isAndroid
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: DesignTokens.colorWhite,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    return ResponsiveWrapper(
      debounceTime: const Duration(milliseconds: 100), // Performance optimized debouncing
      child: MaterialApp.router(
        title: 'SecuryFlex',
        debugShowCheckedModeBanner: false,
        locale: const Locale('nl', 'NL'),
        theme: SecuryFlexTheme.getTheme(_getUserRole()), // Dynamic theme based on user role
        routerConfig: AppRouter.router,
      ),
    );
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return int.parse(hexColor, radix: 16);
  }
}
