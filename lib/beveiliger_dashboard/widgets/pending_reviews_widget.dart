import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/unified_dashboard_card.dart';
import '../../reviews/services/review_management_service.dart';
import '../../reviews/screens/submit_review_screen.dart';
import '../../reviews/models/comprehensive_review_model.dart';
import '../../auth/auth_service.dart';

/// Widget to display pending reviews that need to be submitted
class PendingReviewsWidget extends StatefulWidget {
  final AnimationController? animationController;
  
  const PendingReviewsWidget({
    super.key,
    this.animationController,
  });

  @override
  State<PendingReviewsWidget> createState() => _PendingReviewsWidgetState();
}

class _PendingReviewsWidgetState extends State<PendingReviewsWidget>
    with SingleTickerProviderStateMixin {
  final ReviewManagementService _reviewService = ReviewManagementService();
  List<Map<String, dynamic>> _pendingReviews = [];
  bool _isLoading = true;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _loadPendingReviews();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingReviews() async {
    try {
      final userId = AuthService.currentUserId;
      final reviews = await _reviewService.getPendingReviewsForUser(userId);
      if (mounted) {
        setState(() {
          _pendingReviews = reviews;
          _isLoading = false;
        });
      }
        } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_pendingReviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: UnifiedDashboardCard(
            title: 'Reviews in afwachting',
            subtitle: '${_pendingReviews.length} ${_pendingReviews.length == 1 ? "opdracht" : "opdrachten"} wachten op je beoordeling',
            userRole: UserRole.guard,
            variant: DashboardCardVariant.featured,
            child: Column(
              children: [
                // Display up to 3 pending reviews
                ..._pendingReviews.take(3).map((review) => 
                  _buildPendingReviewItem(context, review, colorScheme)
                ),
                
                if (_pendingReviews.length > 3) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    'En ${_pendingReviews.length - 3} meer...',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingReviewItem(
    BuildContext context,
    Map<String, dynamic> review,
    ColorScheme colorScheme,
  ) {
    final daysRemaining = review['daysRemaining'] as int;
    final isUrgent = daysRemaining <= 3;
    
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: InkWell(
        onTap: () async {
          // Navigate to review submission screen
          final result = await context.push('/review/submit', extra: {
            'workflowId': review['workflowId'],
            'jobId': review['jobId'],
            'revieweeId': review['companyId'],
            'revieweeName': 'Bedrijf',
            'reviewerType': 'guard',
            'userRole': 'guard',
            'shiftDate': review['completedAt'],
          });
          // Original: Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => SubmitReviewScreen(
          //       workflowId: review['workflowId'],
          //       jobId: review['jobId'],
          //       revieweeId: review['companyId'],
          //       revieweeName: 'Bedrijf', // In production, fetch actual company name
          //       reviewerType: ReviewerType.guard,
          //       userRole: UserRole.guard,
          //       shiftDate: review['completedAt'],
          //     ),
          //   ),
          // );
          
          if (result == true && mounted) {
            // Reload pending reviews
            _loadPendingReviews();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Review succesvol ingediend!'),
                backgroundColor: DesignTokens.colorSuccess,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: isUrgent 
                ? DesignTokens.colorWarning.withValues(alpha: 0.1)
                : colorScheme.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: isUrgent
                  ? DesignTokens.colorWarning.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUrgent 
                      ? DesignTokens.colorWarning.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rate_review_outlined,
                  size: DesignTokens.iconSizeM,
                  color: isUrgent 
                      ? DesignTokens.colorWarning
                      : colorScheme.primary,
                ),
              ),
              
              SizedBox(width: DesignTokens.spacingM),
              
              // Review info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opdracht #${review['jobId'].substring(0, 8)}',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeBody,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      'Voltooid op ${_formatDate(review['completedAt'])}',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightRegular,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Days remaining badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? DesignTokens.colorWarning
                      : DesignTokens.colorSuccess,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Text(
                  '$daysRemaining ${daysRemaining == 1 ? "dag" : "dagen"}',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeCaption,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              
              SizedBox(width: DesignTokens.spacingS),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: DesignTokens.iconSizeS,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan', 'feb', 'mrt', 'apr', 'mei', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}