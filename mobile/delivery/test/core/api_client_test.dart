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
  });
}
