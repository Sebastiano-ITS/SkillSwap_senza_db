// lib/widgets/editable_skill_list.dart
import 'package:flutter/material.dart';
import '../theme/brand_palette.dart';

/// Lista di chip modificabili, ottimizzata contro overflow.
/// - Chip con larghezza massima e testo in ellissi.
/// - In modalità modifica mostra la X per rimuovere.
/// - Pulsante "Aggiungi" in giallo (BrandPalette.amber).
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // max larghezza per singolo chip per evitare overflows con testi lunghi
        final double maxChipWidth = _clamp(
          constraints.maxWidth * 0.6,
          140,
          320,
        );

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in items)
              _SkillChip(
                label: s,
                isEditing: isEditing,
                maxWidth: maxChipWidth,
                onRemove: () => onRemove(s),
              ),

            // Pulsante Aggiungi in giallo/amber (più visibile)
            _AddButton(
              label: addLabel,
              onPressed: onAdd,
            ),
          ],
        );
      },
    );
  }

  double _clamp(double v, double min, double max) =>
      v < min ? min : (v > max ? max : v);
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({
    required this.label,
    required this.isEditing,
    required this.maxWidth,
    required this.onRemove,
  });

  final String label;
  final bool isEditing;
  final double maxWidth;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final chip = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BrandPalette.purple.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: BrandPalette.purple, width: 1.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // testo ellissato per prevenire overflow
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BrandPalette.purple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child:
                  Icon(Icons.close, size: 16, color: BrandPalette.purple),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // In modalità modifica il chip è tappabile per rimuovere
    return isEditing
        ? Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    )
        : chip;
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18, color: Colors.black87),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: BrandPalette.amber, // 🟡 giallo brand
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
