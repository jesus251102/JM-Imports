import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/spare_part.dart';
import '../data/firestore_inventory_repository.dart';

final inventoryStreamProvider = StreamProvider<List<SparePart>>((ref) {
  final repository = ref.watch(inventoryRepositoryProvider);
  return repository.watchAll();
});

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final inventoryBrandFilterProvider = StateProvider<String?>((ref) => null);
final inventoryCategoryFilterProvider = StateProvider<String?>((ref) => null);
final inventoryQualityFilterProvider = StateProvider<String?>((ref) => null);

final filteredInventoryProvider = Provider<AsyncValue<List<SparePart>>>((ref) {
  final inventoryAsync = ref.watch(inventoryStreamProvider);
  final searchQuery = ref.watch(inventorySearchQueryProvider).toLowerCase();
  final brandFilter = ref.watch(inventoryBrandFilterProvider);
  final categoryFilter = ref.watch(inventoryCategoryFilterProvider);
  final qualityFilter = ref.watch(inventoryQualityFilterProvider);

  return inventoryAsync.whenData((parts) {
    return parts.where((part) {
      final matchesSearch = searchQuery.isEmpty ||
          part.brand.toLowerCase().contains(searchQuery) ||
          part.model.toLowerCase().contains(searchQuery) ||
          part.category.toLowerCase().contains(searchQuery) ||
          part.quality.toLowerCase().contains(searchQuery);

      final matchesBrand = brandFilter == null || part.brand == brandFilter;
      final matchesCategory = categoryFilter == null || part.category == categoryFilter;
      final matchesQuality = qualityFilter == null || part.quality == qualityFilter;

      return matchesSearch && matchesBrand && matchesCategory && matchesQuality;
    }).toList();
  });
});
