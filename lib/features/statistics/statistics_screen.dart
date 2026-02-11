import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/category_icon.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _touchedIndex = -1;
  Future<Map<String, double>>? _categoryTotalsCache;
  int _cachedYear = -1;
  int _cachedMonth = -1;

  Future<Map<String, double>> _getCategoryTotals(ExpenseProvider provider) {
    if (_cachedYear != provider.selectedYear || _cachedMonth != provider.selectedMonth) {
      _cachedYear = provider.selectedYear;
      _cachedMonth = provider.selectedMonth;
      _categoryTotalsCache = provider.getTotalByCategory();
    }
    return _categoryTotalsCache!;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Statistiche'),
            ),
            
            SliverToBoxAdapter(child: _MonthSelector(provider: provider)),
            SliverToBoxAdapter(child: _buildQuickStats(provider)),
            SliverToBoxAdapter(child: _buildPieChartAndLegend(provider)),
            SliverToBoxAdapter(child: _buildComparisonCard(provider)),
            SliverToBoxAdapter(child: _buildInsightsCard(provider)),
            SliverToBoxAdapter(child: _buildCategoryRanking(provider)),
            SliverToBoxAdapter(child: _buildLineChart(provider)),
            SliverToBoxAdapter(child: _buildTopExpenses(provider)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(ExpenseProvider provider) {
    return FutureBuilder<double>(
      future: provider.getTotalMonth(),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;
        final expenses = provider.expenses;
        final daysInMonth = DateTime(provider.selectedYear, provider.selectedMonth + 1, 0).day;
        final avgDaily = expenses.isEmpty ? 0.0 : total / daysInMonth;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Totale',
                  value: Formatters.currencyCompact(total),
                  color: AppColors.primary,
                ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today,
                  label: 'Media/Giorno',
                  value: Formatters.currencyCompact(avgDaily),
                  color: AppColors.secondary,
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideX(begin: -0.2, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Transazioni',
                  value: expenses.length.toString(),
                  color: AppColors.warning,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideX(begin: -0.2, end: 0),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChartAndLegend(ExpenseProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: _getCategoryTotals(provider),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('Nessuna spesa registrata', Icons.pie_chart_outline);
        }

        final categoryTotals = snapshot.data!;
        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
        final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.donut_large, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text('Per Categoria', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      Formatters.currencyCompact(total),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  height: 240,
                  width: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 65,
                        sections: sortedEntries.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = provider.getCategoryById(entry.value.key);
                          final isTouched = index == _touchedIndex;
                          
                          return PieChartSectionData(
                            color: category?.color ?? AppColors.textTertiary,
                            value: entry.value.value,
                            title: '',
                            radius: isTouched ? 80 : 70,
                          );
                        }).toList(),
                      ),
                    ),
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: _touchedIndex >= 0 && _touchedIndex < sortedEntries.length
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CategoryIconContainer(
                                iconName: provider.getCategoryById(sortedEntries[_touchedIndex].key)?.iconName ?? 'other',
                                backgroundColor: provider.getCategoryById(sortedEntries[_touchedIndex].key)?.color ?? AppColors.textTertiary,
                                size: 36,
                                iconSize: 18,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.getCategoryById(sortedEntries[_touchedIndex].key)?.name ?? 'Altro',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currencyCompact(sortedEntries[_touchedIndex].value),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              Text(
                                '${(sortedEntries[_touchedIndex].value / total * 100).toStringAsFixed(1)}%',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_outlined, color: AppColors.textTertiary, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Tocca',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                Formatters.currencyCompact(total),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: sortedEntries.take(6).map((entry) {
                  final category = provider.getCategoryById(entry.key);
                  final percentage = entry.value / total * 100;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: category?.color.withAlpha(77) ?? AppColors.textTertiary.withAlpha(77), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: category?.color ?? AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category?.name ?? 'Altro',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildComparisonCard(ExpenseProvider provider) {
    return FutureBuilder<double>(
      future: provider.getTotalMonth(),
      builder: (context, currentSnapshot) {
        final currentTotal = currentSnapshot.data ?? 0;
        
        // Non mostrare se non ci sono spese nel mese corrente
        if (currentTotal == 0) return const SizedBox.shrink();
        
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: provider.getMonthlyTotals(months: 2),
          builder: (context, prevSnapshot) {
            double prevTotal = 0;
            if (prevSnapshot.hasData && prevSnapshot.data!.length >= 2) {
              prevTotal = (prevSnapshot.data![0]['total'] as num).toDouble();
            }
            final difference = currentTotal - prevTotal;
            final percentChange = prevTotal == 0 ? 100.0 : (difference / prevTotal * 100);
            final isIncrease = difference > 0;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isIncrease ? [AppColors.error.withAlpha(100), AppColors.error.withAlpha(50)] : [AppColors.success.withAlpha(100), AppColors.success.withAlpha(50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(isIncrease ? Icons.trending_up : Icons.trending_down, color: isIncrease ? AppColors.error : AppColors.success, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('vs Mese Precedente', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${isIncrease ? '+' : ''}${percentChange.toStringAsFixed(1)}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isIncrease ? const Color(0xFFEF5350) : const Color(0xFF66BB6A))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Differenza', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      Text('${isIncrease ? '+' : ''}${Formatters.currencyCompact(difference.abs())}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isIncrease ? const Color(0xFFEF5350) : const Color(0xFF66BB6A))),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildInsightsCard(ExpenseProvider provider) {
    final expenses = provider.expenses;
    if (expenses.isEmpty) return const SizedBox.shrink();
    
    final categoryExpenses = <String, int>{};
    for (var exp in expenses) {
      categoryExpenses[exp.categoryId] = (categoryExpenses[exp.categoryId] ?? 0) + 1;
    }
    final mostFrequentCategoryId = categoryExpenses.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final mostFrequentCategory = provider.getCategoryById(mostFrequentCategoryId);
    
    final dayTotals = <int, double>{};
    for (var exp in expenses) {
      dayTotals[exp.date.day] = (dayTotals[exp.date.day] ?? 0) + exp.amount;
    }
    final busiestDay = dayTotals.entries.isEmpty ? 1 : dayTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final avgExpense = expenses.fold(0.0, (sum, e) => sum + e.amount) / expenses.length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Insights', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.category_outlined,
            label: 'Categoria più usata',
            value: mostFrequentCategory?.name ?? 'N/A',
            color: mostFrequentCategory?.color ?? AppColors.primary,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.event,
            label: 'Giorno con più spese',
            value: '$busiestDay ${_getMonthName(provider.selectedMonth)}',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.payment,
            label: 'Spesa media',
            value: Formatters.currencyCompact(avgExpense),
            color: AppColors.warning,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  String _getMonthName(int month) {
    const months = ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
    return months[month];
  }

  Widget _buildCategoryRanking(ExpenseProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: _getCategoryTotals(provider),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final categoryTotals = snapshot.data!;
        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
        final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Classifica Categorie', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              ...sortedEntries.asMap().entries.map((e) {
                final index = e.key;
                final category = provider.getCategoryById(e.value.key);
                final percentage = e.value.value / total;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          gradient: index == 0 ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                              : index == 1 ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                              : index == 2 ? LinearGradient(colors: [Colors.brown.shade300, Colors.brown.shade400])
                              : null,
                          color: index >= 3 ? AppColors.surfaceLight : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: index < 3 ? Colors.white : AppColors.textTertiary))),
                      ),
                      const SizedBox(width: 12),
                      CategoryIconContainer(iconName: category?.iconName ?? 'other', backgroundColor: category?.color ?? AppColors.textTertiary, size: 42, iconSize: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category?.name ?? 'Altro', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: percentage, backgroundColor: AppColors.surfaceLight, valueColor: AlwaysStoppedAnimation(category?.color ?? AppColors.textTertiary), minHeight: 6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(Formatters.currencyCompact(e.value.value), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${(percentage * 100).toStringAsFixed(0)}%', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 250 + index * 50), duration: 300.ms);
              }),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildLineChart(ExpenseProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getDailyTotals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final dailyTotals = snapshot.data!;
        final maxValue = dailyTotals.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
        if (maxValue == 0) return const SizedBox.shrink();

        final spots = dailyTotals.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['total'] as num).toDouble())).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.secondary.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.show_chart, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Andamento Giornaliero', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxValue / 4,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppColors.textTertiary.withAlpha(26), strokeWidth: 1, dashArray: [5, 5]),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: dailyTotals.length > 15 ? 5 : 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= dailyTotals.length) return const SizedBox.shrink();
                            final day = dailyTotals[index]['day'] as String;
                            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(day.substring(8, 10), style: TextStyle(color: AppColors.textTertiary, fontSize: 10)));
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (dailyTotals.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxValue * 1.2,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        gradient: AppColors.primaryGradient,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: AppColors.surface),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withAlpha(77), AppColors.primary.withAlpha(26), AppColors.primary.withAlpha(0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => AppColors.surfaceLighter,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(Formatters.currency(s.y), TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12))).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildTopExpenses(ExpenseProvider provider) {
    return FutureBuilder<List<Expense>>(
      future: provider.getTopExpenses(limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        final topExpenses = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.error.withAlpha(26), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.local_fire_department, color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Top 5 Spese', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              ...topExpenses.asMap().entries.map((e) {
                final index = e.key;
                final expense = e.value;
                final category = provider.getCategoryById(expense.categoryId);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: index == 0 ? AppColors.error.withAlpha(51) : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          gradient: index == 0 ? LinearGradient(colors: [AppColors.error, AppColors.error.withAlpha(180)]) : null,
                          color: index != 0 ? AppColors.surfaceLighter : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Text('${index + 1}', style: TextStyle(color: index == 0 ? Colors.white : AppColors.textTertiary, fontWeight: FontWeight.bold, fontSize: 13))),
                      ),
                      const SizedBox(width: 12),
                      CategoryIconContainer(iconName: category?.iconName ?? 'other', backgroundColor: category?.color ?? AppColors.textTertiary, size: 40, iconSize: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(expense.description ?? category?.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 11, color: AppColors.textTertiary),
                                const SizedBox(width: 4),
                                Text(Formatters.relativeDate(expense.date), style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(Formatters.currency(expense.amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error)),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 350 + index * 50), duration: 300.ms).slideX(begin: 0.1, end: 0);
              }),
            ],
          ),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary.withAlpha(77)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
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
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: provider.previousMonth,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(backgroundColor: AppColors.surfaceLight),
          ),
          Text(Formatters.monthYear(selectedDate), style: Theme.of(context).textTheme.titleLarge),
          IconButton(
            onPressed: provider.nextMonth,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(backgroundColor: AppColors.surfaceLight),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(26), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
