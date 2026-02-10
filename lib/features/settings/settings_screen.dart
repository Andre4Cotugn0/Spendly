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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

                // Google Account Section
                SliverToBoxAdapter(
                  child: _buildGoogleSection(context, provider),
                ),

                // Backup Section
                SliverToBoxAdapter(
                  child: _buildBackupSection(context, provider),
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
              future: provider.getTotalMonth(),
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

  Widget _buildGoogleSection(BuildContext context, ExpenseProvider provider) {
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
              'Account Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (provider.isGoogleSignedIn) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundImage: provider.userPhoto != null
                    ? NetworkImage(provider.userPhoto!)
                    : null,
                backgroundColor: AppColors.primary,
                child: provider.userPhoto == null
                    ? Text(
                        provider.userName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              title: Text(provider.userName ?? 'Utente'),
              subtitle: Text(provider.userEmail ?? ''),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: const Text('Disconnetti'),
              onTap: () => _confirmSignOut(context, provider),
            ),
          ] else ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_off, size: 24),
              ),
              title: const Text('Non connesso'),
              subtitle: const Text('Accedi per attivare il backup automatico'),
            ),
            // Avviso configurazione iOS
            // RIMOSSO: alert su iOS

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _signInWithGoogle(context, provider),
                  icon: const Icon(Icons.login),
                  label: const Text('Accedi con Google'),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 300.ms);
  }

  Widget _buildBackupSection(BuildContext context, ExpenseProvider provider) {
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
              'Backup & Ripristino',
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
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                provider.isGoogleSignedIn ? Icons.cloud_done : Icons.cloud_off,
                color: provider.isGoogleSignedIn
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
            ),
            title: const Text('Backup automatico'),
            subtitle: Text(
              provider.isGoogleSignedIn
                  ? 'Attivo - I dati vengono salvati ad ogni modifica'
                  : 'Disattivo - Accedi con Google per attivarlo',
              style: TextStyle(
                color: provider.isGoogleSignedIn
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
            ),
          ),
          if (provider.lastBackupDate != null)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time),
              ),
              title: const Text('Ultimo backup'),
              subtitle: Text(Formatters.dateTime(provider.lastBackupDate!)),
            ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_upload),
            ),
            title: const Text('Backup manuale'),
            subtitle: const Text('Salva ora su Google Drive'),
            trailing: provider.isBackingUp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            enabled: provider.isGoogleSignedIn && !provider.isBackingUp,
            onTap: () => _manualBackup(context, provider),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_download),
            ),
            title: const Text('Ripristina'),
            subtitle: const Text('Recupera dati da Google Drive'),
            trailing: const Icon(Icons.chevron_right),
            enabled: provider.isGoogleSignedIn && !provider.isLoading,
            onTap: () => _confirmRestore(context, provider),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
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

  void _signInWithGoogle(BuildContext context, ExpenseProvider provider) async {
    try {
      final success = await provider.signInGoogle();
      if (!context.mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accesso effettuato! Backup automatico attivo.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accesso annullato'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      
      String errorMsg = 'Errore durante l\'accesso';
      Duration duration = const Duration(seconds: 4);
      
      final errorStr = e.toString().toLowerCase();
      
      // Su iOS, se manca la configurazione Google Sign-In
      if (errorStr.contains('idtokenrequested') || 
          errorStr.contains('platformexception') ||
          errorStr.contains('sign_in_failed') ||
          errorStr.contains('placeholder') ||
          errorStr.contains('no matching client found')) {
        errorMsg = 'Google Sign-In non configurato per iOS.\n'
                   'Consulta GOOGLE_SIGNIN_SETUP.md per le istruzioni.';
        duration = const Duration(seconds: 6);
      } else if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMsg = 'Errore di connessione. Verifica la tua rete.';
      } else if (errorStr.contains('canceled') || errorStr.contains('cancelled')) {
        errorMsg = 'Login annullato';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          duration: duration,
        ),
      );
    }
  }

  void _confirmSignOut(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnetti'),
        content: const Text(
          'Sei sicuro di volerti disconnettere?\n\n'
          'Il backup automatico verrà disattivato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.signOutGoogle();
            },
            child: Text('Disconnetti', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _manualBackup(BuildContext context, ExpenseProvider provider) async {
    final success = await provider.backupToGoogleDrive();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Backup completato' : 'Errore durante il backup'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _confirmRestore(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ripristina dati'),
        content: const Text(
          'Sei sicuro di voler ripristinare i dati dal backup?\n\n'
          'I dati attuali verranno sostituiti con quelli salvati su Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.restoreFromGoogleDrive();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Dati ripristinati' : 'Errore durante il ripristino',
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
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
