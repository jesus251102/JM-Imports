import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jm_imports/core/services/ticket_pdf_service.dart';
import 'package:jm_imports/core/services/whatsapp_service.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/status_badge.dart';
import 'package:jm_imports/features/clients/domain/client.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/repairs/domain/repair.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/repairs/data/firestore_repairs_repository.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/features/inventory/data/firestore_inventory_repository.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
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
            message:
                'Repuesto retirado de la reparación y devuelto al inventario',
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
          decoration: const InputDecoration(
            labelText: 'Costo del Repuesto (S/)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monetization_on_outlined),
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
          decoration: const InputDecoration(
            labelText: 'Costo de Reparación / Presupuesto (S/)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
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

  void _confirmDelete(BuildContext context, Repair repair) {
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
                  AppToast.show(this.context, message: 'Reparación eliminada');
                  if (this.context.mounted) {
                    this.context.pop();
                  }
                }
              } catch (e) {
                if (mounted) {
                  AppToast.show(
                    this.context,
                    message: 'Error: $e',
                    isError: true,
                  );
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
            decoration: const InputDecoration(
              labelText: 'Número de WhatsApp',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_android_rounded),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Seleccionar repuesto',
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
                                  title: Text(
                                    '${part.brand} ${part.model}',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  subtitle: Text(
                                    'Calidad: ${part.quality} | Precio: S/ ${part.costPrice}',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  trailing: Text(
                                    'Stock: ${part.stock}',
                                    style: AppTextStyles.labelLarge,
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
                                            content: Text('Repuesto asignado'),
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

        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            title: Text('Reparación', style: AppTextStyles.titleLarge),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.accentLightBlue,
                ),
                tooltip: 'Imprimir Ticket PDF',
                onPressed: () => _generateTicket(repair),
              ),
              IconButton(
                icon: const Icon(Icons.chat_rounded, color: AppColors.success),
                tooltip: 'Enviar por WhatsApp',
                onPressed: () => _sendWhatsApp(repair),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => _confirmDelete(context, repair),
              ),
            ],
          ),
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Action Bar: PDF & WhatsApp
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _generateTicket(repair),
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Ticket PDF',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _sendWhatsApp(repair),
                          icon: const Icon(
                            Icons.chat_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'WhatsApp',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF25D366,
                            ), // WhatsApp Green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${repair.deviceBrand} ${repair.deviceModel}',
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    StatusBadge(
                      label: repair.status.label,
                      color: repair.status.color,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          StatusChangeSheet.show(context, ref, repair),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Cliente
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cliente', style: AppTextStyles.titleLarge),
                    InkWell(
                      onTap: () async {
                        AppHaptics.selection();
                        final clients =
                            ref.read(clientsStreamProvider).value ?? [];
                        final client = clients.firstWhere(
                          (c) =>
                              c.id == repair.clientId ||
                              c.name.toLowerCase() ==
                                  repair.clientName.toLowerCase(),
                          orElse: () => Client(
                            id: repair.clientId,
                            name: repair.clientName,
                            createdAt: DateTime.now(),
                          ),
                        );
                        final updated = await ClientFormDialog.show(
                          context,
                          client: client,
                        );
                        if (updated == true && mounted) {
                          AppToast.show(
                            this.context,
                            message: 'Cliente actualizado',
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
                              size: 16,
                              color: AppColors.accentLightBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Editar cliente',
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
                const SizedBox(height: 8),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 32,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          repair.clientName,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Equipo
                Text('Equipo', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Marca:', repair.deviceBrand),
                      const SizedBox(height: 8),
                      _buildInfoRow('Modelo:', repair.deviceModel),
                      if (repair.imei != null && repair.imei!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('IMEI:', repair.imei!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Problema y Condición
                Text('Problema reportado', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Text(
                    repair.reportedProblem,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),

                Text('Condición de ingreso', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Text(
                    repair.physicalCondition,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),

                // Notas Internas
                Text('Notas internas', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _notesController,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Añadir notas internas (visibles solo para técnicos)...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textLightGray.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _isNotesDirty = val != repair.internalNotes;
                          });
                        },
                      ),
                      if (_isNotesDirty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(repairsRepositoryProvider)
                                    .updateNotes(
                                      repair.id,
                                      _notesController.text,
                                    );
                                setState(() {
                                  _isNotesDirty = false;
                                });
                                if (mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Notas guardadas'),
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
                            child: const Text('Guardar'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Repuesto Utilizado
                Text('Repuesto utilizado', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child:
                      (repair.partUsedId != null &&
                          repair.partUsedId!.isNotEmpty &&
                          repair.partUsedName != null &&
                          repair.partUsedName!.isNotEmpty)
                      ? Row(
                          children: [
                            const Icon(
                              Icons.settings_suggest,
                              color: AppColors.accentLightBlue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    repair.partUsedName ?? 'Repuesto',
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  Text(
                                    'Costo: S/ ${(repair.partCostPrice ?? 0).toStringAsFixed(2)}',
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
                                size: 20,
                              ),
                              tooltip: 'Modificar costo del repuesto',
                              onPressed: () => _editPartCostPrice(repair),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              tooltip:
                                  'Quitar repuesto y devolver al inventario',
                              onPressed: () => _removeSparePart(repair),
                            ),
                          ],
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _selectSparePart(repair),
                          icon: const Icon(Icons.add),
                          label: const Text('Seleccionar repuesto'),
                        ),
                ),
                const SizedBox(height: 24),

                // Costos y Rentabilidad
                Text('Costos & Utilidad', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      // Cobrado al cliente
                      Row(
                        children: [
                          const Icon(
                            Icons.sell_rounded,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cobrado al cliente:',
                              style: AppTextStyles.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _editRepairCost(repair),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'S/ ${repair.repairCost.toStringAsFixed(2)}',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Costo repuesto comprado
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_rounded,
                            size: 18,
                            color: AppColors.accentLightBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Costo repuesto:',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLightGray,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _editPartCostPrice(repair),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (repair.partCostPrice != null &&
                                        repair.partCostPrice! > 0)
                                    ? AppColors.backgroundDark
                                    : AppColors.accentLightBlue.withValues(
                                        alpha: 0.15,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      (repair.partCostPrice != null &&
                                          repair.partCostPrice! > 0)
                                      ? AppColors.divider
                                      : AppColors.accentLightBlue.withValues(
                                          alpha: 0.4,
                                        ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (repair.partCostPrice != null &&
                                      repair.partCostPrice! > 0) ...[
                                    Text(
                                      'S/ ${repair.partCostPrice!.toStringAsFixed(2)}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: AppColors.accentLightBlue,
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.add,
                                      size: 14,
                                      color: AppColors.accentLightBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Añadir costo',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.accentLightBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Ganancia neta
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 18,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ganancia neta:',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'S/ ${(repair.repairCost - (repair.partCostPrice ?? 0)).toStringAsFixed(2)}',
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
                const SizedBox(height: 24),

                // Fechas
                Text('Fechas', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Ingreso:',
                        dateFormat.format(repair.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Última act.:',
                        dateFormat.format(repair.updatedAt),
                      ),
                      if (repair.deliveredAt != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Entregado:',
                          dateFormat.format(repair.deliveredAt!),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLightGray,
            ),
          ),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ],
    );
  }
}
