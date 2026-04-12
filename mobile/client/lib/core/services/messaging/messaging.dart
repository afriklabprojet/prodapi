/// Messaging module — unified WhatsApp + SMS communication layer.
///
/// ```dart
/// // In a ConsumerWidget:
/// final messaging = ref.read(messagingServiceProvider);
/// final result = await messaging.contactSupport();
/// result.fold(
///   (failure) => showSnackBar(failure.message),
///   (success) => debugPrint('Sent via ${success.channelUsed}'),
/// );
/// ```

export 'message_channel.dart';
export 'message_templates.dart';
export 'messaging_provider.dart';
export 'messaging_service.dart';
export 'messaging_ui_helper.dart';
export 'phone_normalizer.dart';
