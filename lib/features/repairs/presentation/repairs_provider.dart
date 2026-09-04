import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repair.dart';
import '../domain/repair_status.dart';
import '../data/firestore_repairs_repository.dart';

/// Watches all active repairs (not delivered and not cancelled).
final repairsStreamProvider = StreamProvider<List<Repair>>((ref) {
  final repository = ref.watch(repairsRepositoryProvider);
  return repository.watchActive();
});

/// Watches ALL repairs including delivered and cancelled.
final allRepairsStreamProvider = StreamProvider<List<Repair>>((ref) {
  final repository = ref.watch(repairsRepositoryProvider);
  return repository.watchAll();
});

/// Watches recent 5 repairs for Dashboard efficiency.
final recentRepairsStreamProvider = StreamProvider<List<Repair>>((ref) {
  final repository = ref.watch(repairsRepositoryProvider);
  return repository.watchRecent(5);
});

/// Search query for repairs.
final repairsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Optional status filter for repairs (null = active repairs).
final repairsStatusFilterProvider = StateProvider<RepairStatus?>((ref) => null);

/// Combines repairs stream with search and status filter.
final filteredRepairsProvider = Provider<List<Repair>>((ref) {
  final allRepairsAsync = ref.watch(allRepairsStreamProvider);
  final searchQuery = ref.watch(repairsSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(repairsStatusFilterProvider);

  return allRepairsAsync.when(
    data: (repairs) {
      return repairs.where((repair) {
        // Filter by status if set
        if (statusFilter != null) {
          if (repair.status != statusFilter) return false;
        } else {
          // Default: active repairs only (not delivered and not cancelled)
          if (repair.status == RepairStatus.delivered || repair.status == RepairStatus.cancelled) {
            return false;
          }
        }

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          final matchesName = repair.clientName.toLowerCase().contains(searchQuery);
          final matchesBrand = repair.deviceBrand.toLowerCase().contains(searchQuery);
          final matchesModel = repair.deviceModel.toLowerCase().contains(searchQuery);
          final matchesProblem = repair.reportedProblem.toLowerCase().contains(searchQuery);

          if (!matchesName && !matchesBrand && !matchesModel && !matchesProblem) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Groups filtered active repairs by status for a Kanban view.
final repairsByStatusProvider = Provider<Map<RepairStatus, List<Repair>>>((ref) {
  final filteredRepairs = ref.watch(filteredRepairsProvider);

  final Map<RepairStatus, List<Repair>> grouped = {
    for (var status in RepairStatus.values) status: [],
  };

  for (final repair in filteredRepairs) {
    grouped[repair.status]?.add(repair);
  }

  return grouped;
});
