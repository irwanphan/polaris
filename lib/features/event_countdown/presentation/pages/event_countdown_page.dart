import 'package:flutter/material.dart';
import 'package:polaris/shared/widgets/coming_soon_view.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

class EventCountdownPage extends StatelessWidget {
  const EventCountdownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PolarisScaffold(
      appBar: AppBar(title: const Text('Events')),
      body: const ComingSoonView(
        title: 'Event Countdown',
        milestone: 'M2',
        description:
            'CRUD multiple events (ulang tahun, deadline, perjalanan). '
            'Pin favorit ke widget. Reminder T-7d / T-1d / T-1h.',
      ),
    );
  }
}
