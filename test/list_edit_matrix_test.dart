import 'package:collection/collection.dart';
import 'package:json_patch/src/list_edit_matrix.dart';
import 'package:test/test.dart';

main() {
  group('ListEditMatrix', () {
    test('.buildEditMatrix should handle empty lists', () {
      final oldList = [];
      final newList = [];
      final result = ListEditMatrix.buildEditMatrix(
          oldList, newList, (v1, v2) => v1 == v2);
      expect(result, [
        [EditType.noop]
      ]);
    });

    test('.buildEditMatrix should handle equal lists', () {
      final oldList = [1, 2, 3];
      final newList = [1, 2, 3];
      final result = _buildEditMatrixForInts(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.noop, EditType.add],
        [EditType.remove, EditType.remove, EditType.remove, EditType.noop],
      ]);
    });

    test('.buildEditMatrix should handle adding to lists', () {
      final oldList = [1, 2];
      final newList = [1, 2, 3];
      final result = _buildEditMatrixForInts(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.noop, EditType.add],
      ]);
    });

    test('.buildEditMatrix should handle removing from lists', () {
      final oldList = [1, 2, 3, 4];
      final newList = [1, 2, 3];
      final result = _buildEditMatrixForInts(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.noop, EditType.add],
        [EditType.remove, EditType.remove, EditType.remove, EditType.noop],
        [EditType.remove, EditType.remove, EditType.remove, EditType.remove],
      ]);
    });

    test('.buildEditMatrix should handle replacing items in lists', () {
      final oldList = [1, 2, 3];
      final newList = [1, 4, 3];
      final result = _buildEditMatrixForInts(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.replace, EditType.add],
        [EditType.remove, EditType.remove, EditType.remove, EditType.noop],
      ]);
    });

    test('.buildEditMatrix should handle moved items in lists', () {
      final oldList = [1, 2, 3];
      final newList = [1, 4, 2];
      final result = _buildEditMatrixForInts(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.replace, EditType.noop],
        [EditType.remove, EditType.remove, EditType.remove, EditType.remove],
      ]);
    });

    test('.buildEditMatrix should handle objects with custom equals', () {
      final List<Map<dynamic, dynamic>> oldList = [
        {'value': 1}
      ];
      final List<Map<dynamic, dynamic>> newList = [
        {'value': 1}
      ];
      final result = ListEditMatrix.buildEditMatrix(
          oldList,
          newList,
          (Map<dynamic, dynamic> v1, Map<dynamic, dynamic> v2) =>
              MapEquality().equals(v1, v2));
      expect(result, [
        [EditType.noop, EditType.add],
        [EditType.remove, EditType.noop],
      ]);
    });
  });
}

List<List<EditType>> _buildEditMatrixForInts(
        List<int> oldList, List<int> newList) =>
    ListEditMatrix.buildEditMatrix(oldList, newList, _intEquals);

bool _intEquals(int i, int j) => i == j;
