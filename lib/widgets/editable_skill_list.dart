// lib/widgets/editable_skill_list.dart
import 'package:flutter/material.dart';
import '../theme/brand_palette.dart';

/// Lista di chip modificabili.
/// - Tap su una chip → [onRemove] (solo se [isEditing] = true)
/// - Pulsante "Aggiungi" → [onAdd]
class EditableSkillList extends StatelessWidget {
  const EditableSkillList({
    super.key,
    required this.values,
    required this.onAdd,
    required this.onRemove,
    required this.isEditing,
    this.addLabel = 'Aggiungi',
  });

  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool isEditing;
  final String addLabel;

  @override
  Widget build(BuildContext context) {
    final items = [...values]..sort();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final s in items)
          InkWell(
            onTap: isEditing
                ? () => onRemove(s)
                : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attiva "Modifica" per rimuovere una competenza.'),
                ),
              );
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isEditing
                    ? BrandPalette.purple.withOpacity(0.15)
                    : BrandPalette.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: BrandPalette.purple,
                  width: 1.2,
                ),
              ),
              child: Text(
                s,
                style: const TextStyle(
                  color: BrandPalette.purple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Bottone "Aggiungi"
        OutlinedButton.icon(
          onPressed: isEditing
              ? onAdd
              : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attiva "Modifica" per aggiungere una competenza.'),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 18, color: BrandPalette.purple),
          label: Text(
            addLabel,
            style: const TextStyle(color: BrandPalette.purple),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: BrandPalette.purple, width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: BrandPalette.purple,
          ),
        ),
      ],
    );
  }
}
