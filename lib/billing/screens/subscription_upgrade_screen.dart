import 'package:flutter/material.dart';

import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../../unified_design_tokens.dart';
import '../../auth/auth_service.dart';

/// Subscription upgrade and tier selection screen
/// Displays available subscription tiers with features, pricing, and allows users
/// to upgrade their current subscription or start a new subscription
class SubscriptionUpgradeScreen extends StatefulWidget {
  final String? userId;
  final SubscriptionTier? currentTier;
  final bool showTrialOptions;
  
  const SubscriptionUpgradeScreen({
    super.key,
    this.userId,
    this.currentTier,
    this.showTrialOptions = true,
  });

  @override
  State<SubscriptionUpgradeScreen> createState() => _SubscriptionUpgradeScreenState();
}

class _SubscriptionUpgradeScreenState extends State<SubscriptionUpgradeScreen> {
  late final String _userId;
  Subscription? _currentSubscription;
  bool _isLoading = false;
  String? _error;
  SubscriptionTier? _selectedTier;

  // Available tiers for different user types
  static const List<SubscriptionTier> _zzpTiers = [SubscriptionTier.zzpGuard];
  
  static const List<SubscriptionTier> _companyTiers = [
    SubscriptionTier.companyBasic,
    SubscriptionTier.companyProfessional,
    SubscriptionTier.companyEnterprise,
  ];

  @override
  void initState() {
    super.initState();
    _userId = widget.userId ?? AuthService.currentUserId ?? '';
    _selectedTier = widget.currentTier;
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      setState(() => _isLoading = true);
      
      final subscription = await SubscriptionService.instance.getActiveSubscription(_userId);
      
      setState(() {
        _currentSubscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SubscriptionTier> _getAvailableTiers() {
    final userType = AuthService.currentUserType.toLowerCase();
    
    switch (userType) {
      case 'guard':
        return _zzpTiers;
      case 'company':
        return _companyTiers;
      default:
        return _zzpTiers; // Default to ZZP for unknown user types
    }
  }

  bool _canUpgradeToTier(SubscriptionTier tier) {
    if (_currentSubscription == null) return true;
    
    // Can't downgrade (for now)
    return tier.pricePerMonth >= _currentSubscription!.tier.pricePerMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.guardBackground,
      appBar: AppBar(
        title: const Text('Abonnement Kiezen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: DesignTokens.guardTextPrimary,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: DesignTokens.spacingL),
                  _buildTiersList(),
                  const SizedBox(height: DesignTokens.spacingL),
                  if (_selectedTier != null) _buildActionButtons(),
                ],
              ),
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
            'Abonnement opties laden...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kies je abonnement',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: FontWeight.w700,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Text(
          _currentSubscription != null
              ? 'Upgrade je huidige ${_currentSubscription!.tier.displayName} abonnement'
              : 'Selecteer het abonnement dat het beste bij je past',
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.mutedText,
          ),
        ),
        
        if (_currentSubscription != null) ...[
          const SizedBox(height: DesignTokens.spacingM),
          _buildCurrentSubscriptionCard(),
        ],
      ],
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final subscription = _currentSubscription!;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.guardPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.guardPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.guardPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.star,
              color: DesignTokens.colorWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Huidige abonnement',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subscription.tier.displayName,
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '€${subscription.priceWithBTW.toStringAsFixed(2)}/maand',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: DesignTokens.guardPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTiersList() {
    final availableTiers = _getAvailableTiers();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beschikbare abonnementen',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: FontWeight.w600,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        
        ...availableTiers.map((tier) => Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
          child: _buildTierCard(tier),
        )),
      ],
    );
  }

  Widget _buildTierCard(SubscriptionTier tier) {
    final isSelected = _selectedTier == tier;
    final isCurrent = _currentSubscription?.tier == tier;
    final canUpgrade = _canUpgradeToTier(tier);
    final isRecommended = tier == SubscriptionTier.companyProfessional;

    return GestureDetector(
      onTap: canUpgrade && !isCurrent ? () {
        setState(() {
          _selectedTier = tier;
        });
      } : null,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.guardPrimary
                    : isCurrent
                        ? DesignTokens.colorSuccess
                        : DesignTokens.colorGray300,
                width: isSelected || isCurrent ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected || isRecommended)
                  BoxShadow(
                    color: (isSelected ? DesignTokens.guardPrimary : DesignTokens.colorWarning)
                        .withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.displayName,
                            style: const TextStyle(
                              fontSize: DesignTokens.fontSizeTitle,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.guardTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tier.description,
                            style: const TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              color: DesignTokens.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingM),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '€${tier.priceWithBTW.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: DesignTokens.fontSizeTitleLarge,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.guardPrimary,
                          ),
                        ),
                        const Text(
                          'per maand',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeS,
                            color: DesignTokens.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: DesignTokens.spacingM),
                
                // Features list
                _buildFeaturesList(tier),
                
                if (isCurrent) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingM,
                      vertical: DesignTokens.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: DesignTokens.colorSuccess,
                          size: 16,
                        ),
                        const SizedBox(width: DesignTokens.spacingS),
                        const Text(
                          'Huidig abonnement',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeS,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.colorSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (!canUpgrade && !isCurrent) ...[
                  const SizedBox(height: DesignTokens.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingM,
                      vertical: DesignTokens.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorGray200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Niet beschikbaar voor downgrade',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontWeight: FontWeight.w500,
                        color: DesignTokens.mutedText,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Recommended badge
          if (isRecommended)
            Positioned(
              top: -2,
              right: DesignTokens.spacingM,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.colorWarning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AANBEVOLEN',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.colorWhite,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(SubscriptionTier tier) {
    final features = _getTierFeatures(tier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingS),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: DesignTokens.colorSuccess,
              size: 16,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                feature,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.guardTextPrimary,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  List<String> _getTierFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.zzpGuard:
        return [
          '30 dagen gratis proefperiode',
          'Solliciteren op vacatures',
          'Basis profiel beheer',
          'Certificaten beheer',
          'Chat met bedrijven',
          'Nederlandse klantenservice',
        ];
      case SubscriptionTier.companyBasic:
        return [
          'Tot 5 beveiligingsmedewerkers',
          'Basis vacature plaatsing',
          'Sollicitatie beheer',
          'Team overzicht',
          'Basis rapportage',
          'Email ondersteuning',
        ];
      case SubscriptionTier.companyProfessional:
        return [
          'Tot 25 beveiligingsmedewerkers',
          'Onbeperkt vacature plaatsing',
          'Geavanceerde sollicitatie tools',
          'Uitgebreide team analytics',
          'Automatische planning',
          'Prioriteit ondersteuning',
          'Custom branding opties',
        ];
      case SubscriptionTier.companyEnterprise:
        return [
          'Onbeperkt beveiligingsmedewerkers',
          'Enterprise vacature beheer',
          'AI-gestuurde matching',
          'Volledige analytics suite',
          'API toegang',
          '24/7 dedicated support',
          'White-label oplossing',
          'Custom integraties',
        ];
      default:
        return ['Basis functionaliteit'];
    }
  }

  Widget _buildActionButtons() {
    final selectedTier = _selectedTier!;
    final isCurrent = _currentSubscription?.tier == selectedTier;
    
    if (isCurrent) return const SizedBox.shrink();
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _upgradeToTier(selectedTier),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.guardPrimary,
              foregroundColor: DesignTokens.colorWhite,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _currentSubscription != null ? 'Upgrade naar ${selectedTier.displayName}' : 'Start ${selectedTier.displayName}',
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        if (widget.showTrialOptions && selectedTier.hasTrialPeriod && _currentSubscription == null) ...[
          const SizedBox(height: DesignTokens.spacingM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _startTrial(selectedTier),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.guardPrimary,
                side: BorderSide(color: DesignTokens.guardPrimary, width: 1),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '30 dagen gratis proberen',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        
        const SizedBox(height: DesignTokens.spacingM),
        
        Text(
          '• Alle prijzen zijn inclusief 21% BTW\n'
          '• Abonnement kan maandelijks opgezegd worden\n'
          '• Gratis proefperiode eindigt automatisch',
          style: const TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: DesignTokens.mutedText,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _upgradeToTier(SubscriptionTier tier) async {
    try {
      setState(() => _isLoading = true);
      
      final result = _currentSubscription != null
          ? await SubscriptionService.instance.upgradeSubscription(
              subscriptionId: _currentSubscription!.id,
              newTier: tier,
            )
          : await SubscriptionService.instance.createSubscription(
              userId: _userId,
              tier: tier,
              startTrial: false,
            );

      setState(() => _isLoading = false);

      if (result.success) {
        _showSuccessDialog(tier, false);
      } else {
        _showErrorDialog(result.error ?? 'Upgrade mislukt');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _startTrial(SubscriptionTier tier) async {
    try {
      setState(() => _isLoading = true);
      
      final result = await SubscriptionService.instance.createSubscription(
        userId: _userId,
        tier: tier,
        startTrial: true,
      );

      setState(() => _isLoading = false);

      if (result.success) {
        _showSuccessDialog(tier, true);
      } else {
        _showErrorDialog(result.error ?? 'Proefperiode starten mislukt');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  void _showSuccessDialog(SubscriptionTier tier, bool isTrial) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: DesignTokens.colorSuccess,
              size: 28,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            const Text('Gelukt!'),
          ],
        ),
        content: Text(
          isTrial
              ? 'Je 30 dagen gratis proefperiode voor ${tier.displayName} is gestart!'
              : 'Je abonnement is succesvol geüpgraded naar ${tier.displayName}!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, tier); // Return to previous screen with result
            },
            child: const Text('Geweldig!'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fout'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}