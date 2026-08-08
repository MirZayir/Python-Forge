import 'execution_result.dart';

/// Abstract contract for Python code execution backends.
abstract class PythonRunner {
  Future<ExecutionResult> run(String code);
}

enum _LoopSignal { none, breakLoop, continueLoop }

class _ReturnSignal implements Exception {
  final dynamic value;
  _ReturnSignal(this.value);
}

class _FunctionDef {
  final List<String> params;
  final List<String> bodyLines;
  _FunctionDef(this.params, this.bodyLines);
}

/// Native Dart interpreter with support for functions (def/return), scope,
/// built-ins (len, type, range), lists, dictionaries, conditionals, and loops.
class LocalPythonInterpreter implements PythonRunner {
  @override
  Future<ExecutionResult> run(String code) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final StringBuffer stdout = StringBuffer();
    final Map<String, dynamic> environment = {};

    final rawLines = code.split('\n');

    try {
      _executeBlock(rawLines, 0, rawLines.length, environment, stdout);

      stopwatch.stop();
      return ExecutionResult(
        output: stdout.toString().trimRight(),
        success: true,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: false,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is _ReturnSignal) {
        return ExecutionResult(
          output: stdout.toString().trimRight(),
          success: true,
          executionTimeMs: stopwatch.elapsedMilliseconds,
          hasError: false,
        );
      }
      return ExecutionResult(
        output: e.toString(),
        success: false,
        executionTimeMs: stopwatch.elapsedMilliseconds,
        hasError: true,
      );
    }
  }

  _LoopSignal _executeBlock(
    List<String> rawLines,
    int startIndex,
    int endIndex,
    Map<String, dynamic> env,
    StringBuffer stdout,
  ) {
    int i = startIndex;
    while (i < endIndex) {
      final rawLine = rawLines[i];
      final line = _stripComment(rawLine).trimRight();

      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      final trimmed = line.trim();

      if (trimmed == 'break') {
        return _LoopSignal.breakLoop;
      }
      if (trimmed == 'continue') {
        return _LoopSignal.continueLoop;
      }

      // Return statement inside function execution
      if (trimmed.startsWith('return ') || trimmed == 'return') {
        final expr = trimmed.length > 6 ? trimmed.substring(6).trim() : 'None';
        final val = expr.isNotEmpty ? _evaluateExpression(expr, env) : null;
        throw _ReturnSignal(val);
      }

      // 1. Function Definition
      if (trimmed.startsWith('def ') && trimmed.endsWith(':')) {
        i = _handleFunctionDef(rawLines, i, env);
        continue;
      }

      // 2. FOR loop
      if (trimmed.startsWith('for ') && trimmed.endsWith(':')) {
        i = _handleForLoop(rawLines, i, env, stdout);
        continue;
      }

      // 3. WHILE loop
      if (trimmed.startsWith('while ') && trimmed.endsWith(':')) {
        i = _handleWhileLoop(rawLines, i, env, stdout);
        continue;
      }

      // 4. IF / ELIF / ELSE
      if (trimmed.startsWith('if ') && trimmed.endsWith(':')) {
        i = _handleIfStatement(rawLines, i, env, stdout);
        continue;
      }

      // 5. Single line statement
      _executeLine(trimmed, env, stdout);
      i++;
    }
    return _LoopSignal.none;
  }

  int _handleFunctionDef(
    List<String> rawLines,
    int headerIndex,
    Map<String, dynamic> env,
  ) {
    final header = _stripComment(rawLines[headerIndex]).trim();
    final match = RegExp(r'^def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*)\):$')
        .firstMatch(header);
    if (match == null) {
      throw FormatException(
          "SyntaxError: invalid function definition '$header'");
    }

    final funcName = match.group(1)!;
    final paramsStr = match.group(2)!.trim();
    final params = paramsStr.isEmpty
        ? <String>[]
        : paramsStr.split(',').map((p) => p.trim()).toList();

    final blockIndices = _findIndentedBlockIndices(rawLines, headerIndex + 1);
    final blockLines = rawLines.sublist(blockIndices[0], blockIndices[1]);

    env[funcName] = _FunctionDef(params, blockLines);
    return blockIndices[1];
  }

  int _handleForLoop(
    List<String> rawLines,
    int headerIndex,
    Map<String, dynamic> env,
    StringBuffer stdout,
  ) {
    final header = _stripComment(rawLines[headerIndex]).trim();
    final match = RegExp(r'^for\s+([a-zA-Z_][a-zA-Z0-9_]*)\s+in\s+(.+):$')
        .firstMatch(header);
    if (match == null) {
      throw FormatException("SyntaxError: invalid for loop syntax '$header'");
    }

    final iterVar = match.group(1)!;
    final iterExpr = match.group(2)!;

    final blockIndices = _findIndentedBlockIndices(rawLines, headerIndex + 1);
    final blockStart = blockIndices[0];
    final blockEnd = blockIndices[1];

    final iterable = _evaluateIterable(iterExpr, env);

    for (final item in iterable) {
      env[iterVar] = item;
      final signal = _executeBlock(rawLines, blockStart, blockEnd, env, stdout);
      if (signal == _LoopSignal.breakLoop) {
        break;
      }
    }

    return blockEnd;
  }

  int _handleWhileLoop(
    List<String> rawLines,
    int headerIndex,
    Map<String, dynamic> env,
    StringBuffer stdout,
  ) {
    final header = _stripComment(rawLines[headerIndex]).trim();
    final conditionStr = header.substring(6, header.length - 1).trim();

    final blockIndices = _findIndentedBlockIndices(rawLines, headerIndex + 1);
    final blockStart = blockIndices[0];
    final blockEnd = blockIndices[1];

    int maxSafetyIterations = 1000;
    int currentIteration = 0;

    while (_evaluateCondition(conditionStr, env)) {
      currentIteration++;
      if (currentIteration > maxSafetyIterations) {
        throw FormatException("TimeLimitExceeded: Infinite loop detected.");
      }

      final signal = _executeBlock(rawLines, blockStart, blockEnd, env, stdout);
      if (signal == _LoopSignal.breakLoop) {
        break;
      }
    }

    return blockEnd;
  }

  int _handleIfStatement(
    List<String> rawLines,
    int headerIndex,
    Map<String, dynamic> env,
    StringBuffer stdout,
  ) {
    int i = headerIndex;
    bool blockExecuted = false;

    while (i < rawLines.length) {
      final header = _stripComment(rawLines[i]).trim();
      if (header.isEmpty) {
        i++;
        continue;
      }

      if (header.startsWith('if ') && header.endsWith(':')) {
        final conditionStr = header.substring(3, header.length - 1).trim();
        final blockIndices = _findIndentedBlockIndices(rawLines, i + 1);

        if (_evaluateCondition(conditionStr, env)) {
          _executeBlock(
              rawLines, blockIndices[0], blockIndices[1], env, stdout);
          blockExecuted = true;
        }
        i = blockIndices[1];
      } else if (header.startsWith('elif ') && header.endsWith(':')) {
        final conditionStr = header.substring(5, header.length - 1).trim();
        final blockIndices = _findIndentedBlockIndices(rawLines, i + 1);

        if (!blockExecuted && _evaluateCondition(conditionStr, env)) {
          _executeBlock(
              rawLines, blockIndices[0], blockIndices[1], env, stdout);
          blockExecuted = true;
        }
        i = blockIndices[1];
      } else if (header.startsWith('else:') || header == 'else:') {
        final blockIndices = _findIndentedBlockIndices(rawLines, i + 1);

        if (!blockExecuted) {
          _executeBlock(
              rawLines, blockIndices[0], blockIndices[1], env, stdout);
          blockExecuted = true;
        }
        i = blockIndices[1];
      } else {
        break;
      }
    }

    return i;
  }

  List<int> _findIndentedBlockIndices(List<String> lines, int startIndex) {
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
    return [startIndex, curr];
  }

  void _executeLine(
      String line, Map<String, dynamic> env, StringBuffer stdout) {
    // 1. Print statements
    if (line.startsWith('print(') && line.endsWith(')')) {
      final content = line.substring(6, line.length - 1).trim();
      final evaluated = _evaluateExpression(content, env);
      stdout.writeln(evaluated);
    }
    // 2. Standalone Function Call (e.g., greet())
    else if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\s*\(.*\)$').hasMatch(line) &&
        !line.contains('=')) {
      _evaluateExpression(line, env);
    }
    // 3. Method invocation (e.g., fruits.append("banana"))
    else if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\(.*\)$')
        .hasMatch(line)) {
      final dotIndex = line.indexOf('.');
      final varName = line.substring(0, dotIndex).trim();
      final methodCall = line.substring(dotIndex + 1).trim();

      if (env.containsKey(varName)) {
        final target = env[varName];
        if (target is List) {
          if (methodCall.startsWith('append(') && methodCall.endsWith(')')) {
            final argStr =
                methodCall.substring(7, methodCall.length - 1).trim();
            final val = _evaluateExpression(argStr, env);
            target.add(val);
          } else if (methodCall.startsWith('pop(') &&
              methodCall.endsWith(')')) {
            if (target.isNotEmpty) {
              target.removeLast();
            }
          }
        }
      }
    }
    // 4. Compound assignment (+=)
    else if (line.contains('+=')) {
      final parts = line.split('+=');
      if (parts.length == 2) {
        final varName = parts[0].trim();
        final expr = parts[1].trim();
        final currentVal = env[varName] ?? 0;
        final addVal = _evaluateExpression(expr, env);
        env[varName] = (currentVal is num && addVal is num)
            ? (currentVal + addVal)
            : '$currentVal$addVal';
      }
    }
    // 5. Variable assignment (=)
    else if (line.contains('=')) {
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

  List<dynamic> _evaluateIterable(String expr, Map<String, dynamic> env) {
    expr = expr.trim();
    if (expr.startsWith('range(') && expr.endsWith(')')) {
      final inner = expr.substring(6, expr.length - 1);
      final parts =
          inner.split(',').map((e) => _evaluateExpression(e, env)).toList();

      if (parts.length == 1 && parts[0] is int) {
        return List.generate(parts[0] as int, (i) => i);
      } else if (parts.length == 2 && parts[0] is int && parts[1] is int) {
        final start = parts[0] as int;
        final end = parts[1] as int;
        return List.generate(end - start, (i) => start + i);
      }
    }

    final evaluated = _evaluateExpression(expr, env);
    if (evaluated is List) {
      return evaluated;
    }
    throw FormatException("TypeError: '$expr' is not iterable");
  }

  bool _evaluateCondition(String expr, Map<String, dynamic> env) {
    expr = expr.trim();

    if (expr.contains(' and ')) {
      final parts = expr.split(' and ');
      return _evaluateCondition(parts[0], env) &&
          _evaluateCondition(parts[1], env);
    }

    if (expr.contains(' or ')) {
      final parts = expr.split(' or ');
      return _evaluateCondition(parts[0], env) ||
          _evaluateCondition(parts[1], env);
    }

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

    // Built-in len()
    if (expr.startsWith('len(') && expr.endsWith(')')) {
      final inner = expr.substring(4, expr.length - 1).trim();
      final val = _evaluateExpression(inner, env);
      if (val is String) return val.length;
      if (val is List) return val.length;
      if (val is Map) return val.length;
      throw FormatException(
          "TypeError: object of type '${val.runtimeType}' has no len()");
    }

    // Built-in type()
    if (expr.startsWith('type(') && expr.endsWith(')')) {
      final inner = expr.substring(5, expr.length - 1).trim();
      final val = _evaluateExpression(inner, env);
      if (val is int) return "<class 'int'>";
      if (val is double || val is num) return "<class 'float'>";
      if (val is String) return "<class 'str'>";
      if (val is bool) return "<class 'bool'>";
      if (val is List) return "<class 'list'>";
      if (val is Map) return "<class 'dict'>";
      return "<class '${val.runtimeType}'>";
    }

    // Custom Function Execution
    final funcMatch =
        RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*)\)$').firstMatch(expr);
    if (funcMatch != null && !expr.startsWith('[')) {
      final funcName = funcMatch.group(1)!;
      final argsStr = funcMatch.group(2)!.trim();

      if (env.containsKey(funcName) && env[funcName] is _FunctionDef) {
        final fDef = env[funcName] as _FunctionDef;
        final args = argsStr.isEmpty
            ? <dynamic>[]
            : argsStr
                .split(',')
                .map((e) => _evaluateExpression(e.trim(), env))
                .toList();

        final Map<String, dynamic> localEnv = Map.from(env);
        for (int p = 0; p < fDef.params.length && p < args.length; p++) {
          localEnv[fDef.params[p]] = args[p];
        }

        final StringBuffer dummyStdout = StringBuffer();
        try {
          _executeBlock(
              fDef.bodyLines, 0, fDef.bodyLines.length, localEnv, dummyStdout);
        } catch (e) {
          if (e is _ReturnSignal) {
            return e.value;
          }
          rethrow;
        }
        return null;
      }
    }

    // Dictionary Literal {"key": "value"}
    if (expr.startsWith('{') && expr.endsWith('}')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return <String, dynamic>{};

      final Map<String, dynamic> map = {};
      final pairs = inner.split(',');
      for (var pair in pairs) {
        final kv = pair.split(':');
        if (kv.length == 2) {
          final key = _evaluateExpression(kv[0], env).toString();
          final val = _evaluateExpression(kv[1], env);
          map[key] = val;
        }
      }
      return map;
    }

    // List Literal [1, 2, 3]
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return [];
      return inner.split(',').map((e) => _evaluateExpression(e, env)).toList();
    }

    // Bracket Indexing var["key"] or var[0]
    final indexMatch =
        RegExp(r'^([a-zA-Z_][a-zA-Z0-9_]*)\s*\[(.*)\]$').firstMatch(expr);
    if (indexMatch != null) {
      final varName = indexMatch.group(1)!;
      final keyExpr = indexMatch.group(2)!;

      if (env.containsKey(varName)) {
        final collection = env[varName];
        final keyOrIndex = _evaluateExpression(keyExpr, env);

        if (collection is Map) {
          return collection[keyOrIndex.toString()];
        } else if (collection is List && keyOrIndex is int) {
          return collection[keyOrIndex];
        }
      }
    }

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

    // Addition / Concatenation
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
