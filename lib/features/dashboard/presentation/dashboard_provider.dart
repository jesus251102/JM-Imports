import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/sales/presentation/sales_provider.dart';

class DashboardMetrics {
  final int totalActiveRepairs;
  final int repairsByReceived;
  final int repairsByUnderReview;
  final int repairsByRepaired;
  final int repairsByCancelled;
  final int totalDeliveredThisMonth;
  final double revenueThisMonth;
  final double costsThisMonth;
  final double profitThisMonth;
  final int totalInventoryItems;
  final int lowStockItems;
  final double inventoryValue;
  final int totalClients;
  final List<Repair> recentRepairs;

  DashboardMetrics({
    required this.totalActiveRepairs,
    required this.repairsByReceived,
    required this.repairsByUnderReview,
    required this.repairsByRepaired,
    required this.repairsByCancelled,
    required this.totalDeliveredThisMonth,
    required this.revenueThisMonth,
    required this.costsThisMonth,
    required this.profitThisMonth,
    required this.totalInventoryItems,
    required this.lowStockItems,
    required this.inventoryValue,
    required this.totalClients,
    required this.recentRepairs,
  });
}

final dashboardMetricsProvider = Provider<AsyncValue<DashboardMetrics>>((ref) {
  final allRepairsAsync = ref.watch(allRepairsStreamProvider);
  final recentRepairsAsync = ref.watch(recentRepairsStreamProvider);
  final inventoryAsync = ref.watch(inventoryStreamProvider);
  final clientsAsync = ref.watch(clientsStreamProvider);
  final salesAsync = ref.watch(salesStreamProvider);

  if (allRepairsAsync.isLoading || recentRepairsAsync.isLoading || inventoryAsync.isLoading || clientsAsync.isLoading || salesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (allRepairsAsync.hasError) {
    return AsyncValue.error(allRepairsAsync.error!, allRepairsAsync.stackTrace!);
  }
  if (recentRepairsAsync.hasError) {
    return AsyncValue.error(recentRepairsAsync.error!, recentRepairsAsync.stackTrace!);
  }
  if (inventoryAsync.hasError) {
    return AsyncValue.error(inventoryAsync.error!, inventoryAsync.stackTrace!);
  }
  if (clientsAsync.hasError) {
    return AsyncValue.error(clientsAsync.error!, clientsAsync.stackTrace!);
  }
  if (salesAsync.hasError) {
    return AsyncValue.error(salesAsync.error!, salesAsync.stackTrace!);
  }

  final repairs = allRepairsAsync.value ?? [];
  final recentRepairs = recentRepairsAsync.value ?? [];
  final inventory = inventoryAsync.value ?? [];
  final clients = clientsAsync.value ?? [];
  final sales = salesAsync.value ?? [];

  // Active repairs (excluding delivered and cancelled)
  final activeRepairs = repairs.where((r) => r.status != RepairStatus.delivered && r.status != RepairStatus.cancelled).toList();
  
  // Status counts
  int received = 0;
  int underReview = 0;
  int repaired = 0;
  int cancelled = 0;

  for (final r in repairs) {
    switch (r.status) {
      case RepairStatus.received:
        received++;
        break;
      case RepairStatus.underReview:
        underReview++;
        break;
      case RepairStatus.repaired:
        repaired++;
        break;
      case RepairStatus.cancelled:
        cancelled++;
        break;
      case RepairStatus.delivered:
        break;
    }
  }

  // Delivered repairs + completed sales this month
  final now = DateTime.now();
  int totalDeliveredThisMonth = 0;
  double revenueThisMonth = 0;
  double costsThisMonth = 0;

  for (final r in repairs) {
    if (r.status == RepairStatus.delivered) {
      final dateToCheck = r.deliveredAt ?? r.createdAt;
      final localDate = dateToCheck.toLocal();
      if (localDate.year == now.year && localDate.month == now.month) {
        totalDeliveredThisMonth++;
        revenueThisMonth += r.repairCost;
        costsThisMonth += r.partCostPrice ?? 0;
      }
    }
  }

  for (final s in sales) {
    final saleDate = s.createdAt.toLocal();
    if (!s.isReturned && saleDate.year == now.year && saleDate.month == now.month) {
      revenueThisMonth += s.totalAmount;
      costsThisMonth += s.totalCost;
    }
  }

  final profitThisMonth = revenueThisMonth - costsThisMonth;

  // Inventory
  int lowStockItems = 0;
  double inventoryValue = 0;

  for (final item in inventory) {
    if (item.stock <= 2) lowStockItems++;
    inventoryValue += item.costPrice * item.stock;
  }

  return AsyncValue.data(DashboardMetrics(
    totalActiveRepairs: activeRepairs.length,
    repairsByReceived: received,
    repairsByUnderReview: underReview,
    repairsByRepaired: repaired,
    repairsByCancelled: cancelled,
    totalDeliveredThisMonth: totalDeliveredThisMonth,
    revenueThisMonth: revenueThisMonth,
    costsThisMonth: costsThisMonth,
    profitThisMonth: profitThisMonth,
    totalInventoryItems: inventory.length,
    lowStockItems: lowStockItems,
    inventoryValue: inventoryValue,
    totalClients: clients.length,
    recentRepairs: recentRepairs,
  ));
});
