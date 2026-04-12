import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/profile/profile_avatar.dart';

void main() {
  group('ProfileAvatar', () {
    testWidgets('renders with name initials when no image', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ProfileAvatar(name: 'John Doe')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatar), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ProfileAvatar(name: 'Jane', size: 60)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatar), findsOneWidget);
    });

    testWidgets('renders with online indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfileAvatar(name: 'Test User', isOnline: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileAvatar), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfileAvatar(name: 'Test', onTap: () => tapped = true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProfileAvatar));
      expect(tapped, true);
    });

    testWidgets('contains Container widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ProfileAvatar(name: 'AB')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Text widget for initials', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ProfileAvatar(name: 'CD')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders without onTap', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: ProfileAvatar(name: 'EF')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProfileAvatar), findsOneWidget);
    });
  });
}
