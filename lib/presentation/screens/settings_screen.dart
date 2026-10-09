import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/currencies.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/safe_dispose.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/home_widget_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/widget_guide_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = ref.watch(currencyCodeProvider);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 800 ? 900.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _SectionLabel(title: 'Preferences'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.attach_money_rounded),
                          title: const Text('Currency'),
                          subtitle: Text(
                            '${findCurrency(settings.currencyCode)?.name ?? settings.currencyCode} '
                            '(${findCurrency(settings.currencyCode)?.symbol ?? settings.currencyCode})',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showCurrencyPicker(context, ref, settings),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Theme'),
                          subtitle: Text(_themeLabel(settings.themeMode)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showThemePicker(context, ref, settings),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.auto_awesome_rounded),
                          title: const Text('Appearance'),
                          subtitle: Text(_styleLabel(settings.visualStyle)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              _showAppearancePicker(context, ref, settings),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.account_balance_wallet_outlined),
                          title: const Text('Monthly budget'),
                          subtitle: Text(
                            MoneyFormatter.format(
                              settings.monthlyBudget,
                              currencyCode: currency,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _editMonthlyBudget(context, ref, settings),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(title: 'Security'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.pin_outlined),
                          title: const Text('PIN lock'),
                          subtitle: const Text('Require PIN to open the app'),
                          value: settings.pinEnabled,
                          onChanged: (enabled) async {
                            if (enabled) {
                              await _enablePin(context, ref);
                            } else {
                              await _disablePin(context, ref, settings);
                            }
                          },
                        ),
                        const Divider(height: 1, indent: 56),
                        SwitchListTile(
                          secondary: const Icon(Icons.fingerprint_rounded),
                          title: const Text('Biometric unlock'),
                          subtitle: const Text('Use fingerprint or face ID'),
                          value: settings.biometricEnabled,
                          onChanged: settings.pinEnabled
                              ? (enabled) async {
                                  if (enabled) {
                                    final canUse = await ref
                                        .read(authServiceProvider)
                                        .canUseBiometrics();
                                    if (!canUse && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Biometrics not available on this device.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                  await ref
                                      .read(settingsControllerProvider)
                                      .update(
                                        settings.copyWith(
                                          biometricEnabled: enabled,
                                        ),
                                      );
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(title: 'Notifications'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Budget reminders'),
                      subtitle: const Text('Daily check-in at 8:00 PM'),
                      value: settings.budgetRemindersEnabled,
                      onChanged: (enabled) {
                        ref.read(settingsControllerProvider).update(
                              settings.copyWith(
                                budgetRemindersEnabled: enabled,
                              ),
                            );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(title: 'Help'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: const Text('Replay app guide'),
                          subtitle: const Text(
                            'Full walkthrough of Home, Analytics, Budget & more',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/onboarding?replay=1'),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.widgets_outlined),
                          title: const Text('Money Glance guide'),
                          subtitle: const Text(
                            'Short tips for the home-screen widget',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              showWidgetGuideSheet(context, markComplete: false),
                        ),
                        const Divider(height: 1, indent: 56),
                        const _AddHomeWidgetTile(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel(title: 'Data'),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.category_outlined),
                          title: const Text('Categories'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/categories'),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.backup_outlined),
                          title: const Text('Backup & restore'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.push('/backup'),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: const Text('Export CSV'),
                          onTap: () => _exportCsv(context, ref),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: const Icon(Icons.picture_as_pdf_outlined),
                          title: const Text('Export PDF report'),
                          onTap: () => _exportPdf(context, ref),
                        ),
                        const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Icon(
                            Icons.delete_forever_outlined,
                            color: AppColors.expense,
                          ),
                          title: Text(
                            'Clear all data',
                            style: TextStyle(color: AppColors.expense),
                          ),
                          subtitle: const Text('Requires security key'),
                          onTap: () => _clearAllData(context, ref),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'System default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  String _styleLabel(AppVisualStyle style) {
    switch (style) {
      case AppVisualStyle.classic:
        return 'Classic — teal fintech';
      case AppVisualStyle.rich:
        return 'Rich — navy & gold';
    }
  }

  Future<void> _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    AppSettingsModel settings,
  ) async {
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = kIsoCurrencies.where((c) {
              if (query.isEmpty) return true;
              final q = query.toLowerCase();
              return c.code.toLowerCase().contains(q) ||
                  c.name.toLowerCase().contains(q);
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (_, scrollController) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search currencies…',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final selected = c.code == settings.currencyCode;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: selected
                                ? AppColors.brand.withValues(alpha: 0.15)
                                : null,
                            child: Text(
                              c.symbol,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.brand : null,
                              ),
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: Text(c.code),
                          trailing: selected
                              ? const Icon(Icons.check_rounded, color: AppColors.brand)
                              : null,
                          onTap: () async {
                            await ref
                                .read(settingsControllerProvider)
                                .setCurrency(c.code);
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    AppSettingsModel settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in AppThemeMode.values)
              ListTile(
                title: Text(_themeLabel(mode)),
                trailing: settings.themeMode == mode
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  await ref.read(settingsControllerProvider).setTheme(mode);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAppearancePicker(
    BuildContext context,
    WidgetRef ref,
    AppSettingsModel settings,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Appearance',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional visual style. Theme mode (light/dark) still applies.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _AppearancePreviewTile(
                      label: 'Classic',
                      subtitle: 'Teal',
                      selected: settings.visualStyle == AppVisualStyle.classic,
                      colors: const [
                        Color(0xFF134E4A),
                        Color(0xFF0F766E),
                        Color(0xFF14B8A6),
                      ],
                      onTap: () async {
                        await ref
                            .read(settingsControllerProvider)
                            .setVisualStyle(AppVisualStyle.classic);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AppearancePreviewTile(
                      label: 'Rich',
                      subtitle: 'Navy & gold',
                      selected: settings.visualStyle == AppVisualStyle.rich,
                      colors: const [
                        Color(0xFF070B14),
                        Color(0xFF1A2740),
                        Color(0xFFB8860B),
                      ],
                      onTap: () async {
                        await ref
                            .read(settingsControllerProvider)
                            .setVisualStyle(AppVisualStyle.rich);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editMonthlyBudget(
    BuildContext context,
    WidgetRef ref,
    AppSettingsModel settings,
  ) async {
    final controller = TextEditingController(
      text: settings.monthlyBudget.toStringAsFixed(0),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Monthly budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v != null && v >= 0) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (amount != null) {
      await ref.read(settingsControllerProvider).setMonthlyBudget(amount);
    }
    disposeAfterFrame([controller]);
  }

  Future<void> _enablePin(BuildContext context, WidgetRef ref) async {
    final pin = await _showPinDialog(context, title: 'Set PIN', confirm: true);
    if (pin == null || pin.length < 4) return;

    final auth = ref.read(authServiceProvider);
    await auth.setPin(pin);
    final current = ref.read(settingsRepositoryProvider).get();
    await ref.read(settingsControllerProvider).update(
          current.copyWith(
            pinEnabled: true,
            pinHash: auth.hashPin(pin),
          ),
        );
  }

  Future<void> _disablePin(
    BuildContext context,
    WidgetRef ref,
    AppSettingsModel settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable PIN?'),
        content: const Text('Anyone with access to your device can open the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(authServiceProvider).clearPin();
    await ref.read(settingsControllerProvider).update(
          settings.copyWith(
            pinEnabled: false,
            biometricEnabled: false,
            clearPin: true,
          ),
        );
  }

  Future<String?> _showPinDialog(
    BuildContext context, {
    required String title,
    bool confirm = false,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN (4–6 digits)',
                counterText: '',
              ),
              autofocus: true,
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  counterText: '',
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pin = controller.text.trim();
              if (pin.length < 4 || pin.length > 6) return;
              if (confirm && pin != confirmController.text.trim()) return;
              Navigator.pop(ctx, pin);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    disposeAfterFrame([controller, confirmController]);
    return result;
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final txs = ref.read(transactionsProvider).valueOrNull ?? [];
    final categories = ref.read(categoryMapProvider);
    final accounts = ref.read(accountMapProvider);
    final currency = ref.read(currencyCodeProvider);
    final export = ref.read(exportServiceProvider);

    try {
      final file = await export.exportCsv(
        transactions: txs,
        categories: categories,
        accounts: accounts,
        currencyCode: currency,
      );
      await export.shareFile(file, subject: 'PocketFlow CSV Export');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV export ready to share')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final txs = ref.read(transactionsProvider).valueOrNull ?? [];
    final categories = ref.read(categoryMapProvider);
    final currency = ref.read(currencyCodeProvider);
    final dash = ref.read(dashboardProvider).valueOrNull;
    final export = ref.read(exportServiceProvider);

    try {
      final file = await export.exportPdfReport(
        transactions: txs,
        categories: categories,
        currencyCode: currency,
        income: dash?.totalIncome ?? 0,
        expense: dash?.totalExpense ?? 0,
        balance: dash?.balance ?? 0,
      );
      await export.shareFile(file, subject: 'PocketFlow PDF Report');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF report ready to share')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _ClearDataKeyDialog(),
    );
    if (confirmed != true) return;

    await ref.read(settingsControllerProvider).resetAllData();
    ref.invalidate(transactionsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(budgetsProvider);
    ref.invalidate(settingsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }
}

class _ClearDataKeyDialog extends StatefulWidget {
  const _ClearDataKeyDialog();

  @override
  State<_ClearDataKeyDialog> createState() => _ClearDataKeyDialogState();
}

class _ClearDataKeyDialogState extends State<_ClearDataKeyDialog> {
  late final TextEditingController _keyController;
  var _keyError = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _submit() {
    final ok = _keyController.text.trim().toUpperCase() ==
        AppConstants.dataWipeSecurityKey;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _keyError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clear all data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This permanently deletes all transactions, budgets, '
            'custom categories, and resets settings.\n\n'
            'Type the security key to confirm:',
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.dataWipeSecurityKey,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: AppColors.expense,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Security key',
              errorText: _keyError ? 'Incorrect security key' : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
          onPressed: _submit,
          child: const Text('Clear everything'),
        ),
      ],
    );
  }
}

class _AppearancePreviewTile extends StatelessWidget {
  const _AppearancePreviewTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (selected) ...[
                const SizedBox(height: 6),
                Icon(Icons.check_circle_rounded, size: 18, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddHomeWidgetTile extends ConsumerStatefulWidget {
  const _AddHomeWidgetTile();

  @override
  ConsumerState<_AddHomeWidgetTile> createState() => _AddHomeWidgetTileState();
}

class _AddHomeWidgetTileState extends ConsumerState<_AddHomeWidgetTile>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(homeWidgetPinnedProvider);
    }
  }

  Future<void> _onTap(bool alreadyPinned) async {
    if (alreadyPinned) return;
    final result =
        await ref.read(homeWidgetServiceProvider).requestPinWidget();
    if (!mounted) return;
    ref.invalidate(homeWidgetPinnedProvider);

    final message = switch (result) {
      PinWidgetResult.prompted =>
        'Follow the system prompt to place the widget.',
      PinWidgetResult.alreadyPinned =>
        'Money Glance is already on your home screen.',
      PinWidgetResult.unsupported =>
        'Not supported here. Long-press home → Widgets → PocketFlow.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final pinnedAsync = ref.watch(homeWidgetPinnedProvider);
    final pinned = pinnedAsync.valueOrNull ?? false;

    return ListTile(
      enabled: !pinned,
      leading: Icon(
        pinned ? Icons.check_circle_outline_rounded : Icons.add_to_home_screen_rounded,
      ),
      title: Text(pinned ? 'Widget already added' : 'Add widget to home'),
      subtitle: Text(
        pinned
            ? 'Remove it from the home screen to enable this again'
            : 'Pin PocketFlow if your launcher supports it',
      ),
      trailing: pinned
          ? null
          : const Icon(Icons.chevron_right_rounded),
      onTap: pinned ? null : () => _onTap(false),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
      ),
    );
  }
}
