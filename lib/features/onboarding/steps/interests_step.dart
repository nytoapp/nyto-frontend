import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

class InterestsStep extends StatefulWidget {
  const InterestsStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<({String id, String label})> get _visibleOptions {
    final q = _search.text.trim().toLowerCase();
    final all = [
      ...OnboardingOptions.interests,
      ...widget.data.customInterestLabels.entries
          .map((e) => (id: e.key, label: e.value)),
    ];
    if (q.isEmpty) return all;
    return all
        .where((item) => item.label.toLowerCase().contains(q))
        .toList();
  }

  void _toggle(String id) {
    setState(() {
      if (widget.data.interests.contains(id)) {
        widget.data.interests.remove(id);
      } else if (widget.data.interests.length < OnboardingData.maxInterests) {
        widget.data.interests.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final can = widget.data.interests.isNotEmpty;
    final visible = _visibleOptions;

    return OnboardingScaffold(
      step: 9,
      totalSteps: OnboardingData.totalSteps,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: can,
        onPressed: can ? widget.onContinue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTitle(
            'What are you into?',
            subtitle:
                'Pick up to five. Deeper matching comes when you book a table.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.dmSans(color: NytoColors.cream, fontSize: 15),
            cursorColor: NytoColors.brandPink,
            decoration: InputDecoration(
              hintText: 'Search interests…',
              hintStyle: GoogleFonts.dmSans(
                color: NytoColors.cream.withValues(alpha: 0.4),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: NytoColors.cream.withValues(alpha: 0.45),
              ),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(
                      onPressed: () => setState(() => _search.clear()),
                      icon: Icon(
                        Icons.close_rounded,
                        color: NytoColors.cream.withValues(alpha: 0.4),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: NytoColors.cream.withValues(alpha: 0.05),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: NytoColors.cream.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: NytoColors.brandPink, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: visible.map((item) {
                  final selected = widget.data.interests.contains(item.id);
                  final locked =
                      !selected &&
                      widget.data.interests.length >=
                          OnboardingData.maxInterests;
                  return _InterestChip(
                    label: item.label,
                    selected: selected,
                    locked: locked,
                    onTap: locked ? null : () => _toggle(item.id),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: locked ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: NytoGlass.panel(
            selected: selected,
            borderRadius: 999,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : NytoColors.cream.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
