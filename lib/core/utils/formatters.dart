import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'it_IT');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'it_IT');
  static final DateFormat _dayMonthFormat = DateFormat('dd MMM', 'it_IT');
  static final DateFormat _shortDayFormat = DateFormat('EEE', 'it_IT');

  /// Formatta un importo in valuta (€)
  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Formatta un importo compatto (senza decimali se .00)
  static String currencyCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      return NumberFormat.currency(
        locale: 'it_IT',
        symbol: '€',
        decimalDigits: 0,
      ).format(amount);
    }
    return _currencyFormat.format(amount);
  }

  /// Formatta una data (dd/MM/yyyy)
  static String date(DateTime date) {
    return _dateFormat.format(date);
  }

  /// Formatta una data con ora (dd/MM/yyyy HH:mm)
  static String dateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Formatta mese e anno (Gennaio 2026)
  static String monthYear(DateTime date) {
    final formatted = _monthYearFormat.format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Formatta giorno e mese abbreviato (15 Gen)
  static String dayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// Formatta giorno della settimana abbreviato (Lun, Mar, ...)
  static String shortDay(DateTime date) {
    return _shortDayFormat.format(date);
  }

  /// Formatta data relativa (Oggi, Ieri, dd/MM/yyyy)
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(dateOnly).inDays;
    
    if (difference == 0) {
      return 'Oggi';
    } else if (difference == 1) {
      return 'Ieri';
    } else if (difference == -1) {
      return 'Domani';
    } else if (difference > 0 && difference < 7) {
      return '$difference giorni fa';
    } else {
      return _dateFormat.format(date);
    }
  }
}
