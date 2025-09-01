# 📚 **CLAUDE CODE CLI PROMPT LIBRARY FOR SECURYFLEX**

## 🎯 **OVERVIEW**

Deze uitgebreide prompt library is specifiek ontworpen voor Claude Code CLI gebruik in de Securyflex enterprise Flutter/Dart applicatie, gebaseerd op de werkelijke codebase architectuur en agent-gebaseerde workflows.

## 📋 **INHOUDSOPGAVE**

1. [Securyflex Code Analysis](#securyflex-code-analysis)
2. [Securyflex Refactoring](#securyflex-refactoring)
3. [Securyflex Testing](#securyflex-testing)
4. [Agent Integration Workflows](#agent-integration-workflows)
5. [Dutch Business Logic](#dutch-business-logic)

---

## 🔍 **SECURYFLEX CODE ANALYSIS**

### **SCA-001: ModernBeveiligerDashboard Analysis**

**Category**: Code Analysis  
**Use Case**: Analyzing the actual ModernBeveiligerDashboard implementation  
**Agent Integration**: Uses `flutter-expert`, `code-reviewer`

```markdown
# 🔍 MODERNBEVEILIGERDASHBOARD ANALYSIS

## Context
Project: Securyflex Dutch Security Marketplace
Target: lib/beveiliger_dashboard/modern_beveiliger_dashboard.dart
Current Status: Active primary dashboard implementation

## Analysis Request
Use codebase-retrieval to analyze ModernBeveiligerDashboard and provide:

1. **Current Implementation Assessment**
   - Inline styling vs unified component usage
   - BLoC integration patterns
   - Performance characteristics
   - Design system compliance level

2. **Component Usage Analysis**
   - Which unified components are actually used
   - Where inline styling is still present
   - Opportunities for unified component migration
   - Consistency with Securyflex design standards

3. **Integration Points**
   - Profile completion integration
   - Certificate alerts system
   - Notification summary implementation
   - BLoC state management patterns

## Specific Focus Areas
- UnifiedHeader usage (currently implemented)
- Inline Container styling (needs migration)
- DesignTokens compliance
- Role-based theming implementation

## Expected Deliverables
- Current state assessment report
- Migration opportunities identification
- Unified component integration plan
- Performance optimization recommendations

## Agent Coordination
- Primary: flutter-expert for Flutter-specific analysis
- Secondary: code-reviewer for quality assessment
- Focus: Real implementation, not theoretical patterns
```

### **SCA-002: Orphaned Widget Detection**

**Category**: Code Analysis  
**Use Case**: Identifying unused widgets in beveiliger_dashboard/widgets  
**Agent Integration**: Uses `error-detective`, `code-reviewer`

```markdown
# 🔍 ORPHANED WIDGET DETECTION IN SECURYFLEX

## Context
Project: Securyflex beveiliger_dashboard module
Target: lib/beveiliger_dashboard/widgets/ directory
Issue: Many widgets exist but are not referenced

## Detection Request
Use error-detective to find orphaned widgets:

1. **Reference Analysis**
   - Scan all imports for beveiliger_dashboard/widgets
   - Identify widgets with zero references
   - Find widgets only referenced in unused files
   - Detect circular dependencies

2. **Usage Pattern Analysis**
   - enhanced_dashboard_screen.dart widgets (unused parent)
   - Integration example files (not actually integrated)
   - Test-only references vs production usage
   - Documentation-only references

## Known Orphaned Candidates
Based on analysis, check these specifically:
- recent_shifts_widget.dart
- section_title_widget.dart
- hours_tracker_widget.dart
- dashboard_metrics_summary.dart
- emergency_actions_widget.dart
- All widgets in daily_overview/ subdirectory

## Verification Requirements
- Confirm zero production references
- Check test file usage
- Verify no dynamic imports
- Validate removal safety

## Deliverables
- Complete orphaned widget list
- Safe removal recommendations
- Dependency impact assessment
- Cleanup implementation plan
```

---

## 🔄 **SECURYFLEX REFACTORING**

### **SRF-001: ModernBeveiligerDashboard Unified Component Migration**

**Category**: Refactoring  
**Use Case**: Migrating inline styling to unified components  
**Agent Integration**: Uses `flutter-expert`, `legacy-modernizer`

```markdown
# 🔄 MODERNBEVEILIGERDASHBOARD UNIFIED COMPONENT MIGRATION

## Migration Target
File: lib/beveiliger_dashboard/modern_beveiliger_dashboard.dart
Current Issue: Uses inline styling instead of unified components
Goal: 100% unified component compliance

## Migration Request
Please migrate ModernBeveiligerDashboard to use unified components while maintaining all functionality.

## Current Implementation Analysis
1. **Inline Styling Patterns**
   - Container with manual decoration
   - Hardcoded colors and spacing
   - Custom BoxShadow implementations
   - Manual border radius definitions

2. **Existing Unified Usage**
   - UnifiedHeader.multiLine (already implemented)
   - DesignTokens for some spacing
   - SecuryFlexTheme.getColorScheme usage
   - Role-based theming

## Migration Strategy
### Phase 1: Container to UnifiedCard Migration
```dart
// BEFORE (current inline styling):
Container(
  margin: EdgeInsets.all(DesignTokens.spacingM),
  padding: EdgeInsets.all(DesignTokens.spacingL),
  decoration: BoxDecoration(
    color: SecuryFlexTheme.getColorScheme(UserRole.guard).surfaceContainer,
    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
    boxShadow: [BoxShadow(...)],
  ),
  child: content,
)

// AFTER (unified component):
UnifiedCard.standard(
  userRole: UserRole.guard,
  child: content,
)
```

### Phase 2: Earnings Section Migration
- Replace earnings Container with ModernEarningsWidget
- Maintain Dutch currency formatting
- Preserve real-time update functionality
- Keep BLoC integration intact

### Phase 3: Shifts Section Migration
- Replace shifts Container with appropriate unified component
- Maintain shift status indicators
- Preserve Dutch time formatting
- Keep navigation functionality

## Quality Requirements
- Zero functionality regression
- Maintain performance characteristics
- Preserve accessibility features
- Keep Dutch localization intact
- Maintain BLoC integration patterns

## Testing Strategy
- Widget tests for each migrated section
- Integration tests for complete dashboard
- Performance benchmarks comparison
- Visual regression testing

## Deliverables
- Fully migrated ModernBeveiligerDashboard
- Performance comparison report
- Updated test suite
- Migration documentation
```

---

## 🧪 **SECURYFLEX TESTING**

### **ST-001: ModernBeveiligerDashboard Test Suite**

**Category**: Testing  
**Use Case**: Creating comprehensive tests for the actual dashboard  
**Agent Integration**: Uses `test-automator`, `flutter-expert`

```markdown
# 🧪 MODERNBEVEILIGERDASHBOARD TEST SUITE CREATION

## Testing Target
Component: lib/beveiliger_dashboard/modern_beveiliger_dashboard.dart
Current Status: Primary dashboard with limited test coverage
Goal: 90%+ test coverage with Dutch business logic validation

## Test Suite Request
Use test-automator to create comprehensive test coverage for ModernBeveiligerDashboard:

## Test Categories
### 1. Widget Tests
- **Dashboard Rendering**
  - Initial state display
  - Loading state handling
  - Error state presentation
  - Data loaded state verification

- **BLoC Integration**
  - Event dispatching
  - State transitions
  - Error handling
  - Real-time updates

### 2. Business Logic Tests
- **Profile Completion Logic**
  - Completion percentage calculation
  - Missing elements identification
  - Threshold-based display logic
  - Navigation to completion actions

- **Certificate Alerts**
  - Alert priority handling
  - Expiration date calculations
  - Dutch date formatting
  - Navigation to certificate management

- **Notification Summary**
  - Notification aggregation
  - Priority sorting
  - Dutch localization
  - Badge count calculations

### 3. Dutch-Specific Tests
- **Currency Formatting**
  - Euro symbol placement
  - Decimal separator (comma)
  - Thousands separator (period)
  - Negative amount handling

- **Date/Time Formatting**
  - Dutch date format (dd-MM-yyyy)
  - Time format (24-hour)
  - Relative time calculations
  - Timezone handling

- **Localization Tests**
  - Dutch text rendering
  - Text overflow handling
  - RTL support (if needed)
  - Accessibility labels

## Test Implementation Patterns
### Widget Test Structure
```dart
group('ModernBeveiligerDashboard Tests', () {
  late BeveiligerDashboardBloc mockBloc;
  
  setUp(() {
    mockBloc = MockBeveiligerDashboardBloc();
  });

  testWidgets('displays loading state correctly', (WidgetTester tester) async {
    when(() => mockBloc.state).thenReturn(BeveiligerDashboardLoading());
    
    await tester.pumpWidget(
      MaterialApp(
        theme: SecuryFlexTheme.getTheme(UserRole.guard),
        home: BlocProvider<BeveiligerDashboardBloc>.value(
          value: mockBloc,
          child: const ModernBeveiligerDashboard(),
        ),
      ),
    );
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Dashboard laden...'), findsOneWidget);
  });
});
```

## Deliverables
- Complete test suite implementation
- Test coverage report (target: 90%+)
- Performance benchmark results
- Accessibility compliance validation
- Dutch localization test results
- CI/CD integration setup
```

---

## 🤖 **AGENT INTEGRATION WORKFLOWS**

### **SAI-001: Dashboard Enhancement Workflow**

**Category**: Agent Orchestration  
**Use Case**: Coordinated enhancement of ModernBeveiligerDashboard  
**Agent Integration**: Multi-agent workflow

```markdown
# 🤖 MODERNBEVEILIGERDASHBOARD ENHANCEMENT WORKFLOW

## Enhancement Request
Target: lib/beveiliger_dashboard/modern_beveiliger_dashboard.dart
Goal: Complete modernization with unified components
Timeline: Phased approach with validation gates

## Multi-Agent Coordination
Please coordinate the following agents for complete dashboard enhancement:

## Phase 1: Analysis & Planning (flutter-expert + code-reviewer)
**Primary Agent**: flutter-expert
**Task**: Analyze current ModernBeveiligerDashboard implementation
**Focus Areas**:
- Current inline styling patterns
- BLoC integration assessment
- Performance characteristics
- Dutch business logic implementation

**Secondary Agent**: code-reviewer
**Task**: Quality and compliance assessment
**Focus Areas**:
- Design system compliance gaps
- Security considerations
- Performance bottlenecks
- Maintainability issues

**Deliverables**:
- Current state analysis report
- Enhancement opportunity identification
- Risk assessment
- Implementation roadmap

## Phase 2: Unified Component Migration (flutter-expert + ui-ux-designer)
**Primary Agent**: flutter-expert
**Task**: Migrate inline styling to unified components
**Implementation**:
- Replace Container styling with UnifiedCard
- Implement ModernEarningsWidget integration
- Add ModernQuickActionsWidget
- Ensure DesignTokens compliance

**Secondary Agent**: ui-ux-designer
**Task**: Design consistency validation
**Validation**:
- Visual design compliance
- User experience consistency
- Accessibility standards
- Dutch localization quality

**Deliverables**:
- Migrated dashboard implementation
- Design consistency validation
- User experience testing results
- Performance comparison

## Quality Gates
### Gate 1: Analysis Completion
- ✅ Current state fully documented
- ✅ Enhancement plan approved
- ✅ Risk assessment completed
- ✅ Timeline validated

### Gate 2: Migration Completion
- ✅ All inline styling migrated
- ✅ Unified components integrated
- ✅ Design consistency validated
- ✅ Functionality preserved

## Success Metrics
- **Code Quality**: 100% unified component usage
- **Performance**: Maintain <2s load time, <300ms navigation
- **Test Coverage**: 90%+ business logic, 80%+ overall
- **Design Consistency**: 100% DesignTokens compliance
- **Dutch Compliance**: Complete business logic validation
```

---

## 🇳🇱 **DUTCH BUSINESS LOGIC**

### **SDL-001: Notification System Dutch Compliance**

**Category**: Dutch Business Logic  
**Use Case**: Implementing Dutch-compliant notification system  
**Agent Integration**: Uses compliance and localization specialists

```markdown
# 🇳🇱 NOTIFICATION SYSTEM DUTCH COMPLIANCE IMPLEMENTATION

## Context
File: lib/beveiliger_notificaties/services/notification_preferences_service.dart
Current: JobEventType.completion selected
Goal: Complete Dutch notification compliance system

## Dutch Compliance Request
Please implement comprehensive Dutch notification system compliance:

## GDPR/WPBR Notification Requirements
### 1. Consent Management
- **Explicit Consent**
  - Clear notification purpose explanation
  - Granular consent options
  - Easy withdrawal mechanisms
  - Consent audit trail

- **Notification Categories**
  - Essential notifications (no consent needed)
  - Marketing notifications (consent required)
  - Operational notifications (legitimate interest)
  - Emergency notifications (override consent)

### 2. Data Processing Compliance
- **Purpose Limitation**
  - Notification data only for stated purpose
  - No secondary use without consent
  - Clear data retention periods
  - Automatic data deletion

- **Data Minimization**
  - Only necessary notification data
  - Minimal personal information
  - Anonymization where possible
  - Pseudonymization techniques

## Security Industry Notification Rules
### 1. Incident Reporting (WPBR Article 34)
- **Mandatory Notifications**
  - Security incidents within 72 hours
  - Data breaches to authorities
  - High-risk breaches to individuals
  - Regulatory compliance updates

### 2. Operational Notifications
- **Shift Management**
  - Shift assignment confirmations
  - Schedule change notifications
  - Emergency shift requests
  - Completion confirmations

## Implementation Architecture
### 1. Notification Service Structure
```dart
class DutchCompliantNotificationService {
  // GDPR-compliant notification sending
  Future<void> sendNotification({
    required NotificationType type,
    required String userId,
    required Map<String, dynamic> content,
    required ConsentBasis legalBasis,
  });
  
  // Consent verification
  Future<bool> hasValidConsent({
    required String userId,
    required NotificationCategory category,
  });
  
  // WPBR incident reporting
  Future<void> reportSecurityIncident({
    required IncidentDetails incident,
    required List<String> affectedUsers,
  });
}
```

## Deliverables
- Complete Dutch-compliant notification system
- GDPR/WPBR compliance framework
- Consent management implementation
- Audit trail system
- Dutch localization
- Compliance testing suite
- Legal documentation
```

---

## 📝 **USAGE GUIDELINES**

### **How to Use These Prompts**

1. **Copy the relevant prompt** from this library
2. **Customize the placeholders** with your specific requirements
3. **Use in Claude Code CLI** with appropriate agent mentions
4. **Follow the expected deliverables** for consistent results

### **Agent Integration**

All prompts are designed to work with the existing `.claude/agents/` system:
- Mention agents explicitly: "Use flutter-expert to..."
- Leverage multi-agent workflows for complex tasks
- Follow the quality gates for enterprise-grade results

### **Securyflex-Specific Context**

These prompts are tailored for:
- ModernBeveiligerDashboard as the primary dashboard
- Dutch business logic compliance (GDPR/WPBR)
- Unified design system migration
- Enterprise Flutter development patterns

### **SRF-002: Orphaned Widget Cleanup**

**Category**: Refactoring
**Use Case**: Safe removal of unused widgets
**Agent Integration**: Uses `code-reviewer`, `debugger`

```markdown
# 🔄 ORPHANED WIDGET CLEANUP IN SECURYFLEX

## Cleanup Target
Directory: lib/beveiliger_dashboard/widgets/
Scope: Remove confirmed orphaned widgets
Safety: Ensure zero impact on active functionality

## Cleanup Request
Please safely remove orphaned widgets while preserving any valuable functionality.

## Confirmed Orphaned Widgets
Based on analysis, these widgets have zero active references:
- recent_shifts_widget.dart (382 lines)
- section_title_widget.dart (97 lines)
- hours_tracker_widget.dart (330 lines)
- dashboard_metrics_summary.dart (not used in ModernBeveiligerDashboard)
- emergency_actions_widget.dart
- emergency_shift_alert_widget.dart
- All widgets in daily_overview/ subdirectory

## Cleanup Strategy
### Phase 1: Verification
- Double-check zero references in active code
- Verify no dynamic imports or string-based references
- Confirm test-only usage vs production usage
- Check for any valuable functionality to preserve

### Phase 2: Safe Removal
- Remove widget files
- Remove associated test files
- Update any documentation references
- Clean up import statements

### Phase 3: Functionality Preservation
- Extract any valuable patterns for future use
- Document removed functionality
- Preserve any reusable business logic
- Update architecture documentation

## Special Considerations
### Enhanced Dashboard Screen
- enhanced_dashboard_screen.dart is also orphaned
- Contains widgets that might be valuable:
  - EarningsCardWidget
  - ShiftOverviewWidget
  - ComplianceStatusWidget
  - WeatherCardWidget
  - PerformanceChartWidget

### Evaluation Criteria
- Is the widget functionality needed in ModernBeveiligerDashboard?
- Can the widget be converted to unified component?
- Does it contain valuable Dutch business logic?
- Is it worth preserving for future features?

## Deliverables
- Cleaned codebase with orphaned widgets removed
- Preserved functionality documentation
- Updated test suite
- Architecture documentation updates
- Reduction metrics (lines of code eliminated)
```

---

## 🧠 **ULTRATHINK COMPLEX REASONING**

### **UT-001: Complex Architecture Decision**

**Category**: Complex Reasoning
**Use Case**: Making complex architectural decisions with multiple trade-offs
**Agent Integration**: Uses `architect-reviewer`, `context-manager`

```markdown
# 🧠 COMPLEX ARCHITECTURE DECISION WITH ULTRATHINK

## Decision Context
Architecture Challenge: {SPECIFIC_CHALLENGE}
Constraints: {TECHNICAL_AND_BUSINESS_CONSTRAINTS}
Stakeholders: {AFFECTED_PARTIES}
Timeline: {DECISION_TIMELINE}

## Ultrathink Analysis Request
Please ultrathink this complex architectural decision, considering all implications and trade-offs.

## Multi-Dimensional Analysis
Please think harder about the following aspects:

### 1. Technical Feasibility Analysis
- Implementation complexity assessment
- Technology stack compatibility
- Performance implications
- Scalability considerations
- Maintenance overhead

### 2. Business Impact Evaluation
- Development timeline impact
- Resource requirements
- Cost implications
- Risk assessment
- ROI analysis

### 3. User Experience Implications
- Performance impact on users
- Feature availability changes
- Learning curve for users
- Accessibility considerations
- Mobile vs desktop experience

### 4. Security & Compliance Assessment
- Security architecture changes
- Dutch compliance requirements (GDPR/WPBR)
- Data protection implications
- Audit trail requirements
- Risk mitigation strategies

### 5. Integration & Dependencies
- Existing system integration
- Third-party service dependencies
- API compatibility requirements
- Data migration needs
- Rollback procedures

## Decision Framework
Please evaluate each option against:

### Technical Criteria (Weight: 30%)
- Implementation feasibility
- Performance characteristics
- Maintainability
- Scalability
- Technology alignment

### Business Criteria (Weight: 25%)
- Development cost
- Time to market
- Resource requirements
- Risk level
- Strategic alignment

### User Experience Criteria (Weight: 25%)
- Performance impact
- Feature richness
- Usability
- Accessibility
- Mobile experience

### Compliance Criteria (Weight: 20%)
- Security requirements
- Dutch legal compliance
- Data protection
- Audit requirements
- Industry standards

## Recommendation Format
### Primary Recommendation
- **Option**: [Selected approach]
- **Rationale**: [Detailed reasoning]
- **Trade-offs**: [Accepted compromises]
- **Implementation Plan**: [High-level approach]

### Alternative Options
- **Option 2**: [Alternative approach]
- **Pros/Cons**: [Comparative analysis]
- **When to Consider**: [Scenarios for this option]

### Risk Mitigation
- **Identified Risks**: [Potential issues]
- **Mitigation Strategies**: [Risk reduction approaches]
- **Contingency Plans**: [Fallback options]

## Implementation Roadmap
- **Phase 1**: [Initial implementation steps]
- **Phase 2**: [Intermediate milestones]
- **Phase 3**: [Final implementation]
- **Validation**: [Success criteria and testing]

## Agent Coordination
- **architect-reviewer**: Technical architecture validation
- **security-auditor**: Security and compliance review
- **performance-engineer**: Performance impact assessment
- **business-analyst**: Business impact evaluation
```

### **UT-002: Complex Dutch Business Logic Implementation**

**Category**: Complex Reasoning
**Use Case**: Implementing complex Dutch business logic with multiple edge cases
**Agent Integration**: Uses domain specialists

```markdown
# 🧠 COMPLEX DUTCH BUSINESS LOGIC IMPLEMENTATION

## Business Logic Challenge
Domain: {SPECIFIC_BUSINESS_DOMAIN}
Complexity: {REGULATORY_REQUIREMENTS}
Edge Cases: {KNOWN_EDGE_CASES}
Compliance: {SPECIFIC_DUTCH_REGULATIONS}

## Ultrathink Business Analysis
Please ultrathink the implementation of this complex Dutch business logic.

## Comprehensive Requirements Analysis
Please think harder about these interconnected requirements:

### 1. Dutch Regulatory Compliance
- **KvK (Chamber of Commerce) Requirements**
  - Company registration validation
  - Business activity codes
  - Legal entity types
  - Registration status verification

- **BTW (VAT) Calculations**
  - Standard rates (21%)
  - Reduced rates (9%, 0%)
  - Exemption categories
  - Cross-border transactions
  - Reverse charge mechanisms

- **WPBR (Data Protection) Compliance**
  - Data processing lawfulness
  - Consent management
  - Data subject rights
  - Breach notification procedures
  - Privacy by design implementation

### 2. CAO (Collective Labor Agreement) Rules
- **Working Time Regulations**
  - Maximum working hours
  - Overtime calculations
  - Rest period requirements
  - Holiday entitlements
  - Sick leave provisions

- **Wage Calculations**
  - Minimum wage compliance
  - Holiday allowance (vakantiegeld)
  - Overtime premiums
  - Shift allowances
  - Expense reimbursements

### 3. Security Industry Specifics
- **Licensing Requirements**
  - Security guard licenses
  - Company certifications
  - Training requirements
  - Background checks
  - Renewal procedures

- **Operational Compliance**
  - Incident reporting
  - Equipment requirements
  - Insurance obligations
  - Client contract terms
  - Subcontracting rules

## Implementation Strategy
Please analyze the optimal implementation approach:

### 1. Rule Engine Design
- **Business Rule Modeling**
  - Rule categorization
  - Priority hierarchies
  - Conflict resolution
  - Exception handling
  - Audit trail requirements

- **Validation Framework**
  - Input validation rules
  - Cross-field validations
  - Temporal validations
  - External system validations
  - Error message localization

### 2. Data Architecture
- **Master Data Management**
  - Reference data sources
  - Data synchronization
  - Version control
  - Change management
  - Data quality assurance

- **Calculation Engine**
  - Formula management
  - Rate tables
  - Calculation history
  - Recalculation procedures
  - Performance optimization

## Edge Case Analysis
Please identify and address complex edge cases:

### 1. Temporal Edge Cases
- **Regulation Changes**
  - Mid-period rate changes
  - Retroactive adjustments
  - Transition periods
  - Grandfathering rules
  - Implementation timelines

- **Calendar Complexities**
  - Leap years
  - Holiday calculations
  - Weekend handling
  - Time zone considerations
  - Daylight saving time

### 2. Business Edge Cases
- **Multi-Entity Scenarios**
  - Holding company structures
  - Cross-border operations
  - Joint ventures
  - Subcontracting chains
  - Temporary assignments

- **Exception Handling**
  - Force majeure situations
  - Emergency procedures
  - Regulatory exemptions
  - Special circumstances
  - Manual overrides

## Implementation Deliverables
### 1. Business Logic Framework
- Rule engine implementation
- Validation framework
- Calculation engine
- Exception handling system
- Audit trail mechanism

### 2. Integration Layer
- External API integrations
- Data synchronization
- Error handling
- Monitoring and alerting
- Performance optimization

### 3. Testing Strategy
- Unit tests for all rules
- Integration tests for workflows
- Edge case validation
- Performance testing
- Compliance verification

### 4. Documentation
- Business rule documentation
- Technical implementation guide
- Compliance mapping
- User guides
- Maintenance procedures

## Quality Assurance
- **Compliance Verification**
  - Legal review process
  - Regulatory approval
  - Audit preparation
  - Documentation standards
  - Change control procedures

- **Performance Validation**
  - Calculation accuracy
  - Processing speed
  - System reliability
  - Error handling
  - User experience
```

---

## 🏗️ **ENTERPRISE FLUTTER PATTERNS**

### **EF-001: Enterprise State Management Setup**

**Category**: Enterprise Patterns
**Use Case**: Setting up enterprise-grade state management with BLoC
**Agent Integration**: Uses `flutter-expert`, `architect-reviewer`

```markdown
# 🏗️ ENTERPRISE FLUTTER STATE MANAGEMENT SETUP

## State Management Requirements
Application: {APPLICATION_NAME}
Complexity: {SIMPLE_OR_COMPLEX}
Scale: {USER_COUNT_AND_DATA_VOLUME}
Architecture: {EXISTING_ARCHITECTURE}

## Enterprise State Management Request
Please implement enterprise-grade state management using BLoC pattern:

## Architecture Requirements
1. **BLoC Pattern Implementation**
   - Event-driven architecture
   - Immutable state objects
   - Clear separation of concerns
   - Testable business logic
   - Reactive programming patterns

2. **Scalability Considerations**
   - Modular BLoC organization
   - Dependency injection setup
   - Memory management
   - Performance optimization
   - Code maintainability

## Implementation Structure
### 1. BLoC Architecture Setup
```dart
// Example structure for reference
lib/
├── blocs/
│   ├── authentication/
│   │   ├── auth_bloc.dart
│   │   ├── auth_event.dart
│   │   ├── auth_state.dart
│   │   └── auth_repository.dart
│   ├── dashboard/
│   └── shared/
├── models/
├── repositories/
└── services/
```

### 2. State Management Patterns
- **Global State**: Authentication, user preferences, app configuration
- **Feature State**: Screen-specific data and UI state
- **Local State**: Widget-level state for simple interactions
- **Cached State**: Offline data and performance optimization

### 3. Event Handling Strategy
- **User Events**: UI interactions and user actions
- **System Events**: Network changes, app lifecycle
- **Data Events**: API responses and data updates
- **Error Events**: Exception handling and error recovery

## Securyflex Integration
### 1. Role-Based State Management
- **Guard State**: Shift management, earnings tracking, job applications
- **Company State**: Job posting, applicant management, analytics
- **Admin State**: System configuration, user management, reporting

### 2. Dutch Business Logic Integration
- **Validation State**: KvK validation, BTW calculations
- **Compliance State**: WPBR compliance, audit trails
- **Localization State**: Dutch language and formatting

## Quality Requirements
### 1. Testing Strategy
- **Unit Tests**: BLoC logic testing
- **Widget Tests**: UI state testing
- **Integration Tests**: End-to-end workflows
- **Performance Tests**: State management efficiency

### 2. Error Handling
- **Graceful Degradation**: Offline functionality
- **Error Recovery**: Automatic retry mechanisms
- **User Feedback**: Clear error messages
- **Logging**: Comprehensive error tracking

## Implementation Deliverables
- Complete BLoC architecture setup
- State management documentation
- Testing strategy implementation
- Performance optimization guidelines
- Error handling framework
```

---

**Last Updated**: 2025-01-26
**Version**: 1.0
**Maintainer**: Securyflex Development Team
