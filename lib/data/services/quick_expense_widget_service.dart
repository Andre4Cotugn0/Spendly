import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import '../database/database_helper.dart';

/// Servizio per il widget di inserimento rapido spese
/// Supporta Android (home_widget) e iOS (app clips / extension)
class QuickExpenseWidgetService {
  static final QuickExpenseWidgetService instance = QuickExpenseWidgetService._init();
  
  static const String _appGroupId = 'group.com.andre4cotugn0.spendly';
  static const String _widgetName = 'QuickExpenseWidget';

  QuickExpenseWidgetService._init();

  /// Inizializza il servizio widget
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      if (Platform.isAndroid) {
        await _initializeAndroid();
      } else if (Platform.isIOS) {
        await _initializeIOS();
      }
    } catch (e) {
      debugPrint('Errore inizializzazione quick expense widget: $e');
    }
  }

  Future<void> _initializeAndroid() async {
    try {
      // Carica le categorie per il widget Android
      final categories = await DatabaseHelper.instance.getAllCategories();
      
      // Salva le categorie come JSON per il widget
      final categoriesJson = categories
          .map((c) => '''{{"id":"${c.id}","name":"${c.name}","color":"${c.color.toARGB32()}","icon":"${c.iconName}"}}''')
          .join(',');
      
      await HomeWidget.saveWidgetData<String>('categoriesJson', categoriesJson);
      
      // Aggiorna il widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
      );
      
      debugPrint('Quick Expense Widget Android inizializzato');
    } catch (e) {
      debugPrint('Errore inizializzazione Android widget: $e');
    }
  }

  Future<void> _initializeIOS() async {
    try {
      // Su iOS, salva dati nel shared app group per l'app clip
      // Salva l'ultimo importo e categoria
      final lastExpense = await DatabaseHelper.instance
          .getExpensesByMonth(DateTime.now().year, DateTime.now().month)
          .then((e) => e.isNotEmpty ? e.last : null);
      
      if (lastExpense != null) {
        await HomeWidget.saveWidgetData<String>(
          'lastAmount',
          lastExpense.amount.toStringAsFixed(2),
        );
        await HomeWidget.saveWidgetData<String>(
          'lastCategoryId',
          lastExpense.categoryId,
        );
      }
      
      debugPrint('Quick Expense Widget iOS inizializzato');
    } catch (e) {
      debugPrint('Errore inizializzazione iOS widget: $e');
    }
  }

  /// Aggiorna il widget dopo aver aggiunto una spesa
  Future<void> updateAfterExpense(String categoryId, double amount) async {
    try {
      // Salva l'ultima spesa aggiunta
      await HomeWidget.saveWidgetData<String>('lastAmount', amount.toStringAsFixed(2));
      await HomeWidget.saveWidgetData<String>('lastCategoryId', categoryId);
      
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          name: _widgetName,
          androidName: _widgetName,
        );
      }
      
      debugPrint('Quick Expense Widget aggiornato: €$amount');
    } catch (e) {
      debugPrint('Errore aggiornamento quick expense widget: $e');
    }
  }

  /// Aggiorna il widget con il totale del mese
  Future<void> updateWithMonthTotal() async {
    try {
      final now = DateTime.now();
      final total = await DatabaseHelper.instance.getTotalByMonth(now.year, now.month);
      
      final currencyFormat = NumberFormat.currency(
        locale: 'it_IT',
        symbol: '€',
        decimalDigits: 2,
      );
      final formattedTotal = currencyFormat.format(total);
      
      await HomeWidget.saveWidgetData<String>('monthTotal', formattedTotal);
      
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          name: _widgetName,
          androidName: _widgetName,
        );
      }
      
      debugPrint('Quick Expense Widget totale aggiornato: $formattedTotal');
    } catch (e) {
      debugPrint('Errore aggiornamento totale widget: $e');
    }
  }
}
