import 'package:flutter/material.dart';
import '../neon_sync_service.dart';
import '../theme.dart';
import 'drawer_components.dart';

class BirthdayDrawer {
  BirthdayDrawer._();

  static void show({
    required BuildContext context,
    required dynamic item,
    required String userId,
    required VoidCallback onSaved,
  }) {
    bool isEditing = false;
    bool isSaving = false;

    final nameCtrl = TextEditingController(text: item['name'] ?? '');
    final dateCtrl =
        TextEditingController(text: item['birthdate']?.toString().split('T').first ?? '');
    final relCtrl = TextEditingController(text: item['relationship'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setDrawerState) {
            final String currentTitle =
                nameCtrl.text.trim().isEmpty ? 'Birthday' : nameCtrl.text.trim();

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
                              isEditing ? 'Edit Birthday' : currentTitle,
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
                          controller: nameCtrl,
                          label: 'Family Member Name',
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            DateTime initialDate = DateTime.tryParse(dateCtrl.text.trim()) ?? DateTime(1998, 1, 1);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initialDate,
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              initialDatePickerMode: DatePickerMode.year,
                              initialEntryMode: DatePickerEntryMode.calendarOnly,
                              helpText: 'SELECT BIRTHDATE',
                              cancelText: 'CANCEL',
                              confirmText: 'SELECT',
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    dialogTheme: DialogThemeData(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      backgroundColor: AppColors.oatMilkBg,
                                    ),
                                    datePickerTheme: DatePickerThemeData(
                                      backgroundColor: AppColors.cardSurface,
                                      headerBackgroundColor: AppColors.primaryMatcha,
                                      headerForegroundColor: Colors.white,
                                      headerHeadlineStyle: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      dayStyle: const TextStyle(fontWeight: FontWeight.w600),
                                      todayBorder: const BorderSide(color: AppColors.primaryMatcha, width: 1.5),
                                      todayForegroundColor: const WidgetStatePropertyAll(AppColors.primaryMatcha),
                                      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) return Colors.white;
                                        return AppColors.textPrimary;
                                      }),
                                      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) return AppColors.primaryMatcha;
                                        return null;
                                      }),
                                      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) return Colors.white;
                                        return AppColors.textPrimary;
                                      }),
                                      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) return AppColors.primaryMatcha;
                                        return null;
                                      }),
                                    ),
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primaryMatcha,
                                      onPrimary: Colors.white,
                                      surface: AppColors.cardSurface,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              final formatted =
                                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              setDrawerState(() {
                                dateCtrl.text = formatted;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderMuted, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateCtrl.text.isEmpty
                                      ? 'Select Birthdate (Tap to Pick)'
                                      : 'Birthdate: ${dateCtrl.text}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: dateCtrl.text.isEmpty
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 20,
                                  color: AppColors.primaryMatcha,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DrawerComponents.drawerInput(
                          controller: relCtrl,
                          label: 'Relationship (e.g. Mother, Brother)',
                        ),
                        const SizedBox(height: 14),

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
                                      type: 'birthday',
                                      data: {
                                        'name': nameCtrl.text.trim(),
                                        'birthdate': dateCtrl.text.trim(),
                                        'relationship': relCtrl.text.trim(),
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
                          label: 'BIRTHDATE',
                          value: item['birthdate']?.toString().split('T').first ?? '',
                          canCopy: true,
                        ),
                        DrawerComponents.viewField(
                          context: modalCtx,
                          label: 'RELATIONSHIP',
                          value: item['relationship'] ?? 'Family',
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
