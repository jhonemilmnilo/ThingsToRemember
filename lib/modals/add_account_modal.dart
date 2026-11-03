import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_vault_db.dart';
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
                      final newId = const Uuid().v4();
                      final payload = {
                        'id': newId,
                        'user_id': userId,
                        'title': titleCtrl.text.trim(),
                        'username_or_email': userCtrl.text.trim(),
                        'encrypted_password': passCtrl.text.trim(),
                        'iv': 'local_plain',
                        'notes': notesCtrl.text.trim(),
                        'website_url': notesCtrl.text.trim(),
                        'is_pinned': 0,
                      };

                      // 1. Instant Local Save with is_synced = 0
                      await LocalVaultDb.instance.upsertLocalItem(
                        table: 'local_credentials',
                        row: payload,
                        markDirty: true,
                      );
                      onAdded();

                      // 2. Silent Cloud Push if connected
                      try {
                        final createdItem = await NeonSyncService.createVaultItem(
                          userId: userId,
                          type: 'password',
                          data: {
                            'id': newId,
                            'title': titleCtrl.text.trim(),
                            'username_or_email': userCtrl.text.trim(),
                            'password': passCtrl.text.trim(),
                            'notes': notesCtrl.text.trim(),
                          },
                        );

                        if (createdItem != null && createdItem['id'] != null) {
                          final serverId = createdItem['id'].toString();
                          // If Neon generated a new ID, update our local ID to match server ID so no duplicate occurs on pull
                          if (serverId != newId) {
                            final db = await LocalVaultDb.instance.database;
                            await db.delete('local_credentials', where: 'id = ?', whereArgs: [newId]);
                            payload['id'] = serverId;
                            payload['encrypted_password'] = createdItem['encrypted_password'] ?? passCtrl.text.trim();
                            await LocalVaultDb.instance.upsertLocalItem(
                              table: 'local_credentials',
                              row: payload,
                              markDirty: false,
                            );
                          } else {
                            await LocalVaultDb.instance.markBatchSynced(
                              table: 'local_credentials',
                              activeIds: [newId],
                              deletedIds: [],
                            );
                          }
                          onAdded();
                        }
                      } catch (_) {}
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
