import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/local_vault_db.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'modal_components.dart';
import 'wifi_scanner_modal.dart';

class AddWifiModal {
  AddWifiModal._();

  static void show({
    required BuildContext context,
    required String userId,
    required VoidCallback onAdded,
  }) {
    final ssidCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String securityType = 'WPA';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.oatMilkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 22,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ModalComponents.header(context: ctx, title: 'Add Wi-Fi Network'),
                    const SizedBox(height: 16),

                    // 📷 Scan Wi-Fi QR Code Button (Matcha Pill Action)
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await WifiScannerModal.scan(modalCtx);
                        if (result != null) {
                          setModalState(() {
                            ssidCtrl.text = result.ssid;
                            passwordCtrl.text = result.password;
                            securityType = result.securityType;
                          });

                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.primaryMatcha,
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'Scanned "${result.ssid}" successfully!',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.pistachioMint.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryMatcha.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 20,
                              color: AppColors.primaryMatcha,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Scan Wi-Fi QR Code (Auto-Fill)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryMatcha,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // SSID Input
                    ModalComponents.input(
                      controller: ssidCtrl,
                      label: 'Wi-Fi Name (SSID)',
                    ),
                    const SizedBox(height: 12),

                    // Password Input
                    ModalComponents.input(
                      controller: passwordCtrl,
                      label: 'Wi-Fi Password',
                    ),
                    const SizedBox(height: 12),

                    // Notes / Location Input
                    ModalComponents.input(
                      controller: notesCtrl,
                      label: 'Location / Notes (e.g. 5GHz, Living Room Router)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ModalComponents.submitButton(
                      onPressed: () async {
                        if (ssidCtrl.text.trim().isEmpty) return;

                        Navigator.pop(ctx);
                        final newId = const Uuid().v4();
                        final nowIso = DateTime.now().toIso8601String();
                        final payload = {
                          'id': newId,
                          'user_id': userId,
                          'ssid': ssidCtrl.text.trim(),
                          'password': passwordCtrl.text.trim(),
                          'security_type': securityType,
                          'notes': notesCtrl.text.trim(),
                          'is_pinned': 0,
                          'created_at': nowIso,
                          'updated_at': nowIso,
                        };

                        // 1. Instant Local Save with is_synced = 0
                        await LocalVaultDb.instance.upsertLocalItem(
                          table: 'local_wifi_networks',
                          row: payload,
                          markDirty: true,
                        );
                        onAdded();

                        // 2. Silent Cloud Push if connected
                        try {
                          final createdItem = await NeonSyncService.createVaultItem(
                            userId: userId,
                            type: 'wifi',
                            data: {
                              'id': newId,
                              'ssid': ssidCtrl.text.trim(),
                              'password': passwordCtrl.text.trim(),
                              'security_type': securityType,
                              'notes': notesCtrl.text.trim(),
                            },
                          );
                          if (createdItem != null && createdItem['id'] != null) {
                            final serverId = createdItem['id'].toString();
                            if (serverId != newId) {
                              final db = await LocalVaultDb.instance.database;
                              await db.delete('local_wifi_networks', where: 'id = ?', whereArgs: [newId]);
                              payload['id'] = serverId;
                              payload['password'] = createdItem['password'] ?? passwordCtrl.text.trim();
                              await LocalVaultDb.instance.upsertLocalItem(
                                table: 'local_wifi_networks',
                                row: payload,
                                markDirty: false,
                              );
                            } else {
                              await LocalVaultDb.instance.markBatchSynced(
                                table: 'local_wifi_networks',
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
              ),
            );
          },
        );
      },
    );
  }
}
