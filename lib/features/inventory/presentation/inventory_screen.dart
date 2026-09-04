import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/status_badge.dart';
import 'package:jm_imports/core/widgets/empty_state.dart';
import 'package:jm_imports/core/constants/app_constants.dart';
import 'package:jm_imports/features/inventory/data/firestore_inventory_repository.dart';
import 'package:jm_imports/features/inventory/domain/spare_part.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/core/widgets/app_speed_dial.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('pantalla') || cat.contains('módulo')) {
      return Icons.smartphone_rounded;
    } else if (cat.contains('batería')) {
      return Icons.battery_charging_full_rounded;
    } else if (cat.contains('cámara')) {
      return Icons.photo_camera_rounded;
    } else if (cat.contains('altavoc')) {
      return Icons.volume_up_rounded;
    } else if (cat.contains('huella')) {
      return Icons.fingerprint_rounded;
    } else if (cat.contains('carga') || cat.contains('pin')) {
      return Icons.power_rounded;
    }
    return Icons.extension_rounded;
  }

  Future<void> _cleanOutOfStock() async {
    final count = await ref.read(inventoryRepositoryProvider).deleteOutOfStock();
    if (mounted) {
      AppToast.show(
        context,
        message: count > 0
            ? 'Se eliminaron $count repuestos agotados'
            : 'No hay repuestos agotados por eliminar',
      );
    }
  }

  List<String> _getUniqueBrands(List<SparePart> allParts) {
    final set = <String>{...AppConstants.phoneBrands.where((b) => b != 'Otra marca')};
    for (final part in allParts) {
      if (part.brand.isNotEmpty) set.add(part.brand);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _getUniqueCategories(List<SparePart> allParts) {
    final set = <String>{...AppConstants.sparePartCategories.where((c) => c != 'Otro repuesto')};
    for (final part in allParts) {
      if (part.category.isNotEmpty) set.add(part.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  void _showFilterSheet({
    required BuildContext context,
    required String title,
    required IconData titleIcon,
    required List<String> options,
    required String? selectedValue,
    required Map<String, int> counts,
    required ValueChanged<String?> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            final totalCount = counts.values.fold(0, (sum, count) => sum + count);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(titleIcon, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text(title, style: AppTextStyles.titleLarge),
                        ],
                      ),
                      if (selectedValue != null)
                        TextButton(
                          onPressed: () {
                            onSelect(null);
                            Navigator.pop(context);
                          },
                          child: const Text('Limpiar filtro'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: options.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isAllSelected = selectedValue == null;
                        return ListTile(
                          leading: Icon(
                            Icons.grid_view_rounded,
                            color: isAllSelected ? AppColors.primaryBlue : AppColors.textLightGray,
                          ),
                          title: Text(
                            'Todas',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isAllSelected ? AppColors.primaryBlue : null,
                              fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$totalCount', style: AppTextStyles.bodySmall),
                          ),
                          onTap: () {
                            onSelect(null);
                            Navigator.pop(context);
                          },
                        );
                      }

                      final option = options[index - 1];
                      final count = counts[option] ?? 0;
                      final isSelected = selectedValue == option;

                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? AppColors.primaryBlue : AppColors.textLightGray,
                        ),
                        title: Text(
                          option,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: isSelected ? AppColors.primaryBlue : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withValues(alpha: 0.2)
                                : AppColors.backgroundDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? AppColors.primaryBlue : AppColors.textLightGray,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        onTap: () {
                          onSelect(isSelected ? null : option);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredInventoryAsync = ref.watch(filteredInventoryProvider);
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final currentBrandFilter = ref.watch(inventoryBrandFilterProvider);
    final currentCategoryFilter = ref.watch(inventoryCategoryFilterProvider);
    final currentQualityFilter = ref.watch(inventoryQualityFilterProvider);

    final hasActiveFilters = currentBrandFilter != null ||
        currentCategoryFilter != null ||
        currentQualityFilter != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Buscar marca, modelo o repuesto...',
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLightGray.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(inventorySearchQueryProvider.notifier).state = value;
                },
              )
            : const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Eliminar repuestos agotados (Stock 0)',
            onPressed: _cleanOutOfStock,
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(inventorySearchQueryProvider.notifier).state = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar with Brand, Category & Quality options
          inventoryAsync.when(
            data: (allParts) {
              final brandCounts = <String, int>{};
              final categoryCounts = <String, int>{};
              final qualityCounts = <String, int>{};

              for (final p in allParts) {
                if (p.brand.isNotEmpty) {
                  brandCounts[p.brand] = (brandCounts[p.brand] ?? 0) + 1;
                }
                if (p.category.isNotEmpty) {
                  categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
                }
                if (p.quality.isNotEmpty) {
                  qualityCounts[p.quality] = (qualityCounts[p.quality] ?? 0) + 1;
                }
              }

              final uniqueBrands = _getUniqueBrands(allParts);
              final uniqueCategories = _getUniqueCategories(allParts);

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.divider.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // Filter Pill: Marca
                          _buildFilterDropdownChip(
                            label: currentBrandFilter ?? 'Marca',
                            icon: Icons.phone_android_rounded,
                            isSelected: currentBrandFilter != null,
                            onTap: () {
                              _showFilterSheet(
                                context: context,
                                title: 'Filtrar por Marca',
                                titleIcon: Icons.phone_android_rounded,
                                options: uniqueBrands,
                                selectedValue: currentBrandFilter,
                                counts: brandCounts,
                                onSelect: (val) {
                                  ref.read(inventoryBrandFilterProvider.notifier).state = val;
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),

                          // Filter Pill: Categoría
                          _buildFilterDropdownChip(
                            label: currentCategoryFilter ?? 'Categoría',
                            icon: Icons.category_rounded,
                            isSelected: currentCategoryFilter != null,
                            onTap: () {
                              _showFilterSheet(
                                context: context,
                                title: 'Filtrar por Categoría',
                                titleIcon: Icons.category_rounded,
                                options: uniqueCategories,
                                selectedValue: currentCategoryFilter,
                                counts: categoryCounts,
                                onSelect: (val) {
                                  ref.read(inventoryCategoryFilterProvider.notifier).state = val;
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 8),

                          // Filter Pill: Calidad
                          _buildFilterDropdownChip(
                            label: currentQualityFilter ?? 'Calidad',
                            icon: Icons.tune_rounded,
                            isSelected: currentQualityFilter != null,
                            onTap: () {
                              _showFilterSheet(
                                context: context,
                                title: 'Filtrar por Calidad',
                                titleIcon: Icons.tune_rounded,
                                options: AppConstants.qualities,
                                selectedValue: currentQualityFilter,
                                counts: qualityCounts,
                                onSelect: (val) {
                                  ref.read(inventoryQualityFilterProvider.notifier).state = val;
                                },
                              );
                            },
                          ),

                          if (hasActiveFilters) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                ref.read(inventoryBrandFilterProvider.notifier).state = null;
                                ref.read(inventoryCategoryFilterProvider.notifier).state = null;
                                ref.read(inventoryQualityFilterProvider.notifier).state = null;
                              },
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                              label: const Text('Limpiar todo', style: TextStyle(color: AppColors.error, fontSize: 13)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Active Filter Tags Row
                    if (hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (currentBrandFilter != null)
                              _buildActiveFilterChip(
                                label: 'Marca: $currentBrandFilter',
                                onRemove: () => ref.read(inventoryBrandFilterProvider.notifier).state = null,
                              ),
                            if (currentCategoryFilter != null)
                              _buildActiveFilterChip(
                                label: 'Cat: $currentCategoryFilter',
                                onRemove: () => ref.read(inventoryCategoryFilterProvider.notifier).state = null,
                              ),
                            if (currentQualityFilter != null)
                              _buildActiveFilterChip(
                                label: 'Calidad: $currentQualityFilter',
                                onRemove: () => ref.read(inventoryQualityFilterProvider.notifier).state = null,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 52),
            error: (_, _) => const SizedBox(height: 52),
          ),

          // Inventory items list
          Expanded(
            child: filteredInventoryAsync.when(
              data: (parts) {
                if (parts.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No hay repuestos',
                    subtitle: 'No se encontraron repuestos que coincidan con tu búsqueda o filtros.',
                    actionLabel: 'Agregar repuesto',
                    onAction: () => context.push('/inventory/new'),
                  );
                }
                return ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 80.0),
                  itemCount: parts.length,
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    Color stockColor = AppColors.success;
                    String stockLabel = 'Stock: ${part.stock}';

                    if (part.stock == 0) {
                      stockColor = AppColors.error;
                      stockLabel = 'Agotado';
                    } else if (part.stock <= 2) {
                      stockColor = AppColors.error;
                      stockLabel = 'Stock bajo (${part.stock})';
                    } else if (part.stock <= 5) {
                      stockColor = AppColors.warning;
                    }

                    final catIcon = _getCategoryIcon(part.category);

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      onTap: () => context.push('/inventory/${part.id}/edit'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(catIcon, color: AppColors.accentLightBlue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${part.brand} ${part.model}',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      part.category,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.accentLightBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: part.quality,
                                color: AppColors.surfaceBlue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stockColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: stockColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: stockColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      stockLabel,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: stockColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Costo: S/ ${part.costPrice.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLightGray,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    'Venta: S/ ${part.salePrice.toStringAsFixed(2)}',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error al cargar inventario: $error',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: const AppSpeedDial(),
    );
  }

  Widget _buildFilterDropdownChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : AppColors.accentLightBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textLightGray,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textLightGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.accentLightBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.cancel,
              size: 14,
              color: AppColors.accentLightBlue,
            ),
          ),
        ],
      ),
    );
  }
}
