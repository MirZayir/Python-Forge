import '../../features/poc/domain/models/mission.dart';

/// Validates user submitted Python code against mission rules with robust normalization.
class AnswerValidator {
  /// Validates [userCode] against the given [mission] requirements.
  static bool validate(String userCode, Mission mission) {
    final rules = mission.validationRules;
    final type = rules.type;

    if (type == 'exact_match') {
      final validAnswers = rules.validAnswers;
      final normalizedUserCode = _normalizeCode(userCode);

      for (final rawAnswer in validAnswers) {
        if (_normalizeCode(rawAnswer) == normalizedUserCode) {
          return true;
        }
      }
    }

    return false;
  }

  /// Strips comments, normalizes quotes, removes excess whitespace around operators,
  /// and standardizes line structure for reliable Python code comparison.
  static String _normalizeCode(String input) {
    final lines = input.split('\n');

    // 1. Strip comments (# comment) and filter empty lines
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

    // 2. Standardize quote style (convert single quotes to double quotes)
    code = code.replaceAll("'", '"');

    // 3. Normalize spacing around assignment operator '='
    code = code.replaceAll(RegExp(r'\s*=\s*'), '=');

    // 4. Normalize spacing around function parentheses '(', ')'
    code = code.replaceAll(RegExp(r'\s*\(\s*'), '(');
    code = code.replaceAll(RegExp(r'\s*\)\s*'), ')');

    // 5. Collapse multi-space gaps into single spaces
    code = code.replaceAll(RegExp(r'\s+'), ' ').trim();

    return code;
  }
}
