import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/event_countdown/application/events_controller.dart';
import 'package:polaris/features/event_countdown/domain/entities/event.dart';
import 'package:polaris/features/event_countdown/domain/value_objects/recurrence.dart';

/// Modal bottom sheet for creating or editing an [Event].
///
/// Pass [original] to edit; omit it to create a new event.
class EventEditorSheet extends ConsumerStatefulWidget {
  const EventEditorSheet({this.original, super.key});

  final Event? original;

  static Future<bool?> show(BuildContext context, {Event? original}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => EventEditorSheet(original: original),
    );
  }

  @override
  ConsumerState<EventEditorSheet> createState() => _EventEditorSheetState();
}

class _EventEditorSheetState extends ConsumerState<EventEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _targetAt;
  late Recurrence _recurrence;
  String _colorHex = '#6366F1';
  String? _titleError;
  bool _submitting = false;

  static const List<String> _swatch = <String>[
    '#6366F1', // midnight 500
    '#F59E0B', // starlight 500
    '#10B981', // emerald
    '#F43F5E', // rose
    '#0EA5E9', // sky
    '#A855F7', // purple
  ];

  @override
  void initState() {
    super.initState();
    final Event? o = widget.original;
    _titleCtrl = TextEditingController(text: o?.title ?? '');
    _noteCtrl = TextEditingController(text: o?.note ?? '');
    _targetAt =
        o?.targetAt ??
        DateTime.now()
            .add(const Duration(days: 7))
            .copyWith(
              hour: 9,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );
    _recurrence = o?.recurrence ?? Recurrence.none;
    _colorHex = o?.colorHex ?? _swatch.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final DateTime first = DateTime.now().subtract(const Duration(days: 365));
    final DateTime last = DateTime.now().add(const Duration(days: 365 * 50));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetAt,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return;

    if (!mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_targetAt),
    );
    if (time == null) {
      setState(
        () => _targetAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _targetAt.hour,
          _targetAt.minute,
        ),
      );
      return;
    }
    setState(
      () => _targetAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _submit() async {
    final String title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Title is required.');
      return;
    }
    setState(() {
      _titleError = null;
      _submitting = true;
    });

    final ctrl = ref.read(eventsControllerProvider);
    final original = widget.original;
    final result = original == null
        ? await ctrl.createEvent(
            title: title,
            targetAt: _targetAt,
            colorHex: _colorHex,
            note: _noteCtrl.text,
            recurrence: _recurrence,
          )
        : await ctrl.updateEvent(
            original: original,
            title: title,
            targetAt: _targetAt,
            colorHex: _colorHex,
            iconKey: original.iconKey,
            note: _noteCtrl.text,
            recurrence: _recurrence,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.isOk) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: ${result.failureOrNull}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEdit = widget.original != null;
    final EdgeInsets keyboardInset = EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    );

    return Padding(
      padding: keyboardInset,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.x4,
          Spacing.x2,
          Spacing.x4,
          Spacing.x6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isEdit ? 'Edit event' : 'New event',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: Spacing.x4),
            TextField(
              controller: _titleCtrl,
              autofocus: !isEdit,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _titleError,
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: Spacing.x3),
            InkWell(
              onTap: _pickTargetDate,
              borderRadius: BorderRadius.circular(Radii.lg),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'When',
                  prefixIcon: Icon(Icons.event),
                ),
                child: Text(DateFormat.yMMMMd().add_jm().format(_targetAt)),
              ),
            ),
            const SizedBox(height: Spacing.x3),
            DropdownButtonFormField<Recurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Repeats',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: <DropdownMenuItem<Recurrence>>[
                for (final Recurrence r in Recurrence.values)
                  DropdownMenuItem<Recurrence>(value: r, child: Text(r.label)),
              ],
              onChanged: (Recurrence? r) {
                if (r != null) setState(() => _recurrence = r);
              },
            ),
            const SizedBox(height: Spacing.x3),
            TextField(
              controller: _noteCtrl,
              minLines: 1,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: Spacing.x4),
            Text('Accent color', style: theme.textTheme.labelLarge),
            const SizedBox(height: Spacing.x2),
            Wrap(
              spacing: Spacing.x2,
              children: <Widget>[
                for (final String hex in _swatch)
                  _ColorSwatch(
                    hex: hex,
                    selected: hex == _colorHex,
                    onTap: () => setState(() => _colorHex = hex),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.x6),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Spacing.x3),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_submitting ? 'Saving…' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(
      int.parse('FF${hex.replaceFirst('#', '')}', radix: 16),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(vertical: Spacing.x1),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
    );
  }
}
