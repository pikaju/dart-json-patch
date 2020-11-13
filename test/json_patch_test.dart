import 'dart:convert';

import 'package:json_patch/json_patch.dart';
import 'package:test/test.dart';

void main() {
  group('.diff', () {
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
      _checkPatch(result[0], 'add', '/object/newKey', value: 'newValue');
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
      _checkPatch(result[0], 'replace', '/object/oldKey', value: 'newValue');

      result = JsonPatch.diff(
        {
          'object': {'test': 123, 'oldKey': 'oldValue'}
        },
        {
          'object': {'test': 123, 'oldKey': true}
        },
      );
      expect(result, hasLength(1));
      _checkPatch(result[0], 'replace', '/object/oldKey', value: true);
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
      _checkPatch(result[0], 'remove', '/object/oldKey');
    });
    test('.diff finds root changes', () {
      final result = JsonPatch.diff(1, 'test');
      expect(result, hasLength(1));
      _checkPatch(result[0], 'replace', '', value: 'test');
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

    test('.diff finds added values in arrays', () {
      final oldJson = [0, 1, 4];
      final newJson = [
        0,
        1,
        2,
        3,
        4,
        {'value': 5},
        [1, 2, 3]
      ];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(4));
      _checkPatch(
        result[0],
        'add',
        '/-',
        value: [1, 2, 3],
      );
      _checkPatch(
        result[1],
        'add',
        '/3',
        value: {'value': 5},
      );
      _checkPatch(result[2], 'add', '/2', value: 3);
      _checkPatch(result[3], 'add', '/2', value: 2);
    });

    test('.diff finds values to replace', () {
      final oldJson = [1];
      final newJson = [0];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(1));
      _checkPatch(
        result[0],
        'replace',
        '/0',
        value: 0,
      );
    });

    test('.diff finds removed values in arrays', () {
      final oldJson = [
        0,
        1,
        2,
        3,
        [1, 2, 3],
        {'value': 5},
      ];
      final newJson = [0, 1, 3];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(3));
      _checkPatch(result[0], 'remove', '/5');
      _checkPatch(result[1], 'remove', '/4');
      _checkPatch(result[2], 'remove', '/2');
    });

    test('.diff finds removed and added values in arrays', () {
      final oldJson = {
        'object': {
          'test': [0, 3, 4]
        }
      };
      final newJson = {
        'object': {
          'test': [0, 1, 3]
        }
      };
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(2));
      _checkPatch(result[0], 'remove', '/object/test/2');
      _checkPatch(result[1], 'add', '/object/test/1', value: 1);
    });

    test('.diff finds values to replace', () {
      final oldJson = [
        {'value': 0},
        {'value': 1},
        {'value': 2},
        {'value': 3}
      ];
      final newJson = [
        {'value': 0},
        {'value': 1},
        {'value': 4},
        {'value': 5}
      ];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(2));
      _checkPatch(result[0], 'replace', '/3/value', value: 5);
      _checkPatch(result[1], 'replace', '/2/value', value: 4);
    });

    test('.diff of an array handles nested json', () {
      final oldJson = {
        'object': {
          'test': [
            {'sharedValue': 'sharedValue'},
            {
              'changedValue': [1, 2, 3]
            }
          ]
        }
      };
      final newJson = {
        'object': {
          'test': [
            {'sharedValue': 'sharedValue'},
            {
              'changedValue': [1, 4, 3]
            },
          ]
        }
      };
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(1));
      _checkPatch(result[0], 'replace', '/object/test/1/changedValue/1',
          value: 4);
    });

    test('.diff should handle different sized lists with no repetitions', () {
      final oldJson = [1, 2, 3];
      final newJson = [4, 5, 6, 7];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(4));
      _checkPatch(result[0], 'add', '/-', value: 7);
      _checkPatch(result[1], 'replace', '/2', value: 6);
      _checkPatch(result[2], 'replace', '/1', value: 5);
      _checkPatch(result[3], 'replace', '/0', value: 4);
    });

    test('.diff should handle emptyLists', () {
      final emptyList = [];
      final otherList = [1];
      final result = JsonPatch.diff(emptyList, emptyList);
      expect(result, isEmpty);

      final addResult = JsonPatch.diff(emptyList, otherList);
      expect(addResult, hasLength(1));
      _checkPatch(addResult[0], 'add', '/-', value: 1);

      final removeResult = JsonPatch.diff(otherList, emptyList);
      expect(removeResult, hasLength(1));
      _checkPatch(removeResult[0], 'remove', '/0');
    });

    test('.diff should be able to compare maps and lists', () {
      final oldJson = [
        1,
        {'value': 1},
        [1, 2, 3]
      ];
      final newJson = [
        {'value': 1},
        [1, 2, 3]
      ];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(1));
      _checkPatch(result[0], 'remove', '/0');
    });

    test('.diff should handle a shared prefix and suffix', () {
      final oldJson = [1, 2, 3, 4, 5];
      final newJson = [1, 2, 6, 4, 5];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(1));
      _checkPatch(result[0], 'replace', '/2', value: 6);
    });

    test('.diff should handle a removing from a list with a common suffix', () {
      final oldJson = [1, 2, 3, 4, 5];
      final newJson = [1, 2, 4, 5];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, hasLength(1));
      _checkPatch(result[0], 'remove', '/2');
    });

    test('.diff should handle a equal lists', () {
      final oldJson = [1, 2, 3, 4, 5];
      final newJson = [1, 2, 3, 4, 5];
      final result = JsonPatch.diff(oldJson, newJson);
      expect(result, isEmpty);
    });
  });

  group('.apply', () {
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

void _checkPatch(Map<String, dynamic> result, String op, String path,
    {dynamic value = null}) {
  expect(
      result,
      allOf(
        containsPair('op', op),
        containsPair('path', path),
        value != null ? containsPair('value', value) : isNot(contains('value')),
      ));
}
