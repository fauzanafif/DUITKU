import 'package:flutter/material.dart';

import 'package:duitku/core/constants/app_defaults.dart';

class IconPickerRow extends StatelessWidget {
  const IconPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppDefaults.iconChoices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final icon = AppDefaults.iconChoices[index];
          final isSelected = icon.codePoint == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onChanged(icon.codePoint),
            child: Container(
              width: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary.withValues(alpha: 0.15)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  width: 1.6,
                ),
              ),
              child: Icon(icon,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant),
            ),
          );
        },
      ),
    );
  }
}

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AppDefaults.palette.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = AppDefaults.palette[index];
          final value = color.toARGB32();
          final isSelected = value == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onChanged(value),
            child: Container(
              width: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
