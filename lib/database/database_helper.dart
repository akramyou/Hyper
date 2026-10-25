import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/item_model.dart';
import '../models/item_batch_model.dart';
import '../models/branch_config.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'hyper_dammam3.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE app_config(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            branch_id TEXT,
            org_code TEXT,
            apps_code TEXT,
            pos_code TEXT,
            description_en TEXT,
            description_ar TEXT,
            uom TEXT,
            wh_stock REAL DEFAULT 0,
            br_stock REAL DEFAULT 0,
            sold_stk INTEGER DEFAULT 0,
            wh_loc_code TEXT,
            is_flyer INTEGER DEFAULT 0,
            extra_data TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE item_batches(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            batch_number TEXT,
            production_date TEXT,
            expiry_date TEXT,
            quantity REAL DEFAULT 0,
            is_active INTEGER DEFAULT 1,
            created_at TEXT,
            FOREIGN KEY(item_id) REFERENCES items(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE notification_settings(
            id INTEGER PRIMARY KEY DEFAULT 1,
            expired_enabled INTEGER DEFAULT 1,
            less_than_week_enabled INTEGER DEFAULT 1,
            less_than_month_enabled INTEGER DEFAULT 1,
            one_to_two_months_enabled INTEGER DEFAULT 1,
            two_to_three_months_enabled INTEGER DEFAULT 1,
            low_stock_enabled INTEGER DEFAULT 1
          )
        ''');
        await db.execute('INSERT INTO notification_settings VALUES (1,1,1,1,1,1,1)');
        await db.execute('''
          CREATE TABLE audit_log(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT,
            details TEXT,
            created_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE items ADD COLUMN extra_data TEXT');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_config(
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS notification_settings(
              id INTEGER PRIMARY KEY DEFAULT 1,
              expired_enabled INTEGER DEFAULT 1,
              less_than_week_enabled INTEGER DEFAULT 1,
              less_than_month_enabled INTEGER DEFAULT 1,
              one_to_two_months_enabled INTEGER DEFAULT 1,
              two_to_three_months_enabled INTEGER DEFAULT 1,
              low_stock_enabled INTEGER DEFAULT 1
            )
          ''');
          await db.execute('INSERT OR IGNORE INTO notification_settings VALUES (1,1,1,1,1,1,1)');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS audit_log(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              action TEXT,
              details TEXT,
              created_at TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> setConfig(String key, String value) async {
    final db = await instance.db;
    await db.insert('app_config', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getConfig(String key) async {
    final db = await instance.db;
    final maps = await db.query('app_config', where: 'key = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<bool> isConfigured() async {
    final v = await getConfig('is_configured');
    return v == 'true';
  }

  Future<BranchConfig> getBranchConfig() async {
    final raw = await getConfig('branch_config');
    if (raw == null) return BranchConfig();
    return BranchConfig.fromMap(jsonDecode(raw));
  }

  Future<void> saveBranchConfig(BranchConfig config) async {
    await setConfig('branch_config', jsonEncode(config.toMap()));
    await setConfig('is_configured', config.isConfigured ? 'true' : 'false');
  }

  Future<void> addAuditLog(String action, String details) async {
    final db = await instance.db;
    await db.insert('audit_log', {
      'action': action,
      'details': details,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLog({int limit = 50}) async {
    final db = await instance.db;
    return await db.query('audit_log', orderBy: 'created_at DESC', limit: limit);
  }

  Future<int> insertItem(Item item) async {
    final db = await instance.db;
    final id = await db.insert('items', item.toMap());
    await addAuditLog('إضافة صنف', 'تم إضافة صنف: ${item.descriptionAr} (كود: ${item.posCode})');
    return id;
  }

  Future<List<Item>> getAllItems() async {
    final db = await instance.db;
    final maps = await db.query('items', orderBy: 'description_ar ASC');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<Item?> getItemById(int id) async {
    final db = await instance.db;
    final maps = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<Item?> getItemByCode(String appsCode, String posCode) async {
    final db = await instance.db;
    final maps = await db.query(
      'items',
      where: '(apps_code = ? OR pos_code = ?) AND branch_id = ?',
      whereArgs: [appsCode, posCode, await getConfig('branch_id') ?? ''],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Item.fromMap(maps.first);
  }

  Future<int> updateItemStockOnly(int itemId, {required double whStock, required double brStock, required int soldStk}) async {
    final db = await instance.db;
    return await db.update(
      'items',
      {'wh_stock': whStock, 'br_stock': brStock, 'sold_stk': soldStk, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await instance.db;
    await db.delete('item_batches', where: 'item_id = ?', whereArgs: [id]);
    await addAuditLog('حذف صنف', 'تم حذف الصنف رقم: $id');
    return await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getItemCount() async {
    final db = await instance.db;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM items');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertItemBatch(ItemBatch batch) async {
    final db = await instance.db;
    final id = await db.insert('item_batches', batch.toMap());
    await addAuditLog('إضافة دفعة', 'تم إضافة دفعة رقم: ${batch.batchNumber} للمنتج: ${batch.itemId}');
    return id;
  }

  Future<List<ItemBatch>> getBatchesForItem(int itemId) async {
    final db = await instance.db;
    final maps = await db.query(
      'item_batches',
      where: 'item_id = ? AND is_active = 1',
      whereArgs: [itemId],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((m) => ItemBatch.fromMap(m)).toList();
  }

  Future<List<ItemBatch>> getAllBatches() async {
    final db = await instance.db;
    final maps = await db.query('item_batches', where: 'is_active = 1', orderBy: 'expiry_date ASC');
    return maps.map((m) => ItemBatch.fromMap(m)).toList();
  }

  Future<ItemBatch?> getBatchById(int id) async {
    final db = await instance.db;
    final maps = await db.query('item_batches', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ItemBatch.fromMap(maps.first);
  }

  Future<int> updateItemBatch(ItemBatch batch) async {
    final db = await instance.db;
    await addAuditLog('تعديل دفعة', 'تم تعديل الدفعة رقم: ${batch.batchNumber}');
    return await db.update('item_batches', batch.toMap(), where: 'id = ?', whereArgs: [batch.id]);
  }

  Future<int> deleteItemBatch(int id) async {
    final db = await instance.db;
    await addAuditLog('حذف دفعة', 'تم حذف الدفعة رقم: $id');
    return await db.delete('item_batches', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    final db = await instance.db;
    final maps = await db.query('notification_settings', limit: 1);
    if (maps.isEmpty) return {
      'expired': true, 'less_than_week': true, 'less_than_month': true,
      'one_to_two_months': true, 'two_to_three_months': true, 'low_stock': true,
    };
    final m = maps.first;
    return {
      'expired': m['expired_enabled'] == 1,
      'less_than_week': m['less_than_week_enabled'] == 1,
      'less_than_month': m['less_than_month_enabled'] == 1,
      'one_to_two_months': m['one_to_two_months_enabled'] == 1,
      'two_to_three_months': m['two_to_three_months_enabled'] == 1,
      'low_stock': m['low_stock_enabled'] == 1,
    };
  }

  Future<void> setNotificationSetting(String key, bool value) async {
    final db = await instance.db;
    await db.update('notification_settings', {key: value ? 1 : 0}, where: 'id = 1');
  }

  Future<List<ItemBatch>> getExpiredBatches() async {
    final db = await instance.db;
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final maps = await db.query(
      'item_batches',
      where: 'is_active = 1 AND expiry_date IS NOT NULL AND expiry_date != "" AND expiry_date < ?',
      whereArgs: [now],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((m) => ItemBatch.fromMap(m)).toList();
  }

  Future<List<ItemBatch>> getExpiringBatches({int days = 90}) async {
    final db = await instance.db;
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final limit = DateTime.now().add(Duration(days: days)).toIso8601String().substring(0, 10);
    final maps = await db.query(
      'item_batches',
      where: 'is_active = 1 AND expiry_date IS NOT NULL AND expiry_date != "" AND expiry_date >= ? AND expiry_date <= ?',
      whereArgs: [now, limit],
      orderBy: 'expiry_date ASC',
    );
    return maps.map((m) => ItemBatch.fromMap(m)).toList();
  }

  Future<List<Item>> getLowStockItems() async {
    final db = await instance.db;
    final maps = await db.query('items', where: 'br_stock <= 0', orderBy: 'description_ar ASC');
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<Map<String, int>> smartImport({
    required List<Map<String, dynamic>> rows,
    required String branchId,
    required String orgCode,
    required Map<String, String> columnMapping,
  }) async {
    int inserted = 0, updated = 0, skipped = 0;
    final db = await instance.db;
    final batch = db.batch();

    for (final row in rows) {
      String getField(String std) {
        for (final entry in columnMapping.entries) {
          if (entry.value == std) {
            return (row[entry.key] ?? '').toString().trim();
          }
        }
        return '';
      }

      final appsCode = getField('apps_code');
      final posCode = getField('pos_code');
      if (appsCode.isEmpty && posCode.isEmpty) {
        skipped++;
        continue;
      }

      final existing = await getItemByCode(appsCode, posCode);

      final itemData = {
        'branch_id': branchId,
        'org_code': orgCode,
        'apps_code': appsCode,
        'pos_code': posCode,
        'description_en': getField('description_en'),
        'description_ar': getField('description_ar'),
        'uom': getField('uom'),
        'wh_stock': double.tryParse(getField('wh_stock')) ?? 0,
        'br_stock': double.tryParse(getField('br_stock')) ?? 0,
        'sold_stk': int.tryParse(getField('sold_stk')) ?? 0,
        'wh_loc_code': getField('wh_loc_code'),
        'is_flyer': (getField('flyer_item') ?? '').toLowerCase() == 'flyer' ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final mappedKeys = columnMapping.keys.toSet();
      final extra = <String, dynamic>{};
      row.forEach((k, v) {
        if (!mappedKeys.contains(k)) {
          extra[k] = v;
        }
      });
      if (extra.isNotEmpty) {
        itemData['extra_data'] = extra.toString();
      }

      if (existing != null) {
        batch.update(
          'items',
          {'wh_stock': itemData['wh_stock'], 'br_stock': itemData['br_stock'], 'sold_stk': itemData['sold_stk'], 'updated_at': itemData['updated_at']},
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        updated++;
      } else {
        itemData['created_at'] = DateTime.now().toIso8601String();
        batch.insert('items', itemData);
        inserted++;
      }
    }

    await batch.commit(noResult: true);
    await addAuditLog('استيراد تقرير', 'تم استيراد report: مضاف $inserted, محدث $updated, تخطي $skipped');
    return {'inserted': inserted, 'updated': updated, 'skipped': skipped};
  }
}
