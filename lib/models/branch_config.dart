import 'dart:convert';

class BranchConfig {
  final String? branchId;
  final String? orgCode;
  final String? branchName;
  final Map<String, String> columnMapping;
  final bool isConfigured;
  final bool notificationsEnabled;
  final double defaultMinStock;

  BranchConfig({
    this.branchId,
    this.orgCode,
    this.branchName,
    this.columnMapping = const {},
    this.isConfigured = false,
    this.notificationsEnabled = true,
    this.defaultMinStock = 5.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'branch_id': branchId,
      'org_code': orgCode,
      'branch_name': branchName,
      'column_mapping': columnMapping.isNotEmpty ? jsonEncode(columnMapping) : null,
      'is_configured': isConfigured ? 1 : 0,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'default_min_stock': defaultMinStock,
    };
  }

  factory BranchConfig.fromMap(Map<String, dynamic> m) {
    return BranchConfig(
      branchId: m['branch_id'],
      orgCode: m['org_code'],
      branchName: m['branch_name'],
      columnMapping: m['column_mapping'] != null
          ? Map<String, String>.from(jsonDecode(m['column_mapping']))
          : {},
      isConfigured: m['is_configured'] == 1,
      notificationsEnabled: m['notifications_enabled'] == 1,
      defaultMinStock: (m['default_min_stock'] ?? 5.0) is int
          ? (m['default_min_stock'] as int).toDouble()
          : (m['default_min_stock'] ?? 5.0),
    );
  }
}
