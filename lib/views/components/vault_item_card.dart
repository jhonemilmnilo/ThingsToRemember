import 'package:flutter/material.dart';
import '../../theme.dart';

class VaultItemCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? noteContent;
  final bool isPinned;
  final bool isCompact;
  final VoidCallback onTap;

  const VaultItemCard({
    super.key,
    required this.title,
    this.subtitle,
    this.noteContent,
    this.isPinned = false,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        border: Border.all(
          color: isPinned ? AppColors.primaryMatcha.withValues(alpha: 0.5) : AppColors.borderMuted,
          width: isPinned ? 1.5 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        child: InkWell(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
          onTap: onTap,
          splashColor: AppColors.primaryMatcha.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryMatcha.withValues(alpha: 0.04),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isCompact ? 10 : 16,
            ),
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
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  SizedBox(height: isCompact ? 3 : 5),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isCompact ? 13.0 : 13.5,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (noteContent != null && noteContent!.trim().isNotEmpty) ...[
                  SizedBox(height: isCompact ? 5 : 8),
                  Text(
                    'Note: ${noteContent!.trim()}',
                    style: TextStyle(
                      fontSize: isCompact ? 11.5 : 12.0,
                      fontStyle: FontStyle.italic,
                      color: AppColors.sageMatcha,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: isCompact ? 1 : 2,
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
