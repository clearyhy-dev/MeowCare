import 'package:flutter/material.dart';

import '../core/constants/enums.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/l10n_ext.dart';

class ReminderDialog extends StatefulWidget {
  const ReminderDialog({
    super.key,
    this.initialTime,
    this.initialRepeatType = RepeatType.daily,
    this.initialIntervalDays = 1,
    this.onSave,
  });

  final String? initialTime;
  final RepeatType initialRepeatType;
  final int initialIntervalDays;
  final void Function(String scheduledTime, RepeatType repeatType, int intervalDays)? onSave;

  static Future<void> show(
    BuildContext context, {
    String? initialTime,
    RepeatType initialRepeatType = RepeatType.daily,
    int initialIntervalDays = 1,
    void Function(String scheduledTime, RepeatType repeatType, int intervalDays)? onSave,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (context) => ReminderDialog(
        initialTime: initialTime,
        initialRepeatType: initialRepeatType,
        initialIntervalDays: initialIntervalDays,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late TimeOfDay _time;
  late RepeatType _repeatType;
  late int _intervalDays;

  @override
  void initState() {
    super.initState();
    _time = AppDateUtils.parseHHmm(widget.initialTime) ?? const TimeOfDay(hour: 9, minute: 0);
    _repeatType = widget.initialRepeatType;
    _intervalDays = widget.initialIntervalDays;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.l10n.reminderDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(context.l10n.time),
              trailing: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              onTap: _pickTime,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.repeat, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            DropdownButtonFormField<RepeatType>(
              key: ValueKey(_repeatType),
              initialValue: _repeatType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: RepeatType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _repeatType = v ?? RepeatType.daily),
            ),
            if (_repeatType == RepeatType.custom) ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _intervalDays.toString(),
                decoration: InputDecoration(
                  labelText: context.l10n.everyNDays,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (s) => setState(() => _intervalDays = int.tryParse(s) ?? 1),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.cancel)),
        FilledButton(
          onPressed: () {
            final timeStr = AppDateUtils.timeOfDayToHHmm(_time);
            widget.onSave?.call(timeStr, _repeatType, _intervalDays);
            Navigator.of(context).pop();
          },
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}

