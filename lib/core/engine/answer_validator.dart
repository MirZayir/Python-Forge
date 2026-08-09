import '../../features/curriculum/domain/models/mission.dart';

/// Represents the result status of a mission validation.
enum ValidationStatus {
  correct,
  incorrect,
  methodWarning,
}

/// Contains the status and user feedback message for an answer submission.
class ValidationResult {
  final ValidationStatus status;
  final String message;

  const ValidationResult({
    required this.status,
    required this.message,
  });
}

/// Validates the explicit curriculum contract after execution has succeeded.
class AnswerValidator {
  static ValidationResult validate({
    required String fullCode,
    required String actualOutput,
    required Mission mission,
    bool isError = false,
  }) {
    // Execution status is authoritative. A failed engine cannot complete a
    // mission, even if the submitted source happens to match an answer.
    if (isError) {
      return const ValidationResult(
        status: ValidationStatus.incorrect,
        message:
            '❌ Execution failed. Fix the error and try again; this attempt was not completed.',
      );
    }

    switch (mission.type) {
      case MissionType.mcq:
        return _validateChoice(fullCode, mission);
      case MissionType.fillInBlank:
        return _validateFillInBlank(fullCode, mission);
      case MissionType.code:
        return _validateCode(fullCode, actualOutput, mission);
    }
  }

  static ValidationResult _validateCode(
    String submittedCode,
    String actualOutput,
    Mission mission,
  ) {
    final expectedOutput = _normalizeOutput(mission.expectedOutput);
    if (expectedOutput.isNotEmpty &&
        _normalizeOutput(actualOutput) != expectedOutput) {
      return ValidationResult(
        status: ValidationStatus.incorrect,
        message:
            '❌ Output does not match the expected result.\nExpected: "${mission.expectedOutput.trim()}"\nGot: "${actualOutput.trim()}"',
      );
    }

    final answers = mission.validAnswers;
    if (answers.isEmpty) {
      return const ValidationResult(
        status: ValidationStatus.incorrect,
        message: '❌ This mission has no valid answer contract yet.',
      );
    }

    // The current asset explicitly declares exact source contracts. Preserve
    // their alternatives while normalizing only formatting and safe comments.
    final normalizedSubmission = _normalizeCode(submittedCode);
    final sourceMatches = answers.any(
      (answer) => _normalizeCode(answer) == normalizedSubmission,
    );

    if (!sourceMatches) {
      return const ValidationResult(
        status: ValidationStatus.incorrect,
        message:
            '❌ Not quite. Check the requested Python structure and try again.',
      );
    }

    return const ValidationResult(
      status: ValidationStatus.correct,
      message: '✅ Perfect! Your code executed cleanly and matches the mission.',
    );
  }

  static ValidationResult _validateChoice(
    String selection,
    Mission mission,
  ) {
    final normalizedSelection = _normalizeAnswer(selection);
    if (normalizedSelection.isEmpty) {
      return const ValidationResult(
        status: ValidationStatus.incorrect,
        message: '❌ Please select an option before submitting.',
      );
    }

    final isCorrect = mission.validAnswers
        .map(_normalizeAnswer)
        .contains(normalizedSelection);
    return isCorrect
        ? const ValidationResult(
            status: ValidationStatus.correct,
            message: '✅ Correct answer!',
          )
        : const ValidationResult(
            status: ValidationStatus.incorrect,
            message: '❌ Incorrect option selected. Try again!',
          );
  }

  static ValidationResult _validateFillInBlank(
    String input,
    Mission mission,
  ) {
    final normalizedInput = _normalizeAnswer(input);
    if (normalizedInput.isEmpty) {
      return const ValidationResult(
        status: ValidationStatus.incorrect,
        message: '❌ Please type an answer before submitting.',
      );
    }

    final isCorrect =
        mission.validAnswers.map(_normalizeAnswer).contains(normalizedInput);
    return isCorrect
        ? const ValidationResult(
            status: ValidationStatus.correct,
            message: '✅ Spot on!',
          )
        : const ValidationResult(
            status: ValidationStatus.incorrect,
            message: '❌ Incorrect value. Double-check your syntax!',
          );
  }

  static String _normalizeAnswer(String value) => value.trim().toLowerCase();

  static String _normalizeOutput(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trimRight())
        .join('\n')
        .trim();
  }

  static String _normalizeCode(String input) {
    final lines = input
        .split('\n')
        .map(_stripCommentOutsideString)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' '));
    return lines.join('\n').trim();
  }

  static String _stripCommentOutsideString(String line) {
    var quote = '';
    var escaped = false;

    for (var index = 0; index < line.length; index++) {
      final character = line[index];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (character == '\\' && quote.isNotEmpty) {
        escaped = true;
        continue;
      }
      if ((character == '"' || character == "'") && quote.isEmpty) {
        quote = character;
        continue;
      }
      if (character == quote) {
        quote = '';
        continue;
      }
      if (character == '#' && quote.isEmpty) {
        return line.substring(0, index);
      }
    }
    return line;
  }
}
