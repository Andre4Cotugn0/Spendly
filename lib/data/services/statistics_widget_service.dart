import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'dart:convert' show jsonEncode;
import '../database/database_helper.dart';

/// Servizio per il widget di statistiche mensili (solo Android)
class StatisticsWidgetService {
  static final StatisticsWidgetService instance = StatisticsWidgetService._init();
  
  static const String _appGroupId = 'group.com.andre4cotugn0.spendly';
  static const String _widgetName = 'StatisticsWidget';

  StatisticsWidgetService._init();

  /// Inizializza il servizio widget
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await _initializeAndroid();
    } catch (e) {
      debugPrint('Errore inizializzazione statistics widget: $e');
    }
  }

  Future<void> _initializeAndroid() async {
    try {
      await updateStatistics();
      debugPrint('Statistics Widget Android inizializzato');
    } catch (e) {
      debugPrint('Errore inizializzazione Android statistics widget: $e');
    }
  }

  /// Aggiorna tutte le statistiche del widget
  Future<void> updateStatistics() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final now = DateTime.now();
      final db = DatabaseHelper.instance;
      
      // Totale mese corrente
      final monthTotal = await db.getTotalByMonth(now.year, now.month);
      
      // Media giornaliera
      final avgDaily = await db.getAverageDaily(now.year, now.month);
      
      // Totale ultimi 6 mesi
      final monthlyTotals = await db.getMonthlyTotals(months: 6);
      
      // Top spese del mese
      final topExpenses = await db.getTopExpenses(now.year, now.month, limit: 3);
      
      // Totale per categoria
      final categoryTotals = await db.getTotalByCategory(now.year, now.month);
      
      // Formattazione
      final currencyFormat = NumberFormat.currency(
        locale: 'it_IT',
        symbol: '€',
        decimalDigits: 2,
      );
      
      final monthFormat = DateFormat('MMMM yyyy', 'it_IT');
      String formattedMonth = monthFormat.format(now);
      formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
      
      // Salva i dati
      await HomeWidget.saveWidgetData<String>(
        'monthTotal',
        currencyFormat.format(monthTotal),
      );
      
      await HomeWidget.saveWidgetData<String>(
        'avgDaily',
        currencyFormat.format(avgDaily),
      );
      
      await HomeWidget.saveWidgetData<String>(
        'monthLabel',
        formattedMonth,
      );
      
      // Top spese come JSON
      final topExpensesJson = jsonEncode(
        topExpenses.map((e) => {
          'amount': e.amount.toStringAsFixed(2),
          'categoryId': e.categoryId,
          'description': e.description ?? 'Senza descrizione',
        }).toList(),
      );
      await HomeWidget.saveWidgetData<String>(
        'topExpenses',
        topExpensesJson,
      );
      
      // Categoria con maggiore spesa
      if (categoryTotals.isNotEmpty) {
        final topCategory = categoryTotals.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        final topCatName = await _getCategoryName(topCategory.key);
        await HomeWidget.saveWidgetData<String>(
          'topCategory',
          '$topCatName: ${currencyFormat.format(topCategory.value)}',
        );
      }
      
      // Trend (ultimi 6 mesi)
      if (monthlyTotals.isNotEmpty) {
        final trend = monthlyTotals.map((m) => m['total'].toString()).join(',');
        await HomeWidget.saveWidgetData<String>('trend', trend);
      }
      
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      debugPrint('Statistics Widget aggiornato: €$monthTotal');
    } catch (e) {
      debugPrint('Errore aggiornamento statistics widget: $e');
    }
  }

  Future<String> _getCategoryName(String categoryId) async {
    try {
      final category = await DatabaseHelper.instance.getAllCategories()
          .then((cats) => cats.firstWhere((c) => c.id == categoryId));
      return category.name;
    } catch (_) {
      return 'Categoria';
    }
  }

  /// Aggiorna il widget dopo cambio mese
  Future<void> updateForMonthChange() async {
    await updateStatistics();
  }
}
