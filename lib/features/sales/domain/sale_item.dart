class SaleItem {
  final String sparePartId;
  final String sparePartName;
  final int quantity;
  final double unitCostPrice;
  final double unitSalePrice;

  SaleItem({
    required this.sparePartId,
    required this.sparePartName,
    required this.quantity,
    required this.unitCostPrice,
    required this.unitSalePrice,
  });

  double get totalPrice => quantity * unitSalePrice;
  double get totalCost => quantity * unitCostPrice;
  double get profit => totalPrice - totalCost;

  Map<String, dynamic> toMap() {
    return {
      'sparePartId': sparePartId,
      'sparePartName': sparePartName,
      'quantity': quantity,
      'unitCostPrice': unitCostPrice,
      'unitSalePrice': unitSalePrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      sparePartId: map['sparePartId'] ?? '',
      sparePartName: map['sparePartName'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      unitCostPrice: map['unitCostPrice']?.toDouble() ?? 0.0,
      unitSalePrice: map['unitSalePrice']?.toDouble() ?? 0.0,
    );
  }
}
