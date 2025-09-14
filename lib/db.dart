import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  static final DB _instance = DB._internal();
  static Database? _db;

  DB._internal();
  factory DB() => _instance;

  Future<Database> getDB() async {
    if (_db != null) return _db!;
    _db = await _initDB('mis_rialitos.db');
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        balance REAL NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0,1)),
      )
    ''');
    await db.execute('''
      CREATE TABLE account_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          from_account_id INTEGER NOT NULL,
          to_account_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          description TEXT,
          FOREIGN KEY(from_account_id) REFERENCES accounts(id),
          FOREIGN KEY(to_account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        monthly_budget REAL,
        is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0,1)),
      )
    ''');

    await db.execute('''
      CREATE TABLE income_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        monthly_budget REAL,
        is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0,1)),
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        account_id INTEGER,
        notes TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES expense_categories(id),
        FOREIGN KEY(account_id) REFERENCES accounts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        account_id INTEGER,
        notes TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES income_categories(id),
        FOREIGN KEY(account_id) REFERENCES accounts(id)
      )
    ''');
  }

  // ---------------- CUENTAS ----------------
  Future<int> createAccount(String name, double balance, String icon) async {
    final db = await getDB();
    return await db.insert('accounts', {
      'name': name,
      'balance': balance,
      'icon': icon,
    });
  }

  Future<Map<String, dynamic>?> getAccount(int id) async {
    final db = await getDB();
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllAccounts() async {
    final db = await getDB();
    return await db.query('accounts');
  }

  Future<int> updateBalanceToAccount(int id, double amount) async {
    final db = await getDB();
    final account = await getAccount(id);
    return await db.update(
      'accounts',
      {'balance': account?['balance'] + amount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateAccount(
    int id,
    String name,
    String icon,
    double balance,
  ) async {
    final db = await getDB();
    return await db.update(
      'accounts',
      {'balance': balance, 'name': name, 'icon': icon},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await getDB();
    return await db.update(
      'accounts',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- TRANSACCIONES ENTRE CUENTAS ----------------
  Future<int> createAccountTransaction({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    final db = await getDB();
    await updateBalanceToAccount(fromAccountId, -amount);
    await updateBalanceToAccount(toAccountId, amount);

    return await db.insert('account_transactions', {
      'from_account_id': fromAccountId,
      'to_account_id': toAccountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    });
  }

  Future<Map<String, dynamic>?> getAccountTransaction(int id) async {
    final db = await getDB();
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllAccountTransactions() async {
    final db = await getDB();
    return await db.query('account_transactions', orderBy: 'date DESC');
  }

  Future<int> deleteAccountTransaction(int id) async {
    final db = await getDB();
    final accountTransaction = await getAccountTransaction(id);
    await updateBalanceToAccount(
      accountTransaction?['from'],
      accountTransaction?['amount'],
    );
    await updateBalanceToAccount(
      accountTransaction?['to'],
      -accountTransaction?['amoun'],
    );
    return await db.delete(
      'account_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- CATEGORÍAS ----------------
  Future<int> createExpenseCategory(String name, String icon) async {
    final db = await getDB();
    return await db.insert('expense_categories', {'name': name, 'icon': icon});
  }

  Future<List<Map<String, dynamic>>> getAllExpenseCategories() async {
    final db = await getDB();
    return await db.query('expense_categories');
  }

  Future<int> deleteExpenseCategory(int id) async {
    final db = await getDB();
    return await db.update(
      'expense_categories',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> createIncomeCategory(String name, String icon) async {
    final db = await getDB();
    return await db.insert('income_categories', {'name': name, 'icon': icon});
  }

  Future<List<Map<String, dynamic>>> getAllIncomeCategories() async {
    final db = await getDB();
    return await db.query('income_categories');
  }

  Future<int> deleteIncomeCategory(int id) async {
    final db = await getDB();
    return await db.update(
      'income_categories',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- GASTOS ----------------
  Future<int> createExpense(
    int categoryId,
    int accountId,
    double amount,
    DateTime date,
    String notes,
  ) async {
    final db = await getDB();
    return await db.insert('expenses', {
      'amount': amount,
      'date': date.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'category_id': categoryId,
      'account_id': accountId,
      'notes': notes,
    });
  }

  Future<Map<String, dynamic>?> getExpense(int id) async {
    final db = await getDB();
    final result = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await getDB();
    return await db.query('expenses', orderBy: 'date DESC');
  }

  Future<int> updateExpense(
    int id,
    int categoryId,
    int accountId,
    double amount,
    DateTime date,
    String notes,
  ) async {
    final db = await getDB();
    final actualExpense = await getExpense(id);
    await updateBalanceToAccount(accountId, actualExpense?['amount']);
    await updateBalanceToAccount(accountId, -amount);
    return await db.update(
      'expenses',
      {
        'amount': amount,
        'date': date.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'category_id': categoryId,
        'account_id': accountId,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await getDB();
    final expense = await getExpense(id);
    await updateBalanceToAccount(expense?['account_id'], expense?['amount']);
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- INGRESOS ----------------
  Future<int> createIncome(
    int categoryId,
    int accountId,
    String title,
    double amount,
    DateTime date,
  ) async {
    final db = await getDB();
    return await db.insert('incomes', {
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'category_id': categoryId,
      'account_id': accountId,
    });
  }

  Future<Map<String, dynamic>?> getIncome(int id) async {
    final db = await getDB();
    final result = await db.query('incomes', where: 'id = ?', whereArgs: [id]);
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAllIncomes() async {
    final db = await getDB();
    return await db.query('incomes', orderBy: 'date DESC');
  }

  Future<int> updateIncome(
    int id,
    int categoryId,
    int accountId,
    double amount,
    DateTime date,
    String notes,
  ) async {
    final db = await getDB();
    final actualIncome = await getIncome(id);
    await updateBalanceToAccount(accountId, -actualIncome?['amount']);
    await updateBalanceToAccount(accountId, amount);
    return await db.update(
      'incomes',
      {
        'amount': amount,
        'date': date.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'category_id': categoryId,
        'account_id': accountId,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await getDB();
    final income = await getIncome(id);
    await updateBalanceToAccount(income?['account_id'], -income?['amount']);
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await getDB();
    await db.close();
  }
}
