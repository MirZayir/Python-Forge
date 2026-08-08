import '../../features/curriculum/domain/models/mission.dart';

class AnswerValidator {
  static bool validate(String userCode, Mission mission) {
    if (mission.type == MissionType.mcq) {
      final selectedAnswer = userCode.trim();
      return mission.validationRules.validAnswers.contains(selectedAnswer);
    }

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
