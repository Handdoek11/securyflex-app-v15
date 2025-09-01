# 🚀 CLAUDE CODE (CLI) + ULTRATHINK COMPLETE GUIDE - SECURYFLEX

## 📋 EXECUTIVE SUMMARY

Deze uitgebreide guide biedt **complete prompt templates** voor het ontwikkelen van **ALLE SecuryFlex pages** met **Claude Code (CLI)** en **Ultrathink** reasoning. Gebaseerd op officiële Anthropic best practices en community-verified technieken.

### 🎯 **SCOPE & DOELSTELLINGEN**
- **85+ Page Templates**: Complete prompts voor alle SecuryFlex features
- **Officiële Ultrathink Integration**: "think" < "think hard" < "think harder" < "ultrathink"
- **CLAUDE.md Best Practices**: Optimale context management
- **Nederlandse Business Logic**: KvK, BTW, CAO, WPBR compliance
- **100% Design Consistency**: Unified Design System enforcement
- **Enterprise Quality**: 90%+ test coverage, 0 flutter analyze issues

---

## 🏗️ **PROJECT ARCHITECTURE CONTEXT**

### **SecuryFlex Platform Overview**
```
SecuryFlex = Nederlandse Security Marketplace Platform
├── 3 User Roles: Guard/Company/Admin
├── Enterprise-grade Security & Compliance
├── Dutch-first Business Logic (KvK, BTW, WPBR)
├── Unified Design System (100% implemented)
├── BLoC Architecture + Firebase Backend
└── 68+ Tests + Performance Standards
```

### **Bestaande Systemen Inventory**
```
BESTAANDE PAGES (uitbreiden/verbeteren):
├── auth/ (login, registration, profile)
├── beveiliger_dashboard/ (dashboard home, widgets)
├── company_dashboard/ (dashboard home, analytics)
├── marketplace/ (jobs, job details, filters)
└── chat/ (messaging, conversations)

BESTAANDE SERVICES:
├── AuthService, FirebaseAuthService
├── JobPostingService, ApplicationService
├── ChatService, NotificationService
├── BeveiligerProfielService, CompanyService
├── DashboardService, AnalyticsService
└── Nederlandse business logic (KvK, postal codes)

UNIFIED DESIGN SYSTEM:
├── DesignTokens (colors, spacing, typography)
├── UnifiedHeader, UnifiedButton, UnifiedCard
├── Role-based theming (Guard/Company/Admin)
└── 100% template consistency
```

---

## 🧠 **CLAUDE CODE (CLI) + ULTRATHINK METHODOLOGY**

### **Officiële Ultrathink Levels (Anthropic Verified)**
Volgens de officiële Anthropic documentatie zijn er 4 thinking levels:

```
"think" < "think hard" < "think harder" < "ultrathink"
```

Elk level alloceert progressief meer "thinking budget" voor Claude om alternatieven grondig te evalueren.

### **Core Principles**
1. **CLAUDE.md First**: Centraal configuratiebestand voor context
2. **Ultrathink for Complex Logic**: Gebruik alleen bij complexe problemen
3. **Codebase-Retrieval First**: Altijd beginnen met bestaande code analyse
4. **System Reuse**: Maximaal gebruik van bestaande componenten
5. **Quality Gates**: Strikte kwaliteitseisen per feature

### **Universal Prompt Structure**
```markdown
# 🎯 CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Role: [Guard/Company/Admin]
Feature: [Specific feature name]
Existing Systems: [List relevant existing systems]

# 🧠 ULTRATHINK REASONING
Please think hard about this implementation and make a comprehensive plan.

## Business Logic Analysis
[Step-by-step business requirements analysis]

## Technical Implementation Planning
[Detailed technical approach with existing systems]

## Integration Points Identification
[Cross-feature dependencies and connections]

## Risk Assessment & Edge Cases
[Potential issues and mitigation strategies]

# 🛠️ IMPLEMENTATION REQUIREMENTS
## Codebase Analysis First
Use codebase-retrieval to understand:
- Existing patterns and architecture
- Available unified components
- Current service implementations
- Testing patterns and standards

## Unified Design System Usage
- UnifiedHeader.[variant] for all headers
- UnifiedButton.[type] for all buttons
- UnifiedCard.[variant] for all cards
- DesignTokens.* for all styling values

## BLoC Architecture Patterns
- [FeatureName]Bloc extends BaseBloc
- [FeatureName]Event extends BaseEvent
- [FeatureName]State extends BaseState
- Repository pattern for data access

## Testing Requirements
- Unit Tests: 90%+ business logic coverage
- Widget Tests: 80%+ UI component coverage
- Integration Tests: Key user flows
- BLoC Tests: All state transitions

## Dutch Business Logic
- KvK validation for companies
- WPBR certificate verification for guards
- BTW calculations (21% Dutch rates)
- Nederlandse postal code validation
- CAO arbeidsrecht compliance

## Performance Standards
- App startup: <2 seconds
- Navigation: <300ms
- Memory usage: <150MB
- Flutter analyze: 0 issues

# 🎯 QUALITY GATES
- [ ] Flutter Analyze: 0 issues
- [ ] Test Coverage: 90%+ business logic
- [ ] Design Consistency: 100% unified components
- [ ] Dutch Compliance: Complete business logic
- [ ] Performance: Meets all benchmarks
- [ ] Documentation: Complete API docs
```

---

## 🔧 **CLAUDE CODE SETUP & CONFIGURATION**

### **1. CLAUDE.md Configuration**
Maak een `CLAUDE.md` bestand in de root van je SecuryFlex project:

```markdown
# SecuryFlex - Nederlandse Security Marketplace Platform

## Project Overview
- Flutter app met BLoC architecture
- 3 user roles: Guard/Company/Admin
- Nederlandse business logic (KvK, BTW, WPBR)
- Firebase backend + Firestore

## Common Commands
- `flutter run`: Start development server
- `flutter test`: Run all tests
- `flutter analyze`: Check code quality
- `flutter build apk`: Build Android APK

## Code Style Guidelines
- Use UnifiedHeader, UnifiedButton, UnifiedCard components ONLY
- Apply DesignTokens.* for ALL styling values (never hardcode)
- Follow BLoC pattern: [Feature]Bloc, [Feature]Event, [Feature]State
- Dutch localization required for all user-facing text
- 90%+ test coverage for business logic

## Architecture Patterns
- lib/[feature_name]/ directory structure
- services/ for business logic
- unified_components/ for UI components
- BLoC for state management
- Repository pattern for data access

## Testing Requirements
- Unit tests in test/[feature_name]/
- Widget tests for all screens
- Integration tests for user flows
- BLoC tests for state transitions

## Dutch Business Rules
- KvK validation for companies (8 digits)
- WPBR certificate verification for guards
- BTW calculations at 21%
- Nederlandse postal code format: 1234AB
- CAO arbeidsrecht compliance

## Performance Standards
- App startup: <2 seconds
- Navigation: <300ms
- Memory usage: <150MB
- Flutter analyze: 0 issues

## IMPORTANT REMINDERS
- ALWAYS use codebase-retrieval before making changes
- NEVER hardcode styling values - use DesignTokens.*
- ALWAYS implement role-based theming
- NEVER skip testing requirements
- ALWAYS validate Dutch business logic
```

### **2. Workflow Patterns**

#### **A. Explore, Plan, Code, Commit (Recommended)**
```
1. Ask Claude to read relevant files (use codebase-retrieval)
2. Ask Claude to think hard and make a comprehensive plan
3. Ask Claude to implement the solution
4. Ask Claude to commit and create PR
```

#### **B. Test-Driven Development**
```
1. Ask Claude to write tests based on requirements
2. Confirm tests fail
3. Ask Claude to implement code to pass tests
4. Iterate until all tests pass
```

### **3. Ultrathink Usage Guidelines**

#### **When to Use Ultrathink**
- Complex business logic (KvK validation, WPBR verification)
- Multi-role feature implementation
- Performance optimization problems
- Integration between multiple existing systems
- Dutch legal compliance requirements

#### **Ultrathink Prompt Examples**
```
"Please ultrathink this implementation and consider all edge cases for Dutch business validation"

"Think harder about the integration between beveiliger_dashboard and marketplace features"

"Please think hard about the performance implications of this real-time chat feature"
```

⚠️ **Warning**: Ultrathink increases token consumption significantly. Use only when necessary.

---

## 📱 **PAGE CATEGORIES & TEMPLATES**

### **Category 1: BESTAANDE PAGES (Uitbreiding)**
Pages die al bestaan maar uitgebreid moeten worden.

### **Category 2: NIEUWE GUARD FEATURES**
Nieuwe beveiliger-specifieke functionaliteit.

### **Category 3: NIEUWE COMPANY FEATURES**
Nieuwe bedrijf-specifieke functionaliteit.

### **Category 4: NIEUWE ADMIN FEATURES**
Nieuwe admin-specifieke functionaliteit.

### **Category 5: GEDEELDE FEATURES**
Cross-role functionaliteit zoals instellingen, hulp, juridisch.

---

## 🔐 **CATEGORY 1: BESTAANDE PAGES UITBREIDING**

### **Template: Auth System Enhancement**
```markdown
# 🎯 CLAUDE CODE (CLI) PROMPT: AUTH SYSTEM ENHANCEMENT

## CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Feature: Authentication System Enhancement
Existing Systems: auth/, AuthService, FirebaseAuthService, unified_components/
Target: Enhance existing auth with Dutch business validation

## STEP 1: CODEBASE ANALYSIS
Please use codebase-retrieval to analyze the existing authentication system:

"Analyze the current auth system implementation, including AuthService, FirebaseAuthService, registration flows, and how unified components are currently used in authentication screens."

## STEP 2: ULTRATHINK PLANNING
Please think hard about this authentication enhancement and create a comprehensive implementation plan.

### Business Logic Analysis
1. Current auth supports basic email/password + demo mode
2. Need to add KvK validation for companies (8-digit format)
3. Need to add WPBR certificate verification for guards
4. Need to add 2FA and biometric authentication
5. Need complete onboarding flow per role with Dutch compliance

### Technical Implementation Planning
1. Extend existing AuthService with Dutch validation methods
2. Add new services: KvKApiService, WPBRVerificationService
3. Enhance registration flow with role-specific validation
4. Add document upload capability for certificates
5. Integrate with existing UnifiedHeader and UnifiedButton components
6. Maintain existing BLoC architecture patterns

### Integration Points
- Connects to: ALL features (authentication required)
- Uses: Firebase Auth, Firestore, Firebase Storage
- Extends: Existing auth/ directory structure
- Integrates: Dutch business validation services
- Maintains: Current unified component usage

### Risk Assessment & Edge Cases
- KvK API rate limiting → Implement caching and retry logic
- Document upload security → Validate file types and sizes
- WPBR verification delays → Provide clear status updates
- Biometric availability → Graceful fallback to 2FA
- Network connectivity issues → Offline validation caching
- Invalid certificate formats → Comprehensive validation

## STEP 3: IMPLEMENTATION REQUIREMENTS

### Directory Structure Enhancement
```
lib/auth/
├── screens/ (existing - enhance)
│   ├── login_screen.dart (enhance with 2FA)
│   ├── registration_screen.dart (enhance with role validation)
│   └── profile_screen.dart (enhance with certificates)
├── services/ (extend existing)
│   ├── auth_service.dart (extend existing)
│   ├── kvk_api_service.dart (new)
│   ├── wpbr_verification_service.dart (new)
│   └── document_upload_service.dart (new)
├── widgets/ (enhance existing)
│   ├── role_selection_widget.dart (enhance)
│   ├── kvk_validation_widget.dart (new)
│   └── wpbr_upload_widget.dart (new)
└── models/ (extend existing)
    ├── kvk_data.dart (new)
    └── wpbr_data.dart (new)
```

### Unified Design System Usage
```dart
// Enhanced registration form with unified components
UnifiedHeader.simple(
  title: 'Registreren als Beveiliger',
  userRole: UserRole.guard,
)

UnifiedCard.standard(
  userRole: UserRole.guard,
  child: Column(
    children: [
      UnifiedInputField(
        label: 'WPBR Certificaatnummer',
        validator: WPBRValidation.validateCertificate,
        keyboardType: TextInputType.text,
      ),
      SizedBox(height: DesignTokens.spacingM),
      UnifiedButton.primary(
        text: 'Certificaat Uploaden',
        onPressed: _uploadWPBRCertificate,
        userRole: UserRole.guard,
      ),
    ],
  ),
)
```

### BLoC Architecture Enhancement
```dart
// Extend existing AuthBloc with new events
abstract class AuthEvent extends BaseEvent {
  // Existing events...

  // New Dutch validation events
  const AuthValidateKvK(String kvkNumber);
  const AuthVerifyWPBR(String certificateNumber, File certificate);
  const AuthSetupBiometric();
  const AuthEnable2FA();
}

// New states for Dutch validation
abstract class AuthState extends BaseState {
  // Existing states...

  // New validation states
  const AuthKvKValidating();
  const AuthKvKValid(KvKData kvkData);
  const AuthKvKInvalid(String error);
  const AuthWPBRVerifying();
  const AuthWPBRVerified(WPBRData wpbrData);
  const AuthWPBRInvalid(String error);
}
```

### Dutch Business Logic Implementation
```dart
// KvK validation service
class KvKApiService {
  static Future<KvKData?> validateKvK(String kvkNumber) async {
    // Validate format first (8 digits)
    if (!RegExp(r'^\d{8}$').hasMatch(kvkNumber)) {
      throw ValidationException('KvK nummer moet 8 cijfers bevatten');
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.kvk.nl/api/v1/zoeken?kvkNummer=$kvkNumber'),
        headers: {'apikey': KvKConfig.apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return KvKData.fromJson(data['resultaten'][0]);
      }
      return null;
    } catch (e) {
      throw KvKValidationException('KvK validatie mislukt: $e');
    }
  }
}

// WPBR verification service
class WPBRVerificationService {
  static Future<WPBRData?> verifyCertificate(String number, File certificate) async {
    // Validate WPBR format
    if (!RegExp(r'^WPBR-\d{6}$').hasMatch(number)) {
      throw ValidationException('WPBR nummer moet format WPBR-123456 hebben');
    }

    // Upload certificate to Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('wpbr_certificates')
        .child('${DateTime.now().millisecondsSinceEpoch}_$number.pdf');

    await storageRef.putFile(certificate);
    final downloadUrl = await storageRef.getDownloadURL();

    // Verify against WPBR database (mock implementation)
    await Future.delayed(Duration(seconds: 2));

    return WPBRData(
      certificateNumber: number,
      holderName: 'Jan de Beveiliger',
      isValid: true,
      expirationDate: DateTime.now().add(Duration(days: 1825)), // 5 years
      documentUrl: downloadUrl,
    );
  }
}
```

### Testing Strategy
```dart
// Comprehensive testing for enhanced auth
group('Enhanced Auth Tests', () {
  group('KvK Validation Tests', () {
    test('should validate correct KvK format', () async {
      final kvkData = await KvKApiService.validateKvK('12345678');
      expect(kvkData, isNotNull);
      expect(kvkData!.isActive, isTrue);
    });

    test('should reject invalid KvK format', () async {
      expect(
        () => KvKApiService.validateKvK('1234567'), // 7 digits
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('WPBR Verification Tests', () {
    test('should verify valid WPBR certificate', () async {
      final file = File('test/fixtures/wpbr_certificate.pdf');
      final wpbrData = await WPBRVerificationService.verifyCertificate('WPBR-123456', file);

      expect(wpbrData, isNotNull);
      expect(wpbrData!.isValid, isTrue);
      expect(wpbrData.certificateNumber, equals('WPBR-123456'));
    });
  });

  testWidgets('Enhanced registration should show role-specific fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        home: EnhancedRegistrationScreen(),
      ),
    );

    // Test guard-specific fields
    expect(find.text('WPBR Certificaatnummer'), findsOneWidget);
    expect(find.byType(UnifiedButton), findsWidgets);

    // Test unified component usage
    expect(find.byType(UnifiedHeader), findsOneWidget);
    expect(find.byType(UnifiedCard), findsWidgets);
  });
});
```

## STEP 4: IMPLEMENTATION WORKFLOW
1. First, extend existing AuthService with new validation methods
2. Create new services for KvK and WPBR validation
3. Enhance existing registration screens with role-specific validation
4. Add new widgets for certificate upload and validation
5. Update existing BLoC with new events and states
6. Write comprehensive tests for all new functionality
7. Ensure all unified components are used consistently
8. Validate Dutch business logic compliance

## QUALITY GATES
- [ ] Extends existing auth/ without breaking changes
- [ ] Uses UnifiedHeader, UnifiedButton, UnifiedCard consistently
- [ ] Implements proper KvK validation (8-digit format)
- [ ] Implements proper WPBR verification (WPBR-123456 format)
- [ ] Includes comprehensive error handling for all edge cases
- [ ] Maintains 90%+ test coverage for all new functionality
- [ ] Passes flutter analyze with 0 issues
- [ ] Supports all three user roles (Guard/Company/Admin)
- [ ] Includes proper Dutch localization for all new strings
- [ ] Maintains existing performance standards
```

---

## 👮 **CATEGORY 2: NIEUWE GUARD FEATURES**

### **Template: Beveiliger Opdrachten (New Feature)**
```markdown
# 🎯 CLAUDE CODE (CLI) PROMPT: BEVEILIGER OPDRACHTEN FEATURE

## CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Feature: Beveiliger Opdrachten (Job Search & Applications)
Existing Systems: marketplace/, JobPostingService, ApplicationService, unified_components/
Target: Create comprehensive job search and application system for guards

## STEP 1: CODEBASE ANALYSIS
Please use codebase-retrieval to analyze existing systems:

"Analyze the marketplace/ directory, JobPostingService, ApplicationService, and how unified components are used in existing job-related screens. Also examine the current navigation structure and BLoC patterns."

## STEP 2: ULTRATHINK PLANNING
Please ultrathink this new feature implementation and create a comprehensive plan that integrates seamlessly with existing systems.

### Business Logic Analysis
1. Guards need to search jobs by Nederlandse postcodes (1234AB format)
2. WPBR/VCA certificate matching required for job eligibility
3. Uurtarief negotiations in euros (€15-€35/hour typical range)
4. Favorite companies system for preferred employers
5. Application tracking with real-time status updates
6. Integration with existing marketplace/ and chat/ systems
7. Dutch labor law compliance (CAO Beveiliging)

### Technical Implementation Planning
1. Create new beveiliger_opdrachten/ directory following existing patterns
2. Extend existing JobPostingService with guard-specific search methods
3. Create new JobSearchService for advanced filtering and postcode logic
4. Implement PostcodeService for Nederlandse postal code validation
5. Use existing UnifiedCard, UnifiedButton, UnifiedHeader components
6. Integrate with existing chat/ for employer communication
7. Follow established BLoC architecture patterns
8. Maintain existing navigation and routing structure

### Integration Points & Dependencies
- Extends: marketplace/ (job listings and data models)
- Uses: chat/ (communication), beveiliger_profiel/ (certificate matching)
- Services: JobSearchService, ApplicationService (extend), PostcodeService
- APIs: Nederlandse Postcode API, Google Maps API (distance calculation)
- Navigation: Integrate with existing beveiliger_dashboard/ navigation
- Theming: Use UserRole.guard theming throughout

### Risk Assessment & Edge Cases
- Postcode API rate limits → Implement intelligent caching with 24h TTL
- Certificate matching complexity → Use fuzzy matching algorithms
- Large job datasets → Implement pagination (25 items per page) and lazy loading
- Real-time updates → Use Firebase listeners efficiently with proper cleanup
- Network connectivity → Implement offline caching for recent searches
- Invalid postcode formats → Comprehensive validation and user feedback
- Certificate expiration → Real-time validation and renewal reminders

## STEP 3: IMPLEMENTATION REQUIREMENTS

### Directory Structure (Following Existing Patterns)
```
lib/beveiliger_opdrachten/
├── screens/
│   ├── opdrachten_zoeken_screen.dart
│   ├── opdracht_details_screen.dart
│   ├── sollicitatie_screen.dart
│   ├── mijn_sollicitaties_screen.dart
│   ├── actieve_opdrachten_screen.dart
│   ├── opdracht_geschiedenis_screen.dart
│   └── favoriete_bedrijven_screen.dart
├── widgets/
│   ├── job_search_filters.dart
│   ├── job_card_guard.dart
│   ├── application_status_card.dart
│   ├── certificate_match_indicator.dart
│   ├── distance_calculator.dart
│   └── salary_range_slider.dart
├── services/
│   ├── job_search_service.dart
│   ├── application_service.dart (extend existing)
│   ├── postcode_service.dart
│   ├── certificate_matching_service.dart
│   └── favorites_service.dart
├── models/
│   ├── job_search_filters.dart
│   ├── application_data.dart
│   ├── certificate_match.dart
│   └── favorite_company.dart
├── bloc/
│   ├── job_search_bloc.dart
│   ├── application_bloc.dart
│   ├── favorites_bloc.dart
│   └── certificate_matching_bloc.dart
└── repositories/
    ├── job_search_repository.dart
    └── application_repository.dart
```

### Unified Design System Implementation
```dart
// Job search screen with consistent unified components
class OpdrachtZoekenScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          UnifiedHeader.animated(
            title: 'Opdrachten Zoeken',
            userRole: UserRole.guard,
            animationController: _animationController,
            actions: [
              UnifiedButton.icon(
                icon: Icons.filter_list,
                onPressed: _showFilters,
                userRole: UserRole.guard,
              ),
            ],
          ),
          // Search bar with unified styling
          Padding(
            padding: EdgeInsets.all(DesignTokens.spacingM),
            child: UnifiedInputField(
              label: 'Zoek opdrachten...',
              prefixIcon: Icons.search,
              onChanged: _onSearchChanged,
              validator: null,
            ),
          ),
          // Job list with unified cards
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
                  child: UnifiedCard.standard(
                    userRole: UserRole.guard,
                    isClickable: true,
                    onTap: () => _navigateToJobDetails(jobs[index]),
                    child: JobCardGuard(job: jobs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: UnifiedButton.floating(
        icon: Icons.bookmark,
        onPressed: _showFavorites,
        userRole: UserRole.guard,
      ),
    );
  }
}

// Job card with guard-specific information
class JobCardGuard extends StatelessWidget {
  final JobData job;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job title and company
        Row(
          children: [
            Expanded(
              child: Text(
                job.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),
            CertificateMatchIndicator(
              matchPercentage: job.certificateMatchPercentage,
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),

        // Company and location
        Row(
          children: [
            Icon(
              Icons.business,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.colorTextSecondary,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              job.companyName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.colorTextSecondary,
              ),
            ),
            Spacer(),
            Icon(
              Icons.location_on,
              size: DesignTokens.iconSizeS,
              color: DesignTokens.colorTextSecondary,
            ),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              '${job.postcode} (${job.distanceKm.toStringAsFixed(1)} km)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DesignTokens.colorTextSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),

        // Salary and action button
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.guardPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                '€${job.hourlyRate.toStringAsFixed(2)}/uur',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DesignTokens.guardPrimary,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),
            Spacer(),
            UnifiedButton.secondary(
              text: 'Solliciteren',
              onPressed: () => _applyForJob(job),
              userRole: UserRole.guard,
              size: ButtonSize.small,
            ),
          ],
        ),
      ],
    );
  }
}
```

### Nederlandse Business Logic Implementation
```dart
// Postcode service for Dutch postal codes
class PostcodeService {
  static const String _cacheKey = 'postcode_cache';
  static const Duration _cacheDuration = Duration(hours: 24);

  /// Validate Dutch postcode format (1234AB)
  static bool isValidDutchPostcode(String postcode) {
    return RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(postcode.toUpperCase());
  }

  /// Calculate distance between Dutch postcodes
  static Future<double> calculateDistance(String fromPostcode, String toPostcode) async {
    // Validate both postcodes
    if (!isValidDutchPostcode(fromPostcode) || !isValidDutchPostcode(toPostcode)) {
      throw ValidationException('Ongeldige postcode format');
    }

    // Check cache first
    final cacheKey = '${fromPostcode}_${toPostcode}';
    final cachedDistance = await _getCachedDistance(cacheKey);
    if (cachedDistance != null) {
      return cachedDistance;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.postcode.nl/distance/$fromPostcode/$toPostcode'),
        headers: {'X-API-Key': PostcodeConfig.apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final distance = data['distance'].toDouble();

        // Cache the result
        await _cacheDistance(cacheKey, distance);
        return distance;
      }

      throw PostcodeApiException('Postcode API error: ${response.statusCode}');
    } catch (e) {
      throw PostcodeApiException('Distance calculation failed: $e');
    }
  }

  /// Get postcode coordinates for map display
  static Future<PostcodeCoordinates> getCoordinates(String postcode) async {
    if (!isValidDutchPostcode(postcode)) {
      throw ValidationException('Ongeldige postcode format');
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.postcode.nl/coordinates/$postcode'),
        headers: {'X-API-Key': PostcodeConfig.apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PostcodeCoordinates.fromJson(data);
      }

      throw PostcodeApiException('Coordinates API error: ${response.statusCode}');
    } catch (e) {
      throw PostcodeApiException('Coordinates lookup failed: $e');
    }
  }

  static Future<double?> _getCachedDistance(String key) async {
    // Implementation for cache retrieval
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('${_cacheKey}_$key');
    if (cachedData != null) {
      final data = json.decode(cachedData);
      final timestamp = DateTime.parse(data['timestamp']);
      if (DateTime.now().difference(timestamp) < _cacheDuration) {
        return data['distance'].toDouble();
      }
    }
    return null;
  }

  static Future<void> _cacheDistance(String key, double distance) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'distance': distance,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString('${_cacheKey}_$key', json.encode(data));
  }
}

// Certificate matching service for job requirements
class CertificateMatchingService {
  /// Check if guard's certificates match job requirements
  static CertificateMatch checkJobRequirements(JobData job, BeveiligerProfielData profiel) {
    final matches = <String>[];
    final missing = <String>[];
    final expiringSoon = <String>[];

    // Check WPBR requirement
    if (job.requiresWPBR) {
      final wpbrCert = profiel.certificates.firstWhere(
        (cert) => cert.type == CertificateType.wpbr,
        orElse: () => null,
      );

      if (wpbrCert != null && wpbrCert.isValid) {
        matches.add('WPBR Beveiligingsbeambte');

        // Check if expiring within 6 months
        if (wpbrCert.expirationDate.difference(DateTime.now()).inDays < 180) {
          expiringSoon.add('WPBR Beveiligingsbeambte');
        }
      } else {
        missing.add('WPBR Beveiligingsbeambte');
      }
    }

    // Check VCA requirement
    if (job.requiresVCA) {
      final vcaCert = profiel.certificates.firstWhere(
        (cert) => cert.type == CertificateType.vca,
        orElse: () => null,
      );

      if (vcaCert != null && vcaCert.isValid) {
        matches.add('VCA Veiligheid');

        if (vcaCert.expirationDate.difference(DateTime.now()).inDays < 180) {
          expiringSoon.add('VCA Veiligheid');
        }
      } else {
        missing.add('VCA Veiligheid');
      }
    }

    // Check BHV requirement
    if (job.requiresBHV) {
      final bhvCert = profiel.certificates.firstWhere(
        (cert) => cert.type == CertificateType.bhv,
        orElse: () => null,
      );

      if (bhvCert != null && bhvCert.isValid) {
        matches.add('BHV Bedrijfshulpverlening');

        if (bhvCert.expirationDate.difference(DateTime.now()).inDays < 180) {
          expiringSoon.add('BHV Bedrijfshulpverlening');
        }
      } else {
        missing.add('BHV Bedrijfshulpverlening');
      }
    }

    final totalRequired = (job.requiresWPBR ? 1 : 0) +
                         (job.requiresVCA ? 1 : 0) +
                         (job.requiresBHV ? 1 : 0);

    final matchPercentage = totalRequired > 0
        ? (matches.length / totalRequired * 100)
        : 100.0;

    return CertificateMatch(
      matchPercentage: matchPercentage,
      matchedCertificates: matches,
      missingCertificates: missing,
      expiringSoonCertificates: expiringSoon,
      isEligible: missing.isEmpty,
      requiresRenewal: expiringSoon.isNotEmpty,
    );
  }

  /// Get certificate recommendations for better job matching
  static List<CertificateRecommendation> getRecommendations(BeveiligerProfielData profiel) {
    final recommendations = <CertificateRecommendation>[];

    // Check for missing common certificates
    if (!profiel.certificates.any((cert) => cert.type == CertificateType.wpbr)) {
      recommendations.add(CertificateRecommendation(
        type: CertificateType.wpbr,
        title: 'WPBR Beveiligingsbeambte',
        description: 'Verplicht voor de meeste beveiligingsfuncties',
        priority: CertificatePriority.high,
        estimatedCost: 450.0,
        trainingDurationDays: 5,
      ));
    }

    if (!profiel.certificates.any((cert) => cert.type == CertificateType.vca)) {
      recommendations.add(CertificateRecommendation(
        type: CertificateType.vca,
        title: 'VCA Veiligheid',
        description: 'Vereist voor werk op bouwplaatsen en industriële locaties',
        priority: CertificatePriority.medium,
        estimatedCost: 125.0,
        trainingDurationDays: 1,
      ));
    }

    return recommendations;
  }
}
```

## STEP 4: IMPLEMENTATION WORKFLOW
1. First, analyze existing marketplace/ and job-related code
2. Create new beveiliger_opdrachten/ directory following established patterns
3. Implement PostcodeService with caching and validation
4. Create CertificateMatchingService for job eligibility
5. Build job search screens using unified components
6. Implement BLoC architecture for state management
7. Add comprehensive testing for all business logic
8. Integrate with existing navigation and theming
9. Ensure Dutch localization for all user-facing text

## QUALITY GATES
- [ ] Creates new beveiliger_opdrachten/ following existing directory patterns
- [ ] Extends existing marketplace/ and JobPostingService without breaking changes
- [ ] Uses UnifiedHeader, UnifiedCard, UnifiedButton consistently with guard theming
- [ ] Implements Nederlandse postcode validation (1234AB format) with caching
- [ ] Includes comprehensive WPBR/VCA/BHV certificate matching logic
- [ ] Supports euro currency formatting (€15-€35/hour) with proper localization
- [ ] Integrates seamlessly with existing chat/ for employer communication
- [ ] Maintains 90%+ test coverage for all business logic and edge cases
- [ ] Passes flutter analyze with 0 issues
- [ ] Includes comprehensive error handling and offline support
- [ ] Follows established BLoC architecture patterns
- [ ] Implements proper loading states and user feedback
```

---

## 🎯 **COMPLETE PAGE TEMPLATE OVERVIEW**

### **85+ SecuryFlex Pages Categorized**

#### **BESTAANDE PAGES (Uitbreiding - 5 pages)**
1. `auth/` - Enhanced with KvK/WPBR validation
2. `beveiliger_dashboard/` - Enhanced with real-time metrics
3. `company_dashboard/` - Enhanced with team analytics
4. `marketplace/` - Enhanced with advanced filtering
5. `chat/` - Enhanced with file sharing and notifications

#### **NIEUWE GUARD FEATURES (25 pages)**
6. `beveiliger_opdrachten/` - Job search and applications
7. `beveiliger_planning/` - Schedule and calendar management
8. `beveiliger_verdiensten/` - Earnings and payment tracking
9. `beveiliger_profiel/` - Profile and certificate management
10. `beveiliger_training/` - Training and certification tracking
11. `beveiliger_locaties/` - Location and travel management
12. `beveiliger_reviews/` - Performance reviews and ratings
13. `beveiliger_documenten/` - Document storage and management
14. `beveiliger_notificaties/` - Notification preferences
15. `beveiliger_statistieken/` - Personal performance analytics
16. `beveiliger_netwerk/` - Professional networking
17. `beveiliger_hulp/` - Help and support for guards
18. `beveiliger_feedback/` - Feedback and suggestions
19. `beveiliger_instellingen/` - Guard-specific settings
20. `beveiliger_geschiedenis/` - Work history and achievements
21. `beveiliger_certificaten/` - Certificate renewal and tracking
22. `beveiliger_shifts/` - Shift management and swapping
23. `beveiliger_emergency/` - Emergency procedures and contacts
24. `beveiliger_compliance/` - Legal compliance tracking
25. `beveiliger_wellness/` - Health and wellness tracking
26. `beveiliger_community/` - Guard community features
27. `beveiliger_rewards/` - Loyalty and rewards program
28. `beveiliger_referrals/` - Referral program management
29. `beveiliger_insurance/` - Insurance and benefits
30. `beveiliger_tax/` - Tax documentation and support

#### **NIEUWE COMPANY FEATURES (25 pages)**
31. `bedrijf_beveiligers/` - Guard team management
32. `bedrijf_opdrachten/` - Job posting and management
33. `bedrijf_planning/` - Schedule optimization and coverage
34. `bedrijf_facturering/` - Billing and payment management
35. `bedrijf_analytics/` - Business intelligence and reporting
36. `bedrijf_compliance/` - Legal and regulatory compliance
37. `bedrijf_contracts/` - Contract management
38. `bedrijf_locations/` - Site and location management
39. `bedrijf_incidents/` - Incident reporting and tracking
40. `bedrijf_training/` - Training program management
41. `bedrijf_quality/` - Quality assurance and monitoring
42. `bedrijf_reviews/` - Guard performance reviews
43. `bedrijf_recruitment/` - Recruitment and hiring
44. `bedrijf_onboarding/` - New guard onboarding
45. `bedrijf_scheduling/` - Advanced scheduling tools
46. `bedrijf_communication/` - Team communication tools
47. `bedrijf_reports/` - Custom reporting and exports
48. `bedrijf_integrations/` - Third-party integrations
49. `bedrijf_security/` - Security and access management
50. `bedrijf_backup/` - Emergency coverage planning
51. `bedrijf_costs/` - Cost analysis and optimization
52. `bedrijf_performance/` - Performance metrics and KPIs
53. `bedrijf_alerts/` - Real-time alerts and notifications
54. `bedrijf_documentation/` - Policy and procedure management
55. `bedrijf_audit/` - Audit trails and compliance reporting

#### **NIEUWE ADMIN FEATURES (15 pages)**
56. `admin/` - Platform management dashboard
57. `admin_analytics/` - Platform-wide analytics
58. `admin_users/` - User management and verification
59. `admin_compliance/` - Regulatory compliance monitoring
60. `admin_security/` - Platform security management
61. `admin_billing/` - Platform billing and subscriptions
62. `admin_support/` - Customer support tools
63. `admin_content/` - Content management system
64. `admin_integrations/` - API and integration management
65. `admin_monitoring/` - System monitoring and alerts
66. `admin_backups/` - Data backup and recovery
67. `admin_logs/` - Audit logs and system logs
68. `admin_configuration/` - System configuration
69. `admin_reports/` - Administrative reporting
70. `admin_maintenance/` - System maintenance tools

#### **GEDEELDE FEATURES (15 pages)**
71. `instellingen/` - User settings and preferences
72. `hulp/` - Help and documentation
73. `juridisch/` - Legal information and policies
74. `privacy/` - Privacy settings and GDPR compliance
75. `notificaties/` - Notification management
76. `feedback/` - User feedback and suggestions
77. `about/` - About the platform
78. `contact/` - Contact information and support
79. `faq/` - Frequently asked questions
80. `tutorials/` - User tutorials and guides
81. `changelog/` - Platform updates and changes
82. `status/` - System status and uptime
83. `api_docs/` - API documentation
84. `developer/` - Developer resources
85. `partnerships/` - Partnership information

---

## 🚀 **IMPLEMENTATION WORKFLOW**

### **Phase 1: Foundation (Weeks 1-2)**
1. Setup CLAUDE.md configuration
2. Enhance existing auth/ system
3. Extend beveiliger_dashboard/ and company_dashboard/
4. Improve marketplace/ with advanced features
5. Enhance chat/ system

### **Phase 2: Core Guard Features (Weeks 3-6)**
1. Implement beveiliger_opdrachten/ (job search)
2. Build beveiliger_planning/ (scheduling)
3. Create beveiliger_verdiensten/ (earnings)
4. Develop beveiliger_profiel/ (profile management)
5. Add beveiliger_training/ (certification tracking)

### **Phase 3: Core Company Features (Weeks 7-10)**
1. Implement bedrijf_beveiligers/ (team management)
2. Build bedrijf_opdrachten/ (job posting)
3. Create bedrijf_planning/ (schedule optimization)
4. Develop bedrijf_facturering/ (billing)
5. Add bedrijf_analytics/ (business intelligence)

### **Phase 4: Admin & Advanced Features (Weeks 11-14)**
1. Implement admin/ dashboard
2. Build admin_analytics/ and monitoring
3. Create compliance and security features
4. Develop advanced reporting tools
5. Add integration capabilities

### **Phase 5: Shared Features & Polish (Weeks 15-16)**
1. Implement instellingen/ and hulp/
2. Build juridisch/ and privacy/ features
3. Create comprehensive documentation
4. Add tutorials and onboarding
5. Final testing and optimization

---

## 📚 **CLAUDE CODE BEST PRACTICES SUMMARY**

### **Essential Commands**
```bash
# Start Claude Code in project root
claude

# Use codebase-retrieval for analysis
"Please use codebase-retrieval to analyze [specific area]"

# Trigger ultrathink for complex problems
"Please ultrathink this implementation and consider all edge cases"

# Use thinking levels appropriately
"think" < "think hard" < "think harder" < "ultrathink"
```

### **Prompt Structure Template**
```markdown
# 🎯 CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Feature: [Feature Name]
Existing Systems: [List relevant systems]

# 🧠 STEP 1: CODEBASE ANALYSIS
Please use codebase-retrieval to analyze: "[specific analysis request]"

# 🧠 STEP 2: ULTRATHINK PLANNING
Please [think level] about this implementation and create a comprehensive plan.

# 🛠️ STEP 3: IMPLEMENTATION REQUIREMENTS
[Detailed requirements with existing patterns]

# 🎯 STEP 4: QUALITY GATES
[Specific quality requirements]
```

### **Key Success Factors**
1. **Always start with codebase-retrieval** to understand existing patterns
2. **Use appropriate thinking levels** - ultrathink only for complex problems
3. **Follow existing patterns** - don't reinvent the wheel
4. **Maintain unified design system** - use existing components
5. **Include comprehensive testing** - 90%+ coverage requirement
6. **Ensure Dutch compliance** - KvK, BTW, WPBR validation
7. **Document everything** - update CLAUDE.md as you go

### **Common Pitfalls to Avoid**
- ❌ Skipping codebase analysis
- ❌ Overusing ultrathink (increases token costs)
- ❌ Creating new components when unified ones exist
- ❌ Hardcoding styling values instead of using DesignTokens
- ❌ Ignoring existing BLoC patterns
- ❌ Forgetting Dutch business logic validation
- ❌ Insufficient testing coverage
- ❌ Breaking existing functionality

---

## 🎉 **CONCLUSION**

Deze complete guide biedt een systematische benadering voor het ontwikkelen van alle 85+ SecuryFlex pages met Claude Code (CLI) en Ultrathink. Door de officiële Anthropic best practices te volgen en bestaande systemen optimaal te benutten, kun je efficiënt en consistent hoogwaardige features ontwikkelen die voldoen aan Nederlandse business requirements.

**Onthoud**: Start altijd met codebase-retrieval, gebruik ultrathink verstandig, en volg de bestaande patterns voor maximale consistentie en kwaliteit.

**Success Formula**: CLAUDE.md + Codebase Analysis + Ultrathink Planning + Unified Components + Dutch Compliance + Comprehensive Testing = Enterprise-Grade SecuryFlex Platform

---

## 🤖 **CLAUDE CODE AGENTS MAPPING**

### **Agent Analysis Results**
Na grondig onderzoek van de `~/.claude/agents/` directory zijn er **67 gespecialiseerde agents** beschikbaar. Hier is de optimale mapping voor SecuryFlex development:

### **🎯 PRIMARY AGENTS FOR SECURYFLEX**

#### **1. flutter-expert** ⭐⭐⭐⭐⭐
**Best voor**: ALLE Flutter development tasks
```yaml
Gebruik voor:
- Widget composition en custom widgets
- BLoC state management (perfect voor SecuryFlex)
- Platform channels en native integration
- Performance optimization
- Testing strategies (unit, widget, integration)
- Cross-platform deployment

Model: sonnet
Tools: Read, Write, Edit, Bash, Grep, Glob

Prompt trigger:
"Use the flutter-expert agent to implement [feature] with BLoC architecture"
```

#### **2. ui-ux-designer** ⭐⭐⭐⭐⭐
**Best voor**: Design system en user experience
```yaml
Gebruik voor:
- Unified Design System uitbreiding
- User flows voor Guard/Company/Admin roles
- Wireframing nieuwe features
- Accessibility compliance
- Mobile-first responsive design

Model: sonnet
Tools: Read, Write

Prompt trigger:
"Use the ui-ux-designer agent to create user flows for [feature]"
```

#### **3. security-auditor** ⭐⭐⭐⭐⭐
**Best voor**: Nederlandse compliance en security
```yaml
Gebruik voor:
- GDPR compliance implementation
- Authentication/authorization flows
- KvK/WPBR validation security
- API security reviews
- OWASP compliance checks

Model: opus
Tools: Read, Grep, Bash

Prompt trigger:
"Use the security-auditor agent to review security for [feature]"
```

#### **4. test-automator** ⭐⭐⭐⭐⭐
**Best voor**: Testing infrastructure
```yaml
Gebruik voor:
- Unit test suites (90%+ coverage requirement)
- Widget testing voor unified components
- Integration tests voor user flows
- CI/CD pipeline setup
- Mock implementations

Model: sonnet
Tools: Read, Write, Edit, Bash

Prompt trigger:
"Use the test-automator agent to create comprehensive tests for [feature]"
```

#### **5. business-analyst** ⭐⭐⭐⭐
**Best voor**: Nederlandse business logic
```yaml
Gebruik voor:
- KPI tracking en analytics
- Revenue models (€30/maand subscription)
- CAO arbeidsrecht compliance
- BTW calculations (21%)
- Market analysis voor security sector

Model: haiku
Tools: Read, Write

Prompt trigger:
"Use the business-analyst agent to analyze business requirements for [feature]"
```

### **🔧 SECONDARY AGENTS FOR SPECIFIC TASKS**

#### **6. performance-engineer** ⭐⭐⭐⭐
**Best voor**: Performance optimization
```yaml
Gebruik voor:
- App startup optimization (<2s requirement)
- Navigation performance (<300ms)
- Memory usage optimization (<150MB)
- Real-time chat performance
- Database query optimization

Prompt trigger:
"Use the performance-engineer subagent to optimize [performance aspect]"
```

#### **7. legal-advisor** ⭐⭐⭐⭐
**Best voor**: Nederlandse legal compliance
```yaml
Gebruik voor:
- GDPR privacy policies
- Nederlandse arbeidsrecht documentation
- Terms of service voor security marketplace
- Cookie policies
- Data processing agreements

Prompt trigger:
"Use the legal-advisor subagent to create legal documentation for [requirement]"
```

#### **8. payment-integration** ⭐⭐⭐⭐⭐
**Best voor**: Payment processing en billing
```yaml
Gebruik voor:
- SEPA payment integration
- iDEAL payment processing
- Subscription billing (€30/maand)
- BTW/VAT compliance (21%)
- PCI compliance en security
- Webhook handling

Model: sonnet
Tools: Read, Write, Edit, Bash

Prompt trigger:
"Use the payment-integration agent to implement [payment feature]"
```

#### **9. mobile-developer** ⭐⭐⭐⭐
**Best voor**: Mobile-specific optimizations
```yaml
Gebruik voor:
- Flutter platform channels
- iOS/Android native integration
- App store deployment
- Push notifications
- Offline sync capabilities
- Mobile performance optimization

Model: sonnet
Tools: Read, Write, Edit, Bash, Grep

Prompt trigger:
"Use the mobile-developer agent to optimize [mobile feature]"
```

#### **10. code-reviewer** ⭐⭐⭐⭐
**Best voor**: Code quality en security reviews
```yaml
Gebruik voor:
- Proactive code quality reviews
- Security vulnerability detection
- Configuration change reviews
- Production reliability checks
- Best practices enforcement

Model: sonnet
Tools: Read, Grep, Bash

Prompt trigger:
"Use the code-reviewer agent to review [code/feature]"
```

### **📱 FEATURE-SPECIFIC AGENT MAPPING**

#### **Auth System Enhancement**
```bash
Primary: flutter-expert + security-auditor
Secondary: test-automator + legal-advisor

Prompt:
"Use the flutter-expert and security-auditor agents to enhance authentication with KvK/WPBR validation"
```

#### **Beveiliger Opdrachten (Job Search)**
```bash
Primary: flutter-expert + ui-ux-designer
Secondary: business-analyst + performance-engineer

Prompt:
"Use the flutter-expert and ui-ux-designer subagents to create job search feature with Nederlandse postcode integration"
```

#### **Company Dashboard Analytics**
```bash
Primary: flutter-expert + business-analyst
Secondary: performance-engineer + test-automator

Prompt:
"Use the flutter-expert and business-analyst subagents to build company analytics dashboard with Dutch business metrics"
```

#### **Admin Platform Management**
```bash
Primary: flutter-expert + security-auditor
Secondary: business-analyst + database-optimizer

Prompt:
"Use the flutter-expert and security-auditor subagents to create admin dashboard with platform oversight capabilities"
```

#### **Real-time Chat System**
```bash
Primary: flutter-expert + performance-engineer
Secondary: security-auditor + test-automator

Prompt:
"Use the flutter-expert and performance-engineer subagents to optimize real-time chat with file sharing"
```

#### **Payment & Billing System**
```bash
Primary: flutter-expert + payment-integration
Secondary: security-auditor + business-analyst

Prompt:
"Use the flutter-expert and payment-integration agents to implement SEPA payments with Dutch BTW compliance"
```

### **🎯 AGENT USAGE BEST PRACTICES**

#### **1. Agent Chaining Strategy**
```bash
# Voor complexe features gebruik agent chaining:
1. ui-ux-designer → Design user flows
2. flutter-expert → Implement UI/logic
3. security-auditor → Security review
4. test-automator → Create test suite
5. performance-engineer → Optimize performance
```

#### **2. Proactive Agent Usage**
```bash
# Gebruik "PROACTIVELY" in agent descriptions:
"Use the security-auditor subagent PROACTIVELY to review all authentication code"
"Use the test-automator subagent PROACTIVELY to create tests for new features"
```

#### **3. Context Preservation**
```bash
# Agents hebben eigen context windows:
- Gebruik voor gespecialiseerde taken
- Delegate complexe business logic
- Maintain main conversation focus
```

#### **4. Tool Access Management**
```bash
# Configureer tool access per agent:
flutter-expert: Read, Write, Edit, Bash, Grep
security-auditor: Read, Grep, Bash (limited write)
test-automator: Read, Write, Edit, Bash
ui-ux-designer: Read, Write (design files)
```

### **🚀 IMPLEMENTATION WORKFLOW MET AGENTS**

#### **Phase 1: Planning & Design**
```bash
1. ui-ux-designer → User flows en wireframes
2. business-analyst → Business requirements
3. security-auditor → Security requirements
4. flutter-expert → Technical architecture
```

#### **Phase 2: Development**
```bash
1. flutter-expert → Core implementation
2. test-automator → Test suite creation
3. performance-engineer → Performance optimization
4. security-auditor → Security review
```

#### **Phase 3: Deployment & Documentation**
```bash
1. deployment-engineer → CI/CD setup
2. api-documenter → Documentation
3. legal-advisor → Legal compliance
4. test-automator → Final testing
```

### **💡 AGENT SELECTION DECISION TREE**

```
Is it Flutter/Dart code? → flutter-expert
Is it UI/UX design? → ui-ux-designer
Is it security/auth? → security-auditor
Is it testing? → test-automator
Is it business logic? → business-analyst
Is it performance? → performance-engineer
Is it legal/compliance? → legal-advisor
Is it deployment? → deployment-engineer
Is it documentation? → api-documenter
Is it database? → database-optimizer
```

### **⚡ QUICK REFERENCE COMMANDS**

```bash
# View available agents
/agents

# Use specific agent
"Use the flutter-expert subagent to [task]"

# Chain multiple agents
"First use ui-ux-designer to create flows, then flutter-expert to implement"

# Proactive agent usage
"Use the security-auditor subagent PROACTIVELY for all auth code"
```

**🎯 Result**: Met deze agent mapping kun je elke SecuryFlex feature optimaal ontwikkelen door de juiste specialistische expertise in te zetten voor elke taak!

---

## 🏢 **CATEGORY 3: NIEUWE COMPANY FEATURES**

### **Template: Bedrijf Beveiligers (New)**
```markdown
# 🎯 CLAUDE CODE (CLI) PROMPT: BEDRIJF BEVEILIGERS FEATURE

## CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Feature: Bedrijf Beveiligers (Guard Team Management)
Existing Systems: company_dashboard/, CompanyService, beveiliger_profiel/, unified_components/
Target: Create comprehensive guard team management system for companies

## ULTRATHINK REASONING

### Business Logic Analysis
1. Companies need to search WPBR-verified guards
2. Team management with Nederlandse arbeidscontracten
3. Performance tracking per guard with KPI metrics
4. Rating and review system for guard evaluation
5. Integration with existing company dashboard analytics
6. Compliance with Dutch labor law (CAO Beveiliging)

### Technical Implementation Planning
1. Create new bedrijf_beveiligers/ directory structure
2. Extend existing CompanyService with team management
3. Create GuardSearchService for WPBR-verified guard discovery
4. Implement TeamManagementService for contract and performance tracking
5. Use existing UnifiedCard system with company theming
6. Integrate with beveiliger_profiel/ for guard data access

### Integration Points
- Uses: beveiliger_profiel/ (guard profiles), company_dashboard/ (analytics)
- Extends: CompanyService, existing company navigation
- Services: GuardSearchService, TeamManagementService, PerformanceAnalyticsService
- APIs: WPBR Verification API, Nederlandse Arbeidsrecht Database

### Risk Assessment
- WPBR verification delays → Cache verified status with refresh intervals
- Performance data privacy → Implement proper data anonymization
- Contract complexity → Use standardized Nederlandse arbeidscontract templates
- Large team datasets → Implement efficient pagination and filtering

## IMPLEMENTATION REQUIREMENTS

### Directory Structure
```
lib/bedrijf_beveiligers/
├── screens/
│   ├── beveiligers_zoeken_screen.dart
│   ├── team_overzicht_screen.dart
│   ├── beveiliger_details_screen.dart
│   ├── performance_analytics_screen.dart
│   ├── contract_beheer_screen.dart
│   └── beoordelingen_screen.dart
├── widgets/
│   ├── guard_search_filters.dart
│   ├── guard_card_company.dart
│   ├── team_performance_chart.dart
│   ├── contract_status_indicator.dart
│   └── rating_system.dart
├── services/
│   ├── guard_search_service.dart
│   ├── team_management_service.dart
│   ├── performance_analytics_service.dart
│   └── contract_service.dart
├── models/
│   ├── team_member_data.dart
│   ├── performance_metrics.dart
│   ├── contract_data.dart
│   └── guard_rating.dart
└── bloc/
    ├── guard_search_bloc.dart
    ├── team_management_bloc.dart
    └── performance_bloc.dart
```

### Unified Design System Implementation
```dart
// Team overview screen with company theming
class TeamOverzichtScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          UnifiedHeader.animated(
            title: 'Mijn Beveiligingsteam',
            userRole: UserRole.company,
            animationController: _animationController,
            actions: [
              UnifiedButton.icon(
                icon: Icons.person_add,
                onPressed: _navigateToGuardSearch,
                userRole: UserRole.company,
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              itemBuilder: (context, index) {
                return UnifiedCard.standard(
                  userRole: UserRole.company,
                  isClickable: true,
                  onTap: () => _navigateToGuardDetails(teamMembers[index]),
                  child: GuardCardCompany(
                    guard: teamMembers[index],
                    showPerformanceMetrics: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Guard card with company-specific information
class GuardCardCompany extends StatelessWidget {
  final TeamMemberData guard;
  final bool showPerformanceMetrics;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: DesignTokens.spacingL,
              backgroundImage: NetworkImage(guard.profileImageUrl),
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guard.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  Text(
                    'WPBR: ${guard.wpbrNumber}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.colorSuccess,
                    ),
                  ),
                ],
              ),
            ),
            if (showPerformanceMetrics)
              Column(
                children: [
                  Text(
                    '${guard.performanceScore.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: DesignTokens.companyPrimary,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                  Text(
                    'Score',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
        if (showPerformanceMetrics) ...[
          SizedBox(height: DesignTokens.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Shifts', '${guard.totalShifts}'),
              _buildMetric('Uren', '${guard.totalHours}h'),
              _buildMetric('Rating', '${guard.averageRating.toStringAsFixed(1)}⭐'),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: DesignTokens.companyPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: DesignTokens.colorTextSecondary,
          ),
        ),
      ],
    );
  }
}
```

### Nederlandse Business Logic
```dart
// Team management service with Dutch labor law compliance
class TeamManagementService {
  static TeamManagementService? _instance;
  static TeamManagementService get instance => _instance ??= TeamManagementService._();
  
  TeamManagementService._();
  
  /// Get team members for company with performance metrics
  Future<List<TeamMemberData>> getTeamMembers(String companyId) async {
    // Simulate API call to get team data
    await Future.delayed(const Duration(milliseconds: 400));
    
    return [
      TeamMemberData(
        id: 'guard-001',
        name: 'Jan de Beveiliger',
        wpbrNumber: 'WPBR-123456',
        contractType: ContractType.vastContract,
        performanceScore: 4.7,
        totalShifts: 45,
        totalHours: 360,
        averageRating: 4.8,
        contractStartDate: DateTime(2024, 1, 15),
        hourlyRate: 22.50, // Euro per hour
        isActive: true,
      ),
      // More team members...
    ];
  }
  
  /// Calculate performance metrics according to Dutch security standards
  Future<PerformanceMetrics> calculatePerformanceMetrics(String guardId, DateTime startDate, DateTime endDate) async {
    // Implementation would include:
    // - Punctuality tracking (CAO requirement)
    // - Incident reporting accuracy
    // - Client satisfaction scores
    // - Training completion rates
    // - Compliance with Dutch security regulations
    
    return PerformanceMetrics(
      punctualityScore: 95.5, // Percentage on-time arrivals
      incidentReportingScore: 88.0, // Quality of incident reports
      clientSatisfactionScore: 4.6, // Average client rating
      trainingCompletionRate: 100.0, // Required training completion
      overallScore: 92.0, // Weighted average
    );
  }
  
  /// Validate contract compliance with Dutch labor law
  static bool validateContractCompliance(ContractData contract) {
    // Check CAO Beveiliging requirements
    if (contract.hourlyRate < 15.00) return false; // Minimum wage check
    if (contract.maxWeeklyHours > 48) return false; // EU working time directive
    if (contract.overtimeRate < contract.hourlyRate * 1.5) return false; // Overtime rate
    
    return true;
  }
}

// Guard search service for WPBR-verified guards
class GuardSearchService {
  static Future<List<BeveiligerProfielData>> searchVerifiedGuards({
    String? location,
    List<CertificateType>? requiredCertificates,
    double? minRating,
    double? maxHourlyRate,
    List<String>? specializations,
  }) async {
    // Implementation would search through verified guards
    // Filter by WPBR verification status
    // Apply location-based filtering using Dutch postal codes
    // Check certificate requirements
    // Apply rating and rate filters
    
    await Future.delayed(const Duration(milliseconds: 600));
    
    return [
      // Return filtered list of verified guards
    ];
  }
}
```

### BLoC Architecture
```dart
// Team management BLoC for managing team state
class TeamManagementBloc extends BaseBloc<TeamManagementEvent, TeamManagementState> {
  final TeamManagementService _teamService;
  final PerformanceAnalyticsService _analyticsService;
  
  TeamManagementBloc({
    required TeamManagementService teamService,
    required PerformanceAnalyticsService analyticsService,
  }) : _teamService = teamService,
       _analyticsService = analyticsService,
       super(const TeamManagementInitial()) {
    on<TeamManagementInitialize>(_onInitialize);
    on<TeamManagementLoadTeam>(_onLoadTeam);
    on<TeamManagementUpdateMember>(_onUpdateMember);
    on<TeamManagementCalculatePerformance>(_onCalculatePerformance);
  }
  
  Future<void> _onLoadTeam(TeamManagementLoadTeam event, Emitter<TeamManagementState> emit) async {
    emit(const TeamManagementLoading(loadingMessage: 'Team laden...'));
    
    try {
      final teamMembers = await _teamService.getTeamMembers(event.companyId);
      final analytics = await _analyticsService.getTeamAnalytics(event.companyId);
      
      emit(TeamManagementLoaded(
        teamMembers: teamMembers,
        analytics: analytics,
        totalMembers: teamMembers.length,
        activeMembers: teamMembers.where((m) => m.isActive).length,
        averagePerformance: teamMembers.map((m) => m.performanceScore).reduce((a, b) => a + b) / teamMembers.length,
      ));
    } catch (e) {
      emit(TeamManagementError(
        error: ErrorHandler.fromException(e),
      ));
    }
  }
}
```

### Testing Strategy
```dart
// Comprehensive testing for team management functionality
group('Bedrijf Beveiligers Tests', () {
  group('TeamManagementService Tests', () {
    test('should load team members with performance metrics', () async {
      final teamMembers = await TeamManagementService.instance.getTeamMembers('company-123');
      
      expect(teamMembers, isNotEmpty);
      expect(teamMembers.first.wpbrNumber, startsWith('WPBR-'));
      expect(teamMembers.first.performanceScore, greaterThan(0));
      expect(teamMembers.first.hourlyRate, greaterThanOrEqualTo(15.00)); // Minimum wage
    });
    
    test('should validate contract compliance with Dutch labor law', () {
      final validContract = ContractData(
        hourlyRate: 22.50,
        maxWeeklyHours: 40,
        overtimeRate: 33.75, // 1.5x hourly rate
      );
      
      expect(TeamManagementService.validateContractCompliance(validContract), isTrue);
      
      final invalidContract = ContractData(
        hourlyRate: 12.00, // Below minimum
        maxWeeklyHours: 60, // Exceeds legal limit
        overtimeRate: 15.00, // Below required overtime rate
      );
      
      expect(TeamManagementService.validateContractCompliance(invalidContract), isFalse);
    });
  });
  
  testWidgets('Team overview screen should display company-themed components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.company),
        home: TeamOverzichtScreen(),
      ),
    );
    
    expect(find.byType(UnifiedHeader), findsOneWidget);
    expect(find.text('Mijn Beveiligingsteam'), findsOneWidget);
    expect(find.byType(UnifiedCard), findsWidgets);
    
    // Verify company theming is applied
    final theme = Theme.of(tester.element(find.byType(TeamOverzichtScreen)));
    expect(theme.primaryColor, equals(DesignTokens.companyPrimary));
  });
});
```

## QUALITY GATES
- [ ] Creates new bedrijf_beveiligers/ directory structure
- [ ] Extends existing CompanyService and company_dashboard/
- [ ] Uses UnifiedHeader, UnifiedCard, UnifiedButton with company theming
- [ ] Implements WPBR verification and guard search functionality
- [ ] Includes Dutch labor law compliance (CAO Beveiliging)
- [ ] Supports euro currency formatting for hourly rates
- [ ] Integrates with beveiliger_profiel/ for guard data access
- [ ] Maintains 90%+ test coverage for business logic
- [ ] Passes flutter analyze with 0 issues
- [ ] Includes comprehensive performance analytics and reporting
```

---

## ⚙️ **CATEGORY 4: NIEUWE ADMIN FEATURES**

### **Template: Admin Dashboard (New)**
```markdown
# 🎯 CLAUDE CODE (CLI) PROMPT: ADMIN DASHBOARD FEATURE

## CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Feature: Admin Dashboard (Platform Management)
Existing Systems: core/services/, unified_components/, navigation/bloc/
Target: Create comprehensive admin platform management system

## ULTRATHINK REASONING

### Business Logic Analysis
1. Admins need platform oversight with comprehensive KPI monitoring
2. KvK and WPBR verification management for user onboarding
3. Compliance reporting (GDPR, Nederlandse wetgeving)
4. Transaction monitoring and fraud detection capabilities
5. System configuration management for platform settings
6. Full access to all user data for support and verification

### Technical Implementation Planning
1. Create new admin/ directory structure with sidebar navigation
2. Implement AdminAnalyticsService for platform-wide metrics
3. Create VerificationService for KvK/WPBR management
4. Implement ComplianceService for GDPR and legal reporting
5. Use existing UnifiedCard system with admin theming (charcoal + orange)
6. Integrate with ALL existing features for read-only monitoring

### Integration Points
- Monitors: ALL features (auth/, beveiliger_*, bedrijf_*, chat/)
- Uses: Firebase Admin SDK, all database collections
- Services: AdminAnalyticsService, VerificationService, ComplianceService
- APIs: KvK Verification API, WPBR Database API, Audit Logging Service

### Risk Assessment
- Data privacy concerns → Implement strict access logging and audit trails
- Performance with large datasets → Use efficient pagination and caching
- Security vulnerabilities → Implement role-based access control with MFA
- Compliance violations → Automated monitoring and alerting systems

## IMPLEMENTATION REQUIREMENTS

### Directory Structure
```
lib/admin/
├── screens/
│   ├── admin_dashboard_screen.dart
│   ├── platform_analytics_screen.dart
│   ├── user_verification_screen.dart
│   ├── compliance_reporting_screen.dart
│   ├── transaction_monitoring_screen.dart
│   ├── system_configuration_screen.dart
│   └── audit_logs_screen.dart
├── widgets/
│   ├── admin_sidebar_navigation.dart
│   ├── platform_metrics_card.dart
│   ├── verification_queue_widget.dart
│   ├── compliance_status_indicator.dart
│   └── transaction_alert_widget.dart
├── services/
│   ├── admin_analytics_service.dart
│   ├── verification_service.dart
│   ├── compliance_service.dart
│   ├── fraud_detection_service.dart
│   └── system_config_service.dart
├── models/
│   ├── platform_metrics.dart
│   ├── verification_request.dart
│   ├── compliance_report.dart
│   └── audit_log_entry.dart
└── bloc/
    ├── admin_dashboard_bloc.dart
    ├── verification_bloc.dart
    └── compliance_bloc.dart
```

### Unified Design System Implementation
```dart
// Admin dashboard with sidebar navigation and admin theming
class AdminDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar navigation for admin
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: DesignTokens.adminPrimary, // Charcoal
              boxShadow: [DesignTokens.shadowMedium],
            ),
            child: AdminSidebarNavigation(),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                UnifiedHeader.simple(
                  title: 'Platform Beheer',
                  userRole: UserRole.admin,
                  backgroundColor: DesignTokens.adminBackground,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(DesignTokens.spacingL),
                    child: Column(
                      children: [
                        // Platform metrics overview
                        Row(
                          children: [
                            Expanded(
                              child: UnifiedCard.featured(
                                userRole: UserRole.admin,
                                child: PlatformMetricsCard(
                                  title: 'Totaal Gebruikers',
                                  value: '2,847',
                                  trend: '+12%',
                                  icon: Icons.people,
                                ),
                              ),
                            ),
                            SizedBox(width: DesignTokens.spacingM),
                            Expanded(
                              child: UnifiedCard.featured(
                                userRole: UserRole.admin,
                                child: PlatformMetricsCard(
                                  title: 'Actieve Opdrachten',
                                  value: '156',
                                  trend: '+8%',
                                  icon: Icons.work,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: DesignTokens.spacingL),
                        // Verification queue
                        UnifiedCard.standard(
                          userRole: UserRole.admin,
                          child: VerificationQueueWidget(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Admin sidebar navigation with admin theming
class AdminSidebarNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Admin header
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Column(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 48,
                color: DesignTokens.adminAccent, // Orange
              ),
              SizedBox(height: DesignTokens.spacingS),
              Text(
                'SecuryFlex Admin',
                style: TextStyle(
                  color: DesignTokens.colorWhite,
                  fontSize: DesignTokens.fontSizeL,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ],
          ),
        ),
        Divider(color: DesignTokens.adminAccent),
        // Navigation items
        Expanded(
          child: ListView(
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', true),
              _buildNavItem(Icons.analytics, 'Analytics', false),
              _buildNavItem(Icons.verified_user, 'Verificaties', false),
              _buildNavItem(Icons.gavel, 'Compliance', false),
              _buildNavItem(Icons.security, 'Transacties', false),
              _buildNavItem(Icons.settings, 'Configuratie', false),
              _buildNavItem(Icons.history, 'Audit Logs', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String title, bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: isActive ? DesignTokens.adminAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? DesignTokens.adminPrimary : DesignTokens.colorWhite,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? DesignTokens.adminPrimary : DesignTokens.colorWhite,
            fontWeight: isActive ? DesignTokens.fontWeightSemiBold : DesignTokens.fontWeightRegular,
          ),
        ),
        onTap: () {
          // Navigate to specific admin section
        },
      ),
    );
  }
}
```

### Nederlandse Business Logic
```dart
// Admin analytics service for platform-wide metrics
class AdminAnalyticsService {
  static AdminAnalyticsService? _instance;
  static AdminAnalyticsService get instance => _instance ??= AdminAnalyticsService._();

  AdminAnalyticsService._();

  /// Get comprehensive platform metrics
  Future<PlatformMetrics> getPlatformMetrics() async {
    // In production, this would aggregate data from all collections
    await Future.delayed(const Duration(milliseconds: 800));

    return PlatformMetrics(
      totalUsers: 2847,
      totalGuards: 1923,
      totalCompanies: 924,
      activeJobs: 156,
      completedJobs: 3421,
      totalRevenue: 1250000.0, // Euro
      monthlyRevenue: 185000.0, // Euro
      averageJobValue: 450.0, // Euro
      platformGrowthRate: 12.5, // Percentage
      userSatisfactionScore: 4.6,
      verificationPendingCount: 23,
      complianceIssuesCount: 2,
    );
  }

  /// Get user growth analytics with Dutch business insights
  Future<List<UserGrowthData>> getUserGrowthAnalytics(DateTime startDate, DateTime endDate) async {
    // Implementation would analyze:
    // - New guard registrations by region (Nederlandse provincies)
    // - Company registrations by KvK sector codes
    // - WPBR verification completion rates
    // - Geographic distribution across Dutch postal codes

    return [
      UserGrowthData(
        date: DateTime.now().subtract(Duration(days: 30)),
        newGuards: 45,
        newCompanies: 12,
        verificationRate: 87.5,
      ),
      // More data points...
    ];
  }
}

// Verification service for KvK and WPBR management
class VerificationService {
  static Future<List<VerificationRequest>> getPendingVerifications() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      VerificationRequest(
        id: 'ver-001',
        userId: 'user-123',
        type: VerificationType.kvk,
        kvkNumber: '12345678',
        companyName: 'Amsterdam Security B.V.',
        submittedAt: DateTime.now().subtract(Duration(hours: 2)),
        status: VerificationStatus.pending,
        priority: VerificationPriority.normal,
      ),
      VerificationRequest(
        id: 'ver-002',
        userId: 'user-456',
        type: VerificationType.wpbr,
        wpbrNumber: 'WPBR-789012',
        guardName: 'Jan de Beveiliger',
        submittedAt: DateTime.now().subtract(Duration(hours: 6)),
        status: VerificationStatus.pending,
        priority: VerificationPriority.high,
      ),
    ];
  }

  /// Verify KvK number against official Dutch Chamber of Commerce database
  static Future<KvKVerificationResult> verifyKvK(String kvkNumber) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.kvk.nl/api/v1/zoeken?kvkNummer=$kvkNumber'),
        headers: {
          'apikey': AdminConfig.kvkApiKey,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return KvKVerificationResult(
          isValid: true,
          companyName: data['resultaten'][0]['naam'],
          address: data['resultaten'][0]['adres'],
          isActive: data['resultaten'][0]['status'] == 'Actief',
          registrationDate: DateTime.parse(data['resultaten'][0]['datumOprichting']),
        );
      }

      return KvKVerificationResult(isValid: false);
    } catch (e) {
      throw VerificationException('KvK verification failed: $e');
    }
  }

  /// Verify WPBR certificate against official database
  static Future<WPBRVerificationResult> verifyWPBR(String wpbrNumber) async {
    // Implementation would check against official WPBR database
    // Validate certificate status, expiration date, specializations

    await Future.delayed(const Duration(milliseconds: 1000));

    return WPBRVerificationResult(
      isValid: true,
      certificateNumber: wpbrNumber,
      holderName: 'Jan de Beveiliger',
      issueDate: DateTime(2023, 1, 15),
      expirationDate: DateTime(2028, 1, 15),
      specializations: ['Objectbeveiliging', 'Evenementenbeveiliging'],
      isActive: true,
    );
  }
}

// Compliance service for GDPR and Dutch legal requirements
class ComplianceService {
  static Future<ComplianceReport> generateComplianceReport(DateTime startDate, DateTime endDate) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    return ComplianceReport(
      reportPeriod: DateRange(startDate, endDate),
      gdprCompliance: GDPRComplianceData(
        dataSubjectRequests: 12,
        dataBreaches: 0,
        consentWithdrawals: 3,
        dataExports: 8,
        dataDeletions: 2,
      ),
      dutchLegalCompliance: DutchLegalComplianceData(
        caoComplianceRate: 98.5, // CAO Beveiliging compliance
        workingTimeViolations: 1,
        minimumWageViolations: 0,
        wpbrVerificationRate: 99.2,
        kvkVerificationRate: 100.0,
      ),
      securityIncidents: 0,
      auditTrailCompleteness: 100.0,
    );
  }
}
```

### BLoC Architecture
```dart
// Admin dashboard BLoC for managing platform state
class AdminDashboardBloc extends BaseBloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminAnalyticsService _analyticsService;
  final VerificationService _verificationService;
  final ComplianceService _complianceService;

  AdminDashboardBloc({
    required AdminAnalyticsService analyticsService,
    required VerificationService verificationService,
    required ComplianceService complianceService,
  }) : _analyticsService = analyticsService,
       _verificationService = verificationService,
       _complianceService = complianceService,
       super(const AdminDashboardInitial()) {
    on<AdminDashboardInitialize>(_onInitialize);
    on<AdminDashboardLoadMetrics>(_onLoadMetrics);
    on<AdminDashboardLoadVerifications>(_onLoadVerifications);
    on<AdminDashboardGenerateReport>(_onGenerateReport);
  }

  Future<void> _onLoadMetrics(AdminDashboardLoadMetrics event, Emitter<AdminDashboardState> emit) async {
    emit(const AdminDashboardLoading(loadingMessage: 'Platform metrics laden...'));

    try {
      final metrics = await _analyticsService.getPlatformMetrics();
      final pendingVerifications = await _verificationService.getPendingVerifications();

      emit(AdminDashboardLoaded(
        metrics: metrics,
        pendingVerifications: pendingVerifications,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(AdminDashboardError(
        error: ErrorHandler.fromException(e),
      ));
    }
  }
}
```

### Testing Strategy
```dart
// Comprehensive testing for admin functionality
group('Admin Dashboard Tests', () {
  group('AdminAnalyticsService Tests', () {
    test('should load platform metrics successfully', () async {
      final metrics = await AdminAnalyticsService.instance.getPlatformMetrics();

      expect(metrics.totalUsers, greaterThan(0));
      expect(metrics.totalRevenue, greaterThan(0));
      expect(metrics.userSatisfactionScore, greaterThanOrEqualTo(0));
      expect(metrics.userSatisfactionScore, lessThanOrEqualTo(5));
    });
  });

  group('VerificationService Tests', () {
    test('should verify valid KvK number', () async {
      final result = await VerificationService.verifyKvK('12345678');

      expect(result.isValid, isTrue);
      expect(result.companyName, isNotEmpty);
      expect(result.isActive, isTrue);
    });

    test('should verify valid WPBR certificate', () async {
      final result = await VerificationService.verifyWPBR('WPBR-123456');

      expect(result.isValid, isTrue);
      expect(result.certificateNumber, equals('WPBR-123456'));
      expect(result.isActive, isTrue);
      expect(result.specializations, isNotEmpty);
    });
  });

  testWidgets('Admin dashboard should display admin-themed components', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.admin),
        home: AdminDashboardScreen(),
      ),
    );

    expect(find.text('Platform Beheer'), findsOneWidget);
    expect(find.byType(AdminSidebarNavigation), findsOneWidget);
    expect(find.byType(UnifiedCard), findsWidgets);

    // Verify admin theming is applied
    final theme = Theme.of(tester.element(find.byType(AdminDashboardScreen)));
    expect(theme.primaryColor, equals(DesignTokens.adminPrimary));
  });
});
```

## QUALITY GATES
- [ ] Creates new admin/ directory structure with sidebar navigation
- [ ] Implements comprehensive platform analytics and monitoring
- [ ] Uses UnifiedHeader, UnifiedCard with admin theming (charcoal + orange)
- [ ] Includes KvK and WPBR verification management
- [ ] Implements GDPR and Dutch legal compliance reporting
- [ ] Provides fraud detection and transaction monitoring
- [ ] Integrates with ALL existing features for read-only access
- [ ] Maintains 90%+ test coverage for business logic
- [ ] Passes flutter analyze with 0 issues
- [ ] Includes comprehensive audit logging and security measures
```

---

## 🔧 **CATEGORY 5: GEDEELDE FEATURES**

### **Template: Instellingen (Settings)**
```markdown
# 🎯 CLAUDE CODE (CLI) PROMPT: INSTELLINGEN FEATURE

## CONTEXT SETTING
Project: SecuryFlex Dutch Security Marketplace
Feature: Instellingen (Settings & Preferences)
Existing Systems: auth/, core/services/, unified_components/
Target: Create comprehensive settings system for all user roles

## ULTRATHINK REASONING

### Business Logic Analysis
1. Multi-role settings with role-specific options
2. Nederlandse/English language switching capability
3. GDPR data export and privacy controls
4. Account security (2FA, biometrics, password management)
5. Push/email/SMS notification preferences
6. Dutch timezone and regional settings (Europe/Amsterdam)

### Technical Implementation Planning
1. Create new instellingen/ directory structure
2. Implement SettingsService for preference management
3. Create LocalizationService for language switching
4. Implement GDPRService for data export and privacy
5. Use existing UnifiedCard system with role-based theming
6. Integrate with existing auth/ for account security

### Integration Points
- Uses: auth/ (account management), core/services/ (preferences)
- Services: SettingsService, LocalizationService, GDPRService
- Storage: SharedPreferences, Firebase Firestore (user preferences)
- APIs: Data Export APIs, Email/SMS Services

### Risk Assessment
- Data export complexity → Implement efficient data aggregation
- Language switching performance → Cache translations and use lazy loading
- Privacy compliance → Ensure GDPR-compliant data handling
- Cross-platform settings sync → Use Firebase for cloud synchronization

## IMPLEMENTATION REQUIREMENTS

### Directory Structure
```
lib/instellingen/
├── screens/
│   ├── instellingen_home_screen.dart
│   ├── account_beveiliging_screen.dart
│   ├── privacy_instellingen_screen.dart
│   ├── notificatie_instellingen_screen.dart
│   ├── taal_regio_screen.dart
│   └── data_export_screen.dart
├── widgets/
│   ├── settings_section.dart
│   ├── settings_toggle.dart
│   ├── language_selector.dart
│   ├── notification_preferences.dart
│   └── privacy_controls.dart
├── services/
│   ├── settings_service.dart
│   ├── localization_service.dart
│   ├── gdpr_service.dart
│   └── notification_preferences_service.dart
├── models/
│   ├── user_settings.dart
│   ├── notification_preferences.dart
│   ├── privacy_settings.dart
│   └── localization_settings.dart
└── bloc/
    ├── settings_bloc.dart
    ├── privacy_bloc.dart
    └── localization_bloc.dart
```
