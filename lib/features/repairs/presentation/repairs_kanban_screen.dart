import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/status_badge.dart';
import 'package:jm_imports/core/widgets/empty_state.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/repairs/presentation/status_change_sheet.dart';
import 'package:jm_imports/core/widgets/app_speed_dial.dart';

class RepairsKanbanScreen extends ConsumerStatefulWidget {
  const RepairsKanbanScreen({super.key});

  @override
  ConsumerState<RepairsKanbanScreen> createState() => _RepairsKanbanScreenState();
}

class _RepairsKanbanScreenState extends ConsumerState<RepairsKanbanScreen> {
  bool _isSearchVisible = false;

  String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStatusFilter = ref.watch(repairsStatusFilterProvider);
    final allRepairsState = ref.watch(allRepairsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: _isSearchVisible
            ? TextField(
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Buscar cliente, equipo o problema...',
                  border: InputBorder.none,
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLightGray.withValues(alpha: 0.5),
                  ),
                ),
                onChanged: (value) {
                  ref.read(repairsSearchQueryProvider.notifier).state = value;
                },
              )
            : Text('Reparaciones', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  ref.read(repairsSearchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          allRepairsState.when(
            data: (allRepairs) {
              final activeCount = allRepairs.where((r) => r.status != RepairStatus.delivered && r.status != RepairStatus.cancelled).length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Row(
                  children: [
                    _buildFilterPill(
                      label: 'Activas',
                      count: activeCount,
                      isSelected: selectedStatusFilter == null,
                      color: AppColors.primaryBlue,
                      icon: Icons.bolt_rounded,
                      onTap: () {
                        ref.read(repairsStatusFilterProvider.notifier).state = null;
                      },
                    ),
                    ...RepairStatus.values.map((status) {
                      final count = allRepairs.where((r) => r.status == status).length;
                      return _buildFilterPill(
                        label: status.label,
                        count: count,
                        isSelected: selectedStatusFilter == status,
                        color: status.color,
                        onTap: () {
                          ref.read(repairsStatusFilterProvider.notifier).state =
                              selectedStatusFilter == status ? null : status;
                        },
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 52),
            error: (_, _) => const SizedBox(height: 52),
          ),

          // Cards list
          Expanded(
            child: _buildListView(),
          ),
        ],
      ),
      floatingActionButton: const AppSpeedDial(),
    );
  }

  Widget _buildListView() {
    final allRepairsState = ref.watch(allRepairsStreamProvider);

    return allRepairsState.when(
      data: (_) {
        final repairs = ref.watch(filteredRepairsProvider);
        if (repairs.isEmpty) {
          return EmptyState(
            icon: Icons.build_circle_outlined,
            title: 'Sin reparaciones',
            subtitle: 'No hay equipos registrados para este estado o búsqueda',
            actionLabel: 'Nueva Reparación',
            onAction: () => context.push('/repairs/new'),
          );
        }

        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 80.0),
          itemCount: repairs.length,
          itemBuilder: (context, index) {
            return _buildRepairCard(repairs[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: AppTextStyles.bodyMedium),
      ),
    );
  }

  Widget _buildRepairCard(Repair repair) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      onTap: () => context.push('/repairs/${repair.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Client info + Price + Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: repair.status.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(repair.status.icon, color: repair.status.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repair.clientName,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.accentLightBlue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${repair.deviceBrand} ${repair.deviceModel}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.accentLightBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'S/ ${repair.repairCost.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textLightGray),
                    onPressed: () {
                      StatusChangeSheet.show(context, ref, repair);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Problem
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.build_circle_outlined, size: 16, color: AppColors.textLightGray),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  repair.reportedProblem,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLightGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer: Status + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(
                label: repair.status.label,
                color: repair.status.color,
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textLightGray),
                  const SizedBox(width: 4),
                  Text(
                    _timeAgo(repair.createdAt),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textLightGray.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.divider.withValues(alpha: 0.8),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? color : AppColors.textLightGray),
              const SizedBox(width: 6),
            ] else ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.textLightGray.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textLightGray,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.3)
                    : AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? color : AppColors.textLightGray,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
