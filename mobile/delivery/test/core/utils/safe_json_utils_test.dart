import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/utils/safe_json_utils.dart';

void main() {
  group('SafeJsonUtils.safeData', () {
    test('Map<String, dynamic> returns as-is', () {
      final data = {'key': 'value'};
      expect(SafeJsonUtils.safeData(data), data);
    });

    test('generic Map gets converted', () {
      final Map data = {'key': 123};
      final result = SafeJsonUtils.safeData(data);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['key'], 123);
    });

    test('non-map returns empty map', () {
      expect(SafeJsonUtils.safeData('string'), {});
      expect(SafeJsonUtils.safeData(null), {});
      expect(SafeJsonUtils.safeData(42), {});
    });
  });

  group('SafeJsonUtils.safeMap', () {
    test('returns map directly', () {
      final data = {'name': 'test'};
      expect(SafeJsonUtils.safeMap(data), data);
    });

    test('extracts nested map by key', () {
      final data = {
        'user': {'name': 'John'},
      };
      expect(SafeJsonUtils.safeMap(data, 'user'), {'name': 'John'});
    });

    test('null key value returns empty', () {
      expect(SafeJsonUtils.safeMap({'a': null}, 'a'), {});
    });

    test('null data returns empty', () {
      expect(SafeJsonUtils.safeMap(null), {});
    });

    test('parses JSON string', () {
      final result = SafeJsonUtils.safeMap('{"x": 1}');
      expect(result, {'x': 1});
    });

    test('invalid JSON string returns empty', () {
      expect(SafeJsonUtils.safeMap('not json'), {});
    });
  });

  group('SafeJsonUtils.safeList', () {
    test('returns list directly', () {
      final data = [1, 2, 3];
      expect(SafeJsonUtils.safeList(data), data);
    });

    test('extracts list by key', () {
      final data = {
        'items': [1, 2],
      };
      expect(SafeJsonUtils.safeList(data, 'items'), [1, 2]);
    });

    test('null returns empty list', () {
      expect(SafeJsonUtils.safeList(null), []);
    });

    test('parses JSON array string', () {
      expect(SafeJsonUtils.safeList('[1,2,3]'), [1, 2, 3]);
    });

    test('invalid string returns empty', () {
      expect(SafeJsonUtils.safeList('invalid'), []);
    });
  });

  group('SafeJsonUtils.safeString', () {
    test('returns string value', () {
      expect(SafeJsonUtils.safeString({'name': 'John'}, 'name'), 'John');
    });

    test('returns null for missing key', () {
      expect(SafeJsonUtils.safeString({'a': 1}, 'b'), isNull);
    });

    test('returns default for missing key', () {
      expect(
        SafeJsonUtils.safeString({'a': 1}, 'b', defaultValue: 'def'),
        'def',
      );
    });

    test('converts non-string to string', () {
      expect(SafeJsonUtils.safeString({'num': 42}, 'num'), '42');
    });

    test('non-map data returns default', () {
      expect(SafeJsonUtils.safeString('nope', 'key'), isNull);
    });
  });

  group('SafeJsonUtils.safeInt', () {
    test('returns int value', () {
      expect(SafeJsonUtils.safeInt({'x': 5}, 'x'), 5);
    });

    test('double → int', () {
      expect(SafeJsonUtils.safeInt({'x': 5.9}, 'x'), 5);
    });

    test('string → int', () {
      expect(SafeJsonUtils.safeInt({'x': '42'}, 'x'), 42);
    });

    test('invalid string → default', () {
      expect(SafeJsonUtils.safeInt({'x': 'abc'}, 'x', defaultValue: -1), -1);
    });

    test('null → default', () {
      expect(SafeJsonUtils.safeInt({'x': null}, 'x'), isNull);
    });

    test('non-map → default', () {
      expect(SafeJsonUtils.safeInt(42, 'x'), isNull);
    });
  });

  group('SafeJsonUtils.safeDouble', () {
    test('returns double value', () {
      expect(SafeJsonUtils.safeDouble({'x': 3.14}, 'x'), 3.14);
    });

    test('int → double', () {
      expect(SafeJsonUtils.safeDouble({'x': 3}, 'x'), 3.0);
    });

    test('string → double', () {
      expect(SafeJsonUtils.safeDouble({'x': '2.5'}, 'x'), 2.5);
    });

    test('null → default', () {
      expect(SafeJsonUtils.safeDouble({'x': null}, 'x'), isNull);
    });
  });

  group('SafeJsonUtils.safeBool', () {
    test('returns bool value', () {
      expect(SafeJsonUtils.safeBool({'x': true}, 'x'), true);
      expect(SafeJsonUtils.safeBool({'x': false}, 'x'), false);
    });

    test('int truthy', () {
      expect(SafeJsonUtils.safeBool({'x': 1}, 'x'), true);
      expect(SafeJsonUtils.safeBool({'x': 0}, 'x'), false);
    });

    test('string truthy', () {
      expect(SafeJsonUtils.safeBool({'x': 'true'}, 'x'), true);
      expect(SafeJsonUtils.safeBool({'x': '1'}, 'x'), true);
      expect(SafeJsonUtils.safeBool({'x': 'false'}, 'x'), false);
    });

    test('null → default false', () {
      expect(SafeJsonUtils.safeBool({'x': null}, 'x'), false);
    });

    test('non-map → default', () {
      expect(SafeJsonUtils.safeBool(42, 'x'), false);
    });
  });

  group('SafeJsonUtils.safeJsonDecode', () {
    test('valid JSON', () {
      expect(SafeJsonUtils.safeJsonDecode('{"a":1}'), {'a': 1});
    });

    test('null → default', () {
      expect(SafeJsonUtils.safeJsonDecode(null, defaultValue: 'x'), 'x');
    });

    test('empty → default', () {
      expect(SafeJsonUtils.safeJsonDecode('', defaultValue: []), []);
    });

    test('invalid JSON → default', () {
      expect(SafeJsonUtils.safeJsonDecode('{bad}', defaultValue: null), isNull);
    });
  });
}
