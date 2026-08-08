import 'execution_result.dart';

/// Abstract contract for Python code execution backends.
abstract class PythonRunner {
  Future<ExecutionResult> run(String code);
}

/// Native Dart interpreter with support for print statements, variable assignment,
/// string/numeric evaluation, and simple conditional control flow (if / elif / else).
class LocalPythonInterpreter implements PythonRunner {
  @override
  Future<ExecutionResult> run(String code) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final StringBuffer stdout = StringBuffer();
    final Map<String, dynamic> environment = {};

    final rawLines = code.split('\n');

    try {
      int i = 0;
      while (i < rawLines.length) {
        final rawLine = rawLines[i];
        final line = _stripComment(rawLine).trimRight();

        if (line.trim().isEmpty) {
          i++;
          continue;
        }

        final trimmed = line.trim();

        // Check for 'if' statement
        if (trimmed.startsWith('if ') && trimmed.endsWith(':')) {
          final conditionStr = trimmed.substring(3, trimmed.length - 1).trim();
          final conditionResult = _evaluateCondition(conditionStr, environment);

          bool blockExecuted = false;

          if (conditionResult) {
            i = _executeIndentedBlock(rawLines, i + 1, environment, stdout);
            blockExecuted = true;
          } else {
            i = _skipIndentedBlock(rawLines, i + 1);
          }

          // Handle following elif / else blocks
          while (i < rawLines.length) {
            final nextRaw = rawLines[i];
            final nextTrimmed = _stripComment(nextRaw).trim();

            if (nextTrimmed.startsWith('elif ') && nextTrimmed.endsWith(':')) {
              final elifConditionStr =
                  nextTrimmed.substring(5, nextTrimmed.length - 1).trim();
              if (!blockExecuted &&
                  _evaluateCondition(elifConditionStr, environment)) {
                i = _executeIndentedBlock(rawLines, i + 1, environment, stdout);
                blockExecuted = true;
              } else {
                i = _skipIndentedBlock(rawLines, i + 1);
              }
            } else if (nextTrimmed.startsWith('else:') ||
                nextTrimmed == 'else:') {
              if (!blockExecuted) {
                i = _executeIndentedBlock(rawLines, i + 1, environment, stdout);
                blockExecuted = true;
              } else {
                i = _skipIndentedBlock(rawLines, i + 1);
              }
            } else {
              break;
            }
          }
          continue;
        }

        // Single-line statements (print, variable assignment)
        _executeLine(trimmed, environment, stdout);
        i++;
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

  void _executeLine(
      String line, Map<String, dynamic> env, StringBuffer stdout) {
    if (line.startsWith('print(') && line.endsWith(')')) {
      final content = line.substring(6, line.length - 1).trim();
      final evaluated = _evaluateExpression(content, env);
      stdout.writeln(evaluated);
    } else if (line.contains('=')) {
      final parts = line.split('=');
      if (parts.length == 2) {
        final varName = parts[0].trim();
        final expr = parts[1].trim();

        if (!_isValidIdentifier(varName)) {
          throw FormatException("SyntaxError: invalid syntax '$varName'");
        }

        final evaluated = _evaluateExpression(expr, env);
        env[varName] = evaluated;
      }
    }
  }

  int _executeIndentedBlock(
    List<String> lines,
    int startIndex,
    Map<String, dynamic> env,
    StringBuffer stdout,
  ) {
    int curr = startIndex;
    while (curr < lines.length) {
      final raw = lines[curr];
      final line = _stripComment(raw);
      if (line.trim().isEmpty) {
        curr++;
        continue;
      }
      // Check for indentation (leading space or tab)
      if (raw.startsWith(' ') || raw.startsWith('\t')) {
        _executeLine(line.trim(), env, stdout);
        curr++;
      } else {
        break;
      }
    }
    return curr;
  }

  int _skipIndentedBlock(List<String> lines, int startIndex) {
    int curr = startIndex;
    while (curr < lines.length) {
      final raw = lines[curr];
      final line = _stripComment(raw);
      if (line.trim().isEmpty) {
        curr++;
        continue;
      }
      if (raw.startsWith(' ') || raw.startsWith('\t')) {
        curr++;
      } else {
        break;
      }
    }
    return curr;
  }

  bool _evaluateCondition(String expr, Map<String, dynamic> env) {
    expr = expr.trim();

    // Check for logical AND
    if (expr.contains(' and ')) {
      final parts = expr.split(' and ');
      return _evaluateCondition(parts[0], env) &&
          _evaluateCondition(parts[1], env);
    }

    // Check for logical OR
    if (expr.contains(' or ')) {
      final parts = expr.split(' or ');
      return _evaluateCondition(parts[0], env) ||
          _evaluateCondition(parts[1], env);
    }

    // Operators: ==, !=, >=, <=, >, <
    final ops = ['==', '!=', '>=', '<=', '>', '<'];
    for (var op in ops) {
      if (expr.contains(op)) {
        final parts = expr.split(op);
        final left = _evaluateExpression(parts[0], env);
        final right = _evaluateExpression(parts[1], env);

        switch (op) {
          case '==':
            return left == right;
          case '!=':
            return left != right;
          case '>=':
            return (left as num) >= (right as num);
          case '<=':
            return (left as num) <= (right as num);
          case '>':
            return (left as num) > (right as num);
          case '<':
            return (left as num) < (right as num);
        }
      }
    }

    final val = _evaluateExpression(expr, env);
    if (val is bool) return val;
    return val != null && val != 0 && val != '';
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

    if (expr == 'True') return true;
    if (expr == 'False') return false;

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

    // Basic String/Numeric addition
    if (expr.contains('+')) {
      final terms = expr.split('+').map((e) => e.trim()).toList();
      dynamic result = _evaluateExpression(terms[0], env);
      for (int i = 1; i < terms.length; i++) {
        final val = _evaluateExpression(terms[i], env);
        if (result is String || val is String) {
          result = '$result$val';
        } else if (result is num && val is num) {
          result = result + val;
        }
      }
      return result;
    }

    throw FormatException("NameError: name '$expr' is not defined");
  }
}
