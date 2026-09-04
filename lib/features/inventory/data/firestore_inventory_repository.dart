import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/spare_part.dart';

final inventoryRepositoryProvider = Provider<FirestoreInventoryRepository>((ref) {
  return FirestoreInventoryRepository();
});

class FirestoreInventoryRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('spare_parts');

  Stream<List<SparePart>> watchAll() {
    return _collection.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return SparePart.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<String> add(SparePart part) async {
    final docRef = _collection.doc();
    final newPart = part.id.isEmpty ? part.copyWith(id: docRef.id) : part;
    docRef.set(newPart.toMap()).catchError((e) {});
    return docRef.id;
  }

  Future<void> update(SparePart part) async {
    final docRef = _collection.doc(part.id);
    docRef.set(part.toMap(), SetOptions(merge: true)).catchError((e) {});
  }

  Future<void> delete(String id) async {
    final docRef = _collection.doc(id);
    docRef.delete().catchError((e) {});
  }

  Future<void> updateStock(String id, int newStock) async {
    final docRef = _collection.doc(id);
    docRef.update({'stock': newStock}).catchError((e) {});
  }

  Future<void> incrementStock(String id, int delta) async {
    final docRef = _collection.doc(id);
    docRef.update({'stock': FieldValue.increment(delta)}).catchError((e) {});
  }

  Future<int> deleteOutOfStock() async {
    final snapshot = await _collection.where('stock', isLessThanOrEqualTo: 0).get();
    int count = 0;
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
      count++;
    }
    return count;
  }

  /// Conteo atómico en servidor de repuestos totales (1 sola lectura)
  Future<int> countAll() async {
    try {
      final snapshot = await _collection.count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Conteo atómico en servidor de productos con stock bajo (1 sola lectura)
  Future<int> countLowStock({int threshold = 2}) async {
    try {
      final snapshot = await _collection.where('stock', isLessThanOrEqualTo: threshold).count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
