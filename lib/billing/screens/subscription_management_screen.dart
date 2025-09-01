import 'package:flutter/material.dart';

import '../widgets/subscription_status_widget.dart';
import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../services/feature_access_service.dart';
import '../../unified_design_tokens.dart';
import '../../auth/auth_service.dart';

/// Comprehensive subscription management screen
/// Allows users to view current subscription, upgrade/downgrade, manage payment methods,
/// view billing history, and access subscription settings
class SubscriptionManagementScreen extends StatefulWidget {
  final String? userId;
  
  const SubscriptionManagementScreen({
    super.key,
    this.userId,
  });

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Subscription? _subscription;
  Map<String, dynamic>? _usageAnalytics;
  List<Map<String, dynamic>>? _billingHistory;
  bool _isLoading = true;
  String? _error;

  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? AuthService.currentUserId ?? '';
    _tabController = TabController(length: 4, vsync: this);
    _loadSubscriptionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        SubscriptionService.instance.getActiveSubscription(_userId),
        FeatureAccessService.instance.getDetailedUsageAnalytics(_userId),
        SubscriptionService.instance.getBillingHistory(_userId),
      ]);

      setState(() {
        _subscription = results[0] as Subscription?;
        _usageAnalytics = results[1] as Map<String, dynamic>?;
        _billingHistory = results[2] as List<Map<String, dynamic>>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadSubscriptionData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.guardBackground,
      appBar: AppBar(
        title: const Text('Abonnement Beheer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: DesignTokens.guardTextPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Vernieuwen',
          ),
        ],
        bottom: _isLoading || _error != null ? null : TabBar(
          controller: _tabController,
          labelColor: DesignTokens.guardPrimary,
          unselectedLabelColor: DesignTokens.mutedText,
          indicatorColor: DesignTokens.guardPrimary,
          tabs: const [
            Tab(text: 'Overzicht', icon: Icon(Icons.dashboard)),
            Tab(text: 'Gebruik', icon: Icon(Icons.analytics)),
            Tab(text: 'Facturen', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Instellingen', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildUsageTab(),
                    _buildBillingTab(),
                    _buildSettingsTab(),
                  ],
                ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Abonnement gegevens laden...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.colorError,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            const Text(
              'Fout bij laden gegevens',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
                color: DesignTokens.guardTextPrimary,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              _error ?? 'Onbekende fout',
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.mutedText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.guardPrimary,
                foregroundColor: DesignTokens.colorWhite,
              ),
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current subscription status
          SubscriptionStatusWidget(
            userId: _userId,
            showDetails: true,
            onUpgradePressed: () => _navigateToUpgrade(),
          ),
          
          const SizedBox(height: DesignTokens.spacingM),
          
          // Quick actions
          _buildQuickActionsCard(),
          
          const SizedBox(height: DesignTokens.spacingM),
          
          // Recent activity summary
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.colorGray300, width: 1),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.colorBlack.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Snelle acties',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.upgrade,
                  label: 'Upgrade',
                  onTap: () => _navigateToUpgrade(),
                  color: DesignTokens.guardPrimary,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.payment,
                  label: 'Betaling',
                  onTap: () => _showPaymentMethods(),
                  color: DesignTokens.colorInfo,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: DesignTokens.spacingS),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.receipt,
                  label: 'Facturen',
                  onTap: () => _tabController.animateTo(2),
                  color: DesignTokens.colorWarning,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.help_outline,
                  label: 'Help',
                  onTap: () => _showHelp(),
                  color: DesignTokens.mutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingM,
            horizontal: DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                label,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final subscription = _subscription;
    if (subscription == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.colorGray300, width: 1),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.colorBlack.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recente activiteit',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          
          _buildActivityItem(
            icon: Icons.payment,
            title: 'Laatste betaling',
            subtitle: subscription.lastPaymentDate != null
                ? '€${subscription.priceWithBTW.toStringAsFixed(2)} • ${_formatDate(subscription.lastPaymentDate!)}'
                : 'Nog geen betalingen',
            color: DesignTokens.colorSuccess,
          ),
          
          _buildActivityItem(
            icon: Icons.schedule,
            title: 'Volgende betaling',
            subtitle: subscription.nextPaymentDate != null
                ? _formatDate(subscription.nextPaymentDate!)
                : 'Niet gepland',
            color: DesignTokens.colorInfo,
          ),
          
          _buildActivityItem(
            icon: Icons.analytics,
            title: 'Maandelijks gebruik',
            subtitle: 'Bekijk gedetailleerde statistieken',
            color: DesignTokens.guardPrimary,
            onTap: () => _tabController.animateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: FontWeight.w500,
                        color: DesignTokens.guardTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: DesignTokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: DesignTokens.mutedText,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gebruik Statistieken',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeHeading,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          const Text(
            'Overzicht van je abonnement gebruik deze maand',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          
          // Usage analytics will be implemented here
          _buildComingSoonCard('Gedetailleerde gebruik statistieken'),
        ],
      ),
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Factuurgeschiedenis',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeHeading,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          const Text(
            'Bekijk en download je facturen',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          
          // Billing history will be implemented here
          _buildComingSoonCard('Factuur geschiedenis en downloads'),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Abonnement Instellingen',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeHeading,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          const Text(
            'Beheer je abonnement voorkeuren',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          
          _buildSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.colorGray300, width: 1),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: Icons.credit_card,
            title: 'Betaalmethoden',
            subtitle: 'Beheer je betaalmethoden',
            onTap: () => _showPaymentMethods(),
          ),
          
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Meldingen',
            subtitle: 'Abonnement meldingen instellen',
            onTap: () => _showNotificationSettings(),
          ),
          
          _buildSettingItem(
            icon: Icons.security,
            title: 'Privacy & Beveiliging',
            subtitle: 'Account beveiliging instellingen',
            onTap: () => _showSecuritySettings(),
          ),
          
          _buildSettingItem(
            icon: Icons.cancel,
            title: 'Abonnement opzeggen',
            subtitle: 'Abonnement annuleren',
            onTap: () => _showCancelDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? DesignTokens.colorError : DesignTokens.guardTextPrimary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingS),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: DesignTokens.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: DesignTokens.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(String feature) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.colorGray300, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction,
            size: 48,
            color: DesignTokens.mutedText,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Binnenkort beschikbaar',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Text(
            feature,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  void _navigateToUpgrade() {
    Navigator.pushNamed(context, '/subscription-upgrade');
  }

  void _showPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Betaalmethoden beheer binnenkort beschikbaar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Ondersteuning'),
        content: const Text(
          'Voor vragen over je abonnement:\n\n'
          '• Email: support@securyflex.nl\n'
          '• Telefoon: 085 - 123 4567\n'
          '• Website: help.securyflex.nl',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Melding instellingen binnenkort beschikbaar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSecuritySettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Beveiligings instellingen binnenkort beschikbaar'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abonnement opzeggen'),
        content: const Text(
          'Weet je zeker dat je je abonnement wilt opzeggen? '
          'Je verliest toegang tot alle premium functies aan het einde van je huidige facturatieperiode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abonnement opzegging binnenkort beschikbaar'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
            ),
            child: const Text('Opzeggen'),
          ),
        ],
      ),
    );
  }
}