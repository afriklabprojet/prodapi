import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/safe_json.dart';

void main() {
  group('safeInt', () {
    test('null → 0', () => expect(safeInt(null), 0));
    test('int → value', () => expect(safeInt(42), 42));
    test('double → truncated', () => expect(safeInt(3.9), 3));
    test('numeric string → parsed', () => expect(safeInt('123'), 123));
    test('invalid string → 0', () => expect(safeInt('abc'), 0));
    test('bool → 0', () => expect(safeInt(true), 0));
  });

  group('safeDouble', () {
    test('null → 0.0', () => expect(safeDouble(null), 0.0));
    test('double → value', () => expect(safeDouble(3.14), 3.14));
    test('int → double', () => expect(safeDouble(5), 5.0));
    test('numeric string → parsed', () => expect(safeDouble('2.5'), 2.5));
    test('invalid string → 0.0', () => expect(safeDouble('xyz'), 0.0));
    test('bool → 0.0', () => expect(safeDouble(true), 0.0));
  });

  group('safeIntOrNull', () {
    test('null → null', () => expect(safeIntOrNull(null), isNull));
    test('int → value', () => expect(safeIntOrNull(42), 42));
    test('double → truncated', () => expect(safeIntOrNull(3.9), 3));
    test('numeric string → parsed', () => expect(safeIntOrNull('55'), 55));
    test('invalid string → null', () => expect(safeIntOrNull('abc'), isNull));
    test('bool → null', () => expect(safeIntOrNull(true), isNull));
  });

  group('safeDoubleOrNull', () {
    test('null → null', () => expect(safeDoubleOrNull(null), isNull));
    test('double → value', () => expect(safeDoubleOrNull(1.5), 1.5));
    test('int → double', () => expect(safeDoubleOrNull(3), 3.0));
    test('numeric string → parsed', () => expect(safeDoubleOrNull('4.2'), 4.2));
    test(
      'invalid string → null',
      () => expect(safeDoubleOrNull('xyz'), isNull),
    );
    test('bool → null', () => expect(safeDoubleOrNull(false), isNull));
  });
}
