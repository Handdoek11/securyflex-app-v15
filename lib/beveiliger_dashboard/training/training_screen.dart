import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_header.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/unified_components/unified_background_service.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key, this.animationController});

  final AnimationController? animationController;
  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen>
    with TickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SecuryFlexTheme.getColorScheme(UserRole.guard);

    return SafeArea(
      child: UnifiedBackgroundService.guardMeshGradient(
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(AppBar().preferredSize.height),
          child: getAppBarUI(),
        ),
            body: getMainListViewUI(),
          ),
        ),
      ),
    );
  }

  Widget getMainListViewUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 80, color: DesignTokens.guardPrimary),
          SizedBox(height: 20),
          Text(
            'Training & Certificering',
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSection,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Binnenkort beschikbaar',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.guardTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget getAppBarUI() {
    return UnifiedHeader.animated(
      title: 'Training',
      animationController: widget.animationController!,
      scrollController: scrollController,
      enableScrollAnimation: true,
      userRole: UserRole.guard,
      titleAlignment: TextAlign.left, // Main navigation screen
    );
  }
}
