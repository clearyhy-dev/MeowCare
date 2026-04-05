import 'package:flutter/material.dart';

import '../../core/utils/l10n_ext.dart';

class CommentComposer extends StatelessWidget {
  const CommentComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSubmit,
    this.focusNode,
    this.onTap,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = scheme.outline.withValues(alpha: 0.35);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            onTap: onTap,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: enabled ? context.l10n.comments : context.l10n.signInForFullFeatures,
              isDense: true,
              contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
              border: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: scheme.primary, width: 1.5),
              ),
              disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: enabled ? onSubmit : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 44),
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: const Icon(Icons.send_rounded, size: 20),
        ),
      ],
    );
  }
}
