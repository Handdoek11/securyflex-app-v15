import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../workflow/models/job_workflow_models.dart';
import 'premium_glass_system.dart';
import 'premium_typography_system.dart';

/// Payment status data model
class PaymentStatusData {
  final double pendingPayments;
  final double monthlyTotal;
  final List<RecentPayment> recentPayments;
  final List<JobCompletionStatus> pendingCompletions;

  PaymentStatusData({
    required this.pendingPayments,
    required this.monthlyTotal,
    required this.recentPayments,
    required this.pendingCompletions,
  });

  /// Empty data factory for fallback
  factory PaymentStatusData.empty() {
    return PaymentStatusData(
      pendingPayments: 0.0,
      monthlyTotal: 0.0,
      recentPayments: [],
      pendingCompletions: [],
    );
  }

  /// JSON serialization
  factory PaymentStatusData.fromJson(Map<String, dynamic> json) {
    return PaymentStatusData(
      pendingPayments: (json['pendingPayments'] as num).toDouble(),
      monthlyTotal: (json['monthlyTotal'] as num).toDouble(),
      recentPayments: (json['recentPayments'] as List<dynamic>)
          .map((paymentJson) => RecentPayment.fromJson(paymentJson as Map<String, dynamic>))
          .toList(),
      pendingCompletions: (json['pendingCompletions'] as List<dynamic>)
          .map((completionJson) => JobCompletionStatus.fromJson(completionJson as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingPayments': pendingPayments,
      'monthlyTotal': monthlyTotal,
      'recentPayments': recentPayments.map((payment) => payment.toJson()).toList(),
      'pendingCompletions': pendingCompletions.map((completion) => completion.toJson()).toList(),
    };
  }
}

/// Recent payment model
class RecentPayment {
  final String id;
  final String jobTitle;
  final double amount;
  final DateTime paidDate;
  final PaymentStatus status;

  RecentPayment({
    required this.id,
    required this.jobTitle,
    required this.amount,
    required this.paidDate,
    required this.status,
  });

  /// JSON serialization
  factory RecentPayment.fromJson(Map<String, dynamic> json) {
    return RecentPayment(
      id: json['id'] as String,
      jobTitle: json['jobTitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidDate: DateTime.fromMillisecondsSinceEpoch(json['paidDate'] as int),
      status: PaymentStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobTitle': jobTitle,
      'amount': amount,
      'paidDate': paidDate.millisecondsSinceEpoch,
      'status': status.name,
    };
  }
}

/// Job completion status model
class JobCompletionStatus {
  final String jobId;
  final String title;
  final JobWorkflowState state;
  final double estimatedPayout;
  final DateTime completedAt;

  JobCompletionStatus({
    required this.jobId,
    required this.title,
    required this.state,
    required this.estimatedPayout,
    required this.completedAt,
  });

  /// JSON serialization
  factory JobCompletionStatus.fromJson(Map<String, dynamic> json) {
    return JobCompletionStatus(
      jobId: json['jobId'] as String,
      title: json['title'] as String,
      state: JobWorkflowState.values.firstWhere((e) => e.name == json['state']),
      estimatedPayout: (json['estimatedPayout'] as num).toDouble(),
      completedAt: DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'title': title,
      'state': state.name,
      'estimatedPayout': estimatedPayout,
      'completedAt': completedAt.millisecondsSinceEpoch,
    };
  }
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
}

/// Modern payment status widget for the beveiliger dashboard
class ModernPaymentStatusWidget extends StatelessWidget {
  final AnimationController? animationController;
  final Animation<double>? animation;
  final PaymentStatusData? data;
  final VoidCallback? onViewAllPayments;

  const ModernPaymentStatusWidget({
    super.key,
    this.animationController,
    this.animation,
    this.data,
    this.onViewAllPayments,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    final paymentData = data ?? PaymentStatusData(
      pendingPayments: 0.0,
      monthlyTotal: 0.0,
      recentPayments: [],
      pendingCompletions: [],
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Text(
              'Betalingen & Uitkeringen',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // Premium glass payment overview card
          PremiumGlassContainer(
            intensity: GlassIntensity.standard,
            elevation: GlassElevation.floating,
            tintColor: DesignTokens.colorSuccess,
            borderRadius: BorderRadius.circular(DesignTokens.radiusL),
            padding: EdgeInsets.all(DesignTokens.spacingL),
            enableTrustBorder: true,
            child: Column(
              children: [
                // Payment summary
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentSummaryItem(
                        context,
                        'Uitstaande betalingen',
                        '€${paymentData.pendingPayments.toStringAsFixed(2)}',
                        Icons.pending_actions,
                        colorScheme.primary,
                        colorScheme,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    Expanded(
                      child: _buildPaymentSummaryItem(
                        context,
                        'Deze maand',
                        '€${paymentData.monthlyTotal.toStringAsFixed(2)}',
                        Icons.account_balance_wallet,
                        colorScheme.secondary,
                        colorScheme,
                      ),
                    ),
                  ],
                ),

                if (paymentData.pendingCompletions.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                  SizedBox(height: DesignTokens.spacingM),

                  // Pending completions
                  _buildPendingCompletions(paymentData.pendingCompletions, colorScheme),
                ],

                if (paymentData.recentPayments.isNotEmpty) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
                  SizedBox(height: DesignTokens.spacingS),

                  // Recent payments
                  _buildRecentPayments(paymentData.recentPayments, colorScheme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryItem(
    BuildContext context,
    String label,
    String amount,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        SizedBox(height: DesignTokens.spacingS),
        Text(
          amount,
          style: PremiumTypography.financialDisplay(
            context,
            color: color,
            isLarge: true,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: PremiumTypography.professionalCaption(
            context,
            role: UserRole.guard,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCompletions(
    List<JobCompletionStatus> completions,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Te voltooien opdrachten',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        ...completions.take(2).map((completion) => 
          _buildCompletionItem(completion, colorScheme)),
      ],
    );
  }

  Widget _buildCompletionItem(
    JobCompletionStatus completion,
    ColorScheme colorScheme,
  ) {
    final stateInfo = _getStateInfo(completion.state);
    
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      padding: EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: stateInfo['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: stateInfo['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            stateInfo['icon'],
            color: stateInfo['color'],
            size: 16,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completion.title,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightMedium,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  stateInfo['label'],
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '€${completion.estimatedPayout.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
              color: stateInfo['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPayments(
    List<RecentPayment> payments,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recente betalingen',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        ...payments.take(3).map((payment) => 
          _buildPaymentItem(payment, colorScheme)),
      ],
    );
  }

  Widget _buildPaymentItem(
    RecentPayment payment,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.jobTitle,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeBody,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(payment.paidDate),
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '€${payment.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStateInfo(JobWorkflowState state) {
    switch (state) {
      case JobWorkflowState.completed:
        return {
          'label': 'Wacht op beoordeling',
          'icon': Icons.rate_review,
          'color': DesignTokens.statusPending,
        };
      case JobWorkflowState.rated:
        return {
          'label': 'Betaling wordt verwerkt',
          'icon': Icons.payment,
          'color': DesignTokens.statusAccepted,
        };
      case JobWorkflowState.paid:
        return {
          'label': 'Betaald',
          'icon': Icons.check_circle,
          'color': DesignTokens.statusConfirmed,
        };
      default:
        return {
          'label': 'In behandeling',
          'icon': Icons.hourglass_empty,
          'color': Colors.grey,
        };
    }
  }
}