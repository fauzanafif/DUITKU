import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/services/pin_service.dart';

/// Blocks the app behind a PIN / biometric prompt when the user enabled it.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  bool _unlocked = false;
  bool _biometricTried = false;
  String _error = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.valueOrNull;

    if (settings == null || !settings.pinEnabled || _unlocked) {
      return widget.child;
    }

    if (settings.biometricEnabled && !_biometricTried) {
      _biometricTried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ok = await ref.read(biometricServiceProvider).authenticate();
        if (ok && mounted) setState(() => _unlocked = true);
      });
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('DUITKU terkunci',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Masukkan PIN ${PinService.pinLength} digit',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: PinService.pinLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  errorText: _error.isEmpty ? null : _error,
                ),
                onChanged: (value) {
                  if (value.length == PinService.pinLength) _verify();
                },
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _verify, child: const Text('Buka')),
              if (settings.biometricEnabled) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final ok =
                        await ref.read(biometricServiceProvider).authenticate();
                    if (ok && mounted) setState(() => _unlocked = true);
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Gunakan biometrik'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _verify() {
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings == null || !settings.pinEnabled) return;
    final valid = ref.read(pinServiceProvider).verify(
          pin: _controller.text,
          salt: settings.pinSalt!,
          expectedHash: settings.pinHash!,
        );
    setState(() {
      if (valid) {
        _unlocked = true;
        _error = '';
      } else {
        _error = 'PIN salah';
        _controller.clear();
      }
    });
  }
}
