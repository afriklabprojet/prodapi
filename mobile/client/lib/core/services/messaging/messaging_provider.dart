import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/providers.dart';
import 'message_channel.dart';
import 'messaging_service.dart';

/// Riverpod provider — wires [MessagingService] to existing [AnalyticsService].
final messagingServiceProvider = Provider<MessagingService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);

  return MessagingService(
    channels: const [WhatsAppChannel(), SmsChannel()],
    onAnalytics: ({required event, required properties}) {
      analytics.track(event, properties: properties);
    },
  );
});
