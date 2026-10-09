import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/safe_dispose.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_card.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _creating = false;
  bool _restoring = false;

  Future<void> _createBackup() async {
    setState(() => _creating = true);
    try {
      final backup = ref.read(backupServiceProvider);
      final file = await backup.createBackup();
      await backup.shareBackup(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup created: ${file.path.split(Platform.pathSeparator).last}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _restoreBackup() async {
    final jsonController = TextEditingController();
    final pathController = TextEditingController();

    final docs = await getApplicationDocumentsDirectory();
    if (!mounted) {
      disposeAfterFrame([jsonController, pathController]);
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Paste backup JSON, or enter the full path to a .json backup file.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: InputDecoration(
                    labelText: 'File path',
                    hintText: '${docs.path}${Platform.pathSeparator}pocketflow_backup_....json',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Or paste JSON',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      jsonController.text = data!.text!;
                    }
                  },
                  icon: const Icon(Icons.paste_rounded),
                  label: const Text('Paste from clipboard'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'go'),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (choice != 'go') {
      disposeAfterFrame([jsonController, pathController]);
      return;
    }

    String? jsonString;
    final path = pathController.text.trim();
    final pasted = jsonController.text.trim();
    if (pasted.isNotEmpty) {
      jsonString = pasted;
    } else if (path.isNotEmpty) {
      final file = File(path);
      if (!await file.exists()) {
        disposeAfterFrame([jsonController, pathController]);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File not found at that path')),
          );
        }
        return;
      }
      jsonString = await file.readAsString();
    } else {
      disposeAfterFrame([jsonController, pathController]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provide a file path or paste JSON')),
        );
      }
      return;
    }

    if (!mounted) {
      disposeAfterFrame([jsonController, pathController]);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace all data?'),
        content: const Text(
          'This replaces all current PocketFlow data with the backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      disposeAfterFrame([jsonController, pathController]);
      return;
    }

    setState(() => _restoring = true);
    try {
      await ref.read(backupServiceProvider).restoreBackup(jsonString);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(budgetsProvider);
      ref.invalidate(settingsProvider);
      ref.invalidate(accountsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      disposeAfterFrame([jsonController, pathController]);
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 800 ? 600.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandDark,
                      AppColors.brand,
                      Color(0xFF0EA5E9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_sync_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Your data, your control',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Export a full JSON backup and restore it anytime.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _creating ? null : _createBackup,
                      icon: _creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(
                        _creating ? 'Creating…' : 'Create & share backup',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _restoring ? null : _restoreBackup,
                      icon: _restoring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _restoring ? 'Restoring…' : 'Restore from JSON / path',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${AppConstants.appName} backups are not encrypted. Store them securely.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
