import 'package:flutter/material.dart';

class TopicChipsRow extends StatelessWidget {
  const TopicChipsRow({
    super.key,
    required this.selectedTopic,
    required this.topicIds,
    required this.allLabel,
    required this.labelBuilder,
    required this.onSelect,
  });

  final String? selectedTopic;
  final List<String> topicIds;
  final String allLabel;
  final String Function(String id) labelBuilder;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip(context, null, allLabel),
          const SizedBox(width: 8),
          ...topicIds.expand((id) => [_chip(context, id, labelBuilder(id)), const SizedBox(width: 8)]),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String? topicId, String text) {
    final selected = selectedTopic == topicId;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onSelect(topicId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? scheme.primaryContainer.withValues(alpha: 0.95) : scheme.surfaceContainerLow,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
