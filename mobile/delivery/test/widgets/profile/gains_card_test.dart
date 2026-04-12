import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/profile/gains_card.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/models/wallet_data.dart';

void main() {
  Widget buildWidget({
    WalletData? walletData,
    Map<String, dynamic>? courierOverrides,
    double? rating,
    int? completedDeliveries,
  }) {
    final courierData = {
      'id': 1,
      'status': 'active',
      'completed_deliveries': '${completedDeliveries ?? 120}',
      'rating': '${rating ?? 4.7}',
      ...?courierOverrides,
    };
    final user = User.fromJson({
      'id': 1,
      'name': 'Jean Dupont',
      'email': 'jean@test.com',
      'phone': '+2250101010101',
      'courier': courierData,
    });
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GainsCard(user: user, walletData: walletData),
        ),
      ),
    );
  }

  group('GainsCard', () {
    testWidgets('renders with user data', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(GainsCard), findsOneWidget);
    });

    testWidgets('renders with wallet data', (tester) async {
      final walletData = WalletData.fromJson({
        'balance': '25000',
        'pending_earnings': '5000',
        'total_earned': '150000',
        'transactions': [],
      });
      await tester.pumpWidget(buildWidget(walletData: walletData));
      expect(find.byType(GainsCard), findsOneWidget);
    });

    testWidgets('renders without wallet data', (tester) async {
      await tester.pumpWidget(buildWidget(walletData: null));
      expect(find.byType(GainsCard), findsOneWidget);
    });

    testWidgets('contains Text widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('contains Icon widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('contains Container widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('contains Column widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('contains Row widgets', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Row), findsWidgets);
    });

    // ── Label tests ──

    testWidgets('shows "Livraisons" label', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Livraisons'), findsOneWidget);
    });

    testWidgets('shows "Note" label', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Note'), findsOneWidget);
    });

    testWidgets('shows "Gains" label', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Gains'), findsOneWidget);
    });

    testWidgets('shows "Solde disponible" label', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Solde disponible'), findsOneWidget);
    });

    testWidgets('shows "FCFA" badge', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('FCFA'), findsOneWidget);
    });

    testWidgets('shows "Rechargé" label', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Rechargé'), findsOneWidget);
    });

    testWidgets('shows "Commissions" label', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Commissions'), findsOneWidget);
    });

    // ── Rating display ──

    testWidgets('shows formatted rating when > 0', (tester) async {
      await tester.pumpWidget(buildWidget(rating: 4.7));
      expect(find.text('4.7'), findsOneWidget);
    });

    testWidgets('shows "--" when rating is 0', (tester) async {
      await tester.pumpWidget(buildWidget(rating: 0));
      expect(find.text('--'), findsOneWidget);
    });

    // ── Deliveries count ──

    testWidgets('shows delivery count from wallet data when available', (
      tester,
    ) async {
      final walletData = WalletData.fromJson({
        'balance': '1000',
        'pending_earnings': '0',
        'total_earned': '5000',
        'deliveries_count': 42,
        'transactions': [],
      });
      await tester.pumpWidget(buildWidget(walletData: walletData));
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('falls back to courier completedDeliveries when wallet null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(walletData: null, completedDeliveries: 88),
      );
      expect(find.text('88'), findsOneWidget);
    });

    // ── Icons ──

    testWidgets('shows shipping icon for deliveries', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets('shows star icon for rating', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('shows trending up icon for gains', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('shows down arrow icon for topups', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('shows receipt icon for commissions', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });
  });
}
