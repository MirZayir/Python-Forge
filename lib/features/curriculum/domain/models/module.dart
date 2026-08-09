import 'mission.dart';

/// Represents a curriculum module containing a sequence of missions.
class Module {
  final String moduleId;
  final String title;
  final String description;
  final int order;
  final double estimatedHours;
  final bool isUnlocked;
  final List<Mission> missions;

  const Module({
    String? id,
    String? moduleId,
    required this.title,
    required this.description,
    this.order = 0,
    this.estimatedHours = 0.0,
    this.isUnlocked = true,
    required this.missions,
  }) : moduleId = moduleId ?? id ?? '';

  /// Compatibility alias for older screen and provider code.
  String get id => moduleId;

  factory Module.fromJson(Map<String, dynamic> json) {
    final rawMissions = json['missions'] as List<dynamic>? ?? const [];
    final order = (json['order'] as num?)?.toInt() ?? 0;

    final missions = rawMissions.asMap().entries.map((entry) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Every mission must be a JSON object.');
      }
      return Mission.fromJson(
        value,
        numberLabel: entry.key + 1,
        fallbackDifficulty: _difficultyForOrder(order),
      );
    }).toList(growable: false);

    return Module(
      moduleId: json['moduleId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: order,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble() ?? 0.0,
      isUnlocked:
          json['isUnlocked'] as bool? ?? json['is_unlocked'] as bool? ?? true,
      missions: missions,
    );
  }

  /// Calibrates rewards by curriculum stage when the asset omits difficulty.
  static String _difficultyForOrder(int order) {
    if (order <= 2) return 'easy';
    if (order <= 5) return 'medium';
    return 'hard';
  }
}
