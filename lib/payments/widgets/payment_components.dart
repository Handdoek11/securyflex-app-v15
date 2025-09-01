import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/payment_models.dart';
import '../../unified_design_tokens.dart';

/// Dutch Payment Amount Input Widget
/// 
/// Features:
/// - Dutch currency formatting (€1.234,56)
/// - Input validation
/// - Role-based theming
/// - Accessibility compliance
class DutchPaymentAmountInput extends StatefulWidget {
  final String label;
  final double? initialAmount;
  final ValueChanged<double?> onChanged;
  final String? errorText;
  final double? minAmount;
  final double? maxAmount;
  final bool required;
  final bool enabled;
  final Color? primaryColor;

  const DutchPaymentAmountInput({
    super.key,
    required this.label,
    this.initialAmount,
    required this.onChanged,
    this.errorText,
    this.minAmount,
    this.maxAmount,
    this.required = false,
    this.enabled = true,
    this.primaryColor,
  });

  @override
  State<DutchPaymentAmountInput> createState() => _DutchPaymentAmountInputState();
}

class _DutchPaymentAmountInputState extends State<DutchPaymentAmountInput> {
  late TextEditingController _controller;
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'nl_NL',
    symbol: '€',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    
    if (widget.initialAmount != null) {
      _controller.text = _formatAmountForInput(widget.initialAmount!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatAmountForInput(double amount) {
    // Format for input field (without currency symbol)
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _parseAmountFromInput(String text) {
    try {
      // Handle Dutch decimal separator
      final normalized = text.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  String? _validateAmount(String? value) {
    if (widget.required && (value == null || value.trim().isEmpty)) {
      return 'Bedrag is verplicht';
    }

    if (value != null && value.trim().isNotEmpty) {
      final amount = _parseAmountFromInput(value);
      
      if (amount == null) {
        return 'Ongeldig bedrag formaat';
      }

      if (widget.minAmount != null && amount < widget.minAmount!) {
        return 'Minimum bedrag: ${_currencyFormatter.format(widget.minAmount!)}';
      }

      if (widget.maxAmount != null && amount > widget.maxAmount!) {
        return 'Maximum bedrag: ${_currencyFormatter.format(widget.maxAmount!)}';
      }
    }

    return widget.errorText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
            color: widget.primaryColor ?? DesignTokens.darkText,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingXS),
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*,?\d{0,2}$')),
          ],
          decoration: InputDecoration(
            hintText: '0,00',
            prefixText: '€ ',
            prefixStyle: TextStyle(
              color: widget.primaryColor ?? DesignTokens.mutedText,
              fontSize: DesignTokens.fontSizeM,
              fontFamily: DesignTokens.fontFamily,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: widget.primaryColor ?? DesignTokens.colorGray400,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(
                color: widget.primaryColor ?? DesignTokens.guardPrimary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: const BorderSide(color: DesignTokens.colorError),
            ),
            filled: true,
            fillColor: widget.enabled ? DesignTokens.colorGray50 : DesignTokens.colorGray200,
          ),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontFamily: DesignTokens.fontFamily,
            color: widget.enabled ? DesignTokens.darkText : DesignTokens.colorGray400,
          ),
          validator: _validateAmount,
          onChanged: (value) {
            final amount = _parseAmountFromInput(value);
            widget.onChanged(amount);
          },
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: DesignTokens.spacingXS),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.colorError,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ],
    );
  }
}

/// Dutch Bank Selection Widget for iDEAL
class DutchBankSelector extends StatefulWidget {
  final List<iDEALBank> banks;
  final iDEALBank? selectedBank;
  final ValueChanged<iDEALBank?> onBankSelected;
  final String? errorText;
  final bool enabled;
  final Color? primaryColor;

  const DutchBankSelector({
    super.key,
    required this.banks,
    this.selectedBank,
    required this.onBankSelected,
    this.errorText,
    this.enabled = true,
    this.primaryColor,
  });

  @override
  State<DutchBankSelector> createState() => _DutchBankSelectorState();
}

class _DutchBankSelectorState extends State<DutchBankSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecteer uw bank',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightMedium,
            color: widget.primaryColor ?? DesignTokens.darkText,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.errorText != null 
                  ? DesignTokens.colorError 
                  : (widget.primaryColor ?? DesignTokens.colorGray400),
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            color: widget.enabled ? DesignTokens.colorGray50 : DesignTokens.colorGray200,
          ),
          child: Column(
            children: widget.banks.map((bank) {
              final isSelected = widget.selectedBank?.bic == bank.bic;
              
              return InkWell(
                onTap: widget.enabled ? () => widget.onBankSelected(bank) : null,
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.spacingM),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? (widget.primaryColor ?? DesignTokens.guardPrimary).withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected 
                                ? (widget.primaryColor ?? DesignTokens.guardPrimary)
                                : DesignTokens.colorGray300,
                            width: 2,
                          ),
                          color: isSelected 
                              ? (widget.primaryColor ?? DesignTokens.guardPrimary)
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: DesignTokens.colorWhite,
                              )
                            : null,
                      ),
                      const SizedBox(width: DesignTokens.spacingM),
                      if (bank.logoUrl != null) ...[
                        Image.network(
                          bank.logoUrl!,
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) => 
                              _buildBankIcon(bank.name),
                        ),
                        const SizedBox(width: DesignTokens.spacingM),
                      ] else
                        _buildBankIcon(bank.name),
                      Expanded(
                        child: Text(
                          bank.name,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeM,
                            fontWeight: isSelected 
                                ? DesignTokens.fontWeightSemiBold 
                                : DesignTokens.fontWeightRegular,
                            color: widget.enabled 
                                ? DesignTokens.darkText 
                                : DesignTokens.colorGray400,
                            fontFamily: DesignTokens.fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: DesignTokens.spacingXS),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.colorError,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBankIcon(String bankName) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (widget.primaryColor ?? DesignTokens.guardPrimary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Center(
        child: Text(
          bankName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightBold,
            color: widget.primaryColor ?? DesignTokens.guardPrimary,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ),
    );
  }
}

/// Payment Status Badge Widget
class PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus status;
  final double? fontSize;

  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: fontSize ?? DesignTokens.fontSizeS,
            color: _getStatusColor(),
          ),
          const SizedBox(width: DesignTokens.spacingXS),
          Text(
            status.dutchLabel,
            style: TextStyle(
              fontSize: fontSize ?? DesignTokens.fontSizeS,
              fontWeight: DesignTokens.fontWeightMedium,
              color: _getStatusColor(),
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case PaymentStatus.completed:
        return DesignTokens.colorSuccess;
      case PaymentStatus.processing:
      case PaymentStatus.awaitingBank:
        return DesignTokens.colorWarning;
      case PaymentStatus.pending:
        return DesignTokens.colorInfo;
      case PaymentStatus.failed:
      case PaymentStatus.cancelled:
      case PaymentStatus.expired:
        return DesignTokens.colorError;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return DesignTokens.colorInfo;
      case PaymentStatus.unknown:
      default:
        return DesignTokens.mutedText;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.processing:
      case PaymentStatus.awaitingBank:
        return Icons.hourglass_empty;
      case PaymentStatus.pending:
        return Icons.schedule;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.cancelled:
        return Icons.cancel;
      case PaymentStatus.expired:
        return Icons.access_time;
      case PaymentStatus.refunded:
      case PaymentStatus.partiallyRefunded:
        return Icons.undo;
      case PaymentStatus.unknown:
      default:
        return Icons.help_outline;
    }
  }
}

/// Payment Summary Card Widget
class PaymentSummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final String description;
  final PaymentType paymentType;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final Color? primaryColor;

  const PaymentSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.description,
    required this.paymentType,
    required this.createdAt,
    this.onTap,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'nl_NL',
      symbol: '€',
      decimalDigits: 2,
    );

    return Card(
      elevation: DesignTokens.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeM,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: DesignTokens.darkText,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingS,
                      vertical: DesignTokens.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: (primaryColor ?? DesignTokens.guardPrimary).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                    ),
                    child: Text(
                      paymentType.dutchLabel,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeXS,
                        fontWeight: DesignTokens.fontWeightMedium,
                        color: primaryColor ?? DesignTokens.guardPrimary,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                description,
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.mutedText,
                  fontFamily: DesignTokens.fontFamily,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormatter.format(amount),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeL,
                      fontWeight: DesignTokens.fontWeightBold,
                      color: primaryColor ?? DesignTokens.guardPrimary,
                      fontFamily: DesignTokens.fontFamily,
                    ),
                  ),
                  Text(
                    DateFormat('dd-MM-yyyy HH:mm', 'nl_NL').format(createdAt),
                    style: const TextStyle(
                      fontSize: DesignTokens.fontSizeXS,
                      color: DesignTokens.mutedText,
                      fontFamily: DesignTokens.fontFamily,
                    ),
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

/// Payment Loading Widget with Dutch messaging
class PaymentLoadingWidget extends StatelessWidget {
  final String? message;
  final Color? primaryColor;

  const PaymentLoadingWidget({
    super.key,
    this.message,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                primaryColor ?? DesignTokens.guardPrimary,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            message ?? 'Betaling wordt verwerkt...',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              color: DesignTokens.mutedText,
              fontFamily: DesignTokens.fontFamily,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Payment Error Widget with retry functionality
class PaymentErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final Color? primaryColor;

  const PaymentErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onCancel,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DesignTokens.colorError,
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              'Betaling Mislukt',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightBold,
                color: DesignTokens.darkText,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              error,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.mutedText,
                      side: const BorderSide(color: DesignTokens.colorGray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    child: const Text(
                      'Annuleren',
                      style: TextStyle(fontFamily: DesignTokens.fontFamily),
                    ),
                  ),
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor ?? DesignTokens.guardPrimary,
                      foregroundColor: DesignTokens.colorWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    child: const Text(
                      'Opnieuw Proberen',
                      style: TextStyle(fontFamily: DesignTokens.fontFamily),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Payment Success Widget with confirmation
class PaymentSuccessWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? paymentId;
  final double? amount;
  final VoidCallback? onDone;
  final VoidCallback? onViewDetails;
  final Color? primaryColor;

  const PaymentSuccessWidget({
    super.key,
    required this.title,
    required this.message,
    this.paymentId,
    this.amount,
    this.onDone,
    this.onViewDetails,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'nl_NL',
      symbol: '€',
      decimalDigits: 2,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 48,
                color: DesignTokens.colorSuccess,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeL,
                fontWeight: DesignTokens.fontWeightBold,
                color: DesignTokens.darkText,
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.spacingS),
            Text(
              message,
              style: const TextStyle(
                fontSize: DesignTokens.fontSizeM,
                color: DesignTokens.mutedText,
                fontFamily: DesignTokens.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            if (amount != null) ...[
              const SizedBox(height: DesignTokens.spacingM),
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: (primaryColor ?? DesignTokens.guardPrimary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                ),
                child: Text(
                  currencyFormatter.format(amount!),
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeXL,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: primaryColor ?? DesignTokens.guardPrimary,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ),
            ],
            if (paymentId != null) ...[
              const SizedBox(height: DesignTokens.spacingS),
              Text(
                'Referentie: $paymentId',
                style: const TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.mutedText,
                  fontFamily: DesignTokens.fontFamily,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (onViewDetails != null)
                  OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor ?? DesignTokens.guardPrimary,
                      side: BorderSide(
                        color: primaryColor ?? DesignTokens.guardPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    child: const Text(
                      'Details Bekijken',
                      style: TextStyle(fontFamily: DesignTokens.fontFamily),
                    ),
                  ),
                if (onDone != null)
                  ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor ?? DesignTokens.guardPrimary,
                      foregroundColor: DesignTokens.colorWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
                      ),
                    ),
                    child: const Text(
                      'Gereed',
                      style: TextStyle(fontFamily: DesignTokens.fontFamily),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}