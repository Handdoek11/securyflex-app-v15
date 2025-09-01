# Company Dashboard Implementation Guide

## Overview

The Company Dashboard provides a comprehensive interface for security companies to manage job postings, review applications, and oversee their security operations on the Securyflex platform. This implementation follows the established unified design system while providing Company-specific functionality.

## Architecture

### Directory Structure
```
lib/company_dashboard/
├── localization/
│   └── company_nl.dart           # Dutch translations
├── models/
│   ├── company_data.dart         # Company profile data
│   ├── job_posting_data.dart     # Job posting models
│   └── application_review_data.dart # Application review models
├── screens/
│   ├── company_dashboard_main.dart    # Main dashboard
│   ├── company_jobs_screen.dart       # Job management
│   ├── company_applications_screen.dart # Application review
│   ├── company_settings_screen.dart   # Company settings
│   └── job_posting_form_screen.dart   # Job creation form
├── services/
│   ├── company_service.dart           # Company profile service
│   ├── job_posting_service.dart       # Job management service
│   └── application_review_service.dart # Application review service
├── widgets/
│   ├── company_welcome_view.dart      # Welcome widget
│   ├── active_jobs_overview.dart      # Active jobs widget
│   ├── applications_summary.dart      # Applications summary
│   ├── revenue_metrics_view.dart      # Revenue metrics
│   ├── job_management_overview.dart   # Job management widget
│   ├── application_management_overview.dart # Application management
│   └── company_settings_overview.dart # Settings widget
├── company_dashboard_home.dart        # Main container
└── models/
    └── company_tab_data.dart         # Navigation tabs
```

## Key Features

### 1. Multi-Role Support
- **Role-Based Routing**: Automatic routing based on user role (Guard/Company/Admin)
- **Theme Consistency**: Company theme (Teal primary, Navy secondary) following unified design system
- **Navigation Structure**: 4-tab bottom navigation (Dashboard, Jobs, Applications, Settings)

### 2. Job Management
- **Job Posting**: Create, edit, and manage security job postings
- **Dutch Validation**: KvK numbers, postal codes, phone numbers
- **Job Types**: Object security, event security, personal security, mobile surveillance
- **Status Management**: Draft, active, paused, completed, cancelled, expired

### 3. Application Review
- **Application Management**: Review guard applications with detailed profiles
- **Accept/Reject Workflow**: Streamlined decision-making process
- **Guard Profiles**: View certificates, experience, ratings, and reviews
- **Communication**: Direct messaging and interview scheduling

### 4. Company Profile
- **Business Information**: Company details with KvK validation
- **Verification Status**: Verified company badges and premium features
- **Performance Metrics**: Job success rates, guard ratings, completion statistics

## Implementation Patterns

### 1. Screen Structure
All Company screens follow the established pattern:
```dart
class CompanyScreenName extends StatefulWidget {
  final AnimationController? animationController;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: SecuryFlexTheme.getColorScheme(UserRole.company).surface,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: UnifiedHeader.animated(
          title: 'Screen Title',
          userRole: UserRole.company,
        ),
        body: ListView(
          children: listViews,
        ),
      ),
    );
  }
}
```

### 2. Widget Animation Pattern
All widgets use consistent animation patterns:
```dart
return AnimatedBuilder(
  animation: animationController!,
  builder: (BuildContext context, Widget? child) {
    return FadeTransition(
      opacity: animation!,
      child: Transform(
        transform: Matrix4.translationValues(
            0.0, 30 * (1.0 - animation!.value), 0.0),
        child: // Widget content
      ),
    );
  },
);
```

### 3. Service Layer Pattern
All services follow singleton pattern with mock data:
```dart
class ServiceName {
  static ServiceName? _instance;
  static ServiceName get instance => _instance ??= ServiceName._();
  ServiceName._();
  
  static void initializeMockData() {
    // Initialize mock data
  }
  
  Future<DataType> getData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockData;
  }
}
```

## Dutch Business Logic

### 1. Validation Patterns
```dart
// KvK Number Validation (8 digits)
static bool isValidKvkNumber(String kvkNumber) {
  return DutchBusinessValidation.isValidKvkNumber(kvkNumber);
}

// Postal Code Validation (1234AB format)
static bool isValidPostalCode(String postalCode) {
  return DutchBusinessValidation.isValidPostalCode(postalCode);
}

// Dutch Phone Number Validation
static bool isValidDutchPhone(String phoneNumber) {
  return DutchBusinessValidation.isValidDutchPhone(phoneNumber);
}
```

### 2. Currency Formatting
```dart
// Euro formatting with Dutch locale
final currencyFormat = NumberFormat.currency(locale: 'nl_NL', symbol: '€');
Text('${currencyFormat.format(hourlyRate)}/u');
```

### 3. Date Formatting
```dart
// Dutch date formatting
DateFormat('dd MMMM yyyy', 'nl_NL').format(date);
```

## Theming and Design

### 1. Company Color Scheme
```dart
// Company theme colors
Primary: Color(0xFF54D3C2)     // Teal
Secondary: Color(0xFF1E3A8A)   // Navy Blue
Surface: Color(0xFFFAFAFA)     // Light Gray
OnSurface: Color(0xFF1A1A1A)   // Dark Gray
```

### 2. Component Usage
Always use unified components:
```dart
// Headers
UnifiedHeader.animated(
  title: 'Company Dashboard',
  userRole: UserRole.company,
)

// Buttons
UnifiedButton.primary(
  text: 'Nieuwe Opdracht',
  onPressed: () {},
)

// Cards
UnifiedCard.standard(
  userRole: UserRole.company,
  child: content,
)
```

## Testing Strategy

### 1. Unit Tests
- **Business Logic**: 90%+ coverage for services and models
- **Validation**: Dutch business logic validation
- **Data Processing**: Currency, date, and format handling

### 2. Widget Tests
- **Component Rendering**: 80%+ coverage for all widgets
- **Theme Application**: Verify Company theming
- **Animation Behavior**: Test animation controllers

### 3. Integration Tests
- **Cross-Role Workflow**: Guard applies → Company reviews → Decision
- **Navigation Flow**: Tab switching and screen transitions
- **Data Consistency**: Service layer integration

## Performance Requirements

### 1. Loading Times
- **Dashboard Load**: <1000ms
- **Screen Navigation**: <300ms
- **Data Refresh**: <500ms

### 2. Memory Usage
- **Average Usage**: <150MB
- **Peak Usage**: <200MB
- **Memory Leaks**: Zero tolerance

### 3. Animation Performance
- **60 FPS**: Smooth animations
- **No Jank**: Consistent frame rates
- **Responsive**: Immediate user feedback

## Localization

### 1. Dutch Translations
Complete Dutch translations available in `company_nl.dart`:
- Navigation terms
- Business terminology
- Form labels and validation messages
- Status indicators
- Error and success messages

### 2. Usage Pattern
```dart
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';

Text(CompanyNL.dashboard);
Text(CompanyNL.jobManagement);
Text(CompanyNL.applicationManagement);
```

### 3. Extension Methods
```dart
// Convenient translation access
Text('dashboard'.nl); // Returns 'Dashboard'
Text('jobs'.nl);      // Returns 'Opdrachten'
```

## Security Considerations

### 1. Data Protection
- **Role-Based Access**: Company users only see their data
- **Input Validation**: All forms validate Dutch business rules
- **Secure Storage**: Sensitive data encrypted

### 2. Authentication
- **JWT Tokens**: Secure authentication
- **Session Management**: Automatic logout on inactivity
- **Permission Checks**: Role-based feature access

### 3. Privacy Compliance
- **GDPR Compliance**: Dutch privacy law adherence
- **Data Minimization**: Only collect necessary data
- **User Consent**: Clear consent mechanisms

## Deployment and Maintenance

### 1. Quality Gates
- **Flutter Analyze**: 0 issues
- **Test Coverage**: 90%+ business logic, 80%+ overall
- **Performance**: Meet all benchmarks
- **Accessibility**: WCAG 2.1 AA compliance

### 2. Monitoring
- **Error Tracking**: Comprehensive error logging
- **Performance Monitoring**: Real-time metrics
- **User Analytics**: Usage pattern analysis

### 3. Updates
- **Version Control**: Semantic versioning
- **Migration Scripts**: Database schema updates
- **Rollback Strategy**: Safe deployment practices

## Best Practices

### 1. Code Organization
- Follow established directory structure
- Use consistent naming conventions
- Implement proper separation of concerns
- Document complex business logic

### 2. Error Handling
- Graceful degradation for network issues
- User-friendly error messages in Dutch
- Comprehensive logging for debugging
- Fallback mechanisms for critical features

### 3. Accessibility
- Screen reader support
- High contrast mode compatibility
- Keyboard navigation support
- Touch target size compliance

## Future Enhancements

### 1. Planned Features
- Advanced analytics dashboard
- Automated job matching
- Integration with external HR systems
- Mobile app optimization

### 2. Technical Improvements
- Real-time notifications
- Offline capability
- Advanced search and filtering
- Export functionality

### 3. Business Expansion
- Multi-language support beyond Dutch
- International market adaptation
- Advanced reporting features
- API for third-party integrations

## Support and Documentation

### 1. Developer Resources
- Code examples and snippets
- API documentation
- Testing guidelines
- Deployment procedures

### 2. User Support
- User manual in Dutch
- Video tutorials
- FAQ section
- Support ticket system

### 3. Community
- Developer forum
- Feature request system
- Bug reporting process
- Community contributions

---

This guide ensures consistent, high-quality implementation of Company Dashboard features while maintaining the established Securyflex standards and Dutch business requirements.
