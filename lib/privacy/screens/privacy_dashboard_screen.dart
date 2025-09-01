import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/gdpr_models.dart';
import '../services/gdpr_compliance_service.dart';
import '../widgets/data_subject_rights_section.dart';
import '../widgets/consent_management_section.dart';
import '../widgets/data_export_section.dart';
import '../widgets/privacy_notice_section.dart';
import '../../unified_components/smart_tab_bar.dart';
import '../../unified_components/premium_glass_system.dart';

/// Privacy Dashboard Screen
/// Central hub for GDPR/AVG data subject rights management
/// Provides self-service privacy management for users
class PrivacyDashboardScreen extends StatefulWidget {
  const PrivacyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyDashboardScreen> createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen> 
    with SingleTickerProviderStateMixin {
  final GDPRComplianceService _gdprService = GDPRComplianceService();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildPrivacyAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrivacyOverviewCard(context),
                  const SizedBox(height: 24),
                  _buildPrivacyTabSections(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Privacy Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        // subtitle not supported in FlexibleSpaceBar
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 80,
                right: 20,
                child: Icon(
                  Icons.privacy_tip_outlined,
                  size: 100,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyOverviewCard(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.security,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uw Privacy Rechten',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Volledige controle over uw persoonlijke gegevens volgens de AVG/GDPR',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPrivacyRightsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyRightsGrid(BuildContext context) {
    final rights = [
      {
        'icon': Icons.visibility_outlined,
        'title': 'Inzage',
        'subtitle': 'Bekijk uw gegevens',
        'color': Colors.blue,
      },
      {
        'icon': Icons.edit_outlined,
        'title': 'Rectificatie',
        'subtitle': 'Corrigeer gegevens',
        'color': Colors.orange,
      },
      {
        'icon': Icons.delete_outline,
        'title': 'Vergetelheid',
        'subtitle': 'Verwijder gegevens',
        'color': Colors.red,
      },
      {
        'icon': Icons.file_download_outlined,
        'title': 'Portabiliteit',
        'subtitle': 'Download gegevens',
        'color': Colors.green,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: rights.length,
      itemBuilder: (context, index) {
        final right = rights[index];
        return Container(
          decoration: BoxDecoration(
            color: (right['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (right['color'] as Color).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  right['icon'] as IconData,
                  color: right['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        right['title'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: right['color'] as Color,
                        ),
                      ),
                      Text(
                        right['subtitle'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyTabSections(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          SmartTabBar(
            controller: _tabController,
            tabs: [
              SmartTab(
                icon: Icon(Icons.account_circle_outlined),
                text: 'Rechten',
              ),
              SmartTab(
                icon: Icon(Icons.check_circle_outlined),
                text: 'Toestemmingen',
              ),
              SmartTab(
                icon: Icon(Icons.file_download_outlined),
                text: 'Data Export',
              ),
              SmartTab(
                icon: Icon(Icons.policy_outlined),
                text: 'Privacy Beleid',
              ),
            ],
            isScrollable: true,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 600, // Fixed height for tab content
            child: TabBarView(
              children: [
                DataSubjectRightsSection(gdprService: _gdprService),
                ConsentManagementSection(gdprService: _gdprService),
                DataExportSection(gdprService: _gdprService),
                const PrivacyNoticeSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}

/// Privacy Settings Quick Actions
class PrivacyQuickActions extends StatelessWidget {
  final GDPRComplianceService gdprService;
  
  const PrivacyQuickActions({
    super.key,
    required this.gdprService,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snelle Acties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionButton(
              context,
              icon: Icons.file_download,
              title: 'Exporteer Mijn Gegevens',
              subtitle: 'Download alle persoonlijke gegevens',
              onTap: () => _exportUserData(context),
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              context,
              icon: Icons.delete_forever,
              title: 'Verwijder Account',
              subtitle: 'Permanent account verwijdering',
              onTap: () => _requestAccountDeletion(context),
              isDestructive: true,
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              context,
              icon: Icons.help_outline,
              title: 'Privacy Hulp',
              subtitle: 'Vragen over uw privacy rechten',
              onTap: () => _showPrivacyHelp(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportUserData(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Gegevens worden geëxporteerd...'),
            ],
          ),
        ),
      );

      await gdprService.submitDataSubjectRequest(
        requestType: DataSubjectRight.access,
        description: 'Volledige data export aangevraagd via privacy dashboard',
        dataCategories: ['all'],
      );

      context.pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data export aanvraag ingediend. U ontvangt binnen 30 dagen een e-mail.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      context.pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij aanvragen data export: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestAccountDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Verwijderen'),
        content: const Text(
          'Weet u zeker dat u uw account wilt verwijderen? '
          'Deze actie kan niet ongedaan worden gemaakt. '
          'WPBR certificaten worden 7 jaar bewaard conform wettelijke verplichtingen.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await gdprService.submitDataSubjectRequest(
          requestType: DataSubjectRight.erasure,
          description: 'Account verwijdering aangevraagd via privacy dashboard',
          dataCategories: ['profile', 'preferences', 'messages'],
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verwijderingsverzoek ingediend. Dit wordt binnen 30 dagen verwerkt.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij verwijderingsverzoek: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPrivacyHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Hulp'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Uw Privacy Rechten onder de AVG/GDPR:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('• Recht van Inzage (Art. 15): Bekijk alle gegevens die wij over u hebben'),
              SizedBox(height: 8),
              Text('• Recht op Rectificatie (Art. 16): Corrigeer onjuiste gegevens'),
              SizedBox(height: 8),
              Text('• Recht op Vergetelheid (Art. 17): Verwijder uw gegevens (met uitzonderingen)'),
              SizedBox(height: 8),
              Text('• Recht op Portabiliteit (Art. 20): Download uw gegevens'),
              SizedBox(height: 12),
              Text(
                'Nederlandse Specifieke Regels:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• WPBR certificaten: 7 jaar bewaarplicht'),
              Text('• BSN gegevens: Extra beveiligde verwerking'),
              Text('• CAO gegevens: 5 jaar bewaarplicht'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sluiten'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // Navigate to full privacy policy
            },
            child: const Text('Volledig Privacy Beleid'),
          ),
        ],
      ),
    );
  }
}
