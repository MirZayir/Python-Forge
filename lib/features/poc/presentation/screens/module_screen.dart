import 'package:flutter/material.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/unlock_engine.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/module.dart';
import 'mission_screen.dart';

/// Module Screen with Matte Cream Cards for unlocked missions.
class ModuleScreen extends StatefulWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  // Vintage Retro Matte Palette
  static const Color _creamMatte = Color(0xFFE8D8C9);
  static const Color _slateBlue = Color(0xFF4B607F);
  static const Color _retroOrange = Color(0xFFF3701E);
  static const Color _textDark = Color(0xFF18181A);
  static const Color _textMutedDark = Color(0xFF5A5A60);
  static const Color _lockedCard = Color(0xFF1F1F22);

  final ProgressManager _progressManager = ProgressManager();
  final UnlockEngine _unlockEngine = UnlockEngine();

  Map<String, bool> _completedStatus = {};
  Map<String, bool> _unlockedStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    Map<String, bool> comp = {};
    Map<String, bool> unlk = {};

    for (var mission in widget.module.missions) {
      comp[mission.id] = await _progressManager.isMissionCompleted(mission.id);
      unlk[mission.id] = await _unlockEngine.isUnlocked(mission);
    }

    if (mounted) {
      setState(() {
        _completedStatus = comp;
        _unlockedStatus = unlk;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _creamMatte, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.module.title,
          style: AppTypography.title.copyWith(
            color: _creamMatte,
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_retroOrange),
              ),
            )
          : widget.module.missions.isEmpty
              ? Center(
                  child: Text(
                    'No missions in this module yet.',
                    style: AppTypography.body.copyWith(color: _creamMatte),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  itemCount: widget.module.missions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.medium),
                  itemBuilder: (context, index) {
                    final mission = widget.module.missions[index];

                    final isCompleted = _completedStatus[mission.id] ?? false;
                    final isUnlocked = _unlockedStatus[mission.id] ?? false;

                    return Container(
                      decoration: BoxDecoration(
                        color: isUnlocked ? _creamMatte : _lockedCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isCompleted
                              ? _retroOrange
                              : (isUnlocked
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.06)),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: isUnlocked
                              ? () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MissionScreen(mission: mission),
                                    ),
                                  );
                                  _loadStatus();
                                }
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Mission ${mission.numberLabel}: ${mission.title}',
                                        style: AppTypography.title.copyWith(
                                          color: isUnlocked
                                              ? _textDark
                                              : Colors.white
                                                  .withValues(alpha: 0.4),
                                          fontSize: 17.0,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        mission.objective,
                                        style: AppTypography.body.copyWith(
                                          color: isUnlocked
                                              ? _textMutedDark
                                              : Colors.white
                                                  .withValues(alpha: 0.3),
                                          fontSize: 13.0,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.medium),
                                if (isCompleted)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _retroOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 18.0,
                                    ),
                                  )
                                else if (!isUnlocked)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.lock_outline_rounded,
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      size: 18.0,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: _slateBlue,
                                    size: 16.0,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
