import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/constants/app_constants.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/repairs/data/firestore_repairs_repository.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';

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

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_search_rounded,
                                  color: AppColors.accentLightBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Seleccionar Cliente',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                horizontal: 10,
                                vertical: 6,
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o teléfono...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLightGray.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.accentLightBlue,
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
                                      _getInitials(client.name),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    client.name,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  subtitle: Text(
                                    client.phone.isNotEmpty
                                        ? client.phone
                                        : 'Sin teléfono',
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
                  : AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.accentLightBlue
                    : AppColors.divider,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accentLightBlue.withValues(
                          alpha: 0.25,
                        ),
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
                        ? AppColors.accentLightBlue
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
        context.pop();
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
    final costVal =
        double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0.0;
    final partCostVal =
        double.tryParse(_partCostController.text.replaceAll(',', '.')) ?? 0.0;
    final liveProfit = costVal - partCostVal;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          'Nueva Reparación',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
              icon: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
              onPressed: _saveRepair,
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Header Banner
              _buildHeroHeaderBanner(),
              const SizedBox(height: 20),

              // 2. Section 1: Cliente VIP Card
              _buildClientSection(),
              const SizedBox(height: 20),

              // 3. Section 2: Equipo Ficha Card
              _buildDeviceSection(),
              const SizedBox(height: 20),

              // 4. Section 3: Diagnóstico y Condición Card
              _buildDiagnosisSection(),
              const SizedBox(height: 20),

              // 5. Section 4: Costos & Rentabilidad en Vivo
              _buildFinancialSection(liveProfit),
              const SizedBox(height: 28),

              // 6. Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeroHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceDark,
            AppColors.primaryBlue.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accentLightBlue.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: AppColors.accentLightBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registro de Nueva Reparación',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ingresa la información técnica y del cliente',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: RepairStatus.received.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RepairStatus.received.color),
                ),
                child: Text(
                  RepairStatus.received.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: RepairStatus.received.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
    final hasClient =
        _selectedClientId != null && _selectedClientId!.isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_pin_rounded,
                    color: AppColors.accentLightBlue,
                    size: 20,
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
              if (hasClient)
                InkWell(
                  onTap: _selectClient,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sync_alt_rounded,
                          size: 15,
                          color: AppColors.accentLightBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cambiar',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentLightBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasClient)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accentLightBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(
                      _getInitials(_selectedClientName ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedClientName ?? '',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cliente seleccionado',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _selectClient,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accentLightBlue.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_search_rounded,
                      color: AppColors.accentLightBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Buscar o Crear Cliente',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accentLightBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smartphone_rounded,
                color: AppColors.accentLightBlue,
                size: 20,
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
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Escribe la marca personalizada',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLightGray.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentLightBlue,
                  ),
                ),
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
            validator: (val) =>
                val == null || val.isEmpty ? 'Ingresa el modelo' : null,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Galaxy A54, iPhone 15 Pro',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLightGray.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(
                Icons.mobile_friendly_rounded,
                color: AppColors.accentLightBlue,
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentLightBlue),
              ),
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
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: 35xxxxxxxxxxxxx',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLightGray.withValues(alpha: 0.5),
              ),
              prefixIcon: const Icon(
                Icons.qr_code_rounded,
                color: AppColors.accentLightBlue,
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentLightBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisSection() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handyman_rounded,
                color: AppColors.accentLightBlue,
                size: 20,
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
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Pantalla no da imagen, cambio de batería...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLightGray.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentLightBlue),
              ),
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
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: rayones leves en pantalla, golpes en bordes...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLightGray.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.accentLightBlue),
              ),
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
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accentLightBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '+ $cond',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.accentLightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSection(double liveProfit) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.accentLightBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Presupuesto & Rentabilidad',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentLightBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Precio a Cobrar (S/)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentLightBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _costController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Ingresa el monto';
              if (double.tryParse(val.replaceAll(',', '.')) == null) {
                return 'Número inválido';
              }
              return null;
            },
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              prefixIcon: const Icon(
                Icons.sell_rounded,
                color: AppColors.success,
                size: 20,
              ),
              prefixText: 'S/ ',
              prefixStyle: AppTextStyles.titleLarge.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              hintStyle: AppTextStyles.titleLarge.copyWith(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.success),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.success.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.success,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildBudgetPresets(),
          const SizedBox(height: 16),

          Text(
            'Costo del Repuesto (Opcional)',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.accentLightBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _partCostController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              prefixIcon: const Icon(
                Icons.shopping_bag_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              prefixText: 'S/ ',
              prefixStyle: AppTextStyles.titleMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.bold,
              ),
              hintText: '0.00',
              hintStyle: AppTextStyles.titleMedium.copyWith(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: AppColors.backgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.warning),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Live Net Profit Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.success.withValues(alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GANANCIA NETA ESTIMADA',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'S/ ${liveProfit.toStringAsFixed(2)}',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.success,
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
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                width: 18,
                height: 18,
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
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            letterSpacing: 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
