import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/data/firestore_repairs_repository.dart';

class StatusChangeSheet extends ConsumerWidget {
  final Repair repair;

  const StatusChangeSheet({super.key, required this.repair});

  static void show(BuildContext context, WidgetRef ref, Repair repair) {
    AppHaptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatusChangeSheet(repair: repair),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle de arrastre superior
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Encabezado del Modal
            Row(
              children: [
                const Icon(
                  Icons.published_with_changes_rounded,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cambiar estado',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Opciones de estado en formato tarjetas interactivas
            ...RepairStatus.values.map((status) {
              final isCurrent = status == repair.status;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (isCurrent) {
                        context.pop();
                        return;
                      }

                      AppHaptics.success();
                      context.pop();
                      try {
                        await ref
                            .read(repairsRepositoryProvider)
                            .updateStatus(repair.id, status);
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            message: 'Estado actualizado a "${status.label}"',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppToast.show(
                            context,
                            message: 'Error al actualizar: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isCurrent
                            ? LinearGradient(
                                colors: [
                                  status.color.withValues(alpha: 0.25),
                                  status.color.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: isCurrent ? null : AppColors.backgroundDark.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? status.color.withValues(alpha: 0.6)
                              : AppColors.divider,
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          if (isCurrent)
                            BoxShadow(
                              color: status.color.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status.icon,
                              color: status.color,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              status.label,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isCurrent ? Colors.white : AppColors.textLightGray,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: status.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: status.color,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
