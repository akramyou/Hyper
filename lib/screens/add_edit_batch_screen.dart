import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/models/item_batch_model.dart';
import 'package:hyper_dammam3/services/ocr_service.dart';

class AddEditBatchScreen extends StatefulWidget {
  final int itemId;
  final ItemBatch? batch;
  const AddEditBatchScreen({super.key, required this.itemId, this.batch});

  @override
  State<AddEditBatchScreen> createState() => _AddEditBatchScreenState();
}

class _AddEditBatchScreenState extends State<AddEditBatchScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _batchController;
  late TextEditingController _quantityController;
  String? _productionDate;
  String? _expiryDate;
  final OcrService _ocr = OcrService();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _batchController = TextEditingController(text: widget.batch?.batchNumber ?? '');
    _quantityController = TextEditingController(text: widget.batch?.quantity.toString() ?? '0');
    _productionDate = widget.batch?.productionDate;
    _expiryDate = widget.batch?.expiryDate;
  }

  @override
  void dispose() {
    _batchController.dispose();
    _quantityController.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isExpiry) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      locale: const Locale('ar', 'SA'),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) _expiryDate = DateFormat('yyyy-MM-dd').format(picked);
        else _productionDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _scanExpiryFromCamera() async {
    setState(() => _isScanning = true);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) {
      setState(() => _isScanning = false);
      return;
    }
    final file = File(picked.path);
    final detected = await _ocr.extractExpiryDate(file);
    setState(() => _isScanning = false);
    if (detected != null) {
      setState(() => _expiryDate = detected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم اكتشاف تاريخ الانتهاء: $detected'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم التعرف على التاريخ تلقائياً، يرجى إدخاله يدوياً'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final batch = ItemBatch(
      id: widget.batch?.id,
      itemId: widget.itemId,
      batchNumber: _batchController.text.trim(),
      productionDate: _productionDate,
      expiryDate: _expiryDate,
      quantity: double.tryParse(_quantityController.text) ?? 0,
    );
    if (widget.batch == null) {
      await DatabaseHelper.instance.insertItemBatch(batch);
    } else {
      await DatabaseHelper.instance.updateItemBatch(batch);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.batch == null ? 'إضافة دفعة جديدة' : 'تعديل الدفعة'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                TextFormField(controller: _batchController, decoration: const InputDecoration(labelText: 'رقم الدفعة', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'رقم الدفعة مطلوب' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: 'الكمية', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'الكمية مطلوبة' : null),
                const SizedBox(height: 16),
                const Text('تاريخ الإنتاج', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickDate(false),
                        icon: const Icon(Icons.event),
                        label: Text(_productionDate != null ? _productionDate! : 'اختر تاريخ الإنتاج'),
                      ),
                    ),
                  ],
                ),
                if (_productionDate != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('تم تحديد: $_productionDate', style: const TextStyle(color: Colors.green)),
                ),
                const SizedBox(height: 16),
                const Text('تاريخ الانتهاء', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickDate(true),
                        icon: const Icon(Icons.event_busy),
                        label: Text(_expiryDate != null ? _expiryDate! : 'اختر تاريخ الانتهاء'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_isScanning)
                      ElevatedButton.icon(
                        onPressed: _scanExpiryFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('مسح'),
                      )
                    else
                      const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                if (_expiryDate != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'تاريخ الانتهاء: $_expiryDate',
                    style: TextStyle(color: _expiryDate! < DateTime.now().toIso8601String().substring(0, 10) ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(widget.batch == null ? 'إضافة الدفعة' : 'تعديل الدفعة'),
                  style: ElevatedButton.styleFrom(minSize: const Size.fromHeight(50)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
