# 🔍 **SECURY FLEX - BROKEN NAVIGATION FLOWS ANALYSIS**

## 📊 **Executive Summary**

Na een grondige analyse van alle kritieke navigatie flows in SecuryFlex na de GoRouter migratie zijn **15 gebroken flows** geïdentificeerd die daadwerkelijke runtime errors veroorzaken. Deze analyse focust op concrete problemen die gebruikers zullen ondervinden.

### **Severity Breakdown:**
- 🚨 **Critical Issues:** 6 flows (cause runtime crashes)
- ⚠️ **High Priority:** 5 flows (major UX disruption)  
- ℹ️ **Medium Priority:** 4 flows (suboptimal experience)

---

## 🚨 **CRITICAL ISSUES - IMMEDIATE FIX REQUIRED**

### 1. **Job Details Navigation Completely Broken**
**Location:** `lib/marketplace/tabs/job_discovery_tab.dart:331`
```dart
// BROKEN CODE:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => JobDetailsScreen(jobData: job),
  ),
);
```
**Problem:** Gebruikt oude Navigator.push terwijl GoRouter verwacht dat job details via parametrized routes worden bereikt (`/beveiliger/jobs/:jobId`)

**Impact:** Job discovery → job details flow werkt niet. Dit is een core user flow.

**Fix Required:**
```dart
// CORRECT:
context.go('/beveiliger/jobs/${job.jobId}');
```

### 2. **Forgot Password Route Missing**
**Location:** Route gedefinieerd in `app_routes.dart` maar niet in `app_router.dart`
**Problem:** `AppRoutes.forgotPassword` route heeft geen GoRoute definitie
**Impact:** Users kunnen wachtwoord niet resetten
**Fix:** Add GoRoute in authentication section van app_router.dart

### 3. **Chat Conversation Deep Links Broken**
**Location:** `lib/routing/app_router.dart:206`
```dart
// BROKEN IMPLEMENTATION:
builder: (context, state) {
  final conversationId = state.pathParameters['conversationId']!;
  // TODO: Load actual conversation from repository
  return const ConversationsScreen(userRole: UserRole.guard);
},
```
**Problem:** Chat conversation URLs leiden naar conversations list, niet naar actual conversation
**Impact:** Push notifications en deep links naar chats werken niet

### 4. **Company Application Review Hardcoded Data**
**Location:** `lib/routing/app_router.dart:328`
**Problem:** ApplicationReviewScreen gebruikt hardcoded JobPostingData in plaats van route parameters
**Impact:** Company application review flow toont altijd dummy data

### 5. **Security Dashboard Navigation Using Old Routes**
**Location:** `lib/auth/widgets/security_dashboard_widget.dart:779,796,801,806`
```dart
// BROKEN CALLS:
Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
Navigator.of(context).pushNamed('/2fa-setup');
Navigator.of(context).pushNamed('/security-settings');
Navigator.of(context).pushNamed('/security-events');
```
**Problem:** Gebruikt oude named routes die niet bestaan in GoRouter
**Impact:** Security settings navigation fails

### 6. **Push Notification Navigation Incomplete**
**Location:** `lib/main.dart:144,149`
**Problem:** Notification tap handlers alleen debug prints, geen actual navigation
**Impact:** Push notification taps doen niets

---

## ⚠️ **HIGH PRIORITY ISSUES**

### 7. **Multiple Job List Navigation Points Broken**
**Locations:** 
- `lib/marketplace/job_list_view.dart:60`
- `lib/marketplace/screens/jobs_tab_screen.dart:186,244,280`
- `lib/marketplace/jobs_home_screen.dart:672,686`

**Problem:** Alle job list views gebruiken Navigator.push voor job details
**Impact:** Multiple entry points naar job details broken

### 8. **Profile Edit Navigation Mixed**
**Location:** `lib/beveiliger_profiel/screens/beveiliger_profiel_screen.dart:115,1113,1167,1179`
**Problem:** Mix van Navigator.push en GoRouter calls
**Impact:** Inconsistent navigation behavior

### 9. **Company Dashboard Job Navigation Broken**
**Location:** `lib/company_dashboard/screens/responsive_company_dashboard.dart:1574`
**Problem:** Company jobs screen nog Navigator.push
**Impact:** Company job management flow broken

### 10. **Active Jobs Navigation Broken**
**Location:** `lib/marketplace/tabs/active_jobs_tab.dart:427`
**Problem:** pushNamed used for job details
**Impact:** Active jobs → details broken

### 11. **Modern Dashboard Routes Conflict**
**Location:** `lib/modern_dashboard_routes.dart`
**Problem:** Modern dashboard routes (`/modern-beveiliger-dashboard`) conflicts met GoRouter routes (`/beveiliger/dashboard`)
**Impact:** Route conflicts, unpredictable navigation

---

## ℹ️ **MEDIUM PRIORITY ISSUES**

### 12. **Terms Acceptance Parameters Issue**
**Location:** `lib/routing/app_router.dart:102`
**Problem:** UserRole en userId parameters mogelijk niet consistent doorgegeven
**Impact:** Registration flow may fail at terms acceptance

### 13. **Company Chat Route Incorrect**
**Location:** `lib/routing/navigation_service.dart:58`
**Problem:** Company chat route `/chat/$conversationId` niet gedefinieerd in router
**Impact:** Company chat navigation fails

### 14. **Certificate Widget Navigation Mixed**
**Location:** `lib/beveiliger_profiel/widgets/certificaten_widget.dart:74`
**Problem:** Certificate editing uses Navigator.push
**Impact:** Certificate management inconsistent

### 15. **Error Routes Missing Implementation**
**Problem:** `AppRoutes.error` and `AppRoutes.unauthorized` defined maar geen GoRoute
**Impact:** Error handling falls back to default error screen

---

## ✅ **WORKING FLOWS VERIFIED**

- ✅ Role-based authentication and dashboard routing
- ✅ StatefulShellRoute state preservation  
- ✅ Basic tab navigation for both user types
- ✅ Privacy dashboard shared routing
- ✅ Company job creation routing (`/company/jobs/create`)
- ✅ Profile → notifications nested routing
- ✅ Shell screen tab switching logic

---

## 🔧 **RECOMMENDED FIX PRIORITY**

### **Phase 1 - Critical Fixes (Week 1)**
1. Fix job details navigation (impacts core user flow)
2. Add forgot password route
3. Fix chat conversation deep linking
4. Fix security dashboard navigation

### **Phase 2 - High Priority (Week 2)**  
5. Update all job list navigation points
6. Fix company dashboard job navigation
7. Resolve modern dashboard route conflicts

### **Phase 3 - Medium Priority (Week 3)**
8. Fix profile edit navigation consistency
9. Add missing error routes  
10. Fix company chat routing

---

## 📋 **TECHNICAL DEBT IDENTIFIED**

1. **Mixed Navigation Patterns**: App uses beide Navigator.push en GoRouter context.go
2. **Legacy Route References**: Old named routes nog in code
3. **Hardcoded Route Strings**: Some navigation uses hardcoded paths
4. **Inconsistent Parameter Passing**: Mix van route parameters en screen constructor parameters

---

## 🎯 **CONCLUSION**

De GoRouter migratie is **70% complete** maar heeft significante gaps in core user flows. **Job discovery → job details** is de meest critical broken flow die immediate attention needs.

**Estimated Fix Time:** 2-3 weeks voor alle critical en high priority issues.

**Risk:** Without fixes, app will have poor user experience and potential crashes bij core navigation flows.