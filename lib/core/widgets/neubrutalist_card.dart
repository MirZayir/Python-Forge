import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Neubrutalist folder-style card with a top tab, solid 2.5px border, and hard black drop shadow.
class NeubrutalistFolderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tabColor;
  final VoidCallback onTap;
  final Widget? trailingBadge;

  const NeubrutalistFolderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tabColor,
    required this.onTap,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Folder Top Tab
          Container(
            height: 18,
            width: 100,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: tabColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
            ),
          ),
          // Main Folder Body Box
          Container(
            margin: const EdgeInsets.only(top: 0),
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBlack,
                  offset: Offset(5, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chunky Square Icon Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tabColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.borderBlack, width: 2.5),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.borderBlack,
                        size: 24,
                      ),
                    ),
                    if (trailingBadge != null) trailingBadge!,
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.borderBlack,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
