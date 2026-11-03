import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme.dart';

class VaultSkeletonLoading extends StatelessWidget {
  final int itemCount;

  const VaultSkeletonLoading({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      itemCount: itemCount,
      itemBuilder: (_, _) => const _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors.borderMuted.withValues(alpha: 0.5);
    final highlightColor = Colors.white.withValues(alpha: 0.7);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title placeholder
                Container(
                  width: 130,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Small badge / action placeholder
                Container(
                  width: 48,
                  height: 13,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Subtitle placeholder
            Container(
              width: 190,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 8),
            // Extra info / tag placeholder
            Container(
              width: 90,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
