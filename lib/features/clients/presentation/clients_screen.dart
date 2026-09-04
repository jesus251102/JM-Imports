import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/core/theme/app_colors.dart';
import 'package:jm_imports/core/theme/app_text_styles.dart';
import 'package:jm_imports/core/widgets/app_card.dart';
import 'package:jm_imports/core/widgets/empty_state.dart';
import 'package:jm_imports/core/widgets/app_toast.dart';
import 'package:jm_imports/core/utils/app_haptics.dart';
import 'package:jm_imports/features/clients/data/firestore_clients_repository.dart';
import 'package:jm_imports/features/clients/domain/client.dart';
import 'package:jm_imports/features/clients/presentation/client_form_dialog.dart';
import 'package:jm_imports/features/clients/presentation/clients_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(clientsSearchQueryProvider.notifier).state = '';
      }
    });
  }

  Future<void> _showClientDialog({Client? client}) async {
    AppHaptics.selection();
    final result = await ClientFormDialog.show(context, client: client);
    if (result == true && mounted) {
      AppToast.show(
        context,
        message: client == null ? 'Cliente guardado exitosamente' : 'Cliente actualizado correctamente',
      );
    }
  }

  Future<void> _confirmDeleteClient(BuildContext context, Client client) async {
    AppHaptics.warning();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar Cliente', style: AppTextStyles.titleMedium),
        content: Text(
          '¿Deseas eliminar a "${client.name}"? Esta acción no se puede deshacer.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(clientsRepositoryProvider).delete(client.id);
      if (mounted) {
        AppToast.show(this.context, message: 'Cliente eliminado');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClientsAsync = ref.watch(filteredClientsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o DNI...',
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textLightGray.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(clientsSearchQueryProvider.notifier).state = value;
                },
              )
            : Text('Directorio de Clientes', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: filteredClientsAsync.when(
        data: (clients) {
          if (clients.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: _searchController.text.isNotEmpty ? 'Sin resultados' : 'Sin clientes',
              subtitle: _searchController.text.isNotEmpty 
                  ? 'No se encontraron clientes para tu búsqueda' 
                  : 'Agrega tu primer cliente',
              actionLabel: 'Agregar cliente',
              onAction: () => _showClientDialog(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  '${clients.length} cliente${clients.length == 1 ? '' : 's'} registrado${clients.length == 1 ? '' : 's'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLightGray.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 80.0),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];

                    return AppCard(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      padding: const EdgeInsets.all(14),
                      onTap: () => _showClientDialog(client: client),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.name,
                                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 2,
                                  children: [
                                    if (client.phone.isNotEmpty) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone_android_rounded, size: 13, color: AppColors.textLightGray),
                                          const SizedBox(width: 4),
                                          Text(
                                            client.phone,
                                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLightGray, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (client.dniRuc.isNotEmpty) ...[
                                      Text(
                                        'DNI/RUC: ${client.dniRuc}',
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentLightBlue, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.accentLightBlue, size: 20),
                                tooltip: 'Editar cliente',
                                onPressed: () => _showClientDialog(client: client),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                tooltip: 'Eliminar cliente',
                                onPressed: () => _confirmDeleteClient(context, client),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error al cargar clientes: $error',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientDialog(),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
