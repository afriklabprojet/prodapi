import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/features/profile/presentation/providers/profile_provider.dart';
import 'package:drpharma_pharmacy/features/auth/presentation/providers/auth_di_providers.dart';
import 'package:drpharma_pharmacy/features/auth/domain/repositories/auth_repository.dart';
import 'package:drpharma_pharmacy/core/providers/core_providers.dart';
import 'package:drpharma_pharmacy/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockApiClient mockApiClient;
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    mockAuthRepository = MockAuthRepository();
    container = ProviderContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient),
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('ProfileNotifier initial state', () {
    test('initial state is AsyncData(null)', () {
      expect(container.read(profileProvider), isA<AsyncData<void>>());
    });
  });

  // Note: Full integration tests require mocking HTTP calls through ApiClient.
  // These tests verify the provider structure is correct.
}
