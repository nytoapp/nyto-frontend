import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  int _tab = 0; // 0 event, 1 news

  bool _eventPush = false;
  bool _eventEmail = true;
  bool _eventSms = true;
  bool _lastPush = false;
  bool _lastEmail = false;
  bool _lastSms = false;
  bool _newsEmail = true;

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Notifications',
      footer: SettingsPrimaryButton(
        label: 'Save',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences saved (UI only).'),
              backgroundColor: NytoColors.surface,
            ),
          );
          Navigator.pop(context);
        },
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        children: [
          Row(
            children: [
              _TabChip(
                label: 'Event updates',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 10),
              _TabChip(
                label: 'News & offers',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_tab == 0) ...[
            NytoGlass.panel(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: NytoColors.ctaSoft.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Push is off on this device.',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: NytoColors.cream,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enable in system settings to get table alerts.',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: NytoColors.cream.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: NytoColors.cream.withValues(alpha: 0.08),
                              border: Border.all(
                                color: NytoColors.cream.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              'Enable notifications',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: NytoColors.cream,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              title: 'Important event updates',
              body:
                  'Venue, group, and RSVP reminders for your booked nights.',
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              children: [
                _ToggleRow(
                  label: 'Push notifications',
                  value: _eventPush,
                  enabled: false,
                  onChanged: (v) => setState(() => _eventPush = v),
                ),
                _ToggleRow(
                  label: 'Email',
                  value: _eventEmail,
                  onChanged: (v) => setState(() => _eventEmail = v),
                ),
                _ToggleRow(
                  label: 'SMS',
                  value: _eventSms,
                  onChanged: (v) => setState(() => _eventSms = v),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              title: 'Last-minute seats',
              body: 'When a spot opens up close to dinner time.',
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              children: [
                _ToggleRow(
                  label: 'Push notifications',
                  value: _lastPush,
                  enabled: false,
                  onChanged: (v) => setState(() => _lastPush = v),
                ),
                _ToggleRow(
                  label: 'Email',
                  value: _lastEmail,
                  onChanged: (v) => setState(() => _lastEmail = v),
                ),
                _ToggleRow(
                  label: 'SMS',
                  value: _lastSms,
                  onChanged: (v) => setState(() => _lastSms = v),
                ),
              ],
            ),
          ] else ...[
            _SectionTitle(
              title: 'Exclusive updates',
              body:
                  'NYTO openings, city launches, and occasional offers — never spam.',
            ),
            const SizedBox(height: 10),
            _ToggleCard(
              children: [
                _ToggleRow(
                  label: 'Email',
                  value: _newsEmail,
                  onChanged: (v) => setState(() => _newsEmail = v),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected
              ? NytoColors.cta.withValues(alpha: 0.22)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? NytoColors.ctaSoft.withValues(alpha: 0.65)
                : NytoColors.cream.withValues(alpha: 0.14),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? NytoColors.cream
                : NytoColors.cream.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: NytoColors.cream,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            height: 1.4,
            color: NytoColors.cream.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return NytoGlass.panel(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: NytoColors.cream.withValues(alpha: 0.07),
              ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: NytoColors.cream,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.white,
              activeTrackColor: NytoColors.cta,
              inactiveThumbColor: NytoColors.cream.withValues(alpha: 0.7),
              inactiveTrackColor: NytoColors.cream.withValues(alpha: 0.12),
            ),
          ],
        ),
      ),
    );
  }
}
