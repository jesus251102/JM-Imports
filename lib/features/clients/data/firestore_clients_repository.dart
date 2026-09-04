import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/clients/domain/client.dart';

/// Repositorio para la gestión de clientes en Firestore
class FirestoreClientsRepository {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('clients');

  /// Obtiene un stream con todos los clientes ordenados por nombre alfabéticamente
  Stream<List<Client>> watchAll() {
    return _collection.orderBy('name', descending: false).snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return Client.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      },
    );
  }

  /// Añade un nuevo cliente instantáneamente usando un ID local
  Future<String> add(Client client) async {
    final docRef = _collection.doc();
    final clientWithId = client.id.isEmpty ? client.copyWith(id: docRef.id) : client;
    docRef.set(clientWithId.toMap()).catchError((e) {});
    return docRef.id;
  }

  /// Actualiza un cliente existente
  Future<void> update(Client client) async {
    final docRef = _collection.doc(client.id);
    docRef.set(client.toMap(), SetOptions(merge: true)).catchError((e) {});
  }

  /// Elimina un cliente por su ID
  Future<void> delete(String id) async {
    final docRef = _collection.doc(id);
    docRef.delete().catchError((e) {});
  }

  /// Obtiene un cliente por su ID
  Future<Client?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get().timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        return Client.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (_) {
      final doc = await _collection.doc(id).get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        return Client.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    }
    return null;
  }

  /// Conteo atómico en servidor de clientes registrados (1 sola lectura)
  Future<int> countAll() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }
}

/// Provider para el repositorio de clientes
final clientsRepositoryProvider = Provider<FirestoreClientsRepository>((ref) {
  return FirestoreClientsRepository();
});
