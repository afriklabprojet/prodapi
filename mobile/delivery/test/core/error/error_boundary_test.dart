import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/error/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorBoundary(child: const Text('Hello'))),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders with custom errorBuilder parameter stored', (
      tester,
    ) async {
      Widget customBuilder(FlutterErrorDetails d) =>
          Text('Error: ${d.exceptionAsString()}');
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            errorBuilder: customBuilder,
            child: const Text('Content'),
          ),
        ),
      );
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('showErrorDetails defaults based on kDebugMode', (
      tester,
    ) async {
      const boundary = ErrorBoundary(child: SizedBox());
      // In test mode kDebugMode is true, so showErrorDetails defaults to true
      expect(boundary.showErrorDetails, isTrue);
    });

    testWidgets('showErrorDetails can be set to false', (tester) async {
      const boundary = ErrorBoundary(
        showErrorDetails: false,
        child: SizedBox(),
      );
      expect(boundary.showErrorDetails, isFalse);
    });

    testWidgets('onError callback is stored', (tester) async {
      var errorReceived = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onError: (_) => errorReceived = true,
            child: const Text('Test'),
          ),
        ),
      );
      expect(find.text('Test'), findsOneWidget);
      // errorReceived would be true if an error occurred
      expect(errorReceived, isFalse);
    });

    testWidgets('withErrorBoundary extension wraps widget', (tester) async {
      final widget = const Text('wrapped').withErrorBoundary();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(ErrorBoundary), findsOneWidget);
      expect(find.text('wrapped'), findsOneWidget);
    });

    testWidgets('withErrorBoundary with custom builders', (tester) async {
      var onErrorCalled = false;
      final widget = const Text('content').withErrorBoundary(
        errorBuilder: (_) => const Text('custom error'),
        onError: (_) => onErrorCalled = true,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('content'), findsOneWidget);
      // onErrorCalled would be true if an error occurred
      expect(onErrorCalled, isFalse);
    });
  });

  group('ErrorCard', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Something went wrong')),
        ),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders warning icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Error')),
        ),
      );
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('renders details when provided', (tester) async {
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

    testWidgets('does not show details when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Error')),
        ),
      );
      // Only the message and icon, no details text
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
      expect(retried, isTrue);
    });

    testWidgets('no retry button when onRetry is null', (tester) async {
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
            body: ErrorCard(message: 'Dark error', details: 'Dark details'),
          ),
        ),
      );
      expect(find.text('Dark error'), findsOneWidget);
      expect(find.text('Dark details'), findsOneWidget);
    });
  });

  group('LoadingErrorWidget', () {
    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
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

    testWidgets('shows ErrorCard when error is set', (tester) async {
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
            body: LoadingErrorWidget(
              isLoading: false,
              child: Text('Real Content'),
            ),
          ),
        ),
      );
      expect(find.text('Real Content'), findsOneWidget);
    });

    testWidgets('error takes priority over child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: false,
              error: 'Error message',
              child: Text('Child'),
            ),
          ),
        ),
      );
      expect(find.text('Error message'), findsOneWidget);
      expect(find.text('Child'), findsNothing);
    });

    testWidgets('loading takes priority over error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: true,
              error: 'Error here',
              child: Text('Child'),
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Error here'), findsNothing);
      expect(find.text('Child'), findsNothing);
    });

    testWidgets('error with retry callback triggers callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: false,
              error: 'Network error',
              onRetry: () => retried = true,
              child: const Text('Child'),
            ),
          ),
        ),
      );
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });
  });

  group('ErrorType', () {
    test('has all 6 values', () {
      expect(ErrorType.values.length, 6);
    });

    test('contains expected values', () {
      expect(ErrorType.values, contains(ErrorType.flutter));
      expect(ErrorType.values, contains(ErrorType.platform));
      expect(ErrorType.values, contains(ErrorType.network));
      expect(ErrorType.values, contains(ErrorType.api));
      expect(ErrorType.values, contains(ErrorType.validation));
      expect(ErrorType.values, contains(ErrorType.custom));
    });
  });

  group('AppError', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final error = AppError(
        type: ErrorType.network,
        message: 'Connection lost',
        timestamp: now,
      );
      expect(error.type, ErrorType.network);
      expect(error.message, 'Connection lost');
      expect(error.timestamp, now);
      expect(error.stackTrace, isNull);
      expect(error.extra, isNull);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final stack = StackTrace.current;
      final error = AppError(
        type: ErrorType.api,
        message: 'API failed',
        stackTrace: stack,
        timestamp: now,
        extra: {'statusCode': 500, 'endpoint': '/users'},
      );
      expect(error.type, ErrorType.api);
      expect(error.stackTrace, stack);
      expect(error.extra!['statusCode'], 500);
      expect(error.extra!['endpoint'], '/users');
    });

    test('toString formats correctly', () {
      final error = AppError(
        type: ErrorType.flutter,
        message: 'Widget overflow',
        timestamp: DateTime.now(),
      );
      expect(error.toString(), '[ErrorType.flutter] Widget overflow');
    });

    test('toString with custom type', () {
      final error = AppError(
        type: ErrorType.custom,
        message: 'My error',
        timestamp: DateTime.now(),
      );
      expect(error.toString(), contains('custom'));
      expect(error.toString(), contains('My error'));
    });

    test('toString with validation type', () {
      final error = AppError(
        type: ErrorType.validation,
        message: 'Invalid input',
        timestamp: DateTime.now(),
      );
      expect(error.toString(), '[ErrorType.validation] Invalid input');
    });
  });

  group('GlobalErrorHandler', () {
    test('returns same singleton instance', () {
      final handler1 = GlobalErrorHandler();
      final handler2 = GlobalErrorHandler();
      expect(identical(handler1, handler2), isTrue);
    });

    test('errorStream emits reported errors', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      handler.reportError('Test error 1');
      handler.reportError('Test error 2', type: ErrorType.network);
      handler.reportError('Test error 3', extra: {'key': 'value'});

      // Allow stream to propagate
      await Future.delayed(Duration.zero);

      expect(errors.length, 3);
      expect(errors[0].message, 'Test error 1');
      expect(errors[0].type, ErrorType.custom);
      expect(errors[1].message, 'Test error 2');
      expect(errors[1].type, ErrorType.network);
      expect(errors[2].extra!['key'], 'value');

      await sub.cancel();
    });

    test('reportError with stackTrace', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);
      final stack = StackTrace.current;

      handler.reportError('Stack error', stackTrace: stack);
      await Future.delayed(Duration.zero);

      expect(errors.length, greaterThanOrEqualTo(1));
      final lastError = errors.last;
      expect(lastError.message, 'Stack error');
      expect(lastError.stackTrace, stack);

      await sub.cancel();
    });

    test('runSafely returns value on success', () async {
      final handler = GlobalErrorHandler();
      final result = await handler.runSafely(() async => 42);
      expect(result, 42);
    });

    test('runSafely returns fallback on error', () async {
      final handler = GlobalErrorHandler();
      final result = await handler.runSafely<int>(
        () async => throw Exception('fail'),
        fallback: -1,
      );
      expect(result, -1);
    });

    test('runSafely returns null when no fallback and error', () async {
      final handler = GlobalErrorHandler();
      final result = await handler.runSafely<String>(
        () async => throw Exception('fail'),
      );
      expect(result, isNull);
    });

    test('runSafely reports error to stream on failure', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      await handler.runSafely(
        () async => throw Exception('tracked'),
        errorMessage: 'Custom message',
      );
      await Future.delayed(Duration.zero);

      expect(errors.any((e) => e.message == 'Custom message'), isTrue);

      await sub.cancel();
    });

    test('runSafely uses exception toString when no errorMessage', () async {
      final handler = GlobalErrorHandler();
      final errors = <AppError>[];
      final sub = handler.errorStream.listen(errors.add);

      await handler.runSafely(() async => throw Exception('native msg'));
      await Future.delayed(Duration.zero);

      expect(errors.any((e) => e.message.contains('native msg')), isTrue);

      await sub.cancel();
    });

    test('errorStream is broadcast — multiple listeners', () async {
      final handler = GlobalErrorHandler();
      final list1 = <AppError>[];
      final list2 = <AppError>[];
      final sub1 = handler.errorStream.listen(list1.add);
      final sub2 = handler.errorStream.listen(list2.add);

      handler.reportError('broadcast test');
      await Future.delayed(Duration.zero);

      expect(list1.length, greaterThanOrEqualTo(1));
      expect(list2.length, greaterThanOrEqualTo(1));

      await sub1.cancel();
      await sub2.cancel();
    });
  });

  group('ErrorCard styling', () {
    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ErrorCard(
              message: 'Light theme error',
              details: 'Additional info',
            ),
          ),
        ),
      );
      expect(find.text('Light theme error'), findsOneWidget);
      expect(find.text('Additional info'), findsOneWidget);
    });

    testWidgets('renders retry button with icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(message: 'Retry error', onRetry: () {}),
          ),
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('message uses proper text styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorCard(message: 'Styled message')),
        ),
      );

      final textFinder = find.text('Styled message');
      expect(textFinder, findsOneWidget);

      final text = tester.widget<Text>(textFinder);
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('details appear below message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorCard(message: 'Main message', details: 'Detail text'),
          ),
        ),
      );

      // Both texts should be present
      expect(find.text('Main message'), findsOneWidget);
      expect(find.text('Detail text'), findsOneWidget);
    });
  });

  group('LoadingErrorWidget additional tests', () {
    testWidgets('shows centered loading indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(isLoading: true, child: SizedBox()),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('onRetry is passed to ErrorCard', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingErrorWidget(
              isLoading: false,
              error: 'Error',
              onRetry: () => retryCalled = true,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Réessayer'));
      expect(retryCalled, isTrue);
    });
  });
}
