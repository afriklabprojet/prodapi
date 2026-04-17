/// Pusher configuration, driven by --dart-define values.
///
/// Usage:
///   flutter run \
///     --dart-define=PUSHER_APP_KEY=your_key \
///     --dart-define=PUSHER_APP_CLUSTER=mt1
abstract final class PusherConfig {
  static const String pusherKey = String.fromEnvironment(
    'PUSHER_APP_KEY',
    defaultValue: '',
  );

  static const String pusherCluster = String.fromEnvironment(
    'PUSHER_APP_CLUSTER',
    defaultValue: 'mt1',
  );

  static bool get pusherEnabled => pusherKey.isNotEmpty;
}
