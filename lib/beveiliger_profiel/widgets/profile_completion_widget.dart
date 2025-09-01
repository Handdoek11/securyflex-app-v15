import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/unified_components.dart';
import '../../unified_components/smart_badge_overlay.dart';
import '../bloc/beveiliger_profiel_bloc.dart';
import '../services/profile_completion_service.dart';
import '../models/profile_completion_data.dart';

/// Profile completion tracking widget with unified progress indicators
/// 
/// Shows completion percentage, missing elements checklist, and quick actions
/// Integrates with existing analytics and performance systems
/// Uses SecuryFlex unified design components exclusively
class ProfileCompletionWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onCompletionMilestone;
  final bool showQuickActions;
  
  const ProfileCompletionWidget({
    super.key,
    required this.userId,
    this.onCompletionMilestone,
    this.showQuickActions = true,
  });

  @override
  State<ProfileCompletionWidget> createState() => _ProfileCompletionWidgetState();
}

class _ProfileCompletionWidgetState extends State<ProfileCompletionWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _trackCompletionView();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  void _trackCompletionView() {
    // Track analytics event for profile completion widget view
    ProfileCompletionService.instance.trackCompletionWidgetView(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeveiligerProfielBloc, BeveiligerProfielState>(
      builder: (context, state) {
        if (state is BeveiligerProfielLoaded && state.profileCompletionData != null) {
          return _buildCompletionWidget(context, state.profileCompletionData!);
        }
        return _buildLoadingWidget(context);
      },
    );
  }

  Widget _buildCompletionWidget(BuildContext context, ProfileCompletionData completionData) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    // Don't show widget if profile is fully complete
    if (completionData.completionPercentage >= 100) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: EdgeInsets.all(DesignTokens.spacingM),
        child: UnifiedCard.standard(
          backgroundColor: colorScheme.surfaceContainer,
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, completionData, colorScheme),
                SizedBox(height: DesignTokens.spacingM),
                _buildProgressIndicator(context, completionData, colorScheme),
                SizedBox(height: DesignTokens.spacingM),
                _buildMissingElementsList(context, completionData, colorScheme),
                if (widget.showQuickActions) ...[
                  SizedBox(height: DesignTokens.spacingL),
                  _buildQuickActions(context, completionData, colorScheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final colorScheme = SecuryFlexTheme.getColorScheme(UserRole.guard);
    
    return Container(
      margin: EdgeInsets.all(DesignTokens.spacingM),
      child: UnifiedCard.standard(
        backgroundColor: colorScheme.surfaceContainer,
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingL),
          child: Row(
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 2.0,
              ),
              SizedBox(width: DesignTokens.spacingM),
              Text(
                'Profiel completie laden...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileCompletionData completionData, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profiel ${completionData.completionPercentage.round()}% compleet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightBold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: DesignTokens.spacingXS),
              Text(
                _getCompletionMessage(completionData.completionPercentage),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildCompletionBadge(completionData.completionPercentage, colorScheme),
      ],
    );
  }

  Widget _buildCompletionBadge(double completionPercentage, ColorScheme colorScheme) {
    BadgeType badgeType;
    Color badgeColor;
    
    if (completionPercentage >= 80) {
      badgeType = BadgeType.success;
      badgeColor = DesignTokens.statusCompleted;
    } else if (completionPercentage >= 50) {
      badgeType = BadgeType.warning;
      badgeColor = DesignTokens.statusPending;
    } else {
      badgeType = BadgeType.urgent;
      badgeColor = DesignTokens.colorError;
    }

    return SmartBadgeOverlay(
      badgeType: badgeType,
      badgeCount: (100 - completionPercentage).round(),
      showBadge: completionPercentage < 100,
      accessibilityLabel: '${(100 - completionPercentage).round()} procent nog te doen',
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacingS),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusCircular),
        ),
        child: Icon(
          completionPercentage >= 80 ? Icons.check_circle_outline : Icons.pending_outlined,
          color: badgeColor,
          size: DesignTokens.iconSizeM,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, ProfileCompletionData completionData, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Voortgang',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightMedium,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '${completionData.completionPercentage.round()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: DesignTokens.fontFamily,
                fontWeight: DesignTokens.fontWeightBold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.spacingS),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
              child: LinearProgressIndicator(
                value: (completionData.completionPercentage / 100) * _progressAnimation.value,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMissingElementsList(BuildContext context, ProfileCompletionData completionData, ColorScheme colorScheme) {
    if (completionData.missingElements.isEmpty) {
      return Container(
        padding: EdgeInsets.all(DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: DesignTokens.statusCompleted.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusS),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: DesignTokens.statusCompleted,
              size: DesignTokens.iconSizeM,
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Text(
                'Profiel is volledig compleet!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: DesignTokens.statusCompleted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nog te doen',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingS),
        ...completionData.missingElements.take(3).map((element) => 
          Container(
            margin: EdgeInsets.only(bottom: DesignTokens.spacingS),
            padding: EdgeInsets.all(DesignTokens.spacingM),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusS),
            ),
            child: Row(
              children: [
                Icon(
                  _getElementIcon(element.type),
                  color: colorScheme.onSurfaceVariant,
                  size: DesignTokens.iconSizeS,
                ),
                SizedBox(width: DesignTokens.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        element.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: DesignTokens.fontFamily,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (element.description.isNotEmpty) ...[
                        SizedBox(height: DesignTokens.spacingXS),
                        Text(
                          element.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: DesignTokens.fontFamily,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SmartBadgeOverlay(
                  badgeType: BadgeType.info,
                  badgeCount: element.importance,
                  showBadge: element.importance > 0,
                  child: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                    size: DesignTokens.iconSizeS,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (completionData.missingElements.length > 3) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'En ${completionData.missingElements.length - 3} meer...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: DesignTokens.fontFamily,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ProfileCompletionData completionData, ColorScheme colorScheme) {
    if (completionData.missingElements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Snelle acties',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.fontWeightMedium,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: DesignTokens.spacingM),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: completionData.missingElements.take(2).map((element) =>
            UnifiedButton(
              text: _getQuickActionText(element.type),
              onPressed: () => _handleQuickAction(context, element),
              type: UnifiedButtonType.secondary,
              size: UnifiedButtonSize.small,
              icon: _getElementIcon(element.type),
            ),
          ).toList(),
        ),
      ],
    );
  }

  IconData _getElementIcon(ProfileElementType type) {
    switch (type) {
      case ProfileElementType.basicInfo:
        return Icons.person_outline;
      case ProfileElementType.certificates:
        return Icons.verified_outlined;
      case ProfileElementType.specializations:
        return Icons.star_outline;
      case ProfileElementType.photo:
        return Icons.photo_camera_outlined;
      case ProfileElementType.wpbrCertificate:
        return Icons.security_outlined;
      case ProfileElementType.contactInfo:
        return Icons.contact_mail_outlined;
    }
  }

  String _getQuickActionText(ProfileElementType type) {
    switch (type) {
      case ProfileElementType.basicInfo:
        return 'Basis gegevens';
      case ProfileElementType.certificates:
        return 'Certificaten';
      case ProfileElementType.specializations:
        return 'Specialisaties';
      case ProfileElementType.photo:
        return 'Foto toevoegen';
      case ProfileElementType.wpbrCertificate:
        return 'WPBR certificaat';
      case ProfileElementType.contactInfo:
        return 'Contact gegevens';
    }
  }

  String _getCompletionMessage(double percentage) {
    if (percentage >= 90) {
      return 'Bijna compleet! Nog even en je profiel is helemaal af.';
    } else if (percentage >= 70) {
      return 'Goed bezig! Je profiel ziet er al goed uit.';
    } else if (percentage >= 50) {
      return 'Je bent op de goede weg. Nog een paar stappen.';
    } else if (percentage >= 25) {
      return 'Laten we je profiel verder aanvullen.';
    } else {
      return 'Welkom! Laten we je profiel opstellen.';
    }
  }

  void _handleQuickAction(BuildContext context, MissingProfileElement element) {
    // Track analytics for quick action usage
    ProfileCompletionService.instance.trackQuickActionUsed(widget.userId, element.type);
    
    // Trigger BLoC event to handle quick action navigation
    context.read<BeveiligerProfielBloc>().add(
      NavigateToProfileSection(element.type),
    );
    
    // Call milestone callback if provided
    widget.onCompletionMilestone?.call();
  }
}