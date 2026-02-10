import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/debt.dart';
import '../../providers/expense_provider.dart';
import 'add_debt_screen.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final active = provider.activeDebts;
        final settled = provider.settledDebts;

        // Separa attivi per tipo
        final iOwe = active.where((d) => d.type == DebtType.iOwe).toList();
        final owedToMe = active.where((d) => d.type == DebtType.owedToMe).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Debiti'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _openAddDebt(context),
                ),
              ],
            ),

            // Summary Cards
            SliverToBoxAdapter(
              child: _SummaryCards(provider: provider),
            ),

            // Sezione "Devo" (I Owe)
            if (iOwe.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Devo',
                  count: iOwe.length,
                  color: AppColors.error,
                  icon: Icons.arrow_upward,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = iOwe[index];
                    return _DebtItem(
                      debt: debt,
                      onTap: () => _showOptions(context, debt, provider),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 300.ms,
                        );
                  },
                  childCount: iOwe.length,
                ),
              ),
            ],

            // Sezione "Mi devono" (Owed to Me)
            if (owedToMe.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Mi devono',
                  count: owedToMe.length,
                  color: AppColors.success,
                  icon: Icons.arrow_downward,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = owedToMe[index];
                    return _DebtItem(
                      debt: debt,
                      onTap: () => _showOptions(context, debt, provider),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 300.ms,
                        );
                  },
                  childCount: owedToMe.length,
                ),
              ),
            ],

            // Sezione Saldati
            if (settled.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Saldati',
                  count: settled.length,
                  color: AppColors.textTertiary,
                  icon: Icons.check_circle_outline,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final debt = settled[index];
                    return Opacity(
                      opacity: 0.5,
                      child: _DebtItem(
                        debt: debt,
                        onTap: () => _showOptions(context, debt, provider),
                      ),
                    );
                  },
                  childCount: settled.length,
                ),
              ),
            ],

            // Empty state
            if (provider.debts.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(onAdd: () => _openAddDebt(context)),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  void _openAddDebt(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddDebtScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showOptions(BuildContext context, Debt debt, ExpenseProvider provider) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(debt.personName,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${Formatters.currency(debt.amount)} - ${debt.type.label}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (debt.amountPaid > 0 && !debt.isSettled) ...[
              const SizedBox(height: 4),
              Text(
                'Saldato: ${Formatters.currency(debt.amountPaid)} / ${Formatters.currency(debt.amount)}',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            if (!debt.isSettled) ...[
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Modifica'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddDebtScreen(debt: debt),
                      fullscreenDialog: true,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined,
                    color: AppColors.secondary),
                title: const Text('Registra pagamento parziale'),
                onTap: () {
                  Navigator.pop(context);
                  _showPartialPaymentDialog(context, debt, provider);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.success),
                title: const Text('Segna come saldato'),
                onTap: () {
                  Navigator.pop(context);
                  provider.settleDebt(debt.id);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.undo, color: AppColors.warning),
                title: const Text('Riapri debito'),
                onTap: () {
                  Navigator.pop(context);
                  final reopened = debt.copyWith(isSettled: false);
                  provider.updateDebt(reopened);
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Elimina'),
              onTap: () => _confirmDelete(context, debt, provider),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPartialPaymentDialog(
      BuildContext context, Debt debt, ExpenseProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pagamento parziale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rimanente: ${Formatters.currency(debt.remaining)}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo pagamento',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(
                      text: newValue.text.replaceAll(',', '.'));
                }),
              ],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0 && amount <= debt.remaining) {
                Navigator.pop(ctx);
                provider.addPaymentToDebt(debt.id, amount);
              }
            },
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, Debt debt, ExpenseProvider provider) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina debito'),
        content: Text(
            'Vuoi eliminare il debito con "${debt.personName}" di ${Formatters.currency(debt.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteDebt(debt.id);
            },
            child:
                Text('Elimina', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final ExpenseProvider provider;
  const _SummaryCards({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          FutureBuilder<double>(
            future: provider.getTotalIOwe(),
            builder: (context, snapshot) {
              return _SummaryCard(
                title: 'Devo',
                amount: snapshot.data ?? 0,
                icon: Icons.arrow_upward,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          FutureBuilder<double>(
            future: provider.getTotalOwedToMe(),
            builder: (context, snapshot) {
              return _SummaryCard(
                title: 'Mi devono',
                amount: snapshot.data ?? 0,
                icon: Icons.arrow_downward,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D9FF), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final LinearGradient gradient;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textOnAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.textOnAccent, fontSize: 14),
            ),
          ),
          Text(
            Formatters.currency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtItem extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;

  const _DebtItem({
    required this.debt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar persona
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: debt.type == DebtType.iOwe
                            ? AppColors.error.withAlpha(26)
                            : AppColors.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          debt.personName.isNotEmpty
                              ? debt.personName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.personName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: debt.type == DebtType.iOwe
                                      ? AppColors.error.withAlpha(26)
                                      : AppColors.success.withAlpha(26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  debt.type.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (debt.dueDate != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.schedule,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDueDate(debt),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (debt.description != null &&
                                  debt.description!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    debt.description!,
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.currency(debt.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (debt.amountPaid > 0 && !debt.isSettled) ...[
                          const SizedBox(height: 2),
                          Text(
                            '-${Formatters.currencyCompact(debt.amountPaid)}',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                // Barra progresso pagamento
                if (debt.amountPaid > 0 && !debt.isSettled) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: debt.paidPercentage,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: AlwaysStoppedAnimation(
                        debt.type == DebtType.iOwe
                            ? AppColors.error
                            : AppColors.success,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(Debt debt) {
    final days = debt.daysUntilDue;
    if (days == null) return '';
    if (days < 0) return 'Scaduto ${-days}g fa';
    if (days == 0) return 'Scade oggi';
    if (days == 1) return 'Scade domani';
    return 'tra $days giorni';
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.handshake_outlined, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Nessun debito',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tieni traccia dei debiti da saldare\ne di quelli che ti devono',
            style: TextStyle(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi debito'),
          ),
        ],
      ),
    );
  }
}
