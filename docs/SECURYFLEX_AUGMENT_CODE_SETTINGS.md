# 🛡️ SECURYFLEX AUGMENT CODE SETTINGS - COMPLETE CONFIGURATION

## 📋 **COPY-PASTE READY CONFIGURATION**

### **RULES SECTION (Technical Constraints)**
```markdown
# 🛡️ SECURYFLEX TECHNICAL RULES - MANDATORY CONSTRAINTS

## PROJECT IDENTITY
Securyflex is a Dutch security marketplace platform connecting security personnel (beveiligers) with businesses. Multi-role architecture (Guard/Company/Admin), Dutch-first business logic, enterprise-grade security, 100% Flutter UI Template consistency.

## MANDATORY TECHNICAL REQUIREMENTS

### UNIFIED DESIGN SYSTEM COMPLIANCE
✅ REQUIRED: Always use unified components
- UnifiedHeader.simple(title: 'Title', userRole: UserRole.guard)
- UnifiedButton.primary(text: 'Action', onPressed: () {})
- UnifiedCard.standard(userRole: UserRole.company, child: content)
- DesignTokens.* for all styling (never hardcode values)

❌ FORBIDDEN: Direct Material/Cupertino components
- Container() → Use UnifiedCard instead
- ElevatedButton() → Use UnifiedButton instead  
- AppBar() → Use UnifiedHeader instead

### ROLE-BASED THEMING ENFORCEMENT
✅ REQUIRED: Every component must support UserRole enum
- UserRole.guard → Navy Blue (#1E3A8A) + Teal (#54D3C2)
- UserRole.company → Teal (#54D3C2) + Navy Blue (#1E3A8A)
- UserRole.admin → Charcoal (#2D3748) + Orange (#F59E0B)

### DUTCH BUSINESS LOGIC REQUIREMENTS
✅ REQUIRED: Dutch validation patterns
- KvK numbers: 8 digits with validation
- Postal codes: 1234AB format
- Phone numbers: +31 or 06 format
- Locale: 'nl_NL' for dates and currency
- All user-facing text in Dutch

### TEMPLATE CONSISTENCY ENFORCEMENT
✅ REQUIRED: File organization pattern
lib/auth/, lib/beveiliger_dashboard/, lib/marketplace/, lib/unified_*.dart

### TESTING REQUIREMENTS
✅ REQUIRED: Coverage standards
- Unit Tests: 90%+ for business logic
- Widget Tests: 80%+ for UI components
- Integration Tests: 70%+ for user flows
- All 68+ tests must pass

## ABSOLUTE PROHIBITIONS
❌ Hardcode styling values (colors, fonts, spacing, shadows)
❌ Create custom components without checking unified alternatives
❌ Mix different theme systems or ignore role-based theming
❌ Use English strings in user-facing text
❌ Skip input validation for Dutch business logic
❌ Ignore template patterns established in codebase
❌ Create tests with <90% coverage for business logic
❌ Store sensitive data without encryption
❌ Skip authentication checks for protected routes

## PERFORMANCE REQUIREMENTS
- App startup: <2 seconds cold start
- Navigation: <300ms between screens
- API responses: <1 second handling
- Memory usage: <150MB average
- Flutter analyze: 0 issues (mandatory)

## DEVELOPMENT WORKFLOW RULES
1. Read docs/UNIFIED_DESIGN_SYSTEM.md first
2. Use codebase-retrieval to understand existing patterns
3. Follow template standards (100% consistency)
4. Implement role-based theming for all user types
5. Add Dutch localization for all user-facing text
6. Write comprehensive tests (meet coverage requirements)
7. Validate performance against established metrics

## COMPLIANCE CHECKLIST
Every feature implementation MUST verify:
- [ ] Uses unified design system components
- [ ] Implements role-based theming for all user types
- [ ] Includes Dutch business logic validation
- [ ] Maintains template consistency patterns
- [ ] Achieves required test coverage (90%+ business logic)
- [ ] Passes all quality gates (analyze, tests, performance)
- [ ] Includes proper Dutch localization
- [ ] Implements security best practices
- [ ] Follows established file organization
- [ ] Documents any new patterns or components

VIOLATION OF THESE RULES RESULTS IN IMMEDIATE REJECTION OF CODE CHANGES
```

### **USER GUIDELINES SECTION (Best Practices)**
```markdown
# 🎯 SECURYFLEX DEVELOPMENT GUIDELINES - BEST PRACTICES

## PROJECT ARCHITECTURE UNDERSTANDING
Securyflex is a Dutch security marketplace platform with:
- Multi-role ecosystem: Guards, Companies, Admins with distinct workflows
- Enterprise-grade security: Authentication, authorization, data protection
- Dutch-first business logic: KvK validation, postal codes, currency formatting
- Template consistency: 100% compliance with Flutter UI Template standards
- Unified design system: Complete implementation with role-based theming

Current Status: ✅ Design System Complete, ✅ 68+ Tests, ✅ Performance Standards Met, ✅ Dutch Localization Complete

## DEVELOPMENT WORKFLOW OPTIMIZATION

### Pre-Implementation Protocol
BEFORE any coding task, ALWAYS execute this sequence:
1. 📚 Read docs/UNIFIED_DESIGN_SYSTEM.md for current design standards
2. 🔍 Use codebase-retrieval to understand existing patterns and architecture
3. 🎯 Identify which unified components are available for your use case
4. 🎭 Determine which user roles (Guard/Company/Admin) will use this feature
5. 🇳🇱 Plan Dutch localization and business logic requirements
6. 🧪 Design test strategy to meet 90%+ coverage standards
7. 📊 Consider performance impact on established metrics

### Implementation Order (Non-Negotiable)
1. DESIGN SYSTEM FIRST: Use existing UnifiedHeader, UnifiedButton, UnifiedCard components
2. BUSINESS LOGIC SECOND: Implement Dutch validation, authentication, role-based access
3. USER INTERFACE THIRD: Build UI using unified components, test with all user roles
4. TESTING THROUGHOUT: Write tests as you implement (not after)
5. LOCALIZATION & PERFORMANCE: Add Dutch strings, validate performance metrics

## DESIGN SYSTEM BEST PRACTICES

### Component Selection Guide
✅ PREFERRED: Use unified components
- UnifiedHeader.simple(title: 'Beveiligingsopdrachten', userRole: UserRole.guard)
- UnifiedButton.primary(text: 'Solliciteren', onPressed: () {})
- UnifiedCard.standard(userRole: UserRole.company, child: content)

### Role-Based Theming Strategy
Build theme-aware components that automatically adapt to user roles:
```dart
Widget buildJobCard(JobData job, UserRole userRole) {
  return UnifiedCard.standard(
    userRole: userRole,  // Automatic theme application
    child: Column(
      children: [
        Text(job.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: DesignTokens.fontWeightSemiBold,
        )),
        UnifiedButton.primary(
          text: userRole == UserRole.guard ? 'Solliciteren' : 'Bekijk Kandidaten',
          onPressed: () => _handleJobAction(job, userRole),
        ),
      ],
    ),
  );
}
```

## DUTCH-FIRST DEVELOPMENT

### Business Logic Integration
- Currency: NumberFormat.currency(locale: 'nl_NL', symbol: '€')
- Dates: DateFormat('dd-MM-yyyy', 'nl_NL')
- Phone: Format as +31 6 12345678 or 020 1234567
- KvK: 8-digit validation with proper formatting
- Postal codes: 1234AB format validation

### String Management
Maintain comprehensive Dutch translations for:
- User roles: 'guard' → 'Beveiliger', 'company' → 'Bedrijf', 'admin' → 'Beheerder'
- Job status: 'pending' → 'In behandeling', 'accepted' → 'Geaccepteerd'
- Common actions: 'apply' → 'Solliciteren', 'cancel' → 'Annuleren'

## TESTING EXCELLENCE

### Test Structure Patterns
Comprehensive test coverage with:
- Authentication flow tests for all user roles
- Job application flow tests with realistic scenarios
- Performance tests validating <1s loading requirements
- Integration tests for complete user journeys
- Widget tests for UI component rendering

### Performance Testing Integration
Monitor and validate:
- Dashboard loading: <1000ms
- Screen navigation: <300ms
- Memory usage: <150MB average
- Test execution: All 68+ tests must pass

## SECURITY BEST PRACTICES

### Authentication & Authorization
Implement role-based access control:
- Job posting: Company + Admin only
- Job application: Guard only
- User management: Admin only
- Protected routes with proper authorization checks

### Input Validation Patterns
Comprehensive validation for:
- Email addresses with proper regex
- KvK numbers with 8-digit validation
- Dutch postal codes with 1234AB format
- Phone numbers with Dutch format validation

## QUALITY ASSURANCE

### Code Review Checklist
Before submitting any code, verify:
✅ Uses unified design system components (no custom styling)
✅ Implements role-based theming for all user types
✅ Includes comprehensive Dutch localization
✅ Achieves 90%+ test coverage for business logic
✅ Passes flutter analyze with 0 issues
✅ Maintains template consistency patterns
✅ Implements proper security measures
✅ Meets performance requirements (<2s startup, <300ms navigation)
✅ Includes proper error handling and validation
✅ Documents any new patterns or components

### Performance Monitoring
Track and ensure:
- App startup time: <2 seconds
- Screen navigation: <300ms
- Memory usage: <150MB average
- Test coverage: 90%+ business logic, 80%+ overall

## SUCCESS METRICS & CONTINUOUS IMPROVEMENT

### Quality Gates (Must Pass)
Every feature implementation must achieve:
✅ Flutter analyze: 0 issues (mandatory)
✅ Test coverage: 90%+ business logic, 80%+ overall
✅ Performance: <2s startup, <300ms navigation
✅ Design consistency: 100% unified component usage
✅ Dutch localization: Complete business logic compliance
✅ Security: Role-based access control implemented
✅ Template compliance: Maintained Flutter UI Template standards

### When to Ask for Clarification
Request clarification when:
- Business logic requirements are unclear or conflict with existing patterns
- Security implications are complex or require architectural decisions
- Dutch business rules need verification or expansion
- Performance requirements cannot be met with current architecture
- Design system components don't cover new use cases
- Testing strategies need adjustment for complex scenarios

GOAL: Maintain Securyflex as a world-class Dutch security marketplace platform with enterprise-grade reliability, consistency, and user experience while enabling strategic growth and innovation.
```

## 🚀 **IMPLEMENTATION INSTRUCTIONS**

### **Step 1: Copy Rules Section**
Copy the entire "RULES SECTION" content above and paste it into your Augment Code Rules field.

### **Step 2: Copy User Guidelines Section**  
Copy the entire "USER GUIDELINES SECTION" content above and paste it into your Augment Code User Guidelines field.

### **Step 3: Verify Configuration**
Ensure both sections are properly configured in your Augment Code settings and test with a simple query to verify the AI follows the established patterns.

**✅ READY TO USE: These guidelines are specifically tailored to your Securyflex project and will ensure consistent, high-quality development that maintains your established standards.**
