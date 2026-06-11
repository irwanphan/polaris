import 'package:flutter/material.dart';
import 'package:polaris/shared/widgets/coming_soon_view.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

class LifeCountdownPage extends StatelessWidget {
  const LifeCountdownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PolarisScaffold(
      appBar: AppBar(title: const Text('Sisa Hariku')),
      body: const ComingSoonView(
        title: 'Sisa Hariku di Dunia',
        milestone: 'M1',
        description:
            'Onboarding (tanggal lahir, jenis kelamin, negara) lalu '
            'tampilan hitung mundur hari, minggu, bulan, dan persentase '
            'hidup. Estimasi memakai tabel WHO + BPS.',
      ),
    );
  }
}
