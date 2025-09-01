import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../unified_design_tokens.dart';
import '../../unified_theme_system.dart';
import '../../unified_components/unified_dashboard_card.dart';
import '../models/enhanced_auth_models.dart';

/// Two-Factor Authentication Setup Widget
/// 
/// Provides a comprehensive setup flow for TOTP authentication with
/// QR code display, manual entry option, and backup codes.
class TwoFactorSetupWidget extends StatefulWidget {
  final String secret;
  final String qrCodeData;
  final String userEmail;
  final List<BackupCode> backupCodes;
  final Function(String code)? onVerifyCode;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  
  const TwoFactorSetupWidget({
    super.key,
    required this.secret,
    required this.qrCodeData,
    required this.userEmail,
    required this.backupCodes,
    this.onVerifyCode,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<TwoFactorSetupWidget> createState() => _TwoFactorSetupWidgetState();
}

class _TwoFactorSetupWidgetState extends State<TwoFactorSetupWidget> {
  int _currentStep = 0;
  final _codeController = TextEditingController();
  bool _secretCopied = false;
  bool _backupCodesDownloaded = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDashboardCard(
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildStepper(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildStepContent(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.security,
          color: DesignTokens.guardPrimary,
          size: DesignTokens.iconSizeL,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          'Tweefactor Authenticatie Instellen',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const Spacer(),
        if (widget.onCancel != null)
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Annuleren',
          ),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          _buildStepIndicator(i),
          if (i < 2) _buildStepConnector(i),
        ],
      ],
    );
  }

  Widget _buildStepIndicator(int step) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? DesignTokens.colorSuccess : 
               isActive ? DesignTokens.guardPrimary : DesignTokens.colorGray300,
      ),
      child: Center(
        child: isCompleted 
          ? const Icon(Icons.check, color: DesignTokens.colorWhite, size: 16)
          : Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? DesignTokens.colorWhite : DesignTokens.colorGray600,
                fontWeight: DesignTokens.fontWeightBold,
                fontSize: DesignTokens.fontSizeS,
              ),
            ),
      ),
    );
  }

  Widget _buildStepConnector(int step) {
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? DesignTokens.colorSuccess : DesignTokens.colorGray300,
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildQRCodeStep();
      case 1:
        return _buildVerificationStep();
      case 2:
        return _buildBackupCodesStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildQRCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stap 1: Scan QR Code',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Scan deze QR code met je authenticator app (Google Authenticator, Authy, enz.):',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),
        Center(
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorWhite,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              boxShadow: [DesignTokens.shadowMedium],
            ),
            child: QrImageView(
              data: widget.qrCodeData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: DesignTokens.colorWhite,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),
        ExpansionTile(
          title: Text(
            'Handmatige invoer',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          children: [
            _buildManualEntry(),
          ],
        ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorGray50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Als je de QR code niet kunt scannen, voer dan handmatig deze code in:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.guardTextSecondary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              color: DesignTokens.colorWhite,
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              border: Border.all(color: DesignTokens.colorGray300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.secret,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontFamily: 'monospace',
                      color: DesignTokens.guardTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _copySecret,
                  icon: Icon(
                    _secretCopied ? Icons.check : Icons.copy,
                    color: _secretCopied ? DesignTokens.colorSuccess : DesignTokens.guardPrimary,
                  ),
                  tooltip: _secretCopied ? 'Gekopieerd!' : 'Kopiëren',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stap 2: Verificeer Authenticator',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Voer de 6-cijferige code in die wordt weergegeven in je authenticator app:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXXL,
            fontWeight: DesignTokens.fontWeightBold,
            letterSpacing: DesignTokens.spacingS,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: DesignTokens.colorGray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: DesignTokens.guardPrimary),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (value) {
            if (value.length == 6 && widget.onVerifyCode != null) {
              widget.onVerifyCode!(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBackupCodesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stap 3: Bewaar Backup Codes',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Container(
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorWarning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: DesignTokens.colorWarning),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: DesignTokens.colorWarning),
              const SizedBox(width: DesignTokens.spacingM),
              Expanded(
                child: Text(
                  'Bewaar deze backup codes op een veilige plaats. Elke code kan maar één keer gebruikt worden.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.spacingL),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorWhite,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: DesignTokens.colorGray300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Backup Codes',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeM,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                  IconButton(
                    onPressed: _downloadBackupCodes,
                    icon: Icon(
                      _backupCodesDownloaded ? Icons.check : Icons.download,
                      color: _backupCodesDownloaded ? DesignTokens.colorSuccess : DesignTokens.guardPrimary,
                    ),
                    tooltip: _backupCodesDownloaded ? 'Gedownload!' : 'Download',
                  ),
                ],
              ),
              const Divider(),
              ...widget.backupCodes.map((code) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  code.formattedCode,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontFamily: 'monospace',
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text('Vorige'),
          )
        else
          const SizedBox(),
        
        ElevatedButton(
          onPressed: _canContinue() ? _handleContinue : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.guardPrimary,
            foregroundColor: DesignTokens.colorWhite,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingL,
              vertical: DesignTokens.spacingM,
            ),
          ),
          child: Text(_getActionText()),
        ),
      ],
    );
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return true; // Can always continue from QR code step
      case 1:
        return _codeController.text.length == 6;
      case 2:
        return _backupCodesDownloaded;
      default:
        return false;
    }
  }

  String _getActionText() {
    switch (_currentStep) {
      case 0:
        return 'Volgende';
      case 1:
        return 'Verifiëren';
      case 2:
        return 'Voltooien';
      default:
        return 'Volgende';
    }
  }

  void _handleContinue() {
    switch (_currentStep) {
      case 0:
        setState(() => _currentStep = 1);
        break;
      case 1:
        if (widget.onVerifyCode != null) {
          widget.onVerifyCode!(_codeController.text);
        }
        setState(() => _currentStep = 2);
        break;
      case 2:
        if (widget.onComplete != null) {
          widget.onComplete!();
        }
        break;
    }
  }

  void _copySecret() {
    Clipboard.setData(ClipboardData(text: widget.secret));
    setState(() => _secretCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _secretCopied = false);
    });
  }

  void _downloadBackupCodes() {
    // In production, this would actually download/save the codes
    setState(() => _backupCodesDownloaded = true);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Backup codes opgeslagen'),
        backgroundColor: DesignTokens.colorSuccess,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// SMS Verification Widget
/// 
/// Provides SMS verification code input with resend functionality,
/// countdown timer, and Dutch phone number formatting.
class SMSVerificationWidget extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final Function(String code) onVerifyCode;
  final VoidCallback? onResendCode;
  final VoidCallback? onCancel;
  final int initialCooldownSeconds;
  
  const SMSVerificationWidget({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    required this.onVerifyCode,
    this.onResendCode,
    this.onCancel,
    this.initialCooldownSeconds = 60,
  });

  @override
  State<SMSVerificationWidget> createState() => _SMSVerificationWidgetState();
}

class _SMSVerificationWidgetState extends State<SMSVerificationWidget>
    with TickerProviderStateMixin {
  final _codeController = TextEditingController();
  late int _cooldownSeconds;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _cooldownSeconds = widget.initialCooldownSeconds;
    _animationController = AnimationController(
      duration: Duration(seconds: widget.initialCooldownSeconds),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
    
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startCooldownTimer() {
    _animationController.forward();
    
    final timer = Stream.periodic(const Duration(seconds: 1), (i) => i);
    timer.take(_cooldownSeconds).listen((i) {
      if (mounted) {
        setState(() {
          _cooldownSeconds = widget.initialCooldownSeconds - i - 1;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDashboardCard(
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildDescription(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildCodeInput(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildResendSection(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.sms,
          color: DesignTokens.guardPrimary,
          size: DesignTokens.iconSizeL,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          'SMS Verificatie',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const Spacer(),
        if (widget.onCancel != null)
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Annuleren',
          ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We hebben een verificatiecode verzonden naar:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Text(
          widget.phoneNumber,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBodyLarge,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voer de 6-cijferige code in:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeXXL,
            fontWeight: DesignTokens.fontWeightBold,
            letterSpacing: DesignTokens.spacingS,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: DesignTokens.colorGray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: DesignTokens.guardPrimary),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (value) {
            if (value.length == 6) {
              widget.onVerifyCode(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildResendSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_cooldownSeconds > 0) ...[
          Text(
            'Nieuwe code aanvragen over: ',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.guardTextSecondary,
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Text(
                '${_cooldownSeconds}s',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.guardPrimary,
                ),
              );
            },
          ),
        ] else if (widget.onResendCode != null) ...[
          TextButton(
            onPressed: _handleResend,
            child: Text(
              'Code opnieuw versturen',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: DesignTokens.guardPrimary,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _codeController.text.length == 6 ? _handleVerify : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.guardPrimary,
              foregroundColor: DesignTokens.colorWhite,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
            ),
            child: const Text('Verifiëren'),
          ),
        ),
      ],
    );
  }

  void _handleVerify() {
    widget.onVerifyCode(_codeController.text);
  }

  void _handleResend() {
    if (widget.onResendCode != null) {
      widget.onResendCode!();
      setState(() {
        _cooldownSeconds = widget.initialCooldownSeconds;
      });
      _animationController.reset();
      _startCooldownTimer();
    }
  }
}

/// Biometric Setup Widget
/// 
/// Provides biometric authentication setup with device capability detection,
/// type selection, and fallback configuration.
class BiometricSetupWidget extends StatefulWidget {
  final BiometricConfig config;
  final List<BiometricType> availableTypes;
  final Function(List<BiometricType> enabledTypes)? onSetupBiometric;
  final VoidCallback? onTestBiometric;
  final VoidCallback? onCancel;
  
  const BiometricSetupWidget({
    super.key,
    required this.config,
    required this.availableTypes,
    this.onSetupBiometric,
    this.onTestBiometric,
    this.onCancel,
  });

  @override
  State<BiometricSetupWidget> createState() => _BiometricSetupWidgetState();
}

class _BiometricSetupWidgetState extends State<BiometricSetupWidget> {
  late List<BiometricType> _selectedTypes;
  
  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.config.enabledTypes);
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDashboardCard(
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: DesignTokens.spacingL),
          if (widget.config.isSupported) ...[
            _buildAvailableTypes(),
            const SizedBox(height: DesignTokens.spacingL),
            _buildSecurityInfo(),
            const SizedBox(height: DesignTokens.spacingL),
            _buildActions(),
          ] else
            _buildNotSupported(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.fingerprint,
          color: DesignTokens.guardPrimary,
          size: DesignTokens.iconSizeL,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          'Biometrische Authenticatie',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeHeading,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const Spacer(),
        if (widget.onCancel != null)
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            tooltip: 'Annuleren',
          ),
      ],
    );
  }

  Widget _buildAvailableTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beschikbare biometrische methoden:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        ...widget.availableTypes.map((type) => _buildTypeOption(type)),
      ],
    );
  }

  Widget _buildTypeOption(BiometricType type) {
    final isSelected = _selectedTypes.contains(type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingS),
      child: CheckboxListTile(
        title: Text(
          type.dutchName,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        subtitle: Text(
          _getBiometricTypeDescription(type),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeS,
            color: DesignTokens.guardTextSecondary,
          ),
        ),
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedTypes.add(type);
            } else {
              _selectedTypes.remove(type);
            }
          });
        },
        activeColor: DesignTokens.guardPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        tileColor: isSelected 
          ? DesignTokens.guardPrimary.withValues(alpha: 0.1)
          : null,
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorInfo),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: DesignTokens.colorInfo),
          const SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometrische beveiliging',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeM,
                    fontWeight: DesignTokens.fontWeightBold,
                    color: DesignTokens.guardTextPrimary,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXS),
                Text(
                  'Biometrische gegevens worden alleen lokaal op je apparaat opgeslagen en nooit naar onze servers verzonden.',
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.guardTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (_selectedTypes.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.guardPrimary,
                foregroundColor: DesignTokens.colorWhite,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
              ),
              child: const Text('Biometrische Authenticatie Inschakelen'),
            ),
          ),
          if (widget.onTestBiometric != null) ...[
            const SizedBox(height: DesignTokens.spacingM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onTestBiometric,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.guardPrimary,
                  side: BorderSide(color: DesignTokens.guardPrimary),
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
                ),
                child: const Text('Test Biometrische Authenticatie'),
              ),
            ),
          ],
        ] else ...[
          Text(
            'Selecteer minimaal één biometrische methode om door te gaan.',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeS,
              color: DesignTokens.guardTextSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildNotSupported() {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: DesignTokens.colorError,
        ),
        const SizedBox(height: DesignTokens.spacingL),
        Text(
          'Biometrische authenticatie niet ondersteund',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Je apparaat ondersteunt geen biometrische authenticatie of er zijn geen biometrische gegevens ingesteld.',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getBiometricTypeDescription(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Gebruik je vingerafdruk om in te loggen';
      case BiometricType.face:
        return 'Gebruik gezichtsherkenning om in te loggen';
      case BiometricType.iris:
        return 'Gebruik iris scan om in te loggen';
      case BiometricType.strong:
        return 'Sterke biometrische authenticatie';
      case BiometricType.weak:
        return 'Zwakke biometrische authenticatie';
    }
  }

  void _handleSetup() {
    if (widget.onSetupBiometric != null && _selectedTypes.isNotEmpty) {
      widget.onSetupBiometric!(_selectedTypes);
    }
  }
}

/// Backup Codes Widget
/// 
/// Displays backup codes with download functionality and usage instructions.
class BackupCodesWidget extends StatefulWidget {
  final List<BackupCode> backupCodes;
  final VoidCallback? onDownload;
  final VoidCallback? onGenerateNew;
  
  const BackupCodesWidget({
    super.key,
    required this.backupCodes,
    this.onDownload,
    this.onGenerateNew,
  });

  @override
  State<BackupCodesWidget> createState() => _BackupCodesWidgetState();
}

class _BackupCodesWidgetState extends State<BackupCodesWidget> {
  bool _codesVisible = false;

  @override
  Widget build(BuildContext context) {
    final usedCodes = widget.backupCodes.where((c) => c.isUsed).length;
    final remainingCodes = widget.backupCodes.length - usedCodes;

    return UnifiedDashboardCard(
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(remainingCodes),
          const SizedBox(height: DesignTokens.spacingM),
          _buildInstructions(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildCodesSection(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildActions(remainingCodes),
        ],
      ),
    );
  }

  Widget _buildHeader(int remainingCodes) {
    return Row(
      children: [
        Icon(
          Icons.security,
          color: DesignTokens.guardPrimary,
          size: DesignTokens.iconSizeL,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Backup Codes',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeTitle,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: DesignTokens.guardTextPrimary,
                ),
              ),
              Text(
                '$remainingCodes van ${widget.backupCodes.length} codes beschikbaar',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: remainingCodes <= 2 
                    ? DesignTokens.colorWarning 
                    : DesignTokens.guardTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: DesignTokens.colorInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: DesignTokens.colorInfo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Belangrijke informatie:',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeM,
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.guardTextPrimary,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingS),
          ...const [
            '• Elke code kan maar één keer gebruikt worden',
            '• Bewaar deze codes op een veilige plaats',
            '• Gebruik ze om toegang te krijgen als je je telefoon kwijt bent',
            '• Genereer nieuwe codes als je er nog maar weinig hebt',
          ].map((instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeS,
                color: DesignTokens.guardTextSecondary,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Je backup codes:',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightMedium,
                color: DesignTokens.guardTextPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _codesVisible = !_codesVisible),
              icon: Icon(
                _codesVisible ? Icons.visibility_off : Icons.visibility,
                size: DesignTokens.iconSizeS,
              ),
              label: Text(_codesVisible ? 'Verbergen' : 'Tonen'),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.spacingM),
          decoration: BoxDecoration(
            color: DesignTokens.colorWhite,
            borderRadius: BorderRadius.circular(DesignTokens.radiusM),
            border: Border.all(color: DesignTokens.colorGray300),
          ),
          child: _codesVisible ? _buildVisibleCodes() : _buildHiddenCodes(),
        ),
      ],
    );
  }

  Widget _buildVisibleCodes() {
    return Column(
      children: widget.backupCodes.map((code) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: code.isUsed 
            ? DesignTokens.colorGray100 
            : DesignTokens.colorGray50,
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                code.formattedCode,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeM,
                  fontFamily: 'monospace',
                  color: code.isUsed 
                    ? DesignTokens.guardTextSecondary 
                    : DesignTokens.guardTextPrimary,
                  decoration: code.isUsed 
                    ? TextDecoration.lineThrough 
                    : TextDecoration.none,
                ),
              ),
            ),
            if (code.isUsed) ...[
              Icon(
                Icons.check_circle,
                color: DesignTokens.colorSuccess,
                size: DesignTokens.iconSizeS,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Text(
                'Gebruikt',
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeS,
                  color: DesignTokens.colorSuccess,
                ),
              ),
            ],
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildHiddenCodes() {
    return Column(
      children: [
        Icon(
          Icons.visibility_off,
          size: 48,
          color: DesignTokens.colorGray400,
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          'Backup codes verborgen voor beveiliging',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActions(int remainingCodes) {
    return Row(
      children: [
        if (widget.onDownload != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onDownload,
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.guardPrimary,
                side: BorderSide(color: DesignTokens.guardPrimary),
              ),
            ),
          ),
        if (widget.onDownload != null && widget.onGenerateNew != null)
          const SizedBox(width: DesignTokens.spacingM),
        if (widget.onGenerateNew != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: remainingCodes <= 2 ? widget.onGenerateNew : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Nieuwe Codes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: remainingCodes <= 2 
                  ? DesignTokens.colorWarning 
                  : DesignTokens.guardPrimary,
                foregroundColor: DesignTokens.colorWhite,
              ),
            ),
          ),
      ],
    );
  }
}

/// Security Level Indicator Widget
/// 
/// Shows the current authentication security level with visual indicator
/// and recommendations for improvement.
class SecurityLevelIndicator extends StatelessWidget {
  final AuthenticationLevel currentLevel;
  final List<String> recommendations;
  final VoidCallback? onImprove;
  
  const SecurityLevelIndicator({
    super.key,
    required this.currentLevel,
    this.recommendations = const [],
    this.onImprove,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedDashboardCard(
      userRole: UserRole.guard,
      variant: DashboardCardVariant.standard,
      padding: EdgeInsets.all(DesignTokens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: DesignTokens.spacingL),
          _buildLevelIndicator(),
          const SizedBox(height: DesignTokens.spacingL),
          if (recommendations.isNotEmpty) ...[
            _buildRecommendations(),
            const SizedBox(height: DesignTokens.spacingL),
          ],
          if (onImprove != null) _buildImproveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _getLevelIcon(),
          color: _getLevelColor(),
          size: DesignTokens.iconSizeL,
        ),
        const SizedBox(width: DesignTokens.spacingS),
        Text(
          'Beveiligingsniveau',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: currentLevel.level / 4.0,
                backgroundColor: DesignTokens.colorGray200,
                valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
                minHeight: 8,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingM),
            Text(
              '${currentLevel.level}/4',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeM,
                fontWeight: DesignTokens.fontWeightBold,
                color: _getLevelColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),
        Text(
          currentLevel.dutchName,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBodyLarge,
            fontWeight: DesignTokens.fontWeightBold,
            color: _getLevelColor(),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Text(
          currentLevel.descriptionDutch,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: DesignTokens.guardTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aanbevelingen:',
          style: TextStyle(
            fontSize: DesignTokens.fontSizeM,
            fontWeight: DesignTokens.fontWeightBold,
            color: DesignTokens.guardTextPrimary,
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        ...recommendations.map((recommendation) => Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: DesignTokens.iconSizeS,
                color: DesignTokens.colorWarning,
              ),
              const SizedBox(width: DesignTokens.spacingS),
              Expanded(
                child: Text(
                  recommendation,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeS,
                    color: DesignTokens.guardTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildImproveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onImprove,
        icon: const Icon(Icons.security),
        label: const Text('Beveiliging Verbeteren'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getLevelColor(),
          foregroundColor: DesignTokens.colorWhite,
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
        ),
      ),
    );
  }

  Color _getLevelColor() {
    switch (currentLevel) {
      case AuthenticationLevel.basic:
        return DesignTokens.colorError;
      case AuthenticationLevel.twoFactor:
        return DesignTokens.colorWarning;
      case AuthenticationLevel.biometric:
        return DesignTokens.colorInfo;
      case AuthenticationLevel.combined:
        return DesignTokens.colorSuccess;
    }
  }

  IconData _getLevelIcon() {
    switch (currentLevel) {
      case AuthenticationLevel.basic:
        return Icons.security;
      case AuthenticationLevel.twoFactor:
        return Icons.verified_user;
      case AuthenticationLevel.biometric:
        return Icons.fingerprint;
      case AuthenticationLevel.combined:
        return Icons.shield;
    }
  }
}