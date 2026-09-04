import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/sales/data/firestore_sales_repository.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';

final salesStreamProvider = StreamProvider<List<Sale>>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.watchAll();
});

final salesSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredSalesProvider = Provider<AsyncValue<List<Sale>>>((ref) {
  final salesState = ref.watch(salesStreamProvider);
  final query = ref.watch(salesSearchQueryProvider).toLowerCase();

  return salesState.whenData((sales) {
    if (query.isEmpty) return sales;
    return sales.where((sale) {
      final matchesClient = sale.clientName.toLowerCase().contains(query);
      final matchesItems = sale.items.any((item) =>
          item.sparePartName.toLowerCase().contains(query));
      return matchesClient || matchesItems;
    }).toList();
  });
});
