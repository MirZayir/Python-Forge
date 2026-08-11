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
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map(_stripCommentOutsideString)
        .map(_normalizeCodeLine)
        .where((line) => line.isNotEmpty);
    return lines.join('\n').trim();
  }

  /// Canonicalizes Python tokens while preserving string literal contents.
  ///
  /// This makes formatting-only variants such as `age=18` and `age = 18`
  /// compare equally without collapsing meaningful text inside strings or
  /// confusing `=` with operators such as `==` and `+=`.
  static String _normalizeCodeLine(String line) {
    final tokens = <String>[];
    var index = 0;

    while (index < line.length) {
      final character = line[index];
      if (character.trim().isEmpty) {
        index++;
        continue;
      }

      if (character == '"' || character == "'") {
        final start = index;
        final delimiter = line.startsWith('"""', index)
            ? '"""'
            : line.startsWith("'''", index)
                ? "'''"
                : character;
        var escaped = false;
        index += delimiter.length;

        while (index < line.length) {
          if (escaped) {
            escaped = false;
            index++;
            continue;
          }
          if (line[index] == '\\') {
            escaped = true;
            index++;
            continue;
          }
          if (line.startsWith(delimiter, index)) {
            index += delimiter.length;
            break;
          }
          index++;
        }

        tokens.add(line.substring(start, index));
        continue;
      }

      if (_isIdentifierStart(character)) {
        final start = index;
        index++;
        while (index < line.length && _isIdentifierPart(line[index])) {
          index++;
        }
        tokens.add(line.substring(start, index));
        continue;
      }

      if (_isDigit(character) ||
          (character == '.' &&
              index + 1 < line.length &&
              _isDigit(line[index + 1]))) {
        final start = index;
        if (character == '.') index++;
        while (index < line.length && _isDigit(line[index])) {
          index++;
        }
        if (index < line.length && line[index] == '.') {
          index++;
          while (index < line.length && _isDigit(line[index])) {
            index++;
          }
        }
        if (index < line.length && (line[index] == 'e' || line[index] == 'E')) {
          var exponentIndex = index + 1;
          if (exponentIndex < line.length &&
              (line[exponentIndex] == '+' || line[exponentIndex] == '-')) {
            exponentIndex++;
          }
          final exponentDigitsStart = exponentIndex;
          while (exponentIndex < line.length && _isDigit(line[exponentIndex])) {
            exponentIndex++;
          }
          if (exponentIndex > exponentDigitsStart) {
            index = exponentIndex;
          }
        }
        tokens.add(line.substring(start, index));
        continue;
      }

      const multiCharacterOperators = [
        '**=',
        '//=',
        '<<=',
        '>>=',
        '...',
        '==',
        '!=',
        '<=',
        '>=',
        '+=',
        '-=',
        '*=',
        '/=',
        '%=',
        '&=',
        '|=',
        '^=',
        ':=',
        '//',
        '**',
        '<<',
        '>>',
        '->',
      ];
      final operator = multiCharacterOperators.cast<String?>().firstWhere(
            (candidate) =>
                candidate != null && line.startsWith(candidate, index),
            orElse: () => null,
          );
      if (operator != null) {
        tokens.add(operator);
        index += operator.length;
      } else {
        tokens.add(character);
        index++;
      }
    }

    return tokens.join(' ');
  }

  static bool _isIdentifierStart(String character) {
    final code = character.codeUnitAt(0);
    return code == 0x5f ||
        (code >= 0x41 && code <= 0x5a) ||
        (code >= 0x61 && code <= 0x7a);
  }

  static bool _isIdentifierPart(String character) {
    return _isIdentifierStart(character) || _isDigit(character);
  }

  static bool _isDigit(String character) {
    final code = character.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
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
