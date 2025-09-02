import 'package:flutter/material.dart';

import '../models/subscription_models.dart';
import '../services/subscription_service.dart';
import '../services/feature_access_service.dart';
import '../../unified_design_tokens.dart';

/// Widget that displays current subscription status and key metrics
/// Shows subscription info, usage limits, and upgrade options
class SubscriptionStatusWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onUpgradePressed;
  final bool showDetails;

  const SubscriptionStatusWidget({
    Key? key,
    required this.userId,
    this.onUpgradePressed,
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<SubscriptionStatusWidget> createState() => _SubscriptionStatusWidgetState();
}

class _SubscriptionStatusWidgetState extends State<SubscriptionStatusWidget> {
  Subscription? _subscription;
  Map<String, dynamic>? _featureAccessSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final subscription = await SubscriptionService.instance
          .getActiveSubscription(widget.userId);
      
      final featureAccessSummary = await FeatureAccessService.instance
          .getFeatureAccessSummary(widget.userId);

      setState(() {
        _subscription = subscription;
        _featureAccessSummary = featureAccessSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_subscription == null) {
      return _buildNoSubscriptionState();
    }

    return _buildSubscriptionStatus();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: _getCardDecoration(),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: DesignTokens.spacingM),
          Text(
            'Abonnement laden...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: _getCardDecoration(isError: true),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: DesignTokens.colorError,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fout bij laden abonnement',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.colorError,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _error ?? 'Onbekende fout',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loadSubscriptionData,
            child: const Text('Opnieuw'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: _getCardDecoration(isUpgrade: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.guardPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: DesignTokens.guardPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingM),
              const Expanded(
                child: Text(
                  'Geen actief abonnement',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeTitle,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Text(
            'Upgrade naar een betaald abonnement om alle functies te gebruiken.',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.mutedText,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onUpgradePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.guardPrimary,
                foregroundColor: DesignTokens.colorWhite,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Abonnement Kiezen',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatus() {
    final subscription = _subscription!;
    final isTrialing = subscription.status == SubscriptionStatus.trialing;
    final trialDays = subscription.trialDaysRemaining;
    
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: _getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with subscription info
          Row(
            children: [
              _buildStatusIcon(subscription.status),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.tier.displayName,
                      style: const TextStyle(
                        fontSize: DesignTokens.fontSizeTitle,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.guardTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(subscription),
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeS,
                        color: _getStatusColor(subscription.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isTrialing)
                Text(
                  '€${subscription.priceWithBTW.toStringAsFixed(2)}/maand',
                  style: const TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
            ],
          ),

          // Trial warning if applicable
          if (isTrialing && trialDays != null) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildTrialWarning(trialDays),
          ],

          // Usage summary if details requested
          if (widget.showDetails && _featureAccessSummary != null) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildUsageSummary(),
          ],

          // Action buttons
          if (subscription.status.requiresPayment || subscription.isTrialEndingSoon) ...[
            const SizedBox(height: DesignTokens.spacingM),
            _buildActionButtons(subscription),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SubscriptionStatus status) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case SubscriptionStatus.active:
        iconData = Icons.check_circle;
        iconColor = DesignTokens.colorSuccess;
        break;
      case SubscriptionStatus.trialing:
        iconData = Icons.schedule;
        iconColor = DesignTokens.colorWarning;
        break;
      case SubscriptionStatus.pastDue:
      case SubscriptionStatus.unpaid:
        iconData = Icons.warning;
        iconColor = DesignTokens.colorError;
        break;
      case SubscriptionStatus.canceled:
      case SubscriptionStatus.expired:
        iconData = Icons.cancel;
        iconColor = DesignTokens.mutedText;
        break;
      default:
        iconData = Icons.help_outline;
        iconColor = DesignTokens.mutedText;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getStatusText(Subscription subscription) {
    switch (subscription.status) {
      case SubscriptionStatus.active:
        return 'Actief • Volgende betaling: ${_formatDate(subscription.nextPaymentDate)}';
      case SubscriptionStatus.trialing:
        final days = subscription.trialDaysRemaining;
        return 'Proefperiode • ${days ?? 0} dagen resterend';
      case SubscriptionStatus.pastDue:
        return 'Betaling achterstallig • Actie vereist';
      case SubscriptionStatus.unpaid:
        return 'Onbetaald • Abonnement geblokkeerd';
      case SubscriptionStatus.canceled:
        return 'Geannuleerd • Eindigt op ${_formatDate(subscription.endDate)}';
      case SubscriptionStatus.expired:
        return 'Verlopen • Upgrade om door te gaan';
      default:
        return 'Status onbekend';
    }
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return DesignTokens.colorSuccess;
      case SubscriptionStatus.trialing:
        return DesignTokens.colorWarning;
      case SubscriptionStatus.pastDue:
      case SubscriptionStatus.unpaid:
        return DesignTokens.colorError;
      default:
        return DesignTokens.mutedText;
    }
  }

  Widget _buildTrialWarning(int daysRemaining) {
    if (daysRemaining > 7) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingS),
      decoration: BoxDecoration(
        color: DesignTokens.colorWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DesignTokens.colorWarning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: DesignTokens.colorWarning,
            size: 16,
          ),
          const SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              daysRemaining <= 1
                  ? 'Proefperiode eindigt vandaag!'
                  : 'Proefperiode eindigt over $daysRemaining dagen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.colorWarning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSummary() {
    final features = _featureAccessSummary!['features'] as Map<String, dynamic>?;
    if (features == null) return const SizedBox.shrink();

    // Show key usage metrics
    final keyFeatures = ['job_applications', 'job_posting', 'team_management'];
    final usageItems = keyFeatures
        .where((feature) => features.containsKey(feature))
        .map((feature) => features[feature] as Map<String, dynamic>)
        .where((data) => data['has_access'] == true)
        .take(3)
        .toList();

    if (usageItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gebruik deze maand',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            fontWeight: FontWeight.w600,
            color: DesignTokens.mutedText,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        ...usageItems.map((data) => _buildUsageItem(data)),
      ],
    );
  }

  Widget _buildUsageItem(Map<String, dynamic> data) {
    final currentUsage = data['current_usage'] as int? ?? 0;
    final limit = data['limit'] as int?;
    final remaining = data['remaining'] as int?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getFeatureDisplayName(data),
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.mutedText,
              ),
            ),
          ),
          Text(
            limit != null ? '$currentUsage/$limit' : '$currentUsage',
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeS,
              fontWeight: FontWeight.w500,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Subscription subscription) {
    if (subscription.status == SubscriptionStatus.pastDue ||
        subscription.status == SubscriptionStatus.unpaid) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _handleRetryPayment(),
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.colorError,
            foregroundColor: DesignTokens.colorWhite,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Betaling Herstellen'),
        ),
      );
    }

    if (subscription.isTrialEndingSoon) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onUpgradePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.guardPrimary,
            foregroundColor: DesignTokens.colorWhite,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Upgrade naar Betaald'),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  BoxDecoration _getCardDecoration({bool isError = false, bool isUpgrade = false}) {
    Color borderColor;
    if (isError) {
      borderColor = DesignTokens.colorError.withValues(alpha: 0.3);
    } else if (isUpgrade) {
      borderColor = DesignTokens.guardPrimary.withValues(alpha: 0.3);
    } else {
      borderColor = DesignTokens.colorGray300;
    }

    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: DesignTokens.colorBlack.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Onbekend';
    return '${date.day}-${date.month}-${date.year}';
  }

  String _getFeatureDisplayName(Map<String, dynamic> data) {
    // This would be more sophisticated in production
    return 'Feature gebruik';
  }

  void _handleRetryPayment() {
    // Show retry payment dialog or navigate to payment screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doorverwijzen naar betaling...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}