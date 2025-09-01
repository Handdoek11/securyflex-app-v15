import 'package:flutter/material.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../services/application_review_service.dart';

/// MVP Bulk Selection Demo Widget
/// 
/// Demonstrates the Lowlands Festival workflow with individual 1-on-1 chats
/// Perfect for MVP launch - shows how companies can efficiently manage
/// multiple guard selections while creating individual communication channels
class MVPBulkSelectionDemo extends StatefulWidget {
  final String jobTitle;
  final String jobLocation;
  final DateTime jobStartDate;
  final String companyId;
  final String companyName;

  const MVPBulkSelectionDemo({
    super.key,
    required this.jobTitle,
    required this.jobLocation,
    required this.jobStartDate,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<MVPBulkSelectionDemo> createState() => _MVPBulkSelectionDemoState();
}

class _MVPBulkSelectionDemoState extends State<MVPBulkSelectionDemo> {
  final Set<String> _selectedApplicationIds = {};
  final Set<String> _rejectedApplicationIds = {};
  bool _isProcessing = false;
  BulkApplicationResult? _lastResult;

  // Mock applications for demo
  final List<MockGuardApplication> _mockApplications = [
    MockGuardApplication(
      id: 'APP_001',
      guardName: 'Mark van der Berg',
      guardRating: 4.8,
      experience: '7 jaar ervaring',
      distance: '2.3 km',
      specialty: 'Evenementbeveiliging',
      price: '€18/uur',
      availability: 'Volledig weekend',
      highlight: 'Beste reviews + dichtbij',
    ),
    MockGuardApplication(
      id: 'APP_002',
      guardName: 'Lisa Janssen',
      guardRating: 4.9,
      experience: '10 jaar ervaring',
      distance: '5.1 km',
      specialty: 'Senior Beveiliger',
      price: '€22/uur',
      availability: 'Volledig weekend',
      highlight: 'Lange ervaring + perfect profiel',
    ),
    MockGuardApplication(
      id: 'APP_003',
      guardName: 'Ahmed Hassan',
      guardRating: 4.7,
      experience: '5 jaar ervaring',
      distance: '3.8 km',
      specialty: 'Crowd Control',
      price: '€19/uur',
      availability: 'Volledig weekend',
      highlight: 'Hoge rating + goede beschikbaarheid',
    ),
    MockGuardApplication(
      id: 'APP_004',
      guardName: 'Sandra de Vries',
      guardRating: 4.6,
      experience: '8 jaar ervaring',
      distance: '4.2 km',
      specialty: 'Security Coordinator',
      price: '€20/uur',
      availability: 'Flexibel',
      highlight: 'Senior ervaring + flexibel',
    ),
    MockGuardApplication(
      id: 'APP_005',
      guardName: 'Kevin Mulder',
      guardRating: 4.5,
      experience: '6 jaar ervaring',
      distance: '2.9 km',
      specialty: 'Objectbeveiliging',
      price: '€17/uur',
      availability: 'Volledig weekend',
      highlight: 'Stabiele reviews + teamplayer',
    ),
    MockGuardApplication(
      id: 'APP_006',
      guardName: 'Emma Peters',
      guardRating: 4.4,
      experience: '4 jaar ervaring',
      distance: '6.1 km',
      specialty: 'Access Control',
      price: '€16/uur',
      availability: 'Volledig weekend',
      highlight: 'Goede balans rating/afstand',
    ),
    // Rejected candidates
    MockGuardApplication(
      id: 'APP_007',
      guardName: 'Maria Rodriguez',
      guardRating: 4.2,
      experience: '3 jaar ervaring',
      distance: '45.3 km',
      specialty: 'Basis Beveiliging',
      price: '€15/uur',
      availability: 'Volledig weekend',
      highlight: 'Te ver + duur reiskostenvergoeding',
      shouldReject: true,
    ),
    MockGuardApplication(
      id: 'APP_008',
      guardName: 'David Thompson',
      guardRating: 3.8,
      experience: '1 jaar ervaring',
      distance: '8.2 km',
      specialty: 'Junior Beveiliger',
      price: '€14/uur',
      availability: 'Volledig weekend',
      highlight: 'Te weinig ervaring voor groot evenement',
      shouldReject: true,
    ),
    MockGuardApplication(
      id: 'APP_009',
      guardName: 'Sarah van Dijk',
      guardRating: 4.3,
      experience: '5 jaar ervaring',
      distance: '3.1 km',
      specialty: 'Crowd Control',
      price: '€18/uur',
      availability: 'Alleen zaterdag',
      highlight: 'Niet beschikbaar zondag',
      shouldReject: true,
    ),
    MockGuardApplication(
      id: 'APP_010',
      guardName: 'Mike Johnson',
      guardRating: 3.2,
      experience: '4 jaar ervaring',
      distance: '4.8 km',
      specialty: 'Objectbeveiliging',
      price: '€16/uur',
      availability: 'Volledig weekend',
      highlight: 'Recent negatieve review',
      shouldReject: true,
    ),
    MockGuardApplication(
      id: 'APP_011',
      guardName: 'Lucas Bakker',
      guardRating: 4.0,
      experience: '2 jaar ervaring',
      distance: '7.3 km',
      specialty: 'Basis Beveiliging',
      price: '€15/uur',
      availability: 'Volledig weekend',
      highlight: 'Beperkte evenement ervaring',
      shouldReject: true,
    ),
    MockGuardApplication(
      id: 'APP_012',
      guardName: 'Tom de Jong',
      guardRating: 3.9,
      experience: '3 jaar ervaring',
      distance: '9.1 km',
      specialty: 'Junior Beveiliger',
      price: '€14/uur',
      availability: 'Volledig weekend',
      highlight: 'Laagste overall score',
      shouldReject: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildJobSummary(colorScheme),
          SizedBox(height: DesignTokens.spacingL),
          _buildApplicationsList(),
          SizedBox(height: DesignTokens.spacingL),
          _buildActionButtons(colorScheme),
          if (_lastResult != null) ...[
            SizedBox(height: DesignTokens.spacingL),
            _buildResultSummary(colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.companyPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
          ),
          child: Icon(
            Icons.people_outline,
            color: DesignTokens.companyPrimary,
            size: DesignTokens.iconSizeL,
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MVP Bulk Selectie Demo',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeHeading,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                'Lowlands Festival workflow met individuele 1-op-1 chats',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobSummary(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.jobTitle,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXL,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  '📍 ${widget.jobLocation}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '📅 ${_formatDate(widget.jobStartDate)}',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.colorInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            ),
            child: Text(
              '${_mockApplications.length} sollicitaties',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.colorInfo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Kandidaat Selectie',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeXL,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
            Spacer(),
            _buildQuickSelectButtons(),
          ],
        ),
        SizedBox(height: DesignTokens.spacingM),
        ..._mockApplications.map((application) {
          final isSelected = _selectedApplicationIds.contains(application.id);
          final isRejected = _rejectedApplicationIds.contains(application.id);

          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingS),
            child: _buildApplicationCard(application, isSelected, isRejected),
          );
        }),
      ],
    );
  }

  Widget _buildQuickSelectButtons() {
    return Row(
      children: [
        _buildQuickButton(
          'Top 6 selecteren',
          Icons.thumb_up,
          DesignTokens.colorSuccess,
          () => _quickSelectTop6(),
        ),
        SizedBox(width: DesignTokens.spacingS),
        _buildQuickButton(
          'Bottom 6 afwijzen',
          Icons.thumb_down,
          DesignTokens.colorError,
          () => _quickRejectBottom6(),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: DesignTokens.iconSizeS, color: color),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                text,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(MockGuardApplication application, bool isSelected, bool isRejected) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.company);

    Color cardColor = colorScheme.surface;
    Color borderColor = colorScheme.outline.withValues(alpha: 0.2);

    if (isSelected) {
      cardColor = DesignTokens.colorSuccess.withValues(alpha: 0.05);
      borderColor = DesignTokens.colorSuccess;
    } else if (isRejected) {
      cardColor = DesignTokens.colorError.withValues(alpha: 0.05);
      borderColor = DesignTokens.colorError;
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      child: InkWell(
        onTap: () => _toggleSelection(application.id),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? DesignTokens.colorSuccess :
                         isRejected ? DesignTokens.colorError :
                         Colors.transparent,
                  border: Border.all(
                    color: isSelected ? DesignTokens.colorSuccess :
                           isRejected ? DesignTokens.colorError :
                           colorScheme.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : isRejected
                    ? Icon(Icons.close, size: 16, color: Colors.white)
                    : null,
              ),
              SizedBox(width: DesignTokens.spacingM),
              
              // Guard info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          application.guardName,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: DesignTokens.spacingS),
                        _buildRatingChip(application.guardRating),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Row(
                      children: [
                        Text(
                          application.experience,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeS,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: DesignTokens.spacingM),
                        Text(
                          '📍 ${application.distance}',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeS,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(width: DesignTokens.spacingM),
                        Text(
                          application.price,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeS,
                            fontWeight: DesignTokens.fontWeightMedium,
                            color: DesignTokens.companyPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      '💡 ${application.highlight}',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        fontStyle: FontStyle.italic,
                        color: application.shouldReject 
                          ? DesignTokens.colorError
                          : DesignTokens.colorSuccess,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Specialization tag
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.companyPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  application.specialty,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXS,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: DesignTokens.companyPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip(double rating) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 12,
            color: DesignTokens.colorSuccess,
          ),
          SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeXS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.colorSuccess,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Accepteer ${_selectedApplicationIds.length} Beveiligers',
            Icons.people,
            DesignTokens.colorSuccess,
            _selectedApplicationIds.isNotEmpty && !_isProcessing,
            () => _processBulkAccept(),
          ),
        ),
        SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: _buildActionButton(
            'Wijs ${_rejectedApplicationIds.length} Af',
            Icons.cancel,
            DesignTokens.colorError,
            _rejectedApplicationIds.isNotEmpty && !_isProcessing,
            () => _processBulkReject(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onPressed,
  ) {
    return Material(
      color: enabled ? color : Colors.grey.shade300,
      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  icon,
                  color: Colors.white,
                  size: DesignTokens.iconSizeM,
                ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                _isProcessing ? 'Verwerken...' : text,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(ColorScheme colorScheme) {
    if (_lastResult == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: _lastResult!.success 
          ? DesignTokens.colorSuccess.withValues(alpha: 0.1)
          : DesignTokens.colorWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        border: Border.all(
          color: _lastResult!.success 
            ? DesignTokens.colorSuccess
            : DesignTokens.colorWarning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _lastResult!.success ? Icons.check_circle : Icons.info,
                color: _lastResult!.success 
                  ? DesignTokens.colorSuccess
                  : DesignTokens.colorWarning,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Resultaat',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            _lastResult!.displayMessage,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          if (_lastResult!.createdConversationIds.isNotEmpty) ...[
            SizedBox(height: DesignTokens.spacingS),
            Text(
              '💬 ${_lastResult!.createdConversationIds.length} individuele 1-op-1 chats aangemaakt!',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.colorInfo,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              '🚀 MVP Ready: Elke geselecteerde beveiliger heeft nu een privé chat met ${widget.companyName}',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                fontStyle: FontStyle.italic,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleSelection(String applicationId) {
    setState(() {
      if (_selectedApplicationIds.contains(applicationId)) {
        _selectedApplicationIds.remove(applicationId);
      } else if (_rejectedApplicationIds.contains(applicationId)) {
        _rejectedApplicationIds.remove(applicationId);
        _selectedApplicationIds.add(applicationId);
      } else {
        _selectedApplicationIds.add(applicationId);
      }
    });
  }

  void _quickSelectTop6() {
    setState(() {
      _selectedApplicationIds.clear();
      _rejectedApplicationIds.clear();
      
      // Select top 6 (highest rated, closest)
      final topCandidates = _mockApplications
          .where((app) => !app.shouldReject)
          .take(6)
          .map((app) => app.id);
      
      _selectedApplicationIds.addAll(topCandidates);
    });
  }

  void _quickRejectBottom6() {
    setState(() {
      _rejectedApplicationIds.clear();
      
      // Reject bottom 6 (marked as should reject)
      final bottomCandidates = _mockApplications
          .where((app) => app.shouldReject)
          .map((app) => app.id);
      
      _rejectedApplicationIds.addAll(bottomCandidates);
    });
  }

  Future<void> _processBulkAccept() async {
    if (_selectedApplicationIds.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock successful result
    final result = BulkApplicationResult(
      success: true,
      totalProcessed: _selectedApplicationIds.length,
      successCount: _selectedApplicationIds.length,
      failureCount: 0,
      successfulApplicationIds: _selectedApplicationIds.toList(),
      createdConversationIds: _selectedApplicationIds
          .map((id) => 'chat_${id}_${DateTime.now().millisecondsSinceEpoch}')
          .toList(),
      message: '🎉 Alle ${_selectedApplicationIds.length} beveiligers geaccepteerd! Individuele chats aangemaakt.',
    );

    setState(() {
      _isProcessing = false;
      _lastResult = result;
    });
  }

  Future<void> _processBulkReject() async {
    if (_rejectedApplicationIds.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock successful result
    final result = BulkApplicationResult(
      success: true,
      totalProcessed: _rejectedApplicationIds.length,
      successCount: _rejectedApplicationIds.length,
      failureCount: 0,
      successfulApplicationIds: _rejectedApplicationIds.toList(),
      message: 'Alle ${_rejectedApplicationIds.length} kandidaten vriendelijk afgewezen.',
    );

    setState(() {
      _isProcessing = false;
      _lastResult = result;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}-${date.month}-${date.year}';
  }
}

/// Mock guard application data for demo
class MockGuardApplication {
  final String id;
  final String guardName;
  final double guardRating;
  final String experience;
  final String distance;
  final String specialty;
  final String price;
  final String availability;
  final String highlight;
  final bool shouldReject;

  const MockGuardApplication({
    required this.id,
    required this.guardName,
    required this.guardRating,
    required this.experience,
    required this.distance,
    required this.specialty,
    required this.price,
    required this.availability,
    required this.highlight,
    this.shouldReject = false,
  });
}