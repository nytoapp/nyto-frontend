import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/app/session.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/kyc/kyc_session.dart';
import 'package:nyto_app/core/prefs/city_prefs.dart';
import 'package:nyto_app/core/profile/profile_name.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/auth/welcome_screen.dart';
import 'package:nyto_app/features/profile/my_bookings_screen.dart';
import 'package:nyto_app/features/settings/area_settings_screen.dart';
import 'package:nyto_app/features/settings/help_center_screen.dart';
import 'package:nyto_app/features/settings/language_settings_screen.dart';
import 'package:nyto_app/features/settings/login_security_screen.dart';
import 'package:nyto_app/features/settings/notification_preferences_screen.dart';
import 'package:nyto_app/features/settings/rate_app_sheet.dart';
import 'package:nyto_app/features/settings/settings_chrome.dart';
import 'package:nyto_app/features/verification/verify_identity_hub_screen.dart';

/// Profile — stats + account / preferences / resources.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onCityChanged});

  /// Called with the selected area id when location changes.
  final ValueChanged<String>? onCityChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _streakGoal = 3;

  String _area = LocationPrefs.allAreas;
  String _language = 'English';
  String _displayName = '';
  String _initial = '';
  bool _nameMissing = true;
  late final TextEditingController _nameController;
  final FocusNode _nameFocus = FocusNode();
  int _attended = 0;
  int _streak = 0;
  String _verifyStatus = 'Not verified';
  bool _loggingOut = false;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadLocation();
    _loadMe();
    _loadVerifyStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _applyName(String? raw) {
    final name = ProfileName.real(raw);
    if (name == null) {
      _nameMissing = true;
      _displayName = '';
      _initial = '';
      if (_nameController.text.isEmpty) _nameController.text = '';
      return;
    }
    _nameMissing = false;
    _displayName = name;
    _initial = name[0].toUpperCase();
    _nameController.text = name;
  }

  Future<void> _loadLocation() async {
    final area = await LocationPrefs.loadArea();
    if (!mounted) return;
    setState(() => _area = area);
  }

  Future<void> _loadVerifyStatus() async {
    final label = await KycSession.statusLabel();
    if (!mounted) return;
    setState(() => _verifyStatus = label);
  }

  int _readCount(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  Future<void> _loadMe() async {
    final local = await ProfileName.loadLocal();
    if (mounted && local != null) {
      setState(() => _applyName(local));
    }
    try {
      final json = await authApi.me();
      final user = json['user'];
      if (user is! Map || !mounted) return;
      final first = (user['firstName'] as String?)?.trim();
      final full = (user['fullName'] as String?)?.trim();
      final stored = ProfileName.real(first) ?? ProfileName.real(full) ?? local;
      setState(() {
        _applyName(stored);
        _attended = _readCount(user['attendanceCount']);
        _streak = _readCount(user['currentStreak']);
      });
      if (ProfileName.real(first) == null && stored != null) {
        try {
          await ProfileName.save(stored);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _saveTypedName() async {
    if (_savingName) return;
    final next = _nameController.text.trim();
    if (next.length < 2) return;
    setState(() => _savingName = true);
    try {
      final saved = await ProfileName.save(next);
      if (!mounted) return;
      setState(() => _applyName(saved));
      _nameFocus.unfocus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your name. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _logOut() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await NytoSession.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'NYTO',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: NytoColors.cta,
                      letterSpacing: 3.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Profile',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: NytoColors.subtext,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: NytoColors.cta,
                      shape: BoxShape.circle,
                    ),
                    child: _initial.isEmpty
                        ? const Icon(
                            Icons.person_outline,
                            color: NytoColors.cream,
                            size: 32,
                          )
                        : Text(
                            _initial,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 32,
                              color: NytoColors.cream,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_nameMissing)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  autofocus: true,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  maxLength: 40,
                                  onSubmitted: (_) => _saveTypedName(),
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w400,
                                    color: NytoColors.cream,
                                  ),
                                  cursorColor: NytoColors.cta,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    counterText: '',
                                    hintText: 'First name',
                                    hintStyle: GoogleFonts.dmSerifDisplay(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w400,
                                      color: NytoColors.creamMuted,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _savingName ? null : _saveTypedName,
                                child: Text(
                                  _savingName ? 'Saving' : 'Save',
                                  style: GoogleFonts.dmSans(
                                    color: NytoColors.cta,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            _displayName,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              color: NytoColors.cream,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          LocationPrefs.profileSubtitle(_area),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NytoGlass.panel(
                borderRadius: 16,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 14,
                          color: NytoColors.creamMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TABLES ATTENDED',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$_attended',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 48,
                            fontWeight: FontWeight.w400,
                            color: NytoColors.cream,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'shared dinners attended',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: NytoColors.creamMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NytoGlass.panel(
                borderRadius: 16,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: NytoColors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Streak',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: NytoColors.cream,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_streak.clamp(0, _streakGoal)} / $_streakGoal to unlock next discount',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: NytoColors.creamMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _streak.clamp(0, _streakGoal) / _streakGoal,
                        minHeight: 6,
                        backgroundColor:
                            NytoColors.cream.withValues(alpha: 0.1),
                        color: NytoColors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['1', '2', '3']
                          .map(
                            (n) => Text(
                              n,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: NytoColors.creamMuted,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              NytoGlass.panel(
                borderRadius: 16,
                padding: EdgeInsets.zero,
                child: SettingsNavRow(
                  icon: Icons.event_seat_outlined,
                  label: 'My Bookings',
                  subtitle: 'Upcoming nights & entry codes',
                  onTap: () => openSettingsPage(
                    context,
                    const MyBookingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const SettingsSectionLabel('Account'),
              SettingsGlassGroup(
                children: [
                  SettingsNavRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Verify identity',
                    subtitle: _verifyStatus,
                    onTap: () async {
                      await openSettingsPage(
                        context,
                        const VerifyIdentityHubScreen(),
                      );
                      if (mounted) await _loadVerifyStatus();
                    },
                  ),
                  SettingsNavRow(
                    icon: Icons.shield_outlined,
                    label: 'Login & Security',
                    subtitle: 'Google or email code · no password',
                    onTap: () => openSettingsPage(
                      context,
                      const LoginSecurityScreen(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SettingsSectionLabel('Preferences'),
              SettingsGlassGroup(
                children: [
                  SettingsNavRow(
                    icon: Icons.public_rounded,
                    label: 'Location',
                    subtitle: LocationPrefs.profileSubtitle(_area),
                    onTap: () async {
                      final next = await openSettingsPage<String>(
                        context,
                        AreaSettingsScreen(selectedArea: _area),
                      );
                      if (next != null && mounted) {
                        await LocationPrefs.saveArea(next);
                        if (!mounted) return;
                        setState(() => _area = next);
                        widget.onCityChanged?.call(next);
                      }
                    },
                  ),
                  SettingsNavRow(
                    icon: Icons.translate_rounded,
                    label: 'App language',
                    subtitle: _language,
                    onTap: () async {
                      final next = await openSettingsPage<String>(
                        context,
                        LanguageSettingsScreen(selected: _language),
                      );
                      if (next != null && mounted) {
                        setState(() => _language = next);
                      }
                    },
                  ),
                  SettingsNavRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification preferences',
                    subtitle: 'Push, email, SMS',
                    onTap: () => openSettingsPage(
                      context,
                      const NotificationPreferencesScreen(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const SettingsSectionLabel('Resources'),
              SettingsGlassGroup(
                children: [
                  SettingsNavRow(
                    icon: Icons.help_outline_rounded,
                    label: 'Help Center',
                    onTap: () => openSettingsPage(
                      context,
                      const HelpCenterScreen(),
                    ),
                  ),
                  SettingsNavRow(
                    icon: Icons.menu_book_outlined,
                    label: 'NYTO guide',
                    subtitle: 'How nights at the table work',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('NYTO guide — content coming soon.'),
                          backgroundColor: NytoColors.surface,
                        ),
                      );
                    },
                  ),
                  SettingsNavRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Follow NYTO',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Social links — coming soon.'),
                          backgroundColor: NytoColors.surface,
                        ),
                      );
                    },
                  ),
                  SettingsNavRow(
                    icon: Icons.star_outline_rounded,
                    label: 'Rate the app',
                    iconColor: NytoColors.orange,
                    onTap: () => showRateAppSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              NytoGlass.panel(
                borderRadius: 999,
                padding: EdgeInsets.zero,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _loggingOut ? null : _logOut,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Log out',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: NytoColors.cream,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Text(
                      'NYTO',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                        color: NytoColors.ctaSoft.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Version 0.1.0',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: NytoColors.cream.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: [
                        _LegalLink('Terms'),
                        _LegalLink('Privacy'),
                        _LegalLink('Community'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: NytoColors.cream.withValues(alpha: 0.45),
        decoration: TextDecoration.underline,
        decorationColor: NytoColors.cream.withValues(alpha: 0.25),
      ),
    );
  }
}
