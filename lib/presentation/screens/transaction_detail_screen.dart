import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_utils.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_card.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = ref.watch(transactionRepositoryProvider).getById(transactionId);
    final categories = ref.watch(categoryMapProvider);
    final accounts = ref.watch(accountMapProvider);
    final tags = ref.watch(tagsProvider);
    final currency = ref.watch(currencyCodeProvider);

    if (tx == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Transaction not found')),
      );
    }

    final cat = categories[tx.categoryId];
    final acc = accounts[tx.accountId];
    final color = Color(cat?.colorValue ?? 0xFF64748B);
    final amountColor = switch (tx.type) {
      TransactionType.income => AppColors.income,
      TransactionType.refund => AppColors.refund,
      TransactionType.expense => AppColors.expense,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            onPressed: () => context.push('/edit/${tx.id}'),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete?'),
                  content: const Text('Remove this transaction permanently?'),
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
              if (ok == true && context.mounted) {
                await ref.read(transactionControllerProvider).delete(tx.id);
                if (context.mounted) context.pop();
              }
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Hero(
                  tag: 'tx-icon-${tx.id}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      iconFromCode(
                        cat?.iconCode ?? Icons.category.codePoint,
                      ),
                      size: 36,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  MoneyFormatter.format(
                    tx.signedAmount,
                    currencyCode: currency,
                    showSign: true,
                  ),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat?.name ?? 'Unknown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  tx.type.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          GlassCard(
            child: Column(
              children: [
                _row('Date', DateFormatters.medium(tx.date)),
                const Divider(height: 24),
                _row('Account', acc?.name ?? '—'),
                const Divider(height: 24),
                _row(
                  'Recurrence',
                  tx.recurrence.name[0].toUpperCase() +
                      tx.recurrence.name.substring(1),
                ),
                if (tx.note.isNotEmpty) ...[
                  const Divider(height: 24),
                  _row('Note', tx.note),
                ],
                if (tx.tags.isNotEmpty) ...[
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: tx.tags.map((id) {
                        TagModel? tag;
                        for (final t in tags) {
                          if (t.id == id) {
                            tag = t;
                            break;
                          }
                        }
                        return Chip(
                          label: Text(tag?.name ?? id),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
