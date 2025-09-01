import 'package:flutter/material.dart';
import '../models/gdpr_models.dart';
import '../services/gdpr_compliance_service.dart';
import '../../unified_components/premium_glass_system.dart';

/// Data Subject Rights Section Widget
/// Implements Article 15-22 AVG/GDPR rights management
class DataSubjectRightsSection extends StatefulWidget {
  final GDPRComplianceService gdprService;
  
  const DataSubjectRightsSection({
    super.key,
    required this.gdprService,
  });

  @override
  State<DataSubjectRightsSection> createState() => _DataSubjectRightsSectionState();
}

class _DataSubjectRightsSectionState extends State<DataSubjectRightsSection> {
  final _descriptionController = TextEditingController();
  DataSubjectRight _selectedRight = DataSubjectRight.access;
  bool _isSubmitting = false;
  List<String> _selectedDataCategories = [];
  
  final List<String> _availableDataCategories = [
    'Profiel gegevens',
    'Certificaten (WPBR)',
    'Werkgeschiedenis',
    'Betalingsgegevens',
    'Berichten',
    'Locatiegegevens',
    'Voorkeuren',
    'Alle gegevens',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentRequestsCard(context),
          const SizedBox(height: 20),
          _buildNewRequestCard(context),
          const SizedBox(height: 20),
          _buildRightsInformationCard(context),
        ],
      ),
    );
  }

  Widget _buildCurrentRequestsCard(BuildContext context) {
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
                  'Mijn Verzoeken',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<GDPRRequest>>(
              stream: widget.gdprService.getUserGDPRRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(context, snapshot.error.toString());
                }
                
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                final requests = snapshot.data!;
                
                if (requests.isEmpty) {
                  return _buildEmptyRequestsState(context);
                }
                
                return Column(
                  children: requests
                      .map((request) => _buildRequestCard(context, request))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, GDPRRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(context, request.status),
                const Spacer(),
                _buildRequestTypeChip(context, request.requestType),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'Ingediend: ${_formatDate(request.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                if (request.status == GDPRRequestStatus.pending)
                  Text(
                    '${request.daysRemaining} dagen resterend',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: request.daysRemaining < 7 ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            if (request.isOverdue)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Verzoek is verlopen - neem contact op met ons team',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, GDPRRequestStatus status) {
    Color badgeColor;
    IconData icon;
    
    switch (status) {
      case GDPRRequestStatus.pending:
        badgeColor = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case GDPRRequestStatus.underReview:
        badgeColor = Colors.blue;
        icon = Icons.search;
        break;
      case GDPRRequestStatus.inProgress:
        badgeColor = Colors.purple;
        icon = Icons.settings;
        break;
      case GDPRRequestStatus.completed:
        badgeColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case GDPRRequestStatus.rejected:
        badgeColor = Colors.red;
        icon = Icons.cancel;
        break;
      case GDPRRequestStatus.partiallyCompleted:
        badgeColor = Colors.amber;
        icon = Icons.pending_actions;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Text(
            status.dutchName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTypeChip(BuildContext context, DataSubjectRight requestType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        requestType.dutchName,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyRequestsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Geen verzoeken gevonden',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'U heeft nog geen privacy verzoeken ingediend',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewRequestCard(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Nieuw Privacy Verzoek',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRequestTypeSelector(context),
            const SizedBox(height: 20),
            _buildDataCategorySelector(context),
            const SizedBox(height: 20),
            _buildDescriptionField(context),
            const SizedBox(height: 20),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type Verzoek',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: DataSubjectRight.values.map((right) {
            final isSelected = _selectedRight == right;
            return FilterChip(
              selected: isSelected,
              label: Text(right.dutchName),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedRight = right;
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          _getRightDescription(_selectedRight),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCategorySelector(BuildContext context) {
    if (_selectedRight == DataSubjectRight.object || 
        _selectedRight == DataSubjectRight.restrictProcessing) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Categorieën',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableDataCategories.map((category) {
            final isSelected = _selectedDataCategories.contains(category);
            return FilterChip(
              selected: isSelected,
              label: Text(category),
              onSelected: (selected) {
                setState(() {
                  if (category == 'Alle gegevens') {
                    if (selected) {
                      _selectedDataCategories = ['Alle gegevens'];
                    } else {
                      _selectedDataCategories.clear();
                    }
                  } else {
                    if (selected) {
                      _selectedDataCategories.remove('Alle gegevens');
                      _selectedDataCategories.add(category);
                    } else {
                      _selectedDataCategories.remove(category);
                    }
                  }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beschrijving (optioneel)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Geef eventuele aanvullende informatie over uw verzoek...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Verzoek Indienen',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildRightsInformationCard(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Uw Rechten onder de AVG',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRightInfo(
              context,
              'Recht van Inzage (Art. 15)',
              'Bekijk alle persoonlijke gegevens die wij van u hebben',
              Icons.visibility,
            ),
            _buildRightInfo(
              context,
              'Recht op Rectificatie (Art. 16)',
              'Corrigeer onjuiste of onvolledige gegevens',
              Icons.edit,
            ),
            _buildRightInfo(
              context,
              'Recht op Vergetelheid (Art. 17)',
              'Verwijder uw gegevens (met bepaalde uitzonderingen)',
              Icons.delete,
            ),
            _buildRightInfo(
              context,
              'Recht op Portabiliteit (Art. 20)',
              'Download uw gegevens in een machine-leesbaar formaat',
              Icons.file_download,
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
                  Text(
                    'Nederlandse Wetgeving',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• WPBR certificaten: 7 jaar bewaarplicht\n'
                    '• BSN gegevens: Extra beveiligde verwerking\n'
                    '• CAO gegevens: 5 jaar bewaarplicht',
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
    );
  }

  Widget _buildRightInfo(BuildContext context, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                  title,
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

  Widget _buildErrorState(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Fout bij laden van verzoeken',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getRightDescription(DataSubjectRight right) {
    switch (right) {
      case DataSubjectRight.access:
        return 'Ontvang een volledig overzicht van alle persoonlijke gegevens die wij van u hebben.';
      case DataSubjectRight.rectification:
        return 'Verzoek om correctie van onjuiste of onvolledige persoonlijke gegevens.';
      case DataSubjectRight.erasure:
        return 'Verzoek om verwijdering van uw persoonlijke gegevens (met bepaalde wettelijke uitzonderingen).';
      case DataSubjectRight.restrictProcessing:
        return 'Beperk de verwerking van uw gegevens tot opslag alleen.';
      case DataSubjectRight.dataPortability:
        return 'Ontvang uw gegevens in een machine-leesbaar formaat voor overdracht naar een andere dienstverlener.';
      case DataSubjectRight.object:
        return 'Maak bezwaar tegen de verwerking van uw persoonlijke gegevens op basis van gerechtvaardigd belang.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }

  Future<void> _submitRequest() async {
    if (_selectedDataCategories.isEmpty && 
        (_selectedRight == DataSubjectRight.access || 
         _selectedRight == DataSubjectRight.dataPortability || 
         _selectedRight == DataSubjectRight.erasure)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecteer ten minste één data categorie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final description = _descriptionController.text.trim().isEmpty
          ? 'Verzoek ingediend via privacy dashboard'
          : _descriptionController.text.trim();

      await widget.gdprService.submitDataSubjectRequest(
        requestType: _selectedRight,
        description: description,
        dataCategories: _selectedDataCategories,
      );

      // Reset form
      _descriptionController.clear();
      _selectedDataCategories.clear();
      _selectedRight = DataSubjectRight.access;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Privacy verzoek succesvol ingediend. '
            'U ontvangt binnen 30 dagen een reactie.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij indienen verzoek: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
