import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/budget.dart';
import '../../providers/expense_provider.dart';
import '../../providers/theme_provider.dart';
import '../categories/categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<double> _totalMonthFuture;

  @override
  void initState() {
    super.initState();
    _totalMonthFuture = context.read<ExpenseProvider>().getTotalMonth();
  }

  void _refreshTotalMonth(ExpenseProvider provider) {
    setState(() {
      _totalMonthFuture = provider.getTotalMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: const Text('Impostazioni'),
                  backgroundColor: AppColors.background,
                ),

                // Theme Section
                SliverToBoxAdapter(
                  child: _buildThemeSection(context),
                ),

                // Export CSV Section
                SliverToBoxAdapter(
                  child: _buildExportSection(context, provider),
                ),

                // Budget Section
                SliverToBoxAdapter(
                  child: _buildBudgetSection(context, provider),
                ),

                // Categories Section
                SliverToBoxAdapter(
                  child: _buildCategoriesSection(context),
                ),

                // Notifications Section
                SliverToBoxAdapter(
                  child: _buildNotificationsSection(context, provider),
                ),

                // App Info
                SliverToBoxAdapter(
                  child: _buildAppInfo(context),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildBudgetSection(BuildContext context, ExpenseProvider provider) {
    final globalBudget = provider.getGlobalBudget();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Budget Mensile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 20),
            ),
            title: const Text('Budget globale'),
            subtitle: Text(
              globalBudget != null
                  ? Formatters.currency(globalBudget.amount)
                  : 'Non impostato',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBudgetDialog(context, provider, globalBudget),
          ),
          if (globalBudget != null)
            FutureBuilder<double>(
              future: _totalMonthFuture,
              builder: (context, snapshot) {
                final spent = snapshot.data ?? 0;
                final pct = globalBudget.spentPercentage(spent);
                final color = globalBudget.isExceeded(spent) 
                    ? AppColors.error 
                    : globalBudget.isWarning(spent) 
                        ? AppColors.warning 
                        : AppColors.success;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speso: ${Formatters.currency(spent)}',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          Text(
                            'Rimanente: ${Formatters.currency(globalBudget.remaining(spent))}',
                            style: TextStyle(fontSize: 12, color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0, 1),
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 4),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Aspetto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              ...[(ThemeMode.system, 'Sistema', Icons.brightness_auto_outlined, 'Segue il tema del dispositivo'),
                  (ThemeMode.light, 'Chiaro', Icons.light_mode_outlined, 'Tema chiaro'),
                  (ThemeMode.dark, 'Scuro', Icons.dark_mode_outlined, 'Tema scuro'),
              ].map((item) {
                final (mode, label, icon, subtitle) = item;
                final isSelected = themeProvider.themeMode == mode;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(26)
                          : Theme.of(context).inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: isSelected ? AppColors.primary : null, size: 20),
                  ),
                  title: Text(label),
                  subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => themeProvider.setThemeMode(mode),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Categorie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.category_outlined, color: AppColors.secondary, size: 20),
            ),
            title: const Text('Gestisci categorie'),
            subtitle: const Text('Aggiungi o modifica le categorie personalizzate'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildNotificationsSection(BuildContext context, ExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Notifiche',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          FutureBuilder<bool>(
            future: provider.isDailyReminderEnabled(),
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? false;
              return SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications_active_outlined, color: AppColors.warning, size: 20),
                ),
                title: const Text('Promemoria giornaliero'),
                subtitle: const Text('Ricorda di registrare le spese alle 20:00'),
                value: enabled,
                onChanged: (v) async {
                  await provider.setDailyReminder(v);
                },
                activeTrackColor: AppColors.primary,
                activeThumbColor: Colors.white,
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }

  Widget _buildExportSection(BuildContext context, ExpenseProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Esporta dati',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
            ),
            title: const Text('Esporta spese'),
            subtitle: const Text('Genera un file CSV con tutte le spese'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportExpenses(context, provider),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.file_download_outlined, color: AppColors.secondary, size: 20),
            ),
            title: const Text('Esporta tutto'),
            subtitle: const Text('Spese, categorie, abbonamenti e debiti'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportAllData(context, provider),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 300.ms);
  }

  void _exportExpenses(BuildContext context, ExpenseProvider provider) async {
    final success = await provider.exportExpensesCsv();
    if (context.mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'export'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _exportAllData(BuildContext context, ExpenseProvider provider) async {
    final success = await provider.exportAllDataCsv();
    if (context.mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'export'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildAppInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Informazioni',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Spendly'),
            subtitle: Text('Versione 2.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Sviluppato da'),
            subtitle: const Text('Andre4Cotugn0'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://github.com/Andre4Cotugn0'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            leading: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
              child: const Icon(Icons.flutter_dash, color: Colors.white),
            ),
            title: const Text('Sviluppato con'),
            subtitle: const Text('Flutter & Dart'),
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 300.ms);
  }

  void _showBudgetDialog(BuildContext context, ExpenseProvider provider, Budget? current) {
    final controller = TextEditingController(
      text: current != null ? current.amount.toStringAsFixed(0) : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Budget Mensile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Imposta un limite di spesa mensile. Riceverai una notifica quando lo superi.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '€ ',
                hintText: 'Es: 1000',
                labelText: 'Budget mensile',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.deleteBudget(current.id);
                _refreshTotalMonth(provider);
              },
              child: Text('Rimuovi', style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text.replaceAll(',', '.'));
              if (amount != null && amount > 0) {
                final now = DateTime.now();
                provider.setBudget(Budget(
                  id: current?.id,
                  amount: amount,
                  month: now.month,
                  year: now.year,
                ));
                _refreshTotalMonth(provider);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
