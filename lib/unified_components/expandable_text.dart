import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:go_router/go_router.dart';

/// Expandable text widget with "Toon meer"/"Toon minder" functionality
/// Follows SecuryFlex unified design system patterns
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;
  final String expandText;
  final String collapseText;
  final Color? linkColor;
  final Duration animationDuration;
  final bool showTooltipOnTap;
  final String? tooltipMessage;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 3,
    this.style,
    this.expandText = 'Toon meer',
    this.collapseText = 'Toon minder',
    this.linkColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showTooltipOnTap = false,
    this.tooltipMessage,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _hasOverflow = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextOverflow();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkTextOverflow() {
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.text,
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
      ),
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 32);
    
    if (mounted) {
      setState(() {
        _hasOverflow = textPainter.didExceedMaxLines;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showFullTextModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.tooltipMessage ?? 'Volledige tekst',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              widget.text,
              style: widget.style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Sluiten',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkColor = widget.linkColor ?? theme.colorScheme.primary;

    if (!_hasOverflow) {
      return GestureDetector(
        onTap: widget.showTooltipOnTap ? _showFullTextModal : null,
        child: Text(
          widget.text,
          style: widget.style ?? theme.textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            style: widget.style ?? theme.textTheme.bodyMedium?.copyWith(
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          secondChild: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              widget.text,
              style: widget.style ?? theme.textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          crossFadeState: _isExpanded 
            ? CrossFadeState.showSecond 
            : CrossFadeState.showFirst,
          duration: widget.animationDuration,
        ),
        SizedBox(height: DesignTokens.spacingXS),
        GestureDetector(
          onTap: widget.showTooltipOnTap && !_hasOverflow 
            ? _showFullTextModal 
            : _toggleExpanded,
          child: Text(
            _isExpanded ? widget.collapseText : widget.expandText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: linkColor,
              fontWeight: DesignTokens.fontWeightMedium,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}

/// Expandable address widget with location icon and modal
class ExpandableAddress extends StatelessWidget {
  final String address;
  final int maxLines;
  final TextStyle? style;
  final Color? iconColor;
  final double iconSize;

  const ExpandableAddress({
    super.key,
    required this.address,
    this.maxLines = 2,
    this.style,
    this.iconColor,
    this.iconSize = 16,
  });

  void _showAddressModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.location_on,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
                size: DesignTokens.iconSizeM,
              ),
              SizedBox(width: DesignTokens.spacingS),
              Text(
                'Locatie',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ),
            ],
          ),
          content: Text(
            address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Sluiten',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddressModal(context),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
            size: iconSize,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Expanded(
            child: Text(
              address,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: style ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
