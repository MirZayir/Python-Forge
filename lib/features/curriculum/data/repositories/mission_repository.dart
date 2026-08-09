import 'curriculum_repository.dart';
import '../../domain/models/curriculum.dart';

/// Compatibility facade for older callers.
///
/// CurriculumRepository owns parsing, validation, caching, and errors. Keeping
/// this facade prevents two repositories from drifting into different data
/// contracts.
class MissionRepository {
  final CurriculumRepository _repository;

  MissionRepository({CurriculumRepository? repository})
      : _repository = repository ?? CurriculumRepository();

  Future<Curriculum> getCurriculum() => _repository.getCurriculum();
}
