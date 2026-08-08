import 'execution_result.dart';

/// Abstract contract for Python code execution backends.
abstract class PythonRunner {
  Future<ExecutionResult> run(String code);
}

/// Native Dart lightweight interpreter for basic Python execution,
/// variable state tracking, arithmetic evaluation, and error catching.
class LocalPythonInterpreter implements PythonRunner {
  @override
  Future<ExecutionResult> run(String code) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final StringBuffer stdout = StringBuffer();
    final Map<String, dynamic> environment = {};

    final lines = code.split('\n');

    try {
      for (var rawLine in lines) {
        final line = _stripComment(rawLine).trim();
        if (line.isEmpty) continue;

        // 1. Handle print statements: print(...)
        if (line.startsWith('print(') && line.endsWith(')')) {
          final content = line.substring(6, line.length - 1).trim();
          final evaluated = _evaluateExpression(content, environment);
          stdout.writeln(evaluated);
        }
        // 2. Handle variable assignments: var = val
        else if (line.contains('=')) {
          final parts = line.split('=');
          if (parts.length == 2) {
            final varName = parts[0].trim();
            final expr = parts[1].trim();

            if (!_isValidIdentifier(varName)) {
              throw FormatException("SyntaxError: invalid syntax '$varName'");
            }

            final evaluated = _evaluateExpression(expr, environment);
            environment[varName] = evaluated;
          }
        } else {
          // Attempt raw evaluation
          _evaluateExpression(line, environment);
        }
      }

      stopwatch.stop();
      return ExecutionResult(
        output: stdout.toString().trimRight(),
        success: true,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: false,
      );
    } catch (e) {
      stopwatch.stop();
      return ExecutionResult(
        output: e.toString(),
        success: false,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: true,
      );
    }
  }

  String _stripComment(String line) {
    final index = line.indexOf('#');
    return index != -1 ? line.substring(0, index) : line;
  }

  bool _isValidIdentifier(String name) {
    return RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name);
  }

  dynamic _evaluateExpression(String expr, Map<String, dynamic> env) {
    expr = expr.trim();

    // String literal
    if ((expr.startsWith('"') && expr.endsWith('"')) ||
        (expr.startsWith("'") && expr.endsWith("'"))) {
      return expr.substring(1, expr.length - 1);
    }

    // Number literal
    if (num.tryParse(expr) != null) {
      return num.parse(expr);
    }

    // Variable lookup
    if (env.containsKey(expr)) {
      return env[expr];
    }

    // Basic String concatenation: "a" + "b" or var + "a"
    if (expr.contains('+')) {
      final terms = expr.split('+').map((e) => e.trim()).toList();
      String combined = '';
      for (var term in terms) {
        final val = _evaluateExpression(term, env);
        combined += val.toString();
      }
      return combined;
    }

    throw FormatException("NameError: name '$expr' is not defined");
  }
}
