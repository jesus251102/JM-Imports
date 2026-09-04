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
import 'package:jm_imports/core/widgets/empty_state.dart';
import 'package:jm_imports/features/clients/domain/client.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/sales/data/firestore_sales_repository.dart';
import 'package:jm_imports/core/widgets/app_speed_dial.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';
import 'package:jm_imports/features/sales/presentation/sales_provider.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime date) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return format.format(date);
  }

  Future<void> _confirmReturnSale(Sale sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            const Icon(Icons.undo_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Devolver Repuesto', style: AppTextStyles.titleLarge),
          ],
        ),
        content: Text(
          '¿Confirmas la devolución de esta venta?\n\n'
          '• El stock de los repuestos se reingresará automáticamente al inventario (+stock).\n'
          '• La ganancia de esta venta se descontará del Dashboard.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Confirmar Devolución'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(salesRepositoryProvider).returnSale(sale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devolución registrada. Stock reingresado al inventario.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar devolución: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesState = ref.watch(filteredSalesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o producto...',
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLightGray.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(salesSearchQueryProvider.notifier).state = val;
                },
              )
            : const Text('Ventas de Mostrador'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(salesSearchQueryProvider.notifier).state = '';
                }
              });
            },
          ),
        ],
      ),
      body: salesState.when(
        data: (sales) {
          if (sales.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Sin ventas registradas',
              subtitle: 'Registra tus ventas de repuestos en mostrador a técnicos o clientes.',
              actionLabel: 'Nueva Venta',
              onAction: () => context.push('/sales/new'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 80.0),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              final itemCount = sale.items.fold(0, (sum, item) => sum + item.quantity);

              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Client & Date & Action/Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (sale.isReturned ? AppColors.warning : AppColors.success).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            sale.isReturned ? Icons.undo_rounded : Icons.point_of_sale_rounded,
                            color: sale.isReturned ? AppColors.warning : AppColors.success,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sale.clientName,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    _formatDateTime(sale.createdAt),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLightGray.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• $itemCount ${itemCount == 1 ? 'prod.' : 'prods.'}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.accentLightBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (sale.isReturned)
                          const StatusBadge(label: 'Devuelto', color: AppColors.warning)
                        else
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textLightGray),
                            onSelected: (val) async {
                              if (val == 'pdf') {
                                TicketPdfService.printOrShareSaleReceipt(sale);
                              } else if (val == 'whatsapp') {
                                final clientsAsync = ref.read(clientsStreamProvider);
                                final clients = clientsAsync.value ?? [];
                                final client = clients.firstWhere(
                                  (c) => c.id == sale.clientId || c.name == sale.clientName,
                                  orElse: () => Client(id: '', name: '', phone: '', createdAt: DateTime.now()),
                                );

                                String phone = client.phone;
                                if (phone.isEmpty) {
                                  final phoneController = TextEditingController();
                                  final enteredPhone = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.surfaceDark,
                                      title: Text('Ingresar WhatsApp del Cliente', style: AppTextStyles.titleMedium),
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
                                        TextButton(onPressed: () => context.pop(), child: const Text('Cancelar')),
                                        FilledButton(
                                          onPressed: () => context.pop(phoneController.text.trim()),
                                          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                                          child: const Text('Enviar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (enteredPhone == null || enteredPhone.isEmpty) return;
                                  phone = enteredPhone;
                                }
                                WhatsAppService.sendSaleReceipt(sale: sale, clientPhone: phone);
                              } else if (val == 'return') {
                                _confirmReturnSale(sale);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'pdf',
                                child: Row(
                                  children: [
                                    const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentLightBlue, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Imprimir Comprobante PDF', style: AppTextStyles.bodyMedium),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'whatsapp',
                                child: Row(
                                  children: [
                                    const Icon(Icons.chat_rounded, color: AppColors.success, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Enviar por WhatsApp', style: AppTextStyles.bodyMedium),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'return',
                                child: Row(
                                  children: [
                                    const Icon(Icons.undo_rounded, color: AppColors.warning, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Devolver repuesto / Anular', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.warning)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 10),

                    // Items list preview
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sale.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: sale.isReturned ? AppColors.textLightGray : AppColors.accentLightBlue,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.sparePartName}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textLightGray,
                                    decoration: sale.isReturned ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'S/ ${item.totalPrice.toStringAsFixed(2)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: sale.isReturned ? AppColors.textLightGray : Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 10),

                    // Footer: Total & Profit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Venta',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textLightGray,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              'S/ ${sale.totalAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: sale.isReturned ? AppColors.textLightGray : AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                decoration: sale.isReturned ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ],
                        ),
                        if (!sale.isReturned)
                          StatusBadge(
                            label: 'Ganancia: S/ ${sale.profit.toStringAsFixed(2)}',
                            color: AppColors.success,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
        ),
      ),
      floatingActionButton: const AppSpeedDial(),
    );
  }
}
