import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jm_imports/features/sales/domain/sale_item.dart';

class Sale {
  final String id;
  final String? clientId;
  final String clientName;
  final List<SaleItem> items;
  final double totalAmount;
  final double totalCost;
  final double profit;
  final String status; // 'completed' | 'returned'
  final DateTime createdAt;

  Sale({
    required this.id,
    this.clientId,
    this.clientName = 'Cliente Ocasional',
    required this.items,
    required this.totalAmount,
    required this.totalCost,
    required this.profit,
    this.status = 'completed',
    required this.createdAt,
  });

  bool get isReturned => status == 'returned';

  Sale copyWith({
    String? id,
    String? clientId,
    String? clientName,
    List<SaleItem>? items,
    double? totalAmount,
    double? totalCost,
    double? profit,
    String? status,
    DateTime? createdAt,
  }) {
    return Sale(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCost: totalCost ?? this.totalCost,
      profit: profit ?? this.profit,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'profit': profit,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is Timestamp) return val.toDate();
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return DateTime.now();
  }

  factory Sale.fromMap(Map<String, dynamic> map, String id) {
    return Sale(
      id: id,
      clientId: map['clientId'],
      clientName: map['clientName'] ?? 'Cliente Ocasional',
      items: List<SaleItem>.from(
        (map['items'] as List? ?? []).map((x) => SaleItem.fromMap(x)),
      ),
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      totalCost: map['totalCost']?.toDouble() ?? 0.0,
      profit: map['profit']?.toDouble() ?? 0.0,
      status: map['status'] ?? 'completed',
      createdAt: _parseDate(map['createdAt']),
    );
  }
}
