import 'package:flutter/material.dart';

import '../main.dart';

class AccentColorOption {
  const AccentColorOption({required this.name, required this.color});

  final String name;
  final Color color;
}

const defaultAccentOptions = [
  AccentColorOption(name: 'Pine Green (Default)', color: Color(0xFF365C4C)),
  AccentColorOption(name: 'Ocean Blue', color: Color(0xFF1565C0)),
  AccentColorOption(name: 'Deep Purple', color: Color(0xFF6A1B9A)),
  AccentColorOption(name: 'Amber Warmth', color: Color(0xFFC67D0A)),
  AccentColorOption(name: 'Sunset Coral', color: Color(0xFFDF816B)),
  AccentColorOption(name: 'Midnight Slate', color: Color(0xFF37474F)),
];

class AccentColorPicker extends StatelessWidget {
  const AccentColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WARNA AKSEN APLIKASI',
          style: TextStyle(
            color: muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: defaultAccentOptions.map((opt) {
            final isSelected = opt.color.toARGB32() == selectedColor.toARGB32();
            return InkWell(
              onTap: () => onColorSelected(opt.color),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? opt.color.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? opt.color
                        : muted.withValues(alpha: 0.2),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: opt.color,
                        shape: BoxShape.circle,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      opt.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? opt.color
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : ink),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
