import 'package:flutter/material.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'modal_components.dart';

class AddContactModal {
  AddContactModal._();

  static void show({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdded,
  }) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.oatMilkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isPinned = false;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 22,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModalComponents.header(context: ctx, title: 'Add New Contact'),
                  const SizedBox(height: 18),
                  ModalComponents.input(
                    controller: nameCtrl,
                    label: 'Full Name',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: phoneCtrl,
                    label: 'Phone Number (e.g. +63 917...)',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: relCtrl,
                    label: 'Relationship / Note (e.g. Mama, Doctor)',
                  ),
                  const SizedBox(height: 14),
                  ModalComponents.pinToggle(
                    isPinned: isPinned,
                    onChanged: (val) => setModalState(() => isPinned = val),
                  ),
                  const SizedBox(height: 16),
                  ModalComponents.submitButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await NeonSyncService.createVaultItem(
                        userId: userId,
                        type: 'contact',
                        data: {
                          'name': nameCtrl.text.trim(),
                          'phone_number': phoneCtrl.text.trim(),
                          'relationship': relCtrl.text.trim(),
                          'is_pinned': isPinned,
                        },
                      );
                      onAdded();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
