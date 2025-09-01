import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/gdpr_models.dart';
import '../services/gdpr_compliance_service.dart';
import '../../unified_components/premium_glass_system.dart';

/// Consent Management Section Widget
/// Implements Article 7 GDPR - Consent management
/// Provides granular control over data processing consents
class ConsentManagementSection extends StatefulWidget {
  final GDPRComplianceService gdprService;
  
  const ConsentManagementSection({
    Key? key,
    required this.gdprService,
  }) : super(key: key);

  @override
  State<ConsentManagementSection> createState() => _ConsentManagementSectionState();
}

class _ConsentManagementSectionState extends State<ConsentManagementSection> {
  Map<String, bool> _currentConsents = {};
  bool _isLoading = true;
  bool _isUpdating = false;
  
  // Predefined consent purposes for SecuryFlex
  final Map<String, ConsentPurposeInfo> _consentPurposes = {
    'profile_data_processing': ConsentPurposeInfo(
      id: 'profile_data_processing',
      title: 'Profiel Gegevens Verwerking',
      description: 'Verwerking van uw profiel gegevens voor account beheer en personalisatie',
      lawfulBasis: LawfulBasis.consent,
      isRequired: true,
      category: 'Essential',
    ),
    'job_matching': ConsentPurposeInfo(
      id: 'job_matching',
      title: 'Baan Matching Service',
      description: 'Gebruik van uw certificaten en voorkeuren om passende beveiligingsbanen voor te stellen',
      lawfulBasis: LawfulBasis.consent,
      isRequired: false,
      category: 'Functionality',
    ),
    'location_tracking': ConsentPurposeInfo(
      id: 'location_tracking',
      title: 'Locatie Tracking',
      description: 'Gebruik van locatiegegevens voor tijdregistratie en veiligheidsmonitoring',
      lawfulBasis: LawfulBasis.consent,
      isRequired: false,
      category: 'Operational',
    ),
    'marketing_communications': ConsentPurposeInfo(
      id: 'marketing_communications',
      title: 'Marketing Communicatie',
      description: 'Versturen van promotionele e-mails, nieuwsbrieven en marketingberichten',
      lawfulBasis: LawfulBasis.consent,
      isRequired: false,
      category: 'Marketing',
    ),
    'analytics_tracking': ConsentPurposeInfo(
      id: 'analytics_tracking',
      title: 'Analytics en Tracking',
      description: 'Gebruik van cookies en analytics voor app verbetering en gebruiksstatistieken',
      lawfulBasis: LawfulBasis.consent,
      isRequired: false,
      category: 'Analytics',
    ),
    'third_party_integrations': ConsentPurposeInfo(
      id: 'third_party_integrations',
      title: 'Derde Partij Integraties',
      description: 'Delen van gegevens met betrouwbare partners voor verbeterde dienstverlening',
      lawfulBasis: LawfulBasis.consent,
      isRequired: false,
      category: 'Integration',
    ),
    'wpbr_compliance': ConsentPurposeInfo(
      id: 'wpbr_compliance',
      title: 'WPBR Compliance Verificatie',
      description: 'Verwerking van WPBR certificaten voor wettelijke compliance (7 jaar bewaarplicht)',
      lawfulBasis: LawfulBasis.legalObligation,
      isRequired: true,
      category: 'Legal',
    ),
    'bsn_processing': ConsentPurposeInfo(
      id: 'bsn_processing',
      title: 'BSN Verificatie',
      description: 'Verwerking van Burgerservicenummer voor identiteitsverificatie',
      lawfulBasis: LawfulBasis.legalObligation,
      isRequired: true,
      category: 'Legal',
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentConsents();
  }

  Future<void> _loadCurrentConsents() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final consents = await widget.gdprService.getUserConsents();
      final consentMap = <String, bool>{};
      
      // Initialize all purposes with false
      for (final purpose in _consentPurposes.keys) {
        consentMap[purpose] = false;
      }
      
      // Update with actual consent status
      for (final consent in consents) {
        if (consent.isValid) {
          consentMap[consent.purpose] = true;
        }
      }
      
      setState(() {
        _currentConsents = consentMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij laden van toestemmingen: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConsentOverviewCard(context),
          const SizedBox(height: 20),
          _buildConsentCategoriesSection(context),
          const SizedBox(height: 20),
          _buildConsentHistoryCard(context),
        ],
      ),
    );
  }

  Widget _buildConsentOverviewCard(BuildContext context) {
    final totalConsents = _consentPurposes.length;
    final givenConsents = _currentConsents.values.where((consent) => consent).length;
    final consentPercentage = totalConsents > 0 ? (givenConsents / totalConsents) : 0.0;
    
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Toestemmings Overzicht',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildConsentMetric(
                    context,
                    'Totaal Toestemmingen',
                    givenConsents.toString(),
                    '$totalConsents beschikbaar',
                    Icons.fact_check,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildConsentMetric(
                    context,
                    'Percentage Actief',
                    '${(consentPercentage * 100).round()}%',
                    'Van alle toestemmingen',
                    Icons.percent,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: consentPercentage,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'U heeft toestemming gegeven voor $givenConsents van de $totalConsents verwerkingsdoeleinden',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentMetric(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConsentCategoriesSection(BuildContext context) {
    final categories = _groupConsentsByCategory();
    
    return Column(
      children: categories.entries.map((entry) {
        final category = entry.key;
        final purposes = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: PremiumGlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getCategoryIcon(category),
                      const SizedBox(width: 12),
                      Text(
                        _getCategoryDisplayName(category),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildCategoryStatusBadge(context, category, purposes),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: purposes.map((purpose) {
                      return _buildConsentToggle(context, purpose);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsentToggle(BuildContext context, ConsentPurposeInfo purpose) {
    final isConsented = _currentConsents[purpose.id] ?? false;
    final isLegalBasis = purpose.lawfulBasis != LawfulBasis.consent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
        color: isLegalBasis 
            ? Colors.grey.withValues(alpha: 0.05)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          purpose.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (purpose.isRequired)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Verplicht',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (isLegalBasis)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Wettelijk',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      purpose.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rechtsgrondslag: ${purpose.lawfulBasis.dutchName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: isConsented,
                onChanged: isLegalBasis || _isUpdating
                    ? null
                    : (value) => _toggleConsent(purpose.id, value),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          if (isLegalBasis)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deze gegevensverwerking is gebaseerd op een wettelijke verplichting en kan niet worden uitgeschakeld.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryStatusBadge(BuildContext context, String category, List<ConsentPurposeInfo> purposes) {
    final consentablePurposes = purposes.where((p) => p.lawfulBasis == LawfulBasis.consent).toList();
    final consentedCount = consentablePurposes.where((p) => _currentConsents[p.id] == true).length;
    
    if (consentablePurposes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Wettelijk',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    final allConsented = consentedCount == consentablePurposes.length;
    final someConsented = consentedCount > 0;
    
    Color badgeColor;
    String badgeText;
    
    if (allConsented) {
      badgeColor = Colors.green;
      badgeText = 'Alle Actief';
    } else if (someConsented) {
      badgeColor = Colors.orange;
      badgeText = '$consentedCount/${consentablePurposes.length} Actief';
    } else {
      badgeColor = Colors.grey;
      badgeText = 'Geen Actief';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildConsentHistoryCard(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Toestemmings Geschiedenis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showFullConsentHistory(context),
                  child: const Text('Bekijk Alles'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<ConsentRecord>>(
              future: widget.gdprService.getUserConsents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                
                final recentConsents = snapshot.data!.take(3).toList();
                
                if (recentConsents.isEmpty) {
                  return const Text('Geen toestemmingsgeschiedenis beschikbaar');
                }
                
                return Column(
                  children: recentConsents.map((consent) {
                    return _buildConsentHistoryItem(context, consent);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentHistoryItem(BuildContext context, ConsentRecord consent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            consent.isValid ? Icons.check_circle : Icons.cancel,
            color: consent.isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _consentPurposes[consent.purpose]?.title ?? consent.purpose,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${consent.isValid ? 'Toegestaan' : 'Ingetrokken'} op ${_formatDate(consent.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<ConsentPurposeInfo>> _groupConsentsByCategory() {
    final grouped = <String, List<ConsentPurposeInfo>>{};
    
    for (final purpose in _consentPurposes.values) {
      grouped.putIfAbsent(purpose.category, () => []).add(purpose);
    }
    
    // Sort categories by priority
    final sortedCategories = <String, List<ConsentPurposeInfo>>{};
    final categoryOrder = ['Essential', 'Legal', 'Functionality', 'Operational', 'Marketing', 'Analytics', 'Integration'];
    
    for (final category in categoryOrder) {
      if (grouped.containsKey(category)) {
        sortedCategories[category] = grouped[category]!;
      }
    }
    
    return sortedCategories;
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    
    switch (category) {
      case 'Essential':
        icon = Icons.security;
        color = Colors.red;
        break;
      case 'Legal':
        icon = Icons.gavel;
        color = Colors.blue;
        break;
      case 'Functionality':
        icon = Icons.build;
        color = Colors.green;
        break;
      case 'Operational':
        icon = Icons.work;
        color = Colors.orange;
        break;
      case 'Marketing':
        icon = Icons.campaign;
        color = Colors.purple;
        break;
      case 'Analytics':
        icon = Icons.analytics;
        color = Colors.teal;
        break;
      case 'Integration':
        icon = Icons.link;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.category;
        color = Colors.grey;
    }
    
    return Icon(icon, color: color, size: 24);
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'Essential':
        return 'Essentiële Functies';
      case 'Legal':
        return 'Wettelijke Verplichtingen';
      case 'Functionality':
        return 'Functionaliteit';
      case 'Operational':
        return 'Operationeel';
      case 'Marketing':
        return 'Marketing';
      case 'Analytics':
        return 'Analytics';
      case 'Integration':
        return 'Integraties';
      default:
        return category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleConsent(String purposeId, bool isConsented) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final purpose = _consentPurposes[purposeId]!;
      
      if (isConsented) {
        await widget.gdprService.recordConsent(
          purpose: purposeId,
          lawfulBasis: purpose.lawfulBasis,
          isGiven: true,
          consentMethod: 'app_toggle',
          consentText: purpose.description,
          metadata: {
            'category': purpose.category,
            'timestamp': DateTime.now().toIso8601String(),
            'userAction': 'manual_toggle',
          },
        );
      } else {
        await widget.gdprService.withdrawConsent(purposeId);
      }
      
      setState(() {
        _currentConsents[purposeId] = isConsented;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isConsented 
                ? 'Toestemming voor ${purpose.title} gegeven'
                : 'Toestemming voor ${purpose.title} ingetrokken',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij wijzigen toestemming: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _showFullConsentHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Volledige Toestemmings Geschiedenis',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<ConsentRecord>>(
                  future: widget.gdprService.getUserConsents(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    
                    final consents = snapshot.data!;
                    
                    return ListView.builder(
                      itemCount: consents.length,
                      itemBuilder: (context, index) {
                        return _buildConsentHistoryItem(context, consents[index]);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Sluiten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for consent purpose information
class ConsentPurposeInfo {
  final String id;
  final String title;
  final String description;
  final LawfulBasis lawfulBasis;
  final bool isRequired;
  final String category;
  
  const ConsentPurposeInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.lawfulBasis,
    required this.isRequired,
    required this.category,
  });
}
