import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/features/inventory/domain/spare_part.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/features/sales/data/firestore_sales_repository.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';
import 'package:jm_imports/features/sales/domain/sale_item.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  dynamic _selectedClient;
  final List<SaleItem> _items = [];
  bool _isSaving = false;

  void _showInventoryPicker() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Consumer(
                  builder: (context, ref, child) {
                    final inventoryState = ref.watch(inventoryStreamProvider);
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        // Drag handle
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_rounded, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                'Seleccionar Repuesto',
                                style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: TextField(
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Buscar marca, modelo o repuesto...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                searchQuery = val.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: inventoryState.when(
                            data: (parts) {
                              final availableParts = parts.where((p) {
                                if (p.stock <= 0) return false;
                                if (searchQuery.isEmpty) return true;
                                return p.brand.toLowerCase().contains(searchQuery) ||
                                    p.model.toLowerCase().contains(searchQuery) ||
                                    p.category.toLowerCase().contains(searchQuery);
                              }).toList();

                              if (availableParts.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No hay repuestos en stock para esta búsqueda',
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLightGray),
                                  ),
                                );
                              }
                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: availableParts.length,
                                itemBuilder: (context, index) {
                                  final part = availableParts[index];
                                  final stockColor = part.stock <= 2 ? AppColors.warning : AppColors.success;

                                  return Card(
                                    color: AppColors.backgroundDark.withValues(alpha: 0.6),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: AppColors.divider),
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.extension_rounded, color: AppColors.primaryBlue, size: 20),
                                      ),
                                      title: Text(
                                        '${part.brand} ${part.model}',
                                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      subtitle: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${part.category} [${part.quality}]',
                                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: stockColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Stock: ${part.stock}',
                                              style: TextStyle(color: stockColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Text(
                                        'S/ ${part.salePrice.toStringAsFixed(2)}',
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onTap: () {
                                        final existingIndex = _items.indexWhere((i) => i.sparePartId == part.id);
                                        if (existingIndex >= 0) {
                                          if (_items[existingIndex].quantity >= part.stock) {
                                            AppHaptics.warning();
                                            AppToast.show(
                                              context,
                                              message: 'Límite alcanzado: Solo hay ${part.stock} unidades en stock',
                                              isError: true,
                                            );
                                            return;
                                          }
                                          AppHaptics.selection();
                                          setState(() {
                                            _items[existingIndex] = SaleItem(
                                              sparePartId: _items[existingIndex].sparePartId,
                                              sparePartName: _items[existingIndex].sparePartName,
                                              quantity: _items[existingIndex].quantity + 1,
                                              unitCostPrice: _items[existingIndex].unitCostPrice,
                                              unitSalePrice: _items[existingIndex].unitSalePrice,
                                            );
                                          });
                                        } else {
                                          AppHaptics.selection();
                                          setState(() {
                                            _items.add(SaleItem(
                                              sparePartId: part.id,
                                              sparePartName: '${part.brand} ${part.model} (${part.category}) [${part.quality}]',
                                              quantity: 1,
                                              unitCostPrice: part.costPrice,
                                              unitSalePrice: part.salePrice,
                                            ));
                                          });
                                        }
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                            error: (error, stack) => Center(child: Text('Error: $error', style: AppTextStyles.bodyMedium)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showClientPicker() {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Consumer(
                  builder: (context, ref, child) {
                    final clientsState = ref.watch(clientsStreamProvider);
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        // Drag handle
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_search_rounded, color: AppColors.primaryBlue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Seleccionar Cliente',
                                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                onPressed: () async {
                                  AppHaptics.selection();
                                  Navigator.pop(context);
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => const ClientFormDialog(),
                                  );
                                  if (result == true && mounted) {
                                    _showClientPicker();
                                  }
                                },
                                icon: const Icon(Icons.person_add_rounded, size: 16),
                                label: const Text('Nuevo'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          child: TextField(
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o teléfono...',
                              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                searchQuery = val.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: clientsState.when(
                            data: (clients) {
                              final filtered = clients.where((c) {
                                if (searchQuery.isEmpty) return true;
                                return c.name.toLowerCase().contains(searchQuery) ||
                                    c.phone.contains(searchQuery) ||
                                    c.dniRuc.toLowerCase().contains(searchQuery);
                              }).toList();

                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: filtered.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    final isSelected = _selectedClient == null;
                                    return Card(
                                      color: isSelected
                                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                          : AppColors.backgroundDark.withValues(alpha: 0.6),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected ? AppColors.primaryBlue : AppColors.divider,
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                                        ),
                                        title: Text('Cliente Ocasional / Mostrador', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                        subtitle: Text('Venta rápida sin registrar cliente', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
                                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue) : null,
                                        onTap: () {
                                          AppHaptics.selection();
                                          setState(() => _selectedClient = null);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  }
                                  final client = filtered[index - 1];
                                  final isSelected = _selectedClient?.id == client.id;
                                  return Card(
                                    color: isSelected
                                        ? AppColors.primaryBlue.withValues(alpha: 0.15)
                                        : AppColors.backgroundDark.withValues(alpha: 0.6),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected ? AppColors.primaryBlue : AppColors.divider,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.accentLightBlue.withValues(alpha: 0.2),
                                        child: Text(
                                          client.name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(color: AppColors.accentLightBlue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      title: Text(client.name, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        '${client.phone}${client.dniRuc.isNotEmpty ? ' • DNI/RUC: ${client.dniRuc}' : ''}',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                                      ),
                                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue) : null,
                                      onTap: () {
                                        AppHaptics.selection();
                                        setState(() => _selectedClient = client);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                            error: (error, stack) => Center(child: Text('Error: $error', style: AppTextStyles.bodyMedium)),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  double get _totalVenta => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get _costoRepuestos => _items.fold(0.0, (sum, item) => sum + item.totalCost);
  double get _gananciaEst => _totalVenta - _costoRepuestos;

  Future<void> _saveSale() async {
    if (_items.isEmpty) {
      AppToast.show(
        context,
        message: 'Agrega al menos un artículo a la venta',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(salesRepositoryProvider);
      final sale = Sale(
        id: '',
        clientId: _selectedClient?.id,
        clientName: _selectedClient?.name ?? 'Cliente Ocasional',
        items: _items,
        totalAmount: _totalVenta,
        totalCost: _costoRepuestos,
        profit: _gananciaEst,
        createdAt: DateTime.now(),
      );

      await repo.add(sale);
      if (mounted) {
        context.pop();
        AppToast.show(context, message: '¡Venta registrada con éxito!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Error al registrar venta: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Nueva Venta', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check, color: AppColors.primaryBlue),
            onPressed: _isSaving ? null : _saveSale,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              children: [
                // Client Card
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, color: AppColors.primaryBlue),
                          const SizedBox(width: 8),
                          Text('Cliente / Técnico', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showClientPicker,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlue.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedClient?.name ?? 'Cliente Ocasional / Mostrador',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryBlue),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Items Section
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shopping_cart_rounded, color: AppColors.accentLightBlue),
                              const SizedBox(width: 8),
                              Text('Artículos (${_items.length})', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Agregar'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _showInventoryPicker,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.remove_shopping_cart_outlined, size: 48, color: AppColors.textLightGray.withValues(alpha: 0.5)),
                                const SizedBox(height: 12),
                                Text(
                                  'No has agregado repuestos al carrito',
                                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLightGray),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _showInventoryPicker,
                                  icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
                                  label: const Text('Explorar Repuestos', style: TextStyle(color: AppColors.primaryBlue)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primaryBlue),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Consumer(
                          builder: (context, ref, child) {
                            final inventoryParts = ref.watch(inventoryStreamProvider).value ?? [];
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                final matchingPart = inventoryParts.firstWhere(
                                  (p) => p.id == item.sparePartId,
                                  orElse: () => SparePart(
                                    id: '',
                                    category: '',
                                    brand: '',
                                    model: '',
                                    quality: '',
                                    stock: 99999,
                                    costPrice: 0,
                                    salePrice: 0,
                                    createdAt: DateTime.now(),
                                  ),
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundDark.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.sparePartName,
                                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Precio un.: S/ ${item.unitSalePrice.toStringAsFixed(2)} | Subtotal: S/ ${item.totalPrice.toStringAsFixed(2)}',
                                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentLightBlue, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceDark,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppColors.divider),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.remove_rounded, size: 18, color: AppColors.textLightGray),
                                              onPressed: () {
                                                if (item.quantity > 1) {
                                                  AppHaptics.selection();
                                                  setState(() {
                                                    _items[index] = SaleItem(
                                                      sparePartId: item.sparePartId,
                                                      sparePartName: item.sparePartName,
                                                      quantity: item.quantity - 1,
                                                      unitCostPrice: item.unitCostPrice,
                                                      unitSalePrice: item.unitSalePrice,
                                                    );
                                                  });
                                                }
                                              },
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              child: Text(
                                                '${item.quantity}',
                                                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                            IconButton(
                                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryBlue),
                                              onPressed: () {
                                                if (matchingPart.id.isNotEmpty && item.quantity >= matchingPart.stock) {
                                                  AppHaptics.warning();
                                                  AppToast.show(
                                                    context,
                                                    message: 'Límite alcanzado: Solo hay ${matchingPart.stock} unidades en stock',
                                                    isError: true,
                                                  );
                                                  return;
                                                }
                                                AppHaptics.selection();
                                                setState(() {
                                                  _items[index] = SaleItem(
                                                    sparePartId: item.sparePartId,
                                                    sparePartName: item.sparePartName,
                                                    quantity: item.quantity + 1,
                                                    unitCostPrice: item.unitCostPrice,
                                                    unitSalePrice: item.unitSalePrice,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                                    onPressed: () {
                                      AppHaptics.warning();
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Elevated Total & Confirmation Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                top: BorderSide(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Venta:', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textLightGray)),
                    Text(
                      'S/ ${_totalVenta.toStringAsFixed(2)}',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Costo Repuestos: S/ ${_costoRepuestos.toStringAsFixed(2)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                    Text('Ganancia Est.: S/ ${_gananciaEst.toStringAsFixed(2)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            AppHaptics.success();
                            _saveSale();
                          },
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.point_of_sale_rounded, size: 22),
                    label: const Text('Confirmar y Registrar Venta'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
