import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/subscription.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_icon.dart';
import 'add_subscription_screen.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final active = provider.subscriptions.where((s) => s.isActive).toList();
        final inactive = provider.subscriptions.where((s) => !s.isActive).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Abbonamenti'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _openAddSubscription(context),
                ),
              ],
            ),

            // Summary Cards
            SliverToBoxAdapter(
              child: _SummaryCards(provider: provider),
            ),

            // Active Subscriptions Header
            if (active.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Attivi',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${active.length}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Active Subscriptions List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sub = active[index];
                  final category = provider.getCategoryById(sub.categoryId);
                  return _SubscriptionItem(
                    subscription: sub,
                    category: category,
                    onTap: () => _showOptions(context, sub, provider),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                        duration: 300.ms,
                      );
                },
                childCount: active.length,
              ),
            ),

            // Inactive Header
            if (inactive.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Disattivati',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.textTertiary.withAlpha(38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${inactive.length}',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Inactive List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sub = inactive[index];
                  final category = provider.getCategoryById(sub.categoryId);
                  return Opacity(
                    opacity: 0.5,
                    child: _SubscriptionItem(
                      subscription: sub,
                      category: category,
                      onTap: () => _showOptions(context, sub, provider),
                    ),
                  );
                },
                childCount: inactive.length,
              ),
            ),

            // Empty state
            if (provider.subscriptions.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(onAdd: () => _openAddSubscription(context)),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  void _openAddSubscription(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddSubscriptionScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showOptions(BuildContext context, Subscription sub, ExpenseProvider provider) {
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(sub.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${Formatters.currency(sub.amount)} ${sub.frequency.shortLabel}',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Modifica'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddSubscriptionScreen(subscription: sub),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                sub.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: sub.isActive ? AppColors.warning : AppColors.success,
              ),
              title: Text(sub.isActive ? 'Disattiva' : 'Riattiva'),
              onTap: () {
                Navigator.pop(context);
                provider.toggleSubscription(sub.id);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Elimina'),
              onTap: () => _confirmDelete(context, sub, provider),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Subscription sub, ExpenseProvider provider) {
    Navigator.pop(context); // Chiude il bottom sheet
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina abbonamento'),
        content: Text('Vuoi eliminare "${sub.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteSubscription(sub.id);
            },
            child: Text('Elimina', style: TextStyle(color: AppColors.error)),
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
            future: provider.getTotalMonthlySubscriptions(),
            builder: (context, snapshot) {
              return _SummaryCard(
                title: 'Costo mensile',
                amount: snapshot.data ?? 0,
                icon: Icons.calendar_month,
                gradient: AppColors.primaryGradient,
              );
            },
          ),
          const SizedBox(height: 10),
          FutureBuilder<double>(
            future: provider.getTotalYearlySubscriptions(),
            builder: (context, snapshot) {
              return _SummaryCard(
                title: 'Costo annuale',
                amount: snapshot.data ?? 0,
                icon: Icons.calendar_today,
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

class _SubscriptionItem extends StatelessWidget {
  final Subscription subscription;
  final dynamic category;
  final VoidCallback onTap;

  const _SubscriptionItem({
    required this.subscription,
    this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nextPayment = subscription.calculateNextPayment();
    final daysUntil = nextPayment.difference(DateTime.now()).inDays;

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
            child: Row(
              children: [
                CategoryIconContainer(
                  iconName: category?.iconName ?? 'other',
                  backgroundColor: category?.color ?? AppColors.textTertiary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subscription.frequency.label,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            daysUntil == 0
                                ? 'Oggi'
                                : daysUntil == 1
                                    ? 'Domani'
                                    : 'tra $daysUntil giorni',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(subscription.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~${Formatters.currencyCompact(subscription.monthlyCost)}/mese',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          Icon(Icons.autorenew, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Nessun abbonamento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tieni traccia di Netflix, Spotify, abbonamenti\ne pagamenti ricorrenti',
            style: TextStyle(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi abbonamento'),
          ),
        ],
      ),
    );
  }
}
