import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../unified_input_system.dart';
import '../../unified_buttons.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_card_system.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Enhanced KvK validation widget using UnifiedComponents
/// Provides comprehensive KvK number validation with security industry eligibility checking
class KvKValidationWidget extends StatefulWidget {
  /// Whether to require security industry eligibility
  final bool requireSecurityEligibility;
  
  /// User role for theming
  final UserRole? userRole;
  
  /// API key for KvK validation (optional)
  final String? apiKey;
  
  /// Callback when validation is successful
  final void Function(AuthKvKValidation result)? onValidationSuccess;
  
  /// Callback when validation fails
  final void Function(String error)? onValidationError;
  
  /// Whether to show detailed company information
  final bool showDetailedInfo;
  
  /// Whether to enable real-time validation
  final bool enableRealTimeValidation;
  
  /// Custom validation button text
  final String? validateButtonText;

  const KvKValidationWidget({
    super.key,
    this.requireSecurityEligibility = false,
    this.userRole,
    this.apiKey,
    this.onValidationSuccess,
    this.onValidationError,
    this.showDetailedInfo = true,
    this.enableRealTimeValidation = false,
    this.validateButtonText,
  });

  @override
  State<KvKValidationWidget> createState() => _KvKValidationWidgetState();
}

class _KvKValidationWidgetState extends State<KvKValidationWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _kvkController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _currentValidationError;
  AuthKvKValidation? _lastValidationResult;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.durationMedium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enableRealTimeValidation) {
      _kvkController.addListener(_onKvKChanged);
    }
  }

  @override
  void dispose() {
    _kvkController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onKvKChanged() {
    if (_kvkController.text.length == 8) {
      _validateKvK();
    } else {
      setState(() {
        _currentValidationError = null;
        _lastValidationResult = null;
      });
      _animationController.reset();
    }
  }

  void _validateKvK() {
    final kvkNumber = _kvkController.text.trim();
    if (kvkNumber.isEmpty) return;

    setState(() {
      _isValidating = true;
      _currentValidationError = null;
    });

    context.read<AuthBloc>().add(
      AuthValidateKvK(
        kvkNumber,
        requireSecurityEligibility: widget.requireSecurityEligibility,
        apiKey: widget.apiKey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = widget.userRole != null 
        ? SecuryFlexTheme.getColorScheme(widget.userRole!) 
        : theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthKvKValidation) {
          setState(() {
            _isValidating = false;
            _lastValidationResult = state;
            _currentValidationError = state.isValid ? null : state.dutchErrorMessage;
          });

          if (state.isValid) {
            _animationController.forward();
            widget.onValidationSuccess?.call(state);
          } else {
            _animationController.reset();
            widget.onValidationError?.call(state.dutchErrorMessage);
          }
        } else if (state is AuthKvKValidating) {
          setState(() {
            _isValidating = true;
            _currentValidationError = null;
          });
        } else if (state is AuthError) {
          setState(() {
            _isValidating = false;
            _currentValidationError = 'Validatie mislukt. Probeer opnieuw.';
          });
          widget.onValidationError?.call('Validatie mislukt. Probeer opnieuw.');
        }
      },
      child: UnifiedCard(
        variant: UnifiedCardVariant.standard,
        userRole: widget.userRole,
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, colorScheme),
              SizedBox(height: DesignTokens.spacingM),
              _buildKvKInput(theme, colorScheme),
              SizedBox(height: DesignTokens.spacingS),
              if (!widget.enableRealTimeValidation) ...[
                _buildValidateButton(theme, colorScheme),
                SizedBox(height: DesignTokens.spacingS),
              ],
              if (_isValidating) _buildLoadingIndicator(theme, colorScheme),
              if (_currentValidationError != null) 
                _buildErrorDisplay(theme, colorScheme),
              if (_lastValidationResult != null && _lastValidationResult!.isValid)
                _buildSuccessDisplay(theme, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KvK Nummer Validatie',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingXS),
        Text(
          widget.requireSecurityEligibility
              ? 'Valideer uw KvK nummer en controleer geschiktheid voor beveiligingsopdrachten'
              : 'Valideer uw KvK nummer tegen het Nederlandse handelsregister',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildKvKInput(ThemeData theme, ColorScheme colorScheme) {
    return UnifiedInput(
      controller: _kvkController,
      label: 'KvK Nummer',
      hint: '12345678',
      helperText: '8 cijfers, bijvoorbeeld 12345678',
      errorText: _currentValidationError,
      prefixIcon: Icons.business,
      keyboardType: TextInputType.number,
      maxLength: 8,
      userRole: widget.userRole,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'KvK nummer is verplicht';
        }
        if (value.length != 8) {
          return 'KvK nummer moet 8 cijfers bevatten';
        }
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
          return 'KvK nummer mag alleen cijfers bevatten';
        }
        return null;
      },
      suffixIcon: _lastValidationResult?.isValid == true 
          ? Icons.check_circle 
          : _currentValidationError != null 
          ? Icons.error 
          : null,
      onSuffixIconPressed: _lastValidationResult?.isValid == true 
          ? () => _showCompanyDetails(context) 
          : null,
    );
  }

  Widget _buildValidateButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: UnifiedButton(
        text: widget.validateButtonText ?? 'KvK Valideren',
        onPressed: _isValidating ? null : _validateKvK,
        icon: Icons.verified_outlined,
        isLoading: _isValidating,
        type: UnifiedButtonType.primary,
        size: UnifiedButtonSize.medium,
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme, ColorScheme colorScheme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthKvKValidating) {
          return UnifiedCard(
            variant: UnifiedCardVariant.compact,
            userRole: widget.userRole,
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spacingM),
              child: Row(
                children: [
                  SizedBox(
                    width: DesignTokens.iconSizeM,
                    height: DesignTokens.iconSizeM,
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.detailedLoadingMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                        if (state.currentStep != null) ...[
                          SizedBox(height: DesignTokens.spacingXS),
                          Text(
                            state.currentStep!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorDisplay(ThemeData theme, ColorScheme colorScheme) {
    return UnifiedCard(
      variant: UnifiedCardVariant.standard,
      userRole: widget.userRole,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.error,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Validatie Mislukt',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    _currentValidationError!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  UnifiedButton(
                    text: 'Opnieuw Proberen',
                    onPressed: _validateKvK,
                    size: UnifiedButtonSize.small,
                    icon: Icons.refresh,
                    type: UnifiedButtonType.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessDisplay(ThemeData theme, ColorScheme colorScheme) {
    final result = _lastValidationResult!;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: UnifiedCard(
        variant: UnifiedCardVariant.featured,
        userRole: widget.userRole,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: DesignTokens.iconSizeL,
                  ),
                  SizedBox(width: DesignTokens.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KvK Nummer Gevalideerd',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                        if (result.companyName != null) ...[
                          SizedBox(height: DesignTokens.spacingXS),
                          Text(
                            result.companyName!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (widget.requireSecurityEligibility && result.isSecurityEligible) ...[
                SizedBox(height: DesignTokens.spacingM),
                Container(
                  padding: EdgeInsets.all(DesignTokens.spacingS),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusS),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: colorScheme.secondary,
                        size: DesignTokens.iconSizeM,
                      ),
                      SizedBox(width: DesignTokens.spacingS),
                      Expanded(
                        child: Text(
                          result.securityEligibilityDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.showDetailedInfo) ...[
                SizedBox(height: DesignTokens.spacingM),
                UnifiedButton(
                  text: 'Bedrijfsgegevens Bekijken',
                  onPressed: () => _showCompanyDetails(context),
                  size: UnifiedButtonSize.small,
                  icon: Icons.info_outline,
                  type: UnifiedButtonType.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanyDetails(BuildContext context) {
    if (_lastValidationResult == null || !_lastValidationResult!.isValid) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanyDetailsBottomSheet(
        kvkValidation: _lastValidationResult!,
        userRole: widget.userRole,
      ),
    );
  }
}

/// Bottom sheet displaying detailed company information
class CompanyDetailsBottomSheet extends StatelessWidget {
  final AuthKvKValidation kvkValidation;
  final UserRole? userRole;

  const CompanyDetailsBottomSheet({
    super.key,
    required this.kvkValidation,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = userRole != null 
        ? SecuryFlexTheme.getColorScheme(userRole!) 
        : theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusL),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: DesignTokens.spacingS),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(DesignTokens.spacingL),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bedrijfsgegevens',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: DesignTokens.fontWeightSemiBold,
                            ),
                          ),
                          SizedBox(height: DesignTokens.spacingXS),
                          Text(
                            'KvK: ${kvkValidation.kvkNumber}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompanyInfoSection(theme, colorScheme),
                      SizedBox(height: DesignTokens.spacingL),
                      if (kvkValidation.isSecurityEligible)
                        _buildSecurityEligibilitySection(theme, colorScheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanyInfoSection(ThemeData theme, ColorScheme colorScheme) {
    final kvkData = kvkValidation.kvkData;
    if (kvkData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Algemene Informatie',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        _buildInfoItem(
          theme,
          colorScheme,
          'Bedrijfsnaam',
          kvkData['companyName'] ?? 'Niet beschikbaar',
          Icons.business,
        ),
        _buildInfoItem(
          theme,
          colorScheme,
          'Handelsnaam',
          kvkData['tradeName'] ?? kvkData['companyName'] ?? 'Niet beschikbaar',
          Icons.store,
        ),
        _buildInfoItem(
          theme,
          colorScheme,
          'Rechtsvorm',
          kvkData['legalForm'] ?? 'Niet beschikbaar',
          Icons.account_balance,
        ),
        if (kvkData['sbiDescription'] != null)
          _buildInfoItem(
            theme,
            colorScheme,
            'Hoofdactiviteit',
            kvkData['sbiDescription'],
            Icons.work,
          ),
        _buildInfoItem(
          theme,
          colorScheme,
          'Status',
          kvkData['isActive'] == true ? 'Actief' : 'Inactief',
          kvkData['isActive'] == true ? Icons.check_circle : Icons.cancel,
          valueColor: kvkData['isActive'] == true ? colorScheme.primary : colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildSecurityEligibilitySection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beveiligingsgeschiktheid',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: DesignTokens.fontWeightSemiBold,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: colorScheme.secondary,
                    size: DesignTokens.iconSizeM,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      kvkValidation.securityEligibilityDescription,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                ],
              ),
              if (kvkValidation.eligibilityReasons.isNotEmpty) ...[
                SizedBox(height: DesignTokens.spacingM),
                Text(
                  'Redenen:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  kvkValidation.formattedEligibilityReasons,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
            size: DesignTokens.iconSizeS,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
                SizedBox(height: DesignTokens.spacingXS),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}