import 'dart:convert';

import 'package:test/test.dart';
import 'package:json_patch/json_patch.dart';

void main() {
  group('JsonPatch', () {
    test('.diff does not patch unchanged JSON', () {
      final json = {
        'object': {'test': 123, 'anotherTest': true, 'nested': {}},
        'value': true,
      };
      expect(JsonPatch.diff(json, json), isEmpty);
    });
    test('.diff finds added values', () {
      final result = JsonPatch.diff(
        {
          'object': {'test': 123}
        },
        {
          'object': {'test': 123, 'newKey': 'newValue'}
        },
      );
      expect(result, hasLength(1));
      expect(
          result[0],
          allOf(
            containsPair('op', 'add'),
            containsPair('path', '/object/newKey'),
            containsPair('value', 'newValue'),
          ));
    });
    test('.diff finds replaced values', () {
      var result = JsonPatch.diff(
        {
          'object': {'test': 123, 'oldKey': 'oldValue'}
        },
        {
          'object': {'test': 123, 'oldKey': 'newValue'}
        },
      );
      expect(result, hasLength(1));
      expect(
          result[0],
          allOf(
            containsPair('op', 'replace'),
            containsPair('path', '/object/oldKey'),
            containsPair('value', 'newValue'),
          ));

      result = JsonPatch.diff(
        {
          'object': {'test': 123, 'oldKey': 'oldValue'}
        },
        {
          'object': {'test': 123, 'oldKey': true}
        },
      );
      expect(result, hasLength(1));
      expect(
          result[0],
          allOf(
            containsPair('op', 'replace'),
            containsPair('path', '/object/oldKey'),
            containsPair('value', true),
          ));
    });
    test('.diff finds removed values', () {
      final result = JsonPatch.diff(
        {
          'object': {'test': 123, 'oldKey': 'oldValue'}
        },
        {
          'object': {'test': 123}
        },
      );
      expect(result, hasLength(1));
      expect(
          result[0],
          allOf(
            containsPair('op', 'remove'),
            containsPair('path', '/object/oldKey'),
            isNot(contains('value')),
          ));
    });
    test('.diff finds root changes', () {
      final result = JsonPatch.diff(1, 'test');
      expect(result, hasLength(1));
      expect(
          result[0],
          allOf(
            containsPair('op', 'replace'),
            containsPair('path', ''),
            containsPair('value', 'test'),
          ));
    });
    test('.diff converts special characters properly', () {
      final result = JsonPatch.diff(
        {
          'object': {'test': 123}
        },
        {
          'object': {'test': 123, 'new/key~with/special~characters': 'newValue'}
        },
      );
      expect(result, hasLength(1));
      expect(
        result[0],
        containsPair('path', '/object/new~1key~0with~1special~0characters'),
      );
    });

    test('.apply works for add operations', () {
      final result = JsonPatch.apply({
        'object': {}
      }, [
        {'op': 'add', 'path': '/object/child', 'value': 5}
      ]);
      expect(result, contains('object'));
      expect(result['object'], containsPair('child', 5));
    });
    test('.apply works for remove operations', () {
      final result = JsonPatch.apply({
        'a': 5
      }, [
        {'op': 'remove', 'path': '/a'}
      ]);
      expect(result, isEmpty);
    });
    test('.apply works for replace operations', () {
      final result = JsonPatch.apply({
        'a': 5
      }, [
        {'op': 'replace', 'path': '/a', 'value': 'test'}
      ]);
      expect(result, containsPair('a', 'test'));
    });
    test('.apply works for copy operations', () {
      final result = JsonPatch.apply({
        'a': 5
      }, [
        {'op': 'copy', 'from': '/a', 'to': '/b'}
      ]);
      expect(
          result,
          allOf(
            containsPair('a', 5),
            containsPair('b', 5),
          ));
    });
    test('.apply works for move operations', () {
      final result = JsonPatch.apply({
        'a': 5
      }, [
        {'op': 'move', 'from': '/a', 'to': '/b'}
      ]);
      expect(
          result,
          allOf(
            isNot(contains('a')),
            containsPair('b', 5),
          ));
    });
    test('.apply works succeeding test operations', () {
      JsonPatch.apply({
        'a': 5,
        'object': {'test': 'kek'},
      }, [
        {'op': 'test', 'path': '/a', 'value': 5},
        {
          'op': 'test',
          'path': '/object',
          'value': {'test': 'kek'}
        },
      ]);
    });
    test('.apply throws at failing test operations', () {
      expect(
          () => JsonPatch.apply({
                'a': 5,
                'object': {'test': 'kek'},
              }, [
                {'op': 'test', 'path': '/a', 'value': 6},
              ]),
          throwsA(anything));
      expect(
          () => JsonPatch.apply({
                'a': 5,
                'object': {'test': 'kek'},
              }, [
                {
                  'op': 'test',
                  'path': '/object',
                  'value': {'test': 'lel'}
                },
              ]),
          throwsA(anything));
    });
    test('.apply throws at invalid operations', () {
      expect(
          () => JsonPatch.apply({
                'a': 5
              }, [
                {'op': 'add', 'path': '/a', 'value': 6}
              ]),
          throwsA(anything));
      expect(
          () => JsonPatch.apply({
                'test': 5
              }, [
                {'op': 'replace', 'path': '/a', 'value': 6}
              ]),
          throwsA(anything));
      expect(
          () => JsonPatch.apply({
                'test': 5
              }, [
                {'op': 'remove', 'path': '/a'}
              ]),
          throwsA(anything));
      expect(
          () => JsonPatch.apply({
                'test': 5
              }, [
                {'op': 'move', 'path': '/a', 'to': '/b'}
              ]),
          throwsA(anything));
      expect(
          () => JsonPatch.apply({
                'test': 5
              }, [
                {'op': 'copy', 'path': '/a', 'to': '/b'}
              ]),
          throwsA(anything));
    });
    test('.apply allows invalid operations in non-strict mode', () {
      expect(
          JsonPatch.apply({
            'a': 5
          }, [
            {'op': 'add', 'path': '/a', 'value': 6}
          ], strict: false),
          containsPair('a', 6));
      expect(
          JsonPatch.apply({
            'test': 5
          }, [
            {'op': 'replace', 'path': '/a', 'value': 6}
          ], strict: false),
          allOf(containsPair('test', 5), containsPair('a', 6)));
      expect(
          JsonPatch.apply({
            'test': 5
          }, [
            {'op': 'remove', 'path': '/a'}
          ], strict: false),
          containsPair('test', 5));
    });
    test('.apply works for root operations', () {
      expect(
          JsonPatch.apply({
            'kek': 5
          }, [
            {'op': 'replace', 'path': '', 'value': 5}
          ]),
          equals(5));
      expect(
          JsonPatch.apply({
            'kek': 5
          }, [
            {'op': 'remove', 'path': ''}
          ]),
          equals(null));
      expect(
          JsonPatch.apply(5, [
            {'op': 'test', 'path': '', 'value': 5}
          ]),
          equals(5));
      expect(
          () => JsonPatch.apply(5, [
                {'op': 'test', 'path': '', 'value': 6}
              ]),
          throwsA(anything));
    });
    test('.apply works for complex nested operations', () {
      final result = JsonPatch.apply({
        'complex/object~': [
          1,
          2,
          {'test': 3}
        ]
      }, [
        {'op': 'add', 'path': '/complex~1object~0/2/kek', 'value': 4},
        {'op': 'add', 'path': '/complex~1object~0/-', 'value': 4},
        {'op': 'remove', 'path': '/complex~1object~0/1'},
        {'op': 'replace', 'path': '/complex~1object~0/0', 'value': 'test'},
        {'op': 'test', 'path': '/complex~1object~0/0', 'value': 'test'},
      ]);
      expect(
          json.encode(result),
          equals(json.encode({
            'complex/object~': [
              'test',
              {'test': 3, 'kek': 4},
              4
            ]
          })));
    });

    test('.apply does not modify the patch operation lists', () {
      final value = [];
      final operations = [
        {'op': 'add', 'path': '/list', 'value': value},
        {'op': 'add', 'path': '/list/-', 'value': 5},
      ];
      JsonPatch.apply({}, operations);
      expect(value, isEmpty);
    });
    test('.apply does not modify the patch operation object', () {
      final value = <String, dynamic>{};
      final operations = [
        {'op': 'add', 'path': '/obj', 'value': value},
        {'op': 'add', 'path': '/obj/test', 'value': 5},
      ];
      JsonPatch.apply({}, operations);
      expect(value, isEmpty);
    });
  });
}
