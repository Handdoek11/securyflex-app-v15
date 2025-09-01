# 📡 SECURYFLEX API DOCUMENTATION

## 📋 **OVERVIEW**

SecuryFlex uses Firebase as its backend infrastructure, providing real-time data synchronization, authentication, and cloud functions. This document outlines the API structure, data models, and integration patterns.

**Base URL**: `https://securyflex-dev-default-rtdb.europe-west1.firebasedatabase.app/`
**Firestore Database**: `securyflex-dev`
**Region**: `europe-west1`

---

## 🔐 **AUTHENTICATION**

### **Authentication Methods**
- **Email/Password**: Primary authentication method
- **Google Sign-In**: Social authentication option
- **Demo Mode**: Development and testing

### **User Roles**
```typescript
enum UserRole {
  GUARD = 'guard',      // Security personnel
  COMPANY = 'company',  // Business clients
  ADMIN = 'admin'       // Platform administrators
}
```

### **Authentication Flow**
```dart
// Login
final result = await AuthService.login(email, password);

// Get current user
final user = AuthService.currentUser;

// Check user role
final role = AuthService.currentUserType;

// Logout
await AuthService.logout();
```

---

## 📊 **DATA MODELS**

### **User Model**
```typescript
interface User {
  uid: string;
  email: string;
  displayName: string;
  role: UserRole;
  isEmailVerified: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  profile: UserProfile;
  preferences: UserPreferences;
}

interface UserProfile {
  firstName: string;
  lastName: string;
  phoneNumber?: string;
  address?: Address;
  profileImageUrl?: string;
  bio?: string;
}
```

### **Job Model**
```typescript
interface Job {
  id: string;
  companyId: string;
  title: string;
  description: string;
  location: Address;
  jobType: JobType;
  requirements: string[];
  hourlyRate: number;
  startDate: Timestamp;
  endDate: Timestamp;
  status: JobStatus;
  maxApplicants: number;
  currentApplicants: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

enum JobStatus {
  OPEN = 'open',
  CLOSED = 'closed',
  FILLED = 'filled',
  PAUSED = 'paused'
}
```

### **Application Model**
```typescript
interface Application {
  id: string;
  jobId: string;
  guardId: string;
  companyId: string;
  status: ApplicationStatus;
  message: string;
  applicationDate: Timestamp;
  responseDate?: Timestamp;
  responseMessage?: string;
  rating?: number;
  feedback?: string;
}

enum ApplicationStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
  WITHDRAWN = 'withdrawn'
}
```

---

## 🔥 **FIRESTORE COLLECTIONS**

### **Users Collection**
```
/users/{userId}
```
**Security Rules**: Users can read/write their own data, admins can read all

### **Jobs Collection**
```
/jobs/{jobId}
```
**Security Rules**: 
- Companies can create/edit their own jobs
- Guards can read open jobs
- Admins have full access

### **Applications Collection**
```
/applications/{applicationId}
```
**Security Rules**:
- Guards can create applications and read their own
- Companies can read applications for their jobs
- Admins have full access

### **Conversations Collection**
```
/conversations/{conversationId}
  /messages/{messageId}
  /typing/{userId}
```
**Security Rules**: Only participants can access conversation data

---

## 🛠 **SERVICE CLASSES**

### **AuthService**
```dart
class AuthService {
  static Future<bool> login(String email, String password);
  static Future<bool> register(String email, String password, UserRole role);
  static Future<void> logout();
  static Future<void> resetPassword(String email);
  static User? get currentUser;
  static String? get currentUserType;
  static bool get isLoggedIn;
}
```

### **JobPostingService**
```dart
class JobPostingService {
  static Future<List<JobData>> getAvailableJobs();
  static Future<List<JobData>> getJobsByCompany(String companyId);
  static Future<JobData?> getJobById(String jobId);
  static Future<bool> createJob(JobData job);
  static Future<bool> updateJob(JobData job);
  static Future<bool> deleteJob(String jobId);
}
```

### **ApplicationService**
```dart
class ApplicationService {
  static Future<bool> submitApplication(String jobId, String message);
  static Future<List<ApplicationData>> getApplicationsByGuard(String guardId);
  static Future<List<ApplicationData>> getApplicationsByJob(String jobId);
  static Future<bool> updateApplicationStatus(String applicationId, ApplicationStatus status);
  static Future<bool> withdrawApplication(String applicationId);
}
```

---

## 💬 **CHAT SYSTEM API**

### **Conversation Management**
```dart
class ConversationService {
  static Future<String> createConversation(List<String> participants);
  static Future<List<Conversation>> getUserConversations(String userId);
  static Stream<List<Message>> getMessages(String conversationId);
  static Future<bool> sendMessage(String conversationId, String content);
  static Future<bool> markAsRead(String conversationId, String userId);
}
```

### **Real-time Features**
```dart
class PresenceService {
  static Future<void> setUserOnline(String userId);
  static Future<void> setUserOffline(String userId);
  static Stream<bool> getUserPresence(String userId);
  static Future<void> setTyping(String conversationId, bool isTyping);
  static Stream<List<String>> getTypingUsers(String conversationId);
}
```

---

## 📈 **ANALYTICS API**

### **Event Tracking**
```dart
class AnalyticsService {
  static void trackJobView(String jobId);
  static void trackApplicationSubmitted(String jobId);
  static void trackUserLogin(UserRole role);
  static void trackScreenView(String screenName);
  static void trackCustomEvent(String eventName, Map<String, dynamic> parameters);
}
```

### **Performance Metrics**
```dart
class PerformanceService {
  static void trackAppStartup(Duration duration);
  static void trackNavigationTime(String route, Duration duration);
  static void trackApiResponse(String endpoint, Duration duration);
  static void trackMemoryUsage(int memoryMB);
}
```

---

## 🔍 **SEARCH & FILTERING**

### **Job Search API**
```dart
class JobSearchService {
  static Future<List<JobData>> searchJobs({
    String? query,
    List<String>? jobTypes,
    String? location,
    double? minRate,
    double? maxRate,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  static Future<List<JobData>> getRecommendedJobs(String guardId);
  static Future<List<JobData>> getFavoriteJobs(String guardId);
}
```

### **Filter Options**
```typescript
interface JobFilters {
  jobTypes: JobType[];
  locations: string[];
  hourlyRateRange: [number, number];
  dateRange: [Date, Date];
  requirements: string[];
  companyRating: number;
}
```

---

## 🔔 **NOTIFICATIONS API**

### **Push Notifications**
```dart
class NotificationService {
  static Future<void> initialize();
  static Future<String?> getToken();
  static Future<void> subscribeToTopic(String topic);
  static Future<void> unsubscribeFromTopic(String topic);
  static void handleForegroundMessage(RemoteMessage message);
  static void handleBackgroundMessage(RemoteMessage message);
}
```

### **In-App Notifications**
```dart
class InAppNotificationService {
  static Stream<List<Notification>> getNotifications(String userId);
  static Future<bool> markAsRead(String notificationId);
  static Future<bool> markAllAsRead(String userId);
  static Future<int> getUnreadCount(String userId);
}
```

---

## 🌍 **LOCALIZATION API**

### **Dutch Business Logic**
```dart
class DutchBusinessLogic {
  static String formatCurrency(double amount);
  static String formatDate(DateTime date);
  static String formatPhoneNumber(String phone);
  static bool validateKvKNumber(String kvk);
  static bool validatePostalCode(String postalCode);
  static List<String> getDutchRegions();
  static List<String> getCitiesByRegion(String region);
}
```

### **Validation Patterns**
```dart
class DutchValidators {
  static final RegExp kvkPattern = RegExp(r'^\d{8}$');
  static final RegExp postalCodePattern = RegExp(r'^\d{4}\s?[A-Z]{2}$');
  static final RegExp phonePattern = RegExp(r'^(\+31|0)[1-9]\d{8}$');
  static final RegExp ibanPattern = RegExp(r'^NL\d{2}[A-Z]{4}\d{10}$');
}
```

---

## 🚨 **ERROR HANDLING**

### **Error Types**
```typescript
enum ErrorType {
  AUTHENTICATION_ERROR = 'auth_error',
  PERMISSION_DENIED = 'permission_denied',
  NOT_FOUND = 'not_found',
  VALIDATION_ERROR = 'validation_error',
  NETWORK_ERROR = 'network_error',
  SERVER_ERROR = 'server_error'
}

interface ApiError {
  type: ErrorType;
  message: string;
  code: string;
  details?: any;
}
```

### **Error Handling Pattern**
```dart
try {
  final result = await JobPostingService.createJob(jobData);
  return result;
} on FirebaseAuthException catch (e) {
  throw AuthenticationError(e.message ?? 'Authentication failed');
} on FirebaseException catch (e) {
  throw ApiError(e.code, e.message ?? 'Unknown error');
} catch (e) {
  throw ApiError('unknown_error', e.toString());
}
```

---

## 📊 **RATE LIMITS & QUOTAS**

### **Firestore Limits**
- **Reads**: 50,000 per day (free tier)
- **Writes**: 20,000 per day (free tier)
- **Deletes**: 20,000 per day (free tier)
- **Document Size**: 1 MB maximum
- **Collection Depth**: 100 levels maximum

### **Authentication Limits**
- **Sign-in Attempts**: 5 per IP per hour
- **Password Reset**: 5 per email per hour
- **Account Creation**: 100 per IP per hour

---

## 🔧 **DEVELOPMENT TOOLS**

### **Firebase Emulator**
```bash
# Start emulators
firebase emulators:start

# Run with specific ports
firebase emulators:start --only firestore,auth
```

### **API Testing**
```dart
// Test environment setup
void main() {
  setUpAll(() async {
    await Firebase.initializeApp();
    await AuthService.loginWithDemo();
  });
  
  test('should create job successfully', () async {
    final job = JobData(/* test data */);
    final result = await JobPostingService.createJob(job);
    expect(result, isTrue);
  });
}
```

---

## 📞 **SUPPORT & RESOURCES**

### **Documentation Links**
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)

### **Support Channels**
- **Technical Support**: dev@securyflex.nl
- **API Issues**: api@securyflex.nl
- **Emergency**: +31 20 123 4567

**Last Updated**: 2025-01-14
**API Version**: 1.0.0
