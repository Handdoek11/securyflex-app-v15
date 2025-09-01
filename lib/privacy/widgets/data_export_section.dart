import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gdpr_compliance_service.dart';
import '../../unified_components/premium_glass_system.dart';

/// Data Export Section Widget
/// Implements Article 20 GDPR - Data Portability
/// Provides structured data export in multiple formats
class DataExportSection extends StatefulWidget {
  final GDPRComplianceService gdprService;
  
  const DataExportSection({
    super.key,
    required this.gdprService,
  });

  @override
  State<DataExportSection> createState() => _DataExportSectionState();
}

class _DataExportSectionState extends State<DataExportSection> {
  bool _isExporting = false;
  List<String> _selectedCategories = [];
  ExportFormat _selectedFormat = ExportFormat.json;
  Map<String, dynamic>? _lastExportData;
  DateTime? _lastExportDate;
  
  final List<DataCategoryInfo> _dataCategories = [
    DataCategoryInfo(
      id: 'profile',
      name: 'Profiel Gegevens',
      description: 'Persoonlijke informatie, contactgegevens, voorkeuren',
      icon: Icons.person,
      color: Colors.blue,
      estimatedSize: '2-5 KB',
      includesBSN: false,
    ),
    DataCategoryInfo(
      id: 'certificates',
      name: 'Certificaten (WPBR)',
      description: 'Beveiligingscertificaten, verloopdatums, verificatiestatus',
      icon: Icons.verified,
      color: Colors.green,
      estimatedSize: '5-15 KB',
      includesBSN: false,
    ),
    DataCategoryInfo(
      id: 'job_history',
      name: 'Werkgeschiedenis',
      description: 'Diensten, beoordelingen, werkgeversinformatie',
      icon: Icons.work_history,
      color: Colors.orange,
      estimatedSize: '10-50 KB',
      includesBSN: false,
    ),
    DataCategoryInfo(
      id: 'payments',
      name: 'Betalingsgegevens',
      description: 'Facturatie, BTW gegevens, bankgegevens (gemaskeerd)',
      icon: Icons.payment,
      color: Colors.purple,
      estimatedSize: '5-20 KB',
      includesBSN: true,
    ),
    DataCategoryInfo(
      id: 'messages',
      name: 'Berichten',
      description: 'Chat geschiedenis, notificaties (laatste 6 maanden)',
      icon: Icons.message,
      color: Colors.teal,
      estimatedSize: '20-100 KB',
      includesBSN: false,
    ),
    DataCategoryInfo(
      id: 'location_data',
      name: 'Locatiegegevens',
      description: 'GPS tijdregistratie, werklocaties (geëncrypteerd)',
      icon: Icons.location_on,
      color: Colors.red,
      estimatedSize: '50-200 KB',
      includesBSN: false,
    ),
    DataCategoryInfo(
      id: 'audit_logs',
      name: 'Audit Logs',
      description: 'Privacy verzoeken, toestemmingsgeschiedenis',
      icon: Icons.history,
      color: Colors.indigo,
      estimatedSize: '5-30 KB',
      includesBSN: false,
    ),
    DataCategoryInfo(
      id: 'bsn_data',
      name: 'BSN Verificatie',
      description: 'Burgerservicenummer verificatiegegevens (extra beveiliging)',
      icon: Icons.security,
      color: Colors.amber,
      estimatedSize: '1-3 KB',
      includesBSN: true,
      isSpecialCategory: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExportOverviewCard(context),
          const SizedBox(height: 20),
          _buildDataCategorySelection(context),
          const SizedBox(height: 20),
          _buildExportOptionsCard(context),
          const SizedBox(height: 20),
          _buildExportHistoryCard(context),
        ],
      ),
    );
  }

  Widget _buildExportOverviewCard(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Data Export (Art. 20 AVG)',
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
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recht op Data Portabiliteit',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'U heeft het recht om uw persoonlijke gegevens in een '
                    'gestructureerd, gangbaar en machine-leesbaar formaat '
                    'te ontvangen. Deze gegevens kunt u overdragen aan een '
                    'andere dienstverlener.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            if (_lastExportDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Laatste export: ${_formatDate(_lastExportDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_lastExportData != null)
                      TextButton(
                        onPressed: () => _showLastExportPreview(context),
                        child: const Text('Bekijk'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataCategorySelection(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Selecteer Data Categorieën',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories.clear();
                        });
                      },
                      child: const Text('Geen'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategories = _dataCategories
                              .map((cat) => cat.id)
                              .toList();
                        });
                      },
                      child: const Text('Alles'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _dataCategories.length,
              itemBuilder: (context, index) {
                final category = _dataCategories[index];
                final isSelected = _selectedCategories.contains(category.id);
                
                return GestureDetector(
                  onTap: () => _toggleCategorySelection(category.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? category.color
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Icon(
                                category.icon,
                                color: category.color,
                                size: 32,
                              ),
                              if (category.isSpecialCategory)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (isSelected)
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: category.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? category.color : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.estimatedSize,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          if (category.includesBSN)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'BSN',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_selectedCategories.any((id) => 
                _dataCategories.firstWhere((cat) => cat.id == id).includesBSN))
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waarschuwing: BSN gegevens worden extra beveiligd geëxporteerd '
                        'en vereisen aanvullende verificatie.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.amber[700],
                        ),
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

  Widget _buildExportOptionsCard(BuildContext context) {
    return PremiumGlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export Opties',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Bestandsformaat',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ExportFormat.values.map((format) {
                final isSelected = _selectedFormat == format;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFormatIcon(format),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(format.displayName),
                    ],
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFormat = format;
                      });
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              _getFormatDescription(_selectedFormat),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            _buildExportSummary(context),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCategories.isEmpty || _isExporting
                    ? null
                    : _performExport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isExporting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Gegevens Exporteren...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_download),
                          const SizedBox(width: 8),
                          Text(
                            'Export Starten (${_selectedCategories.length} categorieën)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSummary(BuildContext context) {
    if (_selectedCategories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Selecteer ten minste één data categorie om te exporteren',
          textAlign: TextAlign.center,
        ),
      );
    }

    final selectedCategories = _dataCategories
        .where((cat) => _selectedCategories.contains(cat.id))
        .toList();
    
    final hasBSNData = selectedCategories.any((cat) => cat.includesBSN);
    final estimatedTotalSize = _calculateEstimatedSize(selectedCategories);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Samenvatting',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.folder_open,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                '${_selectedCategories.length} data categorieën geselecteerd',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.file_present,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Formaat: ${_selectedFormat.displayName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Geschatte grootte: $estimatedTotalSize',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (hasBSNData) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'BSN gegevens opgenomen - extra beveiliging actief',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportHistoryCard(BuildContext context) {
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
                  'Export Geschiedenis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lastExportDate == null)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Geen exports uitgevoerd',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uw data exports zullen hier verschijnen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              _buildExportHistoryList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildExportHistoryList(BuildContext context) {
    // This would typically come from a service/database
    final mockExports = [
      if (_lastExportDate != null)
        ExportHistoryItem(
          id: '1',
          date: _lastExportDate!,
          format: _selectedFormat,
          categories: _selectedCategories,
          fileSize: _calculateEstimatedSize(
            _dataCategories.where((cat) => _selectedCategories.contains(cat.id)).toList(),
          ),
          status: ExportStatus.completed,
        ),
    ];

    return Column(
      children: mockExports.map((export) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(export.status),
                color: _getStatusColor(export.status),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${export.format.displayName} Export',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${export.categories.length} categorieën, ${export.fileSize}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      _formatDate(export.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (export.status == ExportStatus.completed)
                IconButton(
                  onPressed: () => _showExportPreview(context, export),
                  icon: const Icon(Icons.visibility),
                  tooltip: 'Bekijk export',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Helper methods
  
  void _toggleCategorySelection(String categoryId) {
    setState(() {
      if (_selectedCategories.contains(categoryId)) {
        _selectedCategories.remove(categoryId);
      } else {
        _selectedCategories.add(categoryId);
      }
    });
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object;
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.xml:
        return Icons.code;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'Machine-leesbaar formaat, ideaal voor ontwikkelaars en data-overdracht';
      case ExportFormat.csv:
        return 'Spreadsheet formaat, gemakkelijk te openen in Excel of Google Sheets';
      case ExportFormat.xml:
        return 'Gestructureerd formaat voor systeem integraties';
      case ExportFormat.pdf:
        return 'Menselijk leesbaar document, ideaal voor archivering';
    }
  }

  String _calculateEstimatedSize(List<DataCategoryInfo> categories) {
    // Simple size estimation based on category info
    var totalKB = 0;
    for (final category in categories) {
      final sizeStr = category.estimatedSize.split('-')[1].replaceAll(' KB', '');
      totalKB += int.tryParse(sizeStr) ?? 10;
    }
    
    if (totalKB < 1024) {
      return '$totalKB KB';
    } else {
      return '${(totalKB / 1024).toStringAsFixed(1)} MB';
    }
  }

  IconData _getStatusIcon(ExportStatus status) {
    switch (status) {
      case ExportStatus.pending:
        return Icons.hourglass_empty;
      case ExportStatus.processing:
        return Icons.refresh;
      case ExportStatus.completed:
        return Icons.check_circle;
      case ExportStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(ExportStatus status) {
    switch (status) {
      case ExportStatus.pending:
        return Colors.orange;
      case ExportStatus.processing:
        return Colors.blue;
      case ExportStatus.completed:
        return Colors.green;
      case ExportStatus.failed:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Get user data from GDPR service
      final userData = await widget.gdprService.exportUserData('current_user');
      
      // Filter data based on selected categories
      final filteredData = <String, dynamic>{};
      for (final categoryId in _selectedCategories) {
        if (userData.containsKey(categoryId)) {
          filteredData[categoryId] = userData[categoryId];
        }
      }
      
      // Add export metadata
      filteredData['export_metadata'] = {
        'export_date': DateTime.now().toIso8601String(),
        'format': _selectedFormat.value,
        'categories': _selectedCategories,
        'compliance': 'GDPR Article 20 - Data Portability',
        'app_version': '1.0.0',
        'privacy_notice_version': '2.0',
      };
      
      // Convert to requested format
      String exportContent;
      String fileName;
      
      switch (_selectedFormat) {
        case ExportFormat.json:
          exportContent = const JsonEncoder.withIndent('  ').convert(filteredData);
          fileName = 'securyflex_data_export_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case ExportFormat.csv:
          exportContent = _convertToCSV(filteredData);
          fileName = 'securyflex_data_export_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        case ExportFormat.xml:
          exportContent = _convertToXML(filteredData);
          fileName = 'securyflex_data_export_${DateTime.now().millisecondsSinceEpoch}.xml';
          break;
        case ExportFormat.pdf:
          exportContent = _convertToPDFContent(filteredData);
          fileName = 'securyflex_data_export_${DateTime.now().millisecondsSinceEpoch}.txt';
          break;
      }
      
      // Save to temporary file and share
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(exportContent);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'SecuryFlex Data Export - ${_selectedFormat.displayName}',
        subject: 'Mijn Persoonlijke Gegevens Export',
      );
      
      // Update state
      setState(() {
        _lastExportData = filteredData;
        _lastExportDate = DateTime.now();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data export succesvol aangemaakt en gedeeld'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij exporteren van data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln('Category,Field,Value');
    
    // Flatten data structure for CSV
    void addDataRecursively(String category, String key, dynamic value) {
      if (value is Map) {
        for (final entry in (value as Map<String, dynamic>).entries) {
          addDataRecursively(category, '$key.${entry.key}', entry.value);
        }
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          addDataRecursively(category, '$key[$i]', value[i]);
        }
      } else {
        // Escape CSV values
        final escapedValue = value.toString().replaceAll('"', '""');
        buffer.writeln('"$category","$key","$escapedValue"');
      }
    }
    
    for (final entry in data.entries) {
      if (entry.value is Map) {
        for (final subEntry in (entry.value as Map<String, dynamic>).entries) {
          addDataRecursively(entry.key, subEntry.key, subEntry.value);
        }
      } else {
        addDataRecursively(entry.key, 'value', entry.value);
      }
    }
    
    return buffer.toString();
  }

  String _convertToXML(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<securyflex_data_export>');
    
    void addXMLElement(String key, dynamic value, int indent) {
      final indentStr = '  ' * indent;
      
      if (value is Map) {
        buffer.writeln('$indentStr<$key>');
        for (final entry in (value as Map<String, dynamic>).entries) {
          addXMLElement(entry.key, entry.value, indent + 1);
        }
        buffer.writeln('$indentStr</$key>');
      } else if (value is List) {
        buffer.writeln('$indentStr<$key>');
        for (int i = 0; i < value.length; i++) {
          addXMLElement('item', value[i], indent + 1);
        }
        buffer.writeln('$indentStr</$key>');
      } else {
        final escapedValue = value.toString()
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;');
        buffer.writeln('$indentStr<$key>$escapedValue</$key>');
      }
    }
    
    for (final entry in data.entries) {
      addXMLElement(entry.key, entry.value, 1);
    }
    
    buffer.writeln('</securyflex_data_export>');
    return buffer.toString();
  }

  String _convertToPDFContent(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln('SECURYFLEX DATA EXPORT');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    buffer.writeln('Export Datum: ${DateTime.now()}');
    buffer.writeln('Gebruiker: [GEBRUIKER_ID]');
    buffer.writeln('Compliance: GDPR Artikel 20 - Data Portabiliteit');
    buffer.writeln('');
    buffer.writeln('INHOUD:');
    buffer.writeln('-' * 30);
    buffer.writeln('');
    
    void addContentRecursively(String key, dynamic value, int indent) {
      final indentStr = '  ' * indent;
      
      if (value is Map) {
        buffer.writeln('$indentStr$key:');
        for (final entry in (value as Map<String, dynamic>).entries) {
          addContentRecursively(entry.key, entry.value, indent + 1);
        }
      } else if (value is List) {
        buffer.writeln('$indentStr$key: [${value.length} items]');
        for (int i = 0; i < value.length; i++) {
          addContentRecursively('Item ${i + 1}', value[i], indent + 1);
        }
      } else {
        buffer.writeln('$indentStr$key: $value');
      }
    }
    
    for (final entry in data.entries) {
      addContentRecursively(entry.key, entry.value, 0);
      buffer.writeln('');
    }
    
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('Dit bestand bevat al uw persoonlijke gegevens');
    buffer.writeln('zoals opgeslagen door SecuryFlex conform de AVG/GDPR.');
    
    return buffer.toString();
  }

  void _showLastExportPreview(BuildContext context) {
    if (_lastExportData == null) return;
    
    _showExportPreview(context, ExportHistoryItem(
      id: 'last',
      date: _lastExportDate!,
      format: _selectedFormat,
      categories: _selectedCategories,
      fileSize: _calculateEstimatedSize(
        _dataCategories.where((cat) => _selectedCategories.contains(cat.id)).toList(),
      ),
      status: ExportStatus.completed,
    ));
  }

  void _showExportPreview(BuildContext context, ExportHistoryItem export) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Export Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _lastExportData != null 
                          ? const JsonEncoder.withIndent('  ').convert(_lastExportData)
                          : 'Export preview niet beschikbaar',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Sluiten'),
                  ),
                  ElevatedButton(
                    onPressed: _lastExportData != null 
                        ? () {
                            Clipboard.setData(
                              ClipboardData(
                                text: const JsonEncoder.withIndent('  ').convert(_lastExportData),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Export data gekopieerd naar klembord'),
                              ),
                            );
                          }
                        : null,
                    child: const Text('Kopieer naar Klembord'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Supporting models and enums

enum ExportFormat {
  json('json', 'JSON'),
  csv('csv', 'CSV'),
  xml('xml', 'XML'),
  pdf('pdf', 'PDF');
  
  const ExportFormat(this.value, this.displayName);
  
  final String value;
  final String displayName;
}

enum ExportStatus {
  pending,
  processing,
  completed,
  failed,
}

class DataCategoryInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String estimatedSize;
  final bool includesBSN;
  final bool isSpecialCategory;
  
  const DataCategoryInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.estimatedSize,
    required this.includesBSN,
    this.isSpecialCategory = false,
  });
}

class ExportHistoryItem {
  final String id;
  final DateTime date;
  final ExportFormat format;
  final List<String> categories;
  final String fileSize;
  final ExportStatus status;
  
  const ExportHistoryItem({
    required this.id,
    required this.date,
    required this.format,
    required this.categories,
    required this.fileSize,
    required this.status,
  });
}
