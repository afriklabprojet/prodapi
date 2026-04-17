import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for safe JSON response handling
class SafeJsonUtils {
  SafeJsonUtils._();
  
  /// Parse sécurisé des réponses API (protège contre data qui n'est pas un Map).
  /// Version simplifiée de [safeMap] sans paramètre key.
  static Map<String, dynamic> safeData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  /// Safely extracts a Map from response data
  /// Returns an empty map if extraction fails
  static Map<String, dynamic> safeMap(dynamic data, [String? key]) {
    try {
      dynamic target = data;
      
      // If key is provided, extract nested value
      if (key != null && data is Map) {
        target = data[key];
      }
      
      if (target == null) return {};
      if (target is Map<String, dynamic>) return target;
      if (target is Map) return Map<String, dynamic>.from(target);
      
      // Try parsing as JSON string
      if (target is String) {
        final parsed = jsonDecode(target);
        if (parsed is Map<String, dynamic>) return parsed;
        if (parsed is Map) return Map<String, dynamic>.from(parsed);
      }
      
      return {};
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeMap error: $e');
      return {};
    }
  }
  
  /// Safely extracts a List from response data
  /// Returns an empty list if extraction fails
  static List<dynamic> safeList(dynamic data, [String? key]) {
    try {
      dynamic target = data;
      
      // If key is provided, extract nested value
      if (key != null && data is Map) {
        target = data[key];
      }
      
      if (target == null) return [];
      if (target is List) return target;
      
      // Try parsing as JSON string
      if (target is String) {
        final parsed = jsonDecode(target);
        if (parsed is List) return parsed;
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeList error: $e');
      return [];
    }
  }
  
  /// Safely extracts a String value
  static String? safeString(dynamic data, String key, {String? defaultValue}) {
    try {
      if (data is! Map) return defaultValue;
      final value = data[key];
      if (value == null) return defaultValue;
      return value.toString();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeString error: $e');
      return defaultValue;
    }
  }
  
  /// Safely extracts an int value
  static int? safeInt(dynamic data, String key, {int? defaultValue}) {
    try {
      if (data is! Map) return defaultValue;
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeInt error: $e');
      return defaultValue;
    }
  }
  
  /// Safely extracts a double value
  static double? safeDouble(dynamic data, String key, {double? defaultValue}) {
    try {
      if (data is! Map) return defaultValue;
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeDouble error: $e');
      return defaultValue;
    }
  }
  
  /// Safely extracts a bool value
  static bool safeBool(dynamic data, String key, {bool defaultValue = false}) {
    try {
      if (data is! Map) return defaultValue;
      final value = data[key];
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      return defaultValue;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeBool error: $e');
      return defaultValue;
    }
  }
  
  /// Safely parses JSON string
  static dynamic safeJsonDecode(String? json, {dynamic defaultValue}) {
    if (json == null || json.isEmpty) return defaultValue;
    try {
      return jsonDecode(json);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SafeJsonUtils.safeJsonDecode error: $e');
      return defaultValue;
    }
  }
}
