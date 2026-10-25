import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/models/item_model.dart';
import 'package:hyper_dammam3/models/item_batch_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
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

  int get expiredCount => batches.where((b) {
    if (b.expiryDate == null) return false;
    try => DateTime.parse(b.expiryDate!).isBefore(DateTime.now());
    catch (_) => false;
  }).length;

  int get safeCount => batches.where((b) {
    if (b.expiryDate == null) return false;
    try {
      final d = DateTime.parse(b.expiryDate!);
      return d.isAfter(DateTime.now().add(const Duration(days: 90)));
    } catch (_) => false;
  }).length;

  int get warningCount => batches.length - expiredCount - safeCount;
  int get lowStockCount => items.where((i) => i.brStock <= 0).length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التحليل البياني الذكي'), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _statCard('منتهية', expiredCount.toString(), Colors.red),
                  const SizedBox(width: 12),
                  _statCard('تحذير', warningCount.toString(), Colors.orange),
                  const SizedBox(width: 12),
                  _statCard('آمن', safeCount.toString(), Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              const Text('توزيع حالات الصلاحية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: expiredCount.toDouble(), title: 'منتهية', color: Colors.red, radius: 80),
                      PieChartSectionData(value: warningCount.toDouble(), title: 'تحذير', color: Colors.orange, radius: 80),
                      PieChartSectionData(value: safeCount.toDouble(), title: 'آمن', color: Colors.green, radius: 80),
                    ],
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text('حالة المخزون', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(show: true),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: items.length.toDouble(), color: Colors.blue)]),
                      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: lowStockCount.toDouble(), color: Colors.red)]),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                        return value == 0 ? const Text('إجمالي') : const Text('منخفض');
                      })),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 14, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
