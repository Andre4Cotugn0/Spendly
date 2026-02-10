import 'package:flutter/foundation.dart' hide Category;
import '../data/database/database_helper.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import '../data/models/subscription.dart';
import '../data/models/budget.dart';
import '../data/models/debt.dart';
import '../data/services/csv_export_service.dart';
import '../data/services/home_widget_service.dart';
import '../data/services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final CsvExportService _csvService = CsvExportService.instance;
  final HomeWidgetService _widgetService = HomeWidgetService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  List<Subscription> _subscriptions = [];
  List<Budget> _budgets = [];
  List<Debt> _debts = [];
  bool _isLoading = false;
  String? _error;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Getters
  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get activeSubscriptions => _subscriptions.where((s) => s.isActive).toList();
  List<Budget> get budgets => _budgets;
  List<Debt> get debts => _debts;
  List<Debt> get activeDebts => _debts.where((d) => !d.isSettled).toList();
  List<Debt> get settledDebts => _debts.where((d) => d.isSettled).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  /// Carica tutti i dati iniziali
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Carica categorie PRIMA (servono per le relazioni)
      try {
        _categories = await _db.getAllCategories();
      } catch (e) {
        debugPrint('Errore caricamento categorie: $e');
        _error = 'Errore caricamento categorie: $e';
      }

      // Carica tutti i dati in parallelo
      try {
        final results = await Future.wait([
          _db.getExpensesByMonth(_selectedYear, _selectedMonth),
          _db.getAllSubscriptions(),
          _db.getBudgetsByMonth(_selectedYear, _selectedMonth),
          _db.getAllDebts(),
        ]);
        _expenses = results[0] as List<Expense>;
        _subscriptions = results[1] as List<Subscription>;
        _budgets = results[2] as List<Budget>;
        _debts = results[3] as List<Debt>;
      } catch (e) {
        debugPrint('Errore caricamento dati principali: $e');
      }
    } catch (e) {
      _error = 'Errore caricamento dati: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Servizi secondari: fire-and-forget (non bloccano la UI)
    _initServicesInBackground();
  }

  /// Inizializza widget e notifiche senza bloccare il rendering.
  void _initServicesInBackground() {
    // Widget service
    Future(() async {
      try {
        await _widgetService.initialize();
        await _widgetService.updateWidget();
      } catch (e) {
        debugPrint('Errore widget service: $e');
      }
    });

    // Notification service
    Future(() async {
      try {
        await _notificationService.initialize();
        await _notificationService.scheduleAllSubscriptionReminders(activeSubscriptions);
      } catch (e) {
        debugPrint('Errore notification service: $e');
      }
    });

  }

  // ===== MONTH NAVIGATION =====

  Future<void> setSelectedMonth(int year, int month) async {
    _selectedYear = year;
    _selectedMonth = month;
    notifyListeners();
    try {
      _expenses = await _db.getExpensesByMonth(year, month);
      _budgets = await _db.getBudgetsByMonth(year, month);
    } catch (e) {
      _error = 'Errore caricamento spese: $e';
    }
    notifyListeners();
  }

  Future<void> previousMonth() async {
    int m = _selectedMonth - 1, y = _selectedYear;
    if (m < 1) { m = 12; y--; }
    await setSelectedMonth(y, m);
  }

  Future<void> nextMonth() async {
    int m = _selectedMonth + 1, y = _selectedYear;
    if (m > 12) { m = 1; y++; }
    await setSelectedMonth(y, m);
  }

  // ===== EXPENSES =====

  Future<bool> addExpense(Expense expense) async {
    try {
      await _db.insertExpense(expense);
      await _refreshExpenses();
      await _widgetService.updateWidget();
      await _checkBudgetAlert(expense);
      return true;
    } catch (e) {
      _error = 'Errore aggiunta spesa: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      await _db.updateExpense(expense);
      await _refreshExpenses();
      await _widgetService.updateWidget();
      return true;
    } catch (e) {
      _error = 'Errore aggiornamento spesa: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await _db.deleteExpense(id);
      await _refreshExpenses();
      await _widgetService.updateWidget();
      return true;
    } catch (e) {
      _error = 'Errore eliminazione spesa: $e';
      notifyListeners();
      return false;
    }
  }

  Future<List<Expense>> searchExpenses(String query, {
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
  }) async {
    return await _db.searchExpenses(query,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      minAmount: minAmount,
      maxAmount: maxAmount,
    );
  }

  Future<void> _refreshExpenses() async {
    _expenses = await _db.getExpensesByMonth(_selectedYear, _selectedMonth);
    notifyListeners();
  }

  // ===== CATEGORIES =====

  Future<bool> addCategory(Category category) async {
    try {
      await _db.insertCategory(category);
      _categories = await _db.getAllCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore aggiunta categoria: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await _db.updateCategory(category);
      _categories = await _db.getAllCategories();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore aggiornamento categoria: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final category = _categories.firstWhere((c) => c.id == id);
      if (category.isDefault) {
        _error = 'Non puoi eliminare categorie predefinite';
        notifyListeners();
        return false;
      }
      await _db.deleteCategory(id);
      _categories = await _db.getAllCategories();
      await _refreshExpenses();
      return true;
    } catch (e) {
      _error = 'Errore eliminazione categoria: $e';
      notifyListeners();
      return false;
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===== SUBSCRIPTIONS =====

  Future<bool> addSubscription(Subscription sub) async {
    try {
      await _db.insertSubscription(sub);
      _subscriptions = await _db.getAllSubscriptions();
      await _notificationService.scheduleSubscriptionReminder(sub);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore aggiunta abbonamento: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSubscription(Subscription sub) async {
    try {
      await _db.updateSubscription(sub);
      _subscriptions = await _db.getAllSubscriptions();
      if (sub.isActive && sub.reminderEnabled) {
        await _notificationService.scheduleSubscriptionReminder(sub);
      } else {
        await _notificationService.cancelSubscriptionReminder(sub.id);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore aggiornamento abbonamento: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSubscription(String id) async {
    try {
      await _db.deleteSubscription(id);
      _subscriptions = await _db.getAllSubscriptions();
      await _notificationService.cancelSubscriptionReminder(id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore eliminazione abbonamento: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleSubscription(String id) async {
    try {
      final sub = _subscriptions.firstWhere((s) => s.id == id);
      final updated = sub.copyWith(isActive: !sub.isActive);
      return await updateSubscription(updated);
    } catch (e) {
      return false;
    }
  }

  Future<double> getTotalMonthlySubscriptions() async {
    return await _db.getTotalMonthlySubscriptions();
  }

  Future<double> getTotalYearlySubscriptions() async {
    return await _db.getTotalYearlySubscriptions();
  }

  // ===== DEBTS =====

  Future<bool> addDebt(Debt debt) async {
    try {
      await _db.insertDebt(debt);
      _debts = await _db.getAllDebts();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore aggiunta debito: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDebt(Debt debt) async {
    try {
      await _db.updateDebt(debt);
      _debts = await _db.getAllDebts();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore aggiornamento debito: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDebt(String id) async {
    try {
      await _db.deleteDebt(id);
      _debts = await _db.getAllDebts();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore eliminazione debito: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> settleDebt(String id) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == id);
      final updated = debt.copyWith(isSettled: true, amountPaid: debt.amount);
      return await updateDebt(updated);
    } catch (e) {
      return false;
    }
  }

  Future<bool> addPaymentToDebt(String id, double paymentAmount) async {
    try {
      final debt = _debts.firstWhere((d) => d.id == id);
      final newPaid = debt.amountPaid + paymentAmount;
      final settled = newPaid >= debt.amount;
      final updated = debt.copyWith(
        amountPaid: newPaid.clamp(0, debt.amount),
        isSettled: settled,
      );
      return await updateDebt(updated);
    } catch (e) {
      return false;
    }
  }

  Future<double> getTotalIOwe() async {
    return await _db.getTotalIOwe();
  }

  Future<double> getTotalOwedToMe() async {
    return await _db.getTotalOwedToMe();
  }

  // ===== BUDGETS =====

  Future<bool> setBudget(Budget budget) async {
    try {
      await _db.upsertBudget(budget);
      _budgets = await _db.getBudgetsByMonth(_selectedYear, _selectedMonth);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Errore impostazione budget: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await _db.deleteBudget(id);
      _budgets = await _db.getBudgetsByMonth(_selectedYear, _selectedMonth);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Budget? getGlobalBudget() {
    try {
      return _budgets.firstWhere((b) => b.categoryId == null);
    } catch (_) {
      return null;
    }
  }

  Budget? getCategoryBudget(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkBudgetAlert(Expense expense) async {
    try {
      // Controlla budget globale
      final globalBudget = getGlobalBudget();
      if (globalBudget != null) {
        final total = await getTotalMonth();
        if (globalBudget.isExceeded(total)) {
          await _notificationService.showBudgetExceededNotification(
            'Totale mensile', total, globalBudget.amount,
          );
        }
      }

      // Controlla budget categoria
      final catBudget = getCategoryBudget(expense.categoryId);
      if (catBudget != null) {
        final catTotals = await getTotalByCategory();
        final catTotal = catTotals[expense.categoryId] ?? 0;
        if (catBudget.isExceeded(catTotal)) {
          final cat = getCategoryById(expense.categoryId);
          await _notificationService.showBudgetExceededNotification(
            cat?.name ?? 'Categoria', catTotal, catBudget.amount,
          );
        }
      }
    } catch (_) {}
  }

  // ===== STATISTICS =====

  Future<double> getTotalMonth() async {
    return await _db.getTotalByMonth(_selectedYear, _selectedMonth);
  }

  Future<Map<String, double>> getTotalByCategory() async {
    return await _db.getTotalByCategory(_selectedYear, _selectedMonth);
  }

  Future<List<Map<String, dynamic>>> getDailyTotals() async {
    return await _db.getDailyTotals(_selectedYear, _selectedMonth);
  }

  Future<double> getAverageDaily() async {
    return await _db.getAverageDaily(_selectedYear, _selectedMonth);
  }

  Future<List<Expense>> getTopExpenses({int limit = 5}) async {
    return await _db.getTopExpenses(_selectedYear, _selectedMonth, limit: limit);
  }

  Future<List<Map<String, dynamic>>> getMonthlyTotals({int months = 6}) async {
    return await _db.getMonthlyTotals(months: months);
  }

  // ===== CSV EXPORT =====

  Future<bool> exportExpensesCsv() async {
    return await _csvService.exportExpenses();
  }

  Future<bool> exportAllDataCsv() async {
    return await _csvService.exportAllData();
  }

  // ===== NOTIFICATIONS =====

  Future<void> setDailyReminder(bool enabled, {int hour = 20}) async {
    await _notificationService.setDailyReminder(enabled, hour: hour);
    notifyListeners();
  }

  Future<bool> isDailyReminderEnabled() async {
    return await _notificationService.isDailyReminderEnabled();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
