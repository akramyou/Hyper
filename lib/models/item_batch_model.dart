import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class ItemBatch {
  final int? id;
  final int itemId;
  final String? batchNumber;
  final String? productionDate;
  final String? expiryDate;
  final double quantity;
  final bool isActive;
  final DateTime? createdAt;

  ItemBatch({
    this.id,
    required this.itemId,
    this.batchNumber,
    this.productionDate,
    this.expiryDate,
    this.quantity = 0,
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'batch_number': batchNumber,
      'production_date': productionDate,
      'expiry_date': expiryDate,
      'quantity': quantity,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory ItemBatch.fromMap(Map<String, dynamic> map) {
    return ItemBatch(
      id: map['id'],
      itemId: map['item_id'] ?? 0,
      batchNumber: map['batch_number'],
      productionDate: map['production_date'],
      expiryDate: map['expiry_date'],
      quantity: (map['quantity'] ?? 0) is int ? (map['quantity'] as int).toDouble() : (map['quantity'] ?? 0.0),
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }

  String get expiryStatus {
    if (expiryDate == null || expiryDate!.isEmpty) return 'تاريخ غير محدد';
    try {
      final expiry = DateTime.parse(expiryDate!);
      final now = DateTime.now();
      final diff = expiry.difference(now).inDays;
      if (diff < 0) return 'منتهية';
      if (diff <= 7) return 'أقل من أسبوع';
      if (diff <= 30) return 'أقل من شهر';
      if (diff <= 60) return 'أقل من شهرين';
      if (diff <= 90) return 'أقل من 3 أشهر';
      return 'سليم';
    } catch (_) {
      return 'تاريخ غير صحيح';
    }
  }

  Color get statusColor {
    switch (expiryStatus) {
      case 'منتهية': return Colors.red;
      case 'أقل من أسبوع': return Colors.orange.shade700;
      case 'أقل من شهر': return Colors.orange;
      case 'أقل من شهرين': return Colors.amber;
      case 'أقل من 3 أشهر': return Colors.yellow.shade700;
      default: return Colors.green;
    }
  }
}
