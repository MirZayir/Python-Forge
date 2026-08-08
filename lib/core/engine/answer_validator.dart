import '../../features/curriculum/domain/models/mission.dart';

enum ValidationStatus {
  correct, // Code method & output are correct
  methodWarning, // Output matches expected output, but method/syntax is wrong
  incorrect, // Output and method are both incorrect
}

class ValidationResult {
  final ValidationStatus status;
  final String message;

  const ValidationResult({
    required this.status,
    required this.message,
  });
}

class AnswerValidator {
  static ValidationResult validate({
    required String fullCode,
    required String actualOutput,
    required Mission mission,
  }) {
    // 1. Strip starter code prefix to evaluate user's typed code independently
    String userCode = fullCode;
    if (mission.starterCode.isNotEmpty &&
        userCode.startsWith(mission.starterCode)) {
      userCode = userCode.substring(mission.starterCode.length).trim();
    }

    final normalizedUserCode = _normalizeCode(userCode);
    final normalizedFullCode = _normalizeCode(fullCode);

    // 2. Check if user code or full code strictly matches valid syntax rules
    bool syntaxMatches = false;
    for (final rawAnswer in mission.validationRules.validAnswers) {
      final normalizedAnswer = _normalizeCode(rawAnswer);
      if (normalizedUserCode == normalizedAnswer ||
          normalizedFullCode == normalizedAnswer) {
        syntaxMatches = true;
        break;
      }
    }

    if (syntaxMatches) {
      return const ValidationResult(
        status: ValidationStatus.correct,
        message: '✅ Mission Complete!',
      );
    }

    // 3. Check if output matches expected target output despite syntax mismatch
    final expectedOutputs = _extractExpectedOutputs(mission);
    final cleanActualOutput = actualOutput.trim();

    bool outputMatches = false;
    for (final expected in expectedOutputs) {
      if (cleanActualOutput == expected.trim() && expected.trim().isNotEmpty) {
        outputMatches = true;
        break;
      }
    }

    if (outputMatches) {
      return const ValidationResult(
        status: ValidationStatus.methodWarning,
        message:
            '⚠️ Output is correct, but your code method or syntax is wrong!\nCheck the objective instructions.',
      );
    }

    return const ValidationResult(
      status: ValidationStatus.incorrect,
      message: '❌ Not quite.\nTry again.',
    );
  }

  static List<String> _extractExpectedOutputs(Mission mission) {
    final List<String> outputs = [];
    for (final answer in mission.validationRules.validAnswers) {
      // Basic heuristic to infer expected print output from validAnswers
      final matches = RegExp(r'print\((.*?)\)').allMatches(answer);
      final buffer = StringBuffer();
      for (final m in matches) {
        var val = m.group(1)?.trim() ?? '';
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          val = val.substring(1, val.length - 1);
        }
        buffer.writeln(val);
      }
      if (buffer.isNotEmpty) {
        outputs.add(buffer.toString().trim());
      }
    }
    return outputs;
  }

  static String _normalizeCode(String input) {
    final lines = input.split('\n');

    final cleanLines = lines
        .map((line) {
          final commentIndex = line.indexOf('#');
          if (commentIndex != -1) {
            return line.substring(0, commentIndex);
          }
          return line;
        })
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    var code = cleanLines.join(' ');
    code = code.replaceAll("'", '"');
    code = code.replaceAll(RegExp(r'\s*=\s*'), '=');
    code = code.replaceAll(RegExp(r'\s*\(\s*'), '(');
    code = code.replaceAll(RegExp(r'\s*\)\s*'), ')');
    code = code.replaceAll(RegExp(r'\s+'), ' ').trim();

    return code;
  }
}
