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
              StatefulBuilder(
                builder: (context, setPickerState) {
                  return GestureDetector(
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
                        setPickerState(() {
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
                  );
                },
              ),
              const SizedBox(height: 12),
              ModalComponents.input(
                controller: relCtrl,
                label: 'Relationship (e.g. Mother, Brother)',
              ),
              const SizedBox(height: 18),
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
  }
}
