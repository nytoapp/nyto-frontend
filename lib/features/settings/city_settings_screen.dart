import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class CitySettingsScreen extends StatefulWidget {
  const CitySettingsScreen({super.key, required this.selectedCity});

  final String selectedCity;

  @override
  State<CitySettingsScreen> createState() => _CitySettingsScreenState();
}

class _CitySettingsScreenState extends State<CitySettingsScreen> {
  late String _selected;
  final _search = TextEditingController();

  static const _cities = <({String name, String flag, String people})>[
    (name: 'Hyderabad', flag: '🇮🇳', people: '2,840 people'),
    (name: 'Bengaluru', flag: '🇮🇳', people: '1,920 people'),
    (name: 'Mumbai', flag: '🇮🇳', people: '3,110 people'),
    (name: 'Delhi', flag: '🇮🇳', people: '2,450 people'),
    (name: 'Chennai', flag: '🇮🇳', people: '980 people'),
    (name: 'Pune', flag: '🇮🇳', people: '1,120 people'),
    (name: 'Goa', flag: '🇮🇳', people: '640 people'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCity;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({String name, String flag, String people})> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _cities;
    return _cities.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'City',
      footer: SettingsPrimaryButton(
        label: 'Confirm',
        onPressed: () {
          Navigator.pop(context, '$_selected, India');
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        children: [
          Text(
            'Meet people\naround your city.',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NYTO nights start where you live.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 15),
            cursorColor: NytoColors.ctaSoft,
            decoration: InputDecoration(
              hintText: 'Your city',
              hintStyle: GoogleFonts.dmSans(
                color: NytoColors.cream.withValues(alpha: 0.35),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: NytoColors.cream.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: NytoColors.cream.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: NytoColors.cream.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide:
                    const BorderSide(color: NytoColors.ctaSoft, width: 1.3),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          NytoGlass.panel(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < _filtered.length; i++) ...[
                  _CityRow(
                    name: _filtered[i].name,
                    flag: _filtered[i].flag,
                    people: _filtered[i].people,
                    selected: _selected == _filtered[i].name,
                    onTap: () => setState(() => _selected = _filtered[i].name),
                  ),
                  if (i < _filtered.length - 1)
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

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.name,
    required this.flag,
    required this.people,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String flag;
  final String people;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name $flag',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: NytoColors.cream,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      people,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              _RadioDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

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
