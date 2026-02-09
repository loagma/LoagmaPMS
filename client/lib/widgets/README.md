# UI Consistency Guidelines

This document outlines the consistent UI components and patterns used across the Loagma PMS Flutter application.

## Common Widgets

All reusable UI components are defined in `common_widgets.dart` to ensure consistency across the app.

### ModuleAppBar
Standardized AppBar for all module screens with consistent styling.

**Features:**
- Primary brand color background
- White text and icons
- Optional subtitle support
- Consistent back button behavior
- Support for action buttons

**Usage:**
```dart
ModuleAppBar(
  title: 'Bill of Materials',
  subtitle: 'Loagma',
  onBackPressed: () => Get.back(),
  actions: [
    IconButton(
      icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
      onPressed: () { /* ... */ },
    ),
  ],
)
```

### ContentCard
Consistent card wrapper for content sections with elevation and border styling.

**Features:**
- Consistent elevation and shadow
- Primary color border
- Optional title with action button
- Customizable padding

**Usage:**
```dart
ContentCard(
  title: 'BOM Details',
  titleAction: TextButton.icon(...),
  child: Column(
    children: [
      // Your content here
    ],
  ),
)
```

### EmptyState
Standardized empty state widget with icon, message, and optional action.

**Features:**
- Consistent styling with brand colors
- Icon with background
- Message text
- Optional action button

**Usage:**
```dart
EmptyState(
  icon: Icons.inventory_2_outlined,
  message: 'No raw materials added yet.',
  actionLabel: 'Add Material',
  onAction: () => controller.addRawMaterial(),
)
```

### ActionButtonBar
Consistent bottom action button bar with multiple button support.

**Features:**
- Fixed bottom positioning
- Shadow for elevation
- Safe area support
- Automatic spacing between buttons

**Usage:**
```dart
ActionButtonBar(
  buttons: [
    ActionButton(
      label: 'Cancel',
      onPressed: () => Get.back(),
    ),
    ActionButton(
      label: 'Save',
      isPrimary: true,
      isLoading: controller.isSaving.value,
      onPressed: () => controller.save(),
    ),
  ],
)
```

### ActionButton
Individual button component for use in ActionButtonBar.

**Properties:**
- `label`: Button text
- `onPressed`: Callback function
- `isPrimary`: Boolean for primary/outlined style
- `isLoading`: Shows loading indicator
- `backgroundColor`: Optional custom color

### AppInputDecoration
Standardized input field decoration.

**Usage:**
```dart
TextFormField(
  decoration: AppInputDecoration.standard(
    labelText: 'BOM Version *',
    hintText: 'e.g., v1.0',
  ),
)
```

## Color Palette

All colors are defined in `theme/app_colors.dart`:

- **Primary Colors**: `primary`, `primaryLight`, `primaryLighter`, `primaryDark`, `primaryDarker`
- **Surfaces**: `background`, `surface`
- **Text**: `textDark`, `textMuted`

## Spacing Guidelines

- Card padding: `16px`
- Section spacing: `16px`
- Input field spacing: `16px`
- Button spacing: `12px`
- Content max width: `600px` on larger screens

## Typography

- **AppBar Title**: 18px, w600, white
- **AppBar Subtitle**: 12px, w400, white70
- **Card Title**: 16px, w600, primaryDark
- **Body Text**: 14px, w500
- **Muted Text**: 14px, w500, textMuted

## Best Practices

1. Always use `ModuleAppBar` for module screens
2. Wrap content sections in `ContentCard`
3. Use `EmptyState` for empty lists/collections
4. Use `ActionButtonBar` for bottom action buttons
5. Use `AppInputDecoration.standard()` for all form fields
6. Use `initialValue` instead of deprecated `value` in DropdownButtonFormField
7. Maintain consistent spacing using the guidelines above
8. Always include subtitle 'Loagma' in module AppBars for branding
