import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class CsvExportService {
  CsvExportService._();
  static final CsvExportService instance = CsvExportService._();

  final DatabaseHelper _db = DatabaseHelper.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
    decimalDigits: 2,
  );

  /// Esporta tutte le spese in un file CSV e apre il foglio di condivisione.
  /// Restituisce `true` se l'export è andato a buon fine.
  Future<bool> exportExpenses() async {
    try {
      final data = await _db.exportAllData();
      final expenses = data['expenses'] as List<dynamic>? ?? [];
      final categories = data['categories'] as List<dynamic>? ?? [];

      final catMap = <String, String>{};
      for (final category in categories) {
        final map = category as Map<String, dynamic>;
        catMap[map['id'] as String] = map['name'] as String;
      }

      final rows = <List<String>>[
        ['Data', 'Importo', 'Categoria', 'Note'],
      ];

      for (final expense in expenses) {
        final map = expense as Map<String, dynamic>;
        final categoryId = map['category_id'] as String? ?? '';
        rows.add([
          _formatDate(map['date']),
          _formatCurrency(map['amount']),
          catMap[categoryId] ?? categoryId,
          map['description'] as String? ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter(
        fieldDelimiter: ';',
      ).convert(rows);

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'moneyra_export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvString);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Moneyra - Export spese');

      return true;
    } catch (e) {
      debugPrint('Errore export CSV: $e');
      return false;
    }
  }

  /// Esporta tutti i dati (spese, categorie, abbonamenti, debiti, budget)
  /// in un file CSV multi-sezione.
  Future<bool> exportAllData() async {
    try {
      final data = await _db.exportAllData();

      final categories = data['categories'] as List<dynamic>? ?? [];
      final expenses = data['expenses'] as List<dynamic>? ?? [];
      final subscriptions = data['subscriptions'] as List<dynamic>? ?? [];
      final budgets = data['budgets'] as List<dynamic>? ?? [];
      final debts = data['debts'] as List<dynamic>? ?? [];

      final catMap = <String, String>{};
      for (final category in categories) {
        final map = category as Map<String, dynamic>;
        catMap[map['id'] as String] = map['name'] as String;
      }

      final rows = <List<String>>[];

      rows.add(['--- SPESE ---']);
      rows.add(['Data', 'Importo', 'Categoria', 'Note']);
      for (final expense in expenses) {
        final map = expense as Map<String, dynamic>;
        final categoryId = map['category_id'] as String? ?? '';
        rows.add([
          _formatDate(map['date']),
          _formatCurrency(map['amount']),
          catMap[categoryId] ?? categoryId,
          map['description'] as String? ?? '',
        ]);
      }

      rows.add([]);
      rows.add(['--- CATEGORIE ---']);
      rows.add(['ID', 'Nome', 'Icona', 'Colore']);
      for (final category in categories) {
        final map = category as Map<String, dynamic>;
        rows.add([
          map['id'] as String? ?? '',
          map['name'] as String? ?? '',
          map['icon_name'] as String? ?? '',
          '${map['color'] ?? ''}',
        ]);
      }

      rows.add([]);
      rows.add(['--- ABBONAMENTI ---']);
      rows.add([
        'Nome',
        'Importo',
        'Frequenza',
        'Categoria',
        'Data rinnovo',
        'Attivo',
        'Note',
      ]);
      for (final subscription in subscriptions) {
        final map = subscription as Map<String, dynamic>;
        final categoryId = map['category_id'] as String? ?? '';
        rows.add([
          map['name'] as String? ?? '',
          _formatCurrency(map['amount']),
          map['frequency'] as String? ?? '',
          catMap[categoryId] ?? categoryId,
          _formatDate(map['next_payment_date']),
          _formatYesNo(map['is_active']),
          map['description'] as String? ?? '',
        ]);
      }

      rows.add([]);
      rows.add(['--- BUDGET ---']);
      rows.add(['Categoria', 'Importo', 'Mese', 'Anno']);
      for (final budget in budgets) {
        final map = Map<String, dynamic>.from(budget as Map);
        final categoryId = map['category_id'] as String?;
        rows.add([
          categoryId == null ? 'Globale' : (catMap[categoryId] ?? categoryId),
          _formatCurrency(map['amount']),
          '${map['month'] ?? ''}',
          '${map['year'] ?? ''}',
        ]);
      }

      rows.add([]);
      rows.add(['--- DEBITI ---']);
      rows.add([
        'Persona',
        'Importo',
        'Pagato',
        'Tipo',
        'Scadenza',
        'Saldato',
        'Note',
      ]);
      for (final debt in debts) {
        final map = debt as Map<String, dynamic>;
        rows.add([
          map['person_name'] as String? ?? '',
          _formatCurrency(map['amount']),
          _formatCurrency(map['amount_paid']),
          map['type'] as String? ?? '',
          _formatDate(map['due_date']),
          _formatYesNo(map['is_settled']),
          map['description'] as String? ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter(
        fieldDelimiter: ';',
      ).convert(rows);

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'moneyra_completo_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvString);

      await Share.shareXFiles([
        XFile(file.path),
      ], subject: 'Moneyra - Export completo');

      return true;
    } catch (e) {
      debugPrint('Errore export completo CSV: $e');
      return false;
    }
  }

  String _formatDate(dynamic value) {
    if (value is! String || value.isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    return _dateFormat.format(parsed);
  }

  String _formatCurrency(dynamic value) {
    if (value == null) {
      return '';
    }

    final numericValue = switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };

    if (numericValue == null) {
      return '$value';
    }

    return _currencyFormat.format(numericValue);
  }

  String _formatYesNo(dynamic value) {
    final isEnabled = switch (value) {
      bool flag => flag,
      num number => number != 0,
      String text => text == 'true' || text == '1',
      _ => false,
    };

    return isEnabled ? 'Si' : 'No';
  }
}
