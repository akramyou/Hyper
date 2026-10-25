import 'package:flutter/material.dart';
import 'package:hyper_dammam3/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, bool> settings = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    settings = await DatabaseHelper.instance.getNotificationSettings();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('إدارة التنبيهات'),
                    subtitle: Text('تفعيل أو إيقاف أنواع التنبيهات'),
                  ),
                  SwitchListTile(
                    title: const Text('تنبيهات منتهية الصلاحية'),
                    value: settings['expired'] ?? true,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setNotificationSetting('expired_enabled', v);
                      setState(() => settings['expired'] = v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تنبيهات أقل من أسبوع'),
                    value: settings['less_than_week'] ?? true,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setNotificationSetting('less_than_week_enabled', v);
                      setState(() => settings['less_than_week'] = v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تنبيهات أقل من شهر'),
                    value: settings['less_than_month'] ?? true,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setNotificationSetting('less_than_month_enabled', v);
                      setState(() => settings['less_than_month'] = v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تنبيهات شهر إلى شهرين'),
                    value: settings['one_to_two_months'] ?? true,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setNotificationSetting('one_to_two_months_enabled', v);
                      setState(() => settings['one_to_two_months'] = v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تنبيهات شهرين إلى 3 أشهر'),
                    value: settings['two_to_three_months'] ?? true,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setNotificationSetting('two_to_three_months_enabled', v);
                      setState(() => settings['two_to_three_months'] = v);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('تنبيهات منخفض المخزون'),
                    value: settings['low_stock'] ?? true,
                    onChanged: (v) async {
                      await DatabaseHelper.instance.setNotificationSetting('low_stock_enabled', v);
                      setState(() => settings['low_stock'] = v);
                    },
                  ),
                  const Divider(),
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('عن التطبيق'),
                    subtitle: Text('نظام إدارة مخزون هايبر ماركت - الإصدار 1.0.0'),
                  ),
                ],
              ),
      ),
    );
  }
}
