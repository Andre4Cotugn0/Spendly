import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/debt.dart';
import '../../providers/expense_provider.dart';

class AddDebtScreen extends StatefulWidget {
  final Debt? debt;
  const AddDebtScreen({super.key, this.debt});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountFocusNode = FocusNode();

  DebtType _type = DebtType.iOwe;
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  bool _isLoading = false;

  bool get _isEditing => widget.debt != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final debt = widget.debt!;
      _personController.text = debt.personName;
      _amountController.text = debt.amount.toStringAsFixed(2);
      _descriptionController.text = debt.description ?? '';
      _type = debt.type;
      _date = debt.date;
      _dueDate = debt.dueDate;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
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
          _isEditing ? 'Modifica Debito' : 'Nuovo Debito',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Tipo debito
                  _buildSectionTitle('Tipo'),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  // Nome persona
                  _buildSectionTitle('Persona'),
                  const SizedBox(height: 12),
                  _buildPersonInput(),
                  const SizedBox(height: 24),

                  // Importo
                  _buildSectionTitle('Importo'),
                  const SizedBox(height: 12),
                  _buildAmountInput(),
                  const SizedBox(height: 24),

                  // Data
                  _buildSectionTitle('Data'),
                  const SizedBox(height: 12),
                  _buildDateSelector(),
                  const SizedBox(height: 24),

                  // Scadenza
                  _buildSectionTitle('Scadenza (opzionale)'),
                  const SizedBox(height: 12),
                  _buildDueDateSelector(),
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
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: DebtType.values.map((type) {
        final isSelected = _type == type;
        final color = type == DebtType.iOwe ? AppColors.error : AppColors.success;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type != DebtType.values.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _type = type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? color.withAlpha(26) : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppColors.surfaceLight,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      type == DebtType.iOwe
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: isSelected ? color : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? color : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPersonInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: TextFormField(
        controller: _personController,
        decoration: InputDecoration(
          hintText: 'Es: Marco, Anna...',
          hintStyle: TextStyle(color: AppColors.textTertiary.withAlpha(179)),
          prefixIcon:
              const Icon(Icons.person_outline, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          prefixIcon: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('€',
                style: TextStyle(
                    fontSize: 20, color: AppColors.textSecondary)),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+[,.]?\d{0,2}')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return newValue.copyWith(
                text: newValue.text.replaceAll(',', '.'));
          }),
        ],
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(isStartDate: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: 12),
            Text(
              Formatters.date(_date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(isStartDate: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event,
              color: _dueDate != null ? AppColors.warning : AppColors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _dueDate != null ? Formatters.date(_dueDate!) : 'Nessuna scadenza',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _dueDate != null ? null : AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(Icons.close, color: AppColors.textTertiary, size: 20),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
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
          hintText: 'Motivo del debito...',
          hintStyle: TextStyle(color: AppColors.textTertiary.withAlpha(179)),
          prefixIcon:
              const Icon(Icons.notes, color: AppColors.textTertiary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
      ),
    );
  }

  Widget _buildSaveButton() {
    final isValid = _personController.text.trim().isNotEmpty &&
        _amountController.text.isNotEmpty &&
        (double.tryParse(_amountController.text) ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isValid && !_isLoading ? _saveDebt : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _type == DebtType.iOwe
                ? AppColors.error
                : AppColors.success,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            disabledBackgroundColor: AppColors.surfaceLight,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _isEditing ? 'Aggiorna' : 'Aggiungi debito',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate ? _date : (_dueDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _date = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveDebt() async {
    final person = _personController.text.trim();
    final amount = double.tryParse(_amountController.text);
    if (person.isEmpty || amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    final provider = context.read<ExpenseProvider>();
    final description = _descriptionController.text.trim();

    final debt = _isEditing
        ? widget.debt!.copyWith(
            personName: person,
            amount: amount,
            type: _type,
            description: description.isEmpty ? null : description,
            date: _date,
            dueDate: _dueDate,
          )
        : Debt(
            personName: person,
            amount: amount,
            type: _type,
            description: description.isEmpty ? null : description,
            date: _date,
            dueDate: _dueDate,
          );

    final success = _isEditing
        ? await provider.updateDebt(debt)
        : await provider.addDebt(debt);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
      }
    }
  }
}
