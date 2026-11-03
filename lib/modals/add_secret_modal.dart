import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_vault_db.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'modal_components.dart';

class AddSecretModal {
  AddSecretModal._();

  static void show({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdded,
  }) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

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
                  ModalComponents.header(context: ctx, title: 'Add Thing to Remember'),
                  const SizedBox(height: 18),
                  ModalComponents.input(
                    controller: titleCtrl,
                    label: 'Title (e.g. WiFi Password, Safe Code)',
                  ),
                  const SizedBox(height: 12),
                  ModalComponents.input(
                    controller: contentCtrl,
                    label: 'Details / Note to remember',
                    maxLines: 4,
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
                      final newId = const Uuid().v4();
                      final nowIso = DateTime.now().toIso8601String();
                      final payload = {
                        'id': newId,
                        'user_id': userId,
                        'title': titleCtrl.text.trim(),
                        'content': contentCtrl.text.trim(),
                        'is_pinned': isPinned ? 1 : 0,
                        'created_at': nowIso,
                        'updated_at': nowIso,
                      };

                      // 1. Instant Local Save with is_synced = 0
                      await LocalVaultDb.instance.upsertLocalItem(
                        table: 'local_secure_notes',
                        row: payload,
                        markDirty: true,
                      );
                      onAdded();

                      // 2. Silent Cloud Push if connected
                      try {
                        final createdItem = await NeonSyncService.createVaultItem(
                          userId: userId,
                          type: 'secret',
                          data: {
                            'title': titleCtrl.text.trim(),
                            'content': contentCtrl.text.trim(),
                            'is_pinned': isPinned,
                          },
                        );
                        if (createdItem != null && createdItem['id'] != null) {
                          final serverId = createdItem['id'].toString();
                          if (serverId != newId) {
                            final db = await LocalVaultDb.instance.database;
                            await db.delete('local_secure_notes', where: 'id = ?', whereArgs: [newId]);
                            payload['id'] = serverId;
                            payload['content'] = createdItem['content'] ?? contentCtrl.text.trim();
                            await LocalVaultDb.instance.upsertLocalItem(
                              table: 'local_secure_notes',
                              row: payload,
                              markDirty: false,
                            );
                          } else {
                            await LocalVaultDb.instance.markBatchSynced(
                              table: 'local_secure_notes',
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
