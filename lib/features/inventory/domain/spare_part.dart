import 'package:cloud_firestore/cloud_firestore.dart';

class SparePart {
  final String id;
  final String brand;
  final String model;
  final String category;
  final String quality;
  final int stock;
  final double costPrice;
  final double salePrice;
  final DateTime createdAt;

  const SparePart({
    required this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.quality,
    required this.stock,
    required this.costPrice,
    required this.salePrice,
    required this.createdAt,
  });

  SparePart copyWith({
    String? id,
    String? brand,
    String? model,
    String? category,
    String? quality,
    int? stock,
    double? costPrice,
    double? salePrice,
    DateTime? createdAt,
  }) {
    return SparePart(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      quality: quality ?? this.quality,
      stock: stock ?? this.stock,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'model': model,
      'category': category,
      'quality': quality,
      'stock': stock,
      'costPrice': costPrice,
      'salePrice': salePrice,
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

  factory SparePart.fromMap(Map<String, dynamic> map, String id) {
    return SparePart(
      id: id,
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      category: map['category'] ?? 'Pantalla / Módulo',
      quality: map['quality'] ?? '',
      stock: map['stock']?.toInt() ?? 0,
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      salePrice: map['salePrice']?.toDouble() ?? 0.0,
      createdAt: _parseDate(map['createdAt']),
    );
  }
}
