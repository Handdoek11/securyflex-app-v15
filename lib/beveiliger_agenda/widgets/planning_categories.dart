import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import '../models/planning_category_data.dart';

class PlanningCategoriesView extends StatefulWidget {
  const PlanningCategoriesView({
    super.key,
    this.mainScreenAnimationController,
    this.mainScreenAnimation,
    this.onCategorySelected,
  });

  final AnimationController? mainScreenAnimationController;
  final Animation<double>? mainScreenAnimation;
  final Function(PlanningCategoryData)? onCategorySelected;

  @override
  State<PlanningCategoriesView> createState() => _PlanningCategoriesViewState();
}

class _PlanningCategoriesViewState extends State<PlanningCategoriesView>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  List<PlanningCategoryData> categoryListData =
      PlanningCategoryData.getDefaultCategories();

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.mainScreenAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: widget.mainScreenAnimation!,
          child: Transform(
            transform: Matrix4.translationValues(
              0.0,
              30 * (1.0 - widget.mainScreenAnimation!.value),
              0.0,
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8),
                child: GridView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 24.0,
                    crossAxisSpacing: 24.0,
                    childAspectRatio: 1.0,
                  ),
                  children: List<Widget>.generate(categoryListData.length, (
                    int index,
                  ) {
                    final int count = categoryListData.length;
                    final Animation<double> animation =
                        Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animationController!,
                            curve: Interval(
                              (1 / count) * index,
                              1.0,
                              curve: Curves.fastOutSlowIn,
                            ),
                          ),
                        );
                    animationController?.forward();
                    return PlanningCategoryCard(
                      categoryData: categoryListData[index],
                      animation: animation,
                      animationController: animationController!,
                      onTap: () {
                        setState(() {
                          // Reset all selections
                          for (var category in categoryListData) {
                            category.isSelected = false;
                          }
                          // Select current category
                          categoryListData[index].isSelected = true;
                        });
                        widget.onCategorySelected?.call(
                          categoryListData[index],
                        );
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlanningCategoryCard extends StatelessWidget {
  const PlanningCategoryCard({
    super.key,
    required this.categoryData,
    this.animationController,
    this.animation,
    this.onTap,
  });

  final PlanningCategoryData categoryData;
  final AnimationController? animationController;
  final Animation<double>? animation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Pre-calculate colors to avoid inline parsing
    final startColor = Color(int.parse(categoryData.startColor.replaceAll('#', '0xFF')));
    final endColor = Color(int.parse(categoryData.endColor.replaceAll('#', '0xFF')));

    // Reduced nesting: Combined animation with single animated builder
    return AnimatedBuilder(
      animation: animationController!,
      builder: (BuildContext context, Widget? child) {
        final animValue = animation!.value;
        
        // Combine FadeTransition and Transform into matrix directly
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0.0, 50 * (1.0 - animValue)),
            child: _buildCard(context, startColor, endColor),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, Color startColor, Color endColor) {
    // Flattened structure: Material with Ink decoration
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: const BorderRadius.all(Radius.circular(16.0)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: DesignTokens.colorGray500.withValues(alpha: 0.4),
              offset: const Offset(1.1, 1.1),
              blurRadius: 10.0,
            ),
          ],
          border: categoryData.isSelected
              ? Border.all(color: DesignTokens.colorWhite, width: 3)
              : null,
        ),
        child: InkWell(
          focusColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          highlightColor: Theme.of(context).colorScheme.surfaceContainerLow,
          hoverColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          splashColor: DesignTokens.colorWhite.withValues(alpha: 0.2),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(startColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color startColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Header row with icon and badge
        Row(
          children: [
            Icon(
              categoryData.icon,
              size: 28,
              color: DesignTokens.colorWhite,
            ),
            const Spacer(),
            if (categoryData.badgeCount > 0) _buildBadge(startColor),
          ],
        ),
        const SizedBox(height: 12),
        // Title
        Flexible(
          child: Text(
            categoryData.title,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightSemiBold,
              fontSize: 16,
              letterSpacing: 0.0,
              color: DesignTokens.colorWhite,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Description
        Flexible(
          child: Text(
            categoryData.description,
            textAlign: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.fontWeightRegular,
              fontSize: 11,
              letterSpacing: 0.0,
              color: DesignTokens.colorWhite.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(Color startColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.colorWhite,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${categoryData.badgeCount}',
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontWeight: DesignTokens.fontWeightBold,
          fontSize: 10,
          color: startColor,
        ),
      ),
    );
  }
}
