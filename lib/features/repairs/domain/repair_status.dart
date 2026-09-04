import 'package:flutter/material.dart';

/// Represents the status of a repair job.
enum RepairStatus {
  received,
  underReview,
  repaired,
  delivered,
  cancelled,
}

extension RepairStatusExtension on RepairStatus {
  /// Returns the UI label for the status in Spanish.
  String get label {
    switch (this) {
      case RepairStatus.received:
        return 'Recibido';
      case RepairStatus.underReview:
        return 'En revisión';
      case RepairStatus.repaired:
        return 'Reparado';
      case RepairStatus.delivered:
        return 'Entregado';
      case RepairStatus.cancelled:
        return 'Cancelado';
    }
  }

  /// Returns the corresponding color for the status.
  Color get color {
    switch (this) {
      case RepairStatus.received:
        return Colors.blue;
      case RepairStatus.underReview:
        return Colors.orange;
      case RepairStatus.repaired:
        return Colors.green;
      case RepairStatus.delivered:
        return Colors.grey;
      case RepairStatus.cancelled:
        return Colors.red;
    }
  }

  /// Returns the corresponding icon for the status.
  IconData get icon {
    switch (this) {
      case RepairStatus.received:
        return Icons.inbox_rounded;
      case RepairStatus.underReview:
        return Icons.search_rounded;
      case RepairStatus.repaired:
        return Icons.check_circle_rounded;
      case RepairStatus.delivered:
        return Icons.done_all_rounded;
      case RepairStatus.cancelled:
        return Icons.cancel_rounded;
    }
  }

  /// Returns the enum name as string for Firestore storage.
  String get value => name;

  /// Maps string back to enum.
  static RepairStatus fromString(String value) {
    if (value == 'waitingPart') return RepairStatus.underReview;
    return RepairStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RepairStatus.received,
    );
  }
}
