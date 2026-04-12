import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/error/error_boundary.dart';

void main() {
  group('ErrorCard', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Something went wrong')),
        ),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('shows details when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorCard(
              message: 'Error occurred',
              details: 'Stack trace info here',
            ),
          ),
        ),
      );
      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Stack trace info here'), findsOneWidget);
    });

    testWidgets('hides details when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Error')),
        ),
      );
      expect(find.text('Error'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(message: 'Error', onRetry: () => retried = true),
          ),
        ),
      );
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retried, true);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Error')),
        ),
      );
      expect(find.text('Réessayer'), findsNothing);
    });

    testWidgets('renders in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ErrorCard(message: 'Dark error', details: 'Details in dark'),
          ),
        ),
      );
      expect(find.text('Dark error'), findsOneWidget);
      expect(find.text('Details in dark'), findsOneWidget);
    });
  });

  group('LoadingErrorWidget', () {
    testWidgets('shows loading indicator when isLoading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(isLoading: true, child: Text('Content')),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Content'), findsNothing);
    });

    testWidgets('shows error when error is set', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: false,
              error: 'Something failed',
              child: Text('Content'),
            ),
          ),
        ),
      );
      expect(find.text('Something failed'), findsOneWidget);
      expect(find.text('Content'), findsNothing);
    });

    testWidgets('shows child when not loading and no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(isLoading: false, child: Text('Content')),
          ),
        ),
      );
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('error with retry button calls onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: false,
              error: 'Failed',
              onRetry: () => retried = true,
              child: const Text('Content'),
            ),
          ),
        ),
      );
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retried, true);
    });

    testWidgets('loading takes precedence over error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: true,
              error: 'Error',
              child: Text('Content'),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Error'), findsNothing);
    });
  });

  group('GlobalErrorHandler', () {
    test('is singleton', () {
      final h1 = GlobalErrorHandler();
      final h2 = GlobalErrorHandler();
      expect(identical(h1, h2), true);
    });

    test('reportError emits to errorStream', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      handler.reportError('Test error', type: ErrorType.custom);
      await Future.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors[0].message, 'Test error');
      expect(errors[0].type, ErrorType.custom);

      await sub.cancel();
    });

    test('reportError with stackTrace', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      final stack = StackTrace.current;
      handler.reportError(
        'Stack error',
        stackTrace: stack,
        extra: {'key': 'value'},
      );
      await Future.delayed(Duration.zero);

      expect(errors[0].stackTrace, stack);
      expect(errors[0].extra?['key'], 'value');

      await sub.cancel();
    });

    test('reportError with different error types', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      handler.reportError('Network', type: ErrorType.network);
      handler.reportError('API', type: ErrorType.api);
      handler.reportError('Validation', type: ErrorType.validation);
      await Future.delayed(Duration.zero);

      expect(errors.length, 3);
      expect(errors[0].type, ErrorType.network);
      expect(errors[1].type, ErrorType.api);
      expect(errors[2].type, ErrorType.validation);

      await sub.cancel();
    });

    test('runSafely returns result on success', () async {
      final handler = GlobalErrorHandler();
      final result = await handler.runSafely(() async => 42);
      expect(result, 42);
    });

    test('runSafely returns fallback on error', () async {
      final handler = GlobalErrorHandler();
      final result = await handler.runSafely(
        () async => throw Exception('fail'),
        fallback: -1,
      );
      expect(result, -1);
    });

    test('runSafely returns null on error without fallback', () async {
      final handler = GlobalErrorHandler();
      final result = await handler.runSafely<int>(
        () async => throw Exception('fail'),
      );
      expect(result, isNull);
    });

    test('runSafely reports error to stream', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      await handler.runSafely(
        () async => throw Exception('tracked'),
        errorMessage: 'Custom message',
      );
      await Future.delayed(Duration.zero);

      expect(errors.length, 1);
      expect(errors[0].message, 'Custom message');

      await sub.cancel();
    });
  });

  group('AppError', () {
    test('toString formats correctly', () {
      final error = AppError(
        type: ErrorType.network,
        message: 'Connection failed',
        timestamp: DateTime(2024, 1, 15),
      );
      expect(error.toString(), '[ErrorType.network] Connection failed');
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final stack = StackTrace.current;
      final error = AppError(
        type: ErrorType.flutter,
        message: 'Widget build failed',
        stackTrace: stack,
        timestamp: now,
        extra: {'widget': 'HomeScreen'},
      );
      expect(error.type, ErrorType.flutter);
      expect(error.message, 'Widget build failed');
      expect(error.stackTrace, stack);
      expect(error.timestamp, now);
      expect(error.extra?['widget'], 'HomeScreen');
    });
  });

  group('ErrorType', () {
    test('has all expected values', () {
      expect(ErrorType.values.length, 6);
      expect(ErrorType.values, contains(ErrorType.flutter));
      expect(ErrorType.values, contains(ErrorType.platform));
      expect(ErrorType.values, contains(ErrorType.network));
      expect(ErrorType.values, contains(ErrorType.api));
      expect(ErrorType.values, contains(ErrorType.validation));
      expect(ErrorType.values, contains(ErrorType.custom));
    });
  });

  group('ErrorBoundary widget', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: Text('Hello'))),
      );
      expect(find.text('Hello'), findsOneWidget);
    });
  });

  group('SafeZone extension', () {
    testWidgets('withErrorBoundary wraps widget', (tester) async {
      final widget = const Text('Wrapped');
      final wrapped = widget.withErrorBoundary();

      await tester.pumpWidget(MaterialApp(home: wrapped));
      expect(find.text('Wrapped'), findsOneWidget);
      expect(find.byType(ErrorBoundary), findsOneWidget);
    });

    testWidgets('withErrorBoundary passes callbacks', (tester) async {
      FlutterErrorDetails? capturedError;
      final widget = const Text('Safe');
      final wrapped = widget.withErrorBoundary(
        onError: (e) => capturedError = e,
      );

      await tester.pumpWidget(MaterialApp(home: wrapped));
      expect(find.text('Safe'), findsOneWidget);
      expect(capturedError, isNull);
    });
  });
}
