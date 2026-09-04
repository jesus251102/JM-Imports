import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un cliente / técnico
class Client {
  final String id;
  final String name;
  final String phone;
  final String dniRuc;
  final DateTime createdAt;

  const Client({
    required this.id,
    required this.name,
    this.phone = '',
    this.dniRuc = '',
    required this.createdAt,
  });

  Client copyWith({
    String? id,
    String? name,
    String? phone,
    String? dniRuc,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dniRuc: dniRuc ?? this.dniRuc,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'dniRuc': dniRuc,
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

  factory Client.fromMap(Map<String, dynamic> map, String id) {
    return Client(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      dniRuc: map['dniRuc'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
    );
  }
}
