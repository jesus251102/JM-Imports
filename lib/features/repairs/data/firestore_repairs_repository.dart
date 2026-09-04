import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repair.dart';
import '../domain/repair_status.dart';

final repairsRepositoryProvider = Provider<FirestoreRepairsRepository>((ref) {
  return FirestoreRepairsRepository();
});

class FirestoreRepairsRepository {
  final CollectionReference _collection = FirebaseFirestore.instance.collection('repairs');

  /// Watch all repairs ordered by update time descending.
  Stream<List<Repair>> watchAll() {
    return _collection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Repair.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Watch repairs filtered by a specific status.
  Stream<List<Repair>> watchByStatus(RepairStatus status) {
    return _collection
        .where('status', isEqualTo: status.value)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Repair.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Watch active repairs (status != delivered), sorted by updatedAt descending.
  Stream<List<Repair>> watchActive() {
    return _collection
        .where('status', isNotEqualTo: RepairStatus.delivered.value)
        .snapshots()
        .map((snapshot) {
      final repairs = snapshot.docs
          .map((doc) => Repair.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      repairs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return repairs;
    });
  }

  /// Add a new repair instantly.
  Future<String> add(Repair repair) async {
    final docRef = _collection.doc();
    final data = repair.toMap();
    docRef.set(data).catchError((e) {});
    return docRef.id;
  }

  /// Update an existing repair fully.
  Future<void> update(Repair repair) async {
    final docRef = _collection.doc(repair.id);
    final updatedRepair = repair.copyWith(
      updatedAt: DateTime.now(),
      deliveredAt: repair.status == RepairStatus.delivered ? (repair.deliveredAt ?? repair.createdAt) : null,
    );
    final data = updatedRepair.toMap();
    docRef.set(data, SetOptions(merge: true)).catchError((e) {});
  }

  /// Remove spare part used from repair in Firestore.
  Future<void> removeSparePart(String repairId) async {
    final docRef = _collection.doc(repairId);
    final updateData = {
      'partUsedId': FieldValue.delete(),
      'partUsedName': FieldValue.delete(),
      'partCostPrice': FieldValue.delete(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    docRef.update(updateData).catchError((e) {});
  }

  /// Update only the status and its corresponding metadata.
  Future<void> updateStatus(String id, RepairStatus newStatus) async {
    final now = DateTime.now();
    final Map<String, dynamic> data = {
      'status': newStatus.value,
      'updatedAt': Timestamp.fromDate(now),
    };
    
    if (newStatus == RepairStatus.delivered) {
      data['deliveredAt'] = Timestamp.fromDate(now);
    } else {
      data['deliveredAt'] = FieldValue.delete();
    }
    
    final docRef = _collection.doc(id);
    docRef.update(data).catchError((e) {});
  }

  /// Update only the internal notes for a repair.
  Future<void> updateNotes(String id, String notes) async {
    final docRef = _collection.doc(id);
    final data = {
      'internalNotes': notes,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    docRef.update(data).catchError((e) {});
  }

  /// Delete a repair.
  Future<void> delete(String id) async {
    final docRef = _collection.doc(id);
    docRef.delete().catchError((e) {});
  }

  /// Watch recent repairs with a specific limit for Dashboard efficiency.
  Stream<List<Repair>> watchRecent(int limit) {
    return _collection
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Repair.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Conteo atómico en servidor de reparaciones por estado (1 sola lectura)
  Future<int> countByStatus(RepairStatus status) async {
    try {
      final snapshot = await _collection.where('status', isEqualTo: status.value).count().get();
      return snapshot.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Get a single repair by ID.
  Future<Repair?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get().timeout(const Duration(seconds: 3));
      if (doc.exists && doc.data() != null) {
        return Repair.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (_) {
      final doc = await _collection.doc(id).get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        return Repair.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
    }
    return null;
  }
}
