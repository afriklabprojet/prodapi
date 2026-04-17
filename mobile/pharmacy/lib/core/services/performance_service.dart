import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Service de monitoring de performance utilisant Firebase Performance.
/// Trace les requêtes HTTP, les écrans et les métriques custom.
/// Gracefully handles missing Firebase initialization (e.g., in tests).
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._();
  factory PerformanceService() => _instance;
  PerformanceService._();

  FirebasePerformance? _performance;
  final Map<String, Trace> _activeTraces = {};

  /// Returns true if Firebase Performance is available
  bool get isAvailable => _performance != null;

  /// Lazily initialize Firebase Performance (only if Firebase is ready)
  FirebasePerformance? get performance {
    if (_performance == null) {
      try {
        // Check if Firebase is initialized
        Firebase.app();
        _performance = FirebasePerformance.instance;
      } catch (_) {
        // Firebase not initialized (e.g., in tests)
        if (kDebugMode) {
          debugPrint(
            '📊 [Performance] Firebase not initialized, skipping performance monitoring',
          );
        }
      }
    }
    return _performance;
  }

  /// Active/désactive la collecte (désactivé en debug pour ne pas polluer les données)
  Future<void> initialize() async {
    final perf = performance;
    if (perf == null) return;

    await perf.setPerformanceCollectionEnabled(!kDebugMode);
    if (kDebugMode) {
      debugPrint('📊 [Performance] Initialized (collection: ${!kDebugMode})');
    }
  }

  /// Démarre une trace custom (ex: "order_flow", "prescription_scan")
  Future<Trace?> startTrace(String name) async {
    final perf = performance;
    if (perf == null) return null;

    try {
      final trace = perf.newTrace(name);
      await trace.start();
      _activeTraces[name] = trace;
      if (kDebugMode) debugPrint('📊 [Trace] Started: $name');
      return trace;
    } catch (e) {
      if (kDebugMode) debugPrint('📊 [Trace] Error starting $name: $e');
      return null;
    }
  }

  /// Arrête une trace et l'envoie à Firebase
  Future<void> stopTrace(
    String name, {
    Map<String, int>? metrics,
    Map<String, String>? attributes,
  }) async {
    final trace = _activeTraces.remove(name);
    if (trace != null) {
      try {
        // Ajouter des métriques custom
        metrics?.forEach((key, value) {
          trace.setMetric(key, value);
        });
        // Ajouter des attributs
        attributes?.forEach((key, value) {
          trace.putAttribute(key, value);
        });
        await trace.stop();
        if (kDebugMode) debugPrint('📊 [Trace] Stopped: $name');
      } catch (e) {
        if (kDebugMode) debugPrint('📊 [Trace] Error stopping $name: $e');
      }
    }
  }

  /// Trace une opération async avec durée automatique
  Future<T> traceAsync<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    await startTrace(name);
    try {
      final result = await operation();
      await stopTrace(name, attributes: attributes);
      return result;
    } catch (e) {
      await stopTrace(
        name,
        attributes: {...?attributes, 'error': e.runtimeType.toString()},
      );
      rethrow;
    }
  }

  /// Crée un HttpMetric pour tracer une requête HTTP
  /// Returns null if Firebase is not available
  HttpMetric? newHttpMetric(String url, HttpMethod method) {
    final perf = performance;
    if (perf == null) return null;
    return perf.newHttpMetric(url, method);
  }
}

/// Interceptor Dio pour tracer automatiquement les requêtes HTTP avec Firebase Performance
/// Gracefully handles missing Firebase initialization.
class PerformanceInterceptor extends Interceptor {
  final PerformanceService _service = PerformanceService();
  final Map<RequestOptions, HttpMetric> _metrics = {};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_service.isAvailable) {
      handler.next(options);
      return;
    }

    try {
      final url = options.uri.toString();
      final method = _mapMethod(options.method);
      final metric = _service.newHttpMetric(url, method);
      if (metric != null) {
        await metric.start();
        metric.requestPayloadSize = options.data?.toString().length ?? 0;
        _metrics[options] = metric;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('📊 [HTTP Metric] Error starting: $e');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await _stopMetric(
      response.requestOptions,
      response.statusCode,
      response.data?.toString().length,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    await _stopMetric(err.requestOptions, err.response?.statusCode, null);
    handler.next(err);
  }

  Future<void> _stopMetric(
    RequestOptions options,
    int? statusCode,
    int? responseSize,
  ) async {
    final metric = _metrics.remove(options);
    if (metric != null) {
      try {
        metric.httpResponseCode = statusCode;
        if (responseSize != null) {
          metric.responsePayloadSize = responseSize;
        }
        await metric.stop();
      } catch (e) {
        if (kDebugMode) debugPrint('📊 [HTTP Metric] Error stopping: $e');
      }
    }
  }

  HttpMethod _mapMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      default:
        return HttpMethod.Get;
    }
  }
}
