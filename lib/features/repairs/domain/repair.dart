import 'package:cloud_firestore/cloud_firestore.dart';
import 'repair_status.dart';

/// Represents a repair job in the system.
class Repair {
  final String id;
  final String clientId;
  final String clientName;
  final String deviceBrand;
  final String deviceModel;
  final String? imei;
  final String reportedProblem;
  final String physicalCondition;
  final String internalNotes;
  final RepairStatus status;
  final double repairCost;
  final String? partUsedId;
  final String? partUsedName;
  final double? partCostPrice;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deliveredAt;

  const Repair({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.deviceBrand,
    required this.deviceModel,
    this.imei,
    required this.reportedProblem,
    required this.physicalCondition,
    required this.internalNotes,
    required this.status,
    required this.repairCost,
    this.partUsedId,
    this.partUsedName,
    this.partCostPrice,
    required this.createdAt,
    required this.updatedAt,
    this.deliveredAt,
  });

  Repair copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? deviceBrand,
    String? deviceModel,
    String? imei,
    String? reportedProblem,
    String? physicalCondition,
    String? internalNotes,
    RepairStatus? status,
    double? repairCost,
    String? partUsedId,
    String? partUsedName,
    double? partCostPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    bool clearPartUsed = false,
  }) {
    return Repair(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceModel: deviceModel ?? this.deviceModel,
      imei: imei ?? this.imei,
      reportedProblem: reportedProblem ?? this.reportedProblem,
      physicalCondition: physicalCondition ?? this.physicalCondition,
      internalNotes: internalNotes ?? this.internalNotes,
      status: status ?? this.status,
      repairCost: repairCost ?? this.repairCost,
      partUsedId: clearPartUsed ? null : (partUsedId ?? this.partUsedId),
      partUsedName: clearPartUsed ? null : (partUsedName ?? this.partUsedName),
      partCostPrice: clearPartUsed ? null : (partCostPrice ?? this.partCostPrice),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'deviceBrand': deviceBrand,
      'deviceModel': deviceModel,
      'imei': imei,
      'reportedProblem': reportedProblem,
      'physicalCondition': physicalCondition,
      'internalNotes': internalNotes,
      'status': status.value,
      'repairCost': repairCost,
      'partUsedId': partUsedId,
      'partUsedName': partUsedName,
      'partCostPrice': partCostPrice,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
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

  factory Repair.fromMap(Map<String, dynamic> map, String id) {
    return Repair(
      id: id,
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      deviceBrand: map['deviceBrand'] as String? ?? '',
      deviceModel: map['deviceModel'] as String? ?? '',
      imei: map['imei'] as String?,
      reportedProblem: map['reportedProblem'] as String? ?? '',
      physicalCondition: map['physicalCondition'] as String? ?? '',
      internalNotes: map['internalNotes'] as String? ?? '',
      status: RepairStatusExtension.fromString(map['status'] as String? ?? ''),
      repairCost: (map['repairCost'] as num?)?.toDouble() ?? 0.0,
      partUsedId: map['partUsedId'] as String?,
      partUsedName: map['partUsedName'] as String?,
      partCostPrice: (map['partCostPrice'] as num?)?.toDouble(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      deliveredAt: map['deliveredAt'] != null ? _parseDate(map['deliveredAt']) : null,
    );
  }
}
