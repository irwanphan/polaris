import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:polaris/app/router.dart';
import 'package:polaris/app/theme/color_tokens.dart';
import 'package:polaris/core/l10n/enum_labels.dart';
import 'package:polaris/features/life_countdown/application/life_profile_controller.dart';
import 'package:polaris/features/life_countdown/application/providers.dart';
import 'package:polaris/features/life_countdown/domain/repositories/life_expectancy_repository.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/country_code.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/date_of_birth.dart';
import 'package:polaris/features/life_countdown/domain/value_objects/sex.dart';
import 'package:polaris/features/life_countdown/presentation/widgets/disclaimer_note.dart';
import 'package:polaris/l10n/generated/app_localizations.dart';
import 'package:polaris/shared/widgets/polaris_scaffold.dart';

final FutureProvider<List<CountryOption>> _countriesProvider =
    FutureProvider<List<CountryOption>>((ref) async {
      final repo = ref.watch(lifeExpectancyRepositoryProvider);
      final result = await repo.listSupportedCountries();
      return result.fold(
        onOk: (List<CountryOption> options) => options,
        onErr: (failure) => throw StateError(failure.message),
      );
    });

/// First-run form that captures the inputs needed to compute the life
/// countdown. Validation happens on submit; per-field errors surface
/// inline.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  DateTime? _birthDate;
  Sex _sex = Sex.undisclosed;
  CountryCode _country = CountryCode.indonesia;
  String? _birthDateError;
  bool _submitting = false;

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _birthDate ?? DateTime(now.year - 25, 1, 1);
    final DateTime first = DateTime(now.year - DateOfBirth.maxPlausibleYears);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now,
      helpText: AppL.of(context).onboardingBirthDate,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateError = null;
      });
    }
  }

  Future<void> _submit() async {
    final AppL l = AppL.of(context);
    final DateTime? birth = _birthDate;
    if (birth == null) {
      setState(() => _birthDateError = l.onboardingBirthDate);
      return;
    }
    final dobResult = DateOfBirth.tryFromDateTime(birth);
    if (dobResult.isErr) {
      setState(() => _birthDateError = dobResult.failureOrNull!.message);
      return;
    }

    setState(() => _submitting = true);
    await ref
        .read(lifeProfileControllerProvider.notifier)
        .completeOnboarding(
          dateOfBirth: dobResult.valueOrNull!,
          sex: _sex,
          countryCode: _country,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    final AsyncValue<dynamic> state = ref.read(lifeProfileControllerProvider);
    state.when(
      data: (_) => context.go(AppRoutes.life),
      loading: () {},
      error: (Object e, _) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.eventsSaveFailed(e.toString())))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppL l = AppL.of(context);
    final AsyncValue<List<CountryOption>> countries = ref.watch(
      _countriesProvider,
    );

    return PolarisScaffold(
      appBar: AppBar(title: Text(l.onboardingWelcome)),
      body: ListView(
        children: <Widget>[
          Text(l.onboardingSetup, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Spacing.x2),
          Text(l.onboardingDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: Spacing.x6),
          _FieldLabel(label: l.onboardingBirthDate),
          const SizedBox(height: Spacing.x2),
          InkWell(
            onTap: _pickBirthDate,
            borderRadius: BorderRadius.circular(Radii.lg),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.cake_outlined),
                hintText: l.onboardingBirthDate,
                errorText: _birthDateError,
              ),
              child: Text(
                _birthDate == null
                    ? ' '
                    : DateFormat.yMMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(_birthDate!),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: Spacing.x6),
          _FieldLabel(label: l.onboardingSex),
          const SizedBox(height: Spacing.x2),
          SegmentedButton<Sex>(
            segments: <ButtonSegment<Sex>>[
              ButtonSegment(
                value: Sex.female,
                label: Text(sexLabel(context, Sex.female)),
              ),
              ButtonSegment(
                value: Sex.male,
                label: Text(sexLabel(context, Sex.male)),
              ),
              ButtonSegment(
                value: Sex.undisclosed,
                label: Text(sexLabel(context, Sex.undisclosed)),
              ),
            ],
            selected: <Sex>{_sex},
            showSelectedIcon: false,
            onSelectionChanged: (set) => setState(() => _sex = set.first),
          ),
          const SizedBox(height: Spacing.x6),
          _FieldLabel(label: l.onboardingCountry),
          const SizedBox(height: Spacing.x2),
          countries.when(
            data: (List<CountryOption> options) {
              return DropdownButtonFormField<CountryCode>(
                initialValue: _country,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.public_outlined),
                ),
                items: <DropdownMenuItem<CountryCode>>[
                  for (final CountryOption o in options)
                    DropdownMenuItem<CountryCode>(
                      value: o.code,
                      child: Text(o.displayName),
                    ),
                ],
                onChanged: (CountryCode? code) {
                  if (code != null) setState(() => _country = code);
                },
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (Object e, _) => Text(l.lifestyleLoadFailed(e.toString())),
          ),
          const SizedBox(height: Spacing.x8),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_submitting ? l.commonSaving : l.onboardingStart),
          ),
          const SizedBox(height: Spacing.x6),
          const DisclaimerNote(),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(label, style: theme.textTheme.labelLarge);
  }
}
