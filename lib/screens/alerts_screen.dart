import 'package:flutter/material.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/models/item_model.dart';
import 'package:hyper_dammam3/models/item_batch_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<ItemBatch> expired = [];
  List<ItemBatch> lessThanWeek = [];
  List<ItemBatch> lessThanMonth = [];
  List<ItemBatch> oneToTwoMonths = [];
  List<ItemBatch> twoToThreeMonths = [];
  List<Item> lowStock = [];
  Map<String, bool> settings = {};

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final db = DatabaseHelper.instance;
    settings = await db.getNotificationSettings();
    expired = settings['expired'] == false ? [] : await db.getExpiredBatches();
    lowStock = settings['low_stock'] == false ? [] : await db.getLowStockItems();
    final allBatches = await db.getAllBatches();
    final now = DateTime.now();

    lessThanWeek = [];
    lessThanMonth = [];
    oneToTwoMonths = [];
    twoToThreeMonths = [];

    for (final batch in allBatches) {
      if (batch.expiryDate == null || batch.expiryDate!.isEmpty) continue;
      try {
        final expiry = DateTime.parse(batch.expiryDate!);
        final diff = expiry.difference(now).inDays;
        if (diff <= 7 && settings['less_than_week'] == true) lessThanWeek.add(batch);
        else if (diff <= 30 && settings['less_than_month'] == true) lessThanMonth.add(batch);
        else if (diff <= 60 && settings['one_to_two_months'] == true) oneToTwoMonths.add(batch);
        else if (diff <= 90 && settings['two_to_three_months'] == true) twoToThreeMonths.add(batch);
      } catch (_) {}
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التنبيهات والتنبيهات'), centerTitle: true),
        body: ListView(
          children: [
            if (expired.isNotEmpty) _section('🔴 منتهية الصلاحية', expired.map((b) => _batchTile(b)).toList(), Colors.red),
            if (lessThanWeek.isNotEmpty) _section('⚠️ أقل من أسبوع', lessThanWeek.map((b) => _batchTile(b)).toList(), Colors.orange.shade700),
            if (lessThanMonth.isNotEmpty) _section('🟠 أقل من شهر', lessThanMonth.map((b) => _batchTile(b)).toList(), Colors.orange),
            if (oneToTwoMonths.isNotEmpty) _section('🟡 شهر إلى شهرين', oneToTwoMonths.map((b) => _batchTile(b)).toList(), Colors.amber),
            if (twoToThreeMonths.isNotEmpty) _section('📅 شهرين إلى 3 أشهر', twoToThreeMonths.map((b) => _batchTile(b)).toList(), Colors.yellow.shade700),
            if (lowStock.isNotEmpty) _section('📦 منخفض المخزون', lowStock.map((i) => _itemTile(i)).toList(), Colors.blue),
            if (expired.isEmpty && lessThanWeek.isEmpty && lessThanMonth.isEmpty && oneToTwoMonths.isEmpty && twoToThreeMonths.isEmpty && lowStock.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('لا توجد تنبيهات حالياً، كل شيء بخير ✅', style: TextStyle(fontSize: 16, color: Colors.green)))),
          ],
        ),
      ),
    );
  }

  Widget _batchTile(ItemBatch b) => ListTile(
    title: Text('دفعة ${b.batchNumber ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text('انتهاء: ${b.expiryDate ?? '-'} | الكمية: ${b.quantity}'),
    trailing: Text(b.expiryStatus, style: TextStyle(color: b.statusColor, fontWeight: FontWeight.bold)),
  );

  Widget _itemTile(Item i) => ListTile(
    title: Text(i.displayName),
    subtitle: Text('المخزون: ${i.brStock} ${i.uom} | الكود: ${i.posCode}'),
    trailing: const Text('منخفض', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
  );

  Widget _section(String title, List<Widget> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ),
        ...items,
      ],
    );
  }
}
