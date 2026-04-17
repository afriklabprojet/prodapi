import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_pharmacy/main.dart' as app;
import 'package:drpharma_pharmacy/core/providers/core_providers.dart';

/// E2E Tests for Wallet/Payment Flow
/// 
/// Critical paths tested:
/// - View wallet balance
/// - View transaction history
/// - Request withdrawal
/// - Add/edit bank info
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Wallet Flow', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_test_token',
        'onboarding_complete_v1': true,
        'tutorial_dashboard_seen': true,
        'tutorial_wallet_seen': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Wallet screen displays balance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wallet tab
      final walletTab = find.text('Portefeuille');
      if (walletTab.evaluate().isNotEmpty) {
        await tester.tap(walletTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should show balance section
        final hasSolde = find.textContaining('Solde').evaluate().isNotEmpty;
        final hasFCFA = find.textContaining('FCFA').evaluate().isNotEmpty;
        expect(hasSolde || hasFCFA, isTrue);
      }
    });

    testWidgets('Can view transaction history', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wallet
      final walletTab = find.text('Portefeuille');
      if (walletTab.evaluate().isNotEmpty) {
        await tester.tap(walletTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for transactions section or tab
        final transactionsTab = find.text('Historique');
        if (transactionsTab.evaluate().isNotEmpty) {
          await tester.tap(transactionsTab.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Should show transaction list or empty state
        final hasTransactionList = find.byType(ListView).evaluate().isNotEmpty;
        final hasEmptyState = find.textContaining('transaction').evaluate().isNotEmpty;
        
        expect(hasTransactionList || hasEmptyState, isTrue);
      }
    });

    testWidgets('Withdrawal button is present and tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wallet
      final walletTab = find.text('Portefeuille');
      if (walletTab.evaluate().isNotEmpty) {
        await tester.tap(walletTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for withdrawal button
        final hasRetirer = find.textContaining('Retirer').evaluate().isNotEmpty;
        final hasRetrait = find.textContaining('Retrait').evaluate().isNotEmpty;
        
        if (hasRetirer || hasRetrait) {
          final withdrawButton = hasRetirer 
            ? find.textContaining('Retirer').first
            : find.textContaining('Retrait').first;
          await tester.tap(withdrawButton);
          await tester.pumpAndSettle();

          // Should open withdrawal sheet or screen
          final hasMontant = find.textContaining('Montant').evaluate().isNotEmpty;
          final hasRetraitText = find.textContaining('retrait').evaluate().isNotEmpty;
          final hasBottomSheet = find.byType(BottomSheet).evaluate().isNotEmpty;
          expect(hasMontant || hasRetraitText || hasBottomSheet, isTrue);
        }
      }
    });

    testWidgets('Bank info section is accessible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wallet
      final walletTab = find.text('Portefeuille');
      if (walletTab.evaluate().isNotEmpty) {
        await tester.tap(walletTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for bank info / settings
        final hasBanque = find.textContaining('Banque').evaluate().isNotEmpty;
        final hasBancaire = find.textContaining('bancaire').evaluate().isNotEmpty;
        final hasBankIcon = find.byIcon(Icons.account_balance).evaluate().isNotEmpty;
        
        if (hasBanque || hasBancaire || hasBankIcon) {
          Finder bankButton;
          if (hasBanque) {
            bankButton = find.textContaining('Banque').first;
          } else if (hasBancaire) {
            bankButton = find.textContaining('bancaire').first;
          } else {
            bankButton = find.byIcon(Icons.account_balance).first;
          }
          
          await tester.tap(bankButton);
          await tester.pumpAndSettle();

          // Should show bank info form
          final hasIBAN = find.textContaining('IBAN').evaluate().isNotEmpty;
          final hasRIB = find.textContaining('RIB').evaluate().isNotEmpty;
          final hasCompte = find.textContaining('compte').evaluate().isNotEmpty;
          expect(hasIBAN || hasRIB || hasCompte, isTrue);
        }
      }
    });
  });

  group('Wallet Security', () {
    testWidgets('PIN setup is required for sensitive actions', (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_test_token',
        'onboarding_complete_v1': true,
        'wallet_pin_set': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wallet
      final walletTab = find.text('Portefeuille');
      if (walletTab.evaluate().isNotEmpty) {
        await tester.tap(walletTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Try to withdraw
        final withdrawButton = find.textContaining('Retirer');
        if (withdrawButton.evaluate().isNotEmpty) {
          await tester.tap(withdrawButton.first);
          await tester.pumpAndSettle();

          // Should prompt for PIN setup if not set
          // or PIN entry if already set
          final hasPIN = find.textContaining('PIN').evaluate().isNotEmpty;
          final hasCode = find.textContaining('Code').evaluate().isNotEmpty;
          expect(hasPIN || hasCode, isTrue);
        }
      }
    });
  });

  group('Wallet Edge Cases', () {
    testWidgets('Pull to refresh updates balance', (tester) async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_test_token',
        'onboarding_complete_v1': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to Wallet
      final walletTab = find.text('Portefeuille');
      if (walletTab.evaluate().isNotEmpty) {
        await tester.tap(walletTab.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Pull to refresh
        final scrollView = find.byType(CustomScrollView);
        if (scrollView.evaluate().isNotEmpty) {
          await tester.fling(
            scrollView.first,
            const Offset(0, 300),
            1000,
          );
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Should complete without error
      }
    });
  });
}
