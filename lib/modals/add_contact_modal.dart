import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_vault_db.dart';
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
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.oatMilkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                label: 'Relationship (e.g. Mama, Doctor, Lawyer)',
              ),
              const SizedBox(height: 12),
              ModalComponents.input(
                controller: notesCtrl,
                label: 'Notes / Address (Optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 18),
              ModalComponents.submitButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final newId = const Uuid().v4();
                  final nowIso = DateTime.now().toIso8601String();
                  final payload = {
                    'id': newId,
                    'user_id': userId,
                    'name': nameCtrl.text.trim(),
                    'phone_number': phoneCtrl.text.trim(),
                    'relationship': relCtrl.text.trim(),
                    'notes': notesCtrl.text.trim(),
                    'is_pinned': 0,
                    'created_at': nowIso,
                    'updated_at': nowIso,
                  };

                  // 1. Instant Local Save with is_synced = 0
                  await LocalVaultDb.instance.upsertLocalItem(
                    table: 'local_emergency_contacts',
                    row: payload,
                    markDirty: true,
                  );
                  onAdded();

                  // 2. Silent Cloud Push if connected
                  try {
                    final createdItem = await NeonSyncService.createVaultItem(
                      userId: userId,
                      type: 'contact',
                      data: {
                        'name': nameCtrl.text.trim(),
                        'phone_number': phoneCtrl.text.trim(),
                        'relationship': relCtrl.text.trim(),
                        'notes': notesCtrl.text.trim(),
                      },
                    );
                    if (createdItem != null && createdItem['id'] != null) {
                      final serverId = createdItem['id'].toString();
                      if (serverId != newId) {
                        final db = await LocalVaultDb.instance.database;
                        await db.delete('local_emergency_contacts', where: 'id = ?', whereArgs: [newId]);
                        payload['id'] = serverId;
                        await LocalVaultDb.instance.upsertLocalItem(
                          table: 'local_emergency_contacts',
                          row: payload,
                          markDirty: false,
                        );
                      } else {
                        await LocalVaultDb.instance.markBatchSynced(
                          table: 'local_emergency_contacts',
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
  }
}
