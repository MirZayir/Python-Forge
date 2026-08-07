import 'mission.dart';

class Module {
  final String moduleId;
  final String title;
  final String description;
  final int order;
  final double estimatedHours;
  final List<Mission> missions;

  const Module({
    required this.moduleId,
    required this.title,
    required this.description,
    required this.order,
    required this.estimatedHours,
    required this.missions,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    final missionsJson = json['missions'] as List<dynamic>? ?? [];

    // Inject index + 1 as `numberLabel` to preserve compatibility with MissionScreen
    final missionsList = missionsJson.asMap().entries.map((entry) {
      return Mission.fromJson(
        entry.value as Map<String, dynamic>,
        numberLabel: (entry.key + 1).toString(),
      );
    }).toList();

    return Module(
      moduleId: json['moduleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble() ?? 0.0,
      missions: missionsList,
    );
  }
}
