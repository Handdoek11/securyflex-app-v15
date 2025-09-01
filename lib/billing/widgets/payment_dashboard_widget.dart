import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/unified_dashboard_card.dart';
import '../../unified_buttons.dart';
import '../../unified_input_system.dart';
import '../../beveiliger_dashboard/models/enhanced_dashboard_data.dart';
import '../bloc/payment_bloc.dart';
import '../models/payment_models.dart';

/// Payment dashboard widget integrating with existing earnings system
/// Uses existing UnifiedComponents and DesignTokens
class PaymentDashboardWidget extends StatefulWidget {
  final String guardId;
  final EnhancedEarningsData? currentEarnings;
  final bool showPaymentActions;
  
  const PaymentDashboardWidget({
    super.key,
    required this.guardId,
    this.currentEarnings,
    this.showPaymentActions = true,
  });

  @override
  State<PaymentDashboardWidget> createState() => _PaymentDashboardWidgetState();
}

class _PaymentDashboardWidgetState extends State<PaymentDashboardWidget> {
  final TextEditingController _ibanController = TextEditingController();
  bool _includeVakantiegeld = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        return Column(
          children: [
            // Payment Overview Card
            _buildPaymentOverviewCard(context, colorScheme, state),
            
            const SizedBox(height: DesignTokens.spacingL),
            
            // Payment Actions
            if (widget.showPaymentActions) ...[
              _buildPaymentActionsCard(context, colorScheme, state),
              const SizedBox(height: DesignTokens.spacingL),
            ],
            
            // Payment History
            _buildPaymentHistoryCard(context, colorScheme, state),
            
            // Payment Status/Processing
            if (state is PaymentProcessing || state is PaymentLoading) ...[
              const SizedBox(height: DesignTokens.spacingL),
              _buildPaymentStatusCard(context, colorScheme, state),
            ],
          ],
        );
      },
    );
  }

  /// Payment overview card showing current earnings and payment readiness
  Widget _buildPaymentOverviewCard(
    BuildContext context, 
    ColorScheme colorScheme, 
    PaymentState state,
  ) {
    final earnings = widget.currentEarnings;
    
    return UnifiedDashboardCard(
      title: 'Betalingen Overzicht',
      subtitle: earnings != null ? 
        'Beschikbaar voor uitbetaling: ${earnings.dutchFormattedWeek}' : 
        'Geen verdiensten data beschikbaar',
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (earnings != null) ...[
            _buildEarningsSummary(earnings, colorScheme),
            const SizedBox(height: DesignTokens.spacingL),
            _buildPaymentCalculation(state, colorScheme),
          ] else ...[
            _buildNoEarningsMessage(colorScheme),
          ],
        ],
      ),
    );
  }

  /// Build earnings summary for payment
  Widget _buildEarningsSummary(EnhancedEarningsData earnings, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.colorSuccess.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(
          color: DesignTokens.colorSuccess.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildEarningsRow(
            'Basis Salaris',
            earnings.dutchFormattedWeek,
            '${earnings.hoursWorkedWeek.toStringAsFixed(1)} uur',
            colorScheme,
          ),
          if (earnings.overtimeHours > 0) ...[
            const SizedBox(height: DesignTokens.spacingS),
            _buildEarningsRow(
              'Overwerk',
              _formatDutchCurrency(earnings.overtimeHours * earnings.overtimeRate),
              '${earnings.overtimeHours.toStringAsFixed(1)} uur',
              colorScheme,
              isHighlight: true,
            ),
          ],
          const SizedBox(height: DesignTokens.spacingS),
          _buildEarningsRow(
            'Vakantiegeld (8%)',
            _formatDutchCurrency(earnings.vakantiegeld),
            'Wettelijk verplicht',
            colorScheme,
            isSuccess: true,
          ),
          if (earnings.isFreelance) ...[
            const SizedBox(height: DesignTokens.spacingS),
            _buildEarningsRow(
              'BTW (21%)',
              _formatDutchCurrency(earnings.btwAmount),
              'Voor ZZP\'ers',
              colorScheme,
              isWarning: true,
            ),
          ],
        ],
      ),
    );
  }

  /// Build payment calculation display
  Widget _buildPaymentCalculation(PaymentState state, ColorScheme colorScheme) {
    if (state is PaymentCalculationCompleted) {
      final calc = state.calculation;
      
      return Container(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uitbetaling Berekening',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingM),
            
            _buildCalculationRow('Bruto Bedrag', calc.grossAmount, colorScheme),
            _buildCalculationRow('Vakantiegeld', calc.vakantiegeld, colorScheme),
            _buildCalculationRow('BTW Aftrek', -calc.btwAmount, colorScheme, isNegative: true),
            _buildCalculationRow('Pensioenaftrek', -calc.pensionDeduction, colorScheme, isNegative: true),
            
            const Divider(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Netto Uitbetaling',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontSize: DesignTokens.fontSizeBodyLarge,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  calc.dutchFormattedNet,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightBold,
                    fontSize: DesignTokens.fontSizeBodyLarge,
                    color: DesignTokens.colorSuccess,
                  ),
                ),
              ],
            ),
            
            if (!calc.isCAOCompliant) ...[
              const SizedBox(height: DesignTokens.spacingM),
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingM),
                decoration: BoxDecoration(
                  color: DesignTokens.colorWarning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: DesignTokens.colorWarning,
                      size: DesignTokens.iconSizeS,
                    ),
                    const SizedBox(width: DesignTokens.spacingS),
                    Expanded(
                      child: Text(
                        'Waarschuwing: Niet volledig CAO conform',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.colorWarning,
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
    
    return const SizedBox.shrink();
  }

  /// Payment actions card with SEPA and iDEAL options
  Widget _buildPaymentActionsCard(
    BuildContext context, 
    ColorScheme colorScheme, 
    PaymentState state,
  ) {
    final isProcessing = state is PaymentLoading || state is PaymentProcessing;
    final canProcess = widget.currentEarnings != null && 
                      widget.currentEarnings!.totalWeek >= 50.0 && 
                      !isProcessing;
    
    return UnifiedDashboardCard(
      title: 'Betaal Acties',
      subtitle: 'SEPA uitbetalingen en onkosten vergoedingen',
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      child: Column(
        children: [
          // SEPA Payment Section
          _buildSEPAPaymentSection(context, colorScheme, canProcess),
          
          const SizedBox(height: DesignTokens.spacingL),
          
          // iDEAL Expense Section
          _buildExpenseSection(context, colorScheme, !isProcessing),
          
          if (state is PaymentError) ...[
            const SizedBox(height: DesignTokens.spacingL),
            _buildErrorMessage(state, colorScheme),
          ],
        ],
      ),
    );
  }

  /// SEPA payment section
  Widget _buildSEPAPaymentSection(
    BuildContext context, 
    ColorScheme colorScheme, 
    bool canProcess,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance,
              color: DesignTokens.colorSuccess,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'SEPA Salaris Uitbetaling',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: DesignTokens.spacingM),
        
        UnifiedInput(
          controller: _ibanController,
          label: 'IBAN Rekeningnummer',
          hint: 'NL91 ABNA 0417 1643 00',
          prefixIcon: Icons.account_balance_wallet,
          validator: _validateIBAN,
          isEnabled: canProcess,
        ),
        
        const SizedBox(height: DesignTokens.spacingM),
        
        CheckboxListTile(
          title: Text(
            'Vakantiegeld (8%) toevoegen',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
          subtitle: Text(
            'Wettelijk verplicht vakantiegeld',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          value: _includeVakantiegeld,
          onChanged: canProcess ? (value) {
            setState(() {
              _includeVakantiegeld = value ?? true;
            });
            // Recalculate payment
            context.read<PaymentBloc>().add(CalculatePaymentAmount(
              guardId: widget.guardId,
              type: PaymentType.salaryPayment,
              includeVakantiegeld: _includeVakantiegeld,
            ));
          } : null,
          activeColor: DesignTokens.colorSuccess,
        ),
        
        const SizedBox(height: DesignTokens.spacingL),
        
        Row(
          children: [
            Expanded(
              child: UnifiedButton(
                text: 'Berekenen',
                type: UnifiedButtonType.secondary,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.onSurface,
                onPressed: canProcess ? () {
                  context.read<PaymentBloc>().add(CalculatePaymentAmount(
                    guardId: widget.guardId,
                    type: PaymentType.salaryPayment,
                    includeVakantiegeld: _includeVakantiegeld,
                  ));
                } : null,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              flex: 2,
              child: UnifiedButton(
                text: 'SEPA Uitbetaling',
                type: UnifiedButtonType.primary,
                backgroundColor: DesignTokens.colorSuccess,
                icon: Icons.send,
                onPressed: canProcess && _ibanController.text.isNotEmpty ? () {
                  _processSEPAPayment(context);
                } : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Expense reimbursement section
  Widget _buildExpenseSection(
    BuildContext context, 
    ColorScheme colorScheme, 
    bool canProcess,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.receipt,
              color: DesignTokens.colorInfo,
              size: DesignTokens.iconSizeM,
            ),
            const SizedBox(width: DesignTokens.spacingS),
            Text(
              'Onkosten Vergoeding (iDEAL)',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeBody,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: DesignTokens.spacingM),
        
        Text(
          'Voor kleine bedragen en onkosten vergoedingen',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeCaption,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: DesignTokens.spacingM),
        
        UnifiedButton(
          text: 'Onkosten Indienen',
          type: UnifiedButtonType.secondary,
          backgroundColor: colorScheme.surface,
          foregroundColor: DesignTokens.colorInfo,
          icon: Icons.add_card,
          onPressed: canProcess ? () {
            _showExpenseDialog(context);
          } : null,
        ),
      ],
    );
  }

  /// Payment history card
  Widget _buildPaymentHistoryCard(
    BuildContext context, 
    ColorScheme colorScheme, 
    PaymentState state,
  ) {
    return UnifiedDashboardCard(
      title: 'Recente Betalingen',
      subtitle: 'Laatste uitbetalingen en transacties',
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      child: Column(
        children: [
          if (state is PaymentHistoryLoaded) ...[
            if (state.payments.isNotEmpty) ...[
              ...state.payments.take(3).map((payment) => 
                _buildPaymentHistoryItem(payment, colorScheme)),
            ] else ...[
              _buildEmptyHistoryMessage(colorScheme),
            ],
          ] else ...[
            _buildLoadingHistoryMessage(colorScheme),
          ],
          
          const SizedBox(height: DesignTokens.spacingM),
          
          UnifiedButton(
            text: 'Alle Betalingen Bekijken',
            type: UnifiedButtonType.secondary,
            backgroundColor: colorScheme.surface,
            onPressed: () {
              context.read<PaymentBloc>().add(LoadPaymentHistory(
                guardId: widget.guardId,
              ));
            },
          ),
        ],
      ),
    );
  }

  /// Payment status card for processing payments
  Widget _buildPaymentStatusCard(
    BuildContext context, 
    ColorScheme colorScheme, 
    PaymentState state,
  ) {
    String title = 'Betaling Status';
    String message = '';
    Color statusColor = DesignTokens.colorInfo;
    IconData icon = Icons.info;
    
    if (state is PaymentLoading) {
      message = state.message ?? 'Bezig met verwerken...';
      icon = Icons.hourglass_empty;
    } else if (state is PaymentProcessing) {
      message = state.dutchStatusMessage;
      icon = Icons.sync;
      statusColor = DesignTokens.colorWarning;
    }
    
    return UnifiedDashboardCard(
      title: title,
      subtitle: message,
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: statusColor,
              size: DesignTokens.iconSizeL,
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: DesignTokens.fontSizeBody,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper methods for building UI components

  Widget _buildEarningsRow(
    String label,
    String amount,
    String subtitle,
    ColorScheme colorScheme, {
    bool isHighlight = false,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color textColor = colorScheme.onSurface;
    if (isSuccess) textColor = DesignTokens.colorSuccess;
    if (isWarning) textColor = DesignTokens.colorWarning;
    if (isHighlight) textColor = DesignTokens.colorInfo;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  fontSize: DesignTokens.fontSizeBody,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
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
          amount,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightSemiBold,
            fontSize: DesignTokens.fontSizeBody,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationRow(
    String label,
    double amount,
    ColorScheme colorScheme, {
    bool isNegative = false,
  }) {
    final color = isNegative ? DesignTokens.colorError : colorScheme.onSurface;
    final prefix = isNegative ? '−' : '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeBody,
              color: color,
            ),
          ),
          Text(
            '$prefix${_formatDutchCurrency(amount.abs())}',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeBody,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(PaymentTransaction payment, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(payment.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.type.dutchName,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontWeight: DesignTokens.fontWeightMedium,
                    fontSize: DesignTokens.fontSizeBody,
                  ),
                ),
                Text(
                  payment.status.dutchName,
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
            payment.dutchFormattedAmount,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: DesignTokens.fontSizeBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEarningsMessage(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: DesignTokens.colorWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info,
            color: DesignTokens.colorWarning,
            size: DesignTokens.iconSizeL,
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Text(
            'Geen verdiensten data beschikbaar',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightMedium,
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.colorWarning,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'Werk eerst wat uren om een uitbetaling te kunnen doen',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: DesignTokens.fontSizeCaption,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryMessage(ColorScheme colorScheme) {
    return Text(
      'Nog geen betalingen gedaan',
      style: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBody,
        color: colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingHistoryMessage(ColorScheme colorScheme) {
    return Text(
      'Betalingsgeschiedenis laden...',
      style: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: DesignTokens.fontSizeBody,
        color: colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(PaymentError error, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error,
                color: DesignTokens.colorError,
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  error.errorMessage,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: DesignTokens.fontSizeCaption,
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            ],
          ),
          if (error.canRetry) ...[
            const SizedBox(height: DesignTokens.spacingS),
            UnifiedButton(
              text: 'Opnieuw Proberen',
              type: UnifiedButtonType.secondary,
              backgroundColor: Colors.transparent,
              foregroundColor: DesignTokens.colorError,
              onPressed: () {
                // Retry logic
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Helper methods
  
  String? _validateIBAN(String? value) {
    if (value == null || value.isEmpty) {
      return 'IBAN is verplicht';
    }
    
    // Remove spaces and convert to uppercase
    final cleanIBAN = value.replaceAll(' ', '').toUpperCase();
    
    if (!cleanIBAN.startsWith('NL')) {
      return 'Alleen Nederlandse IBANs worden ondersteund';
    }
    
    if (cleanIBAN.length != 18) {
      return 'IBAN moet 18 karakters hebben';
    }
    
    return null;
  }

  void _processSEPAPayment(BuildContext context) {
    final iban = _ibanController.text.trim();
    if (iban.isNotEmpty && _validateIBAN(iban) == null) {
      context.read<PaymentBloc>().add(ProcessSalaryPayment(
        guardId: widget.guardId,
        recipientIBAN: iban,
        method: PaymentMethod.sepa,
        includeVakantiegeld: _includeVakantiegeld,
      ));
    }
  }

  void _showExpenseDialog(BuildContext context) {
    // Show expense reimbursement dialog
    // Implementation would show a dialog with amount and description fields
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return DesignTokens.colorSuccess;
      case PaymentStatus.processing:
        return DesignTokens.colorWarning;
      case PaymentStatus.failed:
        return DesignTokens.colorError;
      case PaymentStatus.cancelled:
        return DesignTokens.colorError;
      case PaymentStatus.refunded:
        return DesignTokens.colorInfo;
      default:
        return DesignTokens.colorInfo;
    }
  }

  String _formatDutchCurrency(double amount) {
    final euros = amount.floor();
    final cents = ((amount - euros) * 100).round();
    final euroString = euros.toString();
    
    // Add thousand separators (dots in Dutch format)
    String formattedEuros = '';
    for (int i = 0; i < euroString.length; i++) {
      if (i > 0 && (euroString.length - i) % 3 == 0) {
        formattedEuros += '.';
      }
      formattedEuros += euroString[i];
    }
    
    return '€$formattedEuros,${cents.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ibanController.dispose();
    super.dispose();
  }
}