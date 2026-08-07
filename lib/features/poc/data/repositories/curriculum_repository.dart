import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/curriculum.dart';

class CurriculumRepository {
  /// Asynchronously loads and parses the curriculum structure from local JSON assets.
  Future<Curriculum> getCurriculum() async {
    final jsonString =
        await rootBundle.loadString('assets/curriculum/curriculum.json');
    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

    return Curriculum.fromJson(jsonMap);
  }
}
