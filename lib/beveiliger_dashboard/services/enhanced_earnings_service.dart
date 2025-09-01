import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/enhanced_dashboard_data.dart';

/// Enhanced earnings service with real-time tracking and Dutch CAO calculations
class EnhancedEarningsService {
  final StreamController<EnhancedEarningsData> _earningsController = 
      StreamController<EnhancedEarningsData>.broadcast();
  
  // Timer for real-time tracking - CRITICAL: properly managed to prevent memory leaks
  Timer? _realTimeTimer;
  bool _isDisposed = false;

  // Singleton pattern
  static EnhancedEarningsService? _instance;
  static EnhancedEarningsService get instance => _instance ??= EnhancedEarningsService();

  /// Stream for real-time earnings updates
  Stream<EnhancedEarningsData> get earningsStream => _earningsController.stream;

  /// Get enhanced earnings data with Dutch formatting and CAO calculations
  Future<EnhancedEarningsData> getEnhancedEarningsData() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock data for demonstration - in production this would come from Firebase
    final random = Random();
    final hoursWorkedToday = random.nextDouble() * 8; // 0-8 hours
    final hoursWorkedWeek = hoursWorkedToday + (random.nextDouble() * 32); // 0-40 hours
    final hourlyRate = 15.0 + random.nextDouble() * 10; // €15-25/hour (above CAO minimum)
    
    // Calculate overtime (CAO arbeidsrecht: 150% after 40h, 200% after 48h)
    double overtimeHours = 0;
    double overtimeRate = hourlyRate;
    
    if (hoursWorkedWeek > 40) {
      overtimeHours = hoursWorkedWeek - 40;
      if (hoursWorkedWeek > 48) {
        overtimeRate = hourlyRate * 2.0; // 200% after 48 hours
        overtimeHours = hoursWorkedWeek - 48;
      } else {
        overtimeRate = hourlyRate * 1.5; // 150% after 40 hours
      }
    }

    // Calculate base earnings
    final regularHours = hoursWorkedWeek > 40 ? 40 : hoursWorkedWeek;
    final baseEarningsWeek = regularHours * hourlyRate;
    final overtimeEarnings = overtimeHours * overtimeRate;
    final totalWeek = baseEarningsWeek + overtimeEarnings;
    
    final totalToday = hoursWorkedToday * hourlyRate;
    final totalMonth = totalWeek * 4.33; // Average weeks per month

    // Calculate vakantiegeld (8% holiday allowance - Dutch requirement)
    final vakantiegeld = totalMonth * 0.08;
    
    // Calculate BTW for freelance guards (21% Dutch VAT)
    final isFreelance = random.nextBool();
    final btwAmount = isFreelance ? totalMonth * 0.21 : 0.0;

    return EnhancedEarningsData(
      totalToday: totalToday,
      totalWeek: totalWeek,
      totalMonth: totalMonth,
      hourlyRate: hourlyRate,
      hoursWorkedToday: hoursWorkedToday,
      hoursWorkedWeek: hoursWorkedWeek,
      overtimeHours: overtimeHours,
      overtimeRate: overtimeRate,
      vakantiegeld: vakantiegeld,
      btwAmount: btwAmount,
      isFreelance: isFreelance,
      dutchFormattedToday: _formatDutchCurrency(totalToday),
      dutchFormattedWeek: _formatDutchCurrency(totalWeek),
      dutchFormattedMonth: _formatDutchCurrency(totalMonth),
      lastCalculated: DateTime.now(),
    );
  }

  /// Start real-time earnings tracking during active shifts
  /// FIXED: Proper timer management to prevent memory leaks
  void startRealTimeTracking() {
    // Prevent starting multiple timers and dispose check
    if (_isDisposed || _realTimeTimer != null) return;
    
    _realTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      // Check if service was disposed during timer execution
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      try {
        final updatedData = await getEnhancedEarningsData();
        
        // Double-check disposal before adding to stream
        if (!_isDisposed && !_earningsController.isClosed) {
          _earningsController.add(updatedData);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error updating real-time earnings: $e');
        }
        // On error, we might want to retry with exponential backoff
        // For now, continue the timer but log the error
      }
    });
  }

  /// Stop real-time tracking
  void stopRealTimeTracking() {
    _realTimeTimer?.cancel();
    _realTimeTimer = null;
  }

  /// Format currency in Dutch format (€1.234,56)
  String _formatDutchCurrency(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    // Add thousand separators (dots in Dutch format)
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }

  /// Calculate CAO-compliant overtime rates
  double calculateOvertimeRate(double baseRate, double totalHours) {
    if (totalHours <= 40) {
      return baseRate;
    } else if (totalHours <= 48) {
      return baseRate * 1.5; // 150% after 40 hours
    } else {
      return baseRate * 2.0; // 200% after 48 hours
    }
  }

  /// Validate if earnings meet Dutch minimum wage requirements
  bool validateMinimumWage(double hourlyRate) {
    const dutchMinimumWage = 12.0; // €12.00/hour for security work (2024)
    return hourlyRate >= dutchMinimumWage;
  }

  /// Calculate vakantiegeld (Dutch holiday allowance)
  double calculateVakantiegeld(double totalEarnings) {
    return totalEarnings * 0.08; // 8% holiday allowance
  }

  /// Calculate BTW for freelance guards
  double calculateBTW(double totalEarnings, bool isFreelance) {
    return isFreelance ? totalEarnings * 0.21 : 0; // 21% Dutch VAT
  }

  /// Properly dispose of all resources to prevent memory leaks
  void dispose() {
    _isDisposed = true;
    
    // Cancel timer first to prevent any pending operations
    _realTimeTimer?.cancel();
    _realTimeTimer = null;
    
    // Close stream controller
    if (!_earningsController.isClosed) {
      _earningsController.close();
    }
  }
}