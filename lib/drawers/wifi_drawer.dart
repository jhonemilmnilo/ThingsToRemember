import 'package:flutter/material.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'drawer_components.dart';

class WifiDrawer {
  WifiDrawer._();

  static void show({
    required BuildContext context,
    required dynamic item,
    required String userId,
    required VoidCallback onSaved,
  }) {
    bool isEditing = false;
    bool isSaving = false;

    final ssidCtrl = TextEditingController(text: item['ssid'] ?? '');
    final passwordCtrl = TextEditingController(text: item['password'] ?? '');
    final notesCtrl = TextEditingController(text: item['notes'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setDrawerState) {
            final String currentTitle =
                ssidCtrl.text.trim().isEmpty ? 'Wi-Fi Network' : ssidCtrl.text.trim();

            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(modalCtx).viewInsets.bottom + 32,
              ),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DrawerComponents.handlePill(),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Wi-Fi' : currentTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setDrawerState(() => isEditing = !isEditing),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isEditing
                                        ? AppColors.primaryMatcha.withValues(alpha: 0.12)
                                        : AppColors.oatMilkBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderMuted),
                                  ),
                                  child: Text(
                                    isEditing ? 'Cancel' : 'Edit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isEditing ? AppColors.primaryMatcha : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.oatMilkBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.borderMuted),
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (isEditing) ...[
                        DrawerComponents.drawerInput(
                          controller: ssidCtrl,
                          label: 'Wi-Fi Name (SSID)',
                        ),
                        const SizedBox(height: 12),
                        DrawerComponents.drawerInput(
                          controller: passwordCtrl,
                          label: 'Wi-Fi Password',
                        ),
                        const SizedBox(height: 12),
                        DrawerComponents.drawerInput(
                          controller: notesCtrl,
                          label: 'Location / Notes (Optional)',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setDrawerState(() => isSaving = true);

                                    final updated = await NeonSyncService.updateVaultItem(
                                      userId: userId,
                                      itemId: item['id'].toString(),
                                      type: 'wifi',
                                      data: {
                                        'ssid': ssidCtrl.text.trim(),
                                        'password': passwordCtrl.text.trim(),
                                        'notes': notesCtrl.text.trim(),
                                      },
                                    );

                                    if (!context.mounted) return;
                                    if (updated) {
                                      Navigator.pop(ctx);
                                      onSaved();
                                    } else {
                                      setDrawerState(() => isSaving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMatcha,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ] else ...[
                        DrawerComponents.viewField(
                          context: modalCtx,
                          label: 'WI-FI NAME (SSID)',
                          value: item['ssid'] ?? '',
                          canCopy: true,
                        ),
                        DrawerComponents.viewField(
                          context: modalCtx,
                          label: 'PASSWORD',
                          value: item['password'] ?? '',
                          canCopy: true,
                        ),
                        if (item['security_type'] != null && item['security_type'].toString().isNotEmpty)
                          DrawerComponents.viewField(
                            context: modalCtx,
                            label: 'SECURITY TYPE',
                            value: item['security_type'].toString(),
                            canCopy: false,
                          ),
                        if (item['notes'] != null && item['notes'].toString().trim().isNotEmpty)
                          DrawerComponents.viewField(
                            context: modalCtx,
                            label: 'LOCATION / NOTES',
                            value: item['notes'].toString().trim(),
                            canCopy: false,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
