import 'package:flutter/material.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/models/item_model.dart';
import 'package:hyper_dammam3/models/item_batch_model.dart';
import 'package:hyper_dammam3/screens/add_edit_batch_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  List<ItemBatch> batches = [];

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    final list = await DatabaseHelper.instance.getBatchesForItem(widget.item.id!);
    setState(() => batches = list);
  }

  Future<void> _deleteBatch(int batchId) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه الدفعة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteItemBatch(batchId);
              _loadBatches();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.item.displayName), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كود النظام: ${widget.item.appsCode}', style: const TextStyle(fontSize: 14)),
                      Text('كود نقطة البيع: ${widget.item.posCode}', style: const TextStyle(fontSize: 14)),
                      Text('وحدة القياس: ${widget.item.uom}', style: const TextStyle(fontSize: 14)),
                      Text('مخزن المستودع: ${widget.item.whStock}', style: const TextStyle(fontSize: 14)),
                      Text('مخزن الفرع: ${widget.item.brStock}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.item.brStock <= 0 ? Colors.red : Colors.green)),
                      Text('الموقع: ${widget.item.whLocCode}', style: const TextStyle(fontSize: 14)),
                      Text('نشرة دعائية: ${widget.item.isFlyer ? 'نعم' : 'لا'}', style: const TextStyle(fontSize: 14)),
                      const Divider(),
                      Text('تاريخ الإضافة: ${widget.item.createdAt != null ? widget.item.createdAt!.toString().substring(0, 10) : '-'}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('دفعات المنتج وتواريخ الانتهاء:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditBatchScreen(itemId: widget.item.id!)));
                      _loadBatches();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة دفعة'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: batches.isEmpty
                    ? const Center(child: Text('لا توجد دفعات مسجلة لهذا الصنف'))
                    : ListView.builder(
                        itemCount: batches.length,
                        itemBuilder: (ctx, i) {
                          final batch = batches[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text('دفعة: ${batch.batchNumber ?? 'غير محدد'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('تاريخ الإنتاج: ${batch.productionDate ?? '-'} | الانتهاء: ${batch.expiryDate ?? '-'}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: batch.statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(batch.expiryStatus, style: TextStyle(color: batch.statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${batch.quantity} ${widget.item.uom}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBatch(batch.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
