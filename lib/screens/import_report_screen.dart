import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:xlsx/xlsx.dart';
import 'package:hyper_dammam3/database/database_helper.dart';
import 'package:hyper_dammam3/services/report_detector.dart';
import 'package:hyper_dammam3/models/branch_config.dart';

class ImportReportScreen extends StatefulWidget {
  const ImportReportScreen({super.key});

  @override
  State<ImportReportScreen> createState() => _ImportReportScreenState();
}

class _ImportReportScreenState extends State<ImportReportScreen> {
  bool isLoading = false;
  String message = '';
  List<String> headers = [];
  List<Map<String, dynamic>> allRows = [];
  Map<String, String> suggestedMapping = {};

  @override
  void initState() {
    super.initState();
    _checkConfigured();
  }

  Future<void> _checkConfigured() async {
    final configured = await DatabaseHelper.instance.isConfigured();
    if (!configured) {
      setState(() => message = 'مرحباً! يرجى رفع أول تقرير لتحديد إعدادات الفرع تلقائياً.');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => isLoading = true);

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      List<Map<String, dynamic>> rows = [];

      if (result.files.single.extension == 'csv') {
        final data = const CsvToListConverter().convert(String.fromCharCodes(bytes));
        if (data.isEmpty) throw Exception('الملف فارغ');
        headers = data.first.map((e) => e.toString().trim()).toList();
        for (int i = 1; i < data.length; i++) {
          final row = data[i];
          final map = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            map[headers[j]] = row[j];
          }
          rows.add(map);
        }
      } else {
        final decoder = XlsxDecoder.decodeBytes(bytes);
        final sheet = decoder.tables.values.first;
        final tableRows = sheet.rows;
        if (tableRows.isEmpty) throw Exception('الملف فارغ');
        headers = tableRows.first.map((e) => e?.toString().trim() ?? '').toList();
        for (int i = 1; i < tableRows.length; i++) {
          final row = tableRows[i];
          final map = <String, dynamic>{};
          for (int j = 0; j < headers.length && j < row.length; j++) {
            map[headers[j]] = row[j];
          }
          rows.add(map);
        }
      }

      allRows = rows;
      suggestedMapping = ReportDetector.suggestMapping(headers);
      final branchInfo = ReportDetector.detectBranchInfo(rows);

      setState(() {
        if (!await DatabaseHelper.instance.isConfigured()) {
          message = 'تم اكتشاف التقرير. الفرع: ${branchInfo['branch_id'] ?? 'غير واضح'} | المنظمة: ${branchInfo['org_code'] ?? 'غير واضح'}';
        } else {
          message = 'تم قراءة الملف بنجاح. عدد الصفوف: ${rows.length}';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        message = 'خطأ أثناء قراءة الملف: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _saveConfigAndImport() async {
    final db = DatabaseHelper.instance;
    final branchInfo = ReportDetector.detectBranchInfo(allRows);
    final config = BranchConfig(
      branchId: branchInfo['branch_id'] ?? 'غير محدد',
      orgCode: branchInfo['org_code'] ?? 'غير محدد',
      branchName: 'فرع ${branchInfo['branch_id'] ?? ''}',
      columnMapping: suggestedMapping,
      isConfigured: true,
    );
    await db.saveBranchConfig(config);
    final summary = await db.smartImport(
      rows: allRows,
      branchId: config.branchId!,
      orgCode: config.orgCode!,
      columnMapping: suggestedMapping,
    );
    setState(() {
      message = 'تم تكوين الفرع والاستيراد بنجاح:\n'
          'أصناف جديدة: ${summary['inserted']}\n'
          'أصناف محدثة (كميات فقط): ${summary['updated']}\n'
          'تخطي: ${summary['skipped']}\n'
          'ملاحظة: تم الحفاظ على تواريخ الدفعات الموجودة كما هي.';
    });
  }

  Future<void> _importOnly() async {
    final config = await DatabaseHelper.instance.getBranchConfig();
    final summary = await DatabaseHelper.instance.smartImport(
      rows: allRows,
      branchId: config.branchId ?? 'غير محدد',
      orgCode: config.orgCode ?? 'غير محدد',
      columnMapping: config.columnMapping,
    );
    setState(() {
      message = 'تم التحديث:\n'
          'جديد: ${summary['inserted']} صنف\n'
          'محدث: ${summary['updated']} صنف\n'
          'تخطي: ${summary['skipped']} صف\n'
          '(تم الحفاظ على تواريخ الانتهاء والإنتاج كما هي)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(await DatabaseHelper.instance.isConfigured() ? 'استيراد تقرير يومي' : 'تكوين الفرع من التقرير الأول'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: isLoading ? null : _pickFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('اختر ملف إكسل أو CSV'),
                style: ElevatedButton.styleFrom(minSize: const Size.fromHeight(50)),
              ),
              const SizedBox(height: 12),
              if (headers.isNotEmpty) ...[
                const Text('الأعمدة المكتشفة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: headers.map((h) => Chip(label: Text(h))).toList(),
                ),
                const SizedBox(height: 12),
                if (!await DatabaseHelper.instance.isConfigured() && suggestedMapping.isNotEmpty) ...[
                  const Text('تطابق الأعمدة المقترح:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...suggestedMapping.entries.take(8).map((e) =>
                      ListTile(title: Text(e.key), subtitle: Text('→ ${e.value}'))),
                ],
              ],
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Text(message),
                ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || allRows.isEmpty ? null : (await DatabaseHelper.instance.isConfigured() ? _importOnly : _saveConfigAndImport),
                  child: Text(await DatabaseHelper.instance.isConfigured() ? 'استيراد وتحديث الكميات' : 'حفظ الإعدادات واستيراد البيانات'),
                  style: ElevatedButton.styleFrom(minSize: const Size.fromHeight(50)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
