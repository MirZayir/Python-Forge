import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/curriculum/domain/models/mission.dart';
import '../../features/curriculum/presentation/screens/home_screen.dart';
import '../../features/curriculum/presentation/screens/mission_screen.dart';

/// Provides the GoRouter instance for the application.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mission',
        name: 'mission',
        builder: (context, state) {
          final mission = state.extra as Mission;
          return MissionScreen(mission: mission);
        },
      ),
    ],
  );
});
