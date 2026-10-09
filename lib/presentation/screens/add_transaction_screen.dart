import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/icon_utils.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/category_chip.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.transactionId,
    this.initialType,
    this.quickType,
  });

  final String? transactionId;
  final TransactionType? initialType;
  final String? quickType;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  late TransactionType _type;
  String? _categoryId;
  String? _accountId;
  DateTime _date = DateTime.now();
  RecurrenceRule _recurrence = RecurrenceRule.none;
  final Set<String> _selectedTags = {};
  bool _saving = false;

  bool get _isEditing => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ??
        switch (widget.quickType) {
          'income' => TransactionType.income,
          'refund' => TransactionType.refund,
          _ => TransactionType.expense,
        };

    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    final accounts = ref.read(accountRepositoryProvider).getAll();
    final cats = ref.read(categoryRepositoryProvider).getAll();
    _accountId ??=
        ref.read(accountRepositoryProvider).getDefault()?.id ??
            (accounts.isNotEmpty ? accounts.first.id : null);

    if (_isEditing) {
      final tx =
          ref.read(transactionRepositoryProvider).getById(widget.transactionId!);
      if (tx != null) {
        setState(() {
          _amountCtrl.text = tx.amount.toStringAsFixed(2);
          _noteCtrl.text = tx.note;
          _type = tx.type;
          _categoryId = tx.categoryId;
          _accountId = tx.accountId;
          _date = tx.date;
          _recurrence = tx.recurrence;
          _selectedTags.addAll(tx.tags);
        });
      }
    } else {
      final filtered = cats.where((c) {
        if (_type == TransactionType.income) return c.isIncome;
        return !c.isIncome;
      }).toList();
      if (filtered.isNotEmpty) {
        setState(() => _categoryId = filtered.first.id);
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    if (_categoryId == null || _accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select category and account')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final tx = TransactionModel(
      id: widget.transactionId ?? const Uuid().v4(),
      amount: amount,
      type: _type,
      categoryId: _categoryId!,
      accountId: _accountId!,
      date: _date,
      note: _noteCtrl.text.trim(),
      tags: _selectedTags.toList(),
      recurrence: _recurrence,
      createdAt: _isEditing
          ? (ref
                  .read(transactionRepositoryProvider)
                  .getById(widget.transactionId!)
                  ?.createdAt ??
              now)
          : now,
      updatedAt: _isEditing ? now : null,
    );

    final controller = ref.read(transactionControllerProvider);
    if (_isEditing) {
      await controller.update(tx);
    } else {
      await controller.add(tx);
    }

    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Transaction updated' : 'Transaction added'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final tags = ref.watch(tagsProvider);
    final currency = ref.watch(currencyCodeProvider);

    final visibleCats = categories.where((c) {
      if (_type == TransactionType.income) return c.isIncome;
      return !c.isIncome;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit transaction' : 'Add transaction'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.remove_rounded),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
                icon: Icon(Icons.add_rounded),
              ),
              ButtonSegment(
                value: TransactionType.refund,
                label: Text('Refund'),
                icon: Icon(Icons.replay_rounded),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) {
              setState(() {
                _type = s.first;
                final filtered = categories.where((c) {
                  if (_type == TransactionType.income) return c.isIncome;
                  return !c.isIncome;
                }).toList();
                _categoryId =
                    filtered.isNotEmpty ? filtered.first.id : null;
              });
            },
          ),
          const SizedBox(height: 28),
          Text(
            'Amount',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            autofocus: !_isEditing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
            decoration: InputDecoration(
              prefixText: '$currency ',
              hintText: '0.00',
              border: InputBorder.none,
              filled: false,
            ),
          ),
          const SizedBox(height: 16),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in visibleCats)
                CategoryChip(
                  name: cat.name,
                  iconCode: cat.iconCode,
                  colorValue: cat.colorValue,
                  selected: _categoryId == cat.id,
                  onTap: () => setState(() => _categoryId = cat.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Account', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final acc in accounts)
                ChoiceChip(
                  label: Text(acc.name),
                  selected: _accountId == acc.id,
                  onSelected: (_) => setState(() => _accountId = acc.id),
                  avatar: Icon(
                    iconFromCode(acc.iconCode),
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Date'),
            subtitle: Text(DateFormatters.medium(_date)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'Optional note',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<RecurrenceRule>(
            // ignore: deprecated_member_use
            value: _recurrence,
            decoration: const InputDecoration(
              labelText: 'Recurring',
              prefixIcon: Icon(Icons.repeat_rounded),
            ),
            items: RecurrenceRule.values
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _recurrence = v ?? RecurrenceRule.none),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Tags', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in tags)
                  FilterChip(
                    label: Text(tag.name),
                    selected: _selectedTags.contains(tag.id),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _selectedTags.add(tag.id);
                        } else {
                          _selectedTags.remove(tag.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(_isEditing ? 'Update' : 'Save transaction'),
          ),
        ],
      ),
    );
  }
}
