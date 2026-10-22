import 'package:flutter/material.dart';
import '../../theme.dart';

class EmptyTabView extends StatelessWidget {
  final String tabTitle;
  final String explanation;

  const EmptyTabView({
    super.key,
    required this.tabTitle,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.pistachioMint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'VAULT STATUS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryMatcha,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your $tabTitle Vault is Empty',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                explanation,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'End-to-End Encrypted Vault',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sageMatcha,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tap "Add" below to get started',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
