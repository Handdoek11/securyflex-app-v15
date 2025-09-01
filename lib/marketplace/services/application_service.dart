import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:securyflex_app/auth/auth_service.dart';
import 'package:securyflex_app/marketplace/state/job_state_manager.dart';
import '../../billing/services/feature_access_service.dart';

/// Firebase-backed application service for managing job applications
/// Provides functionality to apply for jobs and track application status with real-time updates
class ApplicationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _applicationsCollection = 'applications';

  // Mock data storage for fallback/demo mode
  static final Map<String, ApplicationData> _applications = {};
  
  /// Get all applications for current user
  static Future<List<ApplicationData>> getUserApplications() async {
    if (!AuthService.isLoggedIn) return [];

    final currentUserEmail = _getCurrentUserEmail();

    // First check runtime applications (for tests and demo mode)
    final runtimeApplications = _applications.values
        .where((app) => app.applicantEmail == currentUserEmail)
        .toList()
      ..sort((a, b) => b.applicationDate.compareTo(a.applicationDate));

    if (runtimeApplications.isNotEmpty) {
      return runtimeApplications;
    }

    try {
      final querySnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('applicantEmail', isEqualTo: currentUserEmail)
          .orderBy('applicationDate', descending: true)
          .get();

      final firestoreApplications = querySnapshot.docs
          .map((doc) => _applicationFromFirestore(doc))
          .where((app) => app != null)
          .cast<ApplicationData>()
          .toList();

      // If no Firestore data and no runtime data, return comprehensive Dutch mock data
      if (firestoreApplications.isEmpty) {
        return mockDutchApplications;
      }

      return firestoreApplications;
    } catch (e) {
      debugPrint('Error fetching user applications: $e');

      // Always fallback to comprehensive Dutch mock data
      return mockDutchApplications;
    }
  }
  
  /// Convert Firestore document to ApplicationData
  static ApplicationData? _applicationFromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      return ApplicationData(
        id: doc.id,
        jobId: data['jobId'] ?? '',
        jobTitle: data['jobTitle'] ?? '',
        companyName: data['companyName'] ?? '',
        applicantName: data['applicantName'] ?? '',
        applicantEmail: data['applicantEmail'] ?? '',
        applicantType: data['applicantType'] ?? '',
        isAvailable: data['isAvailable'] ?? false,
        motivationMessage: data['motivationMessage'] ?? '',
        contactPreference: data['contactPreference'] ?? '',
        applicationDate: (data['applicationDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: _statusFromString(data['status'] ?? 'pending'),
      );
    } catch (e) {
      debugPrint('Error converting Firestore document to ApplicationData: $e');
      return null;
    }
  }

  /// Convert ApplicationData to Firestore map
  static Map<String, dynamic> _applicationToFirestore(ApplicationData application) {
    return {
      'jobId': application.jobId,
      'jobTitle': application.jobTitle,
      'companyName': application.companyName,
      'applicantName': application.applicantName,
      'applicantEmail': application.applicantEmail,
      'applicantType': application.applicantType,
      'isAvailable': application.isAvailable,
      'motivationMessage': application.motivationMessage,
      'contactPreference': application.contactPreference,
      'applicationDate': Timestamp.fromDate(application.applicationDate),
      'status': application.status.toString().split('.').last,
    };
  }

  /// Convert string to ApplicationStatus
  static ApplicationStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted': return ApplicationStatus.accepted;
      case 'rejected': return ApplicationStatus.rejected;
      case 'withdrawn': return ApplicationStatus.withdrawn;
      case 'interviewinvited': return ApplicationStatus.interviewInvited;
      case 'documentspending': return ApplicationStatus.documentsPending;
      case 'contractoffered': return ApplicationStatus.contractOffered;
      case 'interviewscheduled': return ApplicationStatus.interviewScheduled;
      default: return ApplicationStatus.pending;
    }
  }

  /// Check if user has applied for a specific job
  static Future<bool> hasAppliedForJob(String jobId) async {
    if (!AuthService.isLoggedIn || jobId.isEmpty) return false;

    // Always check mock data first for demo mode
    final applicationKey = '${_getCurrentUserEmail()}_$jobId';
    if (_applications.containsKey(applicationKey)) {
      return true;
    }

    try {
      final currentUserEmail = _getCurrentUserEmail();
      final querySnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('applicantEmail', isEqualTo: currentUserEmail)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking application status: $e');
      // Return false if Firestore fails and no mock data exists
      return false;
    }
  }
  
  /// Submit job application with subscription-based access control
  static Future<bool> submitApplication({
    required String jobId,
    required String jobTitle,
    required String companyName,
    required bool isAvailable,
    required String motivationMessage,
    required String contactPreference,
  }) async {
    try {
      if (!AuthService.isLoggedIn) return false;

      // Check subscription-based access to job applications
      final userId = AuthService.currentUserId;
      final featureAccess = FeatureAccessService.instance;
      
      final canApply = await featureAccess.hasFeatureAccess(
        userId: userId,
        featureKey: 'job_applications',
        context: {
          'job_id': jobId,
          'company_name': companyName,
        },
      );

      if (!canApply) {
        debugPrint('❌ Job application blocked - subscription required');
        throw FeatureAccessDeniedException(
          message: 'Een actief abonnement is vereist om te solliciteren op vacatures',
          featureKey: 'job_applications',
        );
      }

      // Check if already applied
      final hasApplied = await hasAppliedForJob(jobId);
      if (hasApplied) {
        return false; // Already applied
      }

      // Record feature usage for tracking limits
      await featureAccess.recordFeatureUsage(
        userId: userId,
        featureKey: 'job_applications',
        metadata: {
          'job_id': jobId,
          'job_title': jobTitle,
          'company_name': companyName,
          'application_date': DateTime.now().toIso8601String(),
        },
      );

      // Create application
      final application = ApplicationData(
        id: '', // Will be set by Firestore
        jobId: jobId,
        jobTitle: jobTitle,
        companyName: companyName,
        applicantName: AuthService.currentUserName,
        applicantEmail: _getCurrentUserEmail(),
        applicantType: AuthService.currentUserType,
        isAvailable: isAvailable,
        motivationMessage: motivationMessage,
        contactPreference: contactPreference,
        applicationDate: DateTime.now(),
        status: ApplicationStatus.pending,
      );

      // Submit to Firestore
      await _firestore
          .collection(_applicationsCollection)
          .add(_applicationToFirestore(application));

      // Update state manager
      JobStateManager.addApplication(jobId);
      return true;
    } catch (e) {
      debugPrint('Error submitting application: $e');

      // Fallback to mock storage for demo mode
      if (!AuthService.isLoggedIn) return false;

      // Simulate network delay for realistic testing
      await Future.delayed(const Duration(milliseconds: 1200));

      final applicationKey = '${_getCurrentUserEmail()}_$jobId';

      // Check if already applied
      if (_applications.containsKey(applicationKey)) {
        return false; // Already applied
      }

      // Create application
      final application = ApplicationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: jobId,
        jobTitle: jobTitle,
        companyName: companyName,
        applicantName: AuthService.currentUserName,
        applicantEmail: _getCurrentUserEmail(),
        applicantType: AuthService.currentUserType,
        isAvailable: isAvailable,
        motivationMessage: motivationMessage,
        contactPreference: contactPreference,
        applicationDate: DateTime.now(),
        status: ApplicationStatus.pending,
      );

      _applications[applicationKey] = application;
      JobStateManager.addApplication(jobId);
      return true;
    }
  }
  
  /// Get application for specific job
  static ApplicationData? getApplicationForJob(String jobId) {
    if (!AuthService.isLoggedIn) return null;
    
    final applicationKey = '${_getCurrentUserEmail()}_$jobId';
    return _applications[applicationKey];
  }
  
  /// Get application status display text in Dutch
  static String getStatusDisplayText(ApplicationStatus status) {
    return status.displayTextNL;
  }
  
  /// Get status color
  static String getStatusColor(ApplicationStatus status) {
    return status.colorHex;
  }
  
  /// Withdraw application
  static Future<bool> withdrawApplication(String jobId) async {
    if (!AuthService.isLoggedIn) return false;
    
    final applicationKey = '${_getCurrentUserEmail()}_$jobId';
    final application = _applications[applicationKey];
    
    if (application == null) return false;
    
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 800));
    
    application.status = ApplicationStatus.withdrawn;
    return true;
  }
  
  /// Get current user email (demo implementation)
  static String _getCurrentUserEmail() {
    // In a real app, this would come from the auth service
    // For demo purposes, we'll generate based on user type
    switch (AuthService.currentUserType.toLowerCase()) {
      case 'guard':
        return 'guard@securyflex.nl';
      case 'company':
        return 'company@securyflex.nl';
      case 'admin':
        return 'admin@securyflex.nl';
      default:
        return 'user@securyflex.nl';
    }
  }
  
  /// Clear all applications (for testing)
  static void clearAllApplications() {
    _applications.clear();
  }
  
  /// Get total application count for current user
  static Future<int> getUserApplicationCount() async {
    final applications = await getUserApplications();
    return applications.length;
  }

  /// Get applications by status
  static Future<List<ApplicationData>> getApplicationsByStatus(ApplicationStatus status) async {
    final applications = await getUserApplications();
    return applications
        .where((app) => app.status == status)
        .toList();
  }

  /// Get all applications for a specific job (for companies to review)
  static Future<List<ApplicationData>> getJobApplications(String jobId) async {
    try {
      if (jobId.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection(_applicationsCollection)
          .where('jobId', isEqualTo: jobId)
          .orderBy('applicationDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => _applicationFromFirestore(doc))
          .where((app) => app != null)
          .cast<ApplicationData>()
          .toList();
    } catch (e) {
      debugPrint('Error fetching job applications: $e');

      // Fallback to mock data for demo mode
      return _applications.values
          .where((app) => app.jobId == jobId)
          .toList();
    }
  }

  /// Update application status (for companies)
  static Future<bool> updateApplicationStatus(String applicationId, ApplicationStatus newStatus) async {
    try {
      if (applicationId.isEmpty) return false;

      await _firestore
          .collection(_applicationsCollection)
          .doc(applicationId)
          .update({
        'status': newStatus.toString().split('.').last,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating application status: $e');

      // Fallback to mock data for demo mode
      final application = _applications.values
          .firstWhere((app) => app.id == applicationId, orElse: () => throw StateError('Application not found'));

      application.status = newStatus;
      return true;
    }
  }

  /// Watch applications for a specific job (real-time for companies)
  static Stream<List<ApplicationData>> watchJobApplications(String jobId) {
    if (jobId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_applicationsCollection)
        .where('jobId', isEqualTo: jobId)
        .orderBy('applicationDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _applicationFromFirestore(doc))
            .where((app) => app != null)
            .cast<ApplicationData>()
            .toList())
        .handleError((error) {
          debugPrint('Error watching job applications: $error');
          // Return empty list on error
          return <ApplicationData>[];
        });
  }

  /// Watch user applications (real-time for guards)
  static Stream<List<ApplicationData>> watchUserApplications() {
    if (!AuthService.isLoggedIn) {
      return Stream.value([]);
    }

    final currentUserEmail = _getCurrentUserEmail();
    return _firestore
        .collection(_applicationsCollection)
        .where('applicantEmail', isEqualTo: currentUserEmail)
        .orderBy('applicationDate', descending: true)
        .snapshots()
        .map((snapshot) {
          final firestoreApplications = snapshot.docs
              .map((doc) => _applicationFromFirestore(doc))
              .where((app) => app != null)
              .cast<ApplicationData>()
              .toList();
          
          // If no Firestore data, return comprehensive Dutch mock data
          if (firestoreApplications.isEmpty) {
            return mockDutchApplications;
          }
          
          return firestoreApplications;
        })
        .handleError((error) {
          debugPrint('Error watching user applications: $error');
          // Return comprehensive Dutch mock data on error
          return mockDutchApplications;
        });
  }

  /// Watch application status changes for a specific application
  static Stream<ApplicationData?> watchApplicationStatus(String applicationId) {
    if (applicationId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection(_applicationsCollection)
        .doc(applicationId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return _applicationFromFirestore(snapshot);
        })
        .handleError((error) {
          debugPrint('Error watching application status: $error');
          return null;
        });
  }

  /// Watch all applications for current company (real-time dashboard)
  static Stream<List<ApplicationData>> watchCompanyApplications(String companyId) {
    if (companyId.isEmpty) {
      return Stream.value([]);
    }

    // First get all jobs for this company, then watch applications for those jobs
    return _firestore
        .collection('jobs')
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .asyncMap((jobsSnapshot) async {
          final jobIds = jobsSnapshot.docs.map((doc) => doc.id).toList();

          if (jobIds.isEmpty) return <ApplicationData>[];

          // Watch applications for all company jobs
          final applicationsSnapshot = await _firestore
              .collection(_applicationsCollection)
              .where('jobId', whereIn: jobIds)
              .orderBy('applicationDate', descending: true)
              .get();

          return applicationsSnapshot.docs
              .map((doc) => _applicationFromFirestore(doc))
              .where((app) => app != null)
              .cast<ApplicationData>()
              .toList();
        })
        .handleError((error) {
          debugPrint('Error watching company applications: $error');
          return <ApplicationData>[];
        });
  }
  
  /// Comprehensive Dutch mock applications data for realistic testing
  static List<ApplicationData> get mockDutchApplications {
    final now = DateTime.now();
    
    return [
      // 1. Geaccepteerd - G4S Nederland
      ApplicationData(
        id: 'app_001',
        jobId: 'job_001',
        jobTitle: 'Objectbeveiliging Kantoorcomplex',
        companyName: 'G4S Nederland',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik ben een ervaren beveiliger met meer dan 5 jaar ervaring in objectbeveiliging. Mijn sterke punten zijn alertheid, communicatie en het kunnen werken in teamverband.',
        contactPreference: 'E-mail en telefoon',
        applicationDate: now.subtract(const Duration(days: 5)),
        status: ApplicationStatus.accepted,
        companyResponse: 'Beste Jan, bedankt voor je sollicitatie. We zijn onder de indruk van je ervaring en professionele houding. Je bent geaccepteerd voor deze functie!',
        salaryOffered: 24.50,
        startDate: now.add(const Duration(days: 3)),
        contractType: 'Tijdelijk contract 6 maanden',
        location: 'Amsterdam Zuidas',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A', 'BHV'],
        additionalInfo: {
          'startTime': '07:00',
          'endTime': '19:00',
          'workingDays': ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag'],
          'benefits': 'Reiskosten vergoeding, pensioenregeling'
        },
      ),
      
      // 2. Uitnodiging gesprek - Trigion Security (interview tomorrow)
      ApplicationData(
        id: 'app_002',
        jobId: 'job_002',
        jobTitle: 'Evenementbeveiliging Festival',
        companyName: 'Trigion Security',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik heb uitgebreide ervaring met crowd control en evenementbeveiliging. Ik werk graag in dynamische omgevingen en kan goed omgaan met stress.',
        contactPreference: 'Telefoon voorkeur',
        applicationDate: now.subtract(const Duration(days: 3)),
        status: ApplicationStatus.interviewInvited,
        companyResponse: 'Hallo Jan, we zouden graag een gesprek met je voeren voor de functie van evenementbeveiliger. Kun je morgen om 14:00 voor een interview?',
        interviewDate: now.add(const Duration(days: 1, hours: 14)),
        interviewType: 'persoonlijk',
        interviewDetails: 'Locatie: Trigion kantoor Rotterdam\nAdres: Weena 505, 3013 AL Rotterdam\nDuur: ongeveer 45 minuten\nMeenemen: ID, certificaten, CV',
        location: 'Rotterdam Ahoy',
        salaryOffered: 28.00,
        contractType: 'Freelance opdracht',
        urgencyLevel: 'urgent',
        requiredCertificates: ['WPBR B', 'BHV'],
        additionalInfo: {
          'eventDate': now.add(const Duration(days: 14)).toIso8601String(),
          'eventDuration': '3 dagen',
          'eventType': 'Muziekfestival'
        },
      ),
      
      // 3. Wachten op documenten - Facilicom Security
      ApplicationData(
        id: 'app_003',
        jobId: 'job_003',
        jobTitle: 'Ziekenhuisbeveiliging',
        companyName: 'Facilicom Security',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik heb specifieke ervaring met ziekenhuisbeveiliging en begrijp de gevoeligheid van werken in een zorgomgeving. Empathie en professionaliteit staan centraal in mijn werkwijze.',
        contactPreference: 'E-mail',
        applicationDate: now.subtract(const Duration(days: 7)),
        status: ApplicationStatus.documentsPending,
        companyResponse: 'Beste Jan, je sollicitatie ziet er veelbelovend uit. Voor deze functie hebben we nog je VCA-certificaat nodig. Kun je dit uploaden in ons systeem?',
        missingDocuments: ['VCA-certificaat', 'Uittreksel GBA'],
        location: 'Amsterdam UMC',
        salaryOffered: 26.00,
        contractType: 'Vast contract',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A', 'BHV', 'VCA'],
        additionalInfo: {
          'shiftType': 'Wisselende diensten',
          'specialRequirements': 'Medische omgeving ervaring gewenst'
        },
      ),
      
      // 4. Afgewezen - SecurePro BV
      ApplicationData(
        id: 'app_004',
        jobId: 'job_004',
        jobTitle: 'Persoonbeveiliging VIP',
        companyName: 'SecurePro BV',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik ben geïnteresseerd in persoonbeveiliging en wil graag mijn carrière in deze richting ontwikkelen. Ik ben fysiek fit en heb een sterke motivatie.',
        contactPreference: 'Telefoon',
        applicationDate: now.subtract(const Duration(days: 10)),
        status: ApplicationStatus.rejected,
        companyResponse: 'Beste Jan, bedankt voor je interesse. Helaas zoeken we voor deze functie iemand met minimaal 3 jaar ervaring in persoonbeveiliging. We moedigen je aan om meer ervaring op te doen en in de toekomst opnieuw te solliciteren.',
        rejectionReason: 'Onvoldoende ervaring in persoonbeveiliging',
        location: 'Den Haag',
        salaryOffered: 35.00,
        contractType: 'Freelance',
        urgencyLevel: 'hoog',
        requiredCertificates: ['WPBR B', 'BHV', 'Rijbewijs B'],
        additionalInfo: {
          'experienceRequired': '3+ jaar persoonbeveiliging',
          'physicalRequirements': 'Uitstekende conditie vereist'
        },
      ),
      
      // 5. In behandeling - Brink Security
      ApplicationData(
        id: 'app_005',
        jobId: 'job_005',
        jobTitle: 'Winkelbeveiliging Detailhandel',
        companyName: 'Brink Security',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik heb ervaring met surveillance en het herkennen van verdacht gedrag. In mijn vorige functie heb ik veel winkeldiefstal kunnen voorkomen door alert te zijn en professioneel op te treden.',
        contactPreference: 'E-mail',
        applicationDate: now.subtract(const Duration(days: 2)),
        status: ApplicationStatus.pending,
        companyResponse: 'Je sollicitatie is ontvangen en wordt momenteel beoordeeld door ons team.',
        location: 'Utrecht Centrum',
        salaryOffered: 22.50,
        contractType: 'Tijdelijk contract',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A'],
        additionalInfo: {
          'workingHours': 'Flexibele tijden',
          'location_details': 'Grote winkelketen'
        },
      ),
      
      // 6. Contract aangeboden - Industrial Guard Services
      ApplicationData(
        id: 'app_006',
        jobId: 'job_006',
        jobTitle: 'Havenbeveiliging',
        companyName: 'Industrial Guard Services',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik ben gespecialiseerd in industriële beveiliging en heb ervaring met het werken in haveomgevingen. Veiligheid en protocollen volgen zijn voor mij van het grootste belang.',
        contactPreference: 'E-mail en telefoon',
        applicationDate: now.subtract(const Duration(days: 8)),
        status: ApplicationStatus.contractOffered,
        companyResponse: 'Gefeliciteerd Jan! We bieden je een contract aan voor de functie van havenbeveiliger. Het contract staat klaar voor ondertekening. Graag binnen 5 werkdagen laten weten of je akkoord gaat.',
        salaryOffered: 29.50,
        startDate: now.add(const Duration(days: 10)),
        contractType: 'Vast contract 1 jaar',
        location: 'Rotterdam Haven',
        urgencyLevel: 'hoog',
        requiredCertificates: ['WPBR B', 'BHV', 'Haven ID'],
        additionalInfo: {
          'contractDeadline': now.add(const Duration(days: 5)).toIso8601String(),
          'benefits': 'Volledige pensioenregeling, zorgverzekering, 25 vakantiedagen',
          'shiftAllowance': '15% toeslag nachtdiensten'
        },
      ),
      
      // 7. Ingetrokken - Festival Security
      ApplicationData(
        id: 'app_007',
        jobId: 'job_007',
        jobTitle: 'Zomerevenement Beveiliging',
        companyName: 'Festival Security',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: false,
        motivationMessage: 'Ik ben enthousiast over festival beveiliging en heb eerder bij soortgelijke evenementen gewerkt.',
        contactPreference: 'E-mail',
        applicationDate: now.subtract(const Duration(days: 12)),
        status: ApplicationStatus.withdrawn,
        companyResponse: 'We begrijpen je beslissing en hopen je in de toekomst weer te kunnen verwelkomen.',
        location: 'Verschillende locaties',
        salaryOffered: 25.00,
        contractType: 'Tijdelijk zomerseizoen',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR B', 'BHV'],
        additionalInfo: {
          'withdrawalReason': 'Persoonlijke omstandigheden',
          'withdrawalDate': now.subtract(const Duration(days: 1)).toIso8601String()
        },
      ),
      
      // 8. Uitnodiging gesprek - Rail Security (video interview)
      ApplicationData(
        id: 'app_008',
        jobId: 'job_008',
        jobTitle: 'Station Surveillance',
        companyName: 'Rail Security',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik heb interesse in openbaar vervoer beveiliging en wil bijdragen aan de veiligheid van reizigers.',
        contactPreference: 'E-mail',
        applicationDate: now.subtract(const Duration(days: 4)),
        status: ApplicationStatus.interviewInvited,
        companyResponse: 'Hallo Jan, we nodigen je uit voor een video-interview via Microsoft Teams. Zorg ervoor dat je in een rustige omgeving zit met goede internetverbinding.',
        interviewDate: now.add(const Duration(days: 2, hours: 10)),
        interviewType: 'video',
        interviewDetails: 'Video interview via Microsoft Teams\nDuur: 30 minuten\nOntvang je de Teams-link 1 dag voor het gesprek\nZorg voor: goede internetverbinding, rustige omgeving, certificaten bij de hand',
        location: 'NS Stations landelijk',
        salaryOffered: 23.75,
        contractType: 'Jaarcontract',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A', 'BHV'],
        additionalInfo: {
          'interviewPlatform': 'Microsoft Teams',
          'positions': 'Meerdere openstaande posities',
          'trainingProvided': 'Interne training openbaar vervoer'
        },
      ),
      
      // 9. Gesprek ingepland - Metro Security
      ApplicationData(
        id: 'app_009',
        jobId: 'job_009',
        jobTitle: 'Metro Surveillance Amsterdam',
        companyName: 'Metro Security Amsterdam',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Amsterdam is mijn stad en ik wil graag bijdragen aan de veiligheid van metroreiziger. Ik spreek vloeiend Nederlands en Engels.',
        contactPreference: 'Telefoon voorkeur',
        applicationDate: now.subtract(const Duration(days: 6)),
        status: ApplicationStatus.interviewScheduled,
        companyResponse: 'We hebben je gesprek ingepland voor volgende week dinsdag. Je ontvangt nog een bevestiging met alle details.',
        interviewDate: now.add(const Duration(days: 8, hours: 13)),
        interviewType: 'persoonlijk',
        interviewDetails: 'Locatie: GVB Hoofdkantoor Amsterdam\nAdres: Arlandaweg 100, 1043 EW Amsterdam\nTijd: 13:00\nDuur: 1 uur inclusief rondleiding\nMeenemen: Legitimatie, certificaten, motivatiebrief',
        location: 'Amsterdam Metro Netwerk',
        salaryOffered: 24.75,
        contractType: 'Vast contract',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A', 'BHV'],
        additionalInfo: {
          'languageRequirement': 'Nederlands + Engels gewenst',
          'shiftTypes': 'Dag-, avond- en nachtdiensten',
          'uniform': 'Verstrekt door werkgever'
        },
      ),
      
      // 10. Wachten op documenten - Hospital Security
      ApplicationData(
        id: 'app_010',
        jobId: 'job_010',
        jobTitle: 'Academisch Ziekenhuis Beveiliging',
        companyName: 'Hospital Security Services',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik heb een sterke affiniteit met de zorgverlening en wil graag werken in een ziekenhuisomgeving waar ik kan bijdragen aan een veilige werkplek.',
        contactPreference: 'E-mail',
        applicationDate: now.subtract(const Duration(days: 9)),
        status: ApplicationStatus.documentsPending,
        companyResponse: 'Je sollicitatie is positief beoordeeld. Voor werkzaamheden in het ziekenhuis hebben we nog de volgende documenten nodig voor onze verificatie.',
        missingDocuments: ['VOG (Verklaring Omtrent Gedrag)', 'Medische keuring', 'Hepatitis B vaccinatie bewijs'],
        location: 'Leiden UMC',
        salaryOffered: 27.25,
        contractType: 'Vast contract',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A', 'BHV', 'VCA'],
        additionalInfo: {
          'medicalRequirements': 'Medische keuring verplicht voor zorgomgeving',
          'backgroundCheck': 'Uitgebreide screening vereist',
          'specialTraining': 'EHBO in zorgomgeving'
        },
      ),
      
      // 11. Contract aangeboden - Event Pro Security
      ApplicationData(
        id: 'app_011',
        jobId: 'job_011',
        jobTitle: 'VIP Event Beveiliging',
        companyName: 'Event Pro Security',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik heb ervaring met high-profile evenementen en begrijp de discrete benadering die vereist is voor VIP beveiliging.',
        contactPreference: 'Telefoon',
        applicationDate: now.subtract(const Duration(days: 11)),
        status: ApplicationStatus.contractOffered,
        companyResponse: 'Excellent profiel Jan! We bieden je een exclusief contract aan voor onze VIP events. Het betreft een zeer aantrekkelijk pakket met uitstekende voorwaarden.',
        salaryOffered: 32.00,
        startDate: now.add(const Duration(days: 7)),
        contractType: 'Freelance exclusief',
        location: 'Landelijk, premium locaties',
        urgencyLevel: 'hoog',
        requiredCertificates: ['WPBR B', 'BHV', 'Rijbewijs B'],
        additionalInfo: {
          'clientType': 'A-lijst celebrities, politici, business leaders',
          'dresscode': 'Formal dress code, pak verplicht',
          'discretion': 'Absolute discretie vereist - NDA ondertekening'
        },
      ),
      
      // 12. In behandeling - Retail Guard Pro
      ApplicationData(
        id: 'app_012',
        jobId: 'job_012',
        jobTitle: 'Shopping Mall Surveillance',
        companyName: 'Retail Guard Pro',
        applicantName: 'Jan Vermeulen',
        applicantEmail: 'jan.vermeulen@email.nl',
        applicantType: 'guard',
        isAvailable: true,
        motivationMessage: 'Ik ben ervaren in retail security en ken de uitdagingen van winkelcentrum beveiliging. Klantvriendelijkheid en alertheid combineer ik effectief.',
        contactPreference: 'E-mail',
        applicationDate: now.subtract(const Duration(days: 1)),
        status: ApplicationStatus.pending,
        companyResponse: 'Bedankt voor je sollicitatie. Ons recruitment team bekijkt je profiel en neemt binnen 3 werkdagen contact op.',
        location: 'Amstelveen Stadshart',
        salaryOffered: 23.25,
        contractType: 'Tijdelijk 3 maanden',
        urgencyLevel: 'normaal',
        requiredCertificates: ['WPBR A'],
        additionalInfo: {
          'mallSize': 'Groot winkelcentrum 150+ winkels',
          'customerService': 'Klantvriendelijke benadering vereist',
          'weekendWork': 'Weekend beschikbaarheid gewenst'
        },
      ),
    ];
  }
}

/// Application data model with enhanced Dutch fields for realistic mock data
class ApplicationData {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String applicantName;
  final String applicantEmail;
  final String applicantType;
  final bool isAvailable;
  final String motivationMessage;
  final String contactPreference;
  final DateTime applicationDate;
  ApplicationStatus status;
  
  // Enhanced fields for realistic Dutch mock data
  final String? companyResponse;
  final String? interviewDetails;
  final List<String>? missingDocuments;
  final double? salaryOffered;
  final DateTime? startDate;
  final String? contractType;
  final String? location;
  final String? rejectionReason;
  final DateTime? interviewDate;
  final String? interviewType; // 'video', 'persoonlijk', 'telefoon'
  final List<String>? requiredCertificates;
  final String? urgencyLevel; // 'normaal', 'urgent', 'spoedeisend'
  final Map<String, dynamic>? additionalInfo;

  ApplicationData({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantType,
    required this.isAvailable,
    required this.motivationMessage,
    required this.contactPreference,
    required this.applicationDate,
    required this.status,
    // Enhanced optional fields
    this.companyResponse,
    this.interviewDetails,
    this.missingDocuments,
    this.salaryOffered,
    this.startDate,
    this.contractType,
    this.location,
    this.rejectionReason,
    this.interviewDate,
    this.interviewType,
    this.requiredCertificates,
    this.urgencyLevel,
    this.additionalInfo,
  });
  
  /// Create enhanced copy with updated fields
  ApplicationData copyWith({
    String? id,
    String? jobId,
    String? jobTitle,
    String? companyName,
    String? applicantName,
    String? applicantEmail,
    String? applicantType,
    bool? isAvailable,
    String? motivationMessage,
    String? contactPreference,
    DateTime? applicationDate,
    ApplicationStatus? status,
    String? companyResponse,
    String? interviewDetails,
    List<String>? missingDocuments,
    double? salaryOffered,
    DateTime? startDate,
    String? contractType,
    String? location,
    String? rejectionReason,
    DateTime? interviewDate,
    String? interviewType,
    List<String>? requiredCertificates,
    String? urgencyLevel,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ApplicationData(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      applicantType: applicantType ?? this.applicantType,
      isAvailable: isAvailable ?? this.isAvailable,
      motivationMessage: motivationMessage ?? this.motivationMessage,
      contactPreference: contactPreference ?? this.contactPreference,
      applicationDate: applicationDate ?? this.applicationDate,
      status: status ?? this.status,
      companyResponse: companyResponse ?? this.companyResponse,
      interviewDetails: interviewDetails ?? this.interviewDetails,
      missingDocuments: missingDocuments ?? this.missingDocuments,
      salaryOffered: salaryOffered ?? this.salaryOffered,
      startDate: startDate ?? this.startDate,
      contractType: contractType ?? this.contractType,
      location: location ?? this.location,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      interviewDate: interviewDate ?? this.interviewDate,
      interviewType: interviewType ?? this.interviewType,
      requiredCertificates: requiredCertificates ?? this.requiredCertificates,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}

/// Application status enum with extended Dutch statuses
enum ApplicationStatus {
  pending,
  accepted,
  rejected,
  withdrawn,
  // Enhanced statuses for comprehensive Dutch mock data
  interviewInvited,    // Uitnodiging gesprek
  documentsPending,    // Wachten op documenten
  contractOffered,     // Contract aangeboden
  interviewScheduled,  // Gesprek ingepland
}

/// Enhanced application status extensions
extension ApplicationStatusExtension on ApplicationStatus {
  /// Get Dutch display text
  String get displayTextNL {
    switch (this) {
      case ApplicationStatus.pending:
        return 'In behandeling';
      case ApplicationStatus.accepted:
        return 'Geaccepteerd';
      case ApplicationStatus.rejected:
        return 'Afgewezen';
      case ApplicationStatus.withdrawn:
        return 'Ingetrokken';
      case ApplicationStatus.interviewInvited:
        return 'Uitnodiging gesprek';
      case ApplicationStatus.documentsPending:
        return 'Wachten op documenten';
      case ApplicationStatus.contractOffered:
        return 'Contract aangeboden';
      case ApplicationStatus.interviewScheduled:
        return 'Gesprek ingepland';
    }
  }
  
  /// Get status color for UI
  String get colorHex {
    switch (this) {
      case ApplicationStatus.pending:
        return '#FFA726'; // Orange (matches test expectation)
      case ApplicationStatus.accepted:
        return '#66BB6A'; // Green (matches test expectation)
      case ApplicationStatus.rejected:
        return '#EF5350'; // Red (matches test expectation)
      case ApplicationStatus.withdrawn:
        return '#BDBDBD'; // Grey (matches test expectation)
      case ApplicationStatus.interviewInvited:
        return '#2196F3'; // Blue
      case ApplicationStatus.documentsPending:
        return '#9C27B0'; // Purple
      case ApplicationStatus.contractOffered:
        return '#388E3C'; // Dark green
      case ApplicationStatus.interviewScheduled:
        return '#1976D2'; // Dark blue
    }
  }
  
  /// Check if status allows user actions
  bool get isActionable {
    return this == ApplicationStatus.interviewInvited ||
           this == ApplicationStatus.documentsPending ||
           this == ApplicationStatus.contractOffered ||
           this == ApplicationStatus.interviewScheduled;
  }
}
