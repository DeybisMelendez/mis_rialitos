import 'package:flutter/material.dart';
import '../db.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedMonth = DateTime.now();
  final db = DB();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    });
  }

  Future<double> getTotalAccountsBalance() async {
    final accounts = await db.getAllAccounts();
    double total = 0;
    for (var a in accounts) {
      total += a['balance'] as double;
    }
    return total;
  }

  Future<List<Map<String, dynamic>>> getMonthlyExpenses() async {
    final all = await db.getAllExpenses();
    return all.where((e) {
      final date = DateTime.parse(e['date']);
      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyIncomes() async {
    final all = await db.getAllIncomes();
    return all.where((i) {
      final date = DateTime.parse(i['date']);
      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyTransactions() async {
    final all = await db.getAllAccountTransactions();
    return all.where((t) {
      final date = DateTime.parse(t['date']);
      return date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();
  }

  String formatCurrency(double value) {
    final f = NumberFormat.currency(locale: 'es_NI', symbol: 'C\$');
    return f.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rialitos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gastos'),
            Tab(text: 'Ingresos'),
            Tab(text: 'Transacciones'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Total de cuentas
          FutureBuilder<double>(
            future: getTotalAccountsBalance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Total de cuentas: ${formatCurrency(snapshot.data!)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),

          // Selector de mes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.arrow_left),
              ),
              Text(
                DateFormat.yMMMM('es').format(selectedMonth),
                style: const TextStyle(fontSize: 16),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.arrow_right),
              ),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // -------- GASTOS --------
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: getMonthlyExpenses(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final expenses = snapshot.data!;
                    double total = expenses.fold(
                      0,
                      (sum, e) => sum + e['amount'],
                    );
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final e = expenses[index];
                              return ListTile(
                                title: Text('${e['notes']}'),
                                subtitle: Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.parse(e['date'])),
                                ),
                                trailing: Text(formatCurrency(e['amount'])),
                                onTap: () {
                                  // Aquí podrías navegar a detalle
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total Gastos: ${formatCurrency(total)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // -------- INGRESOS --------
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: getMonthlyIncomes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final incomes = snapshot.data!;
                    double total = incomes.fold(
                      0,
                      (sum, i) => sum + i['amount'],
                    );
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: incomes.length,
                            itemBuilder: (context, index) {
                              final i = incomes[index];
                              return ListTile(
                                title: Text('${i['notes']}'),
                                subtitle: Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.parse(i['date'])),
                                ),
                                trailing: Text(formatCurrency(i['amount'])),
                                onTap: () {},
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total Ingresos: ${formatCurrency(total)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                // -------- TRANSACCIONES --------
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: getMonthlyTransactions(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final transactions = snapshot.data!;
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final t = transactions[index];
                        return ListTile(
                          title: Text('Monto: ${formatCurrency(t['amount'])}'),
                          subtitle: Text(
                            DateFormat(
                              'dd/MM/yyyy',
                            ).format(DateTime.parse(t['date'])),
                          ),
                          onTap: () {},
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Navegar a agregar gasto/ingreso/transacción
        },
      ),
    );
  }
}
