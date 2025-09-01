import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../model/security_job_data.dart';

/// MockJobDataService with realistic Dutch security sector jobs
/// 
/// Provides 20 comprehensive security jobs representing the authentic Nederlandse
/// beveiligingssector market with proper geographic distribution, seasonal variations,
/// certificate requirements, and salary ranges across different regions and companies.
class MockJobDataService {
  static bool _useMockData = kDebugMode; // Enable mock data in debug mode by default
  static final List<SecurityJobData> _cachedMockJobs = [];
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(hours: 1);

  /// Toggle between mock and real data
  static void setUseMockData(bool useMock) {
    _useMockData = useMock;
    _cachedMockJobs.clear(); // Clear cache when switching
    debugPrint('MockJobDataService: ${useMock ? 'Enabled' : 'Disabled'} mock data');
  }

  /// Check if mock data is enabled
  static bool get isUsingMockData => _useMockData;

  /// Get all available mock jobs with caching
  static Future<List<SecurityJobData>> getAllMockJobs() async {
    if (!_useMockData) {
      return [];
    }

    // Return cached data if still valid
    if (_cachedMockJobs.isNotEmpty && _isCacheValid()) {
      return List.from(_cachedMockJobs);
    }

    // Generate fresh mock data
    await _generateMockJobs();
    return List.from(_cachedMockJobs);
  }

  /// Check if cache is still valid
  static bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheValidityDuration;
  }

  /// Generate comprehensive mock job data
  static Future<void> _generateMockJobs() async {
    _cachedMockJobs.clear();
    
    final mockJobs = <SecurityJobData>[
      // ======================================================================
      // OBJECTBEVEILIGING (4 jobs) - Office buildings, shopping centers
      // ======================================================================
      SecurityJobData(
        jobId: 'G4S-OBJ-001',
        jobTitle: 'Objectbeveiliger Winkelcentrum Zuidplein',
        companyName: 'G4S Nederland',
        location: 'Rotterdam Zuid, 3083AA',
        hourlyRate: 22.50,
        distance: 2.3,
        companyRating: 4.6,
        applicantCount: 18,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Voor ons grote winkelcentrum in Rotterdam Zuid zoeken wij een ervaren objectbeveiliger voor dagdiensten. Werkzaamheden omvatten toegangscontrole, CCTV monitoring, patrouilleren en assistentie bij incidenten. Ervaring met crowd management tijdens drukke perioden gewenst. Goede communicatieve vaardigheden in Nederlands en Engels vereist.',
        companyLogo: 'assets/jobs/objectbeveiliging-photo.webp',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 2, hours: 8)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),

      SecurityJobData(
        jobId: 'TRI-OBJ-002',
        jobTitle: 'Kantoorcomplex Beveiliging Zuidas',
        companyName: 'Trigion Beveiliging',
        location: 'Amsterdam Zuidas, 1082MD',
        hourlyRate: 26.00,
        distance: 4.1,
        companyRating: 4.4,
        applicantCount: 12,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Objectbeveiliging voor premium kantoorcomplex in Amsterdam Zuidas. Verantwoordelijk voor receptie, toegangscontrole, bezoekersregistratie en algemene veiligheid. Representatieve uitstraling en professionele houding essentieel. Werkzaamheden tijdens kantooruren met mogelijke flexibiliteit.',
        companyLogo: 'assets/jobs/VINRO-Beveiliging-Objectbeveiliging-Header.webp',
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 5, hours: 8)),
        requiredCertificates: ['WPBR', 'VCA'],
      ),

      SecurityJobData(
        jobId: 'FAC-OBJ-003',
        jobTitle: 'Ziekenhuis Nachtbeveiliging',
        companyName: 'Facilicom Security',
        location: 'Utrecht Centrum, 3584CX',
        hourlyRate: 24.75,
        distance: 6.2,
        companyRating: 4.3,
        applicantCount: 8,
        duration: 12,
        jobType: 'Objectbeveiliging',
        description: 'Nachtbeveiliging in academisch ziekenhuis van 20:00 tot 08:00 uur. Patrouilleren, toegangscontrole, assistentie bij noodsituaties en samenwerking met medisch personeel. Ervaring in medische omgeving gewenst. Goede stressbestendigheid en empathisch vermogen vereist voor contact met patiënten en bezoekers.',
        companyLogo: 'assets/jobs/BLU03341-768x547.jpg',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1, hours: 12)),
        requiredCertificates: ['WPBR', 'BHV', 'EHBO'],
      ),

      SecurityJobData(
        jobId: 'SEC-OBJ-004',
        jobTitle: 'Datacenter Beveiliging Schiphol',
        companyName: 'SecurePro Brabant',
        location: 'Schiphol, 1118CP',
        hourlyRate: 28.50,
        distance: 8.7,
        companyRating: 4.7,
        applicantCount: 6,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Beveiliging van kritiek datacenter nabij Schiphol. Strikte toegangsprotocollen, biometrische systemen en 24/7 monitoring. Technische achtergrond gewenst, ervaring met IT-infrastructuur een pré. Hoge mate van betrouwbaarheid en discretie vereist. Mogelijkheid tot vaste aanstelling bij goed functioneren.',
        companyLogo: 'assets/jobs/Security---780x440---Beveiligers-Controleronde.jpg',
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 3, hours: 8)),
        requiredCertificates: ['WPBR', 'VCA'],
      ),

      // ======================================================================
      // EVENEMENTBEVEILIGING (3 jobs) - Festivals, concerts, sports events
      // ======================================================================
      SecurityJobData(
        jobId: 'G4S-EVE-005',
        jobTitle: 'Festival Beveiliging Lowlands',
        companyName: 'G4S Nederland',
        location: 'Biddinghuizen, 8256RJ',
        hourlyRate: 29.00,
        distance: 12.4,
        companyRating: 4.6,
        applicantCount: 45,
        duration: 12,
        jobType: 'Evenementbeveiliging',
        description: 'Evenementbeveiliging tijdens 3-daags muziekfestival Lowlands. Crowd control, toegangscontrole, podiumbeveiliging en incident management. Fysiek zwaar werk, weersbestendig. Ervaring met grote evenementen vereist. Weekend premie van 25% inbegrepen. Accommodatie en catering verzorgd.',
        companyLogo: 'assets/jobs/qv5a7050.jpg',
        startDate: DateTime.now().add(const Duration(days: 14)),
        endDate: DateTime.now().add(const Duration(days: 14, hours: 12)),
        requiredCertificates: ['WPBR', 'BHV', 'VCA'],
      ),

      SecurityJobData(
        jobId: 'EVE-SEC-006',
        jobTitle: 'Concerthal Ziggo Dome Security',
        companyName: 'Rotterdam Event Security',
        location: 'Amsterdam Zuidoost, 1101EB',
        hourlyRate: 27.50,
        distance: 7.8,
        companyRating: 4.8,
        applicantCount: 22,
        duration: 6,
        jobType: 'Evenementbeveiliging',
        description: 'Crowd control en VIP beveiliging tijdens internationale concerten in Ziggo Dome. Professionele uitstraling, stressbestendigheid en goede communicatieve vaardigheden vereist. Avond- en weekendwerk. Mogelijkheid tot structurele samenwerking bij bewezen kwaliteit.',
        companyLogo: 'assets/jobs/Object-beveiliging-2.webp',
        startDate: DateTime.now().add(const Duration(days: 8)),
        endDate: DateTime.now().add(const Duration(days: 8, hours: 6)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),

      SecurityJobData(
        jobId: 'SPO-EVE-007',
        jobTitle: 'Voetbalstadion De Kuip Beveiliging',
        companyName: 'Trigion Beveiliging',
        location: 'Rotterdam Zuid, 3077AL',
        hourlyRate: 31.00,
        distance: 5.3,
        companyRating: 4.4,
        applicantCount: 28,
        duration: 8,
        jobType: 'Evenementbeveiliging',
        description: 'Stadionbeveiliging tijdens Feyenoord thuiswedstrijden in De Kuip. Crowd management, toegangscontrole, incidentafhandeling en samenwerking met politie. Ervaring met voetbalpubliek gewenst. Goede fysieke conditie en mentale weerbaarheid vereist. Hoge adrenaline omgeving.',
        companyLogo: 'assets/jobs/Portiers-beveiliging-bewaking-fw.jpg',
        startDate: DateTime.now().add(const Duration(days: 6)),
        endDate: DateTime.now().add(const Duration(days: 6, hours: 8)),
        requiredCertificates: ['WPBR', 'BHV', 'VCA'],
      ),

      // ======================================================================
      // RETAILBEVEILIGING (2 jobs) - Supermarkets, fashion stores
      // ======================================================================
      SecurityJobData(
        jobId: 'RET-SUP-008',
        jobTitle: 'Supermarkt Diefstalpreventie',
        companyName: 'VeiligPro Utrecht',
        location: 'Utrecht Overvecht, 3526GA',
        hourlyRate: 18.50,
        distance: 3.2,
        companyRating: 4.0,
        applicantCount: 15,
        duration: 8,
        jobType: 'Winkelbeveiliging',
        description: 'Diefstalpreventie in drukke supermarkt tijdens piek uren. Observatie, discrete benadering van verdachte situaties en samenwerking met management. Ervaring met retailomgeving gewenst. Goede observatievaardigheden en klantgerichte houding vereist.',
        companyLogo: 'assets/jobs/Object-beveiliging-2.webp',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 2, hours: 8)),
        requiredCertificates: ['WPBR'],
      ),

      SecurityJobData(
        jobId: 'RET-FAS-009',
        jobTitle: 'Luxe Warenhuis Kalverstraat',
        companyName: 'Amsterdam Security Noord',
        location: 'Amsterdam Centrum, 1012PH',
        hourlyRate: 21.75,
        distance: 4.6,
        companyRating: 4.2,
        applicantCount: 11,
        duration: 8,
        jobType: 'Winkelbeveiliging',
        description: 'Beveiliging in exclusief warenhuis op Kalverstraat. Klantservice gecombineerd met security taken. Representatieve uitstraling, taalvaardigheden (Nederlands/Engels) en ervaring met luxury retail gewenst. Discrete aanpak van diefstal en klantenservice.',
        companyLogo: 'assets/jobs/BLU03341-768x547.jpg',
        startDate: DateTime.now().add(const Duration(days: 4)),
        endDate: DateTime.now().add(const Duration(days: 4, hours: 8)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),

      // ======================================================================
      // INDUSTRIËLE BEVEILIGING (2 jobs) - Ports, factories
      // ======================================================================
      SecurityJobData(
        jobId: 'HAV-IND-010',
        jobTitle: 'Havenbeveiliging Europoort',
        companyName: 'Havenbeveiliging Nederland',
        location: 'Rotterdam Europoort, 3198LG',
        hourlyRate: 32.00,
        distance: 15.2,
        companyRating: 4.5,
        applicantCount: 7,
        duration: 12,
        jobType: 'Industriële beveiliging',
        description: 'Beveiliging van havengebied Europoort tijdens nachtdienst. Toegangscontrole voor vrachtwagens, controle van documenten, CCTV monitoring en patrouilleren van groot industrieterrein. ISPS code kennis gewenst. Rijbewijs B vereist voor patrouillevoertuig.',
        companyLogo: 'assets/jobs/TaxiVasse13-768x511.jpg',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 1, hours: 12)),
        requiredCertificates: ['WPBR', 'VCA', 'Rijbewijs B'],
      ),

      SecurityJobData(
        jobId: 'CHE-IND-011',
        jobTitle: 'Chemische Fabriek DSM',
        companyName: 'Facilicom Security',
        location: 'Geleen, 6164BM',
        hourlyRate: 30.25,
        distance: 18.9,
        companyRating: 4.3,
        applicantCount: 5,
        duration: 8,
        jobType: 'Industriële beveiliging',
        description: 'Beveiliging van chemische productielocatie met strenge veiligheidsprotocollen. Kennis van gevaarlijke stoffen procedures, persoonlijke beschermingsmiddelen en noodprocedures. VCA-VOL certificaat vereist. Training wordt verzorgd door bedrijf.',
        companyLogo: 'assets/jobs/VINRO-Beveiliging-Objectbeveiliging-Header.webp',
        startDate: DateTime.now().add(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 7, hours: 8)),
        requiredCertificates: ['WPBR', 'VCA', 'BHV'],
      ),

      // ======================================================================
      // TRANSPORTBEVEILIGING (2 jobs) - Schiphol, public transport
      // ======================================================================
      SecurityJobData(
        jobId: 'SCH-TRA-012',
        jobTitle: 'Luchthaven Schiphol Security',
        companyName: 'G4S Nederland',
        location: 'Schiphol, 1118AA',
        hourlyRate: 25.50,
        distance: 11.3,
        companyRating: 4.6,
        applicantCount: 34,
        duration: 8,
        jobType: 'Transportbeveiliging',
        description: 'Passagiers- en bagagecontrole op Schiphol luchthaven. Werken met security screening equipment, handhaving van luchtvaartregulering en internationale security protocollen. Screening en achtergrondonderzoek verplicht. Meertaligheid (Nederlands/Engels) vereist.',
        companyLogo: 'assets/jobs/Security---780x440---Beveiligers-Controleronde.jpg',
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 10, hours: 8)),
        requiredCertificates: ['WPBR', 'Luchtvaart Security'],
      ),

      SecurityJobData(
        jobId: 'NS-TRA-013',
        jobTitle: 'Station Beveiliging Amsterdam CS',
        companyName: 'NS Security',
        location: 'Amsterdam Centrum, 1012AB',
        hourlyRate: 23.25,
        distance: 6.8,
        companyRating: 4.1,
        applicantCount: 19,
        duration: 8,
        jobType: 'Transportbeveiliging',
        description: 'Beveiliging van Amsterdam Centraal Station tijdens spitsuren. Crowd control, assistentie aan reizigers, incidentafhandeling en samenwerking met GVB en Politie. Dynamische werkomgeving met hoge doorstroming van mensen. Klantvriendelijke benadering essentieel.',
        companyLogo: 'assets/jobs/objectbeveiliging-photo.webp',
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 3, hours: 8)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),

      // ======================================================================
      // VIP/PERSOONSBESCHERMING (1 job) - Executive protection
      // ======================================================================
      SecurityJobData(
        jobId: 'VIP-PER-014',
        jobTitle: 'Executive Protection Den Haag',
        companyName: 'Den Haag Executive Protection',
        location: 'Den Haag Centrum, 2511CV',
        hourlyRate: 42.00,
        distance: 9.4,
        companyRating: 4.9,
        applicantCount: 3,
        duration: 10,
        jobType: 'Persoonbeveiliging',
        description: 'Discrete persoonbeveiliging voor C-level executive tijdens zakelijke activiteiten en evenementen. Hoge mate van professionaliteit, discretie en flexibiliteit vereist. Rijbewijs B, defensieve rijtraining en ervaring met VIP bescherming noodzakelijk. Uitgebreide screening verplicht.',
        companyLogo: 'assets/jobs/Persoonsbeveiliging.jpg',
        startDate: DateTime.now().add(const Duration(days: 12)),
        endDate: DateTime.now().add(const Duration(days: 12, hours: 10)),
        requiredCertificates: ['WPBR', 'BHV', 'VCA', 'Rijbewijs B'],
      ),

      // ======================================================================
      // NACHTBEVEILIGING (3 jobs) - Hospitals, hotels, 24/7 locations
      // ======================================================================
      SecurityJobData(
        jobId: 'NACHT-HOT-015',
        jobTitle: 'Hotel Nachtportier Hilton',
        companyName: 'Tilburg Hospitality Security',
        location: 'Amsterdam Zuid, 1077XV',
        hourlyRate: 24.00,
        distance: 5.7,
        companyRating: 4.4,
        applicantCount: 9,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Nachtportier in 5-sterren hotel van 23:00 tot 07:00 uur. Gastenservice gecombineerd met security taken, incident management en noodhulp procedures. Representatieve uitstraling, meertaligheid (Nederlands/Engels/Duits) en hospitality ervaring gewenst.',
        companyLogo: 'assets/jobs/Foto-persoonsbeveiliging.png',
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 5, hours: 8)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),

      SecurityJobData(
        jobId: 'NACHT-LAB-016',
        jobTitle: 'Laboratorium Nacht Security',
        companyName: 'SecurePro Brabant',
        location: 'Eindhoven Noord, 5623EJ',
        hourlyRate: 26.75,
        distance: 8.2,
        companyRating: 4.7,
        applicantCount: 6,
        duration: 12,
        jobType: 'Objectbeveiliging',
        description: 'Nachtbeveiliging van research laboratorium met gevoelige apparatuur en materialen. Monitoring van klimaatsystemen, toegangscontrole voor onderzoekspersoneel en noodprocedures. Technische achtergrond gewenst, training wordt verzorgd.',
        companyLogo: 'assets/jobs/qv5a7050.jpg',
        startDate: DateTime.now().add(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 2, hours: 12)),
        requiredCertificates: ['WPBR', 'VCA'],
      ),

      SecurityJobData(
        jobId: 'NACHT-UNI-017',
        jobTitle: 'Universiteit Campus Beveiliging',
        companyName: 'Groningen Campus Security',
        location: 'Groningen, 9712CP',
        hourlyRate: 22.00,
        distance: 14.6,
        companyRating: 4.2,
        applicantCount: 12,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Nachtbeveiliging van universiteitscampus met meerdere gebouwen. Patrouilleren, toegangscontrole voor studenten en personeel, incident rapportage en samenwerking met campusmanagement. Studentvriendelijke benadering gewenst.',
        companyLogo: 'assets/jobs/objectbeveiliging-photo.webp',
        startDate: DateTime.now().add(const Duration(days: 4)),
        endDate: DateTime.now().add(const Duration(days: 4, hours: 8)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),

      // ======================================================================
      // WEEKEND/PART-TIME (2 jobs) - Flexible opportunities
      // ======================================================================
      SecurityJobData(
        jobId: 'WEEK-MUS-018',
        jobTitle: 'Museum Weekend Security',
        companyName: 'Amsterdam Security Noord',
        location: 'Amsterdam Museum, 1071DJ',
        hourlyRate: 20.50,
        distance: 4.1,
        companyRating: 4.2,
        applicantCount: 16,
        duration: 8,
        jobType: 'Objectbeveiliging',
        description: 'Weekendbeveiliging in prestigieus museum. Kunstbescherming, bezoekersbegeleiding en noodevacuatie procedures. Interesse in kunst en cultuur gewenst. Rustige werkomgeving met educatief aspect. Mogelijkheid tot uitbreiding naar weekdagen.',
        companyLogo: 'assets/jobs/BLU03341-768x547.jpg',
        startDate: DateTime.now().add(const Duration(days: 6)),
        endDate: DateTime.now().add(const Duration(days: 6, hours: 8)),
        requiredCertificates: ['WPBR'],
      ),

      SecurityJobData(
        jobId: 'WEEK-CON-019',
        jobTitle: 'Bouwplaats Weekend Bewaking',
        companyName: 'VeiligPro Utrecht',
        location: 'Utrecht Nieuwegein, 3435CM',
        hourlyRate: 25.00,
        distance: 7.3,
        companyRating: 4.0,
        applicantCount: 8,
        duration: 12,
        jobType: 'Objectbeveiliging',
        description: 'Weekendbeveiliging op grote bouwplaats met dure machines en materialen. Toegangscontrole, patrouilleren en materiaal controle. VCA certificaat verplicht vanwege bouwomgeving. Kennis van bouwveiligheid gewenst. Weekend premie van 40% bovenop uurloon.',
        companyLogo: 'assets/jobs/Portiers-beveiliging-bewaking-fw.jpg',
        startDate: DateTime.now().add(const Duration(days: 9)),
        endDate: DateTime.now().add(const Duration(days: 9, hours: 12)),
        requiredCertificates: ['WPBR', 'VCA'],
      ),

      // ======================================================================
      // SEIZOENSWERK (1 job) - Holiday/seasonal work
      // ======================================================================
      SecurityJobData(
        jobId: 'SEI-KER-020',
        jobTitle: 'Kerst Shopping Security',
        companyName: 'Rotterdam Event Security',
        location: 'Rotterdam Centrum, 3011GV',
        hourlyRate: 23.50,
        distance: 3.8,
        companyRating: 4.8,
        applicantCount: 24,
        duration: 10,
        jobType: 'Evenementbeveiliging',
        description: 'Extra beveiliging tijdens kerst shopping periode in druk winkelcentrum. Crowd control tijdens sale perioden, assistentie bij lange wachtrijen en incident management. Flexibele werktijden, avond en weekend beschikbaarheid gewenst. Tijdelijk contract met mogelijke verlenging.',
        companyLogo: 'assets/jobs/TaxiVasse13-768x511.jpg',
        startDate: DateTime.now().add(const Duration(days: 21)),
        endDate: DateTime.now().add(const Duration(days: 21, hours: 10)),
        requiredCertificates: ['WPBR', 'BHV'],
      ),
    ];

    _cachedMockJobs.addAll(mockJobs);
    _lastCacheUpdate = DateTime.now();
    
    debugPrint('MockJobDataService: Generated ${mockJobs.length} mock jobs');
  }

  /// Get jobs filtered by certificate requirements
  static Future<List<SecurityJobData>> getJobsByCertificateRequirements(
    List<String> userCertificates,
  ) async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) {
      // Check if user has all required certificates
      return job.requiredCertificates.every((required) =>
          userCertificates.any((userCert) => 
              userCert.toLowerCase().contains(required.toLowerCase()) ||
              required.toLowerCase().contains(userCert.toLowerCase())
          )
      );
    }).toList();
  }

  /// Get jobs by location/postcode proximity
  static Future<List<SecurityJobData>> getJobsByLocation(
    String userPostcode, {
    double maxDistanceKm = 25.0,
  }) async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    // For mock data, use the distance field as-is
    return allJobs.where((job) => job.distance <= maxDistanceKm).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
  }

  /// Get jobs by salary range
  static Future<List<SecurityJobData>> getJobsBySalaryRange(
    double minSalary,
    double maxSalary,
  ) async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) =>
        job.hourlyRate >= minSalary && job.hourlyRate <= maxSalary
    ).toList()
      ..sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate)); // Highest salary first
  }

  /// Get jobs by type/category
  static Future<List<SecurityJobData>> getJobsByType(String jobType) async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) =>
        job.jobType.toLowerCase().contains(jobType.toLowerCase())
    ).toList();
  }

  /// Get urgent jobs (starting within next 3 days)
  static Future<List<SecurityJobData>> getUrgentJobs() async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    final urgentThreshold = DateTime.now().add(const Duration(days: 3));
    
    return allJobs.where((job) =>
        job.startDate?.isBefore(urgentThreshold) ?? false
    ).toList()
      ..sort((a, b) => (a.startDate ?? DateTime.now())
          .compareTo(b.startDate ?? DateTime.now()));
  }

  /// Get high-paying jobs (above average market rate)
  static Future<List<SecurityJobData>> getHighPayingJobs({
    double threshold = 28.0,
  }) async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) => job.hourlyRate >= threshold).toList()
      ..sort((a, b) => b.hourlyRate.compareTo(a.hourlyRate));
  }

  /// Get jobs by company
  static Future<List<SecurityJobData>> getJobsByCompany(String companyName) async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) =>
        job.companyName.toLowerCase().contains(companyName.toLowerCase())
    ).toList();
  }

  /// Get weekend jobs
  static Future<List<SecurityJobData>> getWeekendJobs() async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    // For mock data, identify weekend jobs by certain keywords or job IDs
    return allJobs.where((job) =>
        job.jobTitle.toLowerCase().contains('weekend') ||
        job.description.toLowerCase().contains('weekend') ||
        job.jobId.contains('WEEK')
    ).toList();
  }

  /// Get part-time jobs (less than 8 hours)
  static Future<List<SecurityJobData>> getPartTimeJobs() async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) => job.duration < 8).toList();
  }

  /// Get night shift jobs
  static Future<List<SecurityJobData>> getNightJobs() async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    return allJobs.where((job) =>
        job.jobTitle.toLowerCase().contains('nacht') ||
        job.description.toLowerCase().contains('nacht') ||
        job.jobId.contains('NACHT') ||
        job.duration >= 10 // Assume longer shifts are night shifts
    ).toList();
  }

  /// Get jobs suitable for entry-level guards
  static Future<List<SecurityJobData>> getEntryLevelJobs() async {
    if (!_useMockData) return [];

    final allJobs = await getAllMockJobs();
    
    // Entry-level jobs typically only require WPBR certificate
    return allJobs.where((job) =>
        job.requiredCertificates.length == 1 &&
        job.requiredCertificates.first.toLowerCase().contains('wpbr') &&
        job.hourlyRate <= 22.0 // Lower pay typically indicates entry level
    ).toList();
  }

  /// Get recommendation stats for analytics
  static Map<String, dynamic> getMockDataStats() {
    if (!_useMockData || _cachedMockJobs.isEmpty) {
      return {
        'totalJobs': 0,
        'averageSalary': 0.0,
        'jobTypeDistribution': <String, int>{},
        'certificateRequirements': <String, int>{},
      };
    }

    final jobTypes = <String, int>{};
    final certificates = <String, int>{};
    double totalSalary = 0;

    for (final job in _cachedMockJobs) {
      // Job type distribution
      jobTypes[job.jobType] = (jobTypes[job.jobType] ?? 0) + 1;
      
      // Certificate requirements
      for (final cert in job.requiredCertificates) {
        certificates[cert] = (certificates[cert] ?? 0) + 1;
      }
      
      totalSalary += job.hourlyRate;
    }

    return {
      'totalJobs': _cachedMockJobs.length,
      'averageSalary': totalSalary / _cachedMockJobs.length,
      'salaryRange': {
        'min': _cachedMockJobs.map((j) => j.hourlyRate).reduce(min),
        'max': _cachedMockJobs.map((j) => j.hourlyRate).reduce(max),
      },
      'jobTypeDistribution': jobTypes,
      'certificateRequirements': certificates,
      'topCompanies': _cachedMockJobs
          .map((j) => j.companyName)
          .toSet()
          .toList(),
      'locationCoverage': _cachedMockJobs
          .map((j) => j.location.split(',').first.trim())
          .toSet()
          .length,
      'cacheStatus': {
        'isValid': _isCacheValid(),
        'lastUpdate': _lastCacheUpdate?.toIso8601String(),
        'cacheSize': _cachedMockJobs.length,
      }
    };
  }

  /// Clear mock data cache (useful for testing)
  static void clearCache() {
    _cachedMockJobs.clear();
    _lastCacheUpdate = null;
    debugPrint('MockJobDataService: Cache cleared');
  }

  /// Force refresh of mock data
  static Future<void> refreshMockData() async {
    clearCache();
    await _generateMockJobs();
    debugPrint('MockJobDataService: Mock data refreshed');
  }

  /// Get job by ID (for testing specific jobs)
  static Future<SecurityJobData?> getJobById(String jobId) async {
    if (!_useMockData) return null;

    final allJobs = await getAllMockJobs();
    
    try {
      return allJobs.firstWhere((job) => job.jobId == jobId);
    } catch (e) {
      return null;
    }
  }

  /// Simulate dynamic job data changes (for testing)
  static Future<void> simulateJobChanges() async {
    if (!_useMockData || _cachedMockJobs.isEmpty) return;

    final random = Random();
    
    // Randomly update some job data to simulate real-world changes
    for (int i = 0; i < min(5, _cachedMockJobs.length); i++) {
      final jobIndex = random.nextInt(_cachedMockJobs.length);
      final job = _cachedMockJobs[jobIndex];
      
      // Simulate applicant count changes
      final newApplicantCount = max(0, 
          job.applicantCount + random.nextInt(10) - 5);
      
      // Create updated job with new applicant count
      _cachedMockJobs[jobIndex] = SecurityJobData(
        jobId: job.jobId,
        jobTitle: job.jobTitle,
        companyName: job.companyName,
        location: job.location,
        hourlyRate: job.hourlyRate,
        distance: job.distance,
        companyRating: job.companyRating,
        applicantCount: newApplicantCount,
        duration: job.duration,
        jobType: job.jobType,
        description: job.description,
        companyLogo: job.companyLogo,
        startDate: job.startDate,
        endDate: job.endDate,
        requiredCertificates: job.requiredCertificates,
      );
    }
    
    debugPrint('MockJobDataService: Simulated job data changes');
  }
}

/// Extension methods for MockJobDataService integration
extension SecurityJobDataMockExtension on SecurityJobData {
  /// Check if this is a mock job
  bool get isMockJob => MockJobDataService.isUsingMockData && 
      jobId.contains('-');

  /// Get mock job category
  String get mockCategory {
    if (jobId.contains('OBJ')) return 'Objectbeveiliging';
    if (jobId.contains('EVE')) return 'Evenementbeveiliging';
    if (jobId.contains('RET')) return 'Winkelbeveiliging';
    if (jobId.contains('IND')) return 'Industriële beveiliging';
    if (jobId.contains('TRA')) return 'Transportbeveiliging';
    if (jobId.contains('PER')) return 'Persoonbeveiliging';
    if (jobId.contains('NACHT')) return 'Nachtbeveiliging';
    if (jobId.contains('WEEK')) return 'Weekendwerk';
    if (jobId.contains('SEI')) return 'Seizoenswerk';
    return 'Overig';
  }

  /// Get expected salary tier based on mock data
  String get salaryTier {
    if (hourlyRate <= 20.0) return 'Entry Level (€15-€20)';
    if (hourlyRate <= 25.0) return 'Standard (€20-€25)';
    if (hourlyRate <= 30.0) return 'Experienced (€25-€30)';
    if (hourlyRate <= 35.0) return 'Senior (€30-€35)';
    return 'Premium (€35+)';
  }

  /// Check if job is suitable for new guards
  bool get isEntryLevelFriendly => 
      requiredCertificates.length <= 2 &&
      requiredCertificates.any((cert) => cert.toLowerCase().contains('wpbr')) &&
      hourlyRate <= 22.0;
}