import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../services/bsn_security_service.dart';
import '../services/bsn_access_control_service.dart';

/// Secure BSN Display Widget
/// GDPR Article 9 compliant BSN display component
/// Features secure masking, access control, and audit logging
class SecureBSNDisplayWidget extends StatefulWidget {
  final String encryptedBSN;
  final String purpose;
  final String justification;
  final BSNDisplayMode displayMode;
  final BSNAccessLevel requiredAccessLevel;
  final bool showFullBSNButton;
  final String? userId;
  final VoidCallback? onAccessDenied;
  final Function(String)? onAccessGranted;

  const SecureBSNDisplayWidget({
    super.key,
    required this.encryptedBSN,
    required this.purpose,
    required this.justification,
    this.displayMode = BSNDisplayMode.masked,
    this.requiredAccessLevel = BSNAccessLevel.viewer,
    this.showFullBSNButton = false,
    this.userId,
    this.onAccessDenied,
    this.onAccessGranted,
  });

  @override
  State<SecureBSNDisplayWidget> createState() => _SecureBSNDisplayWidgetState();
}

class _SecureBSNDisplayWidgetState extends State<SecureBSNDisplayWidget> {
  String? _displayBSN;
  String? _accessRequestId;
  bool _isLoading = false;
  bool _hasAccess = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeSecureDisplay();
  }

  Future<void> _initializeSecureDisplay() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request access for BSN data
      final accessResult = await BSNAccessControlService.requestBSNAccess(
        targetUserId: widget.userId ?? 'current_user',
        purpose: widget.purpose,
        justification: widget.justification,
        accessLevel: widget.requiredAccessLevel,
      );

      if (!mounted) return;

      if (accessResult.isGranted) {
        _accessRequestId = accessResult.requestId;
        _hasAccess = true;
        
        // Get secure BSN display
        final secureBSN = await BSNAccessControlService.getSecureBSN(
          encryptedBSN: widget.encryptedBSN,
          accessRequestId: accessResult.requestId!,
          displayMode: widget.displayMode,
          userId: widget.userId,
        );

        if (!mounted) return;
        
        setState(() {
          _displayBSN = secureBSN;
          _isLoading = false;
        });
        
        widget.onAccessGranted?.call(secureBSN);
      } else {
        setState(() {
          _errorMessage = accessResult.reason ?? accessResult.error ?? 'Access denied';
          _isLoading = false;
        });
        
        widget.onAccessDenied?.call();
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load BSN: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showFullBSN() async {
    if (!_hasAccess || _accessRequestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geen toegang tot volledige BSN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Request admin-level access for full BSN
      final accessResult = await BSNAccessControlService.requestBSNAccess(
        targetUserId: widget.userId ?? 'current_user',
        purpose: '${widget.purpose}_full_view',
        justification: 'User requested full BSN view: ${widget.justification}',
        accessLevel: BSNAccessLevel.admin,
      );

      if (accessResult.isGranted) {
        final fullBSN = await BSNAccessControlService.getSecureBSN(
          encryptedBSN: widget.encryptedBSN,
          accessRequestId: accessResult.requestId!,
          displayMode: BSNDisplayMode.fullEncrypted,
          userId: widget.userId,
        );

        if (!mounted) return;

        _showFullBSNDialog(fullBSN);
      } else {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Toegang geweigerd: ${accessResult.reason}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fout bij ophalen volledige BSN: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFullBSNDialog(String fullBSN) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('Volledige BSN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WAARSCHUWING: Volledige BSN is gevoelige informatie',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fullBSN,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fullBSN));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('BSN gekopieerd naar klembord'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopieer BSN',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deze toegang wordt gelogd voor compliance doeleinden.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('BSN laden...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'BSN',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (widget.showFullBSNButton && _hasAccess)
                TextButton.icon(
                  onPressed: _showFullBSN,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    'Toon volledig',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _displayBSN ?? 'Niet beschikbaar',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'GDPR-beveiligd • ${widget.displayMode.name}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Revoke access when widget is disposed
    if (_accessRequestId != null) {
      BSNAccessControlService.revokeBSNAccess(
        _accessRequestId!,
        'Widget disposed',
      ).catchError((e) {
        debugPrint('Failed to revoke BSN access: $e');
      });
    }
    super.dispose();
  }
}

/// Simple BSN display for cases where access is already granted
class SimpleBSNDisplay extends StatelessWidget {
  final String bsn;
  final bool isEncrypted;
  final bool showMasked;

  const SimpleBSNDisplay({
    super.key,
    required this.bsn,
    this.isEncrypted = false,
    this.showMasked = true,
  });

  @override
  Widget build(BuildContext context) {
    if (bsn.isEmpty) {
      return const Text(
        'Geen BSN',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    String displayBSN;
    
    if (isEncrypted) {
      // For encrypted BSN, show safe indicator
      displayBSN = '***-**-${bsn.length >= 4 ? bsn.substring(bsn.length - 4, bsn.length - 2) : '**'}';
    } else if (showMasked) {
      displayBSN = BSNSecurityService.maskBSN(bsn);
    } else {
      displayBSN = BSNSecurityService.formatBSN(bsn);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEncrypted ? Icons.lock_outline : Icons.visibility_off_outlined,
            size: 14,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            displayBSN,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension methods for BSNDisplayMode
extension BSNDisplayModeExtension on BSNDisplayMode {
  String get displayName {
    switch (this) {
      case BSNDisplayMode.masked:
        return 'Gemaskeerd';
      case BSNDisplayMode.lastFourDigits:
        return 'Laatste 4 cijfers';
      case BSNDisplayMode.fullEncrypted:
        return 'Volledig (beveiligd)';
      case BSNDisplayMode.auditOnly:
        return 'Alleen voor audit';
    }
  }

  String get description {
    switch (this) {
      case BSNDisplayMode.masked:
        return 'Toont eerste 3 en laatste 2 cijfers: 123****89';
      case BSNDisplayMode.lastFourDigits:
        return 'Toont alleen laatste 4 cijfers: ****6789';
      case BSNDisplayMode.fullEncrypted:
        return 'Volledige BSN met administratorrechten';
      case BSNDisplayMode.auditOnly:
        return 'Alleen hash voor audit doeleinden';
    }
  }
}