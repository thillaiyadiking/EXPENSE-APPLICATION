import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/analytics_entities.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/transaction_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(transactionFilterProvider);
    _searchController = TextEditingController(text: filter.query);
    _minAmountController = TextEditingController(
      text: filter.minAmount?.toString() ?? '',
    );
    _maxAmountController = TextEditingController(
      text: filter.maxAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _updateFilter(TransactionFilter Function(TransactionFilter) update) {
    ref.read(transactionFilterProvider.notifier).state =
        update(ref.read(transactionFilterProvider));
  }

  void _clearFilters() {
    _searchController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    ref.read(transactionFilterProvider.notifier).state =
        TransactionFilter.empty;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final resultsAsync = ref.watch(filteredTransactionsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final categoryMap = ref.watch(categoryMapProvider);
    final currency = ref.watch(currencyCodeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (filter.hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search notes, amounts, tags…',
              leading: const Icon(Icons.search_rounded),
              trailing: filter.query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _updateFilter((f) => f.copyWith(query: ''));
                        },
                      ),
                    ]
                  : null,
              onChanged: (q) => _updateFilter((f) => f.copyWith(query: q)),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final type in TransactionType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                      selected: filter.types.contains(type),
                      onSelected: (selected) {
                        final types = Set<TransactionType>.from(filter.types);
                        if (selected) {
                          types.add(type);
                        } else {
                          types.remove(type);
                        }
                        _updateFilter((f) => f.copyWith(types: types));
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final cat in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CategoryChip(
                      name: cat.name,
                      iconCode: cat.iconCode,
                      colorValue: cat.colorValue,
                      selected: filter.categoryIds.contains(cat.id),
                      onTap: () {
                        final ids = Set<String>.from(filter.categoryIds);
                        if (ids.contains(cat.id)) {
                          ids.remove(cat.id);
                        } else {
                          ids.add(cat.id);
                        }
                        _updateFilter((f) => f.copyWith(categoryIds: ids));
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                _FilterButton(
                  icon: Icons.date_range_rounded,
                  label: _dateLabel(filter),
                  onTap: () => _pickDateRange(filter),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  icon: Icons.attach_money_rounded,
                  label: _amountLabel(filter),
                  onTap: () => _showAmountDialog(filter),
                ),
                const Spacer(),
                _SortButton(
                  field: filter.sortField,
                  order: filter.sortOrder,
                  onChanged: (field, order) {
                    _updateFilter(
                      (f) => f.copyWith(sortField: field, sortOrder: order),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outline.withValues(alpha: 0.15)),
          Expanded(
            child: resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (results) {
                if (results.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: filter.hasActiveFilters
                        ? 'No matches'
                        : 'Search transactions',
                    subtitle: filter.hasActiveFilters
                        ? 'Try adjusting your filters.'
                        : 'Use search and filters to find transactions.',
                    actionLabel: filter.hasActiveFilters ? 'Clear filters' : null,
                    onAction: filter.hasActiveFilters ? _clearFilters : null,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final tx = results[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        borderRadius: 16,
                        child: TransactionTile(
                          transaction: tx,
                          category: categoryMap[tx.categoryId],
                          currencyCode: currency,
                          onTap: () => context.push('/transaction/${tx.id}'),
                          onEdit: () => context.push('/edit/${tx.id}'),
                          onDelete: () => ref
                              .read(transactionControllerProvider)
                              .delete(tx.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(TransactionFilter filter) {
    if (filter.startDate == null && filter.endDate == null) return 'Date';
    final start = filter.startDate != null
        ? '${filter.startDate!.month}/${filter.startDate!.day}'
        : '…';
    final end = filter.endDate != null
        ? '${filter.endDate!.month}/${filter.endDate!.day}'
        : '…';
    return '$start – $end';
  }

  String _amountLabel(TransactionFilter filter) {
    if (filter.minAmount == null && filter.maxAmount == null) return 'Amount';
    final min = filter.minAmount?.toStringAsFixed(0) ?? '0';
    final max = filter.maxAmount?.toStringAsFixed(0) ?? '∞';
    return '$min – $max';
  }

  Future<void> _pickDateRange(TransactionFilter filter) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: filter.startDate != null && filter.endDate != null
          ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
          : null,
    );
    if (range != null) {
      _updateFilter(
        (f) => f.copyWith(startDate: range.start, endDate: range.end),
      );
    }
  }

  Future<void> _showAmountDialog(TransactionFilter filter) async {
    _minAmountController.text = filter.minAmount?.toString() ?? '';
    _maxAmountController.text = filter.maxAmount?.toString() ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Amount range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _minAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Minimum'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Maximum'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _updateFilter((f) => f.copyWith(clearAmounts: true));
              Navigator.pop(ctx, true);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );

    if (saved == true) {
      final min = double.tryParse(_minAmountController.text.trim());
      final max = double.tryParse(_maxAmountController.text.trim());
      _updateFilter(
        (f) => f.copyWith(
          minAmount: min,
          maxAmount: max,
          clearAmounts: min == null && max == null,
        ),
      );
    }
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.field,
    required this.order,
    required this.onChanged,
  });

  final SortField field;
  final SortOrder order;
  final void Function(SortField field, SortOrder order) onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: 'Sort',
      onSelected: (value) {
        final parts = value.split(':');
        onChanged(
          SortField.values.byName(parts[0]),
          SortOrder.values.byName(parts[1]),
        );
      },
      itemBuilder: (context) => [
        for (final f in SortField.values)
          for (final o in SortOrder.values)
            PopupMenuItem(
              value: '${f.name}:${o.name}',
              child: Row(
                children: [
                  if (field == f && order == o)
                    const Icon(Icons.check_rounded, size: 18),
                  if (field == f && order == o) const SizedBox(width: 8),
                  Text('${_fieldLabel(f)} · ${_orderLabel(o)}'),
                ],
              ),
            ),
      ],
    );
  }

  String _fieldLabel(SortField f) {
    switch (f) {
      case SortField.date:
        return 'Date';
      case SortField.amount:
        return 'Amount';
      case SortField.note:
        return 'Note';
    }
  }

  String _orderLabel(SortOrder o) {
    switch (o) {
      case SortOrder.ascending:
        return 'Asc';
      case SortOrder.descending:
        return 'Desc';
    }
  }
}
