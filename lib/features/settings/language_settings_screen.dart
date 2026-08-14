import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key, required this.selected});

  final String selected;

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late String _selected;

  static const _langs = <({String name, String flags})>[
    (name: 'English', flags: '🇺🇸 🇬🇧'),
    (name: 'हिन्दी', flags: '🇮🇳'),
    (name: 'తెలుగు', flags: '🇮🇳'),
    (name: 'தமிழ்', flags: '🇮🇳'),
    (name: 'Español', flags: '🇪🇸'),
    (name: 'Français', flags: '🇫🇷'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'App language',
      footer: SettingsPrimaryButton(
        label: 'Confirm',
        onPressed: () => Navigator.pop(context, _selected),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        children: [
          Text(
            'How should\nNYTO speak?',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 20),
          NytoGlass.panel(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < _langs.length; i++) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selected = _langs[i].name),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _langs[i].name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: NytoColors.cream,
                                ),
                              ),
                            ),
                            Text(
                              _langs[i].flags,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            _Dot(selected: _selected == _langs[i].name),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i < _langs.length - 1)
                    Divider(
                      height: 1,
                      indent: 18,
                      endIndent: 18,
                      color: NytoColors.cream.withValues(alpha: 0.07),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? NytoColors.ctaSoft
              : NytoColors.cream.withValues(alpha: 0.28),
          width: 1.6,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 11 : 0,
          height: selected ? 11 : 0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: NytoColors.cta,
          ),
        ),
      ),
    );
  }
}
