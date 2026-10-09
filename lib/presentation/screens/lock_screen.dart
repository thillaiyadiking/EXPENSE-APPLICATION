import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/glass_card.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _error;
  bool _verifying = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _tryBiometric();
      });
    });
  }

  Future<void> _tryBiometric() async {
    if (_biometricBusy || _verifying) return;
    final settings = ref.read(settingsRepositoryProvider).get();
    if (!settings.biometricEnabled) return;

    setState(() {
      _biometricBusy = true;
      _error = null;
    });

    final auth = ref.read(authServiceProvider);
    try {
      final canUse = await auth.canUseBiometrics();
      if (!canUse || !mounted) {
        if (mounted) {
          setState(() {
            _biometricBusy = false;
            _error = 'Biometrics unavailable on this device';
          });
        }
        return;
      }

      final success = await auth.authenticateBiometric();
      if (!mounted) return;
      if (success) {
        await _unlock();
      } else {
        setState(() {
          _biometricBusy = false;
          _error = 'Biometric unlock cancelled. Enter PIN instead.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricBusy = false;
        _error = 'Biometric unlock failed. Enter PIN instead.';
      });
    }
  }

  Future<void> _unlock() async {
    final auth = ref.read(authServiceProvider);
    try {
      await auth.markUnlocked();
    } catch (_) {
      // Secure storage can fail on some MIUI builds; still unlock in-session.
    }
    if (!mounted) return;
    // Let GoRouter redirect from /lock → pending route or /home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUnlockedProvider.notifier).state = true;
    });
  }

  Future<void> _submitPin() async {
    if (_pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    final valid = await ref.read(authServiceProvider).verifyPin(_pin);
    if (!mounted) return;

    if (valid) {
      await _unlock();
    } else {
      setState(() {
        _verifying = false;
        _pin = '';
        _error = 'Incorrect PIN. Try again.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _onDigit(String digit) {
    if (_verifying || _pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    HapticFeedback.selectionClick();
    if (_pin.length == 6) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_verifying || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final biometricEnabled = settings?.biometricEnabled ?? false;
    final style = ref.watch(visualStyleProvider);
    final palette = AppColors.palette(style);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.heroGradient,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/branding/pocketflow_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your PIN to unlock',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        borderRadius: 28,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (i) {
                                final filled = i < _pin.length;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: filled
                                        ? AppColors.brand
                                        : AppColors.brand
                                            .withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: AppColors.brand
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.overspend,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            if (_verifying || _biometricBusy) ...[
                              const SizedBox(height: 12),
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _PinPad(
                              onDigit: _onDigit,
                              onBackspace: _onBackspace,
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _verifying ||
                                      _biometricBusy ||
                                      _pin.length < 4
                                  ? null
                                  : _submitPin,
                              child: const Text('Unlock'),
                            ),
                            if (biometricEnabled) ...[
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: _verifying || _biometricBusy
                                    ? null
                                    : _tryBiometric,
                                icon: const Icon(Icons.fingerprint_rounded),
                                label: const Text('Use biometrics'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 64, height: 56);
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _PinKey(
                  label: key,
                  onTap: key == '⌫' ? onBackspace : () => onDigit(key),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 64,
          height: 56,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label == '⌫' ? 20 : 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
