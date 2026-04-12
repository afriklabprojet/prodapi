import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_client/core/errors/failures.dart';
import 'package:drpharma_client/core/services/messaging/message_channel.dart';
import 'package:drpharma_client/core/services/messaging/messaging_service.dart';

// ═══════════════════════════════════════════════════════════════
// Fake channels for testing — no mocktail needed for pure logic
// ═══════════════════════════════════════════════════════════════

class FakeSuccessChannel extends MessageChannel {
  int launchCount = 0;
  String? lastPhone;
  String? lastMessage;

  @override
  String get name => 'fake_success';

  @override
  Future<LaunchResult> launch({
    required String phoneNumber,
    String? message,
  }) async {
    launchCount++;
    lastPhone = phoneNumber;
    lastMessage = message;
    return LaunchResult.success;
  }

  @override
  Future<bool> isAvailable() async => true;
}

class FakeUnavailableChannel extends MessageChannel {
  int launchCount = 0;

  @override
  String get name => 'fake_unavailable';

  @override
  Future<LaunchResult> launch({
    required String phoneNumber,
    String? message,
  }) async {
    launchCount++;
    return LaunchResult.unavailable;
  }

  @override
  Future<bool> isAvailable() async => false;
}

class FakeThrowingChannel extends MessageChannel {
  @override
  String get name => 'fake_throwing';

  @override
  Future<LaunchResult> launch({
    required String phoneNumber,
    String? message,
  }) async {
    throw Exception('Channel crashed');
  }

  @override
  Future<bool> isAvailable() async => false;
}

void main() {
  group('MessagingService', () {
    // ─────────────────── send() ───────────────────

    group('send', () {
      test('returns Right(MessagingResult) on first channel success', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        final result = await service.send(phoneNumber: '+22507070707');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (r) {
          expect(r.isSuccess, isTrue);
          expect(r.channelUsed, 'fake_success');
          expect(r.normalizedPhone, '+22507070707');
        });
        expect(channel.launchCount, 1);
      });

      test('passes normalized phone and message to channel', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        await service.send(phoneNumber: '07 07 07 07', message: 'Hello');

        expect(channel.lastPhone, '+2257070707');
        expect(channel.lastMessage, 'Hello');
      });

      test('falls back to second channel when first is unavailable', () async {
        final wa = FakeUnavailableChannel();
        final sms = FakeSuccessChannel();
        final service = MessagingService(channels: [wa, sms]);

        final result = await service.send(phoneNumber: '+22507070707');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (r) {
          expect(r.channelUsed, 'fake_success');
        });
        expect(wa.launchCount, 1);
        expect(sms.launchCount, 1);
      });

      test('returns Left(Failure) when all channels fail', () async {
        final service = MessagingService(
          channels: [FakeUnavailableChannel(), FakeUnavailableChannel()],
        );

        final result = await service.send(phoneNumber: '+22507070707');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<ServerFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test('returns Left(ValidationFailure) for empty phone', () async {
        final service = MessagingService(channels: [FakeSuccessChannel()]);

        final result = await service.send(phoneNumber: '');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<ValidationFailure>()),
          (_) => fail('Expected Left'),
        );
      });

      test(
        'returns Left(ValidationFailure) for invalid phone (letters only)',
        () async {
          final service = MessagingService(channels: [FakeSuccessChannel()]);

          final result = await service.send(phoneNumber: 'abcdef');

          expect(result.isLeft(), isTrue);
          result.fold(
            (f) => expect(f, isA<ValidationFailure>()),
            (_) => fail('Expected Left'),
          );
        },
      );

      test('skips throwing channel and falls back to next', () async {
        final throwing = FakeThrowingChannel();
        final sms = FakeSuccessChannel();
        final service = MessagingService(channels: [throwing, sms]);

        final result = await service.send(phoneNumber: '+22507070707');

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (r) {
          expect(r.channelUsed, 'fake_success');
        });
      });

      test('returns Left when only channel throws', () async {
        final service = MessagingService(channels: [FakeThrowingChannel()]);

        final result = await service.send(phoneNumber: '+22507070707');

        expect(result.isLeft(), isTrue);
      });
    });

    // ─────────────────── contactSupport() ───────────────────

    group('contactSupport', () {
      test('uses default support number when none provided', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        await service.contactSupport();

        expect(channel.lastPhone, kDefaultSupportNumber);
      });

      test('uses custom support number', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        await service.contactSupport(supportNumber: '+22501010101');

        expect(channel.lastPhone, '+22501010101');
      });

      test('generates correct default message', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        await service.contactSupport();

        expect(channel.lastMessage, contains('besoin d\'aide'));
      });
    });

    // ─────────────────── contactCourier() ───────────────────

    group('contactCourier', () {
      test('generates message with courier name and order', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        await service.contactCourier(
          courierPhone: '+22507070707',
          courierName: 'Moussa',
          orderReference: 'CMD-001',
        );

        expect(channel.lastMessage, contains('Moussa'));
        expect(channel.lastMessage, contains('CMD-001'));
        expect(channel.lastMessage, contains('livraison'));
      });
    });

    // ─────────────────── contactPharmacy() ───────────────────

    group('contactPharmacy', () {
      test('generates message with pharmacy name and order', () async {
        final channel = FakeSuccessChannel();
        final service = MessagingService(channels: [channel]);

        await service.contactPharmacy(
          pharmacyPhone: '+22501234567',
          pharmacyName: 'Pharmacie du Plateau',
          orderReference: 'CMD-042',
        );

        expect(channel.lastMessage, contains('Pharmacie du Plateau'));
        expect(channel.lastMessage, contains('CMD-042'));
        expect(channel.lastMessage, contains('commande'));
      });
    });

    // ─────────────────── Analytics callback ───────────────────

    group('analytics', () {
      test('fires analytics callback on successful send', () async {
        final events = <Map<String, dynamic>>[];
        final service = MessagingService(
          channels: [FakeSuccessChannel()],
          onAnalytics: ({required event, required properties}) {
            events.add({'event': event, ...properties});
          },
        );

        await service.send(phoneNumber: '+22507070707', message: 'hi');

        expect(events, isNotEmpty);
        expect(events.last['event'], 'messaging_sent');
        expect(events.last['channel'], 'fake_success');
      });

      test('fires analytics on all channels failed', () async {
        final events = <Map<String, dynamic>>[];
        final service = MessagingService(
          channels: [FakeUnavailableChannel()],
          onAnalytics: ({required event, required properties}) {
            events.add({'event': event, ...properties});
          },
        );

        await service.send(phoneNumber: '+22507070707');

        expect(
          events.any((e) => e['event'] == 'messaging_all_channels_failed'),
          isTrue,
        );
      });

      test('fires analytics on channel exception', () async {
        final events = <Map<String, dynamic>>[];
        final service = MessagingService(
          channels: [FakeThrowingChannel(), FakeSuccessChannel()],
          onAnalytics: ({required event, required properties}) {
            events.add({'event': event, ...properties});
          },
        );

        await service.send(phoneNumber: '+22507070707');

        expect(
          events.any((e) => e['event'] == 'messaging_channel_error'),
          isTrue,
        );
      });

      test('fires support_contacted event', () async {
        final events = <Map<String, dynamic>>[];
        final service = MessagingService(
          channels: [FakeSuccessChannel()],
          onAnalytics: ({required event, required properties}) {
            events.add({'event': event, ...properties});
          },
        );

        await service.contactSupport();

        expect(events.any((e) => e['event'] == 'support_contacted'), isTrue);
      });

      test('fires courier_contacted event with order ref', () async {
        final events = <Map<String, dynamic>>[];
        final service = MessagingService(
          channels: [FakeSuccessChannel()],
          onAnalytics: ({required event, required properties}) {
            events.add({'event': event, ...properties});
          },
        );

        await service.contactCourier(
          courierPhone: '+22507070707',
          orderReference: 'CMD-001',
        );

        final courierEvent = events.firstWhere(
          (e) => e['event'] == 'courier_contacted',
        );
        expect(courierEvent['order_reference'], 'CMD-001');
      });
    });

    // ─────────────────── isPrimaryChannelAvailable ───────────────────

    group('isPrimaryChannelAvailable', () {
      test('returns true when primary channel is available', () async {
        final service = MessagingService(channels: [FakeSuccessChannel()]);
        expect(await service.isPrimaryChannelAvailable(), isTrue);
      });

      test('returns false when primary channel is unavailable', () async {
        final service = MessagingService(channels: [FakeUnavailableChannel()]);
        expect(await service.isPrimaryChannelAvailable(), isFalse);
      });

      test('returns false when no channels', () async {
        final service = MessagingService(channels: []);
        expect(await service.isPrimaryChannelAvailable(), isFalse);
      });
    });
  });
}
