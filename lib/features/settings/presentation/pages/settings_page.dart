import 'package:flutter/material.dart';
import 'package:polaris/shared/widgets/coming_soon_view.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PolarisScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const ComingSoonView(
        title: 'Preferences',
        milestone: 'M0',
        description:
            'Lokal (ID/EN), tema, opsi hide life countdown, kelola izin '
            'notifikasi.',
      ),
    );
  }
}
