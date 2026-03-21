import 'package:flutter/material.dart';

import '../core/utils/l10n_ext.dart';
import '../models/cat_model.dart';

class CatSelector extends StatelessWidget {
  const CatSelector({
    super.key,
    required this.cats,
    required this.onSelected,
    this.selectedCatId,
    this.label,
  });

  final List<CatModel> cats;
  final String? selectedCatId;
  final ValueChanged<CatModel?> onSelected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    const noneValue = '';
    final labelText = label ?? context.l10n.selectCatLabel;
    final effectiveId = selectedCatId?.isNotEmpty == true ? selectedCatId! : noneValue;
    return DropdownButtonFormField<String>(
      key: ValueKey<String>(effectiveId),
      initialValue: effectiveId,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(value: noneValue, child: Text(context.l10n.noneOption)),
        ...cats.map((c) => DropdownMenuItem(value: c.catId, child: Text(c.name))),
      ],
      onChanged: (id) {
        if (id == null || id == noneValue) {
          onSelected(null);
          return;
        }
        final list = cats.where((c) => c.catId == id).toList();
        onSelected(list.isEmpty ? null : list.first);
      },
    );
  }
}

class CatSelectorDialog extends StatelessWidget {
  const CatSelectorDialog({
    super.key,
    required this.cats,
    required this.onSelected,
    this.selectedCatId,
  });

  final List<CatModel> cats;
  final String? selectedCatId;
  final ValueChanged<CatModel?> onSelected;

  static Future<CatModel?> show(BuildContext context, List<CatModel> cats, {String? selectedCatId}) async {
    return showModalBottomSheet<CatModel?>(
      context: context,
      builder: (context) => CatSelectorDialog(
        cats: cats,
        selectedCatId: selectedCatId,
        onSelected: (c) => Navigator.of(context).pop(c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(context.l10n.selectCatLabel, style: Theme.of(context).textTheme.titleMedium),
          ),
          ...cats.map((c) => ListTile(
                title: Text(c.name),
                selected: c.catId == selectedCatId,
                onTap: () => onSelected(c),
              )),
          if (cats.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(context.l10n.noCatsYetShort)),

        ],
      ),
    );
  }
}
