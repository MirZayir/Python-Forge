import 'execution_result.dart';
import 'python_runner.dart';

/// Central execution coordinator routing code to the active backend.
class ExecutionManager {
  final PythonRunner _runner;

  ExecutionManager({PythonRunner? runner})
      : _runner = runner ?? LocalPythonInterpreter();

  Future<ExecutionResult> execute(String code) {
    if (code.trim().isEmpty) {
      return Future.value(const ExecutionResult(
        output: 'No code provided to execute.',
        success: false,
        executionTimeMs: 0,
        hasError: true,
      ));
    }
    return _runner.run(code);
  }
}
