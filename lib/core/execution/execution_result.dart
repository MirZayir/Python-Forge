/// Represents the result of a code execution attempt.
class ExecutionResult {
  final bool success;
  final String output;
  final String? error;
  final Duration executionTime;

  const ExecutionResult({
    required this.success,
    required this.output,
    this.error,
    required this.executionTime,
  });
}
