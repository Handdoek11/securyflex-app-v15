# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SecuryFlex is a Flutter-based security job marketplace app connecting security guards (beveiligers) with security companies in the Netherlands. The app uses Firebase for backend services and follows Dutch regulations and compliance requirements.

**Current Status**: GoRouter 2.0 migration completed (100%). All Navigator 1.0 patterns have been converted to GoRouter 2.0 with StatefulShellRoute for main navigation, proper parameter passing, and custom transitions.

## Development Commands

### Essential Commands
```bash
# Analyze code for issues (REQUIRED before commits)
flutter analyze

# Run tests
flutter test
flutter test test/specific_test.dart           # Run single test file
flutter test --name "test name pattern"       # Run specific test

# Build for different platforms
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build windows      # Windows desktop app

# Run the app with environment variables
flutter run --dart-define-from-file=.env     # Run with Firebase config
flutter run -d chrome      # Run on Chrome (web)
flutter run -d windows     # Run on Windows
flutter run -d chrome --hot                  # Hot reload on Chrome
flutter run -d windows --hot                 # Hot reload on Windows

# Clean and get dependencies
flutter clean
flutter pub get

# Generate code with build_runner
dart run build_runner build
dart run build_runner build --delete-conflicting-outputs  # Force rebuild

# Firebase deployment (from functions directory)
npm run init-production    # Initialize Firestore production data
firebase deploy            # Deploy to Firebase
```

### Firebase Setup
1. Run `setup_firebase_env.bat` to create `.env.example`
2. Copy `.env.example` to `.env`
3. Add your Firebase configuration from Firebase Console
4. Run app with `flutter run --dart-define-from-file=.env`
5. Never commit `.env` to version control

### Testing Commands
```bash
# Security-specific tests
dart test_runner_security.dart               # Run comprehensive security tests
flutter test test/security/                  # Run all security tests
flutter test test/auth/                      # Run authentication tests

# BLoC tests
flutter test test/*/bloc/*_test.dart         # Run all BLoC tests

# Integration tests
flutter test integration_test/
```

### Code Quality Requirements
Before any commit, ensure:
- `flutter analyze` returns 0 compilation errors (warnings acceptable)
- All tests pass with `flutter test`
- Memory usage stays under 150MB average
- No console errors in debug mode

## Architecture Overview

### User Roles & Dashboards
The app supports two primary user types with separate dashboards:

1. **Security Guards (Beveiligers)** - `/lib/beveiliger_*`
   - Dashboard: `beveiliger_dashboard/modern_beveiliger_dashboard_v2.dart`
   - Main navigation hub: `beveiliger_dashboard_home.dart`
   - Features: shift management, earnings tracking, certificate management, job applications

2. **Security Companies** - `/lib/company_*`
   - Dashboard: `company_dashboard/modern_company_dashboard.dart`
   - Main navigation hub: `company_dashboard_home.dart`
   - Features: job posting, team management, analytics, application review

### State Management & Navigation
- **Navigation**: Pure GoRouter 2.0 implementation with StatefulShellRoute for persistent navigation state
- **State Management**: Flutter BLoC pattern throughout with `*/bloc/` directories
- **Repository Pattern**: Data access abstraction in `*/repository/` directories  
- **Services Layer**: Business logic encapsulation in `*/services/` directories
- **Route Configuration**: Centralized in `lib/routing/app_router.dart` with role-based routing

### Core Systems Architecture

**Authentication & Security** (`/lib/auth/`)
- Multi-factor authentication (SMS, TOTP, biometric via `local_auth`)
- BSN (Dutch Social Security Number) validation with `BSNSecurityService`
- Certificate management for security guards (WPBR, VCA, BHV, EHBO)
- KVK (Chamber of Commerce) validation for companies
- AES-GCM encryption for sensitive data storage
- Document upload service with secure file handling

**Job Marketplace** (`/lib/marketplace/`)
- Job discovery with Dutch postcode integration via `geocoding`
- Certificate-based job matching algorithm
- Real-time application tracking with Firestore
- Favorites management with local caching
- Enhanced job service with analytics integration
- Static job repository for demo/testing data

**Chat & Communication** (`/lib/chat/`)
- Real-time messaging using Firebase Firestore streams
- File attachments via Firebase Storage
- Typing indicators and read receipts
- Background message handler for push notifications
- Assignment context integration for job-related conversations
- Presence service for online/offline status

**Payments & Billing** (`/lib/billing/` and `/lib/payments/`)
- Dutch BTW (21%) tax calculations
- Payment webhooks for transaction processing
- SEPA banking integration with IBAN validation
- ZZP (freelancer) compliance and automated invoicing
- Integration with payment providers
- Financial reporting and analytics

**Schedule & Time Tracking** (`/lib/schedule/`)
- CAO (Collective Labor Agreement) compliance checking
- GPS-based time tracking with end-to-end encryption
- Location consent service for privacy compliance
- Shift management and swapping functionality
- Leave request system with approval workflows
- Privacy-focused location tracking service

**Notifications & Alerts** (`/lib/beveiliger_notificaties/`)
- Certificate expiration alerts with multi-stage warnings (90, 60, 30, 7, 1 day)
- Push notification service integration
- Notification preferences management
- Guard-specific notification service

### Design System

**Unified Components** (`/lib/unified_components/`)
- Material 3 design system
- Premium glass morphism effects
- Consistent spacing and typography
- Smart tab bar with badge overlays

**Theme System**
- Light/dark mode support
- Dutch locale (nl_NL) throughout
- WorkSans and Roboto fonts
- Consistent color tokens in `unified_design_tokens.dart`

### Performance & Memory Management
- **AppPerformanceOptimizer**: Comprehensive performance monitoring and optimization
- **MemoryLeakMonitoringSystem**: Real-time detection of memory leaks and resource usage
- **AnimationControllerMonitor**: Prevents animation controller memory leaks with automatic disposal tracking
- **SharedAnimationController**: Optimized animation system achieving 87% memory reduction
- Tab performance monitoring with smart caching strategies
- Image caching via `cached_network_image` with CDN optimization
- Widget tree depth maintained ≤4 levels for optimal performance
- Target: <150MB average memory usage in production

### Security & Compliance
- **BSNSecurityService**: Dutch Social Security Number validation and verification
- **AESGCMCryptoService**: End-to-end encryption for sensitive data
- **FirebaseSecurityService**: Cryptographic validation of Firebase configuration
- **BiometricAuthService**: Secure biometric authentication with fallback options
- **GDPRComplianceService**: Full GDPR/AVG compliance with data export/deletion
- **LocationCryptoService**: GPS data encryption for privacy-compliant tracking
- Debug information sanitization to prevent data leakage

### Testing Architecture
- **Comprehensive test structure** in `/test/` mirroring `/lib/` structure
- **Security tests**: Dedicated security testing suite in `test/security/`
- **BLoC tests**: Using `bloc_test` package for state management testing
- **Integration tests**: Critical user workflows and cross-service interactions
- **Accessibility tests**: WCAG compliance validation
- **Mock services**: Extensive mocking with `mocktail` and `mockito`
- **Test runner**: `test_runner_security.dart` for security-focused test execution

## Dutch Market Specifics

- All text uses Dutch language (nl_NL locale)
- Postcode format: 1234 AB (4 digits, space, 2 letters)
- BTW (VAT) calculations at 21%
- CAO arbeidsrecht (labor law) compliance
- KVK number validation for companies
- DigiD integration considerations
- WPBR certificate requirements for security guards

## Firebase Configuration

- Firestore for data storage with Dutch privacy compliance
- Firebase Auth with multi-provider support
- Cloud Storage for file uploads
- Firebase Messaging for push notifications
- Security rules enforcing data privacy

## Data Flow & Integration Patterns

### Service Integration Hierarchy
1. **Core Services**: Firebase, Analytics, Performance monitoring
2. **Security Layer**: BSN validation, encryption, biometric auth
3. **Business Logic**: Job matching, payment processing, schedule management
4. **UI Layer**: BLoC state management, unified components
5. **Platform Services**: Notifications, location services, file handling

### Key Integration Points
- **AuthService** → **BSNSecurityService** → User validation pipeline
- **JobMatchingService** → **CertificateManagementService** → Job recommendations
- **PaymentService** → **ComplianceService** → Dutch financial regulations
- **ChatService** → **NotificationService** → Real-time communications
- **ScheduleService** → **LocationService** → Privacy-compliant tracking

### Caching Strategy
- **Profile data**: 15-minute TTL with smart invalidation
- **Job listings**: Real-time Firestore with local fallback
- **Certificate data**: Secure local storage with encryption
- **Analytics events**: Batched uploads with offline queue
- **Map data**: CDN caching with Dutch postcode optimization

## Workflow Management

### Key Workflow Services
- **WorkflowOrchestrationService**: Coordinates complex multi-step processes
- **ApplicationWorkflow**: Manages job application lifecycle
- **PaymentWorkflow**: Handles payment processing and compliance
- **CertificateWorkflow**: Manages certificate verification and renewal

### State Management Patterns
- **BLoC Pattern**: All feature state management using `flutter_bloc`
- **Repository Pattern**: Data access abstraction layer
- **Service Layer**: Business logic encapsulation
- **Event-driven**: Cross-service communication via events

## Critical Architecture Files

### Foundation
- `main.dart`: App initialization, Firebase setup, performance optimization
- `unified_theme_system.dart`: Material 3 theme with Dutch design tokens
- `unified_design_tokens.dart`: Complete design system (v2.0.0)
- `firebase_options.dart`: Platform-specific Firebase configuration

### Core Services
- `auth/auth_service.dart`: Authentication orchestration and user management
- `auth/services/bsn_security_service.dart`: Dutch BSN validation and security
- `core/firebase_security_service.dart`: Firebase security and configuration validation
- `core/performance/app_performance_optimizer.dart`: Performance monitoring system

### Business Logic
- `marketplace/services/job_matching_service.dart`: Certificate-based job matching
- `billing/services/payment_integration_service.dart`: Dutch payment compliance
- `schedule/services/location_crypto_service.dart`: Encrypted location tracking
- `chat/services/notification_service.dart`: Multi-platform notification delivery

### Navigation & Routing
- `routing/app_router.dart`: Main GoRouter 2.0 configuration with StatefulShellRoute
- `modern_dashboard_routes.dart`: Dashboard routing with CustomTransitionPage patterns
- `routing/app_routes.dart`: Route constants and path definitions
- `routing/route_guards.dart`: Authentication and authorization guards