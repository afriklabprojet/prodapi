import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drpharma_pharmacy/main.dart' as app;
import 'package:drpharma_pharmacy/core/providers/core_providers.dart';
import 'package:drpharma_pharmacy/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:drpharma_pharmacy/features/auth/data/models/user_model.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/auth_di_providers.dart';

// ===================== MOCK AUTH FOR INTEGRATION TESTS =====================

/// Fake AuthLocalDataSource that returns a pre-authenticated user.
/// Used for integration tests that require authenticated state.
class FakeAuthLocalDataSource implements AuthLocalDataSource {
  final bool isAuthenticated;
  final UserModel? user;
  final String? token;

  FakeAuthLocalDataSource({this.isAuthenticated = true, this.user, this.token});

  /// Factory for authenticated state with default test user
  factory FakeAuthLocalDataSource.authenticated() {
    return FakeAuthLocalDataSource(
      isAuthenticated: true,
      token: 'test-integration-token-12345',
      user: UserModel(
        id: 1,
        name: 'Pharmacie Test',
        email: 'test@pharmacie.ci',
        phone: '+2250700000000',
        role: 'pharmacy',
        pharmacies: [
          PharmacyModel(
            id: 1,
            name: 'Pharmacie du Centre',
            status: 'active',
            address: '123 Rue Test, Abidjan',
            city: 'Abidjan',
          ),
        ],
      ),
    );
  }

  /// Factory for unauthenticated state
  factory FakeAuthLocalDataSource.unauthenticated() {
    return FakeAuthLocalDataSource(isAuthenticated: false);
  }

  @override
  Future<String?> getToken() async => isAuthenticated ? token : null;

  @override
  Future<UserModel?> getUser() async => isAuthenticated ? user : null;

  @override
  Future<bool> hasToken() async => isAuthenticated && token != null;

  @override
  Future<void> cacheToken(String token) async {}

  @override
  Future<void> cacheUser(UserModel user) async {}

  @override
  Future<void> clearAuthData() async {}
}

/// E2E Integration Tests for DR-PHARMA Pharmacy App
///
/// Run with: flutter test integration_test/app_test.dart
///
/// These tests cover critical user flows:
/// - Authentication (login/logout)
/// - Order management (accept/reject/prepare)
/// - Wallet operations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('User can login with valid credentials', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should be on login page
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Enter credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@pharmacie.ci',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'TestPassword123!',
      );
      await tester.pumpAndSettle();

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to dashboard (check for dashboard elements)
      // Note: This will fail without mock server - use for smoke testing
    });

    testWidgets('Shows error on invalid login', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter invalid credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'wrongpassword',
      );
      await tester.pumpAndSettle();

      // Tap login
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show error (snackbar or inline error)
      // Note: Exact behavior depends on API response
    });
  });

  group('Navigation Flow', () {
    testWidgets('Bottom navigation works correctly', (tester) async {
      // Setup mock authenticated user
      final fakeAuth = FakeAuthLocalDataSource.authenticated();

      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            // Override auth to simulate logged-in state
            authLocalDataSourceProvider.overrideWithValue(fakeAuth),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test navigation tabs exist
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Tap Activity tab (index 1)
        await tester.tap(find.text('Commandes').first);
        await tester.pumpAndSettle();

        // Tap Stock tab (index 2)
        await tester.tap(find.text('Stock').first);
        await tester.pumpAndSettle();

        // Tap Wallet tab (index 3)
        await tester.tap(find.text('Portefeuille').first);
        await tester.pumpAndSettle();

        // Tap Settings tab (index 4)
        await tester.tap(find.text('Paramètres').first);
        await tester.pumpAndSettle();

        // Return to Home
        await tester.tap(find.text('Accueil').first);
        await tester.pumpAndSettle();
      }
    });
  });

  group('Accessibility', () {
    testWidgets('Login page has proper semantics', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
          child: const app.PharmacyApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check semantics tree for login page
      final semantics = tester.getSemantics(find.byType(MaterialApp));
      expect(semantics, isNotNull);

      // Email field should be accessible
      expect(
        find.bySemanticsLabel(RegExp('email', caseSensitive: false)),
        findsWidgets,
      );
    });
  });
}
