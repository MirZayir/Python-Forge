import 'module.dart';

class Curriculum {
  final String version;
  final String title;
  final String description;
  final List<Module> modules;

  const Curriculum({
    required this.version,
    required this.title,
    required this.description,
    required this.modules,
  });

  factory Curriculum.fromJson(Map<String, dynamic> json) {
    final modulesJson = json['modules'] as List<dynamic>? ?? [];
    final modulesList = modulesJson
        .map((e) => Module.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort modules based on their designated order
    modulesList.sort((a, b) => a.order.compareTo(b.order));

    return Curriculum(
      version: json['version'] as String? ?? '1.0.0',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      modules: modulesList,
    );
  }
}
