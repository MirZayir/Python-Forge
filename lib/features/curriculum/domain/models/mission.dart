enum MissionType {
  code,
  mcq,
  fillInBlank,
}

class ValidationRules {
  final String type;
  final List<String> validAnswers;

  const ValidationRules({
    required this.type,
    required this.validAnswers,
  });

  factory ValidationRules.fromJson(Map<String, dynamic> json) {
    return ValidationRules(
      type: json['type'] ?? 'exact_match',
      validAnswers: List<String>.from(json['validAnswers'] ?? []),
    );
  }
}

class Mission {
  final String id;
  final String title;
  final String description;
  final String objective;
  final String starterCode;
  final List<String> hints;
  final ValidationRules validationRules;
  final MissionType type;
  final List<String>? mcqOptions;
  final List<String> prerequisites;
  final String difficulty;
  final String? _numberLabel;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.starterCode,
    required this.hints,
    required this.validationRules,
    this.type = MissionType.code,
    this.mcqOptions,
    this.prerequisites = const [],
    this.difficulty = 'easy',
    String? numberLabel,
  }) : _numberLabel = numberLabel;

  String get numberLabel {
    final label = _numberLabel;
    if (label != null && label.isNotEmpty) {
      return label;
    }
    final match = RegExp(r'\d+').firstMatch(id);
    return match?.group(0) ?? '1';
  }

  factory Mission.fromJson(
    Map<String, dynamic> json, {
    String? numberLabel,
  }) {
    MissionType parseType(String? raw) {
      switch (raw) {
        case 'mcq':
          return MissionType.mcq;
        case 'fill_in_blank':
          return MissionType.fillInBlank;
        case 'code':
        default:
          return MissionType.code;
      }
    }

    return Mission(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      objective: json['objective'] ?? '',
      starterCode: json['starterCode'] ?? '',
      hints: List<String>.from(json['hints'] ?? []),
      validationRules: ValidationRules.fromJson(json['validationRules'] ?? {}),
      type: parseType(json['type']),
      mcqOptions: json['mcqOptions'] != null
          ? List<String>.from(json['mcqOptions'])
          : null,
      prerequisites: json['prerequisites'] != null
          ? List<String>.from(json['prerequisites'])
          : [],
      difficulty: json['difficulty'] ?? 'easy',
      numberLabel: numberLabel ?? json['numberLabel'],
    );
  }
}
