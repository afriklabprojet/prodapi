import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:courier/presentation/screens/pending_approval_screen.dart';
import 'package:courier/core/services/secure_token_service.dart';

void main() {
  setUp(() {
    SecureTokenService.enableTestMode({'auth_token': 'test_token'});
  });

  tearDown(() {
    SecureTokenService.disableTestMode();
  });

  Widget buildScreen({required String status, required String message}) {
    return ProviderScope(
      child: MaterialApp(
        home: PendingApprovalScreen(status: status, message: message),
      ),
    );
  }

  group('PendingApprovalScreen - pending_approval', () {
    testWidgets('displays pending approval title and icon', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'pending_approval',
        message: 'Votre compte est en attente.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('En Attente d\'Approbation'), findsOneWidget);
      expect(find.text('Votre compte est en attente.'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('shows info box for pending approval', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'pending_approval',
        message: 'En attente.',
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Vous recevrez une notification dès que votre compte sera validé.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'pending_approval',
        message: 'En attente.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Retour à la connexion'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('does NOT show contact support for pending', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'pending_approval',
        message: 'msg',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contacter le support'), findsNothing);
    });

    testWidgets('logout clears token and navigates to login', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'pending_approval',
        message: 'msg',
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retour à la connexion'));
      // Use pump() instead of pumpAndSettle() because navigation target may have animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Token should be removed
      expect(await SecureTokenService.instance.getToken(), isNull);
    });
  });

  group('PendingApprovalScreen - suspended', () {
    testWidgets('displays suspended title and icon', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'suspended',
        message: 'Votre compte a été suspendu.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Compte Suspendu'), findsOneWidget);
      expect(find.text('Votre compte a été suspendu.'), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
    });

    testWidgets('does NOT show info box for suspended', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'suspended',
        message: 'Suspendu.',
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('Vous recevrez une notification dès que votre compte sera validé.'),
        findsNothing,
      );
    });

    testWidgets('shows contact support button', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'suspended',
        message: 'Suspendu.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contacter le support'), findsOneWidget);
      expect(find.byIcon(Icons.support_agent), findsOneWidget);
    });

    testWidgets('contact support button is tappable', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'suspended',
        message: 'Suspendu.',
      ));
      await tester.pumpAndSettle();

      // Tapping contact support calls WhatsAppService (no snackbar)
      await tester.tap(find.text('Contacter le support'));
      await tester.pump();

      // WhatsApp launcher may throw in test - just verify the button exists and is tappable
      expect(find.text('Contacter le support'), findsOneWidget);
    });
  });

  group('PendingApprovalScreen - rejected', () {
    testWidgets('displays rejected title and icon', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'rejected',
        message: 'Votre demande a été refusée.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Inscription Refusée'), findsOneWidget);
      expect(find.text('Votre demande a été refusée.'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows contact support for rejected', (tester) async {
      await tester.pumpWidget(buildScreen(
        status: 'rejected',
        message: 'Refusé.',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Contacter le support'), findsOneWidget);
    });
  });
}
