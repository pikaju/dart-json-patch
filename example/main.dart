import 'package:json_patch/json_patch.dart';

void main() {
  final diff = JsonPatch.diff(
    {
      'test': 5,
      'object': {
        'list': [1, 2, 3],
        'child': 'value',
      }
    },
    {
      'test': 6,
      'object': {
        'list': [1, 2, 4],
        'child': 5,
      }
    },
  );
  print('Diff algorithm found changes: $diff');

  try {
    final newJson = JsonPatch.apply(
      {
        'a': 5,
      },
      [
        {'op': 'test', 'path': '/a', 'value': 5},
        {
          'op': 'add',
          'path': '/test',
          'value': {'child': 'value'}
        },
        {'op': 'move', 'from': '/test', 'to': '/moved'},
      ],
      strict: true,
    );
    print('Object after applying patch operations: $newJson');
  } on JsonPatchTestFailedException catch (e) {
    print(e);
  }
}
