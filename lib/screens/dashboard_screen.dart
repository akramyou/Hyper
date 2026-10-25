import 'package:flutter/material.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/screens/items_screen.dart';
import 'package:hyper_dammam3/screens/alerts_screen.dart';
import 'package:hyper_dammam3/screens/reports_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalItems = 0;
  int expiredCount = 0;
  int expiringSoonCount = 0;
  int lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseHelper.instance;
    totalItems = await db.getItemCount();
    expiredCount = (await db.getExpiredBatches()).length;
    expiringSoonCount = (await db.getExpiringBatches(days: 90)).length;
    lowStockCount = (await db.getLowStockItems()).length;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة التحكم - هايبر ماركت'),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard('إجمالي الأصناف', totalItems.toString(), Colors.blue.shade700, Icons.inventory),
              _buildStatCard('منتهية الصلاحية', expiredCount.toString(), Colors.red, Icons.warning),
              _buildStatCard('قريبة الانتهاء', expiringSoonCount.toString(), Colors.orange, Icons.schedule),
              _buildStatCard('منخفض المخزون', lowStockCount.toString(), Colors.amber, Icons.remove_shopping_cart),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen()));
            } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
            } else if (index == 3) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'الأصناف'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'التنبيهات'),
            BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'التقارير'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen())),
          icon: const Icon(Icons.add),
          label: const Text('أضف صنف'),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
