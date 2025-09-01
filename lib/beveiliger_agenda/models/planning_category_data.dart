import 'package:flutter/material.dart';

/// Enum voor verschillende planning views
enum PlanningViewType {
  day,      // Dag overzicht
  week,     // Week overzicht
  month,    // Maand overzicht
  calendar, // Kalender view
}

/// Data model voor planning categorieën
class PlanningCategoryData {
  PlanningCategoryData({
    required this.title,
    required this.description,
    required this.icon,
    required this.viewType,
    this.imagePath = '',
    this.startColor = '#4A90E2',
    this.endColor = '#357ABD',
    this.isSelected = false,
    this.badgeCount = 0,
  });

  final String title;
  final String description;
  final IconData icon;
  final PlanningViewType viewType;
  final String imagePath;
  final String startColor;
  final String endColor;
  bool isSelected;
  final int badgeCount;

  /// Geeft een leesbare string voor het view type
  String get viewTypeDisplayName {
    switch (viewType) {
      case PlanningViewType.day:
        return 'Vandaag';
      case PlanningViewType.week:
        return 'Deze Week';
      case PlanningViewType.month:
        return 'Deze Maand';
      case PlanningViewType.calendar:
        return 'Kalender';
    }
  }

  /// Kopieert het object met nieuwe waarden
  PlanningCategoryData copyWith({
    String? title,
    String? description,
    IconData? icon,
    PlanningViewType? viewType,
    String? imagePath,
    String? startColor,
    String? endColor,
    bool? isSelected,
    int? badgeCount,
  }) {
    return PlanningCategoryData(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      viewType: viewType ?? this.viewType,
      imagePath: imagePath ?? this.imagePath,
      startColor: startColor ?? this.startColor,
      endColor: endColor ?? this.endColor,
      isSelected: isSelected ?? this.isSelected,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }

  /// Standaard planning categorieën
  static List<PlanningCategoryData> getDefaultCategories() {
    return [
      PlanningCategoryData(
        title: 'Vandaag',
        description: 'Diensten voor vandaag',
        icon: Icons.today,
        viewType: PlanningViewType.day,
        startColor: '#4A90E2',
        endColor: '#357ABD',
        badgeCount: 2,
      ),
      PlanningCategoryData(
        title: 'Deze Week',
        description: 'Week planning overzicht',
        icon: Icons.view_week,
        viewType: PlanningViewType.week,
        startColor: '#27AE60',
        endColor: '#2ECC71',
        badgeCount: 5,
      ),
      PlanningCategoryData(
        title: 'Kalender',
        description: 'Maand kalender view',
        icon: Icons.calendar_month,
        viewType: PlanningViewType.calendar,
        startColor: '#E67E22',
        endColor: '#F39C12',
        badgeCount: 12,
      ),
      PlanningCategoryData(
        title: 'Beschikbaarheid',
        description: 'Stel beschikbare tijden in',
        icon: Icons.schedule,
        viewType: PlanningViewType.month,
        startColor: '#9B59B6',
        endColor: '#8E44AD',
        badgeCount: 0,
      ),
    ];
  }
}