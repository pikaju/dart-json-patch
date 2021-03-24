import 'package:collection/collection.dart';
import 'package:json_patch/src/list_edit_matrix.dart';
import 'package:test/test.dart';

main() {
  group('ListEditMatrix', () {
    test('.buildEditMatrix should handle empty lists', () {
      final oldList = <int>[];
      final newList = <int>[];
      final result = wagnerFischerComp(oldList, newList);
      expect(result, [
        [EditType.noop]
      ]);
    });

    test('.buildEditMatrix should handle equal lists', () {
      final oldList = [1, 2, 3];
      final newList = [1, 2, 3];
      final result = wagnerFischerComp(oldList, newList);
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
      final result = wagnerFischerComp(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.noop, EditType.add],
      ]);
    });

    test('.buildEditMatrix should handle removing from lists', () {
      final oldList = [1, 2, 3, 4];
      final newList = [1, 2, 3];
      final result = wagnerFischerComp(oldList, newList);
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
      final result = wagnerFischerComp(oldList, newList);
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
      final result = wagnerFischerComp(oldList, newList);
      expect(result, [
        [EditType.noop, EditType.add, EditType.add, EditType.add],
        [EditType.remove, EditType.noop, EditType.add, EditType.add],
        [EditType.remove, EditType.remove, EditType.replace, EditType.noop],
        [EditType.remove, EditType.remove, EditType.remove, EditType.remove],
      ]);
    });

    test('.buildEditMatrix should handle objects with custom equals', () {
      final oldList = [
        {'value': 1}
      ];
      final newList = [
        {'value': 1}
      ];
      final result = wagnerFischer(oldList, newList, MapEquality().equals);
      expect(result, [
        [EditType.noop, EditType.add],
        [EditType.remove, EditType.noop],
      ]);
    });
  });
}
