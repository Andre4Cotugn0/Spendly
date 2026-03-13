import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:moneyra/features/add_expense/add_expense_screen.dart';
import 'package:moneyra/providers/expense_provider.dart';

void main() {
  testWidgets('Add expense screen renders primary controls', (
    WidgetTester tester,
  ) async {
    await initializeDateFormatting('it_IT');

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ExpenseProvider(),
        child: const MaterialApp(home: AddExpenseScreen()),
      ),
    );

    expect(find.text('Nuova Spesa'), findsOneWidget);
    expect(find.text('Importo'), findsOneWidget);
    expect(find.text('Aggiungi Spesa'), findsOneWidget);
  });
}
