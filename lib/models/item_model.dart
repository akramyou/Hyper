class Item {
  final int? id;
  final String branchId;
  final String orgCode;
  final String appsCode;
  final String posCode;
  final String descriptionEn;
  final String descriptionAr;
  final String uom;
  final double whStock;
  final double brStock;
  final int soldStk;
  final String whLocCode;
  final bool isFlyer;
  final Map<String, dynamic> extraData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    this.id,
    required this.branchId,
    required this.orgCode,
    required this.appsCode,
    required this.posCode,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.uom,
    required this.whStock,
    required this.brStock,
    required this.soldStk,
    required this.whLocCode,
    required this.isFlyer,
    this.extraData = const {},
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branch_id': branchId,
      'org_code': orgCode,
      'apps_code': appsCode,
      'pos_code': posCode,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'uom': uom,
      'wh_stock': whStock,
      'br_stock': brStock,
      'sold_stk': soldStk,
      'wh_loc_code': whLocCode,
      'is_flyer': isFlyer ? 1 : 0,
      'extra_data': extraData.isNotEmpty ? extraData.toString() : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      branchId: map['branch_id'] ?? '',
      orgCode: map['org_code'] ?? '',
      appsCode: map['apps_code'] ?? '',
      posCode: map['pos_code'] ?? '',
      descriptionEn: map['description_en'] ?? '',
      descriptionAr: map['description_ar'] ?? '',
      uom: map['uom'] ?? '',
      whStock: (map['wh_stock'] ?? 0) is int ? (map['wh_stock'] as int).toDouble() : (map['wh_stock'] ?? 0.0),
      brStock: (map['br_stock'] ?? 0) is int ? (map['br_stock'] as int).toDouble() : (map['br_stock'] ?? 0.0),
      soldStk: map['sold_stk'] ?? 0,
      whLocCode: map['wh_loc_code'] ?? '',
      isFlyer: map['is_flyer'] == 1,
      extraData: {},
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }

  bool get isLowStock => brStock <= 0;
  String get displayName => descriptionAr.isNotEmpty ? descriptionAr : descriptionEn;
}
