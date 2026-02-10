import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import '../database/database_helper.dart';

/// Servizio per gestire il widget della home screen Android
class HomeWidgetService {
  static final HomeWidgetService instance = HomeWidgetService._init();
  static const String _appGroupId = 'group.com.andre4cotugn0.spendly';
  static const String _androidWidgetName = 'ExpenseWidgetProvider';

  HomeWidgetService._init();

  /// Inizializza il widget
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('Errore inizializzazione widget: $e');
    }
  }

  /// Aggiorna i dati del widget con il totale del mese corrente
  Future<void> updateWidget() async {
    // Il widget è supportato solo su Android
    if (!Platform.isAndroid) return;
    
    try {
      final now = DateTime.now();
      final total = await DatabaseHelper.instance.getTotalByMonth(now.year, now.month);
      
      // Formatta il totale
      final currencyFormat = NumberFormat.currency(
        locale: 'it_IT',
        symbol: '€',
        decimalDigits: 2,
      );
      final formattedTotal = currencyFormat.format(total);
      
      // Formatta il mese
      final monthFormat = DateFormat('MMMM yyyy', 'it_IT');
      String formattedMonth = monthFormat.format(now);
      formattedMonth = formattedMonth[0].toUpperCase() + formattedMonth.substring(1);
      
      // Salva i dati per il widget
      await HomeWidget.saveWidgetData<String>('total', formattedTotal);
      await HomeWidget.saveWidgetData<String>('month', formattedMonth);
      
      // Aggiorna il widget Android
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: _androidWidgetName,
      );
      
      debugPrint('Widget aggiornato: $formattedTotal - $formattedMonth');
    } catch (e) {
      debugPrint('Errore aggiornamento widget: $e');
    }
  }
}
