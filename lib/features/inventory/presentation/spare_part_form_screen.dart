import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/constants/app_constants.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/features/inventory/data/firestore_inventory_repository.dart';
import 'package:jm_imports/features/inventory/domain/spare_part.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'inventory_provider.dart';

class SparePartFormScreen extends ConsumerStatefulWidget {
  final String? sparePartId;

  const SparePartFormScreen({super.key, this.sparePartId});

  @override
  ConsumerState<SparePartFormScreen> createState() =>
      _SparePartFormScreenState();
}

class _SparePartFormScreenState extends ConsumerState<SparePartFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _customBrandController;
  late TextEditingController _modelController;
  late TextEditingController _stockController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;

  String? _selectedBrand = AppConstants.phoneBrands.first;
  String _selectedCategory = AppConstants.sparePartCategories.first;
  String _selectedQuality = AppConstants.qualities.first;
  bool _isLoading = false;
  bool _isFormInitialized = false;
  SparePart? _existingPart;

  double get _estimatedProfit {
    final cost =
        double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final sale =
        double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0.0;
    return sale - cost;
  }

  double get _profitMarginPercent {
    final cost =
        double.tryParse(_costPriceController.text.replaceAll(',', '.')) ?? 0.0;
    final sale =
        double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0.0;
    if (sale <= 0) return 0.0;
    return ((sale - cost) / sale) * 100;
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.sparePartCategories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return GestureDetector(
          onTap: () {
            AppHaptics.selection();
            setState(() {
              _selectedCategory = cat;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.2)
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : AppColors.divider,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat == 'Pantalla'
                      ? Icons.smartphone_rounded
                      : cat == 'Batería'
                      ? Icons.battery_charging_full_rounded
                      : cat == 'Flex de carga'
                      ? Icons.usb_rounded
                      : cat == 'Cámara'
                      ? Icons.camera_alt_rounded
                      : Icons.build_rounded,
                  size: 16,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textLightGray,
                ),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textLightGray,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBrandSelector() {
    final List<String> popularBrands = [
      'Samsung',
      'Xiaomi',
      'Apple',
      'Motorola',
      'Honor',
      'Huawei',
      'ZTE',
      'Realme',
      'Otra marca',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: popularBrands.map((brand) {
        final isSelected = _selectedBrand == brand;
        return GestureDetector(
          onTap: () {
            AppHaptics.selection();
            setState(() {
              _selectedBrand = brand;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.2)
                  : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primaryBlue : AppColors.divider,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (brand == 'Apple')
                  Icon(
                    Icons.apple,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.textLightGray,
                  )
                else if (brand == 'Samsung' || brand == 'Xiaomi')
                  Icon(
                    Icons.phone_android_rounded,
                    size: 16,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textLightGray,
                  )
                else
                  Icon(
                    Icons.mobile_friendly_rounded,
                    size: 16,
                    color: isSelected
                        ? AppColors.accentLightBlue
                        : AppColors.textLightGray,
                  ),
                const SizedBox(width: 6),
                Text(
                  brand,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textLightGray,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStockSelector() {
    final currentStock = int.tryParse(_stockController.text) ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: () {
                if (currentStock > 1) {
                  AppHaptics.selection();
                  setState(() {
                    _stockController.text = (currentStock - 1).toString();
                  });
                }
              },
              icon: const Icon(Icons.remove_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  if (int.tryParse(val.trim()) == null) return 'Inválido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              onPressed: () {
                AppHaptics.selection();
                setState(() {
                  _stockController.text = (currentStock + 1).toString();
                });
              },
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [1, 2, 5, 10].map((qty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ActionChip(
                label: Text('+ $qty'),
                backgroundColor: AppColors.surfaceDark,
                side: const BorderSide(color: AppColors.divider),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  AppHaptics.selection();
                  setState(() {
                    _stockController.text = (currentStock + qty).toString();
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _customBrandController = TextEditingController();
    _modelController = TextEditingController();
    _stockController = TextEditingController();
    _costPriceController = TextEditingController();
    _salePriceController = TextEditingController();

    _costPriceController.addListener(() => setState(() {}));
    _salePriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _customBrandController.dispose();
    _modelController.dispose();
    _stockController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  void _populateForm(SparePart part) {
    if (_isFormInitialized) return;
    _existingPart = part;
    if (AppConstants.phoneBrands.contains(part.brand)) {
      _selectedBrand = part.brand;
    } else {
      _selectedBrand = 'Otra marca';
      _customBrandController.text = part.brand;
    }
    if (AppConstants.sparePartCategories.contains(part.category)) {
      _selectedCategory = part.category;
    }
    _modelController.text = part.model;
    _stockController.text = part.stock.toString();
    _costPriceController.text = part.costPrice.toString();
    _salePriceController.text = part.salePrice.toString();
    _selectedQuality = part.quality;
    _isFormInitialized = true;
  }

  Future<void> _savePart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(inventoryRepositoryProvider);
      final finalBrand = _selectedBrand == 'Otra marca'
          ? _customBrandController.text.trim()
          : (_selectedBrand ?? '');

      final newPart = SparePart(
        id: _existingPart?.id ?? widget.sparePartId ?? '',
        brand: finalBrand,
        model: _modelController.text.trim(),
        category: _selectedCategory,
        quality: _selectedQuality,
        stock: int.parse(_stockController.text.trim()),
        costPrice: double.parse(
          _costPriceController.text.replaceAll(',', '.').trim(),
        ),
        salePrice: double.parse(
          _salePriceController.text.replaceAll(',', '.').trim(),
        ),
        createdAt: _existingPart?.createdAt ?? DateTime.now(),
      );

      if (_existingPart != null || widget.sparePartId != null) {
        await repository.update(newPart);
      } else {
        await repository.add(newPart);
      }

      if (mounted) {
        context.pop();
        AppToast.show(context, message: 'Repuesto guardado exitosamente');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Error al guardar: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePart() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Eliminar repuesto', style: AppTextStyles.titleMedium),
        content: Text(
          '¿Estás seguro de que deseas eliminar este repuesto?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(inventoryRepositoryProvider);
      await repository.delete(widget.sparePartId!);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repuesto eliminado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sparePartId != null;

    if (isEditing && !_isFormInitialized) {
      final partsAsync = ref.watch(inventoryStreamProvider);
      return partsAsync.when(
        data: (parts) {
          try {
            final part = parts.firstWhere((p) => p.id == widget.sparePartId);
            _populateForm(part);
          } catch (_) {}
          return _buildFormScaffold(isEditing);
        },
        loading: () => Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(title: const Text('Editar Repuesto')),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          ),
        ),
        error: (e, s) => _buildFormScaffold(isEditing),
      );
    }

    return _buildFormScaffold(isEditing);
  }

  Widget _buildFormScaffold(bool isEditing) {
    final profit = _estimatedProfit;
    final profitColor = profit >= 0 ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Repuesto' : 'Nuevo Repuesto',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deletePart,
              color: AppColors.error,
            ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check, color: AppColors.primaryBlue),
            onPressed: _isLoading ? null : _savePart,
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Tipo / Categoría
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría de Repuesto',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategorySelector(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: Marca y Modelo
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marca y Modelo',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBrandSelector(),
                    if (_selectedBrand == 'Otra marca') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _customBrandController,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Escribe la marca',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(
                            Icons.edit,
                            color: AppColors.accentLightBlue,
                          ),
                        ),
                        validator: (val) {
                          if (_selectedBrand == 'Otra marca' &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Escribe el nombre de la marca';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modelController,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Ej: Galaxy A54, iPhone 13',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.devices_other,
                          color: AppColors.accentLightBlue,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa el modelo del dispositivo';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Calidad y Stock
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calidad del Repuesto',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AppConstants.qualities.map((quality) {
                        final isSelected = _selectedQuality == quality;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(quality),
                          avatar: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: AppColors.surfaceBlue.withValues(
                            alpha: 0.15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.divider,
                            ),
                          ),
                          labelStyle: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textLightGray,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              AppHaptics.selection();
                              setState(() => _selectedQuality = quality);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cantidad en Stock',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStockSelector(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 4: Precios y Ganancia
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precios & Margen Comercial',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Precio de Costo (S/)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa el precio de costo';
                        }
                        if (double.tryParse(val.replaceAll(',', '.').trim()) ==
                            null) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _salePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Precio de Venta (S/)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.sell_outlined,
                          color: AppColors.success,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingresa el precio de venta';
                        }
                        if (double.tryParse(val.replaceAll(',', '.').trim()) ==
                            null) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: profitColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: profitColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ganancia estimada por unidad:',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                'S/ ${profit.toStringAsFixed(2)}',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: profitColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Margen comercial:',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textLightGray,
                                ),
                              ),
                              Text(
                                '${_profitMarginPercent.toStringAsFixed(1)}%',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: profitColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
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
                  onPressed: _isLoading
                      ? null
                      : () {
                          AppHaptics.success();
                          _savePart();
                        },
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.inventory_2_rounded, size: 22),
                  label: Text(
                    isEditing ? 'Guardar Cambios' : 'Registrar Repuesto',
                  ),
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
      ),
    );
  }
}
