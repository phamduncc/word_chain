import 'package:flutter/material.dart';

import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.initialSettings,
    required this.onChanged,
  });

  final AppSettings initialSettings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  AppCopy get _copy => AppCopy.of(_settings.language);

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _update(AppSettings settings) {
    setState(() {
      _settings = settings;
    });
    widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    final AppCopy copy = _copy;

    return Scaffold(
      appBar: AppBar(title: Text(copy.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SectionLabel(text: copy.answerTime),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.timer_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          copy.seconds(_settings.answerSeconds),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: 5,
                    max: 30,
                    divisions: 25,
                    label: copy.seconds(_settings.answerSeconds),
                    value: _settings.answerSeconds.toDouble(),
                    onChanged: (double value) {
                      _update(_settings.copyWith(answerSeconds: value.round()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionLabel(text: copy.languageLabel),
            DropdownButtonFormField<AppLanguage>(
              initialValue: _settings.language,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.language_rounded),
                labelText: copy.languageLabel,
              ),
              items: <DropdownMenuItem<AppLanguage>>[
                DropdownMenuItem<AppLanguage>(
                  value: AppLanguage.vietnamese,
                  child: Text(copy.vietnamese),
                ),
                DropdownMenuItem<AppLanguage>(
                  value: AppLanguage.english,
                  child: Text(copy.english),
                ),
              ],
              onChanged: (AppLanguage? language) {
                if (language != null) {
                  _update(_settings.copyWith(language: language));
                }
              },
            ),
            const SizedBox(height: 18),
            _SectionLabel(text: copy.appTheme),
            SegmentedButton<AppThemePreference>(
              segments: <ButtonSegment<AppThemePreference>>[
                ButtonSegment<AppThemePreference>(
                  value: AppThemePreference.system,
                  icon: const Icon(Icons.devices_rounded),
                  label: Text(copy.systemTheme),
                ),
                ButtonSegment<AppThemePreference>(
                  value: AppThemePreference.light,
                  icon: const Icon(Icons.light_mode_rounded),
                  label: Text(copy.lightTheme),
                ),
                ButtonSegment<AppThemePreference>(
                  value: AppThemePreference.dark,
                  icon: const Icon(Icons.dark_mode_rounded),
                  label: Text(copy.darkTheme),
                ),
              ],
              selected: <AppThemePreference>{_settings.themePreference},
              onSelectionChanged: (Set<AppThemePreference> selected) {
                _update(_settings.copyWith(themePreference: selected.first));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
