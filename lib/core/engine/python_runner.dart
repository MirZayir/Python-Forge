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

class _PythonException implements Exception {
  final String type;
  final String message;
  _PythonException(this.type, this.message);

  @override
  String toString() => '$type: $message';
}

class _FunctionDef {
  final List<String> params;
  final List<String> bodyLines;
  _FunctionDef(this.params, this.bodyLines);
}

class _ClassDef {
  final String name;
  final Map<String, _FunctionDef> methods = {};
  _ClassDef(this.name);
}

class _Instance {
  final _ClassDef classDef;
  final Map<String, dynamic> fields = {};
  _Instance(this.classDef);
}

/// Native Dart interpreter supporting try-except blocks, OOP, Functions, Scope,
/// Built-ins (len, type, range, int, str), Lists, Dictionaries, Conditionals, and Loops.
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

      if (trimmed.startsWith('return ') || trimmed == 'return') {
        final expr = trimmed.length > 6 ? trimmed.substring(6).trim() : 'None';
        final val = expr.isNotEmpty ? _evaluateExpression(expr, env) : null;
        throw _ReturnSignal(val);
      }

      // 1. Try / Except Blocks
      if (trimmed == 'try:' || trimmed.startsWith('try:')) {
        i = _handleTryExcept(rawLines, i, env, stdout);
        continue;
      }

      // 2. Class Definition
      if (trimmed.startsWith('class ') && trimmed.endsWith(':')) {
        i = _handleClassDef(rawLines, i, env);
        continue;
      }

      // 3. Function Definition
      if (trimmed.startsWith('def ') && trimmed.endsWith(':')) {
        i = _handleFunctionDef(rawLines, i, env);
        continue;
      }

      // 4. FOR loop
      if (trimmed.startsWith('for ') && trimmed.endsWith(':')) {
        i = _handleForLoop(rawLines, i, env, stdout);
        continue;
      }

      // 5. WHILE loop
      if (trimmed.startsWith('while ') && trimmed.endsWith(':')) {
        i = _handleWhileLoop(rawLines, i, env, stdout);
        continue;
      }

      // 6. IF / ELIF / ELSE
      if (trimmed.startsWith('if ') && trimmed.endsWith(':')) {
        i = _handleIfStatement(rawLines, i, env, stdout);
        continue;
      }

      // 7. Single line statement
      _executeLine(trimmed, env, stdout);
      i++;
    }
    return _LoopSignal.none;
  }

  int _handleTryExcept(
    List<String> rawLines,
    int tryHeaderIndex,
    Map<String, dynamic> env,
    StringBuffer stdout,
  ) {
    final tryBlockIndices =
        _findIndentedBlockIndices(rawLines, tryHeaderIndex + 1);
    int curr = tryBlockIndices[1];

    final List<Map<String, dynamic>> exceptBlocks = [];

    while (curr < rawLines.length) {
      final line = _stripComment(rawLines[curr]).trim();
      if (line.isEmpty) {
        curr++;
        continue;
      }

      if (line.startsWith('except') && line.endsWith(':')) {
        String excType = 'Exception';
        String? varName;

        final headerContent = line.substring(6, line.length - 1).trim();
        if (headerContent.isNotEmpty) {
          if (headerContent.contains(' as ')) {
            final parts = headerContent.split(' as ');
            excType = parts[0].trim();
            varName = parts[1].trim();
          } else {
            excType = headerContent;
          }
        }

        final excBlockIndices = _findIndentedBlockIndices(rawLines, curr + 1);
        exceptBlocks.add({
          'type': excType,
          'varName': varName,
          'start': excBlockIndices[0],
          'end': excBlockIndices[1],
        });
        curr = excBlockIndices[1];
      } else {
        break;
      }
    }

    try {
      _executeBlock(
          rawLines, tryBlockIndices[0], tryBlockIndices[1], env, stdout);
    } catch (e) {
      if (e is _ReturnSignal) rethrow;

      _PythonException? exc;
      if (e is _PythonException) {
        exc = e;
      } else if (e is FormatException) {
        exc = _PythonException('ValueError', e.message);
      } else {
        exc = _PythonException('Exception', e.toString());
      }

      bool handled = false;
      for (final block in exceptBlocks) {
        final targetType = block['type'] as String;
        if (targetType == 'Exception' || targetType == exc.type) {
          final varName = block['varName'] as String?;
          if (varName != null) {
            env[varName] = exc.message;
          }
          _executeBlock(rawLines, block['start'] as int, block['end'] as int,
              env, stdout);
          handled = true;
          break;
        }
      }

      if (!handled) rethrow;
    }

    return curr;
  }

  int _handleClassDef(
    List<String> rawLines,
    int headerIndex,
    Map<String, dynamic> env,
  ) {
    final header = _stripComment(rawLines[headerIndex]).trim();
    final className = header.substring(6, header.length - 1).trim();

    final blockIndices = _findIndentedBlockIndices(rawLines, headerIndex + 1);
    final classDef = _ClassDef(className);

    int curr = blockIndices[0];
    while (curr < blockIndices[1]) {
      final raw = rawLines[curr];
      final line = _stripComment(raw).trim();
      if (line.startsWith('def ') && line.endsWith(':')) {
        final match = RegExp(r'^def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\((.*)\):$')
            .firstMatch(line);
        if (match != null) {
          final mName = match.group(1)!;
          final paramsStr = match.group(2)!.trim();
          final params = paramsStr.isEmpty
              ? <String>[]
              : paramsStr.split(',').map((p) => p.trim()).toList();

          final methodBlockIndices =
              _findIndentedBlockIndices(rawLines, curr + 1);
          final methodLines =
              rawLines.sublist(methodBlockIndices[0], methodBlockIndices[1]);
          classDef.methods[mName] = _FunctionDef(params, methodLines);
          curr = methodBlockIndices[1];
          continue;
        }
      }
      curr++;
    }

    env[className] = classDef;
    return blockIndices[1];
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
      throw _PythonException(
          "SyntaxError", "invalid function definition '$header'");
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
      throw _PythonException(
          "SyntaxError", "invalid for loop syntax '$header'");
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
        throw _PythonException("TimeLimitExceeded", "Infinite loop detected.");
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
    if (line.startsWith('print(') && line.endsWith(')')) {
      final content = line.substring(6, line.length - 1).trim();
      final evaluated = _evaluateExpression(content, env);
      stdout.writeln(evaluated);
    } else if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*\s*=')
        .hasMatch(line)) {
      final parts = line.split('=');
      final target = parts[0].trim();
      final expr = parts[1].trim();
      final dotIdx = target.indexOf('.');
      final objName = target.substring(0, dotIdx).trim();
      final attrName = target.substring(dotIdx + 1).trim();

      if (env.containsKey(objName) && env[objName] is _Instance) {
        final inst = env[objName] as _Instance;
        inst.fields[attrName] = _evaluateExpression(expr, env);
      }
    } else if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_.]*\s*\(.*\)$').hasMatch(line) &&
        !line.contains('=')) {
      _evaluateExpression(line, env);
    } else if (line.contains('+=')) {
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
    } else if (line.contains('=')) {
      final parts = line.split('=');
      if (parts.length == 2) {
        final varName = parts[0].trim();
        final expr = parts[1].trim();

        if (!_isValidIdentifier(varName)) {
          throw _PythonException("SyntaxError", "invalid syntax '$varName'");
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
    throw _PythonException("TypeError", "'$expr' is not iterable");
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

    // Division / ZeroDivisionError check
    if (expr.contains('/') && !expr.startsWith('"') && !expr.startsWith("'")) {
      final parts = expr.split('/');
      if (parts.length == 2) {
        final left = _evaluateExpression(parts[0], env);
        final right = _evaluateExpression(parts[1], env);

        if (left is num && right is num) {
          if (right == 0) {
            throw _PythonException('ZeroDivisionError', 'division by zero');
          }
          return left / right;
        }
      }
    }

    // Built-in int()
    if (expr.startsWith('int(') && expr.endsWith(')')) {
      final inner = expr.substring(4, expr.length - 1).trim();
      final val = _evaluateExpression(inner, env);
      final parsed = int.tryParse(val.toString());
      if (parsed == null) {
        throw _PythonException(
            'ValueError', "invalid literal for int(): '$val'");
      }
      return parsed;
    }

    // Built-in str()
    if (expr.startsWith('str(') && expr.endsWith(')')) {
      final inner = expr.substring(4, expr.length - 1).trim();
      return _evaluateExpression(inner, env).toString();
    }

    // Built-in len()
    if (expr.startsWith('len(') && expr.endsWith(')')) {
      final inner = expr.substring(4, expr.length - 1).trim();
      final val = _evaluateExpression(inner, env);
      if (val is String) return val.length;
      if (val is List) return val.length;
      if (val is Map) return val.length;
      throw _PythonException(
          'TypeError', "object of type '${val.runtimeType}' has no len()");
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
      if (val is _Instance) return "<class '${val.classDef.name}'>";
      return "<class '${val.runtimeType}'>";
    }

    // Dot-notation field access (e.g. p.name)
    if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z_][a-zA-Z0-9_]*$')
        .hasMatch(expr)) {
      final dotIdx = expr.indexOf('.');
      final objName = expr.substring(0, dotIdx).trim();
      final attrName = expr.substring(dotIdx + 1).trim();

      if (env.containsKey(objName) && env[objName] is _Instance) {
        final inst = env[objName] as _Instance;
        if (inst.fields.containsKey(attrName)) {
          return inst.fields[attrName];
        }
      }
    }

    // Method Call / Class Instantiation / Function Call
    final funcMatch =
        RegExp(r'^([a-zA-Z_][a-zA-Z0-9_.]*)\s*\((.*)\)$').firstMatch(expr);
    if (funcMatch != null && !expr.startsWith('[')) {
      final target = funcMatch.group(1)!;
      final argsStr = funcMatch.group(2)!.trim();

      if (target.contains('.')) {
        final dotIdx = target.indexOf('.');
        final objName = target.substring(0, dotIdx).trim();
        final mName = target.substring(dotIdx + 1).trim();

        if (env.containsKey(objName) && env[objName] is _Instance) {
          final inst = env[objName] as _Instance;
          if (inst.classDef.methods.containsKey(mName)) {
            final mDef = inst.classDef.methods[mName]!;
            final args = argsStr.isEmpty
                ? <dynamic>[]
                : argsStr
                    .split(',')
                    .map((e) => _evaluateExpression(e.trim(), env))
                    .toList();

            final Map<String, dynamic> localEnv = Map.from(env);
            if (mDef.params.isNotEmpty && mDef.params.first == 'self') {
              localEnv['self'] = inst;
              for (int p = 1;
                  p < mDef.params.length && (p - 1) < args.length;
                  p++) {
                localEnv[mDef.params[p]] = args[p - 1];
              }
            }

            final StringBuffer dummyStdout = StringBuffer();
            try {
              _executeBlock(mDef.bodyLines, 0, mDef.bodyLines.length, localEnv,
                  dummyStdout);
            } catch (e) {
              if (e is _ReturnSignal) return e.value;
              rethrow;
            }
            return null;
          }
        }
      }

      if (env.containsKey(target) && env[target] is _ClassDef) {
        return _Instance(env[target] as _ClassDef);
      }

      if (env.containsKey(target) && env[target] is _FunctionDef) {
        final fDef = env[target] as _FunctionDef;
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
          if (e is _ReturnSignal) return e.value;
          rethrow;
        }
        return null;
      }
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
          final keyStr = keyOrIndex.toString();
          if (!collection.containsKey(keyStr)) {
            throw _PythonException('KeyError', "'$keyStr'");
          }
          return collection[keyStr];
        } else if (collection is List && keyOrIndex is int) {
          if (keyOrIndex < 0 || keyOrIndex >= collection.length) {
            throw _PythonException('IndexError', 'list index out of range');
          }
          return collection[keyOrIndex];
        }
      }
    }

    // Dictionary Literal
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

    // List Literal
    if (expr.startsWith('[') && expr.endsWith(']')) {
      final inner = expr.substring(1, expr.length - 1).trim();
      if (inner.isEmpty) return [];
      return inner.split(',').map((e) => _evaluateExpression(e, env)).toList();
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

    throw _PythonException("NameError", "name '$expr' is not defined");
  }
}
