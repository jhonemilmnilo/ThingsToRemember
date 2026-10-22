import 'package:flutter/material.dart';
import '../../theme.dart';

class VaultItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? noteContent;
  final bool isPinned;
  final VoidCallback onTap;

  const VaultItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.noteContent,
    this.isPinned = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPinned ? AppColors.primaryMatcha.withValues(alpha: 0.5) : AppColors.borderMuted,
          width: isPinned ? 1.5 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: AppColors.primaryMatcha.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryMatcha.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPinned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.pistachioMint.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PINNED',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryMatcha,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (noteContent != null && noteContent!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Note: ${noteContent!.trim()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.sageMatcha,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
