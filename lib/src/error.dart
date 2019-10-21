class JsonPatchError extends Error {
  JsonPatchError(this.message);

  final Object message;

  @override
  String toString() => '$message';
}

class JsonPatchTestFailedException implements Exception {
  const JsonPatchTestFailedException(this.message);

  final Object message;

  @override
  String toString() => 'JSON Patch test operation failed: $message';
}
