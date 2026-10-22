import 'package:flutter/material.dart';
import '../../theme.dart';

class ModalComponents {
  ModalComponents._();

  static Widget header({
    required BuildContext context,
    required String title,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.borderMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static Widget input({
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

  static Widget pinToggle({
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

  static Widget submitButton({
    required VoidCallback onPressed,
    String label = 'Save',
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMatcha,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
