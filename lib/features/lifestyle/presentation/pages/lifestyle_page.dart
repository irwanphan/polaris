import 'package:flutter/material.dart';
import 'package:polaris/shared/widgets/coming_soon_view.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

class LifestylePage extends StatelessWidget {
  const LifestylePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PolarisScaffold(
      appBar: AppBar(title: const Text('Lifestyle')),
      body: const ComingSoonView(
        title: 'Lifestyle Logging',
        milestone: 'M4',
        description:
            'Input harian: tidur, olahraga, rokok, alkohol. Optional sinkron '
            'HealthKit / Health Connect.',
      ),
    );
  }
}
