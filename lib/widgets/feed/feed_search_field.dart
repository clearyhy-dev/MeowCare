import 'package:flutter/material.dart';

class FeedSearchField extends StatelessWidget {
  const FeedSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: scheme.surfaceContainerLow.withValues(alpha: 0.9),
        prefixIcon: Icon(Icons.search_rounded, color: scheme.onSurfaceVariant),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
