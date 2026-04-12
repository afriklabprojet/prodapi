import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:drpharma_client/features/products/presentation/widgets/product_reviews_section.dart';
import 'package:drpharma_client/l10n/app_localizations.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

/// FakeApiClient extended to return review data for testing.
class FakeApiClientWithReviews extends FakeApiClient {
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (path.contains('reviews')) {
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: {
          'data': [
            {
              'id': 1,
              'user_name': 'Jean Dupont',
              'rating': 4,
              'comment': 'Très bon produit, efficace',
              'tags': <String>[],
              'created_at': '2024-01-15T00:00:00.000Z',
            },
          ],
          'meta': {'average_rating': 4.0, 'total': 1},
        },
      );
    }
    return super.get(path, queryParameters: queryParameters, options: options);
  }
}

void main() {
  const int testProductId = 1;

  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  Widget createEmptyWidget() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ProductReviewsSection(productId: testProductId),
          ),
        ),
      ),
    );
  }

  Widget createWidgetWithReviews() {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClientWithReviews()),
      ],
      child: MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ProductReviewsSection(productId: testProductId),
          ),
        ),
      ),
    );
  }

  group('ProductReviewsSection Widget Tests', () {
    testWidgets('shows Aucun avis when reviews list is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createEmptyWidget());
      await tester.pumpAndSettle();
      expect(find.text('Aucun avis pour le moment'), findsOneWidget);
    });

    testWidgets('shows rate_review icon in empty state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createEmptyWidget());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.rate_review_outlined), findsOneWidget);
    });

    testWidgets('shows Avis vérifiés title when reviews exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.text('Avis vérifiés'), findsOneWidget);
    });

    testWidgets('shows verified icon next to avis count', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.verified), findsAtLeastNWidgets(1));
    });

    testWidgets('shows user name in review card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.textContaining('Jean'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows review comment in card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.textContaining('Très bon'), findsOneWidget);
    });

    testWidgets('shows star icons in review card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });

    testWidgets('shows avis count text when reviews exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.textContaining('avis'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows average rating value in rating summary', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.textContaining('4.0'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Basé sur text in rating summary', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetWithReviews());
      await tester.pumpAndSettle();
      expect(find.textContaining('Basé sur'), findsOneWidget);
    });

    testWidgets('empty state shows invitation to buy product', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createEmptyWidget());
      await tester.pumpAndSettle();
      expect(find.textContaining('soyez le premier'), findsOneWidget);
    });
  });
}
