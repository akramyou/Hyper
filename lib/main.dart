import 'package:flutter/material.dart';
import 'package:hyper_dammam3/screens/dashboard_screen.dart';
import 'package:hyper_dammam3/screens/items_screen.dart';
import 'package:hyper_dammam3/screens/alerts_screen.dart';
import 'package:hyper_dammam3/screens/reports_screen.dart';
import 'package:hyper_dammam3/screens/import_report_screen.dart';
import 'package:hyper_dammam3/screens/analytics_screen.dart';
import 'package:hyper_dammam3/screens/settings_screen.dart';
import 'package:hyper_dammam3/screens/item_detail_screen.dart';
import 'package:hyper_dammam3/screens/add_edit_batch_screen.dart';
import 'package:hyper_dammam3/models/item_model.dart';

void main() {
  runApp(const HyperDammam3App());
}

class HyperDammam3App extends StatelessWidget {
  const HyperDammam3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هايبر ماركت - إدارة المخزون',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        fontFamily: 'Arabic',
      ),
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      localizationsDelegates: const [],
      home: const DashboardScreen(),
      routes: {
        '/items': (_) => const ItemsScreen(),
        '/alerts': (_) => const AlertsScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/import': (_) => const ImportReportScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/item_detail') {
          final item = settings.arguments as Item;
          return MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item));
        }
        if (settings.name == '/add_batch') {
          final itemId = settings.arguments as int;
          return MaterialPageRoute(builder: (_) => AddEditBatchScreen(itemId: itemId));
        }
        return null;
      },
    );
  }
}
