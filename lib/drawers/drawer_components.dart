import 'package:flutter/material.dart';
import '../theme.dart';

class DrawerComponents {
  DrawerComponents._();

  /// Handle pill at top of sheet
  static Widget handlePill() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderMuted,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Clean input field for drawers
  static Widget drawerInput({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardSurface,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryMatcha, width: 1.5),
        ),
      ),
    );
  }

  /// Read-only item detail row with optional show/hide and copy action
  static Widget viewField({
    required BuildContext context,
    required String label,
    required String value,
    bool isPassword = false,
    bool isPasswordRevealed = false,
    bool canCopy = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oatMilkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: AppColors.sageMatcha,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPassword
                      ? (isPasswordRevealed ? value : ('•' * (value.isEmpty ? 8 : value.length.clamp(8, 14))))
                      : value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: (isPassword && !isPasswordRevealed) ? 2.0 : 0.2,
                  ),
                ),
              ),
              if (onTogglePassword != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTogglePassword,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderMuted),
                    ),
                    child: Text(
                      isPasswordRevealed ? 'Hide' : 'Show',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryMatcha,
                      ),
                    ),
                  ),
                ),
              ],
              if (canCopy) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primaryMatcha,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                        content: Text('Copied $label to clipboard!'),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderMuted),
                    ),
                    child: const Icon(
                      Icons.content_copy_rounded,
                      size: 15,
                      color: AppColors.primaryMatcha,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Clean, unboxed Pin to Top toggle row
  static Widget pinToggleRow({
    required bool isPinned,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pin to Top',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Keep this priority item at the top',
                style: TextStyle(
                  fontSize: 12,
                  color: isPinned ? AppColors.primaryMatcha : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch.adaptive(
            value: isPinned,
            activeTrackColor: AppColors.primaryMatcha,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
