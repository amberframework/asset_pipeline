---
name: android-compose-components
description: |
  Complete catalog of Android Jetpack Compose and Material Design 3 components.
  Covers M3 Expressive (2025), gesture system, graphics/drawing, navigation patterns,
  theming, and mapping guidance for Crystal cross-platform UI integration via JNI.
user-invocable: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch
version: "1.0.0"
---

# Android Jetpack Compose / Material 3 Components Reference

This document is the authoritative reference for Android Jetpack Compose and Material
Design 3 UI components as of 2025 (compose-material3 1.4.0 stable, 1.5.x alpha series).
It covers Material 3 Expressive, the full gesture system, Canvas/graphics APIs, adaptive
navigation, theming tokens, and platform-specific Android APIs. It provides implementation
priority guidance for the asset_pipeline Crystal library's `Android::Renderer` (JNI bridge).

The asset_pipeline maps Crystal `UI::View` types to native Android elements at compile
time. The `Android::Renderer` (in `src/ui/renderers/android_renderer.cr`) calls through
the JNI bridge (`jni_bridge.c`) to Kotlin/Java, which creates the actual View or Composable
objects. The JNI collection bridge (`src/ui/native/jni_collections.cr`) provides typed
wrappers for JNI references, ViewGroup batch operations, and string marshaling.

---

## 1. Overview

### Material Design 3 and M3 Expressive

Material Design 3 (M3) is the current Google design system, launched alongside Android 12
(Material You). As of 2025 the system has evolved into M3 Expressive, announced at
Google I/O 2025, which adds:

- Five new component families: ButtonGroup, SplitButtonLayout, FloatingActionButtonMenu,
  LoadingIndicator/WavyProgressIndicator, and Floating Toolbars
- 35 new shape definitions and shape-morphing animations
- A physics-based spring motion system replacing fixed easing curves
- Enhanced typography expressiveness
- Research backed by 46 studies and 18,000+ participants

The Jetpack Compose implementation ships in `androidx.compose.material3` (latest stable
1.4.0, released September 24 2025). Experimental and expressive APIs continue in the
1.5.x alpha series.

### Jetpack Compose vs Traditional Android Views

| Aspect | Jetpack Compose | Traditional Android Views |
|--------|----------------|--------------------------|
| Paradigm | Declarative (describe what, not how) | Imperative (XML + Java/Kotlin mutations) |
| State | `State<T>`, `MutableState<T>`, `remember {}` | ViewModel + LiveData/StateFlow observers |
| Layout | Compose layout pass (intrinsics-based) | Measure/layout/draw pass on View hierarchy |
| Thread | Main thread, coroutines for side effects | Main thread for UI; background via Handler |
| Styling | Modifier chains, MaterialTheme | XML attributes, style resources, themes |
| Crystal JNI | Lower priority — hard to drive from native | Higher priority — `jobject` ViewGroup refs |

### Crystal Integration: JNI Bridge Pattern

```
Crystal UI::View tree
        |
        v
Android::Renderer (src/ui/renderers/android_renderer.cr)
  visit(label) / visit(button) / ...
        |
        v  [Crystal -> C via @[Link] fun declarations]
jni_bridge.c (C wrapper functions)
        |
        v  [C -> JVM via JNIEnv* calls]
Kotlin/Java Activity or Fragment
  - Inflates Views or creates Composables
  - Returns jobject back to C
        |
        v  [back to Crystal]
NativeHandle (UI::JNI.global(env, local_ref))
  stored in NativeView node
```

The JNI collection bridge (`src/ui/native/jni_collections.cr`) provides:
- `UI::JNI::JString` — Crystal String <-> jstring marshaling
- `UI::JNI::ObjectArray` — Crystal Array <-> jobjectArray
- `UI::JNI::ArrayList` — Crystal Array <-> java.util.ArrayList
- `UI::JNI.viewgroup_add_views(env, parent, children)` — batch addView()
- `UI::JNI.local_frame(env, capacity)` — scoped local reference tables

**Critical JNI rule:** Local refs are only valid within the current native method call.
Use `UI::JNI.global(env, local_ref)` to promote any View reference that Crystal must
hold past the return boundary, then `NativeHandle` tracks the lifetime.

### API Level Requirements Summary

| Feature | Min API |
|---------|---------|
| All Compose basics | 21 (Android 5.0) |
| Dynamic Color (Material You) | 31 (Android 12) |
| RenderEffect / blur | 31 (Android 12) |
| RuntimeShader / AGSL | 33 (Android 13) |
| Predictive back gesture | 34 (Android 14) |
| Compose BOM 2024+ | 21 |
| WideNavigationRail | 21 (M3 Expressive, lib-based) |
| FloatingActionButtonMenu | 21 (M3 Expressive, lib-based) |
| WavyLinearProgressIndicator | 21 (M3 Expressive, lib-based) |
| Picture-in-Picture | 26 (Android 8.0) |
| Glance Widgets | 23 (Android 6.0) |

---

## 2. Material 3 Components by Category

All components require:
```kotlin
implementation("androidx.compose.material3:material3:1.4.0")
```

Experimental APIs require `@OptIn(ExperimentalMaterial3Api::class)`.
Expressive APIs (1.5.x alpha) additionally require `@OptIn(ExperimentalMaterial3ExpressiveApi::class)`.

---

### 2.1 Buttons and FABs

#### Standard Buttons

| Compose Function | Emphasis | Traditional View | Crystal UI::View Equiv. | Priority |
|-----------------|----------|-----------------|------------------------|----------|
| `Button` | High — filled, primary color | `MaterialButton` | `UI::Button` (maps here) | P0 (done) |
| `FilledButton` | High — alias for Button | `MaterialButton` | Same as Button | P0 |
| `ElevatedButton` | Medium — elevated surface | `MaterialButton` (elevation style) | — | P1 |
| `FilledTonalButton` | Medium — secondary container fill | `MaterialButton` (tonal style) | — | P1 |
| `OutlinedButton` | Low — bordered, transparent fill | `MaterialButton` (outlined style) | — | P1 |
| `TextButton` | Lowest — text only | `MaterialButton` (text style) | — | P2 |

All button parameters:
```kotlin
Button(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    shape: Shape = ButtonDefaults.shape,           // RoundedCornerShape(50%) by default
    colors: ButtonColors = ButtonDefaults.buttonColors(),
    elevation: ButtonElevation? = ButtonDefaults.buttonElevation(),
    border: BorderStroke? = null,
    contentPadding: PaddingValues = ButtonDefaults.ContentPadding,
    interactionSource: MutableInteractionSource? = null,
    content: @Composable RowScope.() -> Unit
)
```

#### Icon Buttons

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `IconButton` | `ImageButton` | P1 |
| `FilledIconButton` | `MaterialButton` (icon, filled) | P2 |
| `FilledTonalIconButton` | `MaterialButton` (icon, tonal) | P2 |
| `OutlinedIconButton` | `MaterialButton` (icon, outlined) | P2 |
| `IconToggleButton` | `ImageButton` + toggle state | P2 |

#### Floating Action Buttons (FABs)

| Compose Function | Size | Traditional View | Priority |
|-----------------|------|-----------------|----------|
| `FloatingActionButton` | Standard (56dp) | `FloatingActionButton` | P1 |
| `SmallFloatingActionButton` | Small (40dp) | `FloatingActionButton` (mini) | P2 |
| `LargeFloatingActionButton` | Large (96dp) | `FloatingActionButton` (large) | P2 |
| `ExtendedFloatingActionButton` | Pill with text | `ExtendedFloatingActionButton` | P2 |

FAB parameters:
```kotlin
FloatingActionButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = FloatingActionButtonDefaults.shape,
    containerColor: Color = FloatingActionButtonDefaults.containerColor,
    contentColor: Color = contentColorFor(containerColor),
    elevation: FloatingActionButtonElevation = FloatingActionButtonDefaults.elevation(),
    interactionSource: MutableInteractionSource? = null,
    content: @Composable () -> Unit
)
```

#### NEW: M3 Expressive Button Components (1.4.x / 1.5.x-alpha)

| Compose Function | Description | Traditional View Equiv. | Priority |
|-----------------|-------------|------------------------|----------|
| `ButtonGroup` | Horizontal or vertical group of semantically related buttons with connected styling | `LinearLayout` of `MaterialButton` | P2 |
| `SplitButtonLayout` | Two-zone button: action zone + dropdown trigger zone | Custom compound `MaterialButton` | P2 |
| `FloatingActionButtonMenu` | FAB that expands into a menu of secondary actions | Custom `CoordinatorLayout` pattern | P2 |
| `ToggleFloatingActionButton` | FAB with toggled (expanded/collapsed) state, used as anchor for FABMenu | `FloatingActionButton` | P2 |
| `FloatingActionButtonMenuItem` | Individual item inside a FABMenu | `MaterialButton` in overlay | P2 |

```kotlin
// ButtonGroup usage (M3 Expressive)
ButtonGroup(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = ButtonGroupDefaults.horizontalArrangement,
    verticalAlignment: Alignment.Vertical = Alignment.CenterVertically,
    content: @Composable ButtonGroupScope.() -> Unit
)

// Inside ButtonGroupScope, use Modifier.align() per-button

// FloatingActionButtonMenu usage
FloatingActionButtonMenu(
    expanded: Boolean,
    button: @Composable () -> Unit,   // Typically a ToggleFloatingActionButton
    modifier: Modifier = Modifier,
    content: @Composable FloatingActionButtonMenuScope.() -> Unit
) {
    FloatingActionButtonMenuItem(
        onClick = { /* action */ },
        icon = { Icon(Icons.Default.Share, contentDescription = null) },
        text = { Text("Share") }
    )
}
```

---

### 2.2 Selection Controls

#### Checkbox

| Compose Function | Traditional View | Parameters | Priority |
|-----------------|-----------------|------------|----------|
| `Checkbox` | `CheckBox` | `checked`, `onCheckedChange`, `enabled`, `colors` | P1 |
| `TriStateCheckbox` | `CheckBox` (partial state) | `state: ToggleableState`, `onClick`, `enabled`, `colors` | P2 |

```kotlin
Checkbox(
    checked: Boolean,
    onCheckedChange: ((Boolean) -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    colors: CheckboxColors = CheckboxDefaults.colors(),
    interactionSource: MutableInteractionSource? = null
)
```

#### RadioButton

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `RadioButton` | `RadioButton` | P1 |

RadioButton has no built-in group; you track selection state in the parent composable.
Traditional equivalent for a group: `RadioGroup` containing `RadioButton` views.

```kotlin
RadioButton(
    selected: Boolean,
    onClick: (() -> Unit)?,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    colors: RadioButtonColors = RadioButtonDefaults.colors()
)
```

#### Switch

| Compose Function | Traditional View | Crystal UI::View Equiv. | Priority |
|-----------------|-----------------|------------------------|----------|
| `Switch` | `SwitchCompat` / `MaterialSwitch` | — | P1 |

```kotlin
Switch(
    checked: Boolean,
    onCheckedChange: ((Boolean) -> Unit)?,
    modifier: Modifier = Modifier,
    thumbContent: (@Composable () -> Unit)? = null,  // Icon inside thumb
    enabled: Boolean = true,
    colors: SwitchColors = SwitchDefaults.colors(),
    interactionSource: MutableInteractionSource? = null
)
```

#### Chips

All chips require `@OptIn(ExperimentalMaterial3Api::class)`.

| Compose Function | Use Case | Traditional View | Priority |
|-----------------|----------|-----------------|----------|
| `AssistChip` | Suggest actions (non-selectable) | `Chip` (action chip style) | P2 |
| `FilterChip` | Toggle-able filter selection | `Chip` (filter chip style) | P2 |
| `InputChip` | Represent user input (tags, tokens) | `Chip` (entry chip style) | P2 |
| `SuggestionChip` | Auto-complete suggestions | `Chip` (suggestion style) | P3 |
| `ElevatedAssistChip` | Elevated variant of AssistChip | `Chip` elevated | P3 |
| `ElevatedFilterChip` | Elevated variant of FilterChip | `Chip` elevated | P3 |
| `ElevatedSuggestionChip` | Elevated variant | `Chip` elevated | P3 |

```kotlin
FilterChip(
    selected: Boolean,
    onClick: () -> Unit,
    label: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    leadingIcon: (@Composable () -> Unit)? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
    shape: Shape = FilterChipDefaults.shape,
    colors: SelectableChipColors = FilterChipDefaults.filterChipColors(),
    elevation: SelectableChipElevation? = FilterChipDefaults.filterChipElevation(),
    border: BorderStroke? = FilterChipDefaults.filterChipBorder(enabled, selected)
)
```

#### SegmentedButton

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `SingleChoiceSegmentedButtonRow` | Custom `MaterialButton` group | P2 |
| `MultiChoiceSegmentedButtonRow` | Custom `MaterialButton` group | P2 |
| `SegmentedButton` | Individual segment within row | `MaterialButton` | P2 |

```kotlin
SingleChoiceSegmentedButtonRow {
    options.forEachIndexed { index, label ->
        SegmentedButton(
            shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size),
            onClick = { selectedIndex = index },
            selected = index == selectedIndex,
            label = { Text(label) }
        )
    }
}
```

---

### 2.3 Text Input

#### TextField and OutlinedTextField

| Compose Function | Traditional View | Crystal UI::View Equiv. | Priority |
|-----------------|-----------------|------------------------|----------|
| `TextField` | `TextInputEditText` (filled style) | `UI::TextField` (maps here) | P0 (done) |
| `OutlinedTextField` | `TextInputEditText` (outlined style) | — | P1 |
| `BasicTextField` | `EditText` (no Material decoration) | — | P1 |
| `SecureTextField` (1.4.0) | `TextInputEditText` (password) | — | P2 |
| `OutlinedSecureTextField` (1.4.0) | `TextInputEditText` (password, outlined) | — | P2 |

```kotlin
TextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    readOnly: Boolean = false,
    textStyle: TextStyle = LocalTextStyle.current,
    label: (@Composable () -> Unit)? = null,
    placeholder: (@Composable () -> Unit)? = null,
    leadingIcon: (@Composable () -> Unit)? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
    prefix: (@Composable () -> Unit)? = null,
    suffix: (@Composable () -> Unit)? = null,
    supportingText: (@Composable () -> Unit)? = null,
    isError: Boolean = false,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    singleLine: Boolean = false,
    maxLines: Int = if (singleLine) 1 else Int.MAX_VALUE,
    minLines: Int = 1,
    interactionSource: MutableInteractionSource? = null,
    shape: Shape = TextFieldDefaults.shape,
    colors: TextFieldColors = TextFieldDefaults.colors()
)

// SecureTextField (1.4.0) — password-only, single line only
SecureTextField(
    state: TextFieldState,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    textObfuscationMode: TextObfuscationMode = TextObfuscationMode.RevealLastTyped,
    textObfuscationCharacter: Char = '\u2022',  // bullet
    keyboardOptions: KeyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
    onKeyboardAction: KeyboardActionHandler? = null,
    shape: Shape = TextFieldDefaults.shape,
    colors: TextFieldColors = TextFieldDefaults.colors(),
    interactionSource: MutableInteractionSource? = null
)
```

#### SearchBar

| Compose Function | Description | Traditional View | Priority |
|-----------------|-------------|-----------------|----------|
| `SearchBar` | Compact search input bar | `SearchView` | P2 |
| `DockedSearchBar` | Search bar anchored to top of screen | `SearchView` | P2 |
| `ExpandedFullScreenSearchBar` (1.4.0) | Full-screen search overlay | `SearchView` full-screen | P3 |
| `ExpandedDockedSearchBar` (1.4.0) | Docked expanded search view | `SearchView` | P3 |

```kotlin
SearchBar(
    inputField: @Composable SearchBarScope.() -> Unit,
    expanded: Boolean,
    onExpandedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    shape: Shape = SearchBarDefaults.inputFieldShape,
    colors: SearchBarColors = SearchBarDefaults.colors(),
    tonalElevation: Dp = SearchBarDefaults.TonalElevation,
    shadowElevation: Dp = SearchBarDefaults.ShadowElevation,
    windowInsets: WindowInsets = SearchBarDefaults.windowInsets,
    content: @Composable ColumnScope.() -> Unit
)
```

---

### 2.4 Progress Indicators

| Compose Function | Indeterminate | Traditional View | Crystal UI::View Equiv. | Priority |
|-----------------|---------------|-----------------|------------------------|----------|
| `LinearProgressIndicator` | Yes (no value param) | `LinearProgressIndicator` | — | P1 |
| `CircularProgressIndicator` | Yes (no value param) | `CircularProgressIndicator` | — | P1 |
| `WavyLinearProgressIndicator` (M3 Exp.) | Yes | Custom animated view | — | P2 |
| `WavyCircularProgressIndicator` (M3 Exp.) | Yes | Custom animated view | — | P2 |
| `LoadingIndicator` (M3 Exp.) | Always indeterminate | Custom animated view | — | P2 |

```kotlin
// Determinate (0.0 to 1.0)
LinearProgressIndicator(
    progress: () -> Float,
    modifier: Modifier = Modifier,
    color: Color = LinearProgressIndicatorDefaults.indicatorColor,
    trackColor: Color = LinearProgressIndicatorDefaults.trackColor,
    strokeCap: StrokeCap = LinearProgressIndicatorDefaults.LinearStrokeCap,
    gapSize: Dp = LinearProgressIndicatorDefaults.LinearIndicatorTrackGapSize,
    drawStopIndicator: DrawScope.() -> Unit = { ... }
)

// Indeterminate (no progress param)
CircularProgressIndicator(
    modifier: Modifier = Modifier,
    color: Color = CircularProgressIndicatorDefaults.indicatorColor,
    strokeWidth: Dp = CircularProgressIndicatorDefaults.StrokeWidth,
    trackColor: Color = CircularProgressIndicatorDefaults.trackColor,
    strokeCap: StrokeCap = CircularProgressIndicatorDefaults.IndeterminateCircularStrokeCap
)

// Wavy variants (M3 Expressive)
WavyLinearProgressIndicator(
    progress: () -> Float,    // or no param for indeterminate
    modifier: Modifier = Modifier,
    color: Color = WavyProgressIndicatorDefaults.indicatorColor,
    trackColor: Color = WavyProgressIndicatorDefaults.trackColor,
    amplitude: Dp = WavyProgressIndicatorDefaults.amplitude,
    wavelength: Dp = WavyProgressIndicatorDefaults.wavelength,
    waveSpeed: Dp = WavyProgressIndicatorDefaults.waveSpeed
)
```

#### Badge

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `Badge` | Custom drawable / overlay | P2 |
| `BadgedBox` | Custom ViewGroup with badge overlay | P2 |

```kotlin
BadgedBox(
    badge: @Composable BoxScope.() -> Unit,  // Badge() goes here
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit
)
Badge(
    modifier: Modifier = Modifier,
    containerColor: Color = BadgeDefaults.containerColor,
    contentColor: Color = contentColorFor(containerColor),
    content: (@Composable RowScope.() -> Unit)? = null  // null = dot badge; text = count badge
)
```

---

### 2.5 Dialogs and Sheets

#### Dialogs

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `AlertDialog` | `MaterialAlertDialog` | P1 |
| `BasicAlertDialog` | `AlertDialog.Builder` | P2 |

```kotlin
AlertDialog(
    onDismissRequest: () -> Unit,
    confirmButton: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    dismissButton: (@Composable () -> Unit)? = null,
    icon: (@Composable () -> Unit)? = null,
    title: (@Composable () -> Unit)? = null,
    text: (@Composable () -> Unit)? = null,
    shape: Shape = AlertDialogDefaults.shape,
    containerColor: Color = AlertDialogDefaults.containerColor,
    iconContentColor: Color = AlertDialogDefaults.iconContentColor,
    titleContentColor: Color = AlertDialogDefaults.titleContentColor,
    textContentColor: Color = AlertDialogDefaults.textContentColor,
    tonalElevation: Dp = AlertDialogDefaults.TonalElevation,
    properties: DialogProperties = DialogProperties()
)
```

#### Bottom Sheets

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `ModalBottomSheet` | `BottomSheetDialog` | P1 |
| `BottomSheetScaffold` | `CoordinatorLayout` + `BottomSheetBehavior` | P2 |

```kotlin
ModalBottomSheet(
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    sheetState: SheetState = rememberModalBottomSheetState(),
    sheetMaxWidth: Dp = BottomSheetDefaults.SheetMaxWidth,
    shape: Shape = BottomSheetDefaults.ExpandedShape,
    containerColor: Color = BottomSheetDefaults.ContainerColor,
    contentColor: Color = contentColorFor(containerColor),
    tonalElevation: Dp = BottomSheetDefaults.Elevation,
    scrimColor: Color = BottomSheetDefaults.ScrimColor,
    dragHandle: (@Composable () -> Unit)? = { BottomSheetDefaults.DragHandle() },
    contentWindowInsets: @Composable () -> WindowInsets = { ... },
    properties: ModalBottomSheetProperties = ModalBottomSheetDefaults.properties,
    content: @Composable ColumnScope.() -> Unit
)

// VerticalDragHandle (1.4.0) — visual drag indicator for bottom sheets
VerticalDragHandle(modifier: Modifier = Modifier)
```

---

### 2.6 Date and Time Pickers

All picker APIs require `@OptIn(ExperimentalMaterial3Api::class)`.

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `DatePicker` | `MaterialDatePicker` | P2 |
| `DateRangePicker` | `MaterialDateRangePicker` | P2 |
| `DatePickerDialog` | `MaterialDatePicker` in Dialog | P2 |
| `TimePicker` | `MaterialTimePicker` (clock face) | P2 |
| `TimeInput` | `MaterialTimePicker` (text input) | P2 |
| `TimePickerDialog` (1.4.0) | `MaterialTimePicker` wrapper | P2 |

```kotlin
val datePickerState = rememberDatePickerState()

DatePickerDialog(
    onDismissRequest = { },
    confirmButton = { Button(onClick = { }) { Text("OK") } },
    dismissButton = { TextButton(onClick = { }) { Text("Cancel") } }
) {
    DatePicker(state = datePickerState)
}

// DatePickerState
// datePickerState.selectedDateMillis -> Long? (UTC epoch ms)
// datePickerState.displayedMonthMillis -> Long

val timePickerState = rememberTimePickerState(initialHour = 12, initialMinute = 0)

TimePickerDialog(
    onDismissRequest = { },
    onConfirm = { hour, minute -> }   // TimePickerDialog is 1.4.0+
) {
    TimePicker(state = timePickerState)
    // or TimeInput(state = timePickerState) for keyboard input
}
```

---

### 2.7 Navigation Components

#### Bottom Navigation Bar

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `NavigationBar` | `BottomNavigationView` | P1 |
| `NavigationBarItem` | Menu item within BottomNavigationView | P1 |

```kotlin
NavigationBar(
    modifier: Modifier = Modifier,
    containerColor: Color = NavigationBarDefaults.containerColor,
    contentColor: Color = MaterialTheme.colorScheme.contentColorFor(containerColor),
    tonalElevation: Dp = NavigationBarDefaults.Elevation,
    windowInsets: WindowInsets = NavigationBarDefaults.windowInsets,
    content: @Composable RowScope.() -> Unit
) {
    NavigationBarItem(
        selected: Boolean,
        onClick: () -> Unit,
        icon: @Composable () -> Unit,
        modifier: Modifier = Modifier,
        enabled: Boolean = true,
        label: (@Composable () -> Unit)? = null,
        alwaysShowLabel: Boolean = true,
        colors: NavigationBarItemColors = NavigationBarItemDefaults.colors(),
        interactionSource: MutableInteractionSource? = null
    )
}
```

#### Navigation Rail

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `NavigationRail` | `NavigationRailView` | P2 |
| `NavigationRailItem` | Menu item within NavigationRailView | P2 |
| `WideNavigationRail` (M3 Exp.) | Custom side panel | P2 |
| `WideNavigationRailItem` (M3 Exp.) | Item within WideNavigationRail | P2 |

NavigationRail is for medium/expanded screens (tablets, landscape phones).
WideNavigationRail (M3 Expressive) is a wider modal drawer-style rail with optional header.

```kotlin
NavigationRail(
    modifier: Modifier = Modifier,
    containerColor: Color = NavigationRailDefaults.ContainerColor,
    contentColor: Color = contentColorFor(containerColor),
    header: (@Composable ColumnScope.() -> Unit)? = null,
    windowInsets: WindowInsets = NavigationRailDefaults.windowInsets,
    content: @Composable ColumnScope.() -> Unit
)
```

#### Navigation Drawers

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `ModalNavigationDrawer` | `DrawerLayout` + `NavigationView` | P2 |
| `PermanentNavigationDrawer` | Permanent side NavigationView | P3 |
| `DismissibleNavigationDrawer` | Dismissible side NavigationView | P3 |
| `NavigationDrawerItem` | Item within drawer | P2 |

```kotlin
val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)

ModalNavigationDrawer(
    drawerContent = {
        ModalDrawerSheet {
            NavigationDrawerItem(
                label = { Text("Home") },
                selected = currentRoute == "home",
                onClick = { /* navigate */ },
                icon = { Icon(Icons.Default.Home, contentDescription = null) }
            )
        }
    },
    drawerState = drawerState,
    content = { /* main content */ }
)
```

#### Adaptive Navigation (NavigationSuiteScaffold)

Requires additional dependency:
```kotlin
implementation("androidx.compose.material3:material3-adaptive-navigation-suite:1.5.0-alpha14")
```

| Compose Function | Behavior | Priority |
|-----------------|----------|----------|
| `NavigationSuiteScaffold` | Auto-selects NavigationBar/Rail/Drawer based on WindowSizeClass | P2 |

```kotlin
NavigationSuiteScaffold(
    navigationSuiteItems = {
        destinations.forEach { dest ->
            item(
                icon = { Icon(dest.icon, contentDescription = null) },
                label = { Text(dest.label) },
                selected = currentDest == dest,
                onClick = { currentDest = dest }
            )
        }
    },
    content = { /* screen content */ }
)
// On compact: shows NavigationBar (bottom)
// On medium/expanded: shows NavigationRail (side)
```

#### NEW: ShortNavigationBar (M3 Expressive, 1.5.x)

A condensed navigation bar with icon-only items (no label), suitable for tight spaces.
Traditional equivalent: custom `BottomNavigationView` with icon-only items.

#### Tabs

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `TabRow` | `TabLayout` (fixed) | P2 |
| `ScrollableTabRow` | `TabLayout` (scrollable) | P2 |
| `Tab` | Tab within TabLayout | P2 |
| `LeadingIconTab` | Tab with leading icon | P2 |
| `SecondaryTabRow` | Secondary-style tabs (M3 indicator style) | P3 |

```kotlin
TabRow(selectedTabIndex = selectedTab) {
    tabs.forEachIndexed { index, title ->
        Tab(
            selected = selectedTab == index,
            onClick = { selectedTab = index },
            text = { Text(title) }
        )
    }
}
```

---

### 2.8 Top App Bars

All top app bar APIs require `@OptIn(ExperimentalMaterial3Api::class)`.

| Compose Function | Collapse | Traditional View | Priority |
|-----------------|---------|-----------------|----------|
| `TopAppBar` | No | `MaterialToolbar` | P1 |
| `CenterAlignedTopAppBar` | No | `MaterialToolbar` (centered) | P2 |
| `MediumTopAppBar` | Yes (title collapses to small) | `CollapsingToolbarLayout` (medium) | P2 |
| `LargeTopAppBar` | Yes (large title collapses) | `CollapsingToolbarLayout` (large) | P2 |

```kotlin
TopAppBar(
    title: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    navigationIcon: @Composable () -> Unit = {},
    actions: @Composable RowScope.() -> Unit = {},
    expandedHeight: Dp = TopAppBarDefaults.TopAppBarExpandedHeight,
    windowInsets: WindowInsets = TopAppBarDefaults.windowInsets,
    colors: TopAppBarColors = TopAppBarDefaults.topAppBarColors(),
    scrollBehavior: TopAppBarScrollBehavior? = null
)

// Collapsing toolbar usage
val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
LargeTopAppBar(
    title = { Text("Screen Title") },
    scrollBehavior = scrollBehavior
)
// + Modifier.nestedScroll(scrollBehavior.nestedScrollConnection) on the body
```

#### NEW: Floating Toolbars (M3 Expressive)

| Compose Function | Description | Traditional View | Priority |
|-----------------|-------------|-----------------|----------|
| `HorizontalFloatingToolbar` | Floating pill-shaped toolbar (horizontal) | Custom overlay view | P2 |
| `VerticalFloatingToolbar` | Floating pill-shaped toolbar (vertical) | Custom overlay view | P2 |
| `FlexibleBottomAppBar` | Bottom bar with flexible layout | `BottomAppBar` | P2 |

```kotlin
HorizontalFloatingToolbar(
    expanded: Boolean,
    modifier: Modifier = Modifier,
    floatingActionButton: (@Composable () -> Unit)? = null,  // Attached FAB
    colors: FloatingToolbarColors = FloatingToolbarDefaults.standardFloatingToolbarColors(),
    content: @Composable RowScope.() -> Unit
)
```

---

### 2.9 Cards

| Compose Function | Elevation Style | Traditional View | Crystal UI::View Equiv. | Priority |
|-----------------|----------------|-----------------|------------------------|----------|
| `Card` | Filled (no elevation by default) | `MaterialCardView` | — | P2 |
| `ElevatedCard` | Elevated (with shadow) | `MaterialCardView` (elevated style) | — | P2 |
| `OutlinedCard` | Outlined border | `MaterialCardView` (outlined style) | — | P2 |

```kotlin
Card(
    modifier: Modifier = Modifier,
    shape: Shape = CardDefaults.shape,
    colors: CardColors = CardDefaults.cardColors(),
    elevation: CardElevation = CardDefaults.cardElevation(),
    border: BorderStroke? = null,
    content: @Composable ColumnScope.() -> Unit
)

// Clickable card — wrap with onClick
Card(onClick = { /* action */ }, ...) { ... }
```

---

### 2.10 Lists and Lazy Collections

#### ListItem

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `ListItem` | `MaterialListItem` / custom layout | P1 |

```kotlin
ListItem(
    headlineContent: @Composable () -> Unit,
    modifier: Modifier = Modifier,
    overlineContent: (@Composable () -> Unit)? = null,
    supportingContent: (@Composable () -> Unit)? = null,   // makes it 2-line
    leadingContent: (@Composable () -> Unit)? = null,
    trailingContent: (@Composable () -> Unit)? = null,
    colors: ListItemColors = ListItemDefaults.colors(),
    tonalElevation: Dp = ListItemDefaults.Elevation,
    shadowElevation: Dp = ListItemDefaults.Elevation
)
```

#### Lazy Collections (foundation, not material3)

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `LazyColumn` | `RecyclerView` (vertical) | P1 |
| `LazyRow` | `RecyclerView` (horizontal) | P1 |
| `LazyVerticalGrid` | `RecyclerView` (GridLayoutManager) | P2 |
| `LazyHorizontalGrid` | `RecyclerView` (horizontal grid) | P2 |
| `LazyVerticalStaggeredGrid` | `RecyclerView` (StaggeredGridLayoutManager) | P2 |
| `LazyHorizontalStaggeredGrid` | `RecyclerView` (horizontal staggered) | P3 |

```kotlin
LazyColumn(
    modifier: Modifier = Modifier,
    state: LazyListState = rememberLazyListState(),
    contentPadding: PaddingValues = PaddingValues(0.dp),
    reverseLayout: Boolean = false,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    horizontalAlignment: Alignment.Horizontal = Alignment.Start,
    flingBehavior: FlingBehavior = ScrollableDefaults.flingBehavior(),
    userScrollEnabled: Boolean = true
) {
    items(itemsList) { item -> ItemComposable(item) }
    item { HeaderComposable() }
    itemsIndexed(list) { index, item -> IndexedItem(index, item) }
}
```

#### Carousel (material3-carousel)

Requires:
```kotlin
implementation("androidx.compose.material3:material3:1.4.0") // carousel included
```

| Compose Function | Style | Priority |
|-----------------|-------|----------|
| `HorizontalMultiBrowseCarousel` | Multiple partially-visible items | P2 |
| `HorizontalUncontainedCarousel` | Full-width scrolling items | P2 |
| `HorizontalCenteredHeroCarousel` (1.4.0) | Hero item centered with peeking items | P2 |

---

### 2.11 Menus and Dropdowns

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `DropdownMenu` | `PopupMenu` | P2 |
| `DropdownMenuItem` | `MenuItem` in PopupMenu | P2 |
| `ExposedDropdownMenuBox` | `AutoCompleteTextView` with `TextInputLayout` | P2 |

```kotlin
var expanded by remember { mutableStateOf(false) }

ExposedDropdownMenuBox(
    expanded = expanded,
    onExpandedChange = { expanded = it }
) {
    TextField(
        value = selectedOption,
        onValueChange = {},
        readOnly = true,
        trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
        modifier = Modifier.menuAnchor()
    )
    ExposedDropdownMenu(
        expanded = expanded,
        onDismissRequest = { expanded = false }
    ) {
        options.forEach { option ->
            DropdownMenuItem(
                text = { Text(option) },
                onClick = { selectedOption = option; expanded = false }
            )
        }
    }
}
```

#### NEW: Expressive Menu Components (1.5.x alpha)

M3 Expressive adds toggleable menu items, selectable menu items with supporting text,
menu groups, and menu popups as distinct first-class components (previously ad-hoc).

---

### 2.12 Sliders

| Compose Function | Traditional View | Crystal UI::View Equiv. | Priority |
|-----------------|-----------------|------------------------|----------|
| `Slider` | `Slider` (from Material) | — | P1 |
| `RangeSlider` | Custom dual-thumb `Slider` | — | P2 |

```kotlin
Slider(
    value: Float,
    onValueChange: (Float) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    onValueChangeFinished: (() -> Unit)? = null,
    colors: SliderColors = SliderDefaults.colors(),
    interactionSource: MutableInteractionSource = remember { MutableInteractionSource() },
    steps: Int = 0,              // 0 = continuous; N = N+1 discrete positions
    thumb: @Composable (SliderState) -> Unit = { SliderDefaults.Thumb(...) },
    track: @Composable (SliderState) -> Unit = { SliderDefaults.Track(...) },
    valueRange: ClosedFloatingPointRange<Float> = 0f..1f
)
```

---

### 2.13 Snackbars and Tooltips

#### Snackbar

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `Snackbar` | `Snackbar` (from Material) | P2 |
| `SnackbarHost` | Manages Snackbar queue + positioning | P2 |

```kotlin
val snackbarHostState = remember { SnackbarHostState() }

Scaffold(snackbarHost = { SnackbarHost(snackbarHostState) }) { padding ->
    // Launch from coroutine
    LaunchedEffect(Unit) {
        snackbarHostState.showSnackbar(
            message = "Item deleted",
            actionLabel = "Undo",
            withDismissAction = true,
            duration = SnackbarDuration.Long
        )
    }
}
```

#### Tooltips

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `PlainTooltip` | Custom popup | P3 |
| `RichTooltip` | Custom popup with title + text | P3 |
| `TooltipBox` | Wrapper that triggers tooltip | P3 |

---

### 2.14 Dividers

| Compose Function | Traditional View | Priority |
|-----------------|-----------------|----------|
| `HorizontalDivider` | `View` with height=1dp | P2 |
| `VerticalDivider` | `View` with width=1dp | P2 |

---

### 2.15 Scaffolding

#### Scaffold

The primary layout container for Material 3 screens.

```kotlin
Scaffold(
    modifier: Modifier = Modifier,
    topBar: @Composable () -> Unit = {},
    bottomBar: @Composable () -> Unit = {},
    snackbarHost: @Composable () -> Unit = {},
    floatingActionButton: @Composable () -> Unit = {},
    floatingActionButtonPosition: FabPosition = FabPosition.End,
    containerColor: Color = MaterialTheme.colorScheme.background,
    contentColor: Color = contentColorFor(containerColor),
    contentWindowInsets: WindowInsets = ScaffoldDefaults.contentWindowInsets,
    content: @Composable (PaddingValues) -> Unit  // PaddingValues accounts for bars
)
```

Traditional View: `CoordinatorLayout` + `AppBarLayout` + `BottomAppBar` + `FloatingActionButton`.

#### Surface

The fundamental building block for Material 3 elevated/colored containers.

```kotlin
Surface(
    modifier: Modifier = Modifier,
    shape: Shape = RectangleShape,
    color: Color = MaterialTheme.colorScheme.surface,
    contentColor: Color = contentColorFor(color),
    tonalElevation: Dp = 0.dp,
    shadowElevation: Dp = 0.dp,
    border: BorderStroke? = null,
    content: @Composable () -> Unit
)
// Clickable Surface variant adds onClick + role params
```

#### Pull to Refresh

| Compose Function | Description | Traditional View | Priority |
|-----------------|-------------|-----------------|----------|
| `PullToRefreshBox` | Box with pull-to-refresh gesture | `SwipeRefreshLayout` | P2 |
| `Modifier.pullToRefresh` | Low-level PTR modifier | SwipeRefreshLayout behavior | P2 |

```kotlin
PullToRefreshBox(
    isRefreshing: Boolean,
    onRefresh: () -> Unit,
    modifier: Modifier = Modifier,
    state: PullToRefreshState = rememberPullToRefreshState(),
    contentAlignment: Alignment = Alignment.TopStart,
    indicator: @Composable BoxScope.() -> Unit = {
        PullToRefreshDefaults.Indicator(state, isRefreshing)
    },
    content: @Composable BoxScope.() -> Unit
)
```

---

## 3. Foundation Components

Requires: `implementation("androidx.compose.foundation:foundation:$compose_version")`

### 3.1 Layout Containers

| Composable | Description | Traditional View |
|-----------|-------------|-----------------|
| `Box` | Stack/overlay layout, like `FrameLayout` | `FrameLayout` |
| `Column` | Vertical linear layout | `LinearLayout(VERTICAL)` |
| `Row` | Horizontal linear layout | `LinearLayout(HORIZONTAL)` |
| `Spacer` | Flexible space | `View` with weight |
| `FlowRow` | Wrapping horizontal layout | `FlexboxLayout` (horizontal) |
| `FlowColumn` | Wrapping vertical layout | `FlexboxLayout` (vertical) |
| `ContextualFlowRow` | FlowRow with maxLines + overflow | FlexboxLayout with clipping |
| `ContextualFlowColumn` | FlowColumn with maxLines + overflow | FlexboxLayout with clipping |

```kotlin
// FlowRow — wrap items onto next line when row fills
FlowRow(
    modifier: Modifier = Modifier,
    horizontalArrangement: Arrangement.Horizontal = Arrangement.Start,
    verticalArrangement: Arrangement.Vertical = Arrangement.Top,
    maxItemsInEachRow: Int = Int.MAX_VALUE,
    maxLines: Int = Int.MAX_VALUE,
    overflow: FlowRowOverflow = FlowRowOverflow.Clip,
    content: @Composable FlowRowScope.() -> Unit
)
```

### 3.2 Text and Image

| Composable | Description | Traditional View |
|-----------|-------------|-----------------|
| `BasicText` | Low-level text (no Material styling) | `TextView` |
| `SelectionContainer` | Makes text inside selectable | `TextView` with `setTextIsSelectable(true)` |
| `BasicTextField` | Low-level editable text | `EditText` |
| `Image` | Bitmap/vector image display | `ImageView` |
| `Icon` | Material icon from painter/vector | `ImageView` |
| `Canvas` | Custom 2D drawing | Custom `View.onDraw()` |
| `AndroidView` | Embed traditional Android View in Compose | — |
| `AndroidViewBinding` | Embed ViewBinding layout in Compose | — |

### 3.3 Interaction Modifiers

| Modifier | Description |
|---------|-------------|
| `Modifier.clickable` | Add tap interaction with ripple |
| `Modifier.combinedClickable` | Tap + double-tap + long-press |
| `Modifier.selectable` | Selectable state (radio group pattern) |
| `Modifier.toggleable` | Toggleable state (checkbox pattern) |
| `Modifier.triStateToggleable` | Three-state toggle |
| `Modifier.focusable` | Keyboard/d-pad focus |
| `Modifier.indication` | Custom press/hover indication |

---

## 4. Layout System

### 4.1 Modifier Chain

Modifiers are the primary way to configure layout, drawing, interaction, and animation
on any composable. Order matters — modifiers are applied inside-out.

```kotlin
Modifier
    .fillMaxSize()                          // size
    .padding(16.dp)                         // spacing (outside)
    .background(Color.White)               // drawing
    .clip(RoundedCornerShape(8.dp))         // clipping
    .border(1.dp, Color.Gray, RoundedCornerShape(8.dp))  // border
    .padding(8.dp)                          // inner spacing
    .clickable { }                          // interaction
```

Common size modifiers:
- `fillMaxSize()`, `fillMaxWidth()`, `fillMaxHeight()`
- `fillMaxSize(fraction)`, `fillMaxWidth(fraction)` — fractional fill
- `size(dp)`, `size(width, height)`, `wrapContentSize()`
- `requiredSize(dp)` — override parent constraints
- `aspectRatio(ratio)`
- `weight(fraction)` — only within Row/Column scope

### 4.2 Arrangement and Alignment

```kotlin
// Column vertical arrangement
Arrangement.Top, Arrangement.Bottom, Arrangement.Center
Arrangement.SpaceEvenly, Arrangement.SpaceBetween, Arrangement.SpaceAround
Arrangement.spacedBy(8.dp)

// Row horizontal arrangement
Arrangement.Start, Arrangement.End, Arrangement.Center
Arrangement.SpaceEvenly, Arrangement.SpaceBetween, Arrangement.SpaceAround
Arrangement.spacedBy(8.dp)

// Alignment (cross-axis)
Alignment.Start, Alignment.End, Alignment.CenterHorizontally   // Column horizontal
Alignment.Top, Alignment.Bottom, Alignment.CenterVertically    // Row vertical
Alignment.Center, Alignment.TopStart, Alignment.BottomEnd      // Box
```

### 4.3 ConstraintLayout

Requires additional dependency:
```kotlin
implementation("androidx.constraintlayout:constraintlayout-compose:1.1.0")
```

```kotlin
ConstraintLayout(modifier = Modifier.fillMaxSize()) {
    val (button, text) = createRefs()

    Button(
        onClick = {},
        modifier = Modifier.constrainAs(button) {
            top.linkTo(parent.top, margin = 16.dp)
            start.linkTo(parent.start)
            end.linkTo(parent.end)
        }
    ) { Text("Click me") }

    Text(
        text = "Label",
        modifier = Modifier.constrainAs(text) {
            top.linkTo(button.bottom, margin = 8.dp)
            centerHorizontallyTo(parent)
        }
    )
}
```

---

## 5. Gesture System

All gesture APIs live in `androidx.compose.foundation` and `androidx.compose.ui.input.pointer`.

### 5.1 High-Level Gesture Detectors

Applied via `Modifier.pointerInput(key)`:

```kotlin
Modifier.pointerInput(Unit) {
    // Each detectX function is a suspend function that loops forever
    detectTapGestures(
        onTap = { offset -> /* single tap */ },
        onDoubleTap = { offset -> /* double tap */ },
        onLongPress = { offset -> /* long press */ },
        onPress = { offset ->
            // Receives PointerInputChange; call tryAwaitRelease() inside
            tryAwaitRelease()  // suspend until finger lifts
        }
    )
}
```

**Important:** Multiple `detectX` calls cannot coexist in one `pointerInput` block.
Use separate `Modifier.pointerInput(key)` instances on the same composable.

#### Available Detectors

| Detector Function | Description | Traditional Equivalent |
|-----------------|-------------|----------------------|
| `detectTapGestures` | Tap, double-tap, long-press, press | `GestureDetector.OnGestureListener` |
| `detectDragGestures` | Generic drag in any direction | `GestureDetector.OnGestureListener.onScroll` |
| `detectDragGesturesAfterLongPress` | Drag initiated by long-press | Custom touch handling |
| `detectHorizontalDragGestures` | Constrained to horizontal axis | `GestureDetector` + custom |
| `detectVerticalDragGestures` | Constrained to vertical axis | `GestureDetector` + custom |
| `detectTransformGestures` | Pan + zoom + rotation simultaneously | `ScaleGestureDetector` + `RotationGestureDetector` |

```kotlin
Modifier.pointerInput(Unit) {
    detectDragGestures(
        onDragStart = { startOffset -> },
        onDrag = { change, dragAmount ->
            change.consume()   // mark event as consumed
            // dragAmount: Offset(dx, dy)
        },
        onDragEnd = { },
        onDragCancel = { }
    )
}

Modifier.pointerInput(Unit) {
    detectTransformGestures(
        panZoomLock = false,
        onGesture = { centroid, pan, zoom, rotation ->
            scale *= zoom
            angle += rotation
            offset += pan
        }
    )
}
```

### 5.2 Modifier-Level Gestures

| Modifier | Description | Traditional Equivalent |
|---------|-------------|----------------------|
| `Modifier.clickable` | Tap with ripple + semantics | `View.setOnClickListener` |
| `Modifier.combinedClickable` | Tap + double-tap + long-press | Custom `GestureDetector` |
| `Modifier.draggable` | Single-axis drag (H or V) | Custom `onTouchEvent` |
| `Modifier.scrollable` | Scrollable with fling support | `ScrollView` behavior |
| `Modifier.transformable` | Pan/zoom/rotate via `TransformableState` | `ScaleGestureDetector` |
| `Modifier.swipeable` (deprecated) | Swipe between anchors | Custom `onTouchEvent` |
| `Modifier.anchoredDraggable` | Replaces swipeable | `BottomSheetBehavior` pattern |
| `Modifier.nestedScroll` | Participate in nested scroll chain | `NestedScrollingChild/Parent` |

```kotlin
// Modifier.draggable — single axis
var offsetX by remember { mutableStateOf(0f) }
Modifier.draggable(
    orientation = Orientation.Horizontal,
    state = rememberDraggableState { delta -> offsetX += delta },
    onDragStarted = { startedPosition -> },
    onDragStopped = { velocity -> }
)

// Modifier.transformable — combined pan/zoom/rotate
var scale by remember { mutableStateOf(1f) }
var rotation by remember { mutableStateOf(0f) }
var offset by remember { mutableStateOf(Offset.Zero) }
val transformState = rememberTransformableState { zoomChange, offsetChange, rotationChange ->
    scale *= zoomChange
    rotation += rotationChange
    offset += offsetChange
}
Modifier.transformable(state = transformState)
```

### 5.3 Low-Level Pointer Input API

For fully custom gesture logic:

```kotlin
Modifier.pointerInput(Unit) {
    // awaitEachGesture loops, calling block for each gesture sequence
    awaitEachGesture {
        // Wait for first pointer down
        val down = awaitFirstDown()
        down.consume()

        // Wait for events until all pointers are up
        do {
            val event = awaitPointerEvent()
            event.changes.forEach { change ->
                if (change.positionChanged()) {
                    change.consume()
                }
            }
        } while (event.changes.any { it.pressed })
    }
}
```

Key low-level APIs in `PointerInputScope`:
- `awaitPointerEvent(pass: PointerEventPass)` — receive raw events
- `awaitFirstDown(requireUnconsumed: Boolean)` — wait for press
- `awaitTouchSlopOrCancellation(pointerId, onTouchSlopReached)` — scroll slop detection
- `awaitDragOrCancellation(pointerId)` — detect drag start

`PointerEventPass` controls dispatch order:
- `PointerEventPass.Initial` — parent intercepts before children
- `PointerEventPass.Main` — normal; children receive before parent (default)
- `PointerEventPass.Final` — parent observes after children

### 5.4 VelocityTracker

Used for fling calculations in custom gesture handlers:

```kotlin
val velocityTracker = VelocityTracker()

Modifier.pointerInput(Unit) {
    detectDragGestures(
        onDrag = { change, _ ->
            velocityTracker.addPointerInputChange(change)
        },
        onDragEnd = {
            val velocity = velocityTracker.calculateVelocity()
            // velocity.x, velocity.y in px/s
        }
    )
}
```

---

## 6. Graphics and Drawing

### 6.1 Canvas Composable

```kotlin
Canvas(modifier = Modifier.fillMaxSize()) {
    // 'this' is DrawScope
    val canvasWidth = size.width
    val canvasHeight = size.height

    drawLine(
        color = Color.Blue,
        start = Offset(0f, 0f),
        end = Offset(canvasWidth, canvasHeight),
        strokeWidth = 4f,
        cap = StrokeCap.Round
    )
}
```

### 6.2 DrawScope API

All draw operations available in `DrawScope` (Canvas, `drawBehind`, `drawWithContent`):

| Function | Description |
|---------|-------------|
| `drawLine(color/brush, start, end, strokeWidth, cap, pathEffect)` | Line segment |
| `drawRect(color/brush, topLeft, size, alpha, style)` | Rectangle (fill or stroke) |
| `drawRoundRect(color/brush, topLeft, size, cornerRadius, style)` | Rounded rectangle |
| `drawCircle(color/brush, radius, center, alpha, style)` | Circle |
| `drawOval(color/brush, topLeft, size, alpha, style)` | Ellipse |
| `drawArc(color/brush, startAngle, sweepAngle, useCenter, topLeft, size, style)` | Arc |
| `drawPath(path, color/brush, alpha, style)` | Custom path |
| `drawImage(image, topLeft, srcOffset, srcSize, dstOffset, dstSize, alpha, style, colorFilter, blendMode)` | Bitmap |
| `drawText(textLayoutResult, color, topLeft, alpha)` | Pre-measured text |
| `drawText(textMeasurer, text, topLeft, style, maxLines)` | Text with inline measurement |
| `drawPoints(points, pointMode, color/brush, strokeWidth, cap, pathEffect, alpha, colorFilter, blendMode)` | Points/lines |
| `inset(horizontal, vertical) { }` | Translate + clip sub-scope |
| `rotate(degrees, pivot) { }` | Rotation sub-scope |
| `scale(sx, sy, pivot) { }` | Scale sub-scope |
| `translate(left, top) { }` | Translation sub-scope |
| `clipRect(left, top, right, bottom, clipOp) { }` | Clip sub-scope |
| `clipPath(path, clipOp) { }` | Path clip sub-scope |
| `withTransform(block) { }` | Combined transforms |

Drawing style:
```kotlin
// Fill (default)
style = Fill

// Stroke
style = Stroke(
    width = 4f,
    cap = StrokeCap.Round,       // Butt, Round, Square
    join = StrokeJoin.Round,     // Miter, Round, Bevel
    miter = 4f,
    pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 5f))
)
```

### 6.3 Brush Types

```kotlin
// Solid color
SolidColor(Color.Blue)

// Linear gradient
Brush.linearGradient(
    colors = listOf(Color.Red, Color.Blue),
    start = Offset.Zero,
    end = Offset(Float.POSITIVE_INFINITY, 0f),  // left-to-right
    tileMode = TileMode.Clamp
)

// Radial gradient
Brush.radialGradient(
    colors = listOf(Color.Yellow, Color.Red),
    center = Offset(100f, 100f),
    radius = 100f,
    tileMode = TileMode.Clamp
)

// Sweep gradient (conic)
Brush.sweepGradient(
    colors = listOf(Color.Red, Color.Green, Color.Blue),
    center = Offset(100f, 100f)
)

// Colorstop variants
Brush.linearGradient(
    0.0f to Color.Transparent,
    0.5f to Color.Blue,
    1.0f to Color.Transparent,
    start = Offset.Zero,
    end = Offset(Float.POSITIVE_INFINITY, 0f)
)
```

### 6.4 Path and PathEffect

```kotlin
val path = Path().apply {
    moveTo(0f, 0f)
    lineTo(100f, 0f)
    quadraticBezierTo(100f, 100f, 0f, 100f)
    cubicTo(50f, 150f, -50f, 150f, 0f, 0f)
    close()
}

// PathEffects
PathEffect.dashPathEffect(intervals = floatArrayOf(10f, 5f), phase = 0f)
PathEffect.cornerPathEffect(radius = 10f)
PathEffect.chainPathEffect(outer = dashEffect, inner = cornerEffect)
PathEffect.stampedPathEffect(shape = stampPath, advance = 20f, phase = 0f, style = StampedPathEffectStyle.Morph)
```

### 6.5 graphicsLayer Modifier

Applies GPU-accelerated rendering effects without recomposition:

```kotlin
Modifier.graphicsLayer {
    // Transform
    scaleX = 1.2f
    scaleY = 1.2f
    rotationZ = 15f                // degrees, around Z axis
    rotationX = 0f                 // perspective tilt
    rotationY = 0f
    translationX = 0f
    translationY = 0f
    transformOrigin = TransformOrigin(0.5f, 0.5f)  // pivot point (0..1)

    // Appearance
    alpha = 0.8f
    shadowElevation = 8f
    shape = RoundedCornerShape(16.dp)
    clip = true

    // Blend
    compositingStrategy = CompositingStrategy.Auto
    // CompositingStrategy.Offscreen — renders to offscreen buffer first (for alpha blending)
    // CompositingStrategy.ModulateAlpha — multiply alpha without offscreen buffer

    // RenderEffect (API 31+ / Android 12+)
    renderEffect = BlurEffect(
        radiusX = 8f,
        radiusY = 8f,
        edgeTreatment = TileMode.Decal
    )
    // Chain effects:
    renderEffect = BlurEffect(8f, 8f).asComposeRenderEffect()
}
```

### 6.6 RenderEffect (API 31+)

```kotlin
// Blur
RenderEffect.createBlurEffect(radiusX, radiusY, Shader.TileMode.DECAL)

// Chain (blur then color matrix)
RenderEffect.createChainEffect(
    outer = RenderEffect.createBlurEffect(8f, 8f, Shader.TileMode.CLAMP),
    inner = RenderEffect.createColorFilterEffect(colorMatrix)
)

// RuntimeShader (AGSL) effect — API 33+
val agslShader = RuntimeShader(agslSource)
RenderEffect.createRuntimeShaderEffect(agslShader, "inputShader")
```

### 6.7 RuntimeShader / AGSL (API 33+ / Android 13+)

AGSL (Android Graphics Shading Language) is a subset of GLSL ES 1.0 that runs on the GPU:

```kotlin
// Requires API 33+
@RequiresApi(33)
fun createRippleEffect(): RuntimeShader {
    val agslSource = """
        uniform float2 resolution;
        uniform float time;
        uniform shader inputShader;   // bound to the composable's rendered content

        half4 main(float2 fragCoord) {
            float2 uv = fragCoord / resolution;
            float wave = sin(uv.x * 20.0 + time) * 0.01;
            return inputShader.eval(fragCoord + float2(0.0, wave * resolution.y));
        }
    """
    return RuntimeShader(agslSource)
}

// Apply in graphicsLayer
val shader = remember { createRippleEffect() }
Modifier.graphicsLayer {
    renderEffect = RenderEffect
        .createRuntimeShaderEffect(shader, "inputShader")
        .asComposeRenderEffect()
}
// Update uniforms in drawing phase:
shader.setFloatUniform("time", System.currentTimeMillis() / 1000f)
shader.setFloatUniform("resolution", width.toFloat(), height.toFloat())
```

Also usable as a `Brush` inside `DrawScope`:
```kotlin
val paint = Paint().apply {
    shader = RuntimeShader(agslSource).also {
        it.setFloatUniform("time", animatedTime)
    }
}
drawIntoCanvas { canvas ->
    canvas.drawRect(Rect(Offset.Zero, size), paint)
}
```

### 6.8 BlendMode

Used in `drawBehind`, `drawWithContent`, `graphicsLayer.blendMode`:

```kotlin
BlendMode.Clear        // Erase destination
BlendMode.Src          // Source only
BlendMode.Dst          // Destination only
BlendMode.SrcOver      // Default — source over destination
BlendMode.DstOver      // Destination over source
BlendMode.SrcIn        // Source where destination is opaque
BlendMode.DstIn        // Destination where source is opaque
BlendMode.SrcOut       // Source where destination is transparent
BlendMode.Xor          // XOR of source and destination
BlendMode.Plus         // Additive blend
BlendMode.Multiply     // Multiply
BlendMode.Screen       // Screen
BlendMode.Overlay      // Overlay
BlendMode.Darken       // Darken
BlendMode.Lighten      // Lighten
BlendMode.ColorDodge   // Color dodge
BlendMode.ColorBurn    // Color burn
BlendMode.Hardlight    // Hard light
BlendMode.Softlight    // Soft light
BlendMode.Difference   // Difference
BlendMode.Exclusion    // Exclusion
BlendMode.Hue, BlendMode.Saturation, BlendMode.Color, BlendMode.Luminosity
```

Drawing modifiers:
```kotlin
Modifier.drawBehind {
    // DrawScope — draw behind composable content
}
Modifier.drawWithContent {
    drawContent()          // draw the composable itself
    // then draw on top
    drawCircle(Color.Red)
}
Modifier.drawWithCache {
    val path = Path()      // build expensive objects once, cache across recompositions
    onDrawBehind { drawPath(path, Color.Blue) }
    // or onDrawWithContent { ... }
}
```

---

## 7. Theming System

### 7.1 MaterialTheme

```kotlin
MaterialTheme(
    colorScheme: ColorScheme = MaterialTheme.colorScheme,
    shapes: Shapes = MaterialTheme.shapes,
    typography: Typography = MaterialTheme.typography,
    content: @Composable () -> Unit
)

// Access tokens anywhere inside:
val primary = MaterialTheme.colorScheme.primary
val bodyLarge = MaterialTheme.typography.bodyLarge
val mediumShape = MaterialTheme.shapes.medium
```

### 7.2 Color Scheme — 26 Semantic Roles

M3 colors come in groups: `primary`, `secondary`, `tertiary`, `error`, `neutral`, and `neutral-variant`.
Each key color generates `color`, `onColor`, `colorContainer`, and `onColorContainer` variants.

| Token | Description |
|-------|-------------|
| `primary` | Main brand/action color |
| `onPrimary` | Text/icons ON primary |
| `primaryContainer` | Background for primary elements |
| `onPrimaryContainer` | Text/icons ON primaryContainer |
| `inversePrimary` | Primary in dark-on-light contexts |
| `secondary` | Supporting brand color |
| `onSecondary` | Text/icons ON secondary |
| `secondaryContainer` | Background for secondary elements |
| `onSecondaryContainer` | Text/icons ON secondaryContainer |
| `tertiary` | Accent color, complementary to primary/secondary |
| `onTertiary` | Text/icons ON tertiary |
| `tertiaryContainer` | Background for tertiary elements |
| `onTertiaryContainer` | Text/icons ON tertiaryContainer |
| `background` | Default background |
| `onBackground` | Text/icons ON background |
| `surface` | Component surfaces (cards, sheets) |
| `onSurface` | Text/icons ON surface |
| `surfaceVariant` | Alternate surface (input fields) |
| `onSurfaceVariant` | Text/icons ON surfaceVariant |
| `surfaceTint` | Color used for tonal elevation |
| `inverseSurface` | Background for inverted surfaces (Snackbar) |
| `inverseOnSurface` | Text ON inverseSurface |
| `error` | Error/destructive color |
| `onError` | Text/icons ON error |
| `errorContainer` | Container for error state |
| `onErrorContainer` | Text/icons ON errorContainer |
| `outline` | Borders, dividers |
| `outlineVariant` | Subtle borders |
| `scrim` | Modal scrim overlay |

#### Dynamic Color (API 31+)

```kotlin
// In your Theme composable:
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,  // wallpaper-based color
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    MaterialTheme(colorScheme = colorScheme, ...) { content() }
}
```

### 7.3 Typography — 15 Styles

M3 type scale groups: `display`, `headline`, `title`, `body`, `label`.
Each group has `Large`, `Medium`, `Small` variants = 15 total styles.

| Token | Default Size | Usage |
|-------|-------------|-------|
| `displayLarge` | 57sp, regular | Hero text, very large displays |
| `displayMedium` | 45sp, regular | Large hero text |
| `displaySmall` | 36sp, regular | Large decorative text |
| `headlineLarge` | 32sp, regular | Page/section headings |
| `headlineMedium` | 28sp, regular | Sub-section headings |
| `headlineSmall` | 24sp, regular | Card headings |
| `titleLarge` | 22sp, regular | App bar title, dialog title |
| `titleMedium` | 16sp, medium (500) | List item primary text |
| `titleSmall` | 14sp, medium (500) | List item supporting |
| `bodyLarge` | 16sp, regular | Body copy, primary reading |
| `bodyMedium` | 14sp, regular | Secondary body |
| `bodySmall` | 12sp, regular | Caption, help text |
| `labelLarge` | 14sp, medium (500) | Button labels |
| `labelMedium` | 12sp, medium (500) | Chip labels, tab labels |
| `labelSmall` | 11sp, medium (500) | Badge labels, overlines |

```kotlin
Typography(
    displayLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 57.sp,
        lineHeight = 64.sp,
        letterSpacing = (-0.25).sp
    ),
    // ... define remaining 14 styles
)
```

### 7.4 Shape System

M3 shapes map to `CornerBasedShape` or `RoundedCornerShape`:

| Token | Default | Typical Use |
|-------|---------|-------------|
| `extraSmall` | `RoundedCornerShape(4.dp)` | Chip, tooltip, menu item |
| `small` | `RoundedCornerShape(8.dp)` | Button, text field |
| `medium` | `RoundedCornerShape(12.dp)` | Card, dialog |
| `large` | `RoundedCornerShape(16.dp)` | Bottom sheet, navigation drawer |
| `extraLarge` | `RoundedCornerShape(28.dp)` | FAB (standard) |
| `full` | `CircleShape` (50%) | FAB (small/large), badge |

M3 Expressive adds 35 additional shape definitions and shape morphing:
```kotlin
// Shape morphing between two shapes using Morph (from androidx.graphics.shapes)
val morph = Morph(startShape, endShape)
val morphedPath = morph.toPath(progress = animatedProgress)
drawPath(morphedPath, color)
```

### 7.5 Motion Tokens (M3 Expressive — MotionScheme)

M3 1.4.0 introduces `MotionScheme` accessed via `MaterialTheme.motionScheme`:

```kotlin
val motionScheme = MaterialTheme.motionScheme

// Standard — enters/exits the screen
motionScheme.standardEffects()            // easing: StandardDecelerateInterpolator

// Emphasized — spatially moving elements, high attention
motionScheme.emphasizedEffects()          // spring-based in M3 Expressive

// Fast — quick micro-interactions
motionScheme.fastEffects()

// Slow — deliberate, large transitions
motionScheme.slowEffects()
```

M3 Expressive replaces duration+easing motion with physics-based spring animations:

```kotlin
// Classic easing tokens (M3 pre-Expressive)
FastOutSlowInEasing        // Standard decelerate (most common)
LinearOutSlowInEasing      // Decelerate (incoming elements)
FastOutLinearInEasing      // Accelerate (outgoing elements)
LinearEasing               // Constant speed

// M3 Expressive spring specs (approximate token values)
spring(dampingRatio = 0.8f, stiffness = 380f)   // Emphasized
spring(dampingRatio = 0.9f, stiffness = 700f)   // Standard
spring(dampingRatio = 1.0f, stiffness = 1400f)  // Fast (overdamped)
```

### 7.6 Elevation and Tonal Elevation

M3 uses tonal elevation (color tint) instead of shadow elevation for surface hierarchy:

| Elevation Level | Tonal Opacity | Surface Typical Use |
|----------------|--------------|---------------------|
| Level 0 | 0% | Background |
| Level 1 | 5% | Surface tint (cards at rest) |
| Level 2 | 8% | Hovered state |
| Level 3 | 11% | Navigation drawer |
| Level 4 | 12% | App bars |
| Level 5 | 14% | Bottom sheets |

```kotlin
Surface(tonalElevation = 2.dp) { ... }  // adds primary color tint at 8% opacity
```

---

## 8. Platform-Specific Android APIs

These APIs exist outside Jetpack Compose but are called from Kotlin/Java code
that Crystal bridges via JNI. They are not exposed as Composables.

### 8.1 Notifications

**Min API:** 23 (for NotificationCompat)

```kotlin
// NotificationCompat (recommended — handles API differences automatically)
val notification = NotificationCompat.Builder(context, CHANNEL_ID)
    .setSmallIcon(R.drawable.ic_notification)
    .setContentTitle("Title")
    .setContentText("Body text")
    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
    .setAutoCancel(true)
    .addAction(R.drawable.ic_action, "Action Label", pendingIntent)
    .setStyle(NotificationCompat.BigTextStyle().bigText("Long text..."))
    .build()

// Notification channels — required on API 26+
val channel = NotificationChannel(
    CHANNEL_ID,
    "Channel Name",
    NotificationManager.IMPORTANCE_DEFAULT
).apply {
    description = "Channel description"
}
val notificationManager = context.getSystemService(NotificationManager::class.java)
notificationManager.createNotificationChannel(channel)

// Show
NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
```

JNI bridge pattern for notifications:
- Crystal calls `notify_user(title, body)` exported C function
- C function calls back via JNI to `com/pkg/CrystalLib.showNotification(String, String)`
- Kotlin creates the `NotificationCompat.Builder` and calls `notify()`

### 8.2 Glance Widgets

**Min API:** 23. Requires:
```kotlin
implementation("androidx.glance:glance-appwidget:1.1.0")
```

```kotlin
// Widget definition
class MyWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            GlanceTheme {
                MyWidgetContent()
            }
        }
    }
}

@Composable
private fun MyWidgetContent() {
    // Glance composables — NOT the same as Jetpack Compose composables!
    // Available: Box, Row, Column, Text, Button, Image, LazyColumn, Spacer
    Column(
        modifier = GlanceModifier.fillMaxSize().background(Color.White)
    ) {
        Text(text = "Widget Title", style = TextStyle(fontSize = 18.sp))
        Button(text = "Tap me", onClick = actionRunCallback<MyAction>())
    }
}

// Widget receiver (registered in AndroidManifest.xml)
class MyWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = MyWidget()
}

// Update from outside
GlanceAppWidgetManager(context).getGlanceIds(MyWidget::class.java).forEach { id ->
    MyWidget().update(context, id)
}
```

**Important for Crystal JNI:** Glance does NOT use regular Views or Compose composables.
It translates to `RemoteViews` internally. Crystal cannot directly drive Glance widgets
via JNI in the normal view-creation pattern. Instead, trigger updates by calling
`GlanceAppWidget.update()` from Kotlin and passing data via `GlanceStateDefinition`.

### 8.3 Quick Settings Tiles

**Min API:** 24 (API 24+ for `TileService`)

```kotlin
class MyTileService : TileService() {
    override fun onTileAdded() { /* tile first added to Quick Settings */ }
    override fun onTileRemoved() { /* tile removed */ }

    override fun onStartListening() {
        // Update tile state
        qsTile.state = Tile.STATE_ACTIVE
        qsTile.label = "My Feature"
        qsTile.icon = Icon.createWithResource(this, R.drawable.ic_tile)
        qsTile.updateTile()
    }

    override fun onClick() {
        // Handle tile tap
        qsTile.state = if (isEnabled) Tile.STATE_INACTIVE else Tile.STATE_ACTIVE
        qsTile.updateTile()
    }
}
// Registered in AndroidManifest with:
// <service android:name=".MyTileService"
//          android:exported="true"
//          android:icon="@drawable/ic_tile"
//          android:label="Tile Label"
//          android:permission="android.permission.BIND_QUICK_SETTINGS_TILE">
//     <intent-filter>
//         <action android:name="android.service.quicksettings.action.QS_TILE" />
//     </intent-filter>
// </service>
```

### 8.4 Picture-in-Picture (PiP)

**Min API:** 26 (Android 8.0)

```kotlin
// Enter PiP mode
val pipParams = PictureInPictureParams.Builder()
    .setAspectRatio(Rational(16, 9))
    .setActions(listOf(
        RemoteAction(
            Icon.createWithResource(context, R.drawable.ic_play),
            "Play",
            "Play/Pause",
            PendingIntent.getBroadcast(context, 0, Intent("com.pkg.PIP_PLAY"), PendingIntent.FLAG_IMMUTABLE)
        )
    ))
    .setAutoEnterEnabled(true)    // API 31+ — auto-enter on home gesture
    .setSeamlessResizeEnabled(true)
    .build()

activity.enterPictureInPictureMode(pipParams)

// React to PiP mode changes in Activity
override fun onPictureInPictureModeChanged(
    isInPictureInPictureMode: Boolean,
    newConfig: Configuration
) {
    if (isInPictureInPictureMode) {
        // Simplify UI, hide chrome
    } else {
        // Restore full UI
    }
}
```

In Compose, observe PiP state:
```kotlin
val pipMode by rememberUpdatedState(newValue = isInPictureInPictureMode())
// or use LocalPipMode from accompanist-pip
```

### 8.5 Foreground Services

**Min API:** 26 (for foreground service); **API 34+:** requires `foregroundServiceType`.

```kotlin
class MyForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        // API 34+: must specify type matching manifest declaration
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            notification,
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC  // or MEDIA_PLAYBACK, CAMERA, etc.
        )
        return START_NOT_STICKY
    }
    override fun onBind(intent: Intent?) = null
}

// AndroidManifest.xml:
// <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
// <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />  // API 34+
// <service android:name=".MyForegroundService"
//          android:foregroundServiceType="dataSync" />
```

### 8.6 MediaSession / Media Controls

Uses `androidx.media3` (preferred) or `android.media.session.MediaSession`.

```kotlin
// Recommended: androidx.media3
implementation("androidx.media3:media3-session:1.5.0")
implementation("androidx.media3:media3-exoplayer:1.5.0")

// In your Service:
val player = ExoPlayer.Builder(context).build()
val mediaSession = MediaSession.Builder(context, player)
    .setId("MyMediaSession")
    .setCallback(object : MediaSession.Callback { /* handle transport controls */ })
    .build()

// MediaSessionService auto-creates a MediaStyle notification
class MyPlaybackService : MediaSessionService() {
    private var mediaSession: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        val player = ExoPlayer.Builder(this).build()
        mediaSession = MediaSession.Builder(this, player).build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo) = mediaSession

    override fun onDestroy() {
        mediaSession?.run { player.release(); release(); mediaSession = null }
        super.onDestroy()
    }
}
```

---

## 9. Crystal Integration Priority Matrix

Mapping between Crystal `UI::View`, proposed new view types, Compose function,
traditional Android View, and web/HTML equivalent.

| Priority | Compose Component | Proposed Crystal UI::View | Traditional Android View | Web Equivalent |
|----------|------------------|--------------------------|-------------------------|----------------|
| **P0 (Done)** | `Text` / `BasicText` | `UI::Label` | `TextView` | `<span>` |
| **P0 (Done)** | `Button` (filled) | `UI::Button` | `MaterialButton` | `<button>` |
| **P0 (Done)** | `Column` | `UI::VStack` | `LinearLayout(VERTICAL)` | `flex-direction:column` |
| **P0 (Done)** | `Row` | `UI::HStack` | `LinearLayout(HORIZONTAL)` | `flex-direction:row` |
| **P0 (Done)** | `Box` | `UI::ZStack` | `FrameLayout` | `position:relative` |
| **P0 (Done)** | `Image` | `UI::Image` | `ImageView` | `<img>` |
| **P0 (Done)** | `TextField` (filled) | `UI::TextField` | `TextInputEditText` | `<input type="text">` |
| **P0 (Done)** | `LazyColumn` (wrapping) | `UI::ScrollView` | `ScrollView` | `overflow-y:auto` |
| **P0 (Done)** | `Spacer` | `UI::Spacer` | `View` with weight | `flex:1` |
| — | — | — | — | — |
| **P1** | `Switch` | `UI::Toggle` | `SwitchCompat` | `<input type="checkbox">` |
| **P1** | `Slider` | `UI::Slider` | `Slider` | `<input type="range">` |
| **P1** | `LazyColumn` | `UI::List` | `RecyclerView` | `<ul>` / virtual scroll |
| **P1** | `NavigationBar` | `UI::TabBar` | `BottomNavigationView` | `<nav>` bottom |
| **P1** | `LinearProgressIndicator` | `UI::ProgressBar` | `LinearProgressIndicator` | `<progress>` |
| **P1** | `CircularProgressIndicator` | `UI::ActivityIndicator` | `CircularProgressIndicator` | CSS spinner |
| **P1** | `Scaffold` | `UI::Screen` | `CoordinatorLayout` | `<main>` / layout |
| **P1** | `TopAppBar` | `UI::NavigationBar` | `MaterialToolbar` | `<header>` |
| **P1** | `AlertDialog` | `UI::Alert` | `MaterialAlertDialog` | `<dialog>` |
| **P1** | `ModalBottomSheet` | `UI::Sheet` | `BottomSheetDialog` | CSS slide-up panel |
| **P1** | `Checkbox` | `UI::Checkbox` | `CheckBox` | `<input type="checkbox">` |
| **P1** | `RadioButton` | `UI::RadioButton` | `RadioButton` | `<input type="radio">` |
| — | — | — | — | — |
| **P2** | `OutlinedTextField` | — | `TextInputEditText` (outlined) | `<input>` styled |
| **P2** | `DatePicker` | `UI::DatePicker` | `MaterialDatePicker` | `<input type="date">` |
| **P2** | `TimePicker` | `UI::TimePicker` | `MaterialTimePicker` | `<input type="time">` |
| **P2** | `ExposedDropdownMenuBox` | `UI::Picker` | `AutoCompleteTextView` | `<select>` |
| **P2** | `SingleChoiceSegmentedButtonRow` | `UI::SegmentedControl` | Custom button group | `<input type="radio">` styled |
| **P2** | `SearchBar` | `UI::SearchField` | `SearchView` | `<input type="search">` |
| **P2** | `Snackbar` + `SnackbarHost` | `UI::Toast` | `Snackbar` | CSS toast |
| **P2** | `NavigationRail` | `UI::SideBar` | `NavigationRailView` | `<nav>` side |
| **P2** | `TabRow` | `UI::TabView` | `TabLayout` | `<div role="tablist">` |
| **P2** | `Card` | `UI::Card` | `MaterialCardView` | `<article>` / `<div>` |
| **P2** | `FloatingActionButton` | `UI::FAB` | `FloatingActionButton` | CSS fixed button |
| **P2** | `RangeSlider` | `UI::RangeSlider` | Custom dual Slider | `<input>` dual-range |
| **P2** | `FilterChip` / `AssistChip` | `UI::Chip` | `Chip` | `<button>` pill |
| **P2** | `HorizontalDivider` | `UI::Divider` | `View` 1dp line | `<hr>` |
| **P2** | `ButtonGroup` (M3 Exp.) | `UI::ButtonGroup` | `LinearLayout` of buttons | `<div role="group">` |
| — | — | — | — | — |
| **P3** | `Canvas` | `UI::Canvas` | Custom `View.onDraw` | `<canvas>` |
| **P3** | `PlainTooltip` | — | Custom popup | CSS tooltip |
| **P3** | `MapView` (external) | `UI::Map` | `MapView` (Google Maps) | `<div id="map">` |
| **P3** | `VideoPlayer` (external) | `UI::VideoPlayer` | `VideoView` / ExoPlayer | `<video>` |
| **P3** | `WideNavigationRail` (M3 Exp.) | — | Custom side panel | CSS sidebar |
| **P3** | `FloatingActionButtonMenu` (M3 Exp.) | — | Custom overlay | CSS menu |
| **P3** | `HorizontalMultiBrowseCarousel` | — | `RecyclerView` (carousel) | CSS scroll snap |
| **P3** | `DateRangePicker` | — | `MaterialDateRangePicker` | Custom date range UI |
| **P3** | `RichTooltip` | — | Custom popup | CSS popover |
| **P3** | `NavigationSuiteScaffold` | `UI::AdaptiveLayout` | Adaptive layout pattern | CSS media queries |

---

## 10. JNI Bridge Patterns for Crystal

### 10.1 Architecture Recap

```
Crystal (android_renderer.cr)
    |
    | Crystal -> C via @[Link] lib declarations
    v
jni_bridge.c (C function wrappers)
    |
    | JNIEnv->CallVoidMethod / CallObjectMethod / etc.
    v
Kotlin (CrystalViewFactory.kt or Activity)
    |
    v
Android View / Compose (actual UI objects)
```

### 10.2 Basic View Creation via JNI

The JNI bridge follows a consistent pattern:

**Crystal side (android_renderer.cr):**
```crystal
{% if flag?(:android) %}
lib LibAndroidBridge
  # C functions that the bridge exposes to Crystal
  fun create_text_view(env : Void*, context : Void*, text : UInt8*) : Void*
  fun create_material_button(env : Void*, context : Void*, text : UInt8*) : Void*
  fun create_linear_layout(env : Void*, context : Void*, orientation : Int32) : Void*
  fun view_set_on_click(env : Void*, view : Void*, callback_id : UInt64) : Void
  fun viewgroup_add_child(env : Void*, parent : Void*, child : Void*) : Void
end

class Android::Renderer < PlatformVisitor
  def initialize(@env : Void*, @context : Void*)
  end

  def visit(button : UI::Button) : NativeView
    label_jstr = UI::JNI::JString.from_string(@env, button.label)
    view_ptr = LibAndroidBridge.create_material_button(@env, @context, label_jstr.ptr)
    handle = UI::JNI.global(@env, view_ptr)   # promote local -> global
    label_jstr.delete_local

    if cb = button.on_tap
      id = UI::CallbackRegistry.register(cb)
      LibAndroidBridge.view_set_on_click(@env, handle.ptr, id)
    end

    NativeView.new(handle)
  end
end
{% end %}
```

**C bridge (jni_bridge.c):**
```c
#include <jni.h>
#include <string.h>

// Helper: get the CrystalViewFactory singleton
static jobject get_factory(JNIEnv *env) {
    jclass cls = (*env)->FindClass(env, "com/pkg/CrystalViewFactory");
    jmethodID get = (*env)->GetStaticMethodID(env, cls, "getInstance", "()Lcom/pkg/CrystalViewFactory;");
    return (*env)->CallStaticObjectMethod(env, cls, get);
}

jobject create_material_button(JNIEnv *env, jobject context, const char *text) {
    jobject factory = get_factory(env);
    jclass cls = (*env)->GetObjectClass(env, factory);
    jmethodID mid = (*env)->GetMethodID(env, cls, "createButton",
        "(Landroid/content/Context;Ljava/lang/String;)Landroid/widget/Button;");
    jstring jtext = (*env)->NewStringUTF(env, text);
    jobject button = (*env)->CallObjectMethod(env, factory, mid, context, jtext);
    (*env)->DeleteLocalRef(env, jtext);
    return button;  // local ref — caller must promote to global if stored
}

void view_set_on_click(JNIEnv *env, jobject view, uint64_t callback_id) {
    jclass cls = (*env)->FindClass(env, "com/pkg/CrystalCallbackDispatcher");
    jmethodID mid = (*env)->GetStaticMethodID(env, cls, "setOnClick",
        "(Landroid/view/View;J)V");
    (*env)->CallStaticVoidMethod(env, cls, mid, view, (jlong)callback_id);
}
```

**Kotlin side (CrystalViewFactory.kt):**
```kotlin
object CrystalViewFactory {
    fun getInstance() = this

    fun createButton(context: Context, text: String): MaterialButton {
        return MaterialButton(context).apply {
            this.text = text
        }
    }

    fun createLinearLayout(context: Context, orientation: Int): LinearLayout {
        return LinearLayout(context).apply {
            this.orientation = orientation  // LinearLayout.VERTICAL or HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
    }

    fun createTextView(context: Context, text: String): TextView {
        return TextView(context).apply {
            this.text = text
            setTextAppearance(com.google.android.material.R.style.TextAppearance_Material3_BodyLarge)
        }
    }
}
```

**Callback dispatcher (CrystalCallbackDispatcher.kt):**
```kotlin
object CrystalCallbackDispatcher {
    // Called from JNI when a view event fires
    @JvmStatic
    external fun crystalInvokeCallback(callbackId: Long)  // implemented in C

    @JvmStatic
    fun setOnClick(view: View, callbackId: Long) {
        view.setOnClickListener { crystalInvokeCallback(callbackId) }
    }

    @JvmStatic
    fun setOnCheckedChange(view: CompoundButton, callbackId: Long) {
        view.setOnCheckedChangeListener { _, isChecked ->
            // Pass boolean state through — crystalInvokeCallback needs extension
            crystalInvokeCallbackBool(callbackId, isChecked)
        }
    }
}
```

### 10.3 Composable-Based Views via AndroidView

For Compose components not available as traditional Views (e.g., DatePicker),
embed them via `ComposeView` when called from Crystal:

**Kotlin:**
```kotlin
fun createDatePickerComposable(context: Context, onDateSelected: (Long) -> Unit): ComposeView {
    return ComposeView(context).apply {
        setContent {
            MaterialTheme {
                val state = rememberDatePickerState()
                Column {
                    DatePicker(state = state)
                    Button(onClick = {
                        state.selectedDateMillis?.let { onDateSelected(it) }
                    }) { Text("OK") }
                }
            }
        }
    }
}
```

**C bridge:**
```c
typedef void (*DateCallback)(long millis);

jobject create_date_picker(JNIEnv *env, jobject context, DateCallback cb) {
    // Store cb in a wrapper, pass id to Kotlin
    // Kotlin calls back via JNI when date confirmed
}
```

### 10.4 Property Setting Patterns

Standard JNI patterns for setting View properties:

```c
// setText (String)
void set_text_view_text(JNIEnv *env, jobject view, const char *text) {
    jclass cls = (*env)->FindClass(env, "android/widget/TextView");
    jmethodID mid = (*env)->GetMethodID(env, cls, "setText", "(Ljava/lang/CharSequence;)V");
    jstring jtext = (*env)->NewStringUTF(env, text);
    (*env)->CallVoidMethod(env, view, mid, jtext);
    (*env)->DeleteLocalRef(env, jtext);
}

// setEnabled (boolean)
void set_view_enabled(JNIEnv *env, jobject view, int enabled) {
    jclass cls = (*env)->FindClass(env, "android/view/View");
    jmethodID mid = (*env)->GetMethodID(env, cls, "setEnabled", "(Z)V");
    (*env)->CallVoidMethod(env, view, mid, (jboolean)enabled);
}

// setTextColor (int — ARGB packed)
void set_text_color(JNIEnv *env, jobject view, float r, float g, float b, float a) {
    int argb = ((int)(a*255) << 24) | ((int)(r*255) << 16) |
               ((int)(g*255) << 8)  |  (int)(b*255);
    jclass cls = (*env)->FindClass(env, "android/widget/TextView");
    jmethodID mid = (*env)->GetMethodID(env, cls, "setTextColor", "(I)V");
    (*env)->CallVoidMethod(env, view, mid, (jint)argb);
}
```

### 10.5 Layout Params Pattern

Setting `LayoutParams` correctly is critical for Android layout:

```c
// Set MATCH_PARENT / WRAP_CONTENT / fixed dp size
void set_layout_params(JNIEnv *env, jobject view, int width_dp, int height_dp, float density) {
    // Convert dp to px
    int width_px  = (width_dp  < 0) ? width_dp  : (int)(width_dp  * density + 0.5f);
    int height_px = (height_dp < 0) ? height_dp : (int)(height_dp * density + 0.5f);

    jclass params_cls = (*env)->FindClass(env, "android/view/ViewGroup$LayoutParams");
    jmethodID ctor = (*env)->GetMethodID(env, params_cls, "<init>", "(II)V");
    jobject params = (*env)->NewObject(env, params_cls, ctor, width_px, height_px);

    jclass view_cls = (*env)->FindClass(env, "android/view/View");
    jmethodID set_params = (*env)->GetMethodID(env, view_cls, "setLayoutParams",
        "(Landroid/view/ViewGroup$LayoutParams;)V");
    (*env)->CallVoidMethod(env, view, set_params, params);
    (*env)->DeleteLocalRef(env, params);
}
// Common values: MATCH_PARENT = -1, WRAP_CONTENT = -2
```

### 10.6 Listener / Callback Patterns

| View Event | Java Listener Interface | JNI Method Signature |
|-----------|------------------------|---------------------|
| Click | `View.OnClickListener` | `setOnClickListener(Landroid/view/View$OnClickListener;)V` |
| Long click | `View.OnLongClickListener` | `setOnLongClickListener(Landroid/view/View$OnLongClickListener;)V` |
| Checked change | `CompoundButton.OnCheckedChangeListener` | `setOnCheckedChangeListener(...)V` |
| Text change | `TextWatcher` | `addTextChangedListener(Landroid/text/TextWatcher;)V` |
| Item selected | `AdapterView.OnItemSelectedListener` | `setOnItemSelectedListener(...)V` |
| Slider change | `Slider.OnChangeListener` | `addOnChangeListener(...)V` |
| Progress change | `SeekBar.OnSeekBarChangeListener` | `setOnSeekBarChangeListener(...)V` |

Recommended pattern: implement all listeners as Kotlin objects in `CrystalCallbackDispatcher`
and call them from C via static JNI methods, passing the `callbackId` that Crystal uses to
look up the registered `Proc`.

### 10.7 Handling Compose Components in JNI Context

For Compose-only components (Scaffold, NavigationBar, etc.), the recommended approach is:

1. **Kotlin-first architecture:** Let Kotlin/Compose own the screen structure. Crystal
   provides data and callbacks, Kotlin renders the chrome.

2. **Embedded ComposeView:** For individual Compose components embedded in a traditional
   View hierarchy, use `ComposeView(context)` and call `setContent {}` from Kotlin.

3. **Shared ViewModel:** Crystal pushes state updates to a Kotlin `ViewModel` via JNI;
   Compose observes the ViewModel via `collectAsState()`.

```kotlin
// Bridge pattern for Compose-heavy screens
class CrystalComposeActivity : ComponentActivity() {
    private val viewModel: CrystalViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Crystal initializes and registers callbacks via JNI in native lib init
        System.loadLibrary("crystal_app")
        crystalInit(viewModel)  // passes ViewModel to C/Crystal layer

        setContent {
            MaterialTheme {
                val state by viewModel.uiState.collectAsState()
                CrystalScreen(state = state, onEvent = { viewModel.dispatch(it) })
            }
        }
    }

    private external fun crystalInit(viewModel: CrystalViewModel)
}
```

---

## 11. Gradle Dependencies Reference

```kotlin
// Core Compose
implementation(platform("androidx.compose:compose-bom:2024.09.00"))
implementation("androidx.compose.ui:ui")
implementation("androidx.compose.ui:ui-graphics")
implementation("androidx.compose.ui:ui-tooling-preview")
implementation("androidx.compose.foundation:foundation")
implementation("androidx.compose.animation:animation")

// Material 3 (stable)
implementation("androidx.compose.material3:material3:1.4.0")

// Material 3 Adaptive Navigation
implementation("androidx.compose.material3:material3-adaptive-navigation-suite:1.5.0-alpha14")

// Window size classes (for adaptive layouts)
implementation("androidx.compose.material3:material3-window-size-class:1.4.0")

// ConstraintLayout in Compose
implementation("androidx.constraintlayout:constraintlayout-compose:1.1.0")

// Glance (widgets)
implementation("androidx.glance:glance-appwidget:1.1.0")

// Media3
implementation("androidx.media3:media3-exoplayer:1.5.0")
implementation("androidx.media3:media3-session:1.5.0")

// Activity + ViewModel
implementation("androidx.activity:activity-compose:1.9.0")
implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.0")

// Debug
debugImplementation("androidx.compose.ui:ui-tooling")
debugImplementation("androidx.compose.ui:ui-test-manifest")
```

---

## 12. Quick Reference: View Mapping Cheat Sheet

| Crystal UI::View | Android View | Compose Equivalent |
|-----------------|-------------|-------------------|
| `UI::Label` | `TextView` | `Text` |
| `UI::Button` | `MaterialButton` | `Button` / `FilledButton` |
| `UI::VStack` | `LinearLayout(VERTICAL)` | `Column` |
| `UI::HStack` | `LinearLayout(HORIZONTAL)` | `Row` |
| `UI::ZStack` | `FrameLayout` | `Box` |
| `UI::Image` | `ImageView` | `Image` |
| `UI::TextField` | `TextInputEditText` (filled) | `TextField` |
| `UI::ScrollView` | `ScrollView` / `NestedScrollView` | `LazyColumn` / `verticalScroll` |
| `UI::Spacer` | `View` with `layout_weight` | `Spacer(Modifier.weight(1f))` |
| — | `SwitchCompat` | `Switch` |
| — | `Slider` (Material) | `Slider` |
| — | `RecyclerView` | `LazyColumn` / `LazyRow` |
| — | `BottomNavigationView` | `NavigationBar` |
| — | `MaterialToolbar` | `TopAppBar` |
| — | `MaterialAlertDialog` | `AlertDialog` |
| — | `BottomSheetDialog` | `ModalBottomSheet` |
| — | `MaterialDatePicker` | `DatePicker` |
| — | `MaterialTimePicker` | `TimePicker` |
| — | `AutoCompleteTextView` | `ExposedDropdownMenuBox` |
| — | `SearchView` | `SearchBar` |
| — | `CoordinatorLayout` + bars | `Scaffold` |
| — | `MaterialCardView` | `Card` |
| — | `FloatingActionButton` | `FloatingActionButton` |
| — | `CheckBox` | `Checkbox` |
| — | `RadioButton` | `RadioButton` |
| — | `Chip` | `FilterChip` / `AssistChip` / `InputChip` |
| — | `LinearProgressIndicator` | `LinearProgressIndicator` |
| — | `CircularProgressIndicator` | `CircularProgressIndicator` |
| — | `Snackbar` | `Snackbar` + `SnackbarHost` |
| — | `TabLayout` | `TabRow` |
| — | `View` (1dp) | `HorizontalDivider` |
| — | `PopupMenu` | `DropdownMenu` |
| — | Custom view | `Canvas` |
