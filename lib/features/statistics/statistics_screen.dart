import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
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

  @override
  Widget build(BuildContext context) {
    // Watch theme provider to rebuild when theme changes
    context.watch<ThemeProvider>();
    
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            const SliverAppBar(
              floating: true,
              title: Text('Statistiche'),
            ),
            
            // Month Selector
            SliverToBoxAdapter(
              child: _MonthSelector(provider: provider),
            ),

            // Pie Chart
            SliverToBoxAdapter(
              child: _buildPieChartSection(provider),
            ),

            // Category Breakdown
            SliverToBoxAdapter(
              child: _buildCategoryBreakdown(provider),
            ),

            // Top Expenses
            SliverToBoxAdapter(
              child: _buildTopExpenses(provider),
            ),

            // Monthly Trend
            SliverToBoxAdapter(
              child: _buildMonthlyTrend(provider),
            ),

            // Daily Chart
            SliverToBoxAdapter(
              child: _buildDailyChartSection(provider),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieChartSection(ExpenseProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: provider.getTotalByCategory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyChart('Nessun dato per questo mese');
        }

        final categoryTotals = snapshot.data!;
        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
        
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spese per Categoria',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: _buildPieSections(categoryTotals, total, provider),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Totale',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.currency(total),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms);
      },
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> categoryTotals,
    double total,
    ExpenseProvider provider,
  ) {
    final sections = <PieChartSectionData>[];
    var index = 0;

    for (final entry in categoryTotals.entries) {
      final category = provider.getCategoryById(entry.key);
      final isTouched = index == _touchedIndex;
      final percentage = (entry.value / total * 100);
      
      sections.add(
        PieChartSectionData(
          color: category?.color ?? AppColors.textTertiary,
          value: entry.value,
          title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: isTouched ? 65 : 55,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      index++;
    }

    return sections;
  }

  Widget _buildCategoryBreakdown(ExpenseProvider provider) {
    return FutureBuilder<Map<String, double>>(
      future: provider.getTotalByCategory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final categoryTotals = snapshot.data!;
        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
        
        // Ordina per valore decrescente
        final sortedEntries = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dettaglio',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...sortedEntries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value;
                final category = provider.getCategoryById(entry.key);
                final percentage = entry.value / total;

                return _CategoryBreakdownItem(
                  category: category,
                  amount: entry.value,
                  percentage: percentage,
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 100 * index),
                      duration: 300.ms,
                    );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyChartSection(ExpenseProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getDailyTotals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final dailyTotals = snapshot.data!;
        final maxValue = dailyTotals
            .map((e) => (e['total'] as num).toDouble())
            .reduce((a, b) => a > b ? a : b);

        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Andamento Giornaliero',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValue * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.surfaceLighter,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            Formatters.currency(rod.toY),
                            TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= dailyTotals.length) {
                              return const SizedBox.shrink();
                            }
                            final day = dailyTotals[index]['day'] as String;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                day.substring(8, 10),
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: dailyTotals.asMap().entries.map((entry) {
                      final index = entry.key;
                      final total = (entry.value['total'] as num).toDouble();
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: total,
                            gradient: AppColors.primaryGradient,
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final topExpenses = snapshot.data!;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Top 5 Spese', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              ...topExpenses.asMap().entries.map((e) {
                final expense = e.value;
                final category = provider.getCategoryById(expense.categoryId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CategoryIconContainer(
                        iconName: category?.iconName ?? 'other',
                        backgroundColor: category?.color ?? AppColors.textTertiary,
                        size: 36,
                        iconSize: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.description ?? category?.name ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              Formatters.relativeDate(expense.date),
                              style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(expense.amount),
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
      },
    );
  }

  Widget _buildMonthlyTrend(ExpenseProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getMonthlyTotals(months: 6),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data!;
        final maxVal = data.map((e) => (e['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
        if (maxVal == 0) return const SizedBox.shrink();

        final monthLabels = ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text('Trend Mensile', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.2,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => AppColors.surfaceLighter,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            Formatters.currency(rod.toY),
                            TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                            final month = data[idx]['month'] as int;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                monthLabels[month],
                                style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: data.asMap().entries.map((entry) {
                      final total = (entry.value['total'] as num).toDouble();
                      final isCurrentMonth = entry.key == data.length - 1;
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: total,
                            gradient: isCurrentMonth ? AppColors.primaryGradient : null,
                            color: isCurrentMonth ? null : AppColors.surfaceLighter,
                            width: 24,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
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
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
          Text(
            Formatters.monthYear(selectedDate),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            onPressed: provider.nextMonth,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownItem extends StatelessWidget {
  final Category? category;
  final double amount;
  final double percentage;

  const _CategoryBreakdownItem({
    this.category,
    required this.amount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CategoryIconContainer(
            iconName: category?.iconName ?? 'other',
            backgroundColor: category?.color ?? AppColors.textTertiary,
            size: 44,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? 'Sconosciuta',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(
                      category?.color ?? AppColors.textTertiary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currencyCompact(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
