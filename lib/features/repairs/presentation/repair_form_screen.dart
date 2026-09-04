import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/constants/app_constants.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/data/firestore_repairs_repository.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';

import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';

class RepairFormScreen extends ConsumerStatefulWidget {
  const RepairFormScreen({super.key});

  @override
  ConsumerState<RepairFormScreen> createState() => _RepairFormScreenState();
}

class _RepairFormScreenState extends ConsumerState<RepairFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedBrand = AppConstants.phoneBrands.first;

  final _clientController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _imeiController = TextEditingController();
  final _problemController = TextEditingController();
  final _conditionController = TextEditingController();
  final _costController = TextEditingController();
  final _partCostController = TextEditingController();

  bool _isLoading = false;

  final List<String> _quickConditions = [
    'Sin observaciones',
    'Rayones leves',
    'Pantalla trizada',
    'Golpe en esquina',
    'Sin tapa posterior',
    'Tapa trizada',
    'Sin bandeja SIM',
  ];

  @override
  void dispose() {
    _clientController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _imeiController.dispose();
    _problemController.dispose();
    _conditionController.dispose();
    _costController.dispose();
    _partCostController.dispose();
    super.dispose();
  }

  Future<void> _selectClient() async {
    final clientsAsync = ref.read(clientsStreamProvider);
    String searchQuery = '';

    await showModalBottomSheet(
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
                return Column(
                  children: [
                    const SizedBox(height: 12),
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
                              const Icon(
                                Icons.person_search_rounded,
                                color: AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Seleccionar Cliente',
                                style: AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          FilledButton.icon(
                            onPressed: () {
                              AppHaptics.selection();
                              context.pop();
                              showDialog(
                                context: context,
                                builder: (context) => const ClientFormDialog(),
                              );
                            },
                            icon: const Icon(
                              Icons.person_add_rounded,
                              size: 16,
                            ),
                            label: const Text('Nuevo'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: TextField(
                        style: AppTextStyles.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o teléfono...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.primaryBlue,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
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
                      child: clientsAsync.when(
                        data: (clients) {
                          final filtered = clients.where((c) {
                            return c.name.toLowerCase().contains(searchQuery) ||
                                c.phone.contains(searchQuery);
                          }).toList();

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(
                                'No se encontraron clientes',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textLightGray,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final client = filtered[index];
                              final isSelected = _selectedClientId == client.id;

                              return Card(
                                color: isSelected
                                    ? AppColors.primaryBlue.withValues(
                                        alpha: 0.15,
                                      )
                                    : AppColors.backgroundDark.withValues(
                                        alpha: 0.6,
                                      ),
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : AppColors.divider,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue
                                        .withValues(alpha: 0.2),
                                    child: Text(
                                      client.name.substring(0, 1).toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    client.name,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    client.phone,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLightGray,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primaryBlue,
                                        )
                                      : null,
                                  onTap: () {
                                    AppHaptics.selection();
                                    setState(() {
                                      _selectedClientId = client.id;
                                      _selectedClientName = client.name;
                                      _clientController.text = client.name;
                                    });
                                    context.pop();
                                  },
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        error: (e, s) => Center(
                          child: Text(
                            'Error: $e',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
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

  Widget _buildBudgetPresets() {
    final List<double> presets = [50, 80, 100, 120, 150, 200];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((price) {
        final priceStr = price.toStringAsFixed(0);
        return GestureDetector(
          onTap: () {
            AppHaptics.selection();
            setState(() {
              _costController.text = priceStr;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '+ S/ $priceStr',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _saveRepair() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un cliente'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final cost =
          double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0.0;
      final partCost = _partCostController.text.trim().isNotEmpty
          ? double.tryParse(_partCostController.text.replaceAll(',', '.'))
          : null;
      final finalBrand = _selectedBrand == 'Otra marca'
          ? _brandController.text.trim()
          : (_selectedBrand ?? '');
      final condition = _conditionController.text.trim().isEmpty
          ? 'Sin observaciones'
          : _conditionController.text.trim();

      final repair = Repair(
        id: '',
        clientId: _selectedClientId!,
        clientName: _selectedClientName!,
        deviceBrand: finalBrand,
        deviceModel: _modelController.text.trim(),
        imei: _imeiController.text.trim(),
        reportedProblem: _problemController.text.trim(),
        physicalCondition: condition,
        internalNotes: '',
        status: RepairStatus.received,
        repairCost: cost,
        partCostPrice: partCost,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(repairsRepositoryProvider).add(repair);

      if (mounted) {
        context.pop(); // Close form screen right away!
        AppToast.show(
          context,
          message: '¡Reparación registrada para ${repair.clientName}!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Error al registrar reparación: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addQuickCondition(String cond) {
    AppHaptics.selection();
    setState(() {
      if (_conditionController.text.isEmpty) {
        _conditionController.text = cond;
      } else {
        if (!_conditionController.text.contains(cond)) {
          _conditionController.text = '${_conditionController.text}, $cond';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Nueva Reparación', style: AppTextStyles.titleLarge),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.primaryBlue),
              onPressed: _saveRepair,
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
              // Section 1: Cliente
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.accentLightBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cliente',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentLightBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientController,
                      readOnly: true,
                      onTap: _selectClient,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Selecciona un cliente'
                          : null,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Buscar o crear cliente...',
                        prefixIcon: Icon(Icons.search_rounded),
                        suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 2: Equipo
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_android_rounded,
                          color: AppColors.accentLightBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información del Equipo',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentLightBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Marca del Celular',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBrandSelector(),
                    if (_selectedBrand == 'Otra marca') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _brandController,
                        textInputAction: TextInputAction.next,
                        validator: (val) =>
                            (_selectedBrand == 'Otra marca' &&
                                (val == null || val.isEmpty))
                            ? 'Ingresa la marca'
                            : null,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Escribe la marca personalizada',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Modelo',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _modelController,
                      textInputAction: TextInputAction.next,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Ingresa el modelo'
                          : null,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. Galaxy A54, iPhone 15',
                        prefixIcon: Icon(Icons.mobile_friendly_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'IMEI (Opcional)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _imeiController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. 35xxxxxxxxxxxxx',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 3: Diagnóstico y Condición
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.handyman_rounded,
                          color: AppColors.accentLightBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Diagnóstico & Condición',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentLightBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Problema reportado por el cliente',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _problemController,
                      maxLines: 3,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Describe el problema del equipo'
                          : null,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. Pantalla no da imagen, no carga...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Condición física del equipo (Opcional)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _conditionController,
                      maxLines: 2,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. rayones, golpes, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Toca para agregar observaciones rápidas:',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _quickConditions.map((cond) {
                        return InkWell(
                          onTap: () => _addQuickCondition(cond),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceBlue.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              '+ $cond',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.textLightGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section 4: Costos & Repuesto Comprado
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: AppColors.accentLightBlue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Presupuesto & Costo del Repuesto',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentLightBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Precio a cobrar (S/)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (double.tryParse(val.replaceAll(',', '.')) == null) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'S/ ',
                        hintText: '0.00',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBudgetPresets(),
                    const SizedBox(height: 16),
                    Text(
                      'Costo del repuesto comprado (Opcional)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _partCostController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        prefixText: 'S/ ',
                        hintText: 'Ej. 45.00',
                        border: OutlineInputBorder(),
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
                          _saveRepair();
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
                      : const Icon(Icons.check_circle_rounded, size: 22),
                  label: const Text('Registrar Reparación'),
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
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
