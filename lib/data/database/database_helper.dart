import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/subscription.dart';
import '../models/budget.dart';
import '../models/debt.dart';
import '../constants/default_categories.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('traccia_spese.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_name TEXT NOT NULL,
        color INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        frequency TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        next_payment_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        description TEXT,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_days_before INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(category_id, month, year)
      )
    ''');

    await db.execute('''
      CREATE TABLE category_keywords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id TEXT NOT NULL,
        keyword TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        amount REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        due_date TEXT,
        is_settled INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    for (final category in DefaultCategories.categories) {
      await db.insert('categories', category.toMap());
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS subscriptions (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          category_id TEXT NOT NULL,
          frequency TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          next_payment_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          description TEXT,
          reminder_enabled INTEGER NOT NULL DEFAULT 1,
          reminder_days_before INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY,
          category_id TEXT,
          amount REAL NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          UNIQUE(category_id, month, year)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS category_keywords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id TEXT NOT NULL,
          keyword TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id)
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS debts (
          id TEXT PRIMARY KEY,
          person_name TEXT NOT NULL,
          amount REAL NOT NULL,
          amount_paid REAL NOT NULL DEFAULT 0,
          type TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          due_date TEXT,
          is_settled INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ===== CATEGORIES =====

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'is_default DESC, name ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await database;
    final result = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteCategory(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'category_id = ?', whereArgs: [id]);
    await db.delete('subscriptions', where: 'category_id = ?', whereArgs: [id]);
    await db.delete('category_keywords', where: 'category_id = ?', whereArgs: [id]);
    return await db.delete('categories', where: 'id = ? AND is_default = 0', whereArgs: [id]);
  }

  // ===== EXPENSES =====

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC, created_at DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getRecentExpenses({int limit = 10}) async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC, created_at DESC', limit: limit);
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> searchExpenses(String query, {
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (query.isNotEmpty) {
      where.add('(description LIKE ? OR category_id IN (SELECT id FROM categories WHERE name LIKE ?))');
      args.addAll(['%$query%', '%$query%']);
    }
    if (categoryId != null) { where.add('category_id = ?'); args.add(categoryId); }
    if (startDate != null) { where.add('date >= ?'); args.add(startDate.toIso8601String()); }
    if (endDate != null) { where.add('date <= ?'); args.add(endDate.toIso8601String()); }
    if (minAmount != null) { where.add('amount >= ?'); args.add(minAmount); }
    if (maxAmount != null) { where.add('amount <= ?'); args.add(maxAmount); }

    final result = await db.query(
      'expenses',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ===== SUBSCRIPTIONS =====

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await database;
    final result = await db.query('subscriptions', orderBy: 'is_active DESC, name ASC');
    return result.map((map) => Subscription.fromMap(map)).toList();
  }

  Future<List<Subscription>> getActiveSubscriptions() async {
    final db = await database;
    final result = await db.query('subscriptions', where: 'is_active = 1', orderBy: 'next_payment_date ASC');
    return result.map((map) => Subscription.fromMap(map)).toList();
  }

  Future<int> insertSubscription(Subscription sub) async {
    final db = await database;
    return await db.insert('subscriptions', sub.toMap());
  }

  Future<int> updateSubscription(Subscription sub) async {
    final db = await database;
    return await db.update('subscriptions', sub.toMap(), where: 'id = ?', whereArgs: [sub.id]);
  }

  Future<int> deleteSubscription(String id) async {
    final db = await database;
    return await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalMonthlySubscriptions() async {
    final subs = await getActiveSubscriptions();
    return subs.fold<double>(0.0, (sum, s) => sum + s.monthlyCost);
  }

  Future<double> getTotalYearlySubscriptions() async {
    final subs = await getActiveSubscriptions();
    return subs.fold<double>(0.0, (sum, s) => sum + s.yearlyCost);
  }

  Future<List<Subscription>> getUpcomingPayments({int days = 7}) async {
    final db = await database;
    final now = DateTime.now();
    final limit = now.add(Duration(days: days));
    final result = await db.query(
      'subscriptions',
      where: 'is_active = 1 AND next_payment_date >= ? AND next_payment_date <= ?',
      whereArgs: [now.toIso8601String(), limit.toIso8601String()],
      orderBy: 'next_payment_date ASC',
    );
    return result.map((map) => Subscription.fromMap(map)).toList();
  }

  // ===== BUDGETS =====

  Future<List<Budget>> getBudgetsByMonth(int year, int month) async {
    final db = await database;
    final result = await db.query('budgets', where: 'month = ? AND year = ?', whereArgs: [month, year]);
    return result.map((map) => Budget.fromMap(map)).toList();
  }

  Future<Budget?> getGlobalBudget(int year, int month) async {
    final db = await database;
    final result = await db.query('budgets', where: 'category_id IS NULL AND month = ? AND year = ?', whereArgs: [month, year]);
    if (result.isEmpty) return null;
    return Budget.fromMap(result.first);
  }

  Future<int> upsertBudget(Budget budget) async {
    final db = await database;
    final existing = await db.query(
      'budgets',
      where: budget.categoryId != null
          ? 'category_id = ? AND month = ? AND year = ?'
          : 'category_id IS NULL AND month = ? AND year = ?',
      whereArgs: budget.categoryId != null
          ? [budget.categoryId, budget.month, budget.year]
          : [budget.month, budget.year],
    );
    if (existing.isNotEmpty) {
      return await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [existing.first['id']]);
    }
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ===== CATEGORY KEYWORDS =====

  Future<Map<String, List<String>>> getAllCategoryKeywords() async {
    final db = await database;
    final result = await db.query('category_keywords');
    final Map<String, List<String>> keywords = {};
    for (final row in result) {
      final catId = row['category_id'] as String;
      keywords.putIfAbsent(catId, () => []).add(row['keyword'] as String);
    }
    return keywords;
  }

  Future<void> setCategoryKeywords(String categoryId, List<String> keywords) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('category_keywords', where: 'category_id = ?', whereArgs: [categoryId]);
      for (final keyword in keywords) {
        await txn.insert('category_keywords', {'category_id': categoryId, 'keyword': keyword.toLowerCase()});
      }
    });
  }

  // ===== DEBTS =====

  Future<List<Debt>> getAllDebts() async {
    final db = await database;
    final result = await db.query('debts', orderBy: 'is_settled ASC, due_date ASC, created_at DESC');
    return result.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getActiveDebts() async {
    final db = await database;
    final result = await db.query('debts', where: 'is_settled = 0', orderBy: 'due_date ASC, created_at DESC');
    return result.map((map) => Debt.fromMap(map)).toList();
  }

  Future<List<Debt>> getDebtsByType(DebtType type) async {
    final db = await database;
    final result = await db.query('debts', where: 'type = ? AND is_settled = 0', whereArgs: [type.name], orderBy: 'due_date ASC');
    return result.map((map) => Debt.fromMap(map)).toList();
  }

  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    return await db.insert('debts', debt.toMap());
  }

  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    return await db.update('debts', debt.toMap(), where: 'id = ?', whereArgs: [debt.id]);
  }

  Future<int> deleteDebt(String id) async {
    final db = await database;
    return await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalIOwe() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount - amount_paid), 0) as total FROM debts WHERE type = 'iOwe' AND is_settled = 0",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalOwedToMe() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COALESCE(SUM(amount - amount_paid), 0) as total FROM debts WHERE type = 'owedToMe' AND is_settled = 0",
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ===== STATISTICS =====

  Future<double> getTotalByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getTotalByCategory(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final result = await db.rawQuery(
      'SELECT category_id, COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ? GROUP BY category_id',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    final Map<String, double> totals = {};
    for (final row in result) {
      totals[row['category_id'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  Future<List<Map<String, dynamic>>> getDailyTotals(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    return await db.rawQuery(
      'SELECT DATE(date) as day, COALESCE(SUM(amount), 0) as total FROM expenses WHERE date >= ? AND date <= ? GROUP BY DATE(date) ORDER BY day ASC',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
  }

  Future<double> getAverageDaily(int year, int month) async {
    final total = await getTotalByMonth(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    int daysToUse = daysInMonth;
    if (year == today.year && month == today.month) {
      daysToUse = today.day;
    }
    return daysToUse > 0 ? total / daysToUse : 0;
  }

  Future<List<Expense>> getTopExpenses(int year, int month, {int limit = 5}) async {
    final db = await database;
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'amount DESC',
      limit: limit,
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals({int months = 6}) async {
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final total = await getTotalByMonth(date.year, date.month);
      results.add({'year': date.year, 'month': date.month, 'total': total});
    }
    return results;
  }

  // ===== BACKUP/EXPORT =====

  Future<Map<String, dynamic>> exportAllData() async {
    final categories = await getAllCategories();
    final expenses = await getAllExpenses();
    final subscriptions = await getAllSubscriptions();
    final db = await database;
    final budgets = await db.query('budgets');
    final keywords = await db.query('category_keywords');
    final debts = await getAllDebts();

    return {
      'version': 3,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
      'budgets': budgets,
      'category_keywords': keywords,
      'debts': debts.map((d) => d.toJson()).toList(),
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
      await txn.delete('subscriptions');
      await txn.delete('budgets');
      await txn.delete('category_keywords');
      await txn.delete('debts');
      await txn.delete('categories');

      for (final catData in (data['categories'] as List<dynamic>)) {
        await txn.insert('categories', Category.fromJson(catData as Map<String, dynamic>).toMap());
      }
      for (final expData in (data['expenses'] as List<dynamic>)) {
        await txn.insert('expenses', Expense.fromJson(expData as Map<String, dynamic>).toMap());
      }
      if (data['subscriptions'] != null) {
        for (final subData in (data['subscriptions'] as List<dynamic>)) {
          await txn.insert('subscriptions', Subscription.fromJson(subData as Map<String, dynamic>).toMap());
        }
      }
      if (data['budgets'] != null) {
        for (final b in (data['budgets'] as List<dynamic>)) {
          await txn.insert('budgets', Map<String, dynamic>.from(b as Map));
        }
      }
      if (data['category_keywords'] != null) {
        for (final kw in (data['category_keywords'] as List<dynamic>)) {
          await txn.insert('category_keywords', {'category_id': kw['category_id'], 'keyword': kw['keyword']});
        }
      }
      if (data['debts'] != null) {
        for (final debtData in (data['debts'] as List<dynamic>)) {
          await txn.insert('debts', Debt.fromJson(debtData as Map<String, dynamic>).toMap());
        }
      }
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
