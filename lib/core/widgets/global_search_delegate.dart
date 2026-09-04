import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/features/inventory/presentation/inventory_provider.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';
import 'package:jm_imports/features/repairs/presentation/repairs_provider.dart';
import 'package:jm_imports/features/repairs/domain/repair_status.dart';

class GlobalSearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;

  GlobalSearchDelegate(this.ref) : super(
    searchFieldLabel: 'Buscar repuestos, clientes o reparaciones...',
    searchFieldStyle: const TextStyle(color: Colors.white, fontSize: 16),
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceBlue,
        iconTheme: IconThemeData(color: AppColors.textLightGray),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLightGray.withValues(alpha: 0.5)),
        border: InputBorder.none,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: AppColors.textLightGray),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textLightGray),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return _buildSearchResults(context, ref);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Escribe para buscar...',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLightGray),
        ),
      );
    }
    return Consumer(
      builder: (context, ref, child) {
        return _buildSearchResults(context, ref);
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, WidgetRef ref) {
    final lowerQuery = query.toLowerCase();

    final inventoryState = ref.watch(inventoryStreamProvider);
    final clientsState = ref.watch(clientsStreamProvider);
    final repairsState = ref.watch(allRepairsStreamProvider);

    final List<Widget> results = [];

    // Inventario
    inventoryState.whenData((parts) {
      final filtered = parts.where((p) => 
        p.brand.toLowerCase().contains(lowerQuery) || 
        p.model.toLowerCase().contains(lowerQuery) ||
        p.quality.toLowerCase().contains(lowerQuery)
      ).toList();

      if (filtered.isNotEmpty) {
        results.add(Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Repuestos', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryBlue)),
        ));
        for (final part in filtered) {
          results.add(ListTile(
            leading: const Icon(Icons.inventory_2_rounded, color: AppColors.textLightGray),
            title: Text('${part.brand} ${part.model} [${part.category}] - ${part.quality}', style: AppTextStyles.bodyMedium),
            subtitle: Text('Stock: ${part.stock}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
            onTap: () {
              close(context, null);
              context.push('/inventory/${part.id}/edit');
            },
          ));
        }
      }
    });

    // Clientes
    clientsState.whenData((clients) {
      final filtered = clients.where((c) => 
        c.name.toLowerCase().contains(lowerQuery) || 
        c.phone.toLowerCase().contains(lowerQuery)
      ).toList();

      if (filtered.isNotEmpty) {
        results.add(Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Clientes', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryBlue)),
        ));
        for (final client in filtered) {
          results.add(ListTile(
            leading: const Icon(Icons.people_rounded, color: AppColors.textLightGray),
            title: Text(client.name, style: AppTextStyles.bodyMedium),
            subtitle: Text(client.phone, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
            onTap: () {
              close(context, null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cliente: ${client.name} - ${client.phone}')),
              );
            },
          ));
        }
      }
    });

    // Reparaciones
    repairsState.whenData((repairs) {
      final filtered = repairs.where((r) => 
        r.id.toLowerCase().contains(lowerQuery) ||
        r.clientName.toLowerCase().contains(lowerQuery) ||
        r.deviceModel.toLowerCase().contains(lowerQuery)
      ).toList();

      if (filtered.isNotEmpty) {
        results.add(Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Reparaciones', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primaryBlue)),
        ));
        for (final repair in filtered) {
          results.add(ListTile(
            leading: const Icon(Icons.build_rounded, color: AppColors.textLightGray),
            title: Text('${repair.deviceModel} - ${repair.clientName}', style: AppTextStyles.bodyMedium),
            subtitle: Text(repair.status.label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLightGray)),
            onTap: () {
              close(context, null);
              context.push('/repairs/${repair.id}');
            },
          ));
        }
      }
    });

    if (results.isEmpty && 
        !inventoryState.isLoading && 
        !clientsState.isLoading && 
        !repairsState.isLoading) {
      return Center(
        child: Text(
          'No se encontraron resultados',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLightGray),
        ),
      );
    }

    return ListView(children: results);
  }
}
