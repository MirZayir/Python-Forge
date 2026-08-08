import 'package:flutter/material.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';
import '../../domain/models/module.dart';
import 'mission_screen.dart';

/// Module detail screen rendered in Neubrutalism style.
class ModuleScreen extends StatefulWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final ProgressManager _progressManager = ProgressManager();
  Set<String> _completedMissionIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = <String>{};
    for (final mission in widget.module.missions) {
      final isCompleted = await _progressManager.isMissionCompleted(mission.id);
      if (isCompleted) {
        completed.add(mission.id);
      }
    }

    if (mounted) {
      setState(() {
        _completedMissionIds = completed;
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
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.borderBlack,
              size: 20,
            ),
          ),
        ),
        title: Text(
          widget.module.title,
          style: const TextStyle(
            color: AppColors.borderBlack,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        color: AppColors.bgCream,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.large),
                physics: const BouncingScrollPhysics(),
                itemCount: widget.module.missions.length,
                itemBuilder: (context, index) {
                  final mission = widget.module.missions[index];
                  final isCompleted = _completedMissionIds.contains(mission.id);
                  return _buildMissionCard(mission, index + 1, isCompleted);
                },
              ),
      ),
    );
  }

  Widget _buildMissionCard(Mission mission, int number, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => MissionScreen(mission: mission),
                ),
              )
              .then((_) => _loadProgress());
        },
        child: Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderBlack, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowBlack,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission $number: ${mission.title}',
                      style: const TextStyle(
                        color: AppColors.borderBlack,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mission.description,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 13.0,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      isCompleted ? AppColors.neuOrange : AppColors.cardWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderBlack, width: 2.0),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  color: isCompleted ? Colors.white : AppColors.borderBlack,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
