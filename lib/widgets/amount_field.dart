import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:duitku/core/utils/formatters.dart';

/// Text field that formats digits as thousands-separated rupiah while typing.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Nominal',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [_ThousandsFormatter()],
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      validator: (value) {
        final amount = Formatters.parseAmount(value ?? '');
        if (amount <= 0) return 'Nominal harus lebih besar dari nol';
        return null;
      },
    );
  }
}

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = Formatters.thousands(double.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
