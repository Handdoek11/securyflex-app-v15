import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../unified_components/premium_glass_system.dart';

/// Privacy Notice Section Widget
/// Displays current privacy policy and terms in Dutch
/// Implements transparent privacy communication requirements
class PrivacyNoticeSection extends StatelessWidget {
  const PrivacyNoticeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrivacyNoticeOverview(context),
          const SizedBox(height: 20),
          _buildPrivacyPolicyContent(context),
          const SizedBox(height: 20),
          _buildDutchComplianceInfo(context),
          const SizedBox(height: 20),
          _buildContactInformation(context),
        ],
      ),
    );
  }

  Widget _buildPrivacyNoticeOverview(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Privacyverklaring SecuryFlex',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Versie 2.0 - Geldig vanaf 1 januari 2024',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deze privacyverklaring is opgesteld conform de Algemene Verordening Gegevensbescherming (AVG/GDPR) '
                    'en de Nederlandse privacywetgeving. Wij respecteren uw privacy en beschermen uw persoonlijke gegevens.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickStat(context, 'Laatste Update', '1 Jan 2024', Icons.update),
                const SizedBox(width: 16),
                _buildQuickStat(context, 'Taal Niveau', 'B1 Nederlands', Icons.language),
                const SizedBox(width: 16),
                _buildQuickStat(context, 'Compliance', 'AVG/GDPR', Icons.verified_user),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPolicyContent(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.article,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Privacybeleid Inhoud',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('1. Wie zijn wij?'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'SecuryFlex B.V. is een Nederlands bedrijf dat zich toelegt op het verbinden van '
                    'beveiligingsprofessionals met beveiligingsbedrijven. Wij zijn geregistreerd '
                    'bij de Kamer van Koophandel onder nummer [KVK_NUMMER] en gevestigd te Amsterdam.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('2. Welke gegevens verzamelen wij?'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wij verzamelen de volgende categorieën persoonlijke gegevens:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDataCategoryItem(context, 'Basisgegevens', 'Naam, e-mailadres, telefoonnummer, adres'),
                      _buildDataCategoryItem(context, 'WPBR Certificaten', 'Beveiligingscertificaten en verloopdatums'),
                      _buildDataCategoryItem(context, 'BSN (optioneel)', 'Voor identiteitsverificatie bij specifieke opdrachten'),
                      _buildDataCategoryItem(context, 'Werkgegevens', 'Werkervaring, specialisaties, beschikbaarheid'),
                      _buildDataCategoryItem(context, 'Locatiegegevens', 'GPS-coördinaten tijdens werkzaamheden (versleuteld)'),
                      _buildDataCategoryItem(context, 'Communicatie', 'Berichten via de app, notificaties'),
                      _buildDataCategoryItem(context, 'Technische gegevens', 'IP-adres, apparaatinfo, gebruiksstatistieken'),
                    ],
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('3. Waarom verzamelen wij deze gegevens?'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPurposeItem(
                        context,
                        'Account beheer',
                        'Voor het aanmaken en beheren van uw account (Art. 6(1)(b) AVG)',
                        Icons.account_circle,
                      ),
                      _buildPurposeItem(
                        context,
                        'Baan matching',
                        'Voor het koppelen van geschikte opdrachten aan uw profiel (Art. 6(1)(b) AVG)',
                        Icons.work,
                      ),
                      _buildPurposeItem(
                        context,
                        'WPBR compliance',
                        'Voor naleving van wettelijke verplichtingen in de beveiligingsbranche (Art. 6(1)(c) AVG)',
                        Icons.verified,
                      ),
                      _buildPurposeItem(
                        context,
                        'Tijdregistratie',
                        'Voor nauwkeurige tijdregistratie en salarisadministratie (Art. 6(1)(b) AVG)',
                        Icons.schedule,
                      ),
                      _buildPurposeItem(
                        context,
                        'Veiligheid',
                        'Voor het waarborgen van veiligheid op de werkplek (Art. 6(1)(f) AVG)',
                        Icons.security,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('4. Hoe lang bewaren wij uw gegevens?'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRetentionItem(context, 'WPBR Certificaten', '7 jaar (wettelijke bewaarplicht)'),
                      _buildRetentionItem(context, 'BSN gegevens', '7 jaar na laatste gebruik'),
                      _buildRetentionItem(context, 'CAO gegevens', '5 jaar (arbeidsrechtelijke verplichting)'),
                      _buildRetentionItem(context, 'Profielgegevens', 'Zolang account actief is'),
                      _buildRetentionItem(context, 'Chat berichten', '6 maanden na verzending'),
                      _buildRetentionItem(context, 'Locatiegegevens', '2 jaar voor tijdregistratie'),
                      _buildRetentionItem(context, 'Technische logs', '1 jaar voor beveiliging'),
                    ],
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('5. Uw rechten onder de AVG'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'U heeft de volgende rechten betreffende uw persoonlijke gegevens:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRightItem(
                        context,
                        'Recht van inzage (Art. 15)',
                        'U kunt opvragen welke gegevens wij van u hebben',
                        Icons.visibility,
                      ),
                      _buildRightItem(
                        context,
                        'Recht op rectificatie (Art. 16)',
                        'U kunt onjuiste gegevens laten corrigeren',
                        Icons.edit,
                      ),
                      _buildRightItem(
                        context,
                        'Recht op vergetelheid (Art. 17)',
                        'U kunt verwijdering van uw gegevens verzoeken*',
                        Icons.delete,
                      ),
                      _buildRightItem(
                        context,
                        'Recht op beperking (Art. 18)',
                        'U kunt beperking van verwerking verzoeken',
                        Icons.pause,
                      ),
                      _buildRightItem(
                        context,
                        'Recht op overdraagbaarheid (Art. 20)',
                        'U kunt uw gegevens in machine-leesbaar formaat ontvangen',
                        Icons.file_download,
                      ),
                      _buildRightItem(
                        context,
                        'Recht van bezwaar (Art. 21)',
                        'U kunt bezwaar maken tegen bepaalde verwerkingen',
                        Icons.block,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.amber[700],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Belangrijke uitzondering',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '*WPBR certificaten en BSN gegevens kunnen niet altijd volledig worden '
                              'verwijderd vanwege wettelijke bewaarplichten van 7 jaar.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('6. Beveiliging van uw gegevens'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wij nemen uitgebreide beveiligingsmaatregelen om uw gegevens te beschermen:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityMeasure(context, 'Encryptie', 'Alle gegevens worden versleuteld opgeslagen en verzonden'),
                      _buildSecurityMeasure(context, 'Toegangscontrole', 'Strenge toegangsbeperking met multi-factor authenticatie'),
                      _buildSecurityMeasure(context, 'Firewalls', 'Geavanceerde netwerk beveiliging en monitoring'),
                      _buildSecurityMeasure(context, 'Backup', 'Regelmatige, beveiligde back-ups van alle gegevens'),
                      _buildSecurityMeasure(context, 'Audits', 'Regelmatige beveiligingsaudits en penetratietests'),
                      _buildSecurityMeasure(context, 'Training', 'Alle medewerkers krijgen privacy- en beveiligingstraining'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCategoryItem(BuildContext context, String category, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeItem(BuildContext context, String purpose, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purpose,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionItem(BuildContext context, String dataType, String period) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dataType,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            period,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightItem(BuildContext context, String right, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMeasure(BuildContext context, String measure, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measure,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutchComplianceInfo(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Nederlandse Wetgeving',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildComplianceItem(
              context,
              'WPBR Wet particuliere beveiligingsorganisaties en recherchebureaus',
              'Alle beveiligingsprofessionals moeten beschikken over geldige WPBR certificaten. '
              'Wij zijn verplicht deze certificaten 7 jaar te bewaren.',
              Icons.verified_user,
            ),
            _buildComplianceItem(
              context,
              'CAO Particuliere Beveiligingsorganisaties',
              'Wij houden ons aan alle bepalingen van de CAO betreffende arbeidsvoorwaarden, '
              'werktijden en salarisadministratie.',
              Icons.work,
            ),
            _buildComplianceItem(
              context,
              'BSN Wet',
              'Het Burgerservicenummer wordt alleen gebruikt voor identiteitsverificatie '
              'en uitsluitend met uw expliciete toestemming.',
              Icons.credit_card,
            ),
            _buildComplianceItem(
              context,
              'Algemene Verordening Gegevensbescherming (AVG)',
              'Volledige naleving van Europese privacywetgeving met Nederlandse uitvoering.',
              Icons.shield,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceItem(BuildContext context, String law, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  law,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInformation(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contact_support,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact & Vragen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Officer SecuryFlex B.V.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactMethod(
                    context,
                    Icons.email,
                    'E-mail',
                    'privacy@securyflex.nl',
                    () => _copyToClipboard(context, 'privacy@securyflex.nl'),
                  ),
                  _buildContactMethod(
                    context,
                    Icons.phone,
                    'Telefoon',
                    '+31 20 123 4567',
                    () => _copyToClipboard(context, '+31 20 123 4567'),
                  ),
                  _buildContactMethod(
                    context,
                    Icons.location_on,
                    'Adres',
                    'SecuryFlex B.V.\nPrivacylaan 123\n1000 AA Amsterdam',
                    () => _copyToClipboard(context, 'Privacylaan 123, 1000 AA Amsterdam'),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Wij reageren binnen 30 dagen op uw privacy verzoeken '
                            '(zoals vereist onder de AVG)',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Autoriteit Persoonsgegevens',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Heeft u klachten over hoe wij met uw persoonlijke gegevens omgaan? '
              'Dan kunt u contact opnemen met de Autoriteit Persoonsgegevens.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _copyToClipboard(context, 'https://autoriteitpersoonsgegevens.nl'),
              child: Text(
                'www.autoriteitpersoonsgegevens.nl',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactMethod(
    BuildContext context,
    IconData icon,
    String method,
    String value,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.copy,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gekopieerd naar klembord: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
