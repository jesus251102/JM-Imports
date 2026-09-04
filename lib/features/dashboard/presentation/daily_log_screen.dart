import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:jm_imports/core/services/ticket_pdf_service.dart';
import 'package:jm_imports/core/services/whatsapp_service.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/app_shimmer.dart';
import 'package:jm_imports/core/widgets/empty_state.dart';
import 'package:jm_imports/core/widgets/status_badge.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';

import 'daily_log_provider.dart';

enum LogFilter { all, financialOnly, receivedOnly }

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  LogFilter _currentFilter = LogFilter.all;

  String _formatSpanishDate(DateTime date) {
    const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];
    return '$dayName ${date.day} de $monthName, ${date.year}';
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return 'S/ ${formatter.format(amount)}';
  }

  void _previousDay(DateTime currentDate) {
    AppHaptics.selection();
    final prev = currentDate.subtract(const Duration(days: 1));
    ref.read(selectedDailyLogDateProvider.notifier).state = prev;
  }

  void _nextDay(DateTime currentDate) {
    AppHaptics.selection();
    final next = currentDate.add(const Duration(days: 1));
    ref.read(selectedDailyLogDateProvider.notifier).state = next;
  }

  Future<void> _pickDate(BuildContext context, DateTime currentDate) async {
    AppHaptics.selection();
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              surface: AppColors.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(selectedDailyLogDateProvider.notifier).state = picked;
    }
  }

  Future<void> _shareClosureWhatsApp(DailyLogSummary summary) async {
    AppHaptics.selection();
    final dateStr = DateFormat('dd/MM/yyyy').format(summary.date);

    final buffer = StringBuffer();
    buffer.writeln('📋 *CIERRE DE CAJA DIARIO - JM IMPORTS*');
    buffer.writeln('📅 *Fecha:* $dateStr\n');

    buffer.writeln('💵 *Total Recaudado:* ${_formatCurrency(summary.totalRevenue)}');
    buffer.writeln('📉 *Costo Repuestos/Stock:* ${_formatCurrency(summary.totalCost)}');
    buffer.writeln('📈 *Ganancia Neta Limpia:* ${_formatCurrency(summary.totalProfit)}\n');

    buffer.writeln('📊 *Resumen de Operaciones (${summary.totalOperations}):*');
    buffer.writeln('• 📱 Equipos recibidos: ${summary.equipmentsReceivedCount}');
    buffer.writeln('• ✅ Equipos entregados: ${summary.equipmentsDeliveredCount}');
    buffer.writeln('• 🛒 Ventas directas POS: ${summary.salesCount}\n');

    if (summary.transactions.isNotEmpty) {
      buffer.writeln('📝 *Detalle de Transacciones:*');
      for (final t in summary.transactions) {
        final timeStr = DateFormat('HH:mm').format(t.timestamp);
        if (t.type == TransactionType.repairDelivered) {
          buffer.writeln('• [$timeStr] ✅ ${t.title} - ${_formatCurrency(t.amount)} (Cliente: ${t.clientName})');
        } else if (t.type == TransactionType.saleCompleted) {
          buffer.writeln('• [$timeStr] 🛒 ${t.title} - ${_formatCurrency(t.amount)} (Cliente: ${t.clientName})');
        } else if (t.type == TransactionType.repairReceived) {
          buffer.writeln('• [$timeStr] 🛠️ ${t.title} (Cliente: ${t.clientName})');
        }
      }
    }

    buffer.writeln('\n🟢 *JM Imports - Taller Activo*');

    await WhatsAppService.launchWhatsApp(
      '',
      buffer.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDailyLogDateProvider);
    final logAsync = ref.watch(dailyLogProvider(selectedDate));
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registro & Cierre Diario', style: AppTextStyles.titleLarge),
            Text(
              isToday ? 'Día de Hoy' : DateFormat('dd/MM/yyyy').format(selectedDate),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue),
            tooltip: 'Seleccionar fecha',
            onPressed: () => _pickDate(context, selectedDate),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Bar de Navegación por Fechas (< Fecha >)
            Container(
              color: AppColors.surfaceDark,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                    onPressed: () => _previousDay(selectedDate),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(context, selectedDate),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Column(
                          children: [
                            Text(
                              _formatSpanishDate(selectedDate),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (isToday)
                              Text(
                                '• En curso hoy •',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: isToday ? AppColors.textLightGray.withValues(alpha: 0.3) : Colors.white,
                    ),
                    onPressed: isToday ? null : () => _nextDay(selectedDate),
                  ),
                ],
              ),
            ),

            // 2. Contenido Principal
            Expanded(
              child: logAsync.when(
                loading: () => const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AppShimmer(height: 140, width: double.infinity),
                      SizedBox(height: 16),
                      AppShimmer(height: 300, width: double.infinity),
                    ],
                  ),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error al cargar el registro diario:\n$err',
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (summary) {
                  // Filtrar transacciones según el filtro seleccionado
                  final filteredTransactions = summary.transactions.where((t) {
                    if (_currentFilter == LogFilter.financialOnly) {
                      return t.type == TransactionType.repairDelivered || t.type == TransactionType.saleCompleted;
                    }
                    if (_currentFilter == LogFilter.receivedOnly) {
                      return t.type == TransactionType.repairReceived;
                    }
                    return true;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      AppHaptics.lightImpact();
                      ref.invalidate(dailyLogProvider(selectedDate));
                    },
                    color: AppColors.primaryBlue,
                    backgroundColor: AppColors.surfaceDark,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2.1 Hero Daily Cash Summary Card
                          _buildDailySummaryCard(summary, context),
                          const SizedBox(height: 20),

                          // 2.2 Botón de Compartir Cierre WhatsApp
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _shareClosureWhatsApp(summary),
                              icon: const Icon(Icons.chat_rounded, color: AppColors.success, size: 18),
                              label: const Text('Exportar Cierre por WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.success,
                                side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2.3 Filter Chips Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Operaciones del Día', style: AppTextStyles.titleMedium),
                              Text(
                                '${filteredTransactions.length} registro${filteredTransactions.length == 1 ? '' : 's'}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Filter Segmented Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip(LogFilter.all, 'Todos (${summary.transactions.length})'),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  LogFilter.financialOnly,
                                  'Cobros & Ventas (${summary.equipmentsDeliveredCount + summary.salesCount})',
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  LogFilter.receivedOnly,
                                  'Recibidos (${summary.equipmentsReceivedCount})',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2.4 Activity List (Chronological Timeline)
                          if (filteredTransactions.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: EmptyState(
                                icon: Icons.history_rounded,
                                title: 'Sin operaciones registradas',
                                subtitle: 'No hay transacciones que coincidan con este filtro para la fecha seleccionada.',
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredTransactions.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filteredTransactions[index];
                                return _buildTransactionItemCard(item, context);
                              },
                            ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(LogFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          AppHaptics.selection();
          setState(() => _currentFilter = filter);
        }
      },
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.surfaceDark,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textLightGray,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(DailyLogSummary summary, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESUMEN FINANCIERO DEL DÍA',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLightGray,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${summary.totalOperations} op.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total Recaudado / Ganancia / Costo
          Row(
            children: [
              // Total Recaudado
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Recaudado', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCurrency(summary.totalRevenue),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              const SizedBox(width: 12),

              // Ganancia Neta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ganancia Neta', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCurrency(summary.totalProfit),
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: AppColors.divider),
              const SizedBox(width: 12),

              // Costo Repuestos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Costo Insumos', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formatCurrency(summary.totalCost),
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),

          // Counts Breakdown (Recibidos, Entregados, Ventas)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCountBadge('📥 Recibidos', '${summary.equipmentsReceivedCount}', AppColors.primaryBlue),
              _buildCountBadge('✅ Entregados', '${summary.equipmentsDeliveredCount}', AppColors.success),
              _buildCountBadge('🛒 Ventas POS', '${summary.salesCount}', AppColors.accentLightBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textLightGray,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItemCard(DailyLogTransaction t, BuildContext context) {
    final timeStr = DateFormat('hh:mm a').format(t.timestamp);

    IconData icon;
    Color color;
    String badgeLabel;

    switch (t.type) {
      case TransactionType.repairReceived:
        icon = Icons.inbox_rounded;
        color = AppColors.primaryBlue;
        badgeLabel = 'Ingreso de Equipo';
        break;
      case TransactionType.repairDelivered:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        badgeLabel = 'Reparación Cobrada';
        break;
      case TransactionType.saleCompleted:
        icon = Icons.shopping_bag_rounded;
        color = AppColors.accentLightBlue;
        badgeLabel = 'Venta POS';
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        AppHaptics.selection();
        if (t.repair != null) {
          context.push('/repairs/${t.repair!.id}');
        } else if (t.sale != null) {
          _showSaleDetailBottomSheet(context, t.sale!);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        t.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Cliente: ${t.clientName.isNotEmpty ? t.clientName : 'Cliente Ocasional'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLightGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (t.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    t.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightGray.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (t.amount > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(t.amount),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (t.profit > 0)
                  Text(
                    'Ganancia: ${_formatCurrency(t.profit)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                  ),
              ],
            )
          else
            StatusBadge(
              label: badgeLabel,
              color: color,
            ),
        ],
      ),
    );
  }

  void _showSaleDetailBottomSheet(BuildContext context, Sale sale) {
    AppHaptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentLightBlue.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_bag_rounded, color: AppColors.accentLightBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detalle de Venta POS', style: AppTextStyles.titleMedium),
                          Text(
                            DateFormat('dd/MM/yyyy - hh:mm a').format(sale.createdAt),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 12),

                // Client Name
                Text('Cliente: ${sale.clientName}', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),

                // Items Table Header
                Text('PRODUCTOS VENDIDOS (${sale.items.length})', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Items list
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: sale.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Text('${item.quantity}x', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentLightBlue, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.sparePartName, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
                            ),
                            Text(
                              'S/ ${(item.quantity * item.unitSalePrice).toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Cobrado:', style: AppTextStyles.titleMedium),
                    Text(_formatCurrency(sale.totalAmount), style: AppTextStyles.titleLarge.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ganancia Neta:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
                    Text(_formatCurrency(sale.profit), style: AppTextStyles.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.pop();
                          TicketPdfService.printOrShareSaleReceipt(sale);
                        },
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Imprimir Ticket'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Cerrar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
