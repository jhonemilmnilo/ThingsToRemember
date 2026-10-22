import 'package:flutter/material.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'modal_components.dart';

class AddBirthdayModal {
  AddBirthdayModal._();

  static void show({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdded,
  }) {
    final nameCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
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
                  ModalComponents.header(context: ctx, title: 'Add New Birthday'),
                  const SizedBox(height: 18),
                  ModalComponents.input(
                    controller: nameCtrl,
                    label: 'Family Member Name',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: dateCtrl,
                    label: 'Birthdate (YYYY-MM-DD)',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: relCtrl,
                    label: 'Relationship (e.g. Mother, Brother)',
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
                        type: 'birthday',
                        data: {
                          'name': nameCtrl.text.trim(),
                          'birthdate': dateCtrl.text.trim().isEmpty
                              ? '2000-01-01'
                              : dateCtrl.text.trim(),
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
