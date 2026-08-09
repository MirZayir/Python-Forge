import 'module.dart';

/// Represents the top-level Python curriculum structure.
class Curriculum {
  final String id;
  final String version;
  final String title;
  final String description;
  final List<Module> modules;

  const Curriculum({
    this.id = 'python_mastery',
    this.version = '1.0.0',
    required this.title,
    required this.description,
    required this.modules,
  });

  /// Parses both the current asset format (a top-level module list) and the
  /// older envelope format ({"modules": [...]}) for safe migration.
  factory Curriculum.fromJson(Object? source) {
    String id = 'python_mastery';
    String version = '1.0.0';
    String title = 'Python Essentials';
    String description = 'Master Python fundamentals from scratch.';
    List<dynamic> moduleJson;

    if (source is List<dynamic>) {
      moduleJson = source;
    } else if (source is Map<String, dynamic>) {
      id = source['id'] as String? ?? id;
      version = source['version'] as String? ?? version;
      title = source['title'] as String? ?? title;
      description = source['description'] as String? ?? description;
      moduleJson = source['modules'] as List<dynamic>? ?? const [];
    } else {
      throw const FormatException(
        'Curriculum must be a JSON list or an object containing modules.',
      );
    }

    final modules = moduleJson.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException(
            'Every curriculum module must be an object.');
      }
      return Module.fromJson(entry);
    }).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Curriculum(
      id: id,
      version: version,
      title: title,
      description: description,
      modules: modules,
    );
  }
}
