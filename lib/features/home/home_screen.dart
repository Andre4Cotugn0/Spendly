import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense.dart';
import '../../data/models/category.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/category_icon.dart';
import '../add_expense/add_expense_screen.dart';
import '../subscriptions/subscriptions_screen.dart';
import '../statistics/statistics_screen.dart';
import '../settings/settings_screen.dart';
import '../debts/debts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // Traccia le tab già visitate per mantenerle in vita (lazy IndexedStack)
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    // Carica i dati all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadData();
    });
  }

  static const _screens = <Widget>[
    _HomeContent(),
    SubscriptionsScreen(),
    DebtsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (int i = 0; i < _screens.length; i++)
            _loadedTabs.contains(i) ? _screens[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64 + (bottomInset > 0 ? 0 : 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(
                icon: Icons.autorenew_outlined,
                activeIcon: Icons.autorenew,
                label: 'Abbonamenti',
                isActive: _currentIndex == 1,
                onTap: () => setState(() { _loadedTabs.add(1); _currentIndex = 1; }),
              ),
              _NavItem(
                icon: Icons.handshake_outlined,
                activeIcon: Icons.handshake,
                label: 'Debiti',
                isActive: _currentIndex == 2,
                onTap: () => setState(() { _loadedTabs.add(2); _currentIndex = 2; }),
              ),
              // Central FAB slot
              GestureDetector(
                onTap: () {
                  if (_currentIndex == 0) {
                    _openAddExpense(context);
                  } else {
                    setState(() { _loadedTabs.add(0); _currentIndex = 0; });
                  }
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(102),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Icon(
                      _currentIndex == 0 ? Icons.add_rounded : Icons.home_rounded,
                      key: ValueKey<bool>(_currentIndex == 0),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Statistiche',
                isActive: _currentIndex == 3,
                onTap: () => setState(() { _loadedTabs.add(3); _currentIndex = 3; }),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Impostazioni',
                isActive: _currentIndex == 4,
                onTap: () => setState(() { _loadedTabs.add(4); _currentIndex = 4; }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddExpenseScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playAnimation() {
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!widget.isActive) {
          _playAnimation();
          widget.onTap();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isActive ? AppColors.primary.withAlpha(22) : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimens.radiusS),
              ),
              child: _buildAnimatedIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    final icon = widget.isActive ? widget.activeIcon : widget.icon;
    final color = widget.isActive ? AppColors.primary : AppColors.textTertiary;

    // Animazioni specifiche per ogni icona
    if (widget.label == 'Abbonamenti' && icon == Icons.autorenew) {
      // Rotazione completa 360°
      return RotationTransition(
        turns: _animationController,
        child: Icon(icon, color: color, size: 28),
      );
    } else if (widget.label == 'Debiti' && icon == Icons.handshake) {
      // Chiusura e apertura delle mani (oscillazione di scala)
      return ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 0.65),
            weight: 50,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.65, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        ),
        child: Icon(icon, color: color, size: 28),
      );
    } else if (widget.label == 'Statistiche' && (icon == Icons.bar_chart || icon == Icons.bar_chart_outlined)) {
      // Le barre salgono/scendono senza spostare l'icona
      return ScaleTransition(
        alignment: Alignment.bottomCenter,
        scale: TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.18),
            weight: 35,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.18, end: 0.92),
            weight: 30,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.92, end: 1.0),
            weight: 35,
          ),
        ]).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        ),
        child: Icon(icon, color: color, size: 28),
      );
    } else if (widget.label == 'Impostazioni' && icon == Icons.settings) {
      // Rotazione 1.5 giri (540°)
      return RotationTransition(
        turns: Tween<double>(begin: 0, end: 1.5).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        ),
        child: Icon(icon, color: color, size: 28),
      );
    }

    // Icona di default senza animazione
    return Icon(icon, color: color, size: 28);
  }

}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Expense>? _searchResults;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query, ExpenseProvider provider) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    final results = await provider.searchExpenses(query.trim());
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.expenses.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return CustomScrollView(
          slivers: [
            // Month Selector + Total
            SliverToBoxAdapter(
              child: _MonthSelector(provider: provider),
            ),

            // Total Card
            SliverToBoxAdapter(
              child: _TotalCard(provider: provider),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(Dimens.radiusFull),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cerca spese...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('', provider);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (q) => _onSearch(q, provider),
                  ),
                ),
              ),
            ),

            // Recent Expenses Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  _searchResults != null ? 'Risultati ricerca' : 'Spese del mese',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),

            // Expenses List
            if (_isSearching)
              const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )),
              )
            else if ((_searchResults ?? provider.expenses).isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expenses = _searchResults ?? provider.expenses;
                    final expense = expenses[index];
                    final category = provider.getCategoryById(expense.categoryId);
                    return _ExpenseItem(
                      expense: expense,
                      category: category,
                      onTap: () => _showExpenseOptions(context, expense, provider),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 300.ms,
                        );
                  },
                  childCount: (_searchResults ?? provider.expenses).length,
                ),
              ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseOptions(
    BuildContext context,
    Expense expense,
    ExpenseProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimens.radiusXL)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(Dimens.radiusFull),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Modifica'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(expense: expense),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.error),
              title: const Text('Elimina'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Elimina spesa'),
                    content: const Text('Sei sicuro di voler eliminare questa spesa?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annulla'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text('Elimina', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.deleteExpense(expense.id);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final ExpenseProvider provider;

  const _MonthSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selectedDate = DateTime(provider.selectedYear, provider.selectedMonth);
    final topPadding = MediaQuery.of(context).padding.top + 16;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Buongiorno' : (hour < 18 ? 'Buon pomeriggio' : 'Buonasera');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Row(
            children: [
              GestureDetector(
                onTap: provider.previousMonth,
                child: Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  Formatters.monthYear(selectedDate),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              GestureDetector(
                onTap: provider.nextMonth,
                child: Icon(Icons.chevron_right, color: AppColors.primary, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final ExpenseProvider provider;

  const _TotalCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(Dimens.radiusXL),
        ),
        child: FutureBuilder<double>(
          future: provider.getTotalMonth(),
          builder: (context, snapshot) {
            final total = snapshot.data ?? 0;
            final globalBudget = provider.getGlobalBudget();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.monthYear(DateTime(provider.selectedYear, provider.selectedMonth)),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                if (globalBudget != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget: ${Formatters.currencyCompact(globalBudget.amount)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        '${(globalBudget.spentPercentage(total) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: globalBudget.isExceeded(total) ? Colors.redAccent : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: globalBudget.spentPercentage(total).clamp(0, 1),
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(
                        globalBudget.isExceeded(total) ? Colors.redAccent : Colors.white,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                ] else ...[
                  FutureBuilder<double>(
                    future: provider.getAverageDaily(),
                    builder: (context, avgSnapshot) {
                      final avg = avgSnapshot.data ?? 0;
                      return Text(
                        'Media giornaliera: ${Formatters.currency(avg)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class _ExpenseItem extends StatelessWidget {
  final Expense expense;
  final Category? category;
  final VoidCallback onTap;

  const _ExpenseItem({
    required this.expense,
    this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusM),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Dimens.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CategoryIconContainer(
                  iconName: category?.iconName ?? 'other',
                  backgroundColor: category?.color ?? AppColors.textTertiary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category?.name ?? 'Sconosciuta',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (expense.description != null && expense.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            expense.description!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          Formatters.relativeDate(expense.date),
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${Formatters.currencyCompact(expense.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.error,
                  ),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna spesa',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocca + per aggiungere la tua prima spesa',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
