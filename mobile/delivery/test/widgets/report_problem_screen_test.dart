import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:courier/presentation/screens/report_problem_screen.dart';
import 'package:courier/core/network/api_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
  });

  group('ReportProblemScreen', () {
    Widget buildTestWidget({bool withMockDio = false}) {
      return ProviderScope(
        overrides: [
          if (withMockDio) dioProvider.overrideWithValue(mockDio),
        ],
        child: const MaterialApp(home: ReportProblemScreen()),
      );
    }

    testWidgets('shows header title', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Signaler un problème'), findsOneWidget);
    });

    testWidgets('shows category selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Type de problème'), findsOneWidget);
      expect(find.text('Problème technique'), findsOneWidget);
      expect(find.text('Problème de paiement'), findsOneWidget);
      expect(find.text('Problème de livraison'), findsOneWidget);
    });

    testWidgets('shows subject and description fields', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Sujet'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Envoyer le signalement'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Envoyer le signalement'), findsOneWidget);
    });

    testWidgets('validates empty subject', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le signalement');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Veuillez entrer un sujet'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates short subject', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'Hi');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le signalement');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('au moins 5 caractères'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty description', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Valid subject text here');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le signalement');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Veuillez décrire'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates short description', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Valid subject text here');
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'Short');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le signalement');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('au moins 20 caractères'), findsAtLeastNWidgets(1));
    });

    testWidgets('can select different categories', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on "Problème de paiement"
      await tester.tap(find.text('Problème de paiement'));
      await tester.pumpAndSettle();
      // No crash = category changed successfully
    });

    testWidgets('shows info message', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('24h'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('24h'), findsOneWidget);
    });

    testWidgets('shows call alternative button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Préférez-vous appeler ?'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Préférez-vous appeler ?'), findsOneWidget);
    });

    testWidgets('shows all category options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Problème de portefeuille'), findsOneWidget);
      expect(find.text('Problème de compte'), findsOneWidget);
      expect(find.text('Autre'), findsOneWidget);
    });

    // --- Submit flow tests ---

    Future<void> fillFormAndSubmit(WidgetTester tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Application ne répond pas');
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'L\'application se bloque quand je clique sur livraison en cours');
      await tester.pumpAndSettle();

      final submitButton = find.text('Envoyer le signalement');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
    }

    testWidgets('successful submit shows success dialog', (tester) async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                data: {'message': 'ok'},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      await tester.pumpWidget(buildTestWidget(withMockDio: true));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Signalement envoyé !'), findsOneWidget);
      expect(find.text('Compris'), findsOneWidget);
    });

    testWidgets('successful submit dialog - Compris closes dialog', (tester) async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                data: {'message': 'ok'},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(mockDio)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Signalement envoyé !'), findsOneWidget);
      await tester.tap(find.text('Compris'));
      await tester.pumpAndSettle();

      // Should have navigated back
      expect(find.text('Signalement envoyé !'), findsNothing);
    });

    testWidgets('failed submit shows error snackbar', (tester) async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: 500,
              data: {'message': 'Internal Server Error'},
              requestOptions: RequestOptions(path: ''),
            ),
          ));

      await tester.pumpWidget(buildTestWidget(withMockDio: true));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur lors de l\'envoi'), findsOneWidget);
    });

    testWidgets('loading state shows CircularProgressIndicator during submit', (tester) async {
      final completer = Completer<Response>();
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget(withMockDio: true));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pump(); // Don't settle - loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to avoid timer issues
      completer.complete(Response(
        data: {'message': 'ok'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('submit sends correct category', (tester) async {
      Map<String, dynamic>? sentData;
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((invocation) async {
        sentData = invocation.namedArguments[const Symbol('data')] as Map<String, dynamic>?;
        return Response(
          data: {'message': 'ok'},
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      await tester.pumpWidget(buildTestWidget(withMockDio: true));
      await tester.pumpAndSettle();

      // Select payment category
      await tester.tap(find.text('Problème de paiement'));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(sentData, isNotNull);
      expect(sentData!['category'], 'payment');
      expect(sentData!['subject'], 'Application ne répond pas');
    });

    testWidgets('submit calls correct API endpoint', (tester) async {
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                data: {'message': 'ok'},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      await tester.pumpWidget(buildTestWidget(withMockDio: true));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pumpAndSettle();

      verify(() => mockDio.post('/courier/report-problem', data: any(named: 'data'))).called(1);
    });

    testWidgets('button disabled during submission', (tester) async {
      final completer = Completer<Response>();
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestWidget(withMockDio: true));
      await tester.pumpAndSettle();

      await fillFormAndSubmit(tester);
      await tester.pump();

      // The submit button should be disabled (ElevatedButton with onPressed: null)
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);
      expect(button.onPressed, isNull);

      completer.complete(Response(
        data: {'message': 'ok'},
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));
      await tester.pumpAndSettle();
    });
  });
}
