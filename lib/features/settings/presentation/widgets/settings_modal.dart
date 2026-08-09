import 'package:flutter/material.dart';

import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Neubrutalist Settings & Preferences bottom sheet modal.
class SettingsModal extends StatefulWidget {
  final VoidCallback onProgressReset;

  const SettingsModal({super.key, required this.onProgressReset});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final SettingsService _settingsService = SettingsService();

  bool _hapticsEnabled = true;
  double _fontSize = 14.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final haptics = await _settingsService.isHapticsEnabled();
    final font = await _settingsService.getEditorFontSize();

    if (mounted) {
      setState(() {
        _hapticsEnabled = haptics;
        _fontSize = font;
        _isLoading = false;
      });
    }
  }

  void _showResetConfirmationDialog() {
    HapticService.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.bgCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderBlack, width: 3.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slagRed,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.0),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reset All Progress?',
                  style: TextStyle(
                    color: AppColors.borderBlack,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action will wipe all completed missions, XP, streaks, and unlocked achievements. It cannot be undone!',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.borderBlack, width: 2.0),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.borderBlack,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          await _settingsService.resetAllProgress();
                          if (!mounted) return;
                          navigator.pop();
                          navigator.pop();
                          widget.onProgressReset();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.slagRed,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.borderBlack, width: 2.0),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowBlack,
                                offset: Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Reset Data',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.borderBlack, width: 3.0),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.neuYellow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.borderBlack, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.borderBlack,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Preferences',
                          style: TextStyle(
                            color: AppColors.borderBlack,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.borderBlack, width: 2.0),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.borderBlack),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Haptic Feedback Toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.vibration_rounded,
                              color: AppColors.borderBlack, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Tactile Haptics',
                            style: TextStyle(
                              color: AppColors.borderBlack,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          final newValue = !_hapticsEnabled;
                          await _settingsService.setHapticsEnabled(newValue);
                          if (!mounted) return;
                          setState(() {
                            _hapticsEnabled = newValue;
                          });
                          if (newValue) HapticService.lightImpact();
                        },
                        child: Container(
                          width: 52,
                          height: 30,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _hapticsEnabled
                                ? AppColors.neuGreen
                                : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                                color: AppColors.borderBlack, width: 2.0),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 180),
                            alignment: _hapticsEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.borderBlack, width: 1.8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Code Editor Font Size Selector
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.format_size_rounded,
                              color: AppColors.borderBlack, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Code Editor Font Size',
                            style: TextStyle(
                              color: AppColors.borderBlack,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildFontSizeChip('Small', 12.0),
                          const SizedBox(width: 8),
                          _buildFontSizeChip('Medium', 14.0),
                          const SizedBox(width: 8),
                          _buildFontSizeChip('Large', 18.0),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reset Progress Action Button
                GestureDetector(
                  onTap: _showResetConfirmationDialog,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neuPink,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restart_alt_rounded,
                            color: AppColors.borderBlack, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Reset All Progress',
                          style: TextStyle(
                            color: AppColors.borderBlack,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFontSizeChip(String label, double size) {
    final isSelected = _fontSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          HapticService.selectionClick();
          await _settingsService.setEditorFontSize(size);
          setState(() {
            _fontSize = size;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neuYellow : AppColors.bgCream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderBlack, width: 2.0),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.borderBlack,
                fontSize: 13.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
