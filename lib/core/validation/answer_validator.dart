import '../../features/poc/domain/models/mission.dart';

/// Engine responsible for validating user code submissions.
class AnswerValidator {
  /// Validates the [input] source code against the [ValidationRules] of the given [mission].
  static bool validate(String input, Mission mission) {
    final rules = mission.validationRules;

    // For V1, we treat 'exact_match' (and currently unsupported types as fallbacks)
    // by comparing strings against the validAnswers array.
    final cleanInput = rules.ignoreWhitespace ? input.trim() : input;

    return rules.validAnswers.any((answer) {
      final cleanAnswer = rules.ignoreWhitespace ? answer.trim() : answer;
      return cleanAnswer == cleanInput;
    });
  }
}
