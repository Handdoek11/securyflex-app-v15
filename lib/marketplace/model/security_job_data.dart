class SecurityJobData {
  SecurityJobData({
    this.jobId = '',
    this.jobTitle = '',
    this.companyName = '',
    this.location = '',
    this.hourlyRate = 25.0,
    this.distance = 1.8,
    this.latitude,
    this.longitude,
    this.companyRating = 4.5,
    this.applicantCount = 80,
    this.duration = 8,
    this.jobType = '',
    this.description = '',
    this.companyLogo = '',
    this.startDate,
    this.endDate,
    this.requiredCertificates = const [],
    // Legacy fields for UI compatibility
    this.imagePath = '',
    this.titleTxt = '',
    this.subTxt = '',
    this.dist = 1.8,
    this.reviews = 80,
    this.rating = 4.5,
    this.perHour = 25,
  }) {
    // Auto-populate legacy fields for UI compatibility
    imagePath = companyLogo.isEmpty ? 'assets/hotel/hotel_1.png' : companyLogo;
    titleTxt = jobTitle;
    subTxt = '$companyName, $location';
    dist = distance;
    reviews = applicantCount;
    rating = companyRating;
    perHour = hourlyRate.round();
  }

  /// Create SecurityJobData from Firestore document
  factory SecurityJobData.fromFirestore(Map<String, dynamic> data) {
    return SecurityJobData(
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      companyName: data['companyName'] ?? '',
      location: data['location'] ?? '',
      hourlyRate: (data['hourlyRate'] ?? 0.0).toDouble(),
      distance: (data['distance'] ?? 0.0).toDouble(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      companyRating: (data['companyRating'] ?? 0.0).toDouble(),
      applicantCount: data['applicantCount'] ?? 0,
      duration: data['duration'] ?? 0,
      jobType: data['jobType'] ?? '',
      description: data['description'] ?? '',
      companyLogo: data['companyLogo'] ?? 'assets/hotel/hotel_1.png',
      startDate: data['startDate']?.toDate() ?? DateTime.now(),
      endDate: data['endDate']?.toDate() ?? DateTime.now(),
      requiredCertificates: List<String>.from(data['requiredCertificates'] ?? []),
    );
  }

  /// Convert SecurityJobData to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'location': location,
      'hourlyRate': hourlyRate,
      'distance': distance,
      'latitude': latitude,
      'longitude': longitude,
      'companyRating': companyRating,
      'applicantCount': applicantCount,
      'viewCount': viewCount,
      'duration': duration,
      'jobType': jobType,
      'description': description,
      'companyLogo': companyLogo,
      'startDate': startDate,
      'endDate': endDate,
      'requiredCertificates': requiredCertificates,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
      'status': 'active', // active, paused, completed, cancelled
    };
  }

  // New comprehensive fields
  String jobId;
  String jobTitle;
  String companyName;
  String location;
  double hourlyRate;
  double distance;
  double? latitude;
  double? longitude;
  double companyRating;
  int applicantCount;
  int viewCount = 0;
  int duration; // hours
  String jobType;
  String description;
  String companyLogo;
  DateTime? startDate;
  DateTime? endDate;
  List<String> requiredCertificates;
  
  // Getter for id to match expected interface
  String get id => jobId;

  // Legacy fields for UI compatibility (auto-populated)
  String imagePath;
  String titleTxt;
  String subTxt;
  double dist;
  double rating;
  int reviews;
  int perHour;

  static List<SecurityJobData> jobList = <SecurityJobData>[
    SecurityJobData(
      jobId: 'SJ001',
      jobTitle: 'Objectbeveiliging Kantoorcomplex',
      companyName: 'Amsterdam Security Partners',
      location: 'Amsterdam Zuidas, 1082 MD',
      hourlyRate: 24.50,
      distance: 2.3,
      latitude: 52.3389,  // Amsterdam Zuidas coordinates
      longitude: 4.8728,
      companyRating: 4.6,
      applicantCount: 12,
      duration: 8,
      jobType: 'Objectbeveiliging',
      description: 'Beveiliging van modern kantoorcomplex met toegangscontrole en surveillance. Dagdienst van 08:00-16:00 uur. Ervaring met CCTV systemen gewenst.',
      companyLogo: 'assets/hotel/hotel_1.png',
      startDate: DateTime.now().add(Duration(days: 2)),
      endDate: DateTime.now().add(Duration(days: 2, hours: 8)),
      requiredCertificates: ['Beveiligingsdiploma A', 'BHV'],
    ),
    SecurityJobData(
      jobId: 'SJ002',
      jobTitle: 'Evenementbeveiliging Concerthal',
      companyName: 'Rotterdam Event Security',
      location: 'Rotterdam Centrum, 3011 AB',
      hourlyRate: 28.75,
      distance: 4.1,
      latitude: 51.9225,  // Rotterdam Centrum coordinates
      longitude: 4.4792,
      companyRating: 4.8,
      applicantCount: 25,
      duration: 6,
      jobType: 'Evenementbeveiliging',
      description: 'Crowd control en toegangscontrole tijdens live concert. Ervaring met grote evenementen vereist. Avonddienst 19:00-01:00 uur.',
      companyLogo: 'assets/hotel/hotel_2.png',
      startDate: DateTime.now().add(Duration(days: 5)),
      endDate: DateTime.now().add(Duration(days: 5, hours: 6)),
      requiredCertificates: ['Beveiligingsdiploma B', 'BHV', 'VCA'],
    ),
    SecurityJobData(
      jobId: 'SJ003',
      jobTitle: 'Winkelbeveiliging Warenhuis',
      companyName: 'Utrecht Retail Protection',
      location: 'Utrecht Centrum, 3511 LN',
      hourlyRate: 19.25,
      distance: 3.7,
      latitude: 52.0907,  // Utrecht Centrum coordinates
      longitude: 5.1214,
      companyRating: 4.2,
      applicantCount: 8,
      duration: 8,
      jobType: 'Winkelbeveiliging',
      description: 'Diefstalpreventie in groot warenhuis tijdens weekend. Observatie en discrete benadering van verdachte situaties. Zaterdag en zondag beschikbaar.',
      companyLogo: 'assets/hotel/hotel_3.png',
      startDate: DateTime.now().add(Duration(days: 3)),
      endDate: DateTime.now().add(Duration(days: 3, hours: 8)),
      requiredCertificates: ['Beveiligingsdiploma A'],
    ),
    SecurityJobData(
      jobId: 'SJ004',
      jobTitle: 'Persoonbeveiliging VIP',
      companyName: 'Den Haag Executive Protection',
      location: 'Den Haag Centrum, 2511 CV',
      hourlyRate: 35.00,
      distance: 6.2,
      latitude: 52.0705,  // Den Haag Centrum coordinates
      longitude: 4.3007,
      companyRating: 4.9,
      applicantCount: 3,
      duration: 10,
      jobType: 'Persoonbeveiliging',
      description: 'Discrete persoonbeveiliging voor zakelijke VIP tijdens conferentie. Hoge mate van professionaliteit en discretie vereist. Rijbewijs B noodzakelijk.',
      companyLogo: 'assets/hotel/hotel_4.png',
      startDate: DateTime.now().add(Duration(days: 8)),
      endDate: DateTime.now().add(Duration(days: 8, hours: 10)),
      requiredCertificates: ['Beveiligingsdiploma B', 'BHV', 'Rijbewijs B'],
    ),
    SecurityJobData(
      jobId: 'SJ005',
      jobTitle: 'Objectbeveiliging Ziekenhuis',
      companyName: 'Eindhoven Healthcare Security',
      location: 'Eindhoven Noord, 5623 EJ',
      hourlyRate: 22.50,
      distance: 1.8,
      latitude: 51.4416,  // Eindhoven Noord coordinates
      longitude: 5.4697,
      companyRating: 4.5,
      applicantCount: 15,
      duration: 12,
      jobType: 'Objectbeveiliging',
      description: 'Nachtdienst beveiliging ziekenhuis 20:00-08:00 uur. Patrouilleren, toegangscontrole en assistentie bij incidenten. Medische omgeving ervaring gewenst.',
      companyLogo: 'assets/hotel/hotel_5.png',
      startDate: DateTime.now().add(Duration(days: 1)),
      endDate: DateTime.now().add(Duration(days: 1, hours: 12)),
      requiredCertificates: ['Beveiligingsdiploma A', 'BHV'],
    ),
    SecurityJobData(
      jobId: 'SJ006',
      jobTitle: 'Portier Luxe Hotel',
      companyName: 'Tilburg Hospitality Security',
      location: 'Tilburg Centrum, 5038 EA',
      hourlyRate: 21.75,
      distance: 5.4,
      latitude: 51.5555,  // Tilburg Centrum coordinates
      longitude: 5.0913,
      companyRating: 4.4,
      applicantCount: 9,
      duration: 8,
      jobType: 'Objectbeveiliging',
      description: 'Portiersdiensten in luxe hotel met gastenservice en toegangscontrole. Representatieve uitstraling en klantvriendelijkheid essentieel. Avonddienst 16:00-00:00 uur.',
      companyLogo: 'assets/hotel/hotel_1.png',
      startDate: DateTime.now().add(Duration(days: 4)),
      endDate: DateTime.now().add(Duration(days: 4, hours: 8)),
      requiredCertificates: ['Portier', 'BHV'],
    ),
    SecurityJobData(
      jobId: 'SJ007',
      jobTitle: 'Evenementbeveiliging Festival',
      companyName: 'Groningen Festival Security',
      location: 'Groningen Stadspark, 9718 BG',
      hourlyRate: 26.50,
      distance: 8.1,
      companyRating: 4.7,
      applicantCount: 18,
      duration: 12,
      jobType: 'Evenementbeveiliging',
      description: 'Beveiliging tijdens 3-daags muziekfestival. Crowd management, toegangscontrole en incidentafhandeling. Fysiek zwaar werk, weersbestendig.',
      companyLogo: 'assets/hotel/hotel_2.png',
      startDate: DateTime.now().add(Duration(days: 10)),
      endDate: DateTime.now().add(Duration(days: 10, hours: 12)),
      requiredCertificates: ['Beveiligingsdiploma B', 'BHV', 'VCA'],
    ),
    SecurityJobData(
      jobId: 'SJ008',
      jobTitle: 'Winkelbeveiliging Supermarkt',
      companyName: 'Utrecht Retail Guard',
      location: 'Utrecht Overvecht, 3526 GA',
      hourlyRate: 17.50,
      distance: 4.9,
      companyRating: 3.9,
      applicantCount: 6,
      duration: 6,
      jobType: 'Winkelbeveiliging',
      description: 'Diefstalpreventie in drukke supermarkt tijdens avonduren. Observatie vanuit kleedkamer en discrete interventie bij verdachte situaties.',
      companyLogo: 'assets/hotel/hotel_3.png',
      startDate: DateTime.now().add(Duration(days: 6)),
      endDate: DateTime.now().add(Duration(days: 6, hours: 6)),
      requiredCertificates: ['Beveiligingsdiploma A'],
    ),
    SecurityJobData(
      jobId: 'SJ009',
      jobTitle: 'Objectbeveiliging Datacenter',
      companyName: 'Amsterdam Tech Security',
      location: 'Amsterdam Zuidoost, 1101 EA',
      hourlyRate: 27.25,
      distance: 7.3,
      companyRating: 4.6,
      applicantCount: 11,
      duration: 8,
      jobType: 'Objectbeveiliging',
      description: 'Beveiliging van kritieke IT-infrastructuur met strikte toegangsprotocollen. Technische achtergrond gewenst. Dagdienst maandag t/m vrijdag.',
      companyLogo: 'assets/hotel/hotel_4.png',
      startDate: DateTime.now().add(Duration(days: 7)),
      endDate: DateTime.now().add(Duration(days: 7, hours: 8)),
      requiredCertificates: ['Beveiligingsdiploma A', 'VCA'],
    ),
    SecurityJobData(
      jobId: 'SJ010',
      jobTitle: 'Persoonbeveiliging Politicus',
      companyName: 'Den Haag VIP Protection',
      location: 'Den Haag Binnenhof, 2513 AA',
      hourlyRate: 42.00,
      distance: 6.8,
      companyRating: 4.9,
      applicantCount: 2,
      duration: 10,
      jobType: 'Persoonbeveiliging',
      description: 'Hoogwaardige persoonbeveiliging voor politieke figuur tijdens publieke evenementen. Uitgebreide screening vereist. Flexibele werktijden.',
      companyLogo: 'assets/hotel/hotel_5.png',
      startDate: DateTime.now().add(Duration(days: 12)),
      endDate: DateTime.now().add(Duration(days: 12, hours: 10)),
      requiredCertificates: ['Beveiligingsdiploma B', 'BHV', 'VCA', 'Rijbewijs B'],
    ),
  ];
}
