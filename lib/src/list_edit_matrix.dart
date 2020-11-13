import 'dart:math';

import 'package:collection/collection.dart';

/// Utility class for diffing lists using the Wagner–Fischer algorithm.
/// It creates a matrix of operations which need to be applied to the old list
/// to recreate the new one.
enum EditType { add, remove, replace, noop }

class ListEditMatrix {
  static List<List<EditType>> buildEditMatrix<T>(
      List<T> oldList, List<T> newList, bool Function(T, T) equal) {
    final oldLength = oldList.length;
    final newLength = newList.length;
    final distanceMatrix = List.generate(
        oldLength + 1, (index) => List.generate(newLength + 1, (index) => 0));
    final diffMatrix = List.generate(oldLength + 1,
        (index) => List.generate(newLength + 1, (index) => EditType.noop));

    for (var i = 1; i < oldLength + 1; i++) {
      distanceMatrix[i][0] = i;
      diffMatrix[i][0] = EditType.remove;
    }

    for (var i = 1; i < newList.length + 1; i++) {
      distanceMatrix[0][i] = i;
      diffMatrix[0][i] = EditType.add;
    }

    final oldHashList = oldList.map(DeepCollectionEquality().hash).toList();
    final newHashList = newList.map(DeepCollectionEquality().hash).toList();

    for (var i = 1; i < oldLength + 1; i++) {
      for (var j = 1; j < newLength + 1; j++) {
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
}
