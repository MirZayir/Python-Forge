import 'execution_result.dart';
import 'python_runner.dart';

/// Central execution coordinator routing code to active execution backends.
class ExecutionManager {
  final PythonRunner _runner;

  ExecutionManager({PythonRunner? runner})
      : _runner = runner ?? LocalPythonInterpreter();

  Future<ExecutionResult> execute(String code) async {
    if (code.trim().isEmpty) {
      return const ExecutionResult(
        output: 'Warning: No code provided to execute.',
        success: true,
        executionTimeMs: 0,
        hasError: false,
      );
    }
    return await _runner.run(code);
  }
}
