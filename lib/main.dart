import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  initializeDateFormatting('es_NI');
  runApp(const MisRialitosApp());
}

class MisRialitosApp extends StatelessWidget {
  const MisRialitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Rialitos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {'/': (context) => const DashboardScreen()},
    );
  }
}
