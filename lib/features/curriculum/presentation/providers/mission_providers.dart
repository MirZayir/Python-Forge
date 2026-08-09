import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/streak_engine.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum.dart';
import '../../domain/models/mission.dart';
import '../../domain/models/module.dart';

/// Provider for CurriculumRepository instance
final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});

/// FutureProvider that fetches the full Curriculum asynchronously
final curriculumProvider = FutureProvider<Curriculum>((ref) async {
  final repository = ref.watch(curriculumRepositoryProvider);
  return repository.getCurriculum();
});

/// Provider for StreakEngine instance
final streakEngineProvider = Provider<StreakEngine>((ref) {
  return StreakEngine();
});

/// Provider for ProgressManager instance
final progressManagerProvider = Provider<ProgressManager>((ref) {
  return ProgressManager();
});

/// Family provider to select a specific Module by ID
final moduleByIdProvider = Provider.family<Module?, String>((ref, moduleId) {
  final curriculumAsync = ref.watch(curriculumProvider);
  return curriculumAsync.when(
    data: (curriculum) {
      try {
        return curriculum.modules.firstWhere((m) => m.id == moduleId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Family provider to select a specific Mission by ID
final missionByIdProvider = Provider.family<Mission?, String>((ref, missionId) {
  final curriculumAsync = ref.watch(curriculumProvider);
  return curriculumAsync.when(
    data: (curriculum) {
      for (final module in curriculum.modules) {
        for (final mission in module.missions) {
          if (mission.id == missionId) {
            return mission;
          }
        }
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
