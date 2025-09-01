import 'package:flutter/material.dart';
import 'package:securyflex_app/unified_design_tokens.dart';
import 'package:securyflex_app/unified_card_system.dart';
import 'package:securyflex_app/unified_theme_system.dart';
import 'package:securyflex_app/company_dashboard/widgets/section_title_widget.dart';

/// CompanyLayoutTokens - Standardized Layout Patterns for Company Dashboard
/// 
/// This utility class provides a single source of truth for all layout patterns
/// used throughout the company dashboard pages. It eliminates hardcoded spacing
/// values and ensures visual consistency across all 5 company dashboard pages.
/// 
/// Key Features:
/// - Standardized spacing patterns following 8pt grid system
/// - Integration with UnifiedCard.standard() and CompanySectionTitleWidget
/// - Full UserRole.company theming support
/// - Reusable buildStandardSection() method for consistent layouts
/// 
/// Usage:
/// ```dart
/// // Use predefined spacing patterns
/// Padding(
///   padding: CompanyLayoutTokens.sectionPadding,
///   child: YourContent(),
/// )
/// 
/// // Build standard sections with title and content
/// CompanyLayoutTokens.buildStandardSection(
///   context: context,
///   title: 'Section Title',
///   content: YourContentWidget(),
/// )
/// ```
class CompanyLayoutTokens {
  CompanyLayoutTokens._(); // Private constructor to prevent instantiation

  // ============================================================================
  // STANDARDIZED SPACING PATTERNS
  // ============================================================================
  
  /// Section padding for main content areas
  /// Horizontal: 24px, Vertical: 8px
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: DesignTokens.spacingL,  // 24px
    vertical: DesignTokens.spacingS,    // 8px
  );
  
  /// Card padding for content within cards
  /// All sides: 16px (follows UnifiedCard.standard default)
  static const EdgeInsets cardPadding = EdgeInsets.all(
    DesignTokens.spacingM,  // 16px
  );
  
  /// Header padding for section titles and headers
  /// Left/Right: 24px, Bottom: 8px
  static const EdgeInsets headerPadding = EdgeInsets.only(
    left: DesignTokens.spacingL,    // 24px
    right: DesignTokens.spacingL,   // 24px
    bottom: DesignTokens.spacingS,  // 8px
  );
  
  /// Content padding for inner content areas
  /// All sides: 24px (for spacious content layouts)
  static const EdgeInsets contentPadding = EdgeInsets.all(
    DesignTokens.spacingL,  // 24px
  );
  
  /// Compact padding for tight layouts
  /// All sides: 12px
  static const EdgeInsets compactPadding = EdgeInsets.all(
    DesignTokens.spacingS + DesignTokens.spacingXS,  // 12px
  );
  
  /// List item padding for consistent list layouts
  /// Horizontal: 16px, Vertical: 8px
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: DesignTokens.spacingM,  // 16px
    vertical: DesignTokens.spacingS,    // 8px
  );
  
  /// Standard margin between sections
  /// All sides: 16px
  static const EdgeInsets sectionMargin = EdgeInsets.all(
    DesignTokens.spacingM,  // 16px
  );
  
  /// Compact margin for tight layouts
  /// All sides: 8px
  static const EdgeInsets compactMargin = EdgeInsets.all(
    DesignTokens.spacingS,  // 8px
  );

  // ============================================================================
  // STANDARD SECTION BUILDER
  // ============================================================================
  
  /// Builds a standard section with consistent layout patterns
  /// 
  /// This method creates a standardized section layout that integrates
  /// seamlessly with the unified design system and company theming.
  /// 
  /// Parameters:
  /// - [context]: BuildContext for theme access
  /// - [title]: Section title text (required)
  /// - [subtitle]: Optional subtitle text for section actions
  /// - [content]: Widget content for the section (required)
  /// - [onTap]: Optional callback for title tap interaction
  /// - [showCard]: Whether to wrap content in UnifiedCard (default: true)
  /// - [cardPadding]: Custom padding for card content
  /// - [margin]: Custom margin around the section
  /// 
  /// Returns a Column widget with standardized layout
  static Widget buildStandardSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget content,
    VoidCallback? onTap,
    bool showCard = true,
    EdgeInsetsGeometry? cardPadding,
    EdgeInsetsGeometry? margin,
  }) {
    return Padding(
      padding: margin ?? sectionMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title using CompanySectionTitleWidget
          CompanySectionTitleWidget(
            titleTxt: title,
            subTxt: subtitle,
            onTap: onTap,
          ),
          
          // Content area
          if (showCard)
            UnifiedCard.standard(
              userRole: UserRole.company,
              padding: cardPadding ?? CompanyLayoutTokens.cardPadding,
              child: content,
            )
          else
            Padding(
              padding: cardPadding ?? CompanyLayoutTokens.contentPadding,
              child: content,
            ),
        ],
      ),
    );
  }
  
  /// Builds a compact section for dense layouts
  /// 
  /// Similar to buildStandardSection but with tighter spacing
  /// for areas where space is at a premium.
  static Widget buildCompactSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget content,
    VoidCallback? onTap,
    bool showCard = true,
  }) {
    return buildStandardSection(
      context: context,
      title: title,
      subtitle: subtitle,
      content: content,
      onTap: onTap,
      showCard: showCard,
      cardPadding: compactPadding,
      margin: compactMargin,
    );
  }
  
  /// Builds a content-only section without title
  /// 
  /// For cases where you need standardized content layout
  /// without the section title header.
  static Widget buildContentSection({
    required Widget content,
    bool showCard = true,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final contentWidget = showCard
        ? UnifiedCard.standard(
            userRole: UserRole.company,
            padding: padding ?? cardPadding,
            child: content,
          )
        : Padding(
            padding: padding ?? contentPadding,
            child: content,
          );
    
    return Padding(
      padding: margin ?? sectionMargin,
      child: contentWidget,
    );
  }

  // ============================================================================
  // LAYOUT HELPERS
  // ============================================================================
  
  /// Standard spacing between elements
  static Widget get standardSpacing => SizedBox(height: DesignTokens.spacingM);
  
  /// Compact spacing between elements
  static Widget get compactSpacing => SizedBox(height: DesignTokens.spacingS);
  
  /// Large spacing between major sections
  static Widget get largeSpacing => SizedBox(height: DesignTokens.spacingL);
  
  /// Horizontal spacing for row layouts
  static Widget get horizontalSpacing => SizedBox(width: DesignTokens.spacingM);
  
  /// Compact horizontal spacing
  static Widget get compactHorizontalSpacing => SizedBox(width: DesignTokens.spacingS);

  // ============================================================================
  // ANIMATION CONSTANTS
  // ============================================================================

  /// Standard animation translation offset for Transform widgets
  /// Used in FadeTransition animations: Matrix4.translationValues(0.0, animationOffset * (1.0 - animation.value), 0.0)
  static const double animationOffset = 30.0;

  /// Standard scroll threshold for header opacity changes
  /// Used in scroll listeners: if (scrollController.offset >= scrollThreshold)
  static const double scrollThreshold = 24.0;

  // ============================================================================
  // ADDITIONAL SPACING HELPERS
  // ============================================================================

  /// Extra large spacing for major section breaks
  static Widget get extraLargeSpacing => SizedBox(height: DesignTokens.spacingXL);

  /// Tiny spacing for minimal gaps
  static Widget get tinySpacing => SizedBox(height: DesignTokens.spacingXS);

  /// Extra large horizontal spacing
  static Widget get extraLargeHorizontalSpacing => SizedBox(width: DesignTokens.spacingXL);

  /// Tiny horizontal spacing
  static Widget get tinyHorizontalSpacing => SizedBox(width: DesignTokens.spacingXS);
}
