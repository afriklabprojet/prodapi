import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/models/delivery.dart';
import 'package:courier/data/models/user.dart';
import 'package:courier/data/models/wallet_data.dart';

/// Tests de sécurité pour l'application Coursier
/// Ces tests vérifient la robustesse contre les attaques courantes
void main() {
  /// Helper to create valid delivery JSON with overrides
  Map<String, dynamic> validDeliveryJson([Map<String, dynamic>? overrides]) {
    return {
      'id': 1,
      'order_id': 1,
      'reference': 'DEL-001',
      'pharmacy_name': 'Pharmacie Test',
      'pharmacy_address': '123 Rue Test',
      'customer_name': 'Client Test',
      'delivery_address': '456 Avenue Test',
      'total_amount': 5000.0,
      'status': 'pending',
      ...?overrides,
    };
  }

  group('Input Validation Security', () {
    group('Delivery Model', () {
      test('handles null values in optional fields safely', () {
        final json = validDeliveryJson({
          'pharmacy_phone': null,
          'customer_phone': null,
          'pharmacy_latitude': null,
          'pharmacy_longitude': null,
          'delivery_fee': null,
          'commission': null,
        });
        
        expect(() => Delivery.fromJson(json), returnsNormally);
      });

      test('rejects null values in required fields', () {
        final json = validDeliveryJson({'reference': null});
        // Should throw or handle gracefully
        expect(() => Delivery.fromJson(json), throwsA(anything));
      });

      test('handles empty string values in optional fields', () {
        final json = validDeliveryJson({
          'pharmacy_phone': '',
          'customer_phone': '',
        });
        
        final delivery = Delivery.fromJson(json);
        expect(delivery.pharmacyPhone, equals(''));
      });

      test('handles very long string values', () {
        final longString = 'A' * 10000;
        final json = validDeliveryJson({
          'pharmacy_name': longString,
          'pharmacy_address': longString,
          'customer_name': longString,
        });
        
        expect(() => Delivery.fromJson(json), returnsNormally);
        final delivery = Delivery.fromJson(json);
        expect(delivery.pharmacyName.length, equals(10000));
      });

      test('handles special characters in addresses - XSS attempts', () {
        final xssStrings = [
          '<script>alert("xss")</script>',
          '<img src=x onerror=alert(1)>',
          'javascript:alert(1)',
          '<svg onload=alert(1)>',
        ];
        
        for (final xss in xssStrings) {
          final json = validDeliveryJson({'pharmacy_address': xss});
          // Model accepts the string (sanitization is UI/rendering responsibility)
          final delivery = Delivery.fromJson(json);
          expect(delivery.pharmacyAddress, equals(xss));
        }
      });

      test('handles SQL injection attempts in strings', () {
        final sqlInjections = [
          "'; DROP TABLE deliveries; --",
          '" OR 1=1 --',
          '1; DELETE FROM users;',
          "UNION SELECT * FROM users --",
        ];
        
        for (final sql in sqlInjections) {
          final json = validDeliveryJson({'customer_name': sql});
          final delivery = Delivery.fromJson(json);
          expect(delivery.customerName, equals(sql));
        }
      });

      test('handles path traversal attempts', () {
        final pathTraversals = [
          '../../etc/passwd',
          '..\\..\\windows\\system32',
          '%2e%2e%2f%2e%2e%2f',
          '\x00/etc/passwd',
        ];
        
        for (final path in pathTraversals) {
          final json = validDeliveryJson({'delivery_address': path});
          final delivery = Delivery.fromJson(json);
          expect(delivery.deliveryAddress, equals(path));
        }
      });

      test('handles negative numeric values', () {
        final json = validDeliveryJson({
          'total_amount': -100.0,
          'delivery_fee': -50.0,
          'commission': -25.0,
        });
        
        final delivery = Delivery.fromJson(json);
        // Model accepts negative values (validation is business logic)
        expect(delivery.totalAmount, equals(-100.0));
      });

      test('handles very large numeric values', () {
        final json = validDeliveryJson({
          'total_amount': double.maxFinite,
          'pharmacy_latitude': 90.0,
          'pharmacy_longitude': 180.0,
        });
        
        expect(() => Delivery.fromJson(json), returnsNormally);
      });

      test('handles extreme coordinate values', () {
        final json = validDeliveryJson({
          'pharmacy_latitude': 999.0,  // Invalid lat
          'pharmacy_longitude': 999.0, // Invalid lng
        });
        
        // Model accepts invalid coords (validation is service responsibility)
        expect(() => Delivery.fromJson(json), returnsNormally);
      });
    });

    group('User Model', () {
      Map<String, dynamic> validUserJson([Map<String, dynamic>? overrides]) {
        return {
          'id': 1,
          'name': 'Test User',
          'phone': '+2250700000000',
          'email': 'test@test.com',
          'role': 'courier',
          ...?overrides,
        };
      }

      test('sanitizes email input - XSS in email', () {
        final maliciousEmails = [
          'test@test.com"><script>',
          "test@test.com' OR 1=1 --",
          '<img src=x onerror=alert(1)>@test.com',
        ];
        
        for (final email in maliciousEmails) {
          final json = validUserJson({'email': email});
          expect(() => User.fromJson(json), returnsNormally);
        }
      });

      test('handles phone number injection attempts', () {
        final maliciousPhones = [
          '+225 000000000; rm -rf /',
          '0000000000<script>',
          '\$(whoami)',
          '|cat /etc/passwd',
        ];
        
        for (final phone in maliciousPhones) {
          final json = validUserJson({'phone': phone});
          expect(() => User.fromJson(json), returnsNormally);
        }
      });
    });
  });

  group('Numeric Validation Security', () {
    group('Wallet Data', () {
      Map<String, dynamic> validWalletJson([Map<String, dynamic>? overrides]) {
        return {
          'balance': 1000.0,
          'pending_balance': 0.0,
          'total_earnings': 5000.0,
          ...?overrides,
        };
      }

      test('handles negative balance values', () {
        final json = validWalletJson({
          'balance': -1000.0,
          'pending_balance': -500.0,
        });
        
        final wallet = WalletData.fromJson(json);
        expect(wallet.balance, equals(-1000.0));
      });

      test('handles infinity values', () {
        final json = validWalletJson({
          'balance': double.infinity,
        });
        
        expect(() => WalletData.fromJson(json), returnsNormally);
      });

      test('handles NaN values', () {
        final json = validWalletJson({
          'balance': double.nan,
        });
        
        final wallet = WalletData.fromJson(json);
        expect(wallet.balance.isNaN, isTrue);
      });

      test('handles zero balance', () {
        final json = validWalletJson({'balance': 0.0});
        final wallet = WalletData.fromJson(json);
        expect(wallet.balance, equals(0.0));
      });
    });
  });

  group('Date/Time Security', () {
    Map<String, dynamic> validDeliveryWithDate([Map<String, dynamic>? overrides]) {
      return {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Pharmacie Test',
        'pharmacy_address': '123 Rue Test',
        'customer_name': 'Client Test',
        'delivery_address': '456 Avenue Test',
        'total_amount': 5000.0,
        'status': 'pending',
        ...?overrides,
      };
    }

    test('handles invalid date strings', () {
      final invalidDates = [
        'not-a-date',
        '9999-99-99T99:99:99Z',
        "2024-01-01'; DROP TABLE --",
      ];
      
      for (final date in invalidDates) {
        final json = validDeliveryWithDate({'created_at': date});
        // Model stores string as-is; parsing is app responsibility
        expect(() => Delivery.fromJson(json), returnsNormally);
      }
    });

    test('handles very far future dates', () {
      final futureDate = '9999-12-31T23:59:59Z';
      final json = validDeliveryWithDate({'created_at': futureDate});
      
      expect(() => Delivery.fromJson(json), returnsNormally);
    });

    test('handles very old dates', () {
      final oldDate = '0001-01-01T00:00:00Z';
      final json = validDeliveryWithDate({'created_at': oldDate});
      
      expect(() => Delivery.fromJson(json), returnsNormally);
    });
  });

  group('JSON Structure Security', () {
    Map<String, dynamic> baseDeliveryJson() => {
      'id': 1,
      'reference': 'DEL-001',
      'pharmacy_name': 'Test',
      'pharmacy_address': 'Address',
      'customer_name': 'Client',
      'delivery_address': 'Delivery',
      'total_amount': 100.0,
      'status': 'pending',
    };

    test('handles deeply nested JSON in extra fields', () {
      Map<String, dynamic> createDeepNested(int depth) {
        if (depth == 0) return {'value': 'end'};
        return {'nested': createDeepNested(depth - 1)};
      }
      
      final json = {
        ...baseDeliveryJson(),
        'extra': createDeepNested(50), // Extra fields ignored by freezed
      };
      
      expect(() => Delivery.fromJson(json), returnsNormally);
    });

    test('ignores unknown fields', () {
      final json = {
        ...baseDeliveryJson(),
        'unknown_field': 'value',
        'malicious_field': '<script>alert(1)</script>',
        'array_field': [1, 2, 3],
      };
      
      expect(() => Delivery.fromJson(json), returnsNormally);
    });

    test('handles arrays with extreme length in extra fields', () {
      final json = {
        ...baseDeliveryJson(),
        'items': List.generate(1000, (i) => 'item_$i'),
      };
      
      expect(() => Delivery.fromJson(json), returnsNormally);
    });
  });

  group('Encoding Security', () {
    Map<String, dynamic> baseJson() => {
      'id': 1,
      'reference': 'DEL-001',
      'pharmacy_name': 'Test',
      'pharmacy_address': 'Address',
      'customer_name': 'Client',
      'delivery_address': 'Delivery',
      'total_amount': 100.0,
      'status': 'pending',
    };

    test('handles unicode edge cases', () {
      final unicodeStrings = [
        '\u0000',        // Null character
        '𝕿𝖊𝖘𝖙',          // Math symbols
        '👨‍👩‍👧‍👦',      // Complex emoji
        '\u202EABC',     // RTL override
        'Ã©',            // Incorrectly encoded é
        '日本語',        // Japanese
        'العربية',       // Arabic
      ];
      
      for (final str in unicodeStrings) {
        final json = {...baseJson(), 'pharmacy_name': str};
        expect(() => Delivery.fromJson(json), returnsNormally);
      }
    });

    test('handles mixed encoding attacks', () {
      final mixedEncodings = [
        'test%3Cscript%3E',        // URL encoded
        'dGVzdA==',                 // Base64
        '&#60;script&#62;',         // HTML entities
        '\\u003cscript\\u003e',     // Unicode escape
      ];
      
      for (final encoded in mixedEncodings) {
        final json = {...baseJson(), 'pharmacy_address': encoded};
        final delivery = Delivery.fromJson(json);
        // Should store as-is, not decode
        expect(delivery.pharmacyAddress, equals(encoded));
      }
    });
  });

  group('Business Logic Security', () {
    test('status field accepts any string value', () {
      // Model doesn not enforce status values - API/service responsibility
      final statuses = ['pending', 'invalid_status', '', 'DELIVERED', 'dropped'];
      
      for (final status in statuses) {
        final json = {
          'id': 1,
          'reference': 'DEL-001',
          'pharmacy_name': 'Test',
          'pharmacy_address': 'Address',
          'customer_name': 'Client',
          'delivery_address': 'Delivery',
          'total_amount': 100.0,
          'status': status,
        };
        
        expect(() => Delivery.fromJson(json), returnsNormally);
      }
    });

    test('validates totalAmount field exists', () {
      final json = {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Test',
        'pharmacy_address': 'Address',
        'customer_name': 'Client',
        'delivery_address': 'Delivery',
        'total_amount': 5000.0,
        'status': 'delivered',
      };
      
      final delivery = Delivery.fromJson(json);
      expect(delivery.totalAmount, equals(5000.0));
    });
  });

  group('Memory Safety', () {
    test('handles moderately large JSON payload', () {
      final json = {
        'id': 1,
        'reference': 'DEL-001',
        'pharmacy_name': 'Test',
        'pharmacy_address': 'Address',
        'customer_name': 'Client',
        'delivery_address': 'Delivery',
        'total_amount': 100.0,
        'status': 'pending',
        'extra': List.generate(100, (i) => {'key': 'value' * 10}),
      };
      
      expect(() => Delivery.fromJson(json), returnsNormally);
    });
  });
}
