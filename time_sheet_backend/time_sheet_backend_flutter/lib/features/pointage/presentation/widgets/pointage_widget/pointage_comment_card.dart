import 'package:flutter/material.dart';

import 'pointage_design_system.dart';

/// Carte de saisie du commentaire libre de la journée.
///
/// Ce texte alimente la colonne « Commentaires » du relevé de temps PDF, à la
/// suite du motif d'absence éventuel. Il sert à justifier un horaire
/// inhabituel — déplacement, intervention, retard — que les seules heures ne
/// racontent pas.
///
/// Enregistrement à la perte du focus plutôt qu'à chaque frappe : une écriture
/// PowerSync par caractère saturerait la file de synchronisation pour rien. Le
/// bouton « Enregistrer » n'apparaît que lorsque le texte diffère de la valeur
/// enregistrée, ce qui rend l'état visible sans imposer un geste.
class PointageCommentCard extends StatefulWidget {
  /// Commentaire déjà enregistré pour la journée affichée.
  final String? comment;

  /// Appelé avec le texte à conserver. Une chaîne vide efface le commentaire.
  final ValueChanged<String> onCommentSaved;

  /// Désactive la saisie tant qu'aucune journée n'existe en base : sans entrée
  /// courante, il n'y a pas de ligne à commenter.
  final bool enabled;

  const PointageCommentCard({
    super.key,
    required this.comment,
    required this.onCommentSaved,
    this.enabled = true,
  });

  @override
  State<PointageCommentCard> createState() => _PointageCommentCardState();
}

class _PointageCommentCardState extends State<PointageCommentCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late String _savedValue;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _savedValue = widget.comment ?? '';
    _controller = TextEditingController(text: _savedValue);
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(PointageCommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // La journée affichée a changé (navigation depuis le calendrier), ou la
    // valeur enregistrée est revenue par la synchronisation. On ne réécrit pas
    // le champ pendant que l'utilisateur tape : sa saisie prime.
    final incoming = widget.comment ?? '';
    if (incoming != _savedValue && !_focusNode.hasFocus) {
      _savedValue = incoming;
      _controller.text = incoming;
      _isDirty = false;
    }
  }

  void _onTextChange() {
    final dirty = _controller.text != _savedValue;
    if (dirty != _isDirty) setState(() => _isDirty = dirty);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isDirty) _save();
  }

  void _save() {
    final value = _controller.text.trim();
    widget.onCommentSaved(value);
    setState(() {
      _savedValue = value;
      _controller.text = value;
      _isDirty = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: PointageSpacing.md, vertical: PointageSpacing.sm),
      decoration: BoxDecoration(
        color: PointageColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note,
                  color: PointageColors.primary, size: 20),
              const SizedBox(width: PointageSpacing.sm),
              Expanded(
                child: Text(
                  'Commentaire de la journée',
                  style: PointageTextStyles.cardLabel.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PointageColors.primary,
                  ),
                ),
              ),
              if (_isDirty)
                TextButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            minLines: 2,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
                fontSize: 14, color: PointageColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.enabled
                  ? 'Déplacement client, intervention, retard…'
                  : 'Commencez la journée pour ajouter un commentaire',
              hintStyle: const TextStyle(
                  fontSize: 13, color: PointageColors.textSecondary),
              filled: true,
              fillColor: PointageColors.background,
              contentPadding: const EdgeInsets.all(PointageSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: PointageSpacing.xs),
          Text(
            'Ce texte apparaît dans la colonne « Commentaires » du relevé PDF.',
            style: PointageTextStyles.cardLabel.copyWith(
              fontSize: 11,
              color: PointageColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
