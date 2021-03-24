class JsonPatchError extends Error {
  final String message;

  JsonPatchError(this.message);

  @override
  String toString() => '$message';
}

class JsonPatchTestFailedException implements Exception {
  final Object message;

  const JsonPatchTestFailedException(this.message);

  @override
  String toString() => 'JSON Patch test operation failed: $message';
}
