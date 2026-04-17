import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drpharma_pharmacy/core/network/network_info.dart';

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkInfo', () {
    group('NetworkInfoImpl', () {
      late MockConnectivity mockConnectivity;
      late NetworkInfoImpl networkInfo;

      setUp(() {
        mockConnectivity = MockConnectivity();
        networkInfo = NetworkInfoImpl(connectivity: mockConnectivity);
      });

      test('should return true when connected via wifi', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await networkInfo.isConnected;

        expect(result, isTrue);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when connected via mobile', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        final result = await networkInfo.isConnected;

        expect(result, isTrue);
      });

      test('should return false when not connected', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await networkInfo.isConnected;

        expect(result, isFalse);
      });

      test('should return false when results are empty', () async {
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => []);

        final result = await networkInfo.isConnected;

        expect(result, isFalse);
      });
    });

    group('NetworkInfo abstract class', () {
      test('NetworkInfoImpl should implement NetworkInfo', () {
        final networkInfo = NetworkInfoImpl(connectivity: MockConnectivity());
        expect(networkInfo, isA<NetworkInfo>());
      });
    });
  });
}
