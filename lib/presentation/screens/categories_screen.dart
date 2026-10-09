import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_utils.dart';
import '../../core/utils/safe_dispose.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';

const _kCategoryIcons = [
  Icons.restaurant_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.movie_rounded,
  Icons.receipt_long_rounded,
  Icons.favorite_rounded,
  Icons.school_rounded,
  Icons.flight_rounded,
  Icons.home_rounded,
  Icons.pets_rounded,
  Icons.sports_esports_rounded,
  Icons.more_horiz_rounded,
];

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: () => _showCategoryDialog(context, ref),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories',
              subtitle: 'Create custom categories for your spending.',
              actionLabel: 'Add category',
              onAction: () => _showCategoryDialog(context, ref),
            );
          }

          final income = categories.where((c) => c.isIncome).toList();
          final expense = categories.where((c) => !c.isIncome).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (expense.isNotEmpty) ...[
                _SectionHeader(title: 'Expense categories'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final cat in expense)
                        _CategoryTile(
                          category: cat,
                          onEdit: cat.isDefault
                              ? null
                              : () => _showCategoryDialog(
                                    context,
                                    ref,
                                    existing: cat,
                                  ),
                          onDelete: cat.isDefault
                              ? null
                              : () => _confirmDelete(context, ref, cat),
                        ),
                    ],
                  ),
                ),
              ],
              if (income.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionHeader(title: 'Income categories'),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final cat in income)
                        _CategoryTile(
                          category: cat,
                          onEdit: cat.isDefault
                              ? null
                              : () => _showCategoryDialog(
                                    context,
                                    ref,
                                    existing: cat,
                                  ),
                          onDelete: cat.isDefault
                              ? null
                              : () => _confirmDelete(context, ref, cat),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Remove "${cat.name}"? Transactions using this category will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(categoryRepositoryProvider).delete(cat.id);
    }
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var selectedIcon = existing?.iconCode ?? _kCategoryIcons.first.codePoint;
    var selectedColor = existing?.colorValue ??
        AppColors.categoryPalette.first.toARGB32();
    var isIncome = existing?.isIncome ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'New category' : 'Edit category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (existing == null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Income category'),
                    value: isIncome,
                    onChanged: (v) => setState(() => isIncome = v),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Icon',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kCategoryIcons.map((icon) {
                    final selected = selectedIcon == icon.codePoint;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = icon.codePoint),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? Color(selectedColor).withValues(alpha: 0.2)
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: Color(selectedColor), width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: selected
                              ? Color(selectedColor)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColors.categoryPalette.map((color) {
                    final selected = selectedColor == color.toARGB32();
                    return InkWell(
                      onTap: () =>
                          setState(() => selectedColor = color.toARGB32()),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      final repo = ref.read(categoryRepositoryProvider);
      if (existing != null) {
        await repo.update(
          existing.copyWith(
            name: nameController.text.trim(),
            iconCode: selectedIcon,
            colorValue: selectedColor,
          ),
        );
      } else {
        await repo.add(
          CategoryModel(
            id: '',
            name: nameController.text.trim(),
            iconCode: selectedIcon,
            colorValue: selectedColor,
            isIncome: isIncome,
            sortOrder: 100,
          ),
        );
      }
    }
    disposeAfterFrame([nameController]);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    this.onEdit,
    this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          iconFromCode(category.iconCode),
          color: color,
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: category.isDefault
          ? const Text('Default category')
          : Text(category.isIncome ? 'Income' : 'Expense'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
