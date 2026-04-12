import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drpharma_client/features/treatments/presentation/widgets/smart_refill_banner.dart';
import 'package:drpharma_client/features/treatments/data/services/smart_refill_service.dart';
import 'package:drpharma_client/features/treatments/domain/entities/treatment_entity.dart';
import 'package:drpharma_client/config/providers.dart';
import '../../../../helpers/fake_api_client.dart';

class MockSmartRefillNotifier extends StateNotifier<SmartRefillState>
    with Mock
    implements SmartRefillNotifier {
  MockSmartRefillNotifier([SmartRefillState? state])
    : super(state ?? const SmartRefillState());

  @override
  Future<void> checkRefills() async {}

  @override
  Future<void> dismissSuggestion(String treatmentId) async {}

  @override
  Future<void> markAsOrdered(String treatmentId) async {}
}

void main() {
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
  });

  TreatmentEntity _makeTreatment({String id = 't1'}) {
    return TreatmentEntity(
      id: id,
      productId: 1,
      productName: 'Paracétamol 500mg',
      renewalPeriodDays: 30,
      reminderEnabled: false,
      reminderDaysBefore: 3,
      isActive: true,
      createdAt: DateTime(2024),
    );
  }

  RefillSuggestion _makeSuggestion({
    RefillUrgency urgency = RefillUrgency.upcoming,
  }) {
    return RefillSuggestion(
      treatment: _makeTreatment(),
      daysRemaining: urgency == RefillUrgency.urgent ? 2 : 5,
      urgency: urgency,
      message: 'Pensez à renouveler votre traitement',
    );
  }

  Widget createWidget({required SmartRefillState state}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        apiClientProvider.overrideWithValue(FakeApiClient()),
        smartRefillProvider.overrideWith(
          (_) => MockSmartRefillNotifier()..state = state,
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: SmartRefillSection())),
    );
  }

  group('SmartRefillBanner Widget Tests', () {
    testWidgets('renders widget without crashing when no suggestions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidget(state: const SmartRefillState()));
      await tester.pump();
      expect(find.byType(SmartRefillSection), findsOneWidget);
    });

    testWidgets('shows notification icon when suggestions exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    });

    testWidgets('shows treatment name in suggestion card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.textContaining('Paracétamol'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Commander button for suggestion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.text('Commander'), findsOneWidget);
    });

    testWidgets('shows add_shopping_cart icon in Commander button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.byIcon(Icons.add_shopping_cart_rounded), findsOneWidget);
    });

    testWidgets('shows close icon to dismiss suggestion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('shows warning icon for urgent suggestion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(
          state: SmartRefillState(
            suggestions: [_makeSuggestion(urgency: RefillUrgency.urgent)],
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('shows schedule icon for upcoming suggestion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(
          state: SmartRefillState(
            suggestions: [_makeSuggestion(urgency: RefillUrgency.upcoming)],
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('shows treatments count text', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.textContaining('traitement'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows Tout voir button when suggestions exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.text('Tout voir'), findsOneWidget);
    });

    testWidgets('shows days remaining text in card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(
          state: SmartRefillState(
            suggestions: [_makeSuggestion(urgency: RefillUrgency.upcoming)],
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('jours'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows message text in card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createWidget(state: SmartRefillState(suggestions: [_makeSuggestion()])),
      );
      await tester.pump();
      expect(find.textContaining('renouveler'), findsAtLeastNWidgets(1));
    });
  });
}
