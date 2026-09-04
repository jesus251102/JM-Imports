import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jm_imports/features/sales/domain/sale.dart';

final salesRepositoryProvider = Provider<FirestoreSalesRepository>((ref) {
  return FirestoreSalesRepository(ref);
});

class FirestoreSalesRepository {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreSalesRepository(this.ref);

  Stream<List<Sale>> watchAll() {
    return _firestore
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Sale.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> add(Sale sale) async {
    final batch = _firestore.batch();
    
    final saleRef = _firestore.collection('sales').doc();
    batch.set(saleRef, sale.toMap());

    for (final item in sale.items) {
      final partRef = _firestore.collection('spare_parts').doc(item.sparePartId);
      batch.update(partRef, {
        'stock': FieldValue.increment(-item.quantity),
      });
    }

    batch.commit().catchError((e) {});
  }

  Future<void> returnSale(Sale sale) async {
    if (sale.isReturned) return;

    final batch = _firestore.batch();

    // Mark sale status as returned
    final saleRef = _firestore.collection('sales').doc(sale.id);
    batch.update(saleRef, {
      'status': 'returned',
    });

    // Re-add stock for each spare part in the sale
    for (final item in sale.items) {
      final partRef = _firestore.collection('spare_parts').doc(item.sparePartId);
      batch.update(partRef, {
        'stock': FieldValue.increment(item.quantity),
      });
    }

    batch.commit().catchError((e) {});
  }
}
