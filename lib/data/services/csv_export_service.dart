import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';

class CsvExportService {
  CsvExportService._();
  static final CsvExportService instance = CsvExportService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Esporta tutte le spese in un file CSV e apre il foglio di condivisione.
  /// Restituisce `true` se l'export è andato a buon fine.
  Future<bool> exportExpenses() async {
    try {
      final data = await _db.exportAllData();
      final expenses = data['expenses'] as List<dynamic>? ?? [];
      final categories = data['categories'] as List<dynamic>? ?? [];

      // Mappa id → nome categoria per rendere il CSV leggibile
      final catMap = <String, String>{};
      for (final c in categories) {
        final map = c as Map<String, dynamic>;
        catMap[map['id'] as String] = map['name'] as String;
      }

      // Header
      final rows = <List<String>>[
        ['Data', 'Importo', 'Categoria', 'Note'],
      ];

      for (final e in expenses) {
        final map = e as Map<String, dynamic>;
        final date = map['date'] as String? ?? '';
        final amount = (map['amount'] ?? 0).toString();
        final catId = map['categoryId'] as String? ?? '';
        final catName = catMap[catId] ?? catId;
        final note = map['note'] as String? ?? '';
        rows.add([date, amount, catName, note]);
      }

      final csvString = const ListToCsvConverter().convert(rows);

      // Scrivi file temporaneo
      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'spendly_export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvString);

      // Condividi
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Spendly - Export spese',
      );

      return true;
    } catch (e) {
      debugPrint('Errore export CSV: $e');
      return false;
    }
  }

  /// Esporta tutti i dati (spese, categorie, abbonamenti, debiti, budget)
  /// in un file CSV multi-foglio (sezioni separate da riga vuota + intestazione).
  Future<bool> exportAllData() async {
    try {
      final data = await _db.exportAllData();

      final categories = data['categories'] as List<dynamic>? ?? [];
      final expenses = data['expenses'] as List<dynamic>? ?? [];
      final subscriptions = data['subscriptions'] as List<dynamic>? ?? [];
      final debts = data['debts'] as List<dynamic>? ?? [];

      // Mappa id → nome categoria
      final catMap = <String, String>{};
      for (final c in categories) {
        final map = c as Map<String, dynamic>;
        catMap[map['id'] as String] = map['name'] as String;
      }

      final rows = <List<String>>[];

      // === SPESE ===
      rows.add(['--- SPESE ---']);
      rows.add(['Data', 'Importo', 'Categoria', 'Note']);
      for (final e in expenses) {
        final map = e as Map<String, dynamic>;
        rows.add([
          map['date'] as String? ?? '',
          (map['amount'] ?? 0).toString(),
          catMap[map['categoryId'] as String? ?? ''] ?? '',
          map['note'] as String? ?? '',
        ]);
      }

      // === CATEGORIE ===
      rows.add([]);
      rows.add(['--- CATEGORIE ---']);
      rows.add(['ID', 'Nome', 'Icona', 'Colore']);
      for (final c in categories) {
        final map = c as Map<String, dynamic>;
        rows.add([
          map['id'] as String? ?? '',
          map['name'] as String? ?? '',
          map['icon'] as String? ?? '',
          map['color'] as String? ?? '',
        ]);
      }

      // === ABBONAMENTI ===
      rows.add([]);
      rows.add(['--- ABBONAMENTI ---']);
      rows.add(['Nome', 'Importo', 'Frequenza', 'Data rinnovo', 'Attivo']);
      for (final s in subscriptions) {
        final map = s as Map<String, dynamic>;
        rows.add([
          map['name'] as String? ?? '',
          (map['amount'] ?? 0).toString(),
          map['frequency'] as String? ?? '',
          map['nextBillingDate'] as String? ?? '',
          (map['isActive'] == true).toString(),
        ]);
      }

      // === DEBITI ===
      rows.add([]);
      rows.add(['--- DEBITI ---']);
      rows.add(['Persona', 'Importo', 'Pagato', 'Tipo', 'Saldato']);
      for (final d in debts) {
        final map = d as Map<String, dynamic>;
        rows.add([
          map['personName'] as String? ?? '',
          (map['amount'] ?? 0).toString(),
          (map['amountPaid'] ?? 0).toString(),
          map['type'] as String? ?? '',
          (map['isSettled'] == true).toString(),
        ]);
      }

      final csvString = const ListToCsvConverter().convert(rows);

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'spendly_completo_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Spendly - Export completo',
      );

      return true;
    } catch (e) {
      debugPrint('Errore export completo CSV: $e');
      return false;
    }
  }
}
