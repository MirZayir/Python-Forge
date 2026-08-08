import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/curriculum.dart';
import '../../domain/models/module.dart';

class CurriculumRepository {
  Curriculum? _cachedCurriculum;

  Future<Curriculum> getCurriculum() async {
    if (_cachedCurriculum != null) {
      return _cachedCurriculum!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/curriculum/missions.json');
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

      final List<Module> modules = jsonList
          .map((json) => Module.fromJson(json as Map<String, dynamic>))
          .toList();

      _cachedCurriculum = Curriculum(
        version: '1.0.0',
        title: 'Python Essentials',
        description: 'Master Python fundamentals from scratch.',
        modules: modules,
      );

      return _cachedCurriculum!;
    } catch (e) {
      throw Exception(
          'Failed to load curriculum from assets/curriculum/missions.json: $e');
    }
  }

  void clearCache() {
    _cachedCurriculum = null;
  }
}
