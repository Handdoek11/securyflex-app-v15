# 🛡️ SECURYFLEX AUGMENT CODE RULES - MANDATORY TECHNICAL CONSTRAINTS

## 🚨 **CRITICAL PROJECT CONTEXT**

### **Project Identity**
**Securyflex** is a Dutch security marketplace platform connecting security personnel (beveiligers) with businesses. This is NOT a generic app but a **strategic platform ecosystem** with:
- **Multi-role architecture**: Guard/Company/Admin with distinct theming
- **Dutch-first business logic**: KvK validation, postal codes, phone numbers
- **Enterprise-grade security**: Multi-user authentication, data protection
- **100% template consistency**: Maintained Flutter UI Template standards

---

## 🔒 **MANDATORY TECHNICAL RULES**

### **1. UNIFIED DESIGN SYSTEM COMPLIANCE**
```dart
// ✅ REQUIRED: Always use unified components
UnifiedHeader.simple(title: 'Title', userRole: UserRole.guard)
UnifiedButton.primary(text: 'Action', onPressed: () {})
UnifiedCard.standard(userRole: UserRole.company, child: content)

// ✅ REQUIRED: Always use design tokens
DesignTokens.colorPrimaryBlue     // Never hardcode colors
DesignTokens.spacingM             // Never hardcode spacing
DesignTokens.fontWeightSemiBold   // Never hardcode typography
DesignTokens.shadowMedium         // Never hardcode shadows

// ❌ FORBIDDEN: Direct Material/Cupertino components
Container()                       // Use UnifiedCard instead
ElevatedButton()                  // Use UnifiedButton instead
AppBar()                         // Use UnifiedHeader instead
```

### **2. ROLE-BASED THEMING ENFORCEMENT**
```dart
// ✅ REQUIRED: Every component must support UserRole
enum UserRole { guard, company, admin }

// ✅ REQUIRED: Theme application
MaterialApp(
  theme: SecuryFlexTheme.getTheme(currentUserRole),
)

// ✅ REQUIRED: Role-specific colors
UserRole.guard    -> Navy Blue (#1E3A8A) + Teal (#54D3C2)
UserRole.company  -> Teal (#54D3C2) + Navy Blue (#1E3A8A)  
UserRole.admin    -> Charcoal (#2D3748) + Orange (#F59E0B)
```

### **3. DUTCH BUSINESS LOGIC REQUIREMENTS**
```dart
// ✅ REQUIRED: Dutch validation patterns
class DutchValidators {
  static bool isValidKvK(String kvk) {
    return RegExp(r'^\d{8}$').hasMatch(kvk);
  }
  
  static bool isValidPostalCode(String postcode) {
    return RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(postcode.toUpperCase());
  }
  
  static bool isValidDutchPhone(String phone) {
    return RegExp(r'^(\+31|0)[1-9]\d{8}$').hasMatch(phone.replaceAll(' ', ''));
  }
}

// ✅ REQUIRED: Dutch localization
const Locale('nl', 'NL')
DateFormat('dd-MM-yyyy', 'nl_NL')
NumberFormat.currency(locale: 'nl_NL', symbol: '€')
```

### **4. TEMPLATE CONSISTENCY ENFORCEMENT**
```dart
// ✅ REQUIRED: File organization pattern
lib/
├── auth/                    // Authentication module
├── beveiliger_dashboard/    // Guard dashboard
├── marketplace/            // Job marketplace
├── unified_*.dart          // Design system components
└── main.dart              // Entry point

// ✅ REQUIRED: Naming conventions
BeveiligerDashboardHome     // Module + Component + Type
ApplicationService          // Business + Service
DutchDateUtils             // Scope + Utility
```

### **5. TESTING REQUIREMENTS**
```dart
// ✅ REQUIRED: Test coverage standards
- Unit Tests: 90%+ for business logic
- Widget Tests: 80%+ for UI components  
- Integration Tests: 70%+ for user flows
- Template Consistency Tests: 100%

// ✅ REQUIRED: Test patterns
group('Authentication Functionality Tests', () {
  test('Login with valid guard credentials should succeed', () async {
    final success = await AuthService.login('guard@securyflex.nl', 'guard123');
    expect(success, isTrue);
    expect(AuthService.currentUserType, equals('guard'));
  });
});
```

---

## 🚫 **ABSOLUTE PROHIBITIONS**

### **Never Do These:**
❌ **Hardcode any styling values** (colors, fonts, spacing, shadows)
❌ **Create custom components** without checking unified alternatives
❌ **Mix different theme systems** or ignore role-based theming
❌ **Use English strings** in user-facing text (Dutch-first requirement)
❌ **Skip input validation** for Dutch business logic (KvK, postal codes)
❌ **Ignore template patterns** established in the codebase
❌ **Create tests with <90% coverage** for business logic
❌ **Use setState** for complex state management (follow template patterns)

### **Security Violations:**
❌ **Store sensitive data** without encryption
❌ **Skip authentication checks** for protected routes
❌ **Expose API keys** or credentials in client code
❌ **Allow unvalidated user input** in any form
❌ **Implement features** without role-based access control

---

## ⚡ **PERFORMANCE REQUIREMENTS**

### **Mandatory Performance Standards:**
- **App startup**: <2 seconds cold start
- **Navigation**: <300ms between screens
- **API responses**: <1 second handling
- **Memory usage**: <150MB average
- **Test execution**: All 68+ tests must pass

### **Code Quality Gates:**
```bash
# ✅ REQUIRED: Zero issues
flutter analyze --fatal-infos

# ✅ REQUIRED: All tests pass
flutter test

# ✅ REQUIRED: Coverage standards
flutter test --coverage
```

---

## 🔄 **DEVELOPMENT WORKFLOW RULES**

### **Mandatory Sequence:**
1. **Read Documentation**: Always check docs/UNIFIED_DESIGN_SYSTEM.md first
2. **Use Codebase Retrieval**: Understand existing patterns before coding
3. **Follow Template Standards**: Maintain 100% consistency
4. **Implement Role-Based Theming**: Support all three user roles
5. **Add Dutch Localization**: All user-facing text in Dutch
6. **Write Comprehensive Tests**: Meet coverage requirements
7. **Validate Performance**: Ensure standards are met

### **Quality Verification:**
```dart
// ✅ REQUIRED: Before any commit
- Flutter analyze: 0 issues
- All tests passing: 68+ tests
- Design system compliance: 100%
- Dutch localization: Complete
- Role-based theming: Implemented
- Template consistency: Maintained
```

---

## 📋 **COMPLIANCE CHECKLIST**

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

**VIOLATION OF THESE RULES RESULTS IN IMMEDIATE REJECTION OF CODE CHANGES**
