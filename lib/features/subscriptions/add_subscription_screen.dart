import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/subscription.dart';
import '../../data/models/category.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_icon.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;
  const AddSubscriptionScreen({super.key, this.subscription});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountFocusNode = FocusNode();

  SubscriptionFrequency _frequency = SubscriptionFrequency.monthly;
  String? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  bool _reminderEnabled = true;
  int _reminderDaysBefore = 1;
  bool _isLoading = false;
  bool _showSuggestions = true;

  bool get _isEditing => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final sub = widget.subscription!;
      _nameController.text = sub.name;
      _amountController.text = sub.amount.toStringAsFixed(2);
      _descriptionController.text = sub.description ?? '';
      _frequency = sub.frequency;
      _selectedCategoryId = sub.categoryId;
      _startDate = sub.startDate;
      _reminderEnabled = sub.reminderEnabled;
      _reminderDaysBefore = sub.reminderDaysBefore;
      _showSuggestions = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Modifica Abbonamento' : 'Nuovo Abbonamento',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Suggerimenti rapidi
                      if (_showSuggestions && !_isEditing) ...[
                        _buildSectionTitle('Scegli rapido'),
                        const SizedBox(height: 12),
                        _buildSuggestions(provider),
                        const SizedBox(height: 24),
                      ],

                      // Nome
                      _buildSectionTitle('Nome'),
                      const SizedBox(height: 12),
                      _buildNameInput(),
                      const SizedBox(height: 24),

                      // Importo
                      _buildSectionTitle('Importo'),
                      const SizedBox(height: 12),
                      _buildAmountInput(),
                      const SizedBox(height: 24),

                      // Frequenza
                      _buildSectionTitle('Frequenza'),
                      const SizedBox(height: 12),
                      _buildFrequencySelector(),
                      const SizedBox(height: 24),

                      // Categoria
                      _buildSectionTitle('Categoria'),
                      const SizedBox(height: 12),
                      _buildCategoryGrid(provider.categories),
                      const SizedBox(height: 24),

                      // Data inizio
                      _buildSectionTitle('Data primo pagamento'),
                      const SizedBox(height: 12),
                      _buildDateSelector(),
                      const SizedBox(height: 24),

                      // Promemoria
                      _buildReminderSection(),
                      const SizedBox(height: 24),

                      // Note
                      _buildSectionTitle('Note (opzionale)'),
                      const SizedBox(height: 12),
                      _buildDescriptionInput(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSuggestions(ExpenseProvider provider) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: SuggestedSubscriptions.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = SuggestedSubscriptions.suggestions[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _nameController.text = s['name'] as String;
              _amountController.text = (s['amount'] as num).toStringAsFixed(2);
              final freq = s['frequency'] as String;
              final suggestedCategoryId = s['category'] as String?;
              setState(() {
                _frequency = SubscriptionFrequency.values.firstWhere(
                  (f) => f.name == freq,
                  orElse: () => SubscriptionFrequency.monthly,
                );
                _selectedCategoryId = _resolveSuggestedCategoryId(
                  provider.categories,
                  suggestedCategoryId,
                );
                _showSuggestions = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Center(
                child: Text(
                  s['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  String? _resolveSuggestedCategoryId(List<Category> categories, String? suggestedId) {
    if (categories.isEmpty) return null;
    if (suggestedId != null) {
      for (final category in categories) {
        if (category.id == suggestedId) {
          return category.id;
        }
      }
    }
    return categories.first.id;
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Es: Netflix, Spotify...',
          hintStyle: TextStyle(color: AppColors.textTertiary.withAlpha(179)),
          prefixIcon: Icon(Icons.subscriptions_outlined, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: TextFormField(
        controller: _amountController,
        focusNode: _amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: '0.00',
          hintStyle: TextStyle(color: AppColors.textTertiary.withAlpha(179)),
          prefixIcon: Padding(
            padding: EdgeInsets.all(14),
            child: Text('€', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return newValue.copyWith(text: newValue.text.replaceAll(',', '.'));
          }),
        ],
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Row(
      children: SubscriptionFrequency.values.map((freq) {
        final isSelected = _frequency == freq;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: freq != SubscriptionFrequency.values.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _frequency = freq);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withAlpha(26) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    freq.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategoryId == category.id;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedCategoryId = category.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? category.color.withAlpha(38) : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? category.color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryIcon(
                  iconName: category.iconName,
                  color: isSelected ? category.color : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? category.color : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.notifications_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Promemoria pagamento',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Switch(
                value: _reminderEnabled,
                onChanged: (v) => setState(() => _reminderEnabled = v),
                activeTrackColor: AppColors.primary,
              ),
            ],
          ),
          if (_reminderEnabled) ...[
            const Divider(height: 24),
            Row(
              children: [
                Text('Avvisa ', style: TextStyle(color: AppColors.textSecondary)),
                _buildDayChip(1),
                const SizedBox(width: 8),
                _buildDayChip(2),
                const SizedBox(width: 8),
                _buildDayChip(3),
                Text(
                  ' giorni prima',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayChip(int days) {
    final isSelected = _reminderDaysBefore == days;
    return GestureDetector(
      onTap: () => setState(() => _reminderDaysBefore = days),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '$days',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: TextFormField(
        controller: _descriptionController,
        decoration: InputDecoration(
          hintText: 'Aggiungi una nota...',
          hintStyle: TextStyle(color: AppColors.textTertiary.withAlpha(179)),
          prefixIcon: Icon(Icons.edit_note, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        maxLines: 2,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildSaveButton(ExpenseProvider provider) {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasAmount = _amountController.text.isNotEmpty;
    final hasCategory = _selectedCategoryId != null;
    final isReady = hasName && hasAmount && hasCategory;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: isReady ? AppColors.primaryGradient : null,
              color: isReady ? null : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isReady
                  ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (_isLoading || !isReady) ? null : () => _save(provider),
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isEditing ? Icons.check : Icons.add,
                              color: isReady ? Colors.white : AppColors.textTertiary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isEditing ? 'Salva Modifiche' : 'Aggiungi Abbonamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isReady ? Colors.white : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save(ExpenseProvider provider) async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    final sub = Subscription(
      id: _isEditing ? widget.subscription!.id : null,
      name: _nameController.text.trim(),
      amount: amount,
      categoryId: _selectedCategoryId!,
      frequency: _frequency,
      startDate: _startDate,
      reminderEnabled: _reminderEnabled,
      reminderDaysBefore: _reminderDaysBefore,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text.trim(),
      isActive: _isEditing ? widget.subscription!.isActive : true,
      createdAt: _isEditing ? widget.subscription!.createdAt : null,
    );

    bool success;
    if (_isEditing) {
      success = await provider.updateSubscription(sub);
    } else {
      success = await provider.addSubscription(sub);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(_isEditing ? 'Abbonamento modificato' : 'Abbonamento aggiunto'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
