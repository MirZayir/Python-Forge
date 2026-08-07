import 'execution_result.dart';

/// Simulates Python code execution for the learning experience.
class ExecutionManager {
  Future<ExecutionResult> execute(String sourceCode) async {
    final stopwatch = Stopwatch()..start();

    await Future.delayed(const Duration(milliseconds: 300));

    final variables = <String, String>{};
    final output = <String>[];

    final lines = sourceCode
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    for (final line in lines) {
      // Ignore comments
      if (line.startsWith('#')) {
        continue;
      }

      // Variable assignment
      final assignment = RegExp(
        r"""^([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*['"](.*)['"]$""",
      ).firstMatch(line);

      if (assignment != null) {
        variables[assignment.group(1)!] = assignment.group(2)!;
        continue;
      }

      // print("text")
      final printLiteral = RegExp(
        r"""^print\s*\(\s*['"](.*)['"]\s*\)$""",
      ).firstMatch(line);

      if (printLiteral != null) {
        output.add(printLiteral.group(1)!);
        continue;
      }

      // print(variable)
      final printVariable = RegExp(
        r'^print\s*\(\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\)$',
      ).firstMatch(line);

      if (printVariable != null) {
        final variableName = printVariable.group(1)!;

        if (variables.containsKey(variableName)) {
          output.add(variables[variableName]!);
        } else {
          output.add("NameError: '$variableName' is not defined");
        }

        continue;
      }
    }

    stopwatch.stop();

    return ExecutionResult(
      success: true,
      output: output.isEmpty ? 'Program finished.' : output.join('\n'),
      executionTime: stopwatch.elapsed,
    );
  }
}
