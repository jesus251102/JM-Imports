import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';
import 'package:jm_imports/features/sales/presentation/sales_provider.dart';

enum TransactionType {
  repairReceived,
  repairDelivered,
  saleCompleted,
}

class DailyLogTransaction {
  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final String clientName;
  final double amount;
  final double cost;
  final double profit;
  final DateTime timestamp;
  final Repair? repair;
  final Sale? sale;

  DailyLogTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.clientName,
    required this.amount,
    required this.cost,
    required this.profit,
    required this.timestamp,
    this.repair,
    this.sale,
  });
}

class DailyLogSummary {
  final DateTime date;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final int equipmentsReceivedCount;
  final int equipmentsDeliveredCount;
  final int salesCount;
  final List<DailyLogTransaction> transactions;

  DailyLogSummary({
    required this.date,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.equipmentsReceivedCount,
    required this.equipmentsDeliveredCount,
    required this.salesCount,
    required this.transactions,
  });

  int get totalOperations => equipmentsReceivedCount + equipmentsDeliveredCount + salesCount;
}

final selectedDailyLogDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailyLogProvider = Provider.family<AsyncValue<DailyLogSummary>, DateTime>((ref, targetDate) {
  final repairsAsync = ref.watch(allRepairsStreamProvider);
  final salesAsync = ref.watch(salesStreamProvider);

  if (repairsAsync.isLoading || salesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (repairsAsync.hasError) {
    return AsyncValue.error(repairsAsync.error!, repairsAsync.stackTrace!);
  }
  if (salesAsync.hasError) {
    return AsyncValue.error(salesAsync.error!, salesAsync.stackTrace!);
  }

  final repairs = repairsAsync.value ?? [];
  final sales = salesAsync.value ?? [];

  final year = targetDate.year;
  final month = targetDate.month;
  final day = targetDate.day;

  double totalRevenue = 0;
  double totalCost = 0;
  double totalProfit = 0;

  int equipmentsReceivedCount = 0;
  int equipmentsDeliveredCount = 0;
  int salesCount = 0;

  List<DailyLogTransaction> transactions = [];

  // 1. Procesar Reparaciones
  for (final r in repairs) {
    final createdDate = r.createdAt.toLocal();

    // Reparación Ingresada hoy
    if (createdDate.year == year && createdDate.month == month && createdDate.day == day) {
      equipmentsReceivedCount++;
      transactions.add(
        DailyLogTransaction(
          id: 'rep_rec_${r.id}',
          type: TransactionType.repairReceived,
          title: 'Equipo Recibido: ${r.deviceBrand} ${r.deviceModel}',
          subtitle: 'Falla: ${r.reportedProblem}',
          clientName: r.clientName,
          amount: 0,
          cost: r.partCostPrice ?? 0,
          profit: 0,
          timestamp: createdDate,
          repair: r,
        ),
      );
    }

    // Reparación Entregada hoy (reconocimiento de cobro)
    if (r.status == RepairStatus.delivered) {
      final deliveredDate = (r.deliveredAt ?? r.createdAt).toLocal();
      if (deliveredDate.year == year && deliveredDate.month == month && deliveredDate.day == day) {
        equipmentsDeliveredCount++;
        final cost = r.partCostPrice ?? 0;
        final profit = r.repairCost - cost;

        totalRevenue += r.repairCost;
        totalCost += cost;
        totalProfit += profit;

        transactions.add(
          DailyLogTransaction(
            id: 'rep_del_${r.id}',
            type: TransactionType.repairDelivered,
            title: 'Entregado: ${r.deviceBrand} ${r.deviceModel}',
            subtitle: 'Cobro de reparación',
            clientName: r.clientName,
            amount: r.repairCost,
            cost: cost,
            profit: profit,
            timestamp: deliveredDate,
            repair: r,
          ),
        );
      }
    }
  }

  // 2. Procesar Ventas POS
  for (final s in sales) {
    final saleDate = s.createdAt.toLocal();
    if (!s.isReturned && saleDate.year == year && saleDate.month == month && saleDate.day == day) {
      salesCount++;
      totalRevenue += s.totalAmount;
      totalCost += s.totalCost;
      totalProfit += s.profit;

      final itemsSummary = s.items.map((i) => '${i.quantity}x ${i.sparePartName}').join(', ');

      transactions.add(
        DailyLogTransaction(
          id: 'sale_${s.id}',
          type: TransactionType.saleCompleted,
          title: 'Venta Directa POS (${s.items.length} ítems)',
          subtitle: itemsSummary,
          clientName: s.clientName,
          amount: s.totalAmount,
          cost: s.totalCost,
          profit: s.profit,
          timestamp: saleDate,
          sale: s,
        ),
      );
    }
  }

  // Ordenar cronológicamente descendente (más reciente primero)
  transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return AsyncValue.data(
    DailyLogSummary(
      date: targetDate,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      totalProfit: totalProfit,
      equipmentsReceivedCount: equipmentsReceivedCount,
      equipmentsDeliveredCount: equipmentsDeliveredCount,
      salesCount: salesCount,
      transactions: transactions,
    ),
  );
});
