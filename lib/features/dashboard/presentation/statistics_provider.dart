import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/sales/presentation/sales_provider.dart';

enum StatsPeriod { daily, weekly, monthly }

class ChartDataPoint {
  final String label;
  final int equipmentCount;
  final double revenue;
  final double profit;

  ChartDataPoint({
    required this.label,
    required this.equipmentCount,
    required this.revenue,
    required this.profit,
  });
}

class StatisticsSummary {
  final StatsPeriod period;
  final List<ChartDataPoint> dataPoints;
  final int totalEquipment;
  final double totalRevenue;
  final double totalProfit;

  StatisticsSummary({
    required this.period,
    required this.dataPoints,
    required this.totalEquipment,
    required this.totalRevenue,
    required this.totalProfit,
  });
}

final selectedStatsPeriodProvider = StateProvider<StatsPeriod>((ref) => StatsPeriod.weekly);

/// Provider específico para obtener las estadísticas de HOY (Daily) de forma independiente
final dailyStatisticsSummaryProvider = Provider<AsyncValue<StatisticsSummary>>((ref) {
  return ref.watch(statisticsSummaryForPeriodProvider(StatsPeriod.daily));
});

/// Provider que reacciona al filtro de período seleccionado en la pantalla
final statisticsSummaryProvider = Provider<AsyncValue<StatisticsSummary>>((ref) {
  final period = ref.watch(selectedStatsPeriodProvider);
  return ref.watch(statisticsSummaryForPeriodProvider(period));
});

/// Provider Family parametrizado para cualquier período (daily, weekly, monthly)
final statisticsSummaryForPeriodProvider = Provider.family<AsyncValue<StatisticsSummary>, StatsPeriod>((ref, period) {
  final allRepairsAsync = ref.watch(allRepairsStreamProvider);
  final salesAsync = ref.watch(salesStreamProvider);

  if (allRepairsAsync.isLoading || salesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (allRepairsAsync.hasError) {
    return AsyncValue.error(allRepairsAsync.error!, allRepairsAsync.stackTrace!);
  }
  if (salesAsync.hasError) {
    return AsyncValue.error(salesAsync.error!, salesAsync.stackTrace!);
  }

  final repairs = allRepairsAsync.value ?? [];
  final sales = salesAsync.value ?? [];
  final now = DateTime.now();

  List<ChartDataPoint> points = [];

  switch (period) {
    case StatsPeriod.daily:
      const spanishDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      // Puntos del gráfico: Últimos 7 días para comparar día por día
      for (int i = 6; i >= 0; i--) {
        final dayDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final dayName = spanishDays[dayDate.weekday % 7];
        final dayLabel = '$dayName ${dayDate.day}';

        int eqCount = 0;
        double rev = 0;
        double profit = 0;

        for (final r in repairs) {
          final rDate = r.createdAt.toLocal();
          if (rDate.year == dayDate.year && rDate.month == dayDate.month && rDate.day == dayDate.day) {
            eqCount++;
          }
          // El ingreso solo se reconoce cuando el equipo ha sido ENTREGADO al cliente
          if (r.status == RepairStatus.delivered) {
            final dateDelivered = (r.deliveredAt ?? r.createdAt).toLocal();
            if (dateDelivered.year == dayDate.year && dateDelivered.month == dayDate.month && dateDelivered.day == dayDate.day) {
              rev += r.repairCost;
              profit += (r.repairCost - (r.partCostPrice ?? 0));
            }
          }
        }

        for (final s in sales) {
          final sDate = s.createdAt.toLocal();
          if (!s.isReturned && sDate.year == dayDate.year && sDate.month == dayDate.month && sDate.day == dayDate.day) {
            rev += s.totalAmount;
            profit += s.profit;
          }
        }

        points.add(ChartDataPoint(
          label: dayLabel,
          equipmentCount: eqCount,
          revenue: rev,
          profit: profit,
        ));
      }
      break;

    case StatsPeriod.weekly:
      // Semana actual (Lunes a Domingo)
      final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      final daysOfWeek = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

      for (int i = 0; i < 7; i++) {
        final dayDate = monday.add(Duration(days: i));
        final label = daysOfWeek[i];

        int eqCount = 0;
        double rev = 0;
        double profit = 0;

        for (final r in repairs) {
          final rDate = r.createdAt.toLocal();
          if (rDate.year == dayDate.year && rDate.month == dayDate.month && rDate.day == dayDate.day) {
            eqCount++;
          }
          if (r.status == RepairStatus.delivered) {
            final dateDelivered = (r.deliveredAt ?? r.createdAt).toLocal();
            if (dateDelivered.year == dayDate.year && dateDelivered.month == dayDate.month && dateDelivered.day == dayDate.day) {
              rev += r.repairCost;
              profit += (r.repairCost - (r.partCostPrice ?? 0));
            }
          }
        }

        for (final s in sales) {
          final sDate = s.createdAt.toLocal();
          if (!s.isReturned && sDate.year == dayDate.year && sDate.month == dayDate.month && sDate.day == dayDate.day) {
            rev += s.totalAmount;
            profit += s.profit;
          }
        }

        points.add(ChartDataPoint(
          label: label,
          equipmentCount: eqCount,
          revenue: rev,
          profit: profit,
        ));
      }
      break;

    case StatsPeriod.monthly:
      // Últimos 6 meses
      final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Set', 'Oct', 'Nov', 'Dic'];

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final label = months[monthDate.month - 1];

        int eqCount = 0;
        double rev = 0;
        double profit = 0;

        for (final r in repairs) {
          final rDate = r.createdAt.toLocal();
          if (rDate.year == monthDate.year && rDate.month == monthDate.month) {
            eqCount++;
          }
          if (r.status == RepairStatus.delivered) {
            final dateDelivered = (r.deliveredAt ?? r.createdAt).toLocal();
            if (dateDelivered.year == monthDate.year && dateDelivered.month == monthDate.month) {
              rev += r.repairCost;
              profit += (r.repairCost - (r.partCostPrice ?? 0));
            }
          }
        }

        for (final s in sales) {
          final sDate = s.createdAt.toLocal();
          if (!s.isReturned && sDate.year == monthDate.year && sDate.month == monthDate.month) {
            rev += s.totalAmount;
            profit += s.profit;
          }
        }

        points.add(ChartDataPoint(
          label: label,
          equipmentCount: eqCount,
          revenue: rev,
          profit: profit,
        ));
      }
      break;
  }

  // Cálculo de los KPIs superiores específicos según el período seleccionado
  int totalEquipment = 0;
  double totalRevenue = 0;
  double totalProfit = 0;

  if (period == StatsPeriod.daily) {
    // Calculo exclusivo para HOY
    final today = DateTime(now.year, now.month, now.day);
    for (final r in repairs) {
      final rDate = r.createdAt.toLocal();
      if (rDate.year == today.year && rDate.month == today.month && rDate.day == today.day) {
        totalEquipment++;
      }
      if (r.status == RepairStatus.delivered) {
        final dateDelivered = (r.deliveredAt ?? r.createdAt).toLocal();
        if (dateDelivered.year == today.year && dateDelivered.month == today.month && dateDelivered.day == today.day) {
          totalRevenue += r.repairCost;
          totalProfit += (r.repairCost - (r.partCostPrice ?? 0));
        }
      }
    }
    for (final s in sales) {
      final sDate = s.createdAt.toLocal();
      if (!s.isReturned && sDate.year == today.year && sDate.month == today.month && sDate.day == today.day) {
        totalRevenue += s.totalAmount;
        totalProfit += s.profit;
      }
    }
  } else if (period == StatsPeriod.weekly) {
    // Calculo acumulado para ESTA SEMANA (Lunes a Domingo)
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    for (final r in repairs) {
      final rDate = r.createdAt.toLocal();
      if (rDate.isAfter(monday.subtract(const Duration(seconds: 1))) && rDate.isBefore(sunday)) {
        totalEquipment++;
      }
      if (r.status == RepairStatus.delivered) {
        final dateDelivered = (r.deliveredAt ?? r.createdAt).toLocal();
        if (dateDelivered.isAfter(monday.subtract(const Duration(seconds: 1))) && dateDelivered.isBefore(sunday)) {
          totalRevenue += r.repairCost;
          totalProfit += (r.repairCost - (r.partCostPrice ?? 0));
        }
      }
    }
    for (final s in sales) {
      final sDate = s.createdAt.toLocal();
      if (!s.isReturned && sDate.isAfter(monday.subtract(const Duration(seconds: 1))) && sDate.isBefore(sunday)) {
        totalRevenue += s.totalAmount;
        totalProfit += s.profit;
      }
    }
  } else if (period == StatsPeriod.monthly) {
    // Calculo acumulado para ESTE MES
    for (final r in repairs) {
      final rDate = r.createdAt.toLocal();
      if (rDate.year == now.year && rDate.month == now.month) {
        totalEquipment++;
      }
      if (r.status == RepairStatus.delivered) {
        final dateDelivered = (r.deliveredAt ?? r.createdAt).toLocal();
        if (dateDelivered.year == now.year && dateDelivered.month == now.month) {
          totalRevenue += r.repairCost;
          totalProfit += (r.repairCost - (r.partCostPrice ?? 0));
        }
      }
    }
    for (final s in sales) {
      final sDate = s.createdAt.toLocal();
      if (!s.isReturned && sDate.year == now.year && sDate.month == now.month) {
        totalRevenue += s.totalAmount;
        totalProfit += s.profit;
      }
    }
  }

  return AsyncValue.data(StatisticsSummary(
    period: period,
    dataPoints: points,
    totalEquipment: totalEquipment,
    totalRevenue: totalRevenue,
    totalProfit: totalProfit,
  ));
});
