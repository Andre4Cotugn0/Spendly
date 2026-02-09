import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class ExportService {
  static final ExportService instance = ExportService._init();
  ExportService._init();

  final _db = DatabaseHelper.instance;
  final _dateFormat = DateFormat('dd/MM/yyyy', 'it_IT');
  final _currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

  /// Esporta le spese in formato CSV e condividi
  Future<bool> exportAndShareCsv({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
  }) async {
    try {
      final expenses = await _db.searchExpenses(
        '',
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
      );

      if (expenses.isEmpty) return false;

      final categories = await _db.getAllCategories();
      final catMap = {for (final c in categories) c.id: c};

      // Header CSV
      final rows = <List<String>>[
        ['Data', 'Categoria', 'Importo', 'Descrizione'],
      ];

      // Dati
      for (final e in expenses) {
        final cat = catMap[e.categoryId];
        rows.add([
          _dateFormat.format(e.date),
          cat?.name ?? 'Sconosciuta',
          _currencyFormat.format(e.amount),
          e.description ?? '',
        ]);
      }

      // Riga totale
      final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
      rows.add([]);
      rows.add(['', 'TOTALE', _currencyFormat.format(total), '']);

      // Genera CSV
      const converter = ListToCsvConverter(fieldDelimiter: ';');
      final csv = converter.convert(rows);

      // Salva file temporaneo
      final dir = await getTemporaryDirectory();
      final dateRange = startDate != null && endDate != null
          ? '${_dateFormat.format(startDate).replaceAll('/', '-')}_${_dateFormat.format(endDate).replaceAll('/', '-')}'
          : 'completo';
      final file = File('${dir.path}/spendly_export_$dateRange.csv');
      await file.writeAsString(csv);

      // Condividi
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export Spese Spendly',
        text: 'Export delle spese da Spendly',
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Esporta abbonamenti in CSV
  Future<bool> exportSubscriptionsCsv() async {
    try {
      final subs = await _db.getActiveSubscriptions();
      if (subs.isEmpty) return false;

      final categories = await _db.getAllCategories();
      final catMap = {for (final c in categories) c.id: c};

      final rows = <List<String>>[
        ['Nome', 'Importo', 'Frequenza', 'Categoria', 'Costo Mensile', 'Costo Annuale', 'Prossimo Pagamento'],
      ];

      for (final s in subs) {
        final cat = catMap[s.categoryId];
        rows.add([
          s.name,
          _currencyFormat.format(s.amount),
          s.frequency.label,
          cat?.name ?? 'Sconosciuta',
          _currencyFormat.format(s.monthlyCost),
          _currencyFormat.format(s.yearlyCost),
          _dateFormat.format(s.nextPaymentDate),
        ]);
      }

      final totalMonthly = subs.fold(0.0, (sum, s) => sum + s.monthlyCost);
      final totalYearly = subs.fold(0.0, (sum, s) => sum + s.yearlyCost);
      rows.add([]);
      rows.add(['TOTALE', '', '', '', _currencyFormat.format(totalMonthly), _currencyFormat.format(totalYearly), '']);

      const converter = ListToCsvConverter(fieldDelimiter: ';');
      final csv = converter.convert(rows);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/spendly_abbonamenti.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Abbonamenti Spendly',
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
