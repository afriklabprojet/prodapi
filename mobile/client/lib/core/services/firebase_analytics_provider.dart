/// Firebase Analytics Provider pour AnalyticsService
///
/// Pour utiliser ce provider, ajoutez firebase_analytics à pubspec.yaml :
/// ```yaml
/// dependencies:
///   firebase_analytics: ^12.1.3
/// ```
///
/// Puis décommentez le code ci-dessous et configurez dans main.dart:
/// ```dart
/// final analyticsService = AnalyticsService(
///   providers: [
///     FirebaseAnalyticsProvider(),
///     if (kDebugMode) DebugAnalyticsProvider(),
///   ],
/// );
/// ```
library firebase_analytics_provider;

// import 'package:firebase_analytics/firebase_analytics.dart';
// 
// import 'analytics_service.dart';
// 
// /// Implémentation Firebase Analytics
// class FirebaseAnalyticsProvider implements AnalyticsProvider {
//   late final FirebaseAnalytics _analytics;
//   
//   @override
//   Future<void> init() async {
//     _analytics = FirebaseAnalytics.instance;
//     await _analytics.setAnalyticsCollectionEnabled(true);
//   }
//   
//   @override
//   Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
//     await _analytics.setUserId(id: userId);
//     
//     // Set user properties from traits
//     if (traits != null) {
//       for (final entry in traits.entries) {
//         if (entry.value != null) {
//           await _analytics.setUserProperty(
//             name: entry.key,
//             value: entry.value.toString(),
//           );
//         }
//       }
//     }
//   }
//   
//   @override
//   Future<void> reset() async {
//     await _analytics.setUserId(id: null);
//   }
//   
//   @override
//   Future<void> track(String event, {Map<String, dynamic>? properties}) async {
//     // Firebase n'accepte que certains types de paramètres
//     final sanitized = _sanitizeParameters(properties);
//     await _analytics.logEvent(name: event, parameters: sanitized);
//   }
//   
//   @override
//   Future<void> screen(String screenName, {Map<String, dynamic>? properties}) async {
//     await _analytics.logScreenView(
//       screenName: screenName,
//       screenClass: properties?['screen_class'] as String?,
//     );
//   }
//   
//   @override
//   Future<void> setUserProperty(String name, String value) async {
//     await _analytics.setUserProperty(name: name, value: value);
//   }
//   
//   /// Sanitize parameters pour Firebase (max 25 params, types limités)
//   Map<String, Object>? _sanitizeParameters(Map<String, dynamic>? params) {
//     if (params == null || params.isEmpty) return null;
//     
//     final result = <String, Object>{};
//     int count = 0;
//     
//     for (final entry in params.entries) {
//       if (count >= 25) break; // Firebase limite à 25 paramètres
//       
//       final key = entry.key;
//       final value = entry.value;
//       
//       // Firebase n'accepte que String, int, double
//       if (value is String || value is int || value is double) {
//         result[key] = value;
//         count++;
//       } else if (value is bool) {
//         result[key] = value ? 1 : 0;
//         count++;
//       } else if (value != null) {
//         result[key] = value.toString();
//         count++;
//       }
//     }
//     
//     return result.isEmpty ? null : result;
//   }
// }
