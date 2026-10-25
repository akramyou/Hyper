import 'package:flutter/material.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/models/item_model.dart';
import 'package:hyper_dammam3/models/item_batch_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedReport = 'الكل';
  List<Item> items = [];
  List<ItemBatch> batches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    items = await DatabaseHelper.instance.getAllItems();
    batches = await DatabaseHelper.instance.getAllBatches();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () async {
                final text = 'تقرير هايبر ماركت\nالتاريخ: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}\n\nأصناف: ${items.length}\nدفعات: ${batches.length}';
                await Share.share(text);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: selectedReport,
                decoration: const InputDecoration(labelText: 'اختر نوع التقرير', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'الكل', child: Text('تقرير شامل')),
                  DropdownMenuItem(value: 'منتهية الصلاحية', child: Text('دفعات منتهية الصلاحية')),
                  DropdownMenuItem(value: 'قريبة الانتهاء', child: Text('دفعات قريبة الانتهاء')),
                  DropdownMenuItem(value: 'منخفض المخزون', child: Text('أصناف منخفض المخزون')),
                ],
                onChanged: (v) => setState(() => selectedReport = v!),
              ),
            ),
            Expanded(
              child: selectedReport == 'منخفض المخزون'
                  ? _buildItemsReport()
                  : _buildBatchesReport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchesReport() {
    final now = DateTime.now();
    List<ItemBatch> filtered = [];
    for (final b in batches) {
      if (b.expiryDate == null) continue;
      try {
        final d = DateTime.parse(b.expiryDate!);
        switch (selectedReport) {
          case 'منتهية الصلاحية':
            if (d.isBefore(now)) filtered.add(b);
            break;
          case 'قريبة الانتهاء':
            if (d.isAfter(now) && d.isBefore(now.add(const Duration(days: 90)))) filtered.add(b);
            break;
          default:
            filtered.add(b);
        }
      } catch (_) {}
    }
    if (filtered.isEmpty) return const Center(child: Text('لا توجد بيانات'));
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final b = filtered[i];
        return Card(
          child: ListTile(
            title: Text('دفعة ${b.batchNumber ?? '-'}'),
            subtitle: Text('انتهاء: ${b.expiryDate} | الكمية: ${b.quantity}'),
            trailing: Text(b.expiryStatus, style: TextStyle(color: b.statusColor)),
          ),
        );
      },
    );
  }

  Widget _buildItemsReport() {
    final low = items.where((i) => i.brStock <= 0).toList();
    if (low.isEmpty) return const Center(child: Text('لا توجد أصناف منخفضة المخزون'));
    return ListView.builder(
      itemCount: low.length,
      itemBuilder: (ctx, i) {
        final it = low[i];
        return ListTile(
          title: Text(it.displayName),
          subtitle: Text('المخزون: ${it.brStock} ${it.uom} | الكود: ${it.posCode}'),
        );
      },
    );
  }
}
