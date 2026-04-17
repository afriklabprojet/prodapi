import 'package:dartz/dartz.dart';

import '../../errors/failures.dart';
import 'message_channel.dart';
import 'message_templates.dart';
import 'phone_normalizer.dart';

/// Default support number (Côte d'Ivoire).
const kDefaultSupportNumber = '+22507000000000';

/// Outcome details after a send attempt.
class MessagingResult {
  final LaunchResult result;
  final String channelUsed;
  final String normalizedPhone;

  const MessagingResult({
    required this.result,
    required this.channelUsed,
    required this.normalizedPhone,
  });

  bool get isSuccess => result == LaunchResult.success;
}

/// Callback for analytics / logging — keeps the service pure.
typedef MessagingAnalyticsCallback =
    void Function({
      required String event,
      required Map<String, dynamic> properties,
    });

/// Production-grade messaging service.
///
/// * Tries channels in priority order (WhatsApp → SMS fallback)
/// * Pure service — no BuildContext, no UI
/// * Injectable channels + analytics for full testability
class MessagingService {
  final List<MessageChannel> _channels;
  final MessagingAnalyticsCallback? _onAnalytics;

  MessagingService({
    List<MessageChannel>? channels,
    MessagingAnalyticsCallback? onAnalytics,
  }) : _channels = channels ?? const [WhatsAppChannel(), SmsChannel()],
       _onAnalytics = onAnalytics;

  // ═══════════════════════════════════════════════════════════
  // Public API — returns Either<Failure, MessagingResult>
  // ═══════════════════════════════════════════════════════════

  /// Open a messaging channel with [phoneNumber].
  /// Tries each channel in order; first success wins.
  Future<Either<Failure, MessagingResult>> send({
    required String phoneNumber,
    String? message,
  }) async {
    final normalized = PhoneNormalizer.normalize(phoneNumber);
    if (normalized.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Numéro de téléphone invalide'),
      );
    }

    for (final channel in _channels) {
      try {
        final result = await channel.launch(
          phoneNumber: normalized,
          message: message,
        );
        if (result == LaunchResult.success) {
          final outcome = MessagingResult(
            result: result,
            channelUsed: channel.name,
            normalizedPhone: normalized,
          );
          _trackEvent('messaging_sent', {
            'channel': channel.name,
            'phone': normalized,
          });
          return Right(outcome);
        }
      } catch (e) {
        _trackEvent('messaging_channel_error', {
          'channel': channel.name,
          'error': e.toString(),
        });
        // Continue to next channel
      }
    }

    _trackEvent('messaging_all_channels_failed', {'phone': normalized});
    return const Left(
      ServerFailure(message: 'Aucun canal de messagerie disponible'),
    );
  }

  /// Contact DR-PHARMA support.
  Future<Either<Failure, MessagingResult>> contactSupport({
    String? supportNumber,
    String? message,
  }) {
    _trackEvent('support_contacted', {'channel': 'whatsapp'});
    return send(
      phoneNumber: supportNumber ?? kDefaultSupportNumber,
      message: MessageTemplates.support(customMessage: message),
    );
  }

  /// Contact a delivery courier.
  Future<Either<Failure, MessagingResult>> contactCourier({
    required String courierPhone,
    String? orderReference,
    String? courierName,
  }) {
    _trackEvent('courier_contacted', {
      'channel': 'whatsapp',
      'order_reference': ?orderReference,
    });
    return send(
      phoneNumber: courierPhone,
      message: MessageTemplates.courier(
        courierName: courierName,
        orderReference: orderReference,
      ),
    );
  }

  /// Contact a pharmacy.
  Future<Either<Failure, MessagingResult>> contactPharmacy({
    required String pharmacyPhone,
    String? orderReference,
    String? pharmacyName,
  }) {
    _trackEvent('pharmacy_contacted', {
      'channel': 'whatsapp',
      'order_reference': ?orderReference,
    });
    return send(
      phoneNumber: pharmacyPhone,
      message: MessageTemplates.pharmacy(
        pharmacyName: pharmacyName,
        orderReference: orderReference,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Utilities
  // ═══════════════════════════════════════════════════════════

  /// Check if the primary channel (WhatsApp) is available.
  Future<bool> isPrimaryChannelAvailable() async {
    if (_channels.isEmpty) return false;
    return _channels.first.isAvailable();
  }

  void _trackEvent(String event, Map<String, dynamic> properties) {
    _onAnalytics?.call(event: event, properties: properties);
  }
}
