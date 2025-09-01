import 'package:intl/intl.dart';

/// Dutch formatting utilities for numbers, currency, dates, and other locale-specific data
class DutchFormatting {
  DutchFormatting._();

  // Dutch locale
  static const Locale dutchLocale = Locale('nl', 'NL');
  
  // Number formatters
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'nl_NL',
    symbol: '€',
    decimalDigits: 2,
  );

  static final NumberFormat _percentageFormatter = NumberFormat.percentPattern('nl_NL');
  static final NumberFormat _decimalFormatter = NumberFormat.decimalPattern('nl_NL');

  // Date formatters
  static final DateFormat _dateFormatter = DateFormat('dd-MM-yyyy', 'nl_NL');
  static final DateFormat _dateTimeFormatter = DateFormat('dd-MM-yyyy HH:mm', 'nl_NL');
  static final DateFormat _timeFormatter = DateFormat('HH:mm', 'nl_NL');

  /// Format currency amount to Dutch standard (€1.234,56)
  static String formatCurrency(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format percentage to Dutch standard (12,34%)
  static String formatPercentage(double percentage) {
    return _percentageFormatter.format(percentage / 100);
  }

  /// Format decimal number to Dutch standard (1.234,56)
  static String formatDecimal(double number) {
    return _decimalFormatter.format(number);
  }

  /// Format date to Dutch standard (31-12-2024)
  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  /// Format date and time to Dutch standard (31-12-2024 15:30)
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Format time to Dutch standard (15:30)
  static String formatTime(DateTime time) {
    return _timeFormatter.format(time);
  }

  /// Format IBAN for display (NL12 ABCD 0123 4567 89)
  static String formatIBAN(String iban) {
    final cleanIBAN = iban.replaceAll(' ', '').toUpperCase();
    if (cleanIBAN.length != 18 || !cleanIBAN.startsWith('NL')) {
      return iban; // Return original if not valid Dutch IBAN
    }
    
    return '${cleanIBAN.substring(0, 4)} ${cleanIBAN.substring(4, 8)} ${cleanIBAN.substring(8, 12)} ${cleanIBAN.substring(12, 16)} ${cleanIBAN.substring(16, 18)}';
  }

  /// Format BSN (Burgerservicenummer) for display with spaces
  /// WARNING: This method is DEPRECATED for GDPR compliance
  /// Use BSNSecurityService.maskBSN() for secure BSN display
  @Deprecated('Use BSNSecurityService.maskBSN for GDPR Article 9 compliance')
  static String formatBSN(String bsn) {
    // Return masked BSN to prevent GDPR violations
    return '***-**-${bsn.length >= 2 ? bsn.substring(bsn.length - 2) : '**'}';
  }
  
  /// Secure BSN formatting that shows only masked version
  /// For internal use in billing documents where BSN display is required
  static String formatBSNSecure(String bsn) {
    if (bsn.isEmpty) return '';
    final cleanBSN = bsn.replaceAll(RegExp(r'\D'), '');
    if (cleanBSN.length != 9) return '***INVALID***';
    
    // Return masked version: show first 3 and last 2 digits
    return '${cleanBSN.substring(0, 3)}****${cleanBSN.substring(7, 9)}';
  }

  /// Format KvK number for display
  static String formatKvK(String kvkNumber) {
    final cleanKvK = kvkNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanKvK.length != 8) return kvkNumber;
    
    return '${cleanKvK.substring(0, 2)}.${cleanKvK.substring(2, 5)}.${cleanKvK.substring(5, 8)}';
  }

  /// Format phone number to Dutch standard
  static String formatPhoneNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Dutch mobile number (06)
    if (cleanPhone.startsWith('316') && cleanPhone.length == 11) {
      return '+31 6 ${cleanPhone.substring(3, 5)} ${cleanPhone.substring(5, 7)} ${cleanPhone.substring(7, 9)} ${cleanPhone.substring(9, 11)}';
    }
    
    // Dutch landline (various area codes)
    if (cleanPhone.startsWith('31') && cleanPhone.length >= 10) {
      return '+31 ${cleanPhone.substring(2, 4)} ${cleanPhone.substring(4, 7)} ${cleanPhone.substring(7, 11)}';
    }
    
    return phoneNumber; // Return original if doesn't match Dutch patterns
  }

  /// Format postal code to Dutch standard (1234 AB)
  static String formatPostalCode(String postalCode) {
    final cleanCode = postalCode.replaceAll(' ', '').toUpperCase();
    if (cleanCode.length != 6) return postalCode;
    
    return '${cleanCode.substring(0, 4)} ${cleanCode.substring(4, 6)}';
  }

  /// Parse Dutch formatted currency string to double
  static double? parseCurrency(String currencyString) {
    try {
      final cleanString = currencyString
          .replaceAll('€', '')
          .replaceAll(' ', '')
          .replaceAll('.', '') // Remove thousands separator
          .replaceAll(',', '.'); // Replace decimal separator
      return double.tryParse(cleanString);
    } catch (e) {
      return null;
    }
  }

  /// Parse Dutch formatted decimal string to double
  static double? parseDecimal(String decimalString) {
    try {
      final cleanString = decimalString
          .replaceAll('.', '') // Remove thousands separator
          .replaceAll(',', '.'); // Replace decimal separator
      return double.tryParse(cleanString);
    } catch (e) {
      return null;
    }
  }

  /// Parse Dutch date string to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse Dutch datetime string to DateTime
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return _dateTimeFormatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Format duration in Dutch (2u 30m)
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return minutes > 0 ? '${hours}u ${minutes}m' : '${hours}u';
    } else {
      return '${minutes}m';
    }
  }

  /// Format working hours for Dutch labor law
  static String formatWorkingHours(double hours) {
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();
    
    if (minutes == 0) {
      return '${wholeHours}u';
    } else {
      return '${wholeHours}u ${minutes}m';
    }
  }

  /// Format salary range in Dutch
  static String formatSalaryRange(double minSalary, double maxSalary) {
    return '${formatCurrency(minSalary)} - ${formatCurrency(maxSalary)}';
  }

  /// Validate Dutch IBAN format
  static bool isValidDutchIBAN(String iban) {
    final cleanIBAN = iban.replaceAll(' ', '').toUpperCase();
    
    // Check format: NL + 2 check digits + 4 bank code + 10 account number = 18 chars
    if (!RegExp(r'^NL\d{16}$').hasMatch(cleanIBAN)) {
      return false;
    }

    // IBAN check digit validation (mod-97)
    final rearranged = cleanIBAN.substring(4) + cleanIBAN.substring(0, 4);
    final numericString = rearranged.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => (match.group(0)!.codeUnitAt(0) - 55).toString(),
    );

    try {
      final remainder = BigInt.parse(numericString) % BigInt.from(97);
      return remainder == BigInt.one;
    } catch (e) {
      return false;
    }
  }

  /// Validate Dutch BSN using the 11-check
  static bool isValidBSN(String bsn) {
    final cleanBSN = bsn.replaceAll(RegExp(r'\D'), '');
    if (cleanBSN.length != 9) return false;
    
    final digits = cleanBSN.split('').map(int.parse).toList();
    
    // 11-check algorithm
    int sum = 0;
    for (int i = 0; i < 8; i++) {
      sum += digits[i] * (9 - i);
    }
    sum -= digits[8];
    
    return sum % 11 == 0;
  }

  /// Validate Dutch postal code format (1234AB)
  static bool isValidPostalCode(String postalCode) {
    final cleanCode = postalCode.replaceAll(' ', '').toUpperCase();
    return RegExp(r'^\d{4}[A-Z]{2}$').hasMatch(cleanCode);
  }

  /// Validate Dutch mobile phone number
  static bool isValidMobileNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Dutch mobile: starts with 06 (national) or +316 (international)
    return cleanPhone.startsWith('06') && cleanPhone.length == 10 ||
           cleanPhone.startsWith('316') && cleanPhone.length == 11;
  }

  /// Get Dutch day name
  static String getDayName(int weekday) {
    const dayNames = [
      'maandag',
      'dinsdag',
      'woensdag',
      'donderdag',
      'vrijdag',
      'zaterdag',
      'zondag',
    ];
    return dayNames[weekday - 1];
  }

  /// Get Dutch month name
  static String getMonthName(int month) {
    const monthNames = [
      'januari',
      'februari',
      'maart',
      'april',
      'mei',
      'juni',
      'juli',
      'augustus',
      'september',
      'oktober',
      'november',
      'december',
    ];
    return monthNames[month - 1];
  }

  /// Get Dutch quarter name for BTW reporting
  static String getQuarterName(int quarter) {
    switch (quarter) {
      case 1:
        return '1e kwartaal';
      case 2:
        return '2e kwartaal';
      case 3:
        return '3e kwartaal';
      case 4:
        return '4e kwartaal';
      default:
        return 'Kwartaal $quarter';
    }
  }
}

/// Extension methods for DateTime to format in Dutch
extension DutchDateTimeExtension on DateTime {
  String get toDutchDate => DutchFormatting.formatDate(this);
  String get toDutchDateTime => DutchFormatting.formatDateTime(this);
  String get toDutchTime => DutchFormatting.formatTime(this);
  String get toDutchDayName => DutchFormatting.getDayName(weekday);
  String get toDutchMonthName => DutchFormatting.getMonthName(month);
}

/// Extension methods for double to format in Dutch
extension DutchDoubleExtension on double {
  String get toDutchCurrency => DutchFormatting.formatCurrency(this);
  String get toDutchDecimal => DutchFormatting.formatDecimal(this);
  String get toDutchPercentage => DutchFormatting.formatPercentage(this);
  String get toDutchWorkingHours => DutchFormatting.formatWorkingHours(this);
}

/// Extension methods for Duration to format in Dutch
extension DutchDurationExtension on Duration {
  String get toDutchDuration => DutchFormatting.formatDuration(this);
}

class Locale {
  const Locale(this.languageCode, this.countryCode);
  
  final String languageCode;
  final String countryCode;
  
  @override
  String toString() => '${languageCode}_$countryCode';
}