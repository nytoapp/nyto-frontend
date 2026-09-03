import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/prefs/city_prefs.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

/// Pick a Hyderabad area (or All areas). Returns area id (`ALL` or name).
class AreaSettingsScreen extends StatefulWidget {
  const AreaSettingsScreen({super.key, required this.selectedArea});

  final String selectedArea;

  @override
  State<AreaSettingsScreen> createState() => _AreaSettingsScreenState();
}

class _AreaSettingsScreenState extends State<AreaSettingsScreen> {
  late String _selected;
  final _search = TextEditingController();
  List<({String id, String name})> _areas = const [
    (id: 'ALL', name: 'All areas'),
    (id: 'Madhapur', name: 'Madhapur'),
    (id: 'Hitech City', name: 'Hitech City'),
    (id: 'Gachibowli', name: 'Gachibowli'),
    (id: 'Kondapur', name: 'Kondapur'),
    (id: 'Jubilee Hills', name: 'Jubilee Hills'),
    (id: 'Banjara Hills', name: 'Banjara Hills'),
    (id: 'Film Nagar', name: 'Film Nagar'),
    (id: 'Ameerpet', name: 'Ameerpet'),
  ];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedArea.isEmpty
        ? LocationPrefs.allAreas
        : widget.selectedArea;
    _loadRemote();
  }

  Future<void> _loadRemote() async {
    try {
      final json = await locationsApi.launch();
      final rows = json['areas'];
      if (rows is List) {
        final parsed = <({String id, String name})>[];
        for (final row in rows) {
          if (row is! Map) continue;
          final id = '${row['id'] ?? ''}';
          final name = '${row['name'] ?? id}';
          if (id.isEmpty) continue;
          parsed.add((id: id, name: name));
        }
        if (parsed.isNotEmpty && mounted) {
          setState(() {
            _areas = parsed;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Fall back to local list.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({String id, String name})> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _areas;
    return _areas.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Area',
      footer: SettingsPrimaryButton(
        label: 'Confirm',
        onPressed: () => Navigator.pop(context, _selected),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        children: [
          Text(
            'Where in\nHyderabad?',
            style: GoogleFonts.fraunces(
              fontSize: 26,
              height: 1.15,
              color: NytoColors.cream,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We’ll show tables in your area first, plus nearby neighbourhoods.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: NytoColors.cream.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(color: NytoColors.cream),
            decoration: InputDecoration(
              hintText: 'Search area',
              hintStyle: GoogleFonts.dmSans(
                color: NytoColors.cream.withValues(alpha: 0.35),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
              filled: true,
              fillColor: NytoColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: CircularProgressIndicator(color: NytoColors.cta),
              ),
            )
          else
            for (final a in _filtered) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = a.id),
                    child: NytoGlass.panel(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: NytoColors.cream,
                              ),
                            ),
                          ),
                          Icon(
                            _selected == a.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: _selected == a.id
                                ? NytoColors.ctaSoft
                                : NytoColors.cream.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }
}
