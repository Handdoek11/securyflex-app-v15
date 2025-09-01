import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'privacy/screens/privacy_dashboard_screen.dart';
import 'privacy/services/gdpr_compliance_service.dart';
import 'privacy/services/compliance_automation_service.dart';
import 'privacy/models/gdpr_models.dart';
import 'routing/app_routes.dart';

/// Navigation integration for GDPR/AVG Privacy features
/// Add these routes to your main navigation system
class PrivacyNavigationIntegration {
  
  /// Add privacy routes to your app's route configuration
  static Map<String, WidgetBuilder> getPrivacyRoutes() {
    return {
      '/privacy-dashboard': (context) => const PrivacyDashboardScreen(),
      '/privacy-settings': (context) => const PrivacyDashboardScreen(),
      '/gdpr-compliance': (context) => const PrivacyDashboardScreen(),
    };
  }
  
  /// Initialize GDPR compliance services
  /// Call this in your app's main() function
  static Future<void> initializePrivacyServices() async {
    try {
      // Initialize automated compliance workflows
      final automationService = ComplianceAutomationService();
      await automationService.initializeAutomation();
      
      debugPrint('✅ GDPR Compliance services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing privacy services: $e');
    }
  }
  
  /// Create privacy menu items for navigation drawer/menu
  static List<PrivacyMenuItem> getPrivacyMenuItems() {
    return [
      PrivacyMenuItem(
        title: 'Privacy Dashboard',
        subtitle: 'Beheer uw privacy instellingen',
        icon: Icons.privacy_tip,
        route: '/privacy-dashboard',
        color: Colors.blue,
      ),
      PrivacyMenuItem(
        title: 'Mijn Gegevens',
        subtitle: 'Inzage in persoonlijke gegevens',
        icon: Icons.person_outline,
        route: '/privacy-dashboard',
        tab: 0, // Data Subject Rights tab
        color: Colors.green,
      ),
      PrivacyMenuItem(
        title: 'Toestemmingen',
        subtitle: 'Beheer data verwerkingstoestemmingen',
        icon: Icons.check_circle_outline,
        route: '/privacy-dashboard',
        tab: 1, // Consent Management tab
        color: Colors.orange,
      ),
      PrivacyMenuItem(
        title: 'Data Export',
        subtitle: 'Download uw gegevens',
        icon: Icons.file_download,
        route: '/privacy-dashboard',
        tab: 2, // Data Export tab
        color: Colors.purple,
      ),
    ];
  }
  
  /// Create privacy quick action buttons
  static Widget buildPrivacyQuickActions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy & Beveiliging',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionChip(
                  context,
                  'Privacy Dashboard',
                  Icons.privacy_tip,
                  () => context.go(AppRoutes.privacy),
                ),
                _buildQuickActionChip(
                  context,
                  'Exporteer Data',
                  Icons.file_download,
                  () => context.go(AppRoutes.privacy),
                ),
                _buildQuickActionChip(
                  context,
                  'Toestemmingen',
                  Icons.check_circle,
                  () => context.go(AppRoutes.privacy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  static Widget _buildQuickActionChip(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18),
      label: Text(label),
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
    );
  }
  
  /// Add privacy notification banner for GDPR compliance
  static Widget buildPrivacyNoticeBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Privacy & Gegevensbescherming',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SecuryFlex respecteert uw privacy en beschermt uw persoonlijke gegevens '
            'conform de AVG/GDPR. U heeft volledige controle over uw gegevens.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: () => context.go(AppRoutes.privacy),
                child: const Text('Privacy Dashboard'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  // Show privacy policy dialog or navigate
                },
                child: const Text('Privacy Beleid'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Check if user needs to update privacy consents
  static Future<bool> needsPrivacyConsentUpdate() async {
    try {
      final gdprService = GDPRComplianceService();
      
      // Check for critical consent requirements
      final hasValidWPBRConsent = await gdprService.hasValidConsent('wpbr_compliance');
      final hasValidProfileConsent = await gdprService.hasValidConsent('profile_data_processing');
      
      return !hasValidWPBRConsent || !hasValidProfileConsent;
    } catch (e) {
      print('Error checking privacy consent status: $e');
      return false;
    }
  }
  
  /// Show privacy consent dialog for new users
  static Future<void> showPrivacyConsentDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Toestemmingen'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welkom bij SecuryFlex! Om u de beste service te kunnen bieden, '
                'hebben we uw toestemming nodig voor het verwerken van bepaalde gegevens.',
              ),
              SizedBox(height: 16),
              Text(
                'Wij verwerken uw gegevens conform de AVG/GDPR en Nederlandse wetgeving. '
                'U kunt uw toestemmingen op elk moment wijzigen via het Privacy Dashboard.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(AppRoutes.privacy);
            },
            child: const Text('Bekijk Details'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Record basic consent
              final gdprService = GDPRComplianceService();
              
              await gdprService.recordConsent(
                purpose: 'profile_data_processing',
                lawfulBasis: LawfulBasis.consent,
                isGiven: true,
                consentMethod: 'initial_dialog',
                consentText: 'Gebruiker heeft toestemming gegeven voor profiel gegevens verwerking',
              );
              
              Navigator.of(context).pop();
            },
            child: const Text('Akkoord'),
          ),
        ],
      ),
    );
  }
}

/// Privacy menu item model
class PrivacyMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final int? tab;
  final Color color;
  
  const PrivacyMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.tab,
    required this.color,
  });
}

/// GDPR Compliance Status Widget
/// Shows current compliance status in settings/profile screens
class GDPRComplianceStatusWidget extends StatefulWidget {
  const GDPRComplianceStatusWidget({super.key});
  
  @override
  State<GDPRComplianceStatusWidget> createState() => _GDPRComplianceStatusWidgetState();
}

class _GDPRComplianceStatusWidgetState extends State<GDPRComplianceStatusWidget> {
  final GDPRComplianceService _gdprService = GDPRComplianceService();
  Map<String, dynamic>? _complianceStatus;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadComplianceStatus();
  }
  
  Future<void> _loadComplianceStatus() async {
    try {
      final report = await _gdprService.generateComplianceReport();
      setState(() {
        _complianceStatus = report;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Privacy status laden...'),
            ],
          ),
        ),
      );
    }
    
    if (_complianceStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 16),
              Text('Fout bij laden privacy status'),
            ],
          ),
        ),
      );
    }
    
    final gdprRequests = _complianceStatus!['gdpr_requests'] as Map<String, dynamic>;
    final consentRecords = _complianceStatus!['consent_records'] as Map<String, dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'GDPR Compliance Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Privacy Verzoeken',
                    '${gdprRequests['total'] ?? 0}',
                    Icons.request_page,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Toestemmingen',
                    '${consentRecords['total'] ?? 0}',
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/privacy-dashboard'),
              child: const Text('Privacy Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
