import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:jm_imports/core/services/ticket_pdf_service.dart';
import 'package:jm_imports/core/services/whatsapp_service.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/features/clients/domain/client.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/inventory/data/firestore_inventory_repository.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/features/repairs/data/firestore_repairs_repository.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/repairs/presentation/status_change_sheet.dart';

class RepairDetailScreen extends ConsumerStatefulWidget {
  final String repairId;

  const RepairDetailScreen({super.key, required this.repairId});

  @override
  ConsumerState<RepairDetailScreen> createState() => _RepairDetailScreenState();
}

class _RepairDetailScreenState extends ConsumerState<RepairDetailScreen> {
  late TextEditingController _notesController;
  bool _isNotesDirty = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
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

  Future<void> _makePhoneCall(String rawPhone) async {
    final clean = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) {
      AppToast.show(
        context,
        message: 'El cliente no tiene un teléfono válido',
        isError: true,
      );
      return;
    }
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'No se pudo realizar la llamada: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _removeSparePart(Repair repair) async {
    if (repair.partUsedId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Quitar Repuesto', style: AppTextStyles.titleMedium),
        content: Text(
          '¿Deseas quitar "${repair.partUsedName}" de esta reparación? Se devolverá 1 unidad al inventario.',
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
            child: const Text('Quitar y Devolver Stock'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        if (repair.partUsedId != null && repair.partUsedId!.isNotEmpty) {
          await ref
              .read(inventoryRepositoryProvider)
              .incrementStock(repair.partUsedId!, 1);
        }

        await ref.read(repairsRepositoryProvider).removeSparePart(repair.id);

        if (mounted) {
          AppToast.show(
            context,
            message: 'Repuesto retirado y devuelto al inventario',
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Error al quitar repuesto: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _editPartCostPrice(Repair repair) async {
    final controller = TextEditingController(
      text: (repair.partCostPrice ?? 0.0).toStringAsFixed(2),
    );

    final newCost = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Modificar Costo del Repuesto',
          style: AppTextStyles.titleMedium,
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: 'Costo del Repuesto (S/)',
            labelStyle: AppTextStyles.labelLarge.copyWith(
              color: AppColors.accentLightBlue,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(
              Icons.monetization_on_outlined,
              color: AppColors.accentLightBlue,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              context.pop(val);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Guardar Costo'),
          ),
        ],
      ),
    );

    if (newCost != null && mounted) {
      try {
        final updatedRepair = repair.copyWith(
          partCostPrice: newCost,
          updatedAt: DateTime.now(),
        );
        await ref.read(repairsRepositoryProvider).update(updatedRepair);
        if (mounted) {
          AppToast.show(context, message: 'Costo del repuesto actualizado');
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Error al actualizar costo: $e',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _editRepairCost(Repair repair) async {
    final controller = TextEditingController(
      text: repair.repairCost.toStringAsFixed(2),
    );

    final newCost = await showDialog<double>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Modificar Presupuesto de Reparación',
          style: AppTextStyles.titleMedium,
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: 'Costo de Reparación (S/)',
            labelStyle: AppTextStyles.labelLarge.copyWith(
              color: AppColors.accentLightBlue,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(
              Icons.attach_money_rounded,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogCtx.pop(null),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.replaceAll(',', '.'));
              dialogCtx.pop(val);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Guardar Presupuesto'),
          ),
        ],
      ),
    );

    if (newCost != null && mounted) {
      try {
        final updatedRepair = repair.copyWith(
          repairCost: newCost,
          updatedAt: DateTime.now(),
        );
        await ref.read(repairsRepositoryProvider).update(updatedRepair);
        if (mounted) {
          AppToast.show(
            context,
            message: 'Presupuesto de reparación actualizado',
          );
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Error al actualizar presupuesto: $e',
            isError: true,
          );
        }
      }
    }
  }

  void _confirmDelete(Repair repair) {
    AppHaptics.warning();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Eliminar reparación', style: AppTextStyles.titleLarge),
        content: Text(
          '¿Estás seguro de que deseas eliminar esta reparación? Esta acción no se puede deshacer.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => dialogCtx.pop(),
            child: Text('Cancelar', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () async {
              dialogCtx.pop();
              try {
                await ref.read(repairsRepositoryProvider).delete(repair.id);
                if (mounted) {
                  AppToast.show(context, message: 'Reparación eliminada');
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  AppToast.show(context, message: 'Error: $e', isError: true);
                }
              }
            },
            child: Text(
              'Eliminar',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendWhatsApp(Repair repair) async {
    final clientsAsync = ref.read(clientsStreamProvider);
    final clients = clientsAsync.value ?? [];
    final client = clients.firstWhere(
      (c) => c.id == repair.clientId || c.name == repair.clientName,
      orElse: () =>
          Client(id: '', name: '', phone: '', createdAt: DateTime.now()),
    );

    String phone = client.phone;

    if (phone.isEmpty) {
      final phoneController = TextEditingController();
      final enteredPhone = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Ingresar WhatsApp del Cliente',
            style: AppTextStyles.titleMedium,
          ),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Número de WhatsApp',
              labelStyle: AppTextStyles.labelLarge.copyWith(
                color: AppColors.accentLightBlue,
                fontWeight: FontWeight.bold,
              ),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(
                Icons.phone_android_rounded,
                color: AppColors.accentLightBlue,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => context.pop(phoneController.text.trim()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: const Text('Enviar'),
            ),
          ],
        ),
      );
      if (enteredPhone == null || enteredPhone.isEmpty) return;
      phone = enteredPhone;
    }

    if (repair.status == RepairStatus.repaired ||
        repair.status == RepairStatus.delivered) {
      await WhatsAppService.sendRepairReady(repair: repair, clientPhone: phone);
    } else {
      await WhatsAppService.sendRepairReceipt(
        repair: repair,
        clientPhone: phone,
      );
    }
  }

  Future<void> _generateTicket(Repair repair) async {
    await TicketPdfService.printOrShareRepairTicket(repair);
  }

  Future<void> _selectSparePart(Repair repair) async {
    final partsAsync = ref.read(inventoryStreamProvider);

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return partsAsync.when(
              data: (parts) {
                final availableParts = parts.where((p) => p.stock > 0).toList();
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Seleccionar repuesto del inventario',
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: availableParts.isEmpty
                          ? Center(
                              child: Text(
                                'No hay repuestos en stock',
                                style: AppTextStyles.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: availableParts.length,
                              itemBuilder: (context, index) {
                                final part = availableParts[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryBlue
                                        .withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.memory_rounded,
                                      color: AppColors.accentLightBlue,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    '${part.brand} ${part.model}',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  subtitle: Text(
                                    'Calidad: ${part.quality} | Precio: S/ ${part.costPrice.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textLightGray,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Stock: ${part.stock}',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  onTap: () async {
                                    final navigator = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(
                                      this.context,
                                    );
                                    navigator.pop();
                                    try {
                                      final updatedRepair = repair.copyWith(
                                        partUsedId: part.id,
                                        partUsedName:
                                            '${part.brand} ${part.model} - ${part.quality}',
                                        partCostPrice: part.costPrice,
                                      );
                                      await ref
                                          .read(repairsRepositoryProvider)
                                          .update(updatedRepair);
                                      await ref
                                          .read(inventoryRepositoryProvider)
                                          .updateStock(part.id, part.stock - 1);

                                      if (mounted) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Repuesto asignado correctamente',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: AppColors.error,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Text('Error: $e', style: AppTextStyles.bodyMedium),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repairsAsync = ref.watch(allRepairsStreamProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);

    return repairsAsync.when(
      data: (repairs) {
        final repair = repairs.firstWhere(
          (r) => r.id == widget.repairId,
          orElse: () => Repair(
            id: '',
            clientId: '',
            clientName: 'No encontrado',
            deviceBrand: '',
            deviceModel: '',
            reportedProblem: '',
            physicalCondition: '',
            internalNotes: '',
            status: RepairStatus.received,
            repairCost: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (repair.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text(
                'Reparación no encontrada',
                style: AppTextStyles.titleLarge,
              ),
            ),
          );
        }

        if (!_isNotesDirty && _notesController.text != repair.internalNotes) {
          _notesController.text = repair.internalNotes;
        }

        final clients = clientsAsync.value ?? [];
        final client = clients.firstWhere(
          (c) =>
              c.id == repair.clientId ||
              c.name.toLowerCase() == repair.clientName.toLowerCase(),
          orElse: () => Client(
            id: repair.clientId,
            name: repair.clientName,
            phone: '',
            createdAt: DateTime.now(),
          ),
        );

        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        final netProfit = repair.repairCost - (repair.partCostPrice ?? 0);

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundDark,
            elevation: 0,
            title: Text(
              'Ficha de Reparación',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                tooltip: 'Eliminar reparación',
                onPressed: () => _confirmDelete(repair),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Device Header & Stepper
                _buildHeroHeader(repair),
                const SizedBox(height: 16),

                // 2. Stepper Timeline
                _buildStatusStepper(repair),
                const SizedBox(height: 20),

                // 3. Action Toolbar Buttons
                _buildQuickActionBar(repair, client),
                const SizedBox(height: 20),

                // 4. VIP Client Contact Card
                _buildClientCard(repair, client),
                const SizedBox(height: 20),

                // 5. Device Specs & Diagnosis Card
                _buildDeviceSpecsCard(repair),
                const SizedBox(height: 20),

                // 6. Financial Profitability Card
                _buildFinancialCard(repair, netProfit),
                const SizedBox(height: 20),

                // 7. Spare Part Section
                _buildSparePartCard(repair),
                const SizedBox(height: 20),

                // 8. Internal Notes Section
                _buildNotesCard(repair),
                const SizedBox(height: 20),

                // 9. Timestamps Card
                _buildAuditDatesCard(repair, dateFormat),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeroHeader(Repair repair) {
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentLightBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentLightBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'TICKET #${repair.id.substring(0, repair.id.length.clamp(0, 6)).toUpperCase()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentLightBlue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: repair.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: repair.status.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      repair.status.icon,
                      size: 14,
                      color: repair.status.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      repair.status.label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: repair.status.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${repair.deviceBrand} ${repair.deviceModel}',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(Repair repair) {
    final steps = RepairStatus.values;
    final currentIndex = steps.indexOf(repair.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.alt_route_rounded,
                    color: AppColors.accentLightBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Progreso de Reparación',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => StatusChangeSheet.show(context, ref, repair),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Cambiar',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accentLightBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.accentLightBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isPassed = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: InkWell(
                  onTap: () => StatusChangeSheet.show(context, ref, repair),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPassed
                                  ? step.color
                                  : AppColors.backgroundDark,
                              border: Border.all(
                                color: isPassed
                                    ? step.color
                                    : AppColors.divider,
                                width: isCurrent ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                if (isCurrent)
                                  BoxShadow(
                                    color: step.color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: isPassed && !isCurrent
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : isCurrent
                                  ? Icon(
                                      step.icon,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textLightGray,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 3,
                                color: index < currentIndex
                                    ? step.color
                                    : AppColors.divider.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? step.color
                              : isPassed
                              ? Colors.white
                              : AppColors.textLightGray.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBar(Repair repair, Client client) {
    return Row(
      children: [
        // Ticket PDF Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _generateTicket(repair),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Ticket PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // WhatsApp Button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _sendWhatsApp(repair),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Call Button
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.phone_rounded,
              color: AppColors.accentLightBlue,
            ),
            tooltip: 'Llamar cliente',
            onPressed: () => _makePhoneCall(client.phone),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(Repair repair, Client client) {
    final initials = _getInitials(repair.clientName);

    return AppCard(
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
                    'Cliente VIP',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.accentLightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () async {
                  AppHaptics.selection();
                  final updated = await ClientFormDialog.show(
                    context,
                    client: client,
                  );
                  if (updated == true && mounted) {
                    AppToast.show(
                      context,
                      message: 'Datos del cliente actualizados',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: AppColors.accentLightBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Editar',
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
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      repair.clientName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      client.phone.isNotEmpty
                          ? client.phone
                          : 'Sin número registrado',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                      ),
                    ),
                  ],
                ),
              ),
              if (client.phone.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.accentLightBlue,
                    size: 20,
                  ),
                  onPressed: () => _makePhoneCall(client.phone),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                  onPressed: () => _sendWhatsApp(repair),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSpecsCard(Repair repair) {
    return AppCard(
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
                'Ficha Técnica del Equipo',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accentLightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSpecRow('Marca:', repair.deviceBrand),
          const SizedBox(height: 8),
          _buildSpecRow('Modelo:', repair.deviceModel),
          if (repair.imei != null && repair.imei!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    'IMEI / Serie:',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLightGray,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    repair.imei!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: AppColors.accentLightBlue,
                  ),
                  tooltip: 'Copiar IMEI',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: repair.imei!));
                    AppToast.show(
                      context,
                      message: 'IMEI copiado al portapapeles',
                    );
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Problema Reportado Highlight Box
          Text(
            'Problema Reportado:',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.accentLightBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    repair.reportedProblem,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Condición de Ingreso Box
          if (repair.physicalCondition.isNotEmpty) ...[
            Text(
              'Condición de Ingreso:',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.accentLightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                repair.physicalCondition,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textLightGray,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLightGray,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard(Repair repair, double netProfit) {
    return AppCard(
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
                'Panel Financiero & Rentabilidad',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accentLightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Presupuesto Cobrado
              Expanded(
                child: InkWell(
                  onTap: () => _editRepairCost(repair),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Cobrado Cliente',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accentLightBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'S/ ${repair.repairCost.toStringAsFixed(2)}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Costo Repuesto
              Expanded(
                child: InkWell(
                  onTap: () => _editPartCostPrice(repair),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Costo Repuesto',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLightGray,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textLightGray,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'S/ ${(repair.partCostPrice ?? 0.0).toStringAsFixed(2)}',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ganancia Neta Big Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withValues(alpha: 0.2),
                  AppColors.success.withValues(alpha: 0.05),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GANANCIA NETA ESTIMADA',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'S/ ${netProfit.toStringAsFixed(2)}',
                      style: AppTextStyles.headlineMedium.copyWith(
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

  Widget _buildSparePartCard(Repair repair) {
    final hasPart =
        repair.partUsedId != null &&
        repair.partUsedId!.isNotEmpty &&
        repair.partUsedName != null &&
        repair.partUsedName!.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    color: AppColors.accentLightBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Repuesto del Almacén',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.accentLightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (hasPart)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: 'Quitar repuesto y devolver stock',
                  onPressed: () => _removeSparePart(repair),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasPart)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentLightBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_suggest_rounded,
                    color: AppColors.accentLightBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          repair.partUsedName ?? 'Repuesto',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Costo Repuesto: S/ ${(repair.partCostPrice ?? 0).toStringAsFixed(2)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLightGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.accentLightBlue,
                      size: 18,
                    ),
                    tooltip: 'Modificar costo',
                    onPressed: () => _editPartCostPrice(repair),
                  ),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _selectSparePart(repair),
              icon: const Icon(
                Icons.add_rounded,
                color: AppColors.accentLightBlue,
              ),
              label: Text(
                'Seleccionar repuesto del inventario',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accentLightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.accentLightBlue.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(Repair repair) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                color: AppColors.accentLightBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Notas Internas del Técnico',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accentLightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escribe observaciones del diagnóstico técnico...',
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
            onChanged: (val) {
              setState(() {
                _isNotesDirty = val != repair.internalNotes;
              });
            },
          ),
          if (_isNotesDirty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref
                        .read(repairsRepositoryProvider)
                        .updateNotes(repair.id, _notesController.text);
                    setState(() {
                      _isNotesDirty = false;
                    });
                    if (mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Notas guardadas correctamente'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Guardar Notas'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditDatesCard(Repair repair, DateFormat dateFormat) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.accentLightBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Historial & Fechas',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accentLightBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAuditRow(
            'Fecha de Ingreso:',
            dateFormat.format(repair.createdAt),
          ),
          const SizedBox(height: 6),
          _buildAuditRow(
            'Última Actualización:',
            dateFormat.format(repair.updatedAt),
          ),
          if (repair.deliveredAt != null) ...[
            const SizedBox(height: 6),
            _buildAuditRow(
              'Fecha de Entrega:',
              dateFormat.format(repair.deliveredAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLightGray,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
