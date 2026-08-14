import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:duitku/core/providers/providers.dart';
import 'package:duitku/core/services/pin_service.dart';
import 'package:duitku/widgets/section_card.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.settings;
    final notifier = ref.read(settingsProvider.notifier);
    final pinService = ref.read(pinServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Keamanan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.pinEnabled,
                  title: const Text('Kunci dengan PIN'),
                  subtitle: Text(
                    'PIN ${PinService.pinLength} digit, disimpan sebagai hash.',
                  ),
                  onChanged: (value) async {
                    if (!value) {
                      await notifier.mutate((s) => s.copyWith(
                            pinHash: null,
                            pinSalt: null,
                            biometricEnabled: false,
                          ));
                      return;
                    }
                    final pin = await _askPin(context, 'Buat PIN baru');
                    if (pin == null) return;
                    if (!context.mounted) return;
                    final confirm = await _askPin(context, 'Ulangi PIN');
                    if (confirm == null) return;
                    if (pin != confirm) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN tidak sama.')),
                      );
                      return;
                    }
                    final salt = pinService.generateSalt();
                    await notifier.mutate((s) => s.copyWith(
                          pinSalt: salt,
                          pinHash: pinService.hashPin(pin, salt),
                        ));
                  },
                ),
                if (settings.pinEnabled)
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Ubah PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final current = await _askPin(context, 'PIN saat ini');
                      if (current == null) return;
                      final valid = pinService.verify(
                        pin: current,
                        salt: settings.pinSalt!,
                        expectedHash: settings.pinHash!,
                      );
                      if (!valid) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN salah.')),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      final next = await _askPin(context, 'PIN baru');
                      if (next == null) return;
                      final salt = pinService.generateSalt();
                      await notifier.mutate((s) => s.copyWith(
                            pinSalt: salt,
                            pinHash: pinService.hashPin(next, salt),
                          ));
                    },
                  ),
                SwitchListTile(
                  value: settings.biometricEnabled,
                  title: const Text('Buka dengan biometrik'),
                  subtitle: const Text('Sidik jari atau face unlock.'),
                  onChanged: !settings.pinEnabled
                      ? null
                      : (value) async {
                          if (value) {
                            final available = await ref
                                .read(biometricServiceProvider)
                                .isAvailable();
                            if (!available) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Perangkat tidak mendukung biometrik.'),
                                ),
                              );
                              return;
                            }
                          }
                          await notifier.mutate(
                              (s) => s.copyWith(biometricEnabled: value));
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'DUITKU tidak pernah menyimpan PIN asli. Yang tersimpan hanya '
            'hash SHA-256 dengan salt acak.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

Future<String?> _askPin(BuildContext context, String title) async {
  final controller = TextEditingController();
  final pin = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: PinService.pinLength,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(labelText: 'PIN'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.length != PinService.pinLength) return;
            Navigator.of(dialogContext).pop(controller.text);
          },
          child: const Text('Lanjut'),
        ),
      ],
    ),
  );
  controller.dispose();
  return pin;
}
