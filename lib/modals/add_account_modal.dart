import 'package:flutter/material.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'modal_components.dart';

class AddAccountModal {
  AddAccountModal._();

  static void show({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdded,
  }) {
    final titleCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.oatMilkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool obscurePassword = true;

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
                  ModalComponents.header(context: ctx, title: 'Add New Account'),
                  const SizedBox(height: 18),
                  ModalComponents.input(
                    controller: titleCtrl,
                    label: 'Account / Service (e.g. Netflix, Gmail)',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: userCtrl,
                    label: 'Username or Email',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: passCtrl,
                    label: 'Password',
                    isPassword: obscurePassword,
                    suffix: GestureDetector(
                      onTap: () => setModalState(() => obscurePassword = !obscurePassword),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            obscurePassword ? 'Show' : 'Hide',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryMatcha,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: notesCtrl,
                    label: 'Note / Hint (Optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  ModalComponents.submitButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await NeonSyncService.createVaultItem(
                        userId: userId,
                        type: 'password',
                        data: {
                          'title': titleCtrl.text.trim(),
                          'username_or_email': userCtrl.text.trim(),
                          'password': passCtrl.text.trim(),
                          'notes': notesCtrl.text.trim(),
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
