import 'package:flutter/material.dart';

import 'feed_mode_switcher.dart';
import 'feed_search_field.dart';
import 'topic_chips_row.dart';

class FeedControlBar extends StatelessWidget {
  const FeedControlBar({
    super.key,
    required this.searchController,
    required this.searchHintText,
    required this.onSearchChanged,
    required this.latestSelected,
    required this.latestLabel,
    required this.hotLabel,
    required this.onSelectLatest,
    required this.onSelectHot,
    required this.selectedTopic,
    required this.topicIds,
    required this.allTopicsLabel,
    required this.topicLabelBuilder,
    required this.onTopicSelect,
  });

  final TextEditingController searchController;
  final String searchHintText;
  final ValueChanged<String> onSearchChanged;
  final bool latestSelected;
  final String latestLabel;
  final String hotLabel;
  final VoidCallback onSelectLatest;
  final VoidCallback onSelectHot;
  final String? selectedTopic;
  final List<String> topicIds;
  final String allTopicsLabel;
  final String Function(String id) topicLabelBuilder;
  final ValueChanged<String?> onTopicSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        children: [
          FeedSearchField(
            controller: searchController,
            hintText: searchHintText,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FeedModeSwitcher(
                latestSelected: latestSelected,
                latestLabel: latestLabel,
                hotLabel: hotLabel,
                onSelectLatest: onSelectLatest,
                onSelectHot: onSelectHot,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TopicChipsRow(
                  selectedTopic: selectedTopic,
                  topicIds: topicIds,
                  allLabel: allTopicsLabel,
                  labelBuilder: topicLabelBuilder,
                  onSelect: onTopicSelect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
