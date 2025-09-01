import 'package:flutter/material.dart';
import '../../unified_status_colors.dart';

/// Enum voor verschillende types beveiligingsdiensten
enum ShiftType {
  office,      // Kantoor beveiliging
  retail,      // Winkel beveiliging
  event,       // Evenement beveiliging
  night,       // Nacht diensten
  patrol,      // Surveillance rondes
  emergency,   // Nood diensten
}

/// Enum voor dienst status
enum ShiftStatus {
  pending,     // Wachtend op acceptatie
  accepted,    // Geaccepteerd
  confirmed,   // Bevestigd door opdrachtgever
  inProgress,  // Bezig
  completed,   // Voltooid
  cancelled,   // Geannuleerd
}

/// Data model voor een beveiligingsdienst
class ShiftData {
  ShiftData({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.hourlyRate,
    required this.shiftType,
    required this.status,
    this.companyName = '',
    this.companyId = '',
    this.contactPerson = '',
    this.contactPhone = '',
    this.specialRequirements = const [],
    this.isUrgent = false,
    this.isPremium = false,
    this.imagePath = '',
    this.startColor = '#4A90E2',
    this.endColor = '#357ABD',
    this.jobId,
    this.applicationId,
    this.guardId = '',
    this.guardName = '',
    this.requirements = const [],
    this.certificatesRequired = const [],
    this.totalEarnings = 0.0,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final double hourlyRate;
  final ShiftType shiftType;
  final ShiftStatus status;
  final String companyName;
  final String companyId;
  final String contactPerson;
  final String contactPhone;
  final List<String> specialRequirements;
  final bool isUrgent;
  final bool isPremium;
  final String imagePath;
  final String startColor;
  final String endColor;
  final String? jobId;
  final String? applicationId;
  final String guardId;
  final String guardName;
  final List<String> requirements;
  final List<String> certificatesRequired;
  final double totalEarnings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  /// Berekent de totale duur van de dienst in uren
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  /// Berekent het totale bedrag voor deze dienst
  double get totalAmount {
    return durationInHours * hourlyRate;
  }

  /// Geeft een leesbare string voor het dienst type
  String get shiftTypeDisplayName {
    switch (shiftType) {
      case ShiftType.office:
        return 'Kantoor Beveiliging';
      case ShiftType.retail:
        return 'Winkel Beveiliging';
      case ShiftType.event:
        return 'Evenement Beveiliging';
      case ShiftType.night:
        return 'Nacht Dienst';
      case ShiftType.patrol:
        return 'Surveillance';
      case ShiftType.emergency:
        return 'Nood Dienst';
    }
  }

  /// Geeft een leesbare string voor de dienst status
  String get statusDisplayName {
    switch (status) {
      case ShiftStatus.pending:
        return 'Wachtend';
      case ShiftStatus.accepted:
        return 'Geaccepteerd';
      case ShiftStatus.confirmed:
        return 'Bevestigd';
      case ShiftStatus.inProgress:
        return 'Bezig';
      case ShiftStatus.completed:
        return 'Voltooid';
      case ShiftStatus.cancelled:
        return 'Geannuleerd';
    }
  }

  /// Geeft de juiste kleur voor de status (unified system)
  Color get statusColor {
    return StatusColorHelper.getShiftStatusColor(status);
  }

  /// Geeft het juiste icoon voor het dienst type
  IconData get shiftTypeIcon {
    switch (shiftType) {
      case ShiftType.office:
        return Icons.business;
      case ShiftType.retail:
        return Icons.store;
      case ShiftType.event:
        return Icons.event;
      case ShiftType.night:
        return Icons.nights_stay;
      case ShiftType.patrol:
        return Icons.directions_walk;
      case ShiftType.emergency:
        return Icons.emergency;
    }
  }

  /// Kopieert het object met nieuwe waarden
  ShiftData copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? address,
    DateTime? startTime,
    DateTime? endTime,
    double? hourlyRate,
    ShiftType? shiftType,
    ShiftStatus? status,
    String? companyName,
    String? contactPerson,
    String? contactPhone,
    List<String>? specialRequirements,
    bool? isUrgent,
    String? imagePath,
    String? startColor,
    String? endColor,
  }) {
    return ShiftData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      address: address ?? this.address,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      shiftType: shiftType ?? this.shiftType,
      status: status ?? this.status,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      isUrgent: isUrgent ?? this.isUrgent,
      imagePath: imagePath ?? this.imagePath,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
    );
  }

  /// Voorbeeld data voor testing
  static List<ShiftData> getSampleShifts() {
    final now = DateTime.now();
    return [
      ShiftData(
        id: '1',
        title: 'Kantoor Beveiliging',
        description: 'Dagdienst kantoorcomplex centrum',
        location: 'Amsterdam Centrum',
        address: 'Damrak 123, 1012 LP Amsterdam',
        startTime: DateTime(now.year, now.month, now.day + 1, 8, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 17, 0),
        hourlyRate: 18.50,
        shiftType: ShiftType.office,
        status: ShiftStatus.confirmed,
        companyName: 'SecureCorp BV',
        contactPerson: 'Jan de Vries',
        contactPhone: '+31 6 12345678',
        specialRequirements: ['VCA certificaat', 'Eigen vervoer'],
        startColor: '#4A90E2',
        endColor: '#357ABD',
      ),
      ShiftData(
        id: '2',
        title: 'Winkel Beveiliging',
        description: 'Weekend dienst winkelcentrum',
        location: 'Rotterdam Zuid',
        address: 'Zuidplein 40, 3083 AA Rotterdam',
        startTime: DateTime(now.year, now.month, now.day + 2, 10, 0),
        endTime: DateTime(now.year, now.month, now.day + 2, 18, 0),
        hourlyRate: 16.75,
        shiftType: ShiftType.retail,
        status: ShiftStatus.pending,
        companyName: 'Retail Security NL',
        contactPerson: 'Maria Jansen',
        contactPhone: '+31 6 87654321',
        specialRequirements: ['Winkel ervaring'],
        isUrgent: true,
        startColor: '#E74C3C',
        endColor: '#C0392B',
      ),
      ShiftData(
        id: '3',
        title: 'Nacht Bewaking',
        description: 'Nachtdienst industrieterrein',
        location: 'Utrecht Noord',
        address: 'Industrieweg 45, 3542 AD Utrecht',
        startTime: DateTime(now.year, now.month, now.day, 22, 0),
        endTime: DateTime(now.year, now.month, now.day + 1, 6, 0),
        hourlyRate: 21.00,
        shiftType: ShiftType.night,
        status: ShiftStatus.inProgress,
        companyName: 'NightGuard Services',
        contactPerson: 'Piet Bakker',
        contactPhone: '+31 6 11223344',
        specialRequirements: ['Nacht ervaring', 'Auto rijbewijs'],
        startColor: '#2C3E50',
        endColor: '#34495E',
      ),
    ];
  }
}