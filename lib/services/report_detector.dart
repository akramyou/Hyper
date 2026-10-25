class ReportDetector {
  static List<String> detectHeaders(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [];
    return rows.first.keys.map((e) => e.toString().trim()).toList();
  }

  static Map<String, String> detectBranchInfo(List<Map<String, dynamic>> rows) {
    final result = <String, String>{};
    final branchKeywords = ['branch', 'فرع', 'المكتب', 'الفرع'];
    final orgKeywords = ['org', 'منظمة', 'المؤسسة', 'الشركة'];

    for (final row in rows.take(10)) {
      row.forEach((key, value) {
        final k = key.toString().trim().toLowerCase();
        final v = value.toString().trim();
        if (v.isEmpty) return;
        if (branchKeywords.any((kw) => k.contains(kw.toLowerCase()))) {
          result['branch_id'] = v;
        }
        if (orgKeywords.any((kw) => k.contains(kw.toLowerCase()))) {
          result['org_code'] = v;
        }
      });
      if (result.containsKey('branch_id') && result.containsKey('org_code')) break;
    }
    return result;
  }

  static Map<String, String> suggestMapping(List<String> headers) {
    final mapping = <String, String>{};
    final aliases = {
      'apps_code': ['apps_code', 'كودالنظام', 'كودالتطبيق', 'الكود', 'itemcode', 'كودالصنف'],
      'pos_code': ['pos_code', 'بوس', 'نقطةالبيع', 'pos', 'كodenقطةالبيع', 'كودالبوس'],
      'description_ar': ['description_ar', 'arb_desc', 'الوصفالعربي', 'اسمالصنف', 'المنتج', 'اسم المنتج', 'الوصف'],
      'description_en': ['description_en', 'description', 'الوصفالإنجليزي', 'الاسمالإنجليزي', 'english name'],
      'uom': ['uom', 'الوحدة', 'وحدةالقياس', 'unit', 'الوحده'],
      'wh_stock': ['wh_stock', 'مخزنينالمستودع', 'المخزونالعام', 'الكميةفيالمخزن', 'مخزن'],
      'br_stock': ['br_stock', 'مخزنالفرع', 'الرصيد', 'المخزون', 'stock', 'رصيد الفرع'],
      'sold_stk': ['sold_stk', 'المباع', 'الكميةالمباعة', 'sold', 'المباعة', 'مبيعات'],
      'wh_loc_code': ['wh_loc_code', 'الموقع', 'موقعالتخزين', 'المخزن', 'loc', 'موقع'],
      'flyer_item': ['flyer_item', 'النشرة', 'فلاير', 'flyer', 'عروض', 'النشرة الدعائية'],
    };

    for (final header in headers) {
      final h = header.toLowerCase().replaceAll(RegExp(r'[\s_]'), '');
      for (final field in aliases.keys) {
        if (aliases[field]!.any((alias) => h.contains(alias.replaceAll(RegExp(r'[\s_]'), '')))) {
          mapping[header] = field;
          break;
        }
      }
    }
    return mapping;
  }
}
