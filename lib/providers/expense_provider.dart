import 'package:flutter/foundation.dart' hide Category;
import '../data/database/database_helper.dart';
import '../data/models/expense.dart';
import '../data/models/category.dart';
import '../data/models/subscription.dart';
import '../data/models/budget.dart';
import '../data/services/google_drive_service.dart';
import '../data/services/home_widget_service.dart';
import '../data/services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final GoogleDriveService _driveService = GoogleDriveService.instance;
  final HomeWidgetService _widgetService = HomeWidgetService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  List<Subscription> _subscriptions = [];
  List<Budget> _budgets = [];
  bool _isLoading = false;
  String? _error;
  bool _isBackingUp = false;
  DateTime? _lastBackupDate;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // Getters
  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  List<Subscription> get subscriptions => _subscriptions;
  List<Subscription> get activeSubscriptions => _subscriptions.where((s) => s.isActive).toList();
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBackingUp => _isBackingUp;
  DateTime? get lastBackupDate => _lastBackupDate;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  bool get isGoogleSignedIn => _driveService.isSignedIn;
  String? get userEmail => _driveService.userEmail;
  String? get userName => _driveService.userName;
  String? get userPhoto => _driveService.userPhoto;

  /// Carica tutti i dati iniziali
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _widgetService.initialize();
      await _notificationService.initialize();

      _categories = await _db.getAllCategories();
      _expenses = await _db.getExpensesByMonth(_selectedYear, _selectedMonth);
      _subscriptions = await _db.getAllSubscriptions();
      _budgets = await _db.getBudgetsByMonth(_selectedYear, _selectedMonth);

      await _widgetService.updateWidget();

      // Pianifica notifiche abbonamenti
      await _notificationService.scheduleAllSubscriptionReminders(activeSubscriptions);

      // Login silenzioso Google
      await _driveService.signInSilently();
      if (_driveService.isSignedIn) {
        _lastBackupDate = await _driveService.getLastBackupDate();
      }
    } catch (e) {
      _error = 'Errore caricamento dati: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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
      await _autoBackup();
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

  // ===== BUDGETS =====

  Future<bool> setBudget(Budget budget) async {
    try {
      await _db.upsertBudget(budget);
      _budgets = await _db.getBudgetsByMonth(_selectedYear, _selectedMonth);
      await _autoBackup();
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
      await _autoBackup();
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

  // ===== GOOGLE DRIVE =====

  Future<bool> signInGoogle() async {
    try {
      final success = await _driveService.signIn();
      if (success) {
        _lastBackupDate = await _driveService.getLastBackupDate();
      }
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Errore login Google: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOutGoogle() async {
    await _driveService.signOut();
    _lastBackupDate = null;
    notifyListeners();
  }

  Future<bool> backupToGoogleDrive() async {
    if (!_driveService.isSignedIn) {
      final success = await signInGoogle();
      if (!success) return false;
    }
    _isBackingUp = true;
    notifyListeners();
    try {
      final success = await _driveService.backup();
      if (success) _lastBackupDate = DateTime.now();
      return success;
    } catch (e) {
      _error = 'Errore backup: $e';
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  Future<bool> restoreFromGoogleDrive() async {
    if (!_driveService.isSignedIn) {
      final success = await signInGoogle();
      if (!success) return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final success = await _driveService.restore();
      if (success) await loadData();
      return success;
    } catch (e) {
      _error = 'Errore ripristino: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _autoBackup() async {
    if (_driveService.isSignedIn) {
      _isBackingUp = true;
      notifyListeners();
      try {
        final success = await _driveService.backup();
        if (success) _lastBackupDate = DateTime.now();
      } catch (e) {
        debugPrint('Errore auto-backup: $e');
      } finally {
        _isBackingUp = false;
        notifyListeners();
      }
    }
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
