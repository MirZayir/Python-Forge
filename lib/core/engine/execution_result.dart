/// Data model representing the output and status of a Python execution run.
class ExecutionResult {
  final String output;
  final bool success;
  final int executionTimeMs;
  final bool hasError;
  final String? errorType;
  final bool truncated;

  const ExecutionResult({
    required this.output,
    required this.success,
    this.executionTimeMs = 0,
    this.hasError = false,
    this.errorType,
    this.truncated = false,
  });
}
