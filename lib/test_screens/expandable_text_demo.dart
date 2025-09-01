import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_components/expandable_text.dart';
import 'package:securyflex_app/unified_components/consistent_card_layout.dart';

/// Demo screen for expandable text and address components
/// Shows how to handle text overflow in assignment/job cards
class ExpandableTextDemo extends StatefulWidget {
  const ExpandableTextDemo({super.key});

  @override
  State<ExpandableTextDemo> createState() => _ExpandableTextDemoState();
}

class _ExpandableTextDemoState extends State<ExpandableTextDemo> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          UnifiedHeader.simple(
            title: 'Expandable Text Demo',
            userRole: UserRole.company,
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),

          // Content
          Expanded(
            child: ResponsiveJobLayout(
              isGridView: _isGridView,
              children: [
                _buildJobCard1(),
                _buildJobCard2(),
                _buildJobCard3(),
                _buildAddressDemo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard1() {
    return ConsistentJobCard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JobCardHeader(
            title: 'Objectbeveiliging Kantoorcomplex Amsterdam Zuidas',
            subtitle: 'Dagdienst • Fulltime',
            statusBadge: Container(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingS,
                vertical: DesignTokens.spacingXS,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.statusConfirmed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: Text(
                'Actief',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DesignTokens.statusConfirmed,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ),
          ),

          SizedBox(height: JobCardSpacing.headerToContent),

          // Expandable address
          ExpandableAddress(
            address: 'Gustav Mahlerlaan 1212, 1082 MK Amsterdam Zuidas, Noord-Holland',
            maxLines: 2,
          ),

          SizedBox(height: JobCardSpacing.betweenContentItems),

          // Expandable description
          ExpandableText(
            text: 'Beveiliging van modern kantoorcomplex met toegangscontrole en surveillance. Dagdienst van 08:00-16:00 uur. Ervaring met CCTV systemen gewenst. Goede communicatieve vaardigheden en representatieve uitstraling vereist.',
            maxLines: 3,
          ),

          SizedBox(height: JobCardSpacing.contentToFooter),

          // Actions
          JobCardFooter(
            actions: [
              ElevatedButton(
                onPressed: () {},
                child: Text('Bewerken'),
              ),
              OutlinedButton(
                onPressed: () {},
                child: Text('Bekijken'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard2() {
    return ConsistentJobCard(
      userRole: UserRole.company,
      isSelected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JobCardHeader(
            title: 'Evenementbeveiliging',
            subtitle: 'Weekend • Tijdelijk',
          ),

          SizedBox(height: JobCardSpacing.headerToContent),

          ExpandableAddress(
            address: 'Ziggo Dome, De Passage 100, 1101 AX Amsterdam Zuidoost',
            maxLines: 1,
          ),

          SizedBox(height: JobCardSpacing.betweenContentItems),

          Text(
            '€28,50/uur',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DesignTokens.statusConfirmed,
              fontWeight: DesignTokens.fontWeightBold,
            ),
          ),

          SizedBox(height: JobCardSpacing.contentToFooter),

          JobCardFooter(
            actions: [
              ElevatedButton(
                onPressed: () {},
                child: Text('Sollicitaties'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard3() {
    return ConsistentJobCard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JobCardHeader(
            title: 'Persoonbeveiliging VIP',
            subtitle: 'Flexibele uren',
          ),

          SizedBox(height: JobCardSpacing.headerToContent),

          ExpandableAddress(
            address: 'Verschillende locaties in Den Haag en omgeving',
            maxLines: 2,
          ),

          SizedBox(height: JobCardSpacing.betweenContentItems),

          ExpandableText(
            text: 'Hoogwaardige persoonbeveiliging voor politieke figuren en zakelijke VIPs. Uitgebreide screening vereist.',
            maxLines: 2,
            showTooltipOnTap: true,
            tooltipMessage: 'Volledige functieomschrijving',
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDemo() {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address Overflow Demo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),

          SizedBox(height: DesignTokens.spacingM),

          Text('Korte adressen:'),
          SizedBox(height: DesignTokens.spacingS),
          ExpandableAddress(address: 'Dam 1, Amsterdam'),

          SizedBox(height: DesignTokens.spacingM),

          Text('Lange adressen (klik voor volledig adres):'),
          SizedBox(height: DesignTokens.spacingS),
          ExpandableAddress(
            address: 'Koningin Wilhelminaplein 13, 1062 HH Amsterdam Noord-Holland Nederland',
            maxLines: 1,
          ),

          SizedBox(height: DesignTokens.spacingS),
          ExpandableAddress(
            address: 'Bedrijvenpark De Hooge Burch, Laan van Westenenk 501, 7334 DT Apeldoorn, Gelderland',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
