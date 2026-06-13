import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/features/lifestyle/application/lifestyle_controller.dart';
import 'package:polaris/features/lifestyle/domain/value_objects/log_category.dart';
import 'package:polaris/features/lifestyle/presentation/widgets/category_icons.dart';

/// Modal bottom sheet for adding one [LifestyleLog] entry.
///
/// Pre-selects [initialCategory] when provided (typical when the
/// user taps a specific category card). Otherwise defaults to the
/// first category. The numeric field auto-clamps to the category's
/// valid range and respects [LogCategory.isInteger].
class QuickLogSheet extends ConsumerStatefulWidget {
  const QuickLogSheet({this.initialCategory, super.key});

  final LogCategory? initialCategory;

  static Future<bool?> show(
    BuildContext context, {
    LogCategory? initialCategory,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => QuickLogSheet(initialCategory: initialCategory),
    );
  }

  @override
  ConsumerState<QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<QuickLogSheet> {
  late LogCategory _category;
  late TextEditingController _valueCtrl;
  final TextEditingController _noteCtrl = TextEditingController();
  String? _valueError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? LogCategory.values.first;
    _valueCtrl = TextEditingController(text: _category.defaultStep.toString());
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(LogCategory c) {
    setState(() {
      _category = c;
      _valueError = null;
      _valueCtrl.text = c.defaultStep.toString();
    });
  }

  Future<void> _submit() async {
    final double? parsed = double.tryParse(_valueCtrl.text.trim());
    if (parsed == null) {
      setState(() => _valueError = 'Enter a number.');
      return;
    }
    if (!_category.isValid(parsed)) {
      setState(
        () => _valueError =
            'Must be ${_formatRange(_category)} ${_category.unit}.',
      );
      return;
    }

    setState(() {
      _valueError = null;
      _submitting = true;
    });

    final result = await ref
        .read(lifestyleControllerProvider)
        .log(category: _category, value: parsed, note: _noteCtrl.text);

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

  static String _formatRange(LogCategory c) {
    String fmt(double v) =>
        c.isInteger ? v.toInt().toString() : v.toStringAsFixed(1);
    return '${fmt(c.minValue)}–${fmt(c.maxValue)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
            Text('Quick log', style: theme.textTheme.titleLarge),
            const SizedBox(height: Spacing.x4),
            Text('Category', style: theme.textTheme.labelLarge),
            const SizedBox(height: Spacing.x2),
            Wrap(
              spacing: Spacing.x2,
              runSpacing: Spacing.x2,
              children: <Widget>[
                for (final LogCategory c in LogCategory.values)
                  ChoiceChip(
                    selected: c == _category,
                    label: Text(c.label),
                    avatar: Icon(iconFor(c), size: 18),
                    onSelected: (bool s) {
                      if (s) _onCategoryChanged(c);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Spacing.x4),
            TextField(
              controller: _valueCtrl,
              autofocus: true,
              keyboardType: _category.isInteger
                  ? TextInputType.number
                  : const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                if (_category.isInteger)
                  FilteringTextInputFormatter.digitsOnly
                else
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Value',
                helperText: '${_formatRange(_category)} ${_category.unit}',
                errorText: _valueError,
                prefixIcon: Icon(iconFor(_category)),
                suffixText: _category.unit,
              ),
            ),
            const SizedBox(height: Spacing.x3),
            TextField(
              controller: _noteCtrl,
              minLines: 1,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
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
