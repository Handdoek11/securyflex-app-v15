import 'package:securyflex_app/company_dashboard/models/company_data.dart';
import 'package:securyflex_app/company_dashboard/localization/company_nl.dart';

/// Service for managing Company profile and business data
/// Following BeveiligerProfielService pattern with Company-specific functionality
class CompanyService {
  static CompanyService? _instance;
  static CompanyService get instance {
    _instance ??= CompanyService._();
    return _instance!;
  }
  
  CompanyService._();
  
  // Mock data - in production this would come from API/database
  CompanyData? _currentCompany;
  
  /// Get current company profile
  Future<CompanyData> getCurrentCompany() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentCompany ??= _createMockCompany();
    return _currentCompany!;
  }
  
  /// Update company profile
  Future<bool> updateCompany(CompanyData updatedCompany) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));
    
    _currentCompany = updatedCompany;
    return true;
  }
  
  /// Validate KvK number (Dutch Chamber of Commerce)
  static bool isValidKvK(String kvk) {
    // Remove any spaces or dashes
    final cleanKvK = kvk.replaceAll(RegExp(r'[\s-]'), '');
    
    // Must be exactly 8 digits
    if (!RegExp(r'^\d{8}$').hasMatch(cleanKvK)) {
      return false;
    }
    
    // Basic checksum validation (simplified)
    return true;
  }
  
  /// Validate Dutch postal code
  static bool isValidPostalCode(String postalCode) {
    return DutchBusinessValidation.isValidPostalCode(postalCode);
  }
  
  /// Validate Dutch phone number
  static bool isValidDutchPhone(String phone) {
    // Remove spaces and dashes
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    // Support +31 or 0 prefix formats
    return RegExp(r'^(\+31|0)[1-9]\d{8}$').hasMatch(cleanPhone);
  }
  
  /// Format Dutch phone number for display
  static String formatDutchPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleanPhone.startsWith('+31')) {
      // Format: +31 20 1234567
      return cleanPhone.replaceAllMapped(
        RegExp(r'\+31(\d{2})(\d{7})'),
        (match) => '+31 ${match.group(1)} ${match.group(2)}',
      );
    } else if (cleanPhone.startsWith('0')) {
      // Format: 020 1234567
      return cleanPhone.replaceAllMapped(
        RegExp(r'0(\d{2})(\d{7})'),
        (match) => '0${match.group(1)} ${match.group(2)}',
      );
    }
    
    return phone; // Return original if no pattern matches
  }
  
  /// Get company metrics for dashboard
  Future<Map<String, dynamic>> getCompanyMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'activeJobs': 5,
      'pendingApplications': 12,
      'totalGuardsHired': 23,
      'monthlySpent': 15750.00,
      'averageJobFillTime': 2.5, // days
      'companyRating': 4.6,
      'repeatHireRate': 78.5, // percentage
    };
  }
  
  /// Create mock company data for development
  CompanyData _createMockCompany() {
    return CompanyData(
      companyId: 'COMP001',
      companyName: 'Amsterdam Security Partners',
      kvkNumber: '12345678',
      btwNumber: 'NL123456789B01',
      contactPerson: 'Pieter van der Berg',
      emailAddress: 'info@amsterdamsecurity.nl',
      phoneNumber: '+31 20 1234567',
      address: 'Damrak 123',
      postalCode: '1012AB',
      city: 'Amsterdam',
      description: 'Professionele beveiligingsdiensten voor bedrijven in de Randstad. Gespecialiseerd in objectbeveiliging, evenementbeveiliging en persoonlijke beveiliging.',
      logoUrl: 'assets/company/amsterdam_security_logo.png',
      registeredSince: DateTime.now().subtract(const Duration(days: 365)),
      serviceTypes: [
        'Objectbeveiliging',
        'Evenementbeveiliging', 
        'Persoonbeveiliging',
        'Mobiele surveillance',
      ],
      operatingRegions: [
        'Amsterdam',
        'Utrecht', 
        'Den Haag',
        'Rotterdam',
      ],
      hasInsurance: true,
      insuranceProvider: 'Nationale Nederlanden',
      insuranceExpiry: DateTime.now().add(const Duration(days: 180)),
      averageRating: 4.6,
      totalJobsPosted: 127,
      activeJobs: 5,
      completedJobs: 122,
      totalSpent: 89750.00,
      totalGuardsHired: 23,
      averageJobValue: 735.00,
      status: CompanyStatus.active,
      isVerified: true,
      lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      verificationDocuments: [
        'KvK Uittreksel',
        'Verzekeringspolis',
        'BTW Certificaat',
      ],
    );
  }
  
  /// Get all companies (for admin functionality)
  static Future<List<CompanyData>> getAllCompanies() async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Mock data for development
    return [
      CompanyData(
        companyId: 'COMP001',
        companyName: 'Amsterdam Security Partners',
        kvkNumber: '12345678',
        contactPerson: 'Pieter van der Berg',
        emailAddress: 'info@amsterdamsecurity.nl',
        phoneNumber: '+31 20 1234567',
        address: 'Damrak 123',
        postalCode: '1012AB',
        city: 'Amsterdam',
        registeredSince: DateTime.now().subtract(const Duration(days: 365)),
        totalJobsPosted: 127,
        activeJobs: 5,
        averageRating: 4.6,
        status: CompanyStatus.active,
        isVerified: true,
      ),
      CompanyData(
        companyId: 'COMP002', 
        companyName: 'SecureMax Nederland',
        kvkNumber: '87654321',
        contactPerson: 'Maria Jansen',
        emailAddress: 'contact@securemax.nl',
        phoneNumber: '+31 30 9876543',
        address: 'Oudegracht 456',
        postalCode: '3511AB',
        city: 'Utrecht',
        registeredSince: DateTime.now().subtract(const Duration(days: 180)),
        totalJobsPosted: 89,
        activeJobs: 3,
        averageRating: 4.8,
        status: CompanyStatus.active,
        isVerified: true,
      ),
    ];
  }
}
