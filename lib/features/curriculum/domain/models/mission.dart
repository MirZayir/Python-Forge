enum MissionType {
  code,
  mcq,
  fillInBlank,
}

/// Explicit answer contract supplied by the curriculum asset.
class ValidationRules {
  final String type;
  final List<String> validAnswers;

  const ValidationRules({
    required this.type,
    required this.validAnswers,
  });

  factory ValidationRules.fromJson(Object? source) {
    if (source is! Map<String, dynamic>) {
      throw const FormatException('Mission validationRules must be an object.');
    }

    final rawAnswers = source['validAnswers'] as List<dynamic>? ?? const [];
    return ValidationRules(
      type: source['type'] as String? ?? 'exact_match',
      validAnswers: rawAnswers.map((answer) => answer.toString()).toList(),
    );
  }
}

/// Represents an individual learning challenge or mission.
class Mission {
  final String id;
  final String title;
  final String description;
  final String objective;
  final MissionType type;
  final String starterCode;
  final String expectedOutput;
  final List<String> hints;
  final ValidationRules validationRules;
  final List<String>? mcqOptions;
  final List<String> prerequisites;
  final String difficulty;
  final String? _numberLabel;
  final String? _expectedAnswer;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.type,
    this.starterCode = '',
    this.expectedOutput = '',
    this.hints = const [],
    this.validationRules = const ValidationRules(
      type: 'exact_match',
      validAnswers: [],
    ),
    this.mcqOptions,
    this.prerequisites = const [],
    this.difficulty = 'easy',
    String? numberLabel,
    String? expectedAnswer,
  })  : _numberLabel = numberLabel,
        _expectedAnswer = expectedAnswer;

  /// Compatibility aliases retained for older consumers.
  String get expectedAnswer => expectedOutput.isNotEmpty
      ? expectedOutput
      : (_expectedAnswer ?? validAnswers.firstOrNull ?? '');

  String get solution => expectedAnswer;

  List<String> get validAnswers => validationRules.validAnswers;

  String get numberLabel {
    if (_numberLabel != null && _numberLabel!.isNotEmpty) {
      return _numberLabel!;
    }
    return RegExp(r'\d+').firstMatch(id)?.group(0) ?? '1';
  }

  factory Mission.fromJson(
    Map<String, dynamic> json, {
    int? numberLabel,
    String fallbackDifficulty = 'easy',
  }) {
    final rawType = (json['type'] as String? ?? 'code').toLowerCase();
    final missionType = switch (rawType) {
      'mcq' => MissionType.mcq,
      'fill_in_blank' || 'fillinblank' => MissionType.fillInBlank,
      'code' => MissionType.code,
      _ => throw FormatException('Unsupported mission type: $rawType'),
    };

    final rawHints = json['hints'] as List<dynamic>? ?? const [];
    final rawPrerequisites =
        json['prerequisites'] as List<dynamic>? ?? const [];
    final rawOptions = json['mcqOptions'] as List<dynamic>? ??
        json['mcq_options'] as List<dynamic>?;

    return Mission(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      type: missionType,
      starterCode: json['starterCode'] as String? ??
          json['starter_code'] as String? ??
          '',
      expectedOutput: json['expectedOutput'] as String? ??
          json['expected_output'] as String? ??
          '',
      hints: rawHints.map((hint) => hint.toString()).toList(),
      validationRules: ValidationRules.fromJson(
        json['validationRules'] ?? json['validation_rules'] ?? const {},
      ),
      mcqOptions: rawOptions?.map((option) => option.toString()).toList(),
      prerequisites: rawPrerequisites
          .map((prerequisite) => prerequisite.toString())
          .toList(),
      difficulty: json['difficulty'] as String? ?? fallbackDifficulty,
      numberLabel: numberLabel?.toString(),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
