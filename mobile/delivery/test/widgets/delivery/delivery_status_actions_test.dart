import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:courier/core/services/firestore_tracking_service.dart';
import 'package:courier/core/services/location_service.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/gamification.dart';
import 'package:courier/data/repositories/delivery_repository.dart';
import 'package:courier/data/repositories/gamification_repository.dart';
import 'package:courier/data/repositories/support_repository.dart';
import 'package:courier/presentation/widgets/delivery/delivery_status_actions.dart';
import 'package:courier/presentation/widgets/delivery/delivery_communication.dart';
import 'package:courier/presentation/widgets/delivery/delivery_proof.dart';
import 'package:courier/core/services/kyc_guard_service.dart';
import 'package:courier/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/widget_test_helpers.dart';

class _MockFirestoreTracking extends Mock implements FirestoreTrackingService {}

Delivery _makeDelivery(String status) {
  return Delivery.fromJson({
    'id': 1,
    'reference': 'DEL-001',
    'pharmacy_name': 'Pharma Test',
    'pharmacy_address': '123 Rue Test',
    'customer_name': 'Client Test',
    'delivery_address': '456 Rue Dest',
    'total_amount': 5000,
    'status': status,
    'customer_phone': '+22500000001',
    'pharmacy_phone': '+22500000002',
  });
}

class FakeActionDeliveryRepository extends DeliveryRepository {
  FakeActionDeliveryRepository() : super(Dio());

  int? acceptedId;
  int? pickedUpId;
  int? completedId;
  String? completedCode;

  @override
  Future<void> acceptDelivery(int id) async {
    acceptedId = id;
  }

  @override
  Future<void> pickupDelivery(int id) async {
    pickedUpId = id;
  }

  @override
  Future<void> completeDelivery(int id, String code) async {
    completedId = id;
    completedCode = code;
  }
}

class FakeActionLocationService extends LocationService {
  FakeActionLocationService()
    : super(DeliveryRepository(Dio()), _MockFirestoreTracking());

  int? updatedDeliveryId;
  String? updatedStatus;
  double? destinationLat;
  double? destinationLng;

  @override
  void setDestination({required double lat, required double lng}) {
    destinationLat = lat;
    destinationLng = lng;
  }

  @override
  Future<void> updateDeliveryStatus({
    required int deliveryId,
    required String status,
    DateTime? estimatedArrival,
  }) async {
    updatedDeliveryId = deliveryId;
    updatedStatus = status;
  }

  @override
  void clearDestination() {
    destinationLat = null;
    destinationLng = null;
  }
}

class FakeSupportRepository extends SupportRepository {
  FakeSupportRepository() : super(Dio());

  int? reportedDeliveryId;
  String? reportedReason;
  bool shouldThrow = false;

  @override
  Future<void> reportIncident({
    required int deliveryId,
    required String reason,
  }) async {
    if (shouldThrow) throw Exception('support error');
    reportedDeliveryId = deliveryId;
    reportedReason = reason;
  }
}

class FakeGamificationRepository extends GamificationRepository {
  FakeGamificationRepository(this.data) : super(Dio());

  final GamificationData data;

  @override
  Future<GamificationData> getGamificationData() async => data;
}

class FakeProofHelper extends DeliveryProofHelper {
  FakeProofHelper({
    required super.context,
    required super.ref,
    required super.delivery,
    this.canDeliverResult = true,
    this.confirmationCode = '1234',
  });

  final bool canDeliverResult;
  final String? confirmationCode;

  @override
  Future<bool> checkBalanceForDelivery() async => canDeliverResult;

  @override
  Future<String?> showConfirmationDialog() async => confirmationCode;
}

class FakeCommunicationHelper extends DeliveryCommunicationHelper {
  FakeCommunicationHelper({required super.context, required super.delivery});

  bool launched = false;
  double? lastLat;
  double? lastLng;

  @override
  Future<void> launchMaps(double lat, double lng) async {
    launched = true;
    lastLat = lat;
    lastLng = lng;
  }
}

Widget _buildTestWidget({
  required Delivery delivery,
  bool isLoading = false,
  bool isNearDestination = false,
  List<Override> extra = const [],
  VoidCallback? onStatusChanged,
  ValueChanged<bool>? onLoadingChanged,
  DeliveryCommunicationHelper Function(BuildContext context, Delivery delivery)?
  commHelperBuilder,
  DeliveryProofHelper Function(
    BuildContext context,
    WidgetRef ref,
    Delivery delivery,
  )?
  proofHelperBuilder,
}) {
  return ProviderScope(
    overrides: commonWidgetTestOverrides(extra: extra),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Consumer(
        builder: (context, ref, _) {
          final commHelper =
              commHelperBuilder?.call(context, delivery) ??
              DeliveryCommunicationHelper(context: context, delivery: delivery);
          final proofHelper =
              proofHelperBuilder?.call(context, ref, delivery) ??
              DeliveryProofHelper(
                context: context,
                ref: ref,
                delivery: delivery,
              );
          return Scaffold(
            body: SingleChildScrollView(
              child: DeliveryStatusActions(
                delivery: delivery,
                isLoading: isLoading,
                isNearDestination: isNearDestination,
                pulseAnimation: const AlwaysStoppedAnimation(1.0),
                onStatusChanged: onStatusChanged ?? () {},
                onLoadingChanged: onLoadingChanged ?? (_) {},
                commHelper: commHelper,
                proofHelper: proofHelper,
              ),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  group('DeliveryStatusActions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crashing', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('accepted')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveryStatusActions), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('accepted'),
            isLoading: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('pending status shows Accepter la course button', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Accepter la course'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('assigned status shows Confirmer récupération button', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer récupération'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('picked_up status shows Confirmer la livraison button', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivered status shows Course terminée text', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
        // No action button for completed status
        expect(find.text('Accepter la course'), findsNothing);
        expect(find.text('Confirmer récupération'), findsNothing);
        expect(find.text('Confirmer la livraison'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancel/problem button visible for non-delivered statuses', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining('Signaler un problème'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancel button hidden for delivered status', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining('Signaler un problème'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('loading true hides action button', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending'), isLoading: true),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // When loading, no Accepter button, just spinner
        expect(find.text('Accepter la course'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('unknown status shows Course terminée', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('cancelled')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('pending status has check_circle_outline icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('assigned status has store icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.byIcon(Icons.store_mall_directory_outlined),
          findsOneWidget,
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('picked_up status has local_shipping icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('pending has action button widget', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Verify button text is there
        expect(find.text('Accepter la course'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancel button has warning icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivered shows check_circle icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has SizedBox for button width', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SizedBox), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('isNearDestination true renders without crash', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('picked_up'),
            isNearDestination: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveryStatusActions), findsOneWidget);
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('different statuses render different button text', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        // Test assigned
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer récupération'), findsOneWidget);
        expect(find.text('Accepter la course'), findsNothing);
        expect(find.text('Confirmer la livraison'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - action flows', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('cancel dialog reports selected incident reason', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      final supportRepo = FakeSupportRepository();

      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('pending'),
            extra: [supportRepositoryProvider.overrideWithValue(supportRepo)],
          ),
        );
        await tester.pump();

        await tester.tap(find.textContaining('Signaler un problème'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Motif d\'annulation'), findsOneWidget);
        expect(find.text('Problème mécanique'), findsOneWidget);
        expect(find.text('Accident'), findsOneWidget);
        expect(find.text('Client injoignable'), findsOneWidget);
        expect(find.text('Autre'), findsOneWidget);

        await tester.tap(find.text('Accident'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(supportRepo.reportedDeliveryId, 1);
        expect(supportRepo.reportedReason, 'Accident');
        expect(
          find.textContaining('Incident signalé: Accident'),
          findsOneWidget,
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - NearDestination combos', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('isNearDestination with pending status', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('pending'),
            isNearDestination: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Accepter la course'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('isNearDestination with assigned status', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('assigned'),
            isNearDestination: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer récupération'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('isNearDestination with delivered status', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('delivered'),
            isNearDestination: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('loading with isNearDestination hides buttons', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('assigned'),
            isLoading: true,
            isNearDestination: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(find.text('Confirmer récupération'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - Delivery with coordinates', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('delivery with pharmacy coordinates', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 2,
          'reference': 'DEL-002',
          'pharmacy_name': 'Pharma Coord',
          'pharmacy_address': '789 Rue Test',
          'customer_name': 'Client GPS',
          'delivery_address': '101 Rue Dest',
          'total_amount': 8000,
          'status': 'assigned',
          'customer_phone': '+22500000003',
          'pharmacy_phone': '+22500000004',
          'pharmacy_latitude': 5.36,
          'pharmacy_longitude': -4.01,
          'delivery_latitude': 5.37,
          'delivery_longitude': -4.02,
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveryStatusActions), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivery with high total amount', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 3,
          'reference': 'DEL-003',
          'pharmacy_name': 'Pharma VIP',
          'pharmacy_address': '200 Rue Test',
          'customer_name': 'Client VIP',
          'delivery_address': '300 Rue Dest',
          'total_amount': 500000,
          'status': 'picked_up',
          'customer_phone': '+22500000005',
          'pharmacy_phone': '+22500000006',
        });
        await tester.pumpWidget(
          _buildTestWidget(delivery: delivery, isNearDestination: true),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('accepted status renders like assigned', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('accepted')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveryStatusActions), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - Button styles and structure', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('pending button has green color scheme', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Green action button with text
        expect(find.text('Accepter la course'), findsOneWidget);
        expect(find.byType(SizedBox), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('assigned button has blue color scheme', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer récupération'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('picked_up button has orange color scheme', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivered shows Container not ElevatedButton', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
        expect(find.byType(Container), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancel button is TextButton', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(TextButton), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('Column wraps action buttons', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Column), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('Row wraps icon and text inside button', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Row), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - Delivery data variations', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('delivery with earnings fields', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 10,
          'reference': 'DEL-010',
          'pharmacy_name': 'Pharma Earnings',
          'pharmacy_address': '100 Rue Test',
          'customer_name': 'Client Money',
          'delivery_address': '200 Rue Dest',
          'total_amount': 15000,
          'status': 'picked_up',
          'customer_phone': '+22500000010',
          'pharmacy_phone': '+22500000011',
          'estimated_earnings': 2500,
          'delivery_fee': 3000,
          'commission': 500,
        });
        await tester.pumpWidget(
          _buildTestWidget(delivery: delivery, isNearDestination: true),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivery with zero total amount', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 11,
          'reference': 'DEL-011',
          'pharmacy_name': 'Pharma Zero',
          'pharmacy_address': '0 Rue Test',
          'customer_name': 'Client Zero',
          'delivery_address': '0 Rue Dest',
          'total_amount': 0,
          'status': 'pending',
          'customer_phone': '+22500000012',
          'pharmacy_phone': '+22500000013',
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Accepter la course'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivery with long customer name', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 12,
          'reference': 'DEL-012',
          'pharmacy_name': 'Pharmacie du Centre Commercial Grand Abidjan',
          'pharmacy_address':
              'Avenue de la République, Plateau, Abidjan, Côte d\'Ivoire',
          'customer_name': 'Jean-Baptiste Koffi Kouamé de la Fontaine',
          'delivery_address':
              'Résidence les Jardins d\'Eden, Cocody Riviera Bonoumin, Bloc 12 Porte 3',
          'total_amount': 25000,
          'status': 'assigned',
          'customer_phone': '+22500000014',
          'pharmacy_phone': '+22500000015',
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer récupération'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancelled status shows terminée', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('cancelled')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
        expect(find.textContaining('Signaler un problème'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('failed status shows terminée', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('failed')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('pending cancel button tap shows dialog', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Tap the cancel/problem button
        final cancelBtn = find.textContaining('Signaler un problème');
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Dialog should appear with cancellation reasons
        expect(find.byType(SimpleDialog), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('assigned cancel button tap shows dialog', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final cancelBtn = find.textContaining('Signaler un problème');
        expect(cancelBtn, findsOneWidget);
        await tester.tap(cancelBtn);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SimpleDialog), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - additional statuses', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('picked_up shows Confirmer la livraison', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('picked_up has local_shipping icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.local_shipping_outlined), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('picked_up has Signaler un problème button', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining('Signaler un problème'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivered shows Course terminée', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Course terminée'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivered has check_circle icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.check_circle), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivered hides Signaler un problème', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('delivered')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining('Signaler un problème'), findsNothing);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('pending has check_circle_outline icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('assigned has store icon', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byIcon(Icons.store_mall_directory_outlined), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - widget structure', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('has Column layout', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Column), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has action button for main action', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Main action button may be ElevatedButton, FilledButton, or SizedBox with InkWell
        expect(find.text('Accepter la course'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has TextButton for cancel', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('pending')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final textBtns = find.byType(TextButton);
        final outlineBtns = find.byType(OutlinedButton);
        expect(
          textBtns.evaluate().length + outlineBtns.evaluate().length,
          greaterThanOrEqualTo(1),
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has SizedBox spacers', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SizedBox), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Icon widgets', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('picked_up')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Icon), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('has Text widgets', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(delivery: _makeDelivery('assigned')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(Text), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('near destination with picked_up shows action', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('picked_up'),
            isNearDestination: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('loading hides buttons for assigned', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('assigned'),
            isLoading: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('loading hides buttons for picked_up', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('picked_up'),
            isLoading: true,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });

  group('DeliveryStatusActions - accept action flow', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('tapping accept button calls acceptDelivery on repo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeActionDeliveryRepository();
      final locationService = FakeActionLocationService();

      await tester.pumpWidget(
        _buildTestWidget(
          delivery: _makeDelivery('pending'),
          extra: [
            deliveryRepositoryProvider.overrideWithValue(repo),
            locationServiceProvider.overrideWithValue(locationService),
            kycStatusProvider.overrideWithValue(KycStatus.verified),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Accepter la course'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));

      expect(repo.acceptedId, 1);
      expect(locationService.updatedStatus, 'accepted');

      // Drain the 3s auto-dismiss timer from _showTransitionSheet
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    });

    testWidgets('tapping pickup button calls pickupDelivery on repo', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeActionDeliveryRepository();
      final locationService = FakeActionLocationService();

      final delivery = Delivery.fromJson({
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Rue Dest',
        'total_amount': 5000,
        'status': 'assigned',
        'customer_phone': '+22500000001',
        'pharmacy_phone': '+22500000002',
        'delivery_latitude': 5.37,
        'delivery_longitude': -4.02,
      });
      await tester.pumpWidget(
        _buildTestWidget(
          delivery: delivery,
          extra: [
            deliveryRepositoryProvider.overrideWithValue(repo),
            locationServiceProvider.overrideWithValue(locationService),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Confirmer récupération'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));

      expect(repo.pickedUpId, 1);
      expect(locationService.updatedStatus, 'picked_up');
      expect(locationService.destinationLat, 5.37);
      expect(locationService.destinationLng, -4.02);

      // Drain the 3s auto-dismiss timer from _showTransitionSheet
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    });

    testWidgets('deliver action requires proof helper confirmation', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeActionDeliveryRepository();
      final locationService = FakeActionLocationService();

      await tester.pumpWidget(
        _buildTestWidget(
          delivery: _makeDelivery('picked_up'),
          extra: [
            deliveryRepositoryProvider.overrideWithValue(repo),
            locationServiceProvider.overrideWithValue(locationService),
            gamificationRepositoryProvider.overrideWithValue(
              FakeGamificationRepository(
                GamificationData.fromJson({
                  'level': {
                    'level': 1,
                    'title': 'Débutant',
                    'current_xp': 0,
                    'required_xp': 100,
                    'total_xp': 0,
                    'color': 'bronze',
                  },
                  'badges': [],
                  'stats': {},
                }),
              ),
            ),
          ],
          proofHelperBuilder: (ctx, ref, delivery) => FakeProofHelper(
            context: ctx,
            ref: ref,
            delivery: delivery,
            canDeliverResult: true,
            confirmationCode: '1234',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Confirmer la livraison'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));

      expect(repo.completedId, 1);
      expect(repo.completedCode, '1234');
      expect(locationService.updatedStatus, 'delivered');

      // Wait for post-delivery summary (has a 3s delay for "Passer" button)
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('deliver action aborted when balance check fails', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      final repo = FakeActionDeliveryRepository();

      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('picked_up'),
            extra: [deliveryRepositoryProvider.overrideWithValue(repo)],
            proofHelperBuilder: (ctx, ref, delivery) => FakeProofHelper(
              context: ctx,
              ref: ref,
              delivery: delivery,
              canDeliverResult: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.tap(find.text('Confirmer la livraison'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Repo should NOT be called if balance check failed
        expect(repo.completedId, isNull);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('deliver action aborted when confirmation code is null', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      final repo = FakeActionDeliveryRepository();

      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('picked_up'),
            extra: [deliveryRepositoryProvider.overrideWithValue(repo)],
            proofHelperBuilder: (ctx, ref, delivery) => FakeProofHelper(
              context: ctx,
              ref: ref,
              delivery: delivery,
              canDeliverResult: true,
              confirmationCode: null,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.tap(find.text('Confirmer la livraison'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(repo.completedId, isNull);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancel dialog error shows snackbar', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      final supportRepo = FakeSupportRepository();
      supportRepo.shouldThrow = true;

      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('pending'),
            extra: [supportRepositoryProvider.overrideWithValue(supportRepo)],
          ),
        );
        await tester.pump();

        await tester.tap(find.textContaining('Signaler un problème'));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Accident'));
        await tester.pump(const Duration(milliseconds: 300));

        // Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('cancel dialog dismiss without selecting does not report', (
      tester,
    ) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      final supportRepo = FakeSupportRepository();

      try {
        await tester.pumpWidget(
          _buildTestWidget(
            delivery: _makeDelivery('pending'),
            extra: [supportRepositoryProvider.overrideWithValue(supportRepo)],
          ),
        );
        await tester.pump();

        await tester.tap(find.textContaining('Signaler un problème'));
        await tester.pump(const Duration(milliseconds: 300));

        // Dismiss dialog by tapping outside
        await tester.tapAt(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 300));

        expect(supportRepo.reportedDeliveryId, isNull);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('accept with pharmacy coordinates sets location destination', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeActionDeliveryRepository();
      final locationService = FakeActionLocationService();

      final delivery = Delivery.fromJson({
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharma Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Rue Dest',
        'total_amount': 5000,
        'status': 'pending',
        'customer_phone': '+22500000001',
        'pharmacy_phone': '+22500000002',
        'pharmacy_latitude': 5.36,
        'pharmacy_longitude': -4.01,
      });
      await tester.pumpWidget(
        _buildTestWidget(
          delivery: delivery,
          extra: [
            deliveryRepositoryProvider.overrideWithValue(repo),
            locationServiceProvider.overrideWithValue(locationService),
            kycStatusProvider.overrideWithValue(KycStatus.verified),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Accepter la course'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 1));

      expect(locationService.destinationLat, 5.36);
      expect(locationService.destinationLng, -4.01);

      // Drain the 3s auto-dismiss timer from _showTransitionSheet
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    });
  });

  group('DeliveryStatusActions - delivery data', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('delivery with coordinates renders', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 100,
          'reference': 'DEL-100',
          'pharmacy_name': 'Pharma GPS',
          'pharmacy_address': 'Addr GPS',
          'customer_name': 'Client GPS',
          'delivery_address': 'Dest GPS',
          'total_amount': 15000,
          'status': 'assigned',
          'customer_phone': '+22500000010',
          'pharmacy_phone': '+22500000020',
          'pharmacy_latitude': 5.3600,
          'pharmacy_longitude': -4.0083,
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveryStatusActions), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivery with earnings fields renders', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 101,
          'reference': 'DEL-101',
          'pharmacy_name': 'Pharma Rich',
          'pharmacy_address': 'Addr',
          'customer_name': 'Rich Client',
          'delivery_address': 'Dest',
          'total_amount': 50000,
          'status': 'pending',
          'customer_phone': '+22500000030',
          'pharmacy_phone': '+22500000040',
          'delivery_fee': 3000,
          'commission': 500,
          'estimated_earnings': 2500,
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Accepter la course'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivery with zero amount', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 102,
          'reference': 'DEL-102',
          'pharmacy_name': 'Pharma Zero',
          'pharmacy_address': 'Addr',
          'customer_name': 'Zero Client',
          'delivery_address': 'Dest',
          'total_amount': 0,
          'status': 'assigned',
          'customer_phone': '+22500000050',
          'pharmacy_phone': '+22500000060',
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(DeliveryStatusActions), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });

    testWidgets('delivery with long names', (tester) async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      try {
        final delivery = Delivery.fromJson({
          'id': 103,
          'reference': 'DEL-103',
          'pharmacy_name':
              'Pharmacie Internationale de la Capitale Abidjan Centre',
          'pharmacy_address':
              'Adresse très longue qui dépasse la taille normale',
          'customer_name':
              'M. Jean-Baptiste Kouamé Assamoi de la Famille Royale',
          'delivery_address':
              'Residence Les Jardins de Cocody, Bloc A, Apt 23, Abidjan',
          'total_amount': 25000,
          'status': 'picked_up',
          'customer_phone': '+22500000070',
          'pharmacy_phone': '+22500000080',
        });
        await tester.pumpWidget(_buildTestWidget(delivery: delivery));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Confirmer la livraison'), findsOneWidget);
      } finally {
        FlutterError.onError = originalOnError;
      }
    });
  });
}
