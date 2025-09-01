import 'package:equatable/equatable.dart';

/// Emergency incident types for security work
enum EmergencyIncidentType {
  theft,              // Diefstal
  vandalism,          // Vandalisme
  trespassing,        // Inbraak/ongeoorloofd betreden
  assault,            // Geweld/bedreiging
  fire,               // Brand
  medicalEmergency,   // Medische noodsituatie
  suspiciousActivity, // Verdachte activiteit
  equipmentFailure,   // Apparatuurstoring
  other,              // Overig
}

/// Emergency incident model for dashboard emergency reporting
class EmergencyIncident extends Equatable {
  final String id;
  final String type;
  final String description;
  final DateTime timestamp;
  final String? location;
  final String? shiftId;

  const EmergencyIncident({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.location,
    this.shiftId,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    description,
    timestamp,
    location,
    shiftId,
  ];
}