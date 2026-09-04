import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/status_badge.dart';
import 'package:jm_imports/core/widgets/app_shimmer.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/core/widgets/app_speed_dial.dart';
import 'package:jm_imports/features/auth/data/firebase_auth_repository.dart';
import 'package:jm_imports/features/auth/presentation/auth_provider.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/repairs/presentation/status_change_sheet.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/features/sales/presentation/sales_provider.dart';

import 'dashboard_provider.dart';
import 'statistics_charts_widget.dart';
import 'statistics_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatSpanishDate(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName ${date.day} de $monthName';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'S/ ${formatter.format(amount)}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}m';
    return 'ahora';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final dailyStatsAsync = ref.watch(dailyStatisticsSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            AppHaptics.lightImpact();
            ref.invalidate(allRepairsStreamProvider);
            ref.invalidate(recentRepairsStreamProvider);
            ref.invalidate(inventoryStreamProvider);
            ref.invalidate(salesStreamProvider);
          },
          color: AppColors.primaryBlue,
          backgroundColor: AppColors.surfaceDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Executive Header Banner
                _buildHeader(ref, context),
                const SizedBox(height: 16),

                // 2. Hero Daily Financial Pulse Card
                dailyStatsAsync.when(
                  data: (dailyStats) =>
                      _buildDailyPulseCard(dailyStats, context),
                  loading: () =>
                      const AppShimmer(height: 110, width: double.infinity),
                  error: (e, s) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // 3. Grid KPI Status Cards & Content
                metricsAsync.when(
                  loading: () => const Column(
                    children: [
                      SizedBox(height: 20),
                      AppShimmer(height: 160, width: double.infinity),
                      SizedBox(height: 20),
                      AppShimmer(height: 250, width: double.infinity),
                    ],
                  ),
                  error: (error, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error al cargar el dashboard:\n$error',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (metrics) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Interactive Charts (Hoy, Semana, Mes)
                        const StatisticsChartsWidget(),
                        const SizedBox(height: 20),

                        // Priority Attention Section (Recent Repairs)
                        _buildPrioritySection(metrics, context, ref),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: const AppSpeedDial(),
    );
  }

  // Executive Header
  Widget _buildHeader(WidgetRef ref, BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Técnico';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.accentLightBlue],
            ),
          ),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceDark,
            backgroundImage: AssetImage('assets/images/app_logo.png'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hola, $userName! 🖐️',
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ' ${_formatSpanishDate(DateTime.now())}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.textLightGray,
              size: 18,
            ),
          ),
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            AppHaptics.warning();
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text('Cerrar sesión', style: AppTextStyles.titleMedium),
                content: Text(
                  '¿Deseas salir de la aplicación?',
                  style: AppTextStyles.bodyMedium,
                ),
                actions: [
                  TextButton(
                    onPressed: () => context.pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => context.pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(authRepositoryProvider).signOut();
              ref.read(isBiometricUnlockedProvider.notifier).state = false;
            }
          },
        ),
      ],
    );
  }

  // Hero Daily Financial Pulse Card
  Widget _buildDailyPulseCard(
    StatisticsSummary dailyStats,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PULSO FINANCIERO DE HOY',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightGray,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'EN TIEMPO REAL',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Ingresos Hoy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresos',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(dailyStats.totalRevenue),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              const SizedBox(width: 12),

              // Ganancia Neta Hoy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ganancia Neta',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(dailyStats.totalProfit),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.divider),
              const SizedBox(width: 12),

              // Equipos Hoy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Equipos Hoy',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dailyStats.totalEquipment}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              AppHaptics.selection();
              context.push('/daily-log');
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: AppColors.accentLightBlue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Cierre de Caja & Registro Diario',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accentLightBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.accentLightBlue, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Priority Attention Section (Recent Repairs List)
  Widget _buildPrioritySection(
    DashboardMetrics metrics,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Últimos Equipos', style: AppTextStyles.titleLarge),
            TextButton(
              onPressed: () {
                AppHaptics.selection();
                context.go('/repairs');
              },
              child: Text(
                'Ver todos',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accentLightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: metrics.recentRepairs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'No hay reparaciones recientes',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: metrics.recentRepairs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: AppColors.divider, height: 18),
                  itemBuilder: (context, index) {
                    final repair = metrics.recentRepairs[index];
                    return InkWell(
                      onTap: () {
                        AppHaptics.selection();
                        context.push('/repairs/${repair.id}');
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: repair.status.color.withValues(
                                  alpha: 0.18,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                repair.status.icon,
                                color: repair.status.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    repair.clientName,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${repair.deviceBrand} ${repair.deviceModel}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLightGray,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    StatusBadge(
                                      label: repair.status.label,
                                      color: repair.status.color,
                                    ),
                                    const SizedBox(width: 2),
                                    InkWell(
                                      onTap: () {
                                        AppHaptics.selection();
                                        StatusChangeSheet.show(context, ref, repair);
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.more_vert_rounded,
                                          color: AppColors.textLightGray,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.only(right: 26.0),
                                  child: Text(
                                    _timeAgo(repair.updatedAt),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLightGray,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
