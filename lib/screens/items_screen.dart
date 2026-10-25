import 'package:flutter/material.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/models/item_model.dart';
import 'package:hyper_dammam3/screens/item_detail_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  List<Item> items = [];
  String query = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final list = await DatabaseHelper.instance.getAllItems();
    setState(() => items = list);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = items.where((item) {
      final q = query.toLowerCase();
      return item.displayName.toLowerCase().contains(q) ||
          item.descriptionEn.toLowerCase().contains(q) ||
          item.appsCode.contains(q) ||
          item.posCode.contains(q) ||
          item.whLocCode.contains(q);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة الأصناف'), centerTitle: true),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو الكود أو الموقع...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد أصناف'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text(item.displayName.isNotEmpty ? item.displayName[0] : '؟', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(item.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('كود: ${item.posCode} | المخزون: ${item.brStock} ${item.uom} | الموقع: ${item.whLocCode}', maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item))),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ItemsScreen())).then((_) => _loadItems()),
          icon: const Icon(Icons.add),
          label: const Text('أضف صنف'),
        ),
      ),
    );
  }
}
