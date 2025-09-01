import 'package:intl/intl.dart';

class SafeDateUtils {
  static final Map<String, String> _dutchMonths = {
    '01': 'jan',
    '02': 'feb',
    '03': 'mrt',
    '04': 'apr',
    '05': 'mei',
    '06': 'jun',
    '07': 'jul',
    '08': 'aug',
    '09': 'sep',
    '10': 'okt',
    '11': 'nov',
    '12': 'dec',
  };

  static final Map<String, String> _dutchMonthsFull = {
    '01': 'januari',
    '02': 'februari',
    '03': 'maart',
    '04': 'april',
    '05': 'mei',
    '06': 'juni',
    '07': 'juli',
    '08': 'augustus',
    '09': 'september',
    '10': 'oktober',
    '11': 'november',
    '12': 'december',
  };

  static final List<String> _dutchDayNames = [
    'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'
  ];

  /// Formats date as "dd MMM" in Dutch (e.g., "15 mei")
  static String formatDayMonth(DateTime date) {
    try {
      final monthKey = date.month.toString().padLeft(2, '0');
      final monthName = _dutchMonths[monthKey] ?? 'jan';
      return '${date.day} $monthName';
    } catch (e) {
      return '${date.day} ${date.month}';
    }
  }

  /// Formats date as "MMMM yyyy" in Dutch (e.g., "mei 2024")
  static String formatMonthYear(DateTime date) {
    try {
      final monthKey = date.month.toString().padLeft(2, '0');
      final monthName = _dutchMonthsFull[monthKey] ?? 'januari';
      return '$monthName ${date.year}';
    } catch (e) {
      return '${date.month}/${date.year}';
    }
  }

  /// Formats time as "HH:mm" (e.g., "14:30")
  static String formatTime(DateTime date) {
    try {
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Gets Dutch day names for calendar headers
  static List<String> getDutchDayNames() {
    return _dutchDayNames;
  }

  /// Formats a date range as "HH:mm - HH:mm"
  static String formatTimeRange(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  /// Checks if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Gets the start of the day for a given date
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the end of the day for a given date
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}