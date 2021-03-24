import 'dart:math';

import 'package:collection/collection.dart';

enum EditType { add, remove, replace, noop }

typedef EqualityPredicate<T> = bool Function(T, T);

/// Wagner–Fischer algorithm.
/// It creates a matrix of operations which need to be applied to the old list
/// to recreate the new one.
List<List<EditType>> wagnerFischer<T>(
  List<T> oldList,
  List<T> newList,
  EqualityPredicate<T> equal,
) {
  final oldLength = oldList.length;
  final newLength = newList.length;
  final distanceMatrix = List.generate(
    oldLength + 1,
    (index) => List.generate(newLength + 1, (index) => 0),
  );
  final diffMatrix = List.generate(
    oldLength + 1,
    (index) => List.generate(newLength + 1, (index) => EditType.noop),
  );

  for (int i = 1; i < oldLength + 1; i++) {
    distanceMatrix[i][0] = i;
    diffMatrix[i][0] = EditType.remove;
  }

  for (int i = 1; i < newList.length + 1; i++) {
    distanceMatrix[0][i] = i;
    diffMatrix[0][i] = EditType.add;
  }

  final oldHashList = oldList.map(DeepCollectionEquality().hash).toList();
  final newHashList = newList.map(DeepCollectionEquality().hash).toList();

  for (int i = 1; i < oldLength + 1; i++) {
    for (int j = 1; j < newLength + 1; j++) {
      final same = oldHashList[i - 1] == newHashList[j - 1] &&
          equal(oldList[i - 1], newList[j - 1]);
      final substitutionCost = same ? 0 : 1;

      final replaceValue = distanceMatrix[i - 1][j - 1] + substitutionCost;
      final addValue = distanceMatrix[i][j - 1] + 1;
      final removeValue = distanceMatrix[i - 1][j] + 1;
      final smallestValue = [
        removeValue,
        addValue,
        replaceValue,
      ].reduce(min);

      distanceMatrix[i][j] = smallestValue;
      if (smallestValue == removeValue) {
        diffMatrix[i][j] = EditType.remove;
      } else if (smallestValue == addValue) {
        diffMatrix[i][j] = EditType.add;
      } else {
        diffMatrix[i][j] = same ? EditType.noop : EditType.replace;
      }
    }
  }

  return diffMatrix;
}

List<List<EditType>> wagnerFischerComp<T extends Comparable>(
  List<T> oldList,
  List<T> newList,
) =>
    wagnerFischer<T>(oldList, newList, (a, b) => a.compareTo(b) == 0);
