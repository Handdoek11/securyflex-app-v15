import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../unified_design_tokens.dart';
import '../unified_theme_system.dart';
import '../workflow/models/job_workflow_models.dart';

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
            padding: EdgeInsets.only(
              left: DesignTokens.spacingS,
              bottom: DesignTokens.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Betalingen & Uitkeringen',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeXL,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (onViewAllPayments != null)
                  TextButton(
                    onPressed: onViewAllPayments,
                    child: Text(
                      'Alles bekijken',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.fontSizeCaption,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Payment overview card
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Payment summary
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentSummaryItem(
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
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeXL,
            fontWeight: DesignTokens.fontWeightBold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
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