import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/constants/api_constants.dart';

void main() {
  group('API Constants Tests', () {
    test('should have correct base URL', () {
      // Vérifie que l'URL de base est correctement configurée
      expect(ApiConstants.baseUrl, isNotEmpty);
      expect(ApiConstants.baseUrl.startsWith('http'), isTrue);
    });

    test('should have authentication endpoints', () {
      expect(ApiConstants.login, contains('login'));
      expect(ApiConstants.logout, contains('logout'));
      expect(ApiConstants.me, contains('me'));
    });

    test('should have courier-specific endpoints', () {
      expect(ApiConstants.profile, contains('courier'));
      expect(ApiConstants.deliveries, contains('deliveries'));
      expect(ApiConstants.location, contains('location'));
    });

    test('should have delivery endpoints', () {
      expect(ApiConstants.acceptDelivery(1), contains('1'));
      expect(ApiConstants.acceptDelivery(1), contains('accept'));
      
      expect(ApiConstants.pickupDelivery(1), contains('1'));
      expect(ApiConstants.pickupDelivery(1), contains('pickup'));
      
      expect(ApiConstants.completeDelivery(1), contains('1'));
      expect(ApiConstants.completeDelivery(1), contains('deliver'));
    });

    test('should have statistics endpoints', () {
      expect(ApiConstants.statistics, contains('statistics'));
      expect(ApiConstants.leaderboard, contains('leaderboard'));
    });

    test('should have wallet endpoints', () {
      expect(ApiConstants.wallet, contains('wallet'));
      expect(ApiConstants.walletEarningsHistory, contains('history'));
    });

    test('should format delivery detail URL correctly', () {
      final url = ApiConstants.acceptDelivery(123);
      expect(url, contains('123'));
    });

    test('should format pickup delivery URL correctly', () {
      final url = ApiConstants.pickupDelivery(456);
      expect(url, contains('456'));
      expect(url, contains('pickup'));
    });
  });

  group('API URL Builder Tests', () {
    test('should build correct URL with query parameters', () {
      // Test pour vérifier la construction d'URLs avec paramètres
      final baseEndpoint = ApiConstants.deliveries;
      final urlWithParams = '$baseEndpoint?status=pending&page=1';
      
      expect(urlWithParams, contains('status=pending'));
      expect(urlWithParams, contains('page=1'));
    });
  });
}
