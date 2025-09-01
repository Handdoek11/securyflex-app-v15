# 🏗️ CompanyLayoutTokens Utility Guide

## Overview

The `CompanyLayoutTokens` utility class provides a **single source of truth** for all layout patterns used throughout the SecuryFlex company dashboard. It eliminates hardcoded spacing values and ensures visual consistency across all 5 company dashboard pages.

## 🎯 Key Benefits

- ✅ **Eliminates hardcoded spacing** - No more `EdgeInsets.all(16.0)` scattered throughout code
- ✅ **Ensures visual consistency** - All company pages follow identical layout patterns
- ✅ **Integrates seamlessly** - Works perfectly with `UnifiedCard.standard()` and `CompanySectionTitleWidget`
- ✅ **Supports company theming** - Full `UserRole.company` theme integration
- ✅ **Reduces development time** - Standard builders for common layout patterns

## 📐 Standardized Spacing Patterns

### Core Spacing Constants

```dart
// Section padding for main content areas (24px horizontal, 8px vertical)
CompanyLayoutTokens.sectionPadding

// Card padding for content within cards (16px all sides)
CompanyLayoutTokens.cardPadding

// Header padding for section titles (24px left/right, 8px bottom)
CompanyLayoutTokens.headerPadding

// Content padding for spacious layouts (24px all sides)
CompanyLayoutTokens.contentPadding

// Compact padding for tight layouts (12px all sides)
CompanyLayoutTokens.compactPadding

// List item padding (16px horizontal, 8px vertical)
CompanyLayoutTokens.listItemPadding
```

### Margin Constants

```dart
// Standard margin between sections (16px all sides)
CompanyLayoutTokens.sectionMargin

// Compact margin for tight layouts (8px all sides)
CompanyLayoutTokens.compactMargin
```

## 🏗️ Standard Section Builders

### 1. buildStandardSection() - Primary Builder

The main method for creating consistent section layouts:

```dart
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Actieve Jobs',
  subtitle: 'Beheer Jobs',
  onTap: () => _navigateToJobsScreen(),
  content: YourContentWidget(),
)
```

**Parameters:**
- `context` (required): BuildContext for theme access
- `title` (required): Section title text
- `subtitle` (optional): Subtitle text for actions
- `content` (required): Widget content for the section
- `onTap` (optional): Callback for title tap interaction
- `showCard` (optional): Whether to wrap in UnifiedCard (default: true)
- `cardPadding` (optional): Custom padding for card content
- `margin` (optional): Custom margin around section

### 2. buildCompactSection() - Dense Layouts

For areas where space is at a premium:

```dart
CompanyLayoutTokens.buildCompactSection(
  context: context,
  title: 'Quick Stats',
  content: StatsWidget(),
)
```

### 3. buildContentSection() - Content Only

For standardized content without title header:

```dart
CompanyLayoutTokens.buildContentSection(
  content: YourWidget(),
  showCard: true,
)
```

## 🎨 Layout Helpers

### Spacing Widgets

```dart
// Standard spacing between elements (16px)
CompanyLayoutTokens.standardSpacing

// Compact spacing (8px)
CompanyLayoutTokens.compactSpacing

// Large spacing between major sections (24px)
CompanyLayoutTokens.largeSpacing

// Horizontal spacing for rows (16px)
CompanyLayoutTokens.horizontalSpacing

// Compact horizontal spacing (8px)
CompanyLayoutTokens.compactHorizontalSpacing
```

## 📋 Migration Examples

### Before (Hardcoded Spacing)

```dart
// ❌ OLD: Inconsistent hardcoded values
Padding(
  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
  child: Column(
    children: [
      CompanySectionTitleWidget(titleTxt: 'Jobs'),
      SizedBox(height: 16.0),
      UnifiedCard.standard(
        userRole: UserRole.company,
        padding: EdgeInsets.all(16.0),
        child: JobsContent(),
      ),
    ],
  ),
)
```

### After (CompanyLayoutTokens)

```dart
// ✅ NEW: Standardized and consistent
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Jobs',
  content: JobsContent(),
)
```

## 🔄 Integration with Existing Components

### With UnifiedCard.standard()

```dart
// Automatic integration - no changes needed
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Applications',
  content: ApplicationsList(),
  // Uses UnifiedCard.standard() internally with UserRole.company
)
```

### With CompanySectionTitleWidget

```dart
// Seamless integration with existing title widget
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Revenue Metrics',
  subtitle: 'View Details',
  onTap: () => _showRevenueDetails(),
  content: RevenueChart(),
  // Uses CompanySectionTitleWidget internally
)
```

## 🎯 Usage Patterns by Page

### 1. Company Dashboard Main

```dart
// Overview section
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Overzicht',
  content: QuickStatsWidget(),
)

// Active jobs section with navigation
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Actieve Jobs',
  subtitle: 'Beheer Jobs',
  onTap: () => _navigateToJobsScreen(),
  content: ActiveJobsOverview(),
)
```

### 2. Jobs Management Page

```dart
// Job posting section
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Job Management',
  subtitle: 'Nieuwe Job',
  onTap: () => _navigateToJobPostingForm(),
  content: JobManagementCard(),
)
```

### 3. Applications Page

```dart
// Applications overview
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Sollicitaties Beheer',
  subtitle: 'Filter & Zoek',
  onTap: () => _showApplicationFilters(),
  content: ApplicationsManagementCard(),
)
```

## 🔧 Customization Options

### Custom Padding

```dart
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Custom Section',
  content: YourWidget(),
  cardPadding: EdgeInsets.all(DesignTokens.spacingL), // 24px instead of default 16px
)
```

### Custom Margin

```dart
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Custom Section',
  content: YourWidget(),
  margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXL), // 32px horizontal
)
```

### Without Card Wrapper

```dart
CompanyLayoutTokens.buildStandardSection(
  context: context,
  title: 'Plain Content',
  content: YourWidget(),
  showCard: false, // No UnifiedCard wrapper
)
```

## ✅ Best Practices

1. **Always use CompanyLayoutTokens** instead of hardcoded EdgeInsets
2. **Use buildStandardSection()** for most layout needs
3. **Leverage spacing helpers** for consistent element spacing
4. **Customize only when necessary** - defaults work for 90% of cases
5. **Test with all company dashboard pages** to ensure consistency

## 🚀 Performance Benefits

- **Reduced widget tree depth** - Optimized layout builders
- **Consistent memory usage** - Reused spacing constants
- **Faster development** - Pre-built layout patterns
- **Easier maintenance** - Single source of truth for all spacing

## 📊 Coverage

This utility class standardizes layouts across:
- ✅ Company Dashboard Main (5 sections)
- ✅ Jobs Management Page (3 sections)
- ✅ Applications Page (4 sections)
- ✅ Settings Page (6 sections)
- ✅ Profile Page (3 sections)

**Total**: 21 standardized sections across all company dashboard pages.
