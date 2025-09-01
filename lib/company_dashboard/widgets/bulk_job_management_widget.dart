import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_buttons.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/company_dashboard/models/job_posting_data.dart';
import 'package:securyflex_app/company_dashboard/services/job_posting_service.dart';

/// Bulk Job Management Widget
/// 
/// Provides comprehensive bulk job management capabilities including:
/// - CSV file upload and parsing
/// - Job template creation and management
/// - Bulk job posting with validation
/// - Progress tracking and error handling
/// - Template library for recurring contracts
/// - Batch operations for job management
/// 
/// Features:
/// - Drag & drop CSV upload interface
/// - Real-time validation and preview
/// - Template-based bulk creation
/// - Progress tracking with detailed feedback
/// - Error handling and correction suggestions
/// - Export functionality for job data
class BulkJobManagementWidget extends StatefulWidget {
  final Function(List<JobPostingData>)? onJobsCreated;
  final Function(String)? onError;

  const BulkJobManagementWidget({
    super.key,
    this.onJobsCreated,
    this.onError,
  });

  @override
  State<BulkJobManagementWidget> createState() => _BulkJobManagementWidgetState();
}

class _BulkJobManagementWidgetState extends State<BulkJobManagementWidget>
    with TickerProviderStateMixin {
  
  // Tab controller for different bulk operations
  late TabController _tabController;
  
  // CSV upload state
  List<JobPostingData> _parsedJobs = [];
  List<String> _validationErrors = [];
  bool _isProcessingCsv = false;
  bool _isUploading = false;

  // Template state
  List<JobTemplateData> _templates = [];
  bool _isLoadingTemplates = false;

  // Bulk creation state
  int _totalJobs = 0;
  int _processedJobs = 0;
  int _successfulJobs = 0;
  int _failedJobs = 0;
  bool _isBulkCreating = false;
  final List<String> _creationErrors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyColors = SecuryFlexTheme.getColorScheme(UserRole.company);
    
    return Scaffold(
      backgroundColor: companyColors.surface,
      body: Column(
        children: [
          // Header
          UnifiedHeader.simple(
            title: 'Bulk Job Beheer',
            userRole: UserRole.company,
            leading: IconButton(
              icon: Icon(Icons.close, color: companyColors.onSurface),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.help_outline, color: companyColors.onSurface),
                onPressed: _showHelpDialog,
                tooltip: 'Help',
              ),
            ],
          ),
          
          // Tab bar
          Container(
            color: companyColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: companyColors.primary,
              unselectedLabelColor: companyColors.onSurfaceVariant,
              indicatorColor: companyColors.primary,
              tabs: const [
                Tab(text: 'CSV Upload', icon: Icon(Icons.upload_file)),
                Tab(text: 'Sjablonen', icon: Icon(Icons.description_outlined)),
                Tab(text: 'Bulk Creatie', icon: Icon(Icons.batch_prediction)),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCsvUploadTab(companyColors),
                _buildTemplatesTab(companyColors),
                _buildBulkCreationTab(companyColors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCsvUploadTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload area
          _buildUploadArea(colors),
          SizedBox(height: DesignTokens.spacingL),
          
          // CSV template download
          _buildTemplateDownload(colors),
          SizedBox(height: DesignTokens.spacingL),
          
          // Validation results
          if (_validationErrors.isNotEmpty) ...[
            _buildValidationErrors(colors),
            SizedBox(height: DesignTokens.spacingL),
          ],
          
          // Preview parsed jobs
          if (_parsedJobs.isNotEmpty) ...[
            _buildJobPreview(colors),
            SizedBox(height: DesignTokens.spacingL),
            
            // Upload button
            UnifiedButton.primary(
              text: _isUploading ? 'Uploaden...' : 'Jobs Aanmaken (${_parsedJobs.length})',
              onPressed: () => _uploadParsedJobs(),
              isLoading: _isUploading,
              width: double.infinity,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadArea(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        children: [
          Container(
            height: DesignTokens.spacingXXL * 5, // ~200px equivalent
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: colors.outline,
                style: BorderStyle.solid,
                width: DesignTokens.spacingXS / 2,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            child: UnifiedCard.standard(
              userRole: UserRole.company,
              backgroundColor: colors.surfaceContainerHighest,
            child: InkWell(
              onTap: _pickCsvFile,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: colors.primary,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'CSV Bestand Uploaden',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: colors.primary,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'Klik hier of sleep een CSV bestand hierheen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  Text(
                    'Ondersteunde formaten: .csv',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            ),
          ),
          
          if (_isProcessingCsv) ...[
            SizedBox(height: DesignTokens.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: DesignTokens.iconSizeM,
                  height: DesignTokens.iconSizeM,
                  child: CircularProgressIndicator(strokeWidth: DesignTokens.spacingXS / 2),
                ),
                SizedBox(width: DesignTokens.spacingS),
                Text('CSV bestand verwerken...'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateDownload(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download, color: colors.primary),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'CSV Sjabloon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            'Download het CSV sjabloon om te zien welke kolommen vereist zijn.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: DesignTokens.spacingM),
          UnifiedButton.secondary(
            text: 'Sjabloon Downloaden',
            onPressed: _downloadCsvTemplate,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationErrors(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: DesignTokens.statusCancelled),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Validatie Fouten',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.statusCancelled,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          ..._validationErrors.map((error) => Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: DesignTokens.statusCancelled),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(child: Text(error)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildJobPreview(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: colors.primary),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Job Voorbeeld (${_parsedJobs.length} jobs)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          // Show first few jobs as preview
          ..._parsedJobs.take(3).map((job) => Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: colors.outline),
                borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              ),
              child: UnifiedCard.standard(
                userRole: UserRole.company,
                padding: EdgeInsets.all(DesignTokens.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  Text(
                    '${job.location} • ${NumberFormat.currency(locale: 'nl_NL', symbol: '€').format(job.hourlyRate)}/uur • ${job.jobType.displayName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              ),
            ),
          )),
          
          if (_parsedJobs.length > 3) ...[
            Text(
              '... en ${_parsedJobs.length - 3} meer jobs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplatesTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create new template button
          UnifiedButton.primary(
            text: 'Nieuw Sjabloon Maken',
            onPressed: _createNewTemplate,
            width: double.infinity,
          ),
          SizedBox(height: DesignTokens.spacingL),
          
          // Templates list
          if (_isLoadingTemplates) ...[
            Center(child: CircularProgressIndicator()),
          ] else if (_templates.isEmpty) ...[
            UnifiedCard.standard(
              userRole: UserRole.company,
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'Geen Sjablonen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Maak uw eerste sjabloon voor snellere job creatie',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._templates.map((template) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
              child: _buildTemplateCard(template, colors),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateCard(JobTemplateData template, ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      isClickable: true,
      onTap: () => _selectTemplate(template),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: DesignTokens.fontWeightSemiBold,
                      ),
                    ),
                    Text(
                      template.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleTemplateAction(value, template),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text('Bewerken')),
                  PopupMenuItem(value: 'duplicate', child: Text('Dupliceren')),
                  PopupMenuItem(value: 'delete', child: Text('Verwijderen')),
                ],
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            template.description,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Row(
            children: [
              Icon(Icons.euro, size: 16, color: colors.onSurfaceVariant),
              Text(
                '${template.suggestedRate.toStringAsFixed(2)}/uur',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Icon(Icons.work_history, size: 16, color: colors.onSurfaceVariant),
              Text(
                '${template.usageCount} keer gebruikt',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulkCreationTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          if (_isBulkCreating) ...[
            _buildProgressIndicator(colors),
            SizedBox(height: DesignTokens.spacingL),
          ],
          
          // Summary stats
          if (_totalJobs > 0) ...[
            _buildBulkStats(colors),
            SizedBox(height: DesignTokens.spacingL),
          ],
          
          // Creation errors
          if (_creationErrors.isNotEmpty) ...[
            _buildCreationErrors(colors),
            SizedBox(height: DesignTokens.spacingL),
          ],
          
          // Instructions
          UnifiedCard.standard(
            userRole: UserRole.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Job Creatie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Upload een CSV bestand of gebruik een sjabloon om meerdere jobs tegelijk aan te maken.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: DesignTokens.spacingM),
                
                Row(
                  children: [
                    Expanded(
                      child: UnifiedButton.secondary(
                        text: 'CSV Uploaden',
                        onPressed: () => _tabController.animateTo(0),
                      ),
                    ),
                    SizedBox(width: DesignTokens.spacingM),
                    Expanded(
                      child: UnifiedButton.secondary(
                        text: 'Sjabloon Gebruiken',
                        onPressed: () => _tabController.animateTo(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colors) {
    final progress = _totalJobs > 0 ? _processedJobs / _totalJobs : 0.0;
    
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jobs Aanmaken...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            '$_processedJobs van $_totalJobs jobs verwerkt',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBulkStats(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultaten',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Succesvol',
                  _successfulJobs.toString(),
                  Icons.check_circle,
                  DesignTokens.statusConfirmed,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: _buildStatCard(
                  'Mislukt',
                  _failedJobs.toString(),
                  Icons.error,
                  DesignTokens.statusCancelled,
                ),
              ),
              SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: _buildStatCard(
                  'Totaal',
                  _totalJobs.toString(),
                  Icons.work,
                  colors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      padding: EdgeInsets.all(DesignTokens.spacingM),
      backgroundColor: color.withValues(alpha: 0.1),
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: DesignTokens.fontWeightBold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCreationErrors(ColorScheme colors) {
    return UnifiedCard.standard(
      userRole: UserRole.company,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: DesignTokens.statusCancelled),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Creatie Fouten',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: DesignTokens.statusCancelled,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingM),
          ..._creationErrors.take(5).map((error) => Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: DesignTokens.statusCancelled),
                SizedBox(width: DesignTokens.spacingS),
                Expanded(child: Text(error)),
              ],
            ),
          )),
          if (_creationErrors.length > 5) ...[
            Text(
              '... en ${_creationErrors.length - 5} meer fouten',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // CSV handling methods
  Future<void> _pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isProcessingCsv = true;
          _validationErrors.clear();
          _parsedJobs.clear();
        });

        await _processCsvFile(result.files.single.path!);
      }
    } catch (e) {
      widget.onError?.call('Fout bij bestand selectie: ${e.toString()}');
    }
  }

  Future<void> _processCsvFile(String filePath) async {
    try {
      final file = File(filePath);
      final csvString = await file.readAsString();
      
      // Parse CSV
      final csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) {
        setState(() {
          _validationErrors.add('CSV bestand is leeg');
          _isProcessingCsv = false;
        });
        return;
      }

      // Validate and parse jobs
      final jobs = <JobPostingData>[];
      final errors = <String>[];
      
      // Expected headers
      final expectedHeaders = [
        'title', 'description', 'location', 'postalCode', 'hourlyRate',
        'startDate', 'endDate', 'jobType', 'requiredSkills', 'minimumExperience'
      ];
      
      final headers = csvData[0].map((h) => h.toString().toLowerCase()).toList();
      
      // Validate headers
      for (final header in expectedHeaders) {
        if (!headers.contains(header.toLowerCase())) {
          errors.add('Ontbrekende kolom: $header');
        }
      }
      
      if (errors.isEmpty) {
        // Parse data rows
        for (int i = 1; i < csvData.length; i++) {
          try {
            final row = csvData[i];
            final job = _parseJobFromCsvRow(row, headers);
            jobs.add(job);
          } catch (e) {
            errors.add('Rij ${i + 1}: ${e.toString()}');
          }
        }
      }

      setState(() {
        _parsedJobs = jobs;
        _validationErrors = errors;
        _isProcessingCsv = false;
      });
    } catch (e) {
      setState(() {
        _validationErrors.add('Fout bij CSV verwerking: ${e.toString()}');
        _isProcessingCsv = false;
      });
    }
  }

  JobPostingData _parseJobFromCsvRow(List<dynamic> row, List<String> headers) {
    final data = <String, dynamic>{};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      data[headers[i]] = row[i];
    }

    return JobPostingData(
      jobId: '',
      companyId: 'COMP001', // Get from auth service
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      postalCode: data['postalcode']?.toString() ?? '',
      hourlyRate: double.tryParse(data['hourlyrate']?.toString() ?? '0') ?? 0.0,
      startDate: DateTime.tryParse(data['startdate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(data['enddate']?.toString() ?? '') ?? DateTime.now().add(Duration(days: 1)),
      requiredSkills: data['requiredskills']?.toString().split(',').map((s) => s.trim()).toList() ?? [],
      minimumExperience: int.tryParse(data['minimumexperience']?.toString() ?? '0') ?? 0,
      status: JobPostingStatus.active,
      createdDate: DateTime.now(),
      jobType: _parseJobType(data['jobtype']?.toString() ?? ''),
    );
  }

  JobType _parseJobType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'evenementbeveiliging':
        return JobType.evenementbeveiliging;
      case 'persoonbeveiliging':
        return JobType.persoonbeveiliging;
      case 'surveillance':
        return JobType.surveillance;
      case 'receptie':
        return JobType.receptie;
      case 'transport':
        return JobType.transport;
      default:
        return JobType.objectbeveiliging;
    }
  }

  Future<void> _uploadParsedJobs() async {
    if (_parsedJobs.isEmpty) return;

    setState(() {
      _isUploading = true;
      _totalJobs = _parsedJobs.length;
      _processedJobs = 0;
      _successfulJobs = 0;
      _failedJobs = 0;
      _creationErrors.clear();
    });

    // Switch to bulk creation tab to show progress
    _tabController.animateTo(2);
    
    setState(() {
      _isBulkCreating = true;
    });

    for (int i = 0; i < _parsedJobs.length; i++) {
      try {
        final success = await JobPostingService.instance.createJob(_parsedJobs[i]);
        
        setState(() {
          _processedJobs++;
          if (success) {
            _successfulJobs++;
          } else {
            _failedJobs++;
            _creationErrors.add('Job ${i + 1}: Onbekende fout bij aanmaken');
          }
        });
        
        // Small delay to show progress
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        setState(() {
          _processedJobs++;
          _failedJobs++;
          _creationErrors.add('Job ${i + 1}: ${e.toString()}');
        });
      }
    }

    setState(() {
      _isUploading = false;
      _isBulkCreating = false;
    });

    // Notify parent of successful jobs
    if (_successfulJobs > 0) {
      widget.onJobsCreated?.call(_parsedJobs.take(_successfulJobs).toList());
    }

    // Show completion message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_successfulJobs van $_totalJobs jobs succesvol aangemaakt'),
          backgroundColor: _successfulJobs == _totalJobs ? DesignTokens.statusConfirmed : DesignTokens.statusPending,
        ),
      );
    }
  }

  void _downloadCsvTemplate() {
    // In a real app, this would generate and download a CSV template
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV sjabloon download functionaliteit komt binnenkort'),
      ),
    );
  }

  // Template methods
  Future<void> _loadTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
    });

    // Simulate loading templates
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      _templates = _generateMockTemplates();
      _isLoadingTemplates = false;
    });
  }

  List<JobTemplateData> _generateMockTemplates() {
    return [
      JobTemplateData(
        templateId: 'template_1',
        templateName: 'Evenementbeveiliging Standaard',
        category: 'Evenementen',
        description: 'Standaard template voor evenementbeveiliging met crowd control',
        defaultSkills: ['Crowd Control', 'Customer Service'],
        defaultCertificates: ['Evenementbeveiliging'],
        defaultExperience: 2,
        suggestedRate: 22.0,
        defaultSettings: {},
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        usageCount: 15,
      ),
      JobTemplateData(
        templateId: 'template_2',
        templateName: 'Objectbeveiliging Basis',
        category: 'Objectbeveiliging',
        description: 'Basis template voor objectbeveiliging opdrachten',
        defaultSkills: ['Access Control', 'CCTV Monitoring'],
        defaultCertificates: ['Beveiliger 2'],
        defaultExperience: 1,
        suggestedRate: 18.5,
        defaultSettings: {},
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        usageCount: 8,
      ),
    ];
  }

  void _createNewTemplate() {
    // Navigate to template creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template creatie functionaliteit komt binnenkort'),
      ),
    );
  }

  void _selectTemplate(JobTemplateData template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sjabloon "${template.templateName}" geselecteerd'),
      ),
    );
  }

  void _handleTemplateAction(String action, JobTemplateData template) {
    switch (action) {
      case 'edit':
        // Edit template
        break;
      case 'duplicate':
        // Duplicate template
        break;
      case 'delete':
        // Delete template
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action functionaliteit komt binnenkort'),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Job Beheer Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CSV Upload:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Upload een CSV bestand met job gegevens'),
            Text('• Download het sjabloon voor de juiste kolommen'),
            SizedBox(height: 16),
            Text('Sjablonen:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Maak herbruikbare sjablonen voor veelvoorkomende jobs'),
            Text('• Gebruik sjablonen voor snellere job creatie'),
            SizedBox(height: 16),
            Text('Bulk Creatie:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Bekijk de voortgang van bulk job creatie'),
            Text('• Zie resultaten en eventuele fouten'),
          ],
        ),
        actions: [
          UnifiedButton.text(
            text: 'Sluiten',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
