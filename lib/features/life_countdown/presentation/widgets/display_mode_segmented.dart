import 'package:flutter/material.dart';
import 'package:polaris/features/life_countdown/application/display_mode.dart';

/// Segmented toggle for switching countdown display modes.
///
/// A thin adapter over Material 3's [SegmentedButton] so feature widgets
/// don't repeat the same `ButtonSegment` boilerplate.
class DisplayModeSegmented extends StatelessWidget {
  const DisplayModeSegmented({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DisplayMode selected;
  final ValueChanged<DisplayMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DisplayMode>(
      style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
      segments: <ButtonSegment<DisplayMode>>[
        for (final DisplayMode m in DisplayMode.values)
          ButtonSegment<DisplayMode>(value: m, label: Text(m.label)),
      ],
      selected: <DisplayMode>{selected},
      showSelectedIcon: false,
      onSelectionChanged: (Set<DisplayMode> set) => onChanged(set.first),
    );
  }
}
