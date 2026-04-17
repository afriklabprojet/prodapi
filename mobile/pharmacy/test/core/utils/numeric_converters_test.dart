import 'package:flutter_test/flutter_test.dart';
import 'package:drpharma_pharmacy/core/utils/numeric_converters.dart';

void main() {
  group('safeToDouble', () {
    test('should convert int to double', () {
      expect(safeToDouble(42), 42.0);
    });

    test('should return double as is', () {
      expect(safeToDouble(3.14), 3.14);
    });

    test('should parse string to double', () {
      expect(safeToDouble('3.14'), 3.14);
    });

    test('should return 0.0 for null', () {
      expect(safeToDouble(null), 0.0);
    });

    test('should return 0.0 for invalid string', () {
      expect(safeToDouble('invalid'), 0.0);
    });

    test('should return 0.0 for non-numeric types', () {
      expect(safeToDouble([1, 2, 3]), 0.0);
      expect(safeToDouble({'key': 'value'}), 0.0);
    });
  });

  group('safeToDoubleNullable', () {
    test('should convert int to double', () {
      expect(safeToDoubleNullable(42), 42.0);
    });

    test('should return double as is', () {
      expect(safeToDoubleNullable(3.14), 3.14);
    });

    test('should parse string to double', () {
      expect(safeToDoubleNullable('3.14'), 3.14);
    });

    test('should return null for null input', () {
      expect(safeToDoubleNullable(null), isNull);
    });

    test('should return null for invalid string', () {
      expect(safeToDoubleNullable('invalid'), isNull);
    });

    test('should return null for non-numeric types', () {
      expect(safeToDoubleNullable([1, 2, 3]), isNull);
    });
  });

  group('safeToInt', () {
    test('should return int as is', () {
      expect(safeToInt(42), 42);
    });

    test('should convert double to int', () {
      expect(safeToInt(3.14), 3);
      expect(safeToInt(3.99), 3);
    });

    test('should parse string to int', () {
      expect(safeToInt('42'), 42);
    });

    test('should return 0 for null', () {
      expect(safeToInt(null), 0);
    });

    test('should return 0 for invalid string', () {
      expect(safeToInt('invalid'), 0);
    });

    test('should return 0 for non-numeric types', () {
      expect(safeToInt([1, 2, 3]), 0);
    });
  });

  group('safeToIntNullable', () {
    test('should return int as is', () {
      expect(safeToIntNullable(42), 42);
    });

    test('should convert double to int', () {
      expect(safeToIntNullable(3.14), 3);
    });

    test('should parse string to int', () {
      expect(safeToIntNullable('42'), 42);
    });

    test('should return null for null input', () {
      expect(safeToIntNullable(null), isNull);
    });

    test('should return null for invalid string', () {
      expect(safeToIntNullable('invalid'), isNull);
    });

    test('should return null for non-numeric types', () {
      expect(safeToIntNullable([1, 2, 3]), isNull);
    });
  });

  group('safeToString', () {
    test('should return string as is', () {
      expect(safeToString('hello'), 'hello');
    });

    test('should convert int to string', () {
      expect(safeToString(42), '42');
    });

    test('should convert double to string', () {
      expect(safeToString(3.14), '3.14');
    });

    test('should return empty string for null by default', () {
      expect(safeToString(null), '');
    });

    test('should return custom default for null', () {
      expect(safeToString(null, defaultValue: 'N/A'), 'N/A');
    });
  });

  group('safeToBool', () {
    test('should return bool as is', () {
      expect(safeToBool(true), true);
      expect(safeToBool(false), false);
    });

    test('should convert int to bool', () {
      expect(safeToBool(1), true);
      expect(safeToBool(0), false);
      expect(safeToBool(42), true);
    });

    test('should convert string to bool', () {
      expect(safeToBool('true'), true);
      expect(safeToBool('TRUE'), true);
      expect(safeToBool('1'), true);
      expect(safeToBool('yes'), true);
      expect(safeToBool('false'), false);
      expect(safeToBool('0'), false);
      expect(safeToBool('no'), false);
    });

    test('should return default for null', () {
      expect(safeToBool(null), false);
      expect(safeToBool(null, defaultValue: true), true);
    });

    test('should return default for invalid types', () {
      expect(safeToBool([1, 2, 3]), false);
      expect(safeToBool({'key': 'value'}), false);
    });
  });
}
