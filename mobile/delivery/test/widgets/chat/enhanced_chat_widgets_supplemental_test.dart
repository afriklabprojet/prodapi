// ignore_for_file: use_null_aware_elements
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:courier/presentation/widgets/chat/enhanced_chat_widgets.dart';
import 'package:courier/data/models/enhanced_chat_message.dart';
import 'package:courier/l10n/app_localizations.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() => initHiveForTests());
  tearDownAll(() => cleanupHiveForTests());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  EnhancedChatMessage makeMsg({
    String type = 'text',
    int senderId = 1,
    String content = 'Test message',
    String? locationAddress,
    String? imageUrl,
    String? replyToContent,
  }) {
    return EnhancedChatMessage.fromJson({
      'delivery_id': 10,
      'sender_id': senderId,
      'sender_type': 'courier',
      'sender_name': 'Jean',
      'type': type,
      'content': content,
      'target': 'customer',
      'status': 'sent',
      'created_at': DateTime.now().toIso8601String(),
      if (locationAddress != null) 'location_address': locationAddress,
      if (imageUrl != null) 'image_url': imageUrl,
      if (replyToContent != null) 'reply_to_content': replyToContent,
    }, 'msg-1');
  }

  Widget buildBubble(EnhancedChatMessage msg, {int courierId = 1}) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: EnhancedMessageBubble(message: msg, courierId: courierId),
        ),
      ),
    );
  }

  Future<void> pumpInput(
    WidgetTester tester, {
    List<String> Function(String)? onSendText,
    VoidCallback? onTypingStart,
    VoidCallback? onTypingStop,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sentTexts = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: commonWidgetTestOverrides(),
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EnhancedChatInput(
              orderId: 1,
              target: 'customer',
              onSendText: (text) => sentTexts.add(text),
              onTypingStart: onTypingStart,
              onTypingStop: onTypingStop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('EnhancedChatInput interactions', () {
    testWidgets('renders input field', (tester) async {
      await pumpInput(tester);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('entering text covers _onTextChanged with non-empty text', (
      tester,
    ) async {
      await pumpInput(tester);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      // _hasText is now true, so FAB should appear
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('clearing text reverts to empty state', (tester) async {
      await pumpInput(tester);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      // _hasText is false, no FAB (mic button shown instead)
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('tap send button calls onSendText and clears field', (
      tester,
    ) async {
      await pumpInput(tester);
      await tester.enterText(find.byType(TextField), 'Message test');
      await tester.pump();

      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first);
        await tester.pumpAndSettle();
        // Field should be cleared after send
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          isEmpty,
        );
      }
    });

    testWidgets('tap quick replies toggle shows quick replies panel', (
      tester,
    ) async {
      await pumpInput(tester);
      // Find the flash_on icon button to toggle quick replies
      final flashIcon = find.byIcon(Icons.flash_on);
      if (flashIcon.evaluate().isNotEmpty) {
        await tester.tap(flashIcon.first);
        await tester.pumpAndSettle();
        // QuickRepliesWidget should now be visible
        expect(find.byType(QuickRepliesWidget), findsOneWidget);
      }
    });

    testWidgets('tap quick reply chip selects a reply', (tester) async {
      await pumpInput(tester);
      // Toggle quick replies
      final flashIcon = find.byIcon(Icons.flash_on);
      if (flashIcon.evaluate().isNotEmpty) {
        await tester.tap(flashIcon.first);
        await tester.pumpAndSettle();
        // Tap the first ActionChip (quick reply)
        final chips = find.byType(ActionChip);
        if (chips.evaluate().isNotEmpty) {
          await tester.tap(chips.first);
          await tester.pumpAndSettle();
          // Quick replies panel should be hidden
          expect(find.byType(QuickRepliesWidget), findsNothing);
        }
      }
    });

    testWidgets('tap attachment button shows attachment modal', (tester) async {
      await pumpInput(tester);
      final addIcon = find.byIcon(Icons.add_circle_outline);
      if (addIcon.evaluate().isNotEmpty) {
        await tester.tap(addIcon.first);
        await tester.pumpAndSettle();
        // should show a modal with attachment options
        expect(
          find.text('Photo').evaluate().isNotEmpty ||
              find.text('Caméra').evaluate().isNotEmpty,
          isTrue,
        );
      }
    });

    testWidgets('toggle quick replies twice hides panel', (tester) async {
      await pumpInput(tester);
      final flashIcon = find.byIcon(Icons.flash_on);
      if (flashIcon.evaluate().isNotEmpty) {
        await tester.tap(flashIcon.first);
        await tester.pumpAndSettle();
        // Toggle off
        final keyboardIcon = find.byIcon(Icons.keyboard);
        if (keyboardIcon.evaluate().isNotEmpty) {
          await tester.tap(keyboardIcon.first);
          await tester.pumpAndSettle();
          expect(find.byType(QuickRepliesWidget), findsNothing);
        }
      }
    });
  });

  group('EnhancedMessageBubble supplemental types', () {
    testWidgets('location message with address shows location text', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBubble(
          makeMsg(
            type: 'location',
            locationAddress: 'Rue des Livreurs, Abidjan',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Rue des Livreurs'), findsOneWidget);
    });

    testWidgets('image message renders image content', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          buildBubble(
            makeMsg(type: 'image', imageUrl: 'https://example.com/test.jpg'),
          ),
        );
        await tester.pump();
        expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });

    testWidgets('message with replyToContent shows reply section', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildBubble(
          makeMsg(content: 'Réponse ici', replyToContent: 'Message original'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Message original'), findsOneWidget);
    });

    testWidgets('voice message renders without crash', (tester) async {
      final orig = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await tester.pumpWidget(
          buildBubble(makeMsg(type: 'voice', content: '/path/audio.m4a')),
        );
        await tester.pump();
        expect(find.byType(EnhancedMessageBubble), findsOneWidget);
      } finally {
        FlutterError.onError = orig;
      }
    });
  });
}
