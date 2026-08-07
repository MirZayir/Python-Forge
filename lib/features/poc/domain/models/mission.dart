class ValidationRules {
  final String type;
  final List<String> validAnswers;
  final bool ignoreWhitespace;

  const ValidationRules({
    required this.type,
    required this.validAnswers,
    required this.ignoreWhitespace,
  });

  factory ValidationRules.fromJson(Map<String, dynamic> json) {
    return ValidationRules(
      type: json['type'] as String? ?? 'exact_match',
      validAnswers: (json['validAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      ignoreWhitespace: json['ignoreWhitespace'] as bool? ?? true,
    );
  }
}

/// Represents a single learning mission within the Python Forge curriculum.
class Mission {
  final String id;
  final String numberLabel;
  final String title;
  final String description;
  final String objective;
  final String difficulty;
  final List<String> prerequisites;
  final String starterCode;
  final List<String> expectedConcepts;
  final ValidationRules validationRules;
  final List<String> hints;

  const Mission({
    required this.id,
    required this.numberLabel,
    required this.title,
    required this.description,
    required this.objective,
    required this.difficulty,
    required this.prerequisites,
    required this.starterCode,
    required this.expectedConcepts,
    required this.validationRules,
    required this.hints,
  });

  factory Mission.fromJson(Map<String, dynamic> json,
      {String numberLabel = '1'}) {
    return Mission(
      id: json['id'] as String? ?? '',
      numberLabel: numberLabel,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'beginner',
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      starterCode: json['starterCode'] as String? ?? '',
      expectedConcepts: (json['expectedConcepts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      validationRules: json['validationRules'] != null
          ? ValidationRules.fromJson(
              json['validationRules'] as Map<String, dynamic>)
          : const ValidationRules(
              type: 'exact_match', validAnswers: [], ignoreWhitespace: true),
      hints: (json['hints'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
