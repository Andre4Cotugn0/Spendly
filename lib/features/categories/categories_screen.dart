import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/category.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/category_icon.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final defaultCategories = provider.categories.where((c) => c.isDefault).toList();
        final customCategories = provider.categories.where((c) => !c.isDefault).toList();

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Categorie'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddCategoryDialog(context, provider),
                ),
              ],
            ),

            // Default Categories
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Categorie Predefinite',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = defaultCategories[index];
                  return _CategoryItem(
                    category: category,
                    canDelete: false,
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 50 * index),
                        duration: 300.ms,
                      );
                },
                childCount: defaultCategories.length,
              ),
            ),

            // Custom Categories
            if (customCategories.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    'Le Tue Categorie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = customCategories[index];
                    return _CategoryItem(
                      category: category,
                      canDelete: true,
                      onDelete: () => _confirmDeleteCategory(context, provider, category),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          duration: 300.ms,
                        );
                  },
                  childCount: customCategories.length,
                ),
              ),
            ],

            // Empty state for custom categories
            if (customCategories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nessuna categoria personalizzata',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tocca + per aggiungerne una',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, ExpenseProvider provider) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.primary;
    
    final availableColors = [
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF95E1D3),
      const Color(0xFFA66CFF),
      const Color(0xFFFF9671),
      const Color(0xFF6BCB77),
      const Color(0xFF778DA9),
      const Color(0xFFE84393),
      const Color(0xFF00B894),
      const Color(0xFF0984E3),
      const Color(0xFFFDAA43),
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuova Categoria'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome categoria',
                  hintText: 'Es: Abbonamenti',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Text(
                'Colore',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableColors.map((color) {
                  final isSelected = selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(128),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci un nome')),
                  );
                  return;
                }

                final category = Category(
                  name: name,
                  iconName: 'custom',
                  color: selectedColor,
                  isDefault: false,
                );

                final success = await provider.addCategory(category);
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Categoria creata'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Crea'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    ExpenseProvider provider,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Categoria'),
        content: Text(
          'Sei sicuro di voler eliminare "${category.name}"?\n\n'
          'Tutte le spese associate verranno eliminate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteCategory(category.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Categoria eliminata'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Elimina', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final Category category;
  final bool canDelete;
  final VoidCallback? onDelete;

  const _CategoryItem({
    required this.category,
    required this.canDelete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CategoryIconContainer(
              iconName: category.iconName,
              backgroundColor: category.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (!category.isDefault)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Personalizzata',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
