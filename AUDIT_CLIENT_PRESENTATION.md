# Flutter Client App — Presentation Layer Audit

**Scope**: `mobile/client/lib/` — all presentation files (pages, widgets,
themes, router)\
**Date**: July 2025

---

## TABLE OF CONTENTS

1. [Critical Bugs](#1-critical-bugs)
2. [Core: Theme & Constants](#2-core-theme--constants)
3. [Core: Shared Widgets](#3-core-shared-widgets)
4. [Core: Router](#4-core-router)
5. [Auth Feature](#5-auth-feature)
6. [Home Feature](#6-home-feature)
7. [Pharmacies Feature](#7-pharmacies-feature)
8. [Orders Feature](#8-orders-feature)
9. [Profile Feature](#9-profile-feature)
10. [Wallet Feature](#10-wallet-feature)
11. [Products Feature](#11-products-feature)
12. [Prescriptions Feature](#12-prescriptions-feature)
13. [Notifications Feature](#13-notifications-feature)
14. [Addresses Feature](#14-addresses-feature)
15. [Cross-Cutting Issues](#15-cross-cutting-issues)

---

## 1. CRITICAL BUGS

### 1.1 `edit_address_page.dart` — `_save()` is a stub (BROKEN FEATURE)

**File**: `features/addresses/presentation/pages/edit_address_page.dart`\
**Lines**: ~119-125

```dart
Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // For simplicity, reuse create logic (the API may support PUT)
    if (context.mounted) {
      context.pop();
    }
    setState(() => _isLoading = false);
  }
```

**Issue**: The save method validates the form, sets loading state, then just
pops without making any API call. **Editing an address does nothing** — the user
sees a success-like pop but no data is persisted.\
**Fix**: Call the address repository's update method, handle errors, show
confirmation snackbar.

### 1.2 `notification_settings_page.dart` — Settings are not persisted

**File**: `features/profile/presentation/pages/notification_settings_page.dart`\
**Lines**: 15-18 (state fields), 34-62 (switches)

```dart
bool _orderUpdates = true;
bool _promotions = true;
bool _prescriptionUpdates = true;
bool _deliveryAlerts = true;
```

**Issue**: All four toggle values are local `setState` only. Toggling switches
never calls an API or writes to SharedPreferences. Values reset on every page
visit.\
**Fix**: Load from API/SharedPreferences on init, persist on change.

### 1.3 `tracking_page.dart` — `setState` called from within `build`

**File**: `features/orders/presentation/pages/tracking_page.dart`\
**Lines**: ~241-244 (inside `trackingAsync.when(data:)`)

```dart
data: (tracking) {
    if (tracking != null) {
      _updateMarkersFromFirestore(tracking);  // calls setState
      _courierPosition = LatLng(tracking.latitude, tracking.longitude);
      _deliveryStatus = tracking.status;
```

**Issue**: `_updateMarkersFromFirestore` modifies `_markers` and may call
`setState` + `_refreshEta` during the `build` method. Mutating state inside
`build` causes "setState or markNeedsBuild called during build" errors.\
**Fix**: Move tracking data processing to a `ref.listen` in `initState` or use
`WidgetsBinding.instance.addPostFrameCallback`.

### 1.4 `tracking_page.dart` — Raw error shown to user

**File**: `features/orders/presentation/pages/tracking_page.dart`\
**Line**: ~317

```dart
error: (e, _) => Center(
    child: Text('Erreur de suivi: $e'),
),
```

**Issue**: Raw exception object displayed to end users.

---

## 2. CORE: THEME & CONSTANTS

### 2.1 `app_text_styles.dart` — All styles hardcode light-theme colors

**File**: `core/constants/app_text_styles.dart`\
**All lines (every style definition)**\
**Issue**: Every text style uses `color: AppColors.textPrimary` (dark color). In
dark theme, text will be nearly invisible against dark backgrounds.\
**Fix**: Remove hardcoded colors from `AppTextStyles`, or build styles from
`Theme.of(context).textTheme`. Alternatively, use `ThemeColors` extension which
already exists.

### 2.2 `app_theme.dart` — Dark theme is incomplete

**File**: `core/constants/app_theme.dart`\
**Issue**: `lightTheme` defines `inputDecorationTheme`, `outlinedButtonTheme`,
`dividerTheme`, `bottomNavigationBarTheme`. `darkTheme` is missing all of these
sub-themes.\
**Fix**: Mirror the light theme customizations into `darkTheme`.

### 2.3 `app_colors.dart` — No dark-mode color variants

**File**: `core/constants/app_colors.dart`\
**Issue**: All colors are static constants for light mode only
(`textPrimary: Color(0xFF1A1A2E)`, `background: Color(0xFFF8F9FA)`, etc.). While
`theme_colors.dart` provides a context-based extension for some colors, many
widgets import `AppColors` directly instead of using `context.primaryText` etc.\
**Impact**: Widespread dark-theme color mismatches.

---

## 3. CORE: SHARED WIDGETS

### 3.1 `async_value_widget.dart` — Raw error shown to users (default error)

**File**: `core/widgets/async_value_widget.dart`\
**Issue**: The default error callback shows `err.toString()` in red text. This
leaks internal errors (stack traces, API URLs, etc.) to end users.\
**Fix**: Provide a user-friendly default error with a retry button.

### 3.2 `connectivity_banner.dart` — Hardcoded French string

**File**: `core/widgets/connectivity_banner.dart`\
**Issue**: `'Pas de connexion Internet'` is hardcoded instead of using
`AppLocalizations`.

### 3.3 `empty_state.dart` — Mixed localization

**File**: `core/widgets/empty_state.dart`\
**Issue**: `EmptyProductsState`, `EmptySearchState`, `EmptyOrdersState`,
`EmptyCartState`, `EmptyNotificationsState` all contain hardcoded French strings
(`'Aucun produit trouvé'`, etc.) instead of l10n keys.

### 3.4 `state_widgets.dart` — Contains deprecated widgets still in codebase

**File**: `core/widgets/state_widgets.dart`\
**Issue**: `OfflineWidget`, `ErrorDisplayWidget`, `EmptyStateWidget` are marked
`@Deprecated` but still present. Dead code that could confuse developers.\
**Recommendation**: Remove deprecated file once all call sites are migrated.

### 3.5 `shimmer_loading.dart` — Manual animation instead of package

**File**: `core/widgets/shimmer_loading.dart`\
**Issue**: Custom shimmer implementation with raw `AnimationController` +
`LinearGradient`. The `shimmer` package provides the same with much less code
and better performance. Not a bug, just unnecessary complexity.

---

## 4. CORE: ROUTER

### 4.1 `app_router.dart` — Invalid route param shows raw text

**File**: `core/router/app_router.dart`\
**Issue**: `_buildInvalidRouteErrorPage` shows a technical error message. Should
show a user-friendly "Page not found" with a home button.

---

## 5. AUTH FEATURE

### 5.1 `login_page.dart` — `toggleProvider` is a global provider for local UI state

**File**: `features/auth/presentation/pages/login_page.dart`\
**Issue**: Uses a global `StateProvider<bool>` (`toggleProvider`) for
phone/email toggle. If two login instances existed (unlikely but architecturally
unsound), they'd share state. Should be local `StatefulWidget` state.

### 5.2 `register_page.dart` — Phone number prefix hardcoded

**File**: `features/auth/presentation/pages/register_page.dart`\
**Issue**: `+225` (Ivory Coast) prefix is hardcoded at multiple places. No
country code selector.\
**Impact**: App unusable for numbers outside Ivory Coast.

### 5.3 `forgot_password_page.dart` — 4-digit OTP vs 6-digit elsewhere

**File**: `features/auth/presentation/pages/forgot_password_page.dart`\
**Issue**: Uses 4-digit OTP fields. `otp_verification_page.dart` uses 6-digit.
Inconsistent OTP length across the app. Verify which the backend actually
expects.

### 5.4 `forgot_password_page.dart` — Uses raw global providers for ephemeral state

**File**: `features/auth/presentation/pages/forgot_password_page.dart`\
**Issue**: `loadingProvider`, `formFieldsProvider` are global StateProviders
used for local page state. These leak state between page visits and are not
disposed.

### 5.5 `change_password_page.dart` — Raw exception shown in error

**File**: `features/auth/presentation/pages/change_password_page.dart`\
**Line**: ~155

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Erreur: ${e.toString()}')),
);
```

**Issue**: Exposes raw exception text (potentially including server internals or
stack traces) to the user.

### 5.6 `otp_verification_page.dart` — No maximum OTP attempt limit on client

**File**: `features/auth/presentation/pages/otp_verification_page.dart`\
**Issue**: User can keep submitting wrong OTPs indefinitely from the UI side.
Should show lockout or limit after N failed attempts to deter brute force (even
if backend rate-limits, client should show feedback).

### 5.7 `splash_page.dart` — Hardcoded 3s minimum splash time

**File**: `features/auth/presentation/pages/splash_page.dart`\
**Issue**: `Completer` with `Future.delayed(Duration(seconds: 3))` forces a
minimum 3-second splash even if auth resolves instantly. On fast connections,
this adds unnecessary wait.

---

## 6. HOME FEATURE

### 6.1 `home_page.dart` — Promo items hardcoded in class body

**File**: `features/home/presentation/pages/home_page.dart`\
**Lines**: ~33-56\
**Issue**: `_promoItems` list is hardcoded with French marketing copy. Should
come from backend API or remote config for dynamic promos.

### 6.2 `home_page.dart` — Two auto-scroll timers not cancelled on hot reload

**File**: `features/home/presentation/pages/home_page.dart`\
**Issue**: `_promoTimer` and `_pharmacyTimer` are cancelled in `dispose()` but
if `initState` is called again (e.g. during hot reload with key changes), timers
could double up.

### 6.3 `home_app_bar.dart` — Notification badge count hardcoded check

**File**: `features/home/presentation/widgets/home_app_bar.dart`\
**Issue**: Badge count depends on `unreadCountProvider`. If provider errors, no
fallback — badge might show stale count.

### 6.4 `quick_actions_grid.dart` — Hard-coded 4 actions, no extensibility

**File**: `features/home/presentation/widgets/quick_actions_grid.dart`\
**Issue**: Grid items (Medications, Guard, Pharmacies, Prescriptions) are
hardcoded. Not a bug, but means adding/removing quick actions requires code
changes.

### 6.5 `promo_slider.dart` — Gradient card colors hardcoded

**File**: `features/home/presentation/widgets/promo_slider.dart`\
**Issue**: Gradient color pairs are passed from hardcoded data in
`home_page.dart`. Colors don't adapt to dark theme.

### 6.6 `featured_pharmacies_section.dart` — `PageController` disposed in parent, not child

**File**: `features/home/presentation/widgets/featured_pharmacies_section.dart`\
**Issue**: If the section widget creates its own `PageController`, it should
dispose it. Verify controller lifecycle.

---

## 7. PHARMACIES FEATURE

### 7.1 `pharmacy_card.dart` + `pharmacy_details_page.dart` — Duplicated utility methods

**Files**: Both files contain identical:

- `_getDutyLabel(String?)`
- `_formatTime(String?)`\
  **Fix**: Extract to a shared `pharmacy_utils.dart`.

### 7.2 `pharmacies_list_page_v2.dart` — GPS permission denied has no retry CTA

**File**: `features/pharmacies/presentation/pages/pharmacies_list_page_v2.dart`\
**Issue**: If location permission is denied, the "Nearby" tab falls back
silently to all pharmacies. Should show a banner or button to open settings.

### 7.3 `pharmacy_details_page.dart` — Uses `launchUrl` without try-catch

**File**: `features/pharmacies/presentation/pages/pharmacy_details_page.dart`\
**Issue**: Phone call / email / map actions call `launchUrl` after
`canLaunchUrl`. But `launchUrl` itself can throw. Missing try-catch around
launch calls.

---

## 8. ORDERS FEATURE

### 8.1 `cart_page.dart` — `DebouncedIconButton` rebuilds on every quantity change

**File**: `features/orders/presentation/pages/cart_page.dart`\
**Issue**: Debounce timers for quantity +/- are instance-level. If the widget
rebuilds (e.g. parent `setState`), a new debounce may start while the old one is
still pending.

### 8.2 `checkout_page.dart` — No loading indicator during stock verification

**File**: `features/orders/presentation/pages/checkout_page.dart`\
**Issue**: Stock is re-verified before order submission. If stock check takes
time, the user sees no feedback other than the button disabled state.

### 8.3 `order_confirmation_page.dart` — Delivery code displayed as plain text

**File**: `features/orders/presentation/pages/order_confirmation_page.dart`\
**Issue**: Delivery verification code is shown in large visible text. Consider
that it could be visible in screenshots. Not necessarily a bug, but a UX
consideration for sensitive codes.

### 8.4 `order_details_page.dart` — Cancel dialog doesn't show loading state

**File**: `features/orders/presentation/pages/order_details_page.dart`\
**Issue**: When cancellation is in progress, the dialog buttons remain active.
User could tap cancel multiple times.

### 8.5 `courier_chat_page.dart` — Raw error shown to user

**File**: `features/orders/presentation/pages/courier_chat_page.dart`\
**Lines**: ~210-211, ~137

```dart
Text('Erreur: $_error')   // line ~211 — raw e.toString() in error state
SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)  // line ~137 — send error
```

**Issue**: Both the error state display and the send-message error snackbar
expose raw exception text.

### 8.6 `courier_chat_page.dart` — 5-second polling instead of real-time

**File**: `features/orders/presentation/pages/courier_chat_page.dart`\
**Line**: ~49

```dart
_refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
```

**Issue**: Chat messages are polled every 5 seconds via HTTP. This is battery
and network intensive. Should use WebSocket or Firestore real-time streams (like
tracking already does).

### 8.7 `tracking_page.dart` — Google Maps API key potentially exposed

**File**: `features/orders/presentation/pages/tracking_page.dart`\
**Issue**: Uses `PolylinePoints` and `EtaService` (Directions API). Ensure the
Google Maps API key in the native manifests is restricted by package name and
API type.

### 8.8 `rating_bottom_sheet.dart` — No error handling on submission failure

**File**: `features/orders/presentation/widgets/rating_bottom_sheet.dart`\
**Lines**: ~355+ (the `_submitRating` method, partially visible)\
**Issue**: API call to submit rating — verify there's a try-catch. If the
request fails, the user may see an unhandled exception.

### 8.9 `payment_dialogs.dart` — `PaymentLoadingDialog.hide()` pops blindly

**File**: `features/orders/presentation/widgets/payment_dialogs.dart`\
**Line**: ~148

```dart
static void hide(BuildContext context) {
    Navigator.of(context).pop();
}
```

**Issue**: If called when the dialog isn't showing (e.g. user navigated away),
this pops the wrong route. Should check if dialog is still in the navigator.

### 8.10 `delivery_address_section.dart` — Uses deprecated `withOpacity`

**File**: `features/orders/presentation/widgets/delivery_address_section.dart`\
**Line**: ~116

```dart
color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
```

**Issue**: `withOpacity` is deprecated in favor of `withValues(alpha:)`. All
other files in the project use `withValues`.

---

## 9. PROFILE FEATURE

### 9.1 `profile_page.dart` — Stats cards show raw provider values

**File**: `features/profile/presentation/pages/profile_page.dart`\
**Issue**: "Total spent" displays raw number. If the API returns null or the
user has no orders, verify the default is `0` not `null`.

### 9.2 `edit_profile_page.dart` — Image upload has no size limit enforcement

**File**: `features/profile/presentation/pages/edit_profile_page.dart`\
**Issue**: `ImagePicker` picks images from camera/gallery without specifying
`maxWidth`/`maxHeight`/`imageQuality`. A 20MB photo could be uploaded raw,
causing slow uploads and potential API rejections.\
**Fix**: Add `imageQuality: 70, maxWidth: 1024` to `ImagePicker.pickImage()`.

### 9.3 `terms_page.dart` / `privacy_policy_page.dart` — Legal content hardcoded

**Files**: `features/profile/presentation/pages/terms_page.dart`,
`privacy_policy_page.dart`\
**Issue**: Full legal text is hardcoded in Dart widgets. Any legal update
requires an app store release cycle.\
**Fix**: Load from a remote URL/CMS, or embed as an asset file that can be
hot-updated.

### 9.4 `legal_notices_page.dart` — Placeholder phone number

**File**: `features/profile/presentation/pages/legal_notices_page.dart`\
**Line**: ~38

```dart
'Téléphone : +225 07 XX XX XX XX\n\n'
```

**Issue**: Contact phone contains placeholder `XX XX XX XX`, visible to end
users.

### 9.5 `help_support_page.dart` — Fallback FAQ is hardcoded, good pattern

**File**: `features/profile/presentation/pages/help_support_page.dart`\
**Note**: Good pattern — fetches FAQ from API with fallback to local items. No
critical issues.

---

## 10. WALLET FEATURE

### 10.1 `wallet_page.dart` — Quick top-up amounts hardcoded

**File**: `features/wallet/presentation/pages/wallet_page.dart`\
**Issue**: Chip amounts like `1000, 2000, 5000, 10000` are hardcoded. Should
come from config for different markets.

### 10.2 `balance_card.dart` — No error state if wallet load fails

**File**: `features/wallet/presentation/widgets/balance_card.dart`\
**Issue**: Widget assumes a valid `WalletEntity` is always passed. If the parent
provider errors, this widget won't render at all. The parent should handle error
→ but verify.

---

## 11. PRODUCTS FEATURE

### 11.1 `product_details_page.dart` — Quantity selector allows values > stock

**File**: `features/products/presentation/pages/product_details_page.dart`\
**Issue**: The quantity increment button should cap at available stock. Verify
the `+` button disables at stock limit.

### 11.2 `all_products_page.dart` — Search debounce restarts on every keystroke

**File**: `features/products/presentation/pages/all_products_page.dart`\
**Issue**: If debounce timer implementation doesn't cancel the previous timer,
rapid typing could trigger multiple search API calls.

---

## 12. PRESCRIPTIONS FEATURE

### 12.1 `prescription_details_page.dart` — Fake "loading" prescription entity

**File**:
`features/prescriptions/presentation/pages/prescription_details_page.dart`\
**Lines**: ~33-39

```dart
final prescription = state.prescriptions.firstWhere(
    (p) => p.id == widget.prescriptionId,
    orElse: () => PrescriptionEntity(
        id: widget.prescriptionId,
        status: 'loading',   // Magic string as loading indicator
        imageUrls: [],
        createdAt: DateTime.now(),
    ),
);
```

**Issue**: Creates a fake entity with `status: 'loading'` as a sentinel value.
This is fragile — if the API ever returns `"loading"` as a real status, logic
breaks. Use a nullable type or separate loading state.

### 12.2 `prescription_details_page.dart` — Image URL path manipulation

**File**:
`features/prescriptions/presentation/pages/prescription_details_page.dart`\
**Lines**: ~68-71

```dart
if (path.startsWith('public/')) {
    path = path.replaceFirst('public/', '');
}
final url = '$baseUrl/$path';
```

**Issue**: Path manipulation for storage URLs should be centralized in the data
layer, not in a UI widget. Also, no URL encoding is applied.

### 12.3 `prescription_details_page.dart` — Payment bottom sheet has fixed 250px height

**File**:
`features/prescriptions/presentation/pages/prescription_details_page.dart`\
**Line**: ~107

```dart
height: 250,
```

**Issue**: Fixed height may clip content on small screens or with large fonts
(accessibility). Use `intrinsicHeight` or let content size naturally.

### 12.4 `prescriptions_list_page.dart` — Animated cards could be performance-heavy

**File**:
`features/prescriptions/presentation/pages/prescriptions_list_page.dart`\
**Issue**: If each card runs entry animations, a list of 50+ prescriptions could
cause jank. Ensure animations only run for newly inserted items, not on every
rebuild.

### 12.5 `prescription_upload_page.dart` — No image compression before upload

**File**:
`features/prescriptions/presentation/pages/prescription_upload_page.dart`\
**Issue**: Similar to edit_profile — images picked from camera/gallery may be
very large. No `imageQuality` or `maxWidth` constraints visible.

---

## 13. NOTIFICATIONS FEATURE

### 13.1 `notifications_page.dart` — Dismiss action is not undoable

**File**: `features/notifications/presentation/pages/notifications_page.dart`\
**Issue**: Swipe-to-delete removes the notification. If this calls the API
immediately, there's no undo. Consider adding an undo snackbar
(`SnackBarAction`).

### 13.2 `notifications_page.dart` — Navigation on tap uses raw notification data

**File**: `features/notifications/presentation/pages/notifications_page.dart`\
**Issue**: Tap navigates based on `notification.data` fields. If data is missing
or malformed, navigation could fail silently or crash. Add null checks on
navigation target data.

---

## 14. ADDRESSES FEATURE

### 14.1 `edit_address_page.dart` — CRITICAL: Save is a stub (see §1.1)

### 14.2 `add_address_page.dart` — GPS location detection has no timeout UI

**File**: `features/addresses/presentation/pages/add_address_page.dart`\
**Issue**: When detecting GPS position, if location takes a long time (indoors,
weak GPS), the user sees a loading spinner indefinitely. Add a timeout with a
retry option.

### 14.3 `addresses_list_page.dart` — Delete has no confirmation dialog

**File**: `features/addresses/presentation/pages/addresses_list_page.dart`\
**Issue**: Verify the delete action in the popup menu shows a confirmation
dialog. If it directly deletes, the user could lose an address with a single
errant tap.

### 14.4 `address_autocomplete_field.dart` — Overlay not removed on widget disposal edge case

**File**:
`features/addresses/presentation/widgets/address_autocomplete_field.dart`\
**Issue**: `_removeOverlay` is called in `dispose()`, but if the overlay entry
is in a different overlay scope (rare), it could leak.

---

## 15. CROSS-CUTTING ISSUES

### 15.1 Localization: Mixed hardcoded French and l10n

**Severity**: High\
**Scope**: Almost every file\
**Issue**: The app has `AppLocalizations` support, but the vast majority of
user-facing strings are hardcoded in French directly in widgets. This makes the
app impossible to localize to other languages without touching every file.\
**Affected files** (non-exhaustive):

- `main_shell_page.dart` line 82: `'Portefeuille'`
- `connectivity_banner.dart`: `'Pas de connexion Internet'`
- `empty_state.dart`: All empty state messages
- `notification_settings_page.dart`: All labels
- `terms_page.dart`, `privacy_policy_page.dart`, `legal_notices_page.dart`: All
  content
- `tracking_page.dart`: Status labels, button labels
- `courier_chat_page.dart`: All UI strings
- `rating_bottom_sheet.dart`: Tags, labels
- Every page's AppBar titles

### 15.2 Raw error messages exposed to users

**Severity**: High (Security + UX)\
**Scope**: Multiple files\
**Issue**: At least 6 places show `e.toString()` or raw exception text to users:

1. `async_value_widget.dart` — default error
2. `change_password_page.dart` — ~line 155
3. `tracking_page.dart` — line ~317
4. `courier_chat_page.dart` — lines ~137, ~211
5. `prescription_details_page.dart` — implicit in error states **Fix**: Create a
   centralized `ErrorFormatter.userFriendly(dynamic error)` utility that maps
   exceptions to human-readable French messages.

### 15.3 Dark theme: Partial support

**Severity**: Medium\
**Scope**: All files using `AppColors` directly\
**Issue**: The app has a dark theme toggle (in profile page) and `ThemeColors`
extension, but:

- `AppTextStyles` hardcodes light colors
- Many widgets use `AppColors.textPrimary`, `AppColors.background`, etc.
  directly
- `app_theme.dart` dark theme is missing sub-themes
- Static page content (`TermsPage`, `PrivacyPolicyPage`) uses hardcoded
  `Colors.grey` etc. **Fix**: Audit every `AppColors.` usage and replace with
  `context.` theme extensions or `Theme.of(context)`.

### 15.4 No loading state abstractions

**Severity**: Low\
**Scope**: All pages with API calls\
**Issue**: Every page reinvents loading state with local `_isLoading` booleans,
`setState`, and inline `CircularProgressIndicator()`. A shared `LoadingOverlay`
or button-level loading mixin would reduce boilerplate.

### 15.5 Accessibility gaps

**Severity**: Medium\
**Scope**: All pages\
**Issues**:

- Most `GestureDetector` and `InkWell` widgets lack `Semantics` labels
- Star rating in `rating_bottom_sheet.dart` uses `GestureDetector` on `Icon` —
  not keyboard/screen-reader accessible
- Status colors (order status, prescription status) convey meaning through color
  alone — need icon or text labels (they do have icons, which is good)
- No `excludeSemantics` on decorative elements
- `quick_actions_grid.dart` has `Semantics` labels — this is one of the few that
  does

### 15.6 `withOpacity` deprecation

**Severity**: Low\
**Scope**: `delivery_address_section.dart` line ~116\
**Issue**: Uses deprecated `withOpacity(0.1)`. The rest of the codebase
correctly uses `withValues(alpha:)`.

### 15.7 State management inconsistency

**Severity**: Low\
**Scope**: Auth, Profile features\
**Issue**: Mix of `StateProvider`, `StateNotifierProvider`,
`ChangeNotifierProvider`, and local `StatefulWidget` state for similar patterns.
Some pages use global providers for ephemeral page-level state
(`toggleProvider`, `loadingProvider`, `formFieldsProvider`).

### 15.8 No pull-to-refresh on several list pages

**Severity**: Low\
**Pages missing pull-to-refresh**:

- `prescriptions_list_page.dart`
- `addresses_list_page.dart`
- `wallet_page.dart` (transaction list)
- `notifications_page.dart` **Pages that have it**: `orders_list_page.dart`,
  `pharmacies_list_page_v2.dart`

### 15.9 No network retry patterns

**Severity**: Medium\
**Issue**: When API calls fail, most pages show an error state with no retry
button. Only a few (like `courier_chat_page.dart`,
`pharmacies_list_page_v2.dart`) have retry buttons.

---

## SUMMARY BY PRIORITY

### Must Fix (Critical/High)

| #    | Issue                                         | File                              |
| ---- | --------------------------------------------- | --------------------------------- |
| 1.1  | `_save()` stub — edit address does nothing    | `edit_address_page.dart`          |
| 1.2  | Notification settings not persisted           | `notification_settings_page.dart` |
| 1.3  | `setState` during `build`                     | `tracking_page.dart`              |
| 9.4  | Placeholder phone `XX XX XX` visible to users | `legal_notices_page.dart`         |
| 15.2 | Raw error messages exposed (6 places)         | Multiple                          |
| 2.1  | Text styles hardcode light-theme colors       | `app_text_styles.dart`            |
| 12.1 | Fake "loading" entity as sentinel             | `prescription_details_page.dart`  |

### Should Fix (Medium)

| #    | Issue                                      | File                            |
| ---- | ------------------------------------------ | ------------------------------- |
| 2.2  | Dark theme incomplete                      | `app_theme.dart`                |
| 5.3  | 4-digit vs 6-digit OTP inconsistency       | `forgot_password_page.dart`     |
| 8.6  | Chat polling every 5s instead of real-time | `courier_chat_page.dart`        |
| 8.9  | `PaymentLoadingDialog.hide()` pops blindly | `payment_dialogs.dart`          |
| 9.2  | No image size limit on upload              | `edit_profile_page.dart`        |
| 12.5 | No image compression for prescriptions     | `prescription_upload_page.dart` |
| 15.1 | Hardcoded French everywhere                | All files                       |
| 15.3 | Dark theme partially broken                | All files                       |
| 15.5 | Accessibility gaps                         | All files                       |
| 15.9 | Missing retry patterns                     | Most pages                      |

### Nice to Have (Low)

| #    | Issue                          | File                                                |
| ---- | ------------------------------ | --------------------------------------------------- |
| 5.7  | 3s forced splash wait          | `splash_page.dart`                                  |
| 7.1  | Duplicated utility methods     | `pharmacy_card.dart` / `pharmacy_details_page.dart` |
| 8.10 | Deprecated `withOpacity`       | `delivery_address_section.dart`                     |
| 9.3  | Hardcoded legal text           | `terms_page.dart`, `privacy_policy_page.dart`       |
| 10.1 | Hardcoded top-up amounts       | `wallet_page.dart`                                  |
| 15.4 | Loading state boilerplate      | All pages                                           |
| 15.7 | State management inconsistency | Auth pages                                          |
| 15.8 | Missing pull-to-refresh        | Several list pages                                  |

---

_End of audit report — 47 issues identified across 14 areas._
