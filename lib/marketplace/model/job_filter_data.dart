/// Job filter data model following template's PopularFilterListData pattern
/// Adapted from hotel_booking/model/popular_filter_list.dart structure
class JobFilterData {
  JobFilterData({
    this.titleTxt = '',
    this.isSelected = false,
  });

  String titleTxt;
  bool isSelected;

  /// Job type filters (following template's static list pattern)
  static List<JobFilterData> jobTypeFilters = <JobFilterData>[
    JobFilterData(
      titleTxt: 'Alle types',
      isSelected: true,
    ),
    JobFilterData(
      titleTxt: 'Objectbeveiliging',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Evenementbeveiliging',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Winkelbeveiliging',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Persoonbeveiliging',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Portier',
      isSelected: false,
    ),
  ];

  /// Certificate filters (following template's static list pattern)
  static List<JobFilterData> certificateFilters = <JobFilterData>[
    JobFilterData(
      titleTxt: 'Beveiligingsdiploma A',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Beveiligingsdiploma B',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'BHV',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'VCA',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Portier',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Rijbewijs B',
      isSelected: false,
    ),
  ];

  /// Distance filters (following template's static list pattern)
  static List<JobFilterData> distanceFilters = <JobFilterData>[
    JobFilterData(
      titleTxt: 'Binnen 2 km',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Binnen 5 km',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Binnen 10 km',
      isSelected: true,
    ),
    JobFilterData(
      titleTxt: 'Binnen 25 km',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Geen limiet',
      isSelected: false,
    ),
  ];

  /// Availability filters (following template's static list pattern)
  static List<JobFilterData> availabilityFilters = <JobFilterData>[
    JobFilterData(
      titleTxt: 'Vandaag beschikbaar',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Deze week',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Deze maand',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Flexibel',
      isSelected: true,
    ),
  ];

  /// Shift type filters (following template's static list pattern)
  static List<JobFilterData> shiftFilters = <JobFilterData>[
    JobFilterData(
      titleTxt: 'Dagdienst',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Avonddienst',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Nachtdienst',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Weekend',
      isSelected: false,
    ),
    JobFilterData(
      titleTxt: 'Alle diensten',
      isSelected: true,
    ),
  ];

  /// Get selected job types (following template's selection pattern)
  static List<String> getSelectedJobTypes() {
    return jobTypeFilters
        .where((filter) => filter.isSelected && filter.titleTxt != 'Alle types')
        .map((filter) => filter.titleTxt)
        .toList();
  }

  /// Get selected certificates (following template's selection pattern)
  static List<String> getSelectedCertificates() {
    return certificateFilters
        .where((filter) => filter.isSelected)
        .map((filter) => filter.titleTxt)
        .toList();
  }

  /// Get selected distance (following template's selection pattern)
  static double getSelectedMaxDistance() {
    final selectedDistance = distanceFilters.firstWhere(
      (filter) => filter.isSelected,
      orElse: () => distanceFilters[2], // Default to 10km
    );

    switch (selectedDistance.titleTxt) {
      case 'Binnen 2 km':
        return 2.0;
      case 'Binnen 5 km':
        return 5.0;
      case 'Binnen 10 km':
        return 10.0;
      case 'Binnen 25 km':
        return 25.0;
      case 'Geen limiet':
        return 100.0;
      default:
        return 10.0;
    }
  }

  /// Reset all filters (following template's reset pattern)
  static void resetAllFilters() {
    // Reset job type filters
    for (var filter in jobTypeFilters) {
      filter.isSelected = filter.titleTxt == 'Alle types';
    }

    // Reset certificate filters
    for (var filter in certificateFilters) {
      filter.isSelected = false;
    }

    // Reset distance filters
    for (var filter in distanceFilters) {
      filter.isSelected = filter.titleTxt == 'Binnen 10 km';
    }

    // Reset availability filters
    for (var filter in availabilityFilters) {
      filter.isSelected = filter.titleTxt == 'Flexibel';
    }

    // Reset shift filters
    for (var filter in shiftFilters) {
      filter.isSelected = filter.titleTxt == 'Alle diensten';
    }
  }

  /// Check if any filters are active (following template's check pattern)
  static bool hasActiveFilters() {
    // Check job type filters (excluding "Alle types")
    if (jobTypeFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Alle types')) {
      return true;
    }

    // Check certificate filters
    if (certificateFilters.any((filter) => filter.isSelected)) {
      return true;
    }

    // Check distance filters (excluding default "Binnen 10 km")
    if (distanceFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Binnen 10 km')) {
      return true;
    }

    // Check availability filters (excluding default "Flexibel")
    if (availabilityFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Flexibel')) {
      return true;
    }

    // Check shift filters (excluding default "Alle diensten")
    if (shiftFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Alle diensten')) {
      return true;
    }

    return false;
  }

  /// Get active filter count (following template's count pattern)
  static int getActiveFilterCount() {
    int count = 0;

    // Count job type filters (excluding "Alle types")
    count += jobTypeFilters
        .where((filter) => filter.isSelected && filter.titleTxt != 'Alle types')
        .length;

    // Count certificate filters
    count += certificateFilters.where((filter) => filter.isSelected).length;

    // Count distance filters (excluding default)
    if (distanceFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Binnen 10 km')) {
      count++;
    }

    // Count availability filters (excluding default)
    if (availabilityFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Flexibel')) {
      count++;
    }

    // Count shift filters (excluding default)
    if (shiftFilters.any((filter) => 
        filter.isSelected && filter.titleTxt != 'Alle diensten')) {
      count++;
    }

    return count;
  }
}
