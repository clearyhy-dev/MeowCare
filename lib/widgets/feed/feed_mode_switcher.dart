import 'package:flutter/material.dart';

class FeedModeSwitcher extends StatelessWidget {
  const FeedModeSwitcher({
    super.key,
    required this.latestSelected,
    required this.latestLabel,
    required this.hotLabel,
    required this.onSelectLatest,
    required this.onSelectHot,
  });

  final bool latestSelected;
  final String latestLabel;
  final String hotLabel;
  final VoidCallback onSelectLatest;
  final VoidCallback onSelectHot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeButton(
            context: context,
            label: latestLabel,
            selected: latestSelected,
            onTap: onSelectLatest,
          ),
          _modeButton(
            context: context,
            label: hotLabel,
            selected: !latestSelected,
            onTap: onSelectHot,
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
