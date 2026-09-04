import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'statistics_provider.dart';

class StatisticsChartsWidget extends ConsumerWidget {
  const StatisticsChartsWidget({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'S/ ${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedStatsPeriodProvider);
    final statsAsync = ref.watch(statisticsSummaryProvider);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title & Filter Segmented Control
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estadísticas de Gestión',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Period Filter Chips (Hoy, Semana, Mes)
          Row(
            children: [
              _buildPeriodChip(ref, StatsPeriod.daily, 'Hoy', selectedPeriod),
              const SizedBox(width: 8),
              _buildPeriodChip(ref, StatsPeriod.weekly, 'Semana', selectedPeriod),
              const SizedBox(width: 8),
              _buildPeriodChip(ref, StatsPeriod.monthly, 'Mes', selectedPeriod),
            ],
          ),
          const SizedBox(height: 16),

          statsAsync.when(
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error al calcular estadísticas: $err',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
            data: (stats) {
              final periodSuffix = selectedPeriod == StatsPeriod.daily
                  ? 'Hoy'
                  : (selectedPeriod == StatsPeriod.weekly ? 'Semana' : 'Mes');

              return Column(
                children: [
                  // KPI Summary Badges
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiMiniCard(
                          'Equipos ($periodSuffix)',
                          stats.totalEquipment.toString(),
                          Icons.phone_android_rounded,
                          AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiMiniCard(
                          'Ingresos ($periodSuffix)',
                          _formatCurrency(stats.totalRevenue),
                          Icons.payments_rounded,
                          AppColors.accentLightBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiMiniCard(
                          'Ganancia ($periodSuffix)',
                          _formatCurrency(stats.totalProfit),
                          Icons.trending_up_rounded,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section Title 1: Ingreso de Equipos
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ingreso de Equipos (Celulares / Dispositivos)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLightGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: _buildEquipmentBarChart(stats.dataPoints),
                  ),

                  const SizedBox(height: 24),

                  // Section Title 2: Ingresos y Ganancia
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Flujo Monetario (Ingresos & Ganancia en S/)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLightGray,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: _buildMoneyLineChart(stats.dataPoints),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(WidgetRef ref, StatsPeriod period, String label, StatsPeriod current) {
    final isSelected = current == period;

    return Expanded(
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          ref.read(selectedStatsPeriodProvider.notifier).state = period;
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.22)
                : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.divider,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textLightGray,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLightGray,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentBarChart(List<ChartDataPoint> points) {
    int maxVal = 1;
    for (final p in points) {
      if (p.equipmentCount > maxVal) maxVal = p.equipmentCount;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxVal + 1).toDouble(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.surfaceDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final pt = points[groupIndex];
              return BarTooltipItem(
                '${pt.label}\n${pt.equipmentCount} equipos',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    points[idx].label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightGray,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(points.length, (index) {
          final count = points[index].equipmentCount;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: AppColors.primaryBlue,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: (maxVal + 1).toDouble(),
                  color: AppColors.surfaceDark,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMoneyLineChart(List<ChartDataPoint> points) {
    double maxVal = 100;
    for (final p in points) {
      if (p.revenue > maxVal) maxVal = p.revenue;
    }

    final spotsRevenue = List.generate(points.length, (i) {
      return FlSpot(i.toDouble(), points[i].revenue);
    });

    final spotsProfit = List.generate(points.length, (i) {
      return FlSpot(i.toDouble(), points[i].profit);
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        maxY: maxVal * 1.15,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => AppColors.surfaceDark,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final pt = points[idx];
                final isRev = spot.barIndex == 0;
                final val = isRev ? pt.revenue : pt.profit;
                final tag = isRev ? 'Ingreso' : 'Ganancia';
                final col = isRev ? AppColors.accentLightBlue : AppColors.success;
                return LineTooltipItem(
                  '${pt.label}\n$tag: S/ ${val.toStringAsFixed(2)}',
                  TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    points[idx].label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightGray,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          // Ingresos totales
          LineChartBarData(
            spots: spotsRevenue,
            isCurved: true,
            color: AppColors.accentLightBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accentLightBlue.withValues(alpha: 0.12),
            ),
          ),
          // Ganancia neta
          LineChartBarData(
            spots: spotsProfit,
            isCurved: true,
            color: AppColors.success,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
