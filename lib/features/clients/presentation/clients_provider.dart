import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/clients/data/firestore_clients_repository.dart';
import 'package:jm_imports/features/clients/domain/client.dart';

/// Provider para el stream de clientes
final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  final repository = ref.watch(clientsRepositoryProvider);
  return repository.watchAll();
});

/// Provider para la consulta de búsqueda
final clientsSearchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Provider para la lista de clientes filtrada según la consulta de búsqueda
final filteredClientsProvider = Provider<AsyncValue<List<Client>>>((ref) {
  final clientsAsync = ref.watch(clientsStreamProvider);
  final searchQuery = ref.watch(clientsSearchQueryProvider).toLowerCase();

  return clientsAsync.whenData((clients) {
    if (searchQuery.isEmpty) {
      return clients;
    }
    
    return clients.where((client) {
      final nameMatch = client.name.toLowerCase().contains(searchQuery);
      final phoneMatch = client.phone.toLowerCase().contains(searchQuery);
      final dniMatch = client.dniRuc.toLowerCase().contains(searchQuery);
      return nameMatch || phoneMatch || dniMatch;
    }).toList();
  });
});
