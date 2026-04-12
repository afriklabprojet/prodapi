import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/network/api_client.dart';

void main() {
  group('dioProvider', () {
    test('creates Dio instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      expect(dio, isA<Dio>());
    });

    test('has correct base URL configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      expect(dio.options.baseUrl, isNotEmpty);
    });

    test('has interceptors configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      expect(dio.interceptors, isNotEmpty);
    });

    test('has timeout configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      expect(dio.options.connectTimeout, isNotNull);
    });

    test('returns same instance from same container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio1 = container.read(dioProvider);
      final dio2 = container.read(dioProvider);
      expect(identical(dio1, dio2), isTrue);
    });

    test('has headers configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      expect(dio.options.headers, isNotNull);
    });
  });
}
