# Touch Targets Accessibility Audit

## Minimum Requirements (Material Design Guidelines)

- **Minimum touch target size**: 48x48 dp
- **Recommended spacing between targets**: 8dp

## Quick Fixes

### 1. Use `IconButton` instead of raw `Icon` with `GestureDetector`

```dart
// ❌ Bad - touch target may be too small
GestureDetector(
  onTap: () {},
  child: Icon(Icons.close, size: 20),
)

// ✅ Good - IconButton ensures 48dp minimum
IconButton(
  onPressed: () {},
  icon: Icon(Icons.close, size: 20),
)
```

### 2. Use `InkWell` with explicit constraints

```dart
// ❌ Bad - no minimum size
InkWell(
  onTap: () {},
  child: Text('X'),
)

// ✅ Good - ensure minimum hit area
InkWell(
  onTap: () {},
  child: ConstrainedBox(
    constraints: BoxConstraints(minHeight: 48, minWidth: 48),
    child: Center(child: Text('X')),
  ),
)
```

### 3. Use `SizedBox` wrapper for small icons

```dart
// ✅ Ensures touch target is always 48x48
SizedBox(
  width: 48,
  height: 48,
  child: Center(
    child: IconButton(
      icon: Icon(Icons.edit, size: 18),
      onPressed: () {},
    ),
  ),
)
```

## Areas to Review

Based on codebase search, check these files for potential issues:

### High Priority (Interactive Elements)

- [ ] `lib/features/orders/presentation/widgets/swipeable_order_card.dart`
- [ ] `lib/features/orders/presentation/widgets/enhanced_order_card.dart`
- [ ] `lib/features/wallet/presentation/screens/wallet_withdraw_sheet.dart`
- [ ] `lib/features/chat/presentation/pages/chat_page.dart`
- [ ] `lib/features/notifications/presentation/pages/notifications_page.dart`

### Medium Priority

- [ ] `lib/features/prescriptions/presentation/widgets/prescription_image_viewer.dart`
- [ ] `lib/features/inventory/presentation/widgets/`
- [ ] `lib/features/profile/presentation/pages/`

## Automated Testing

Add this test to verify touch targets:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Touch targets are at least 48x48', (tester) async {
    await tester.pumpWidget(MyApp());
    
    final tappable = find.byWidgetPredicate((widget) =>
      widget is GestureDetector ||
      widget is InkWell ||
      widget is IconButton
    );
    
    for (final element in tappable.evaluate()) {
      final size = element.size;
      expect(
        size!.width >= 48 && size.height >= 48,
        isTrue,
        reason: 'Touch target ${element.widget.runtimeType} is ${size.width}x${size.height}, should be at least 48x48',
      );
    }
  });
}
```

## Standard Tappable Widget

Consider using this wrapper for consistency:

```dart
/// Ensures minimum touch target of 48x48 dp
class TappableArea extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;
  
  const TappableArea({
    required this.child,
    this.onTap,
    this.minSize = 48,
    super.key,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minSize,
          minHeight: minSize,
        ),
        child: Center(child: child),
      ),
    );
  }
}
```

## Status

- [ ] Review completed
- [ ] Critical issues fixed
- [ ] Secondary issues documented for next sprint
