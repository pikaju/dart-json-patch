# JSON Patch for Dart

A simple utility package for [JSON Patch](https://tools.ietf.org/html/rfc6902). Includes a simple diff algorithm as well as
the ability to apply JSON Patch operations to a JSON-like Dart object.

## Usage

```dart
import 'package:json_patch/json_patch.dart';

...

final ops = JsonPatch.diff(oldJson, newJson);
try {
    final patchedJson = JsonPatch.apply(json, patches, strict: false);
} on JsonPatchTestFailedException catch (e) {
    print(e);
}
```

See the example or the API docs for more information.