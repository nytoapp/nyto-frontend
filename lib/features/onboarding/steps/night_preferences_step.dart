import 'package:flutter/material.dart';
import 'package:nyto_app/features/onboarding/models/bubble_carousel_item.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/bubble_carousel.dart';
import 'package:nyto_app/features/onboarding/widgets/onboarding_chrome.dart';

/// Step 2 — spatial bubble picker for night / experience preferences.
class NightPreferencesStep extends StatefulWidget {
  const NightPreferencesStep({
    super.key,
    required this.data,
    required this.onContinue,
  });

  final OnboardingData data;
  final VoidCallback onContinue;

  @override
  State<NightPreferencesStep> createState() => _NightPreferencesStepState();
}

class _NightPreferencesStepState extends State<NightPreferencesStep> {
  static const _carouselViewportFraction = 0.36;

  late final PageController _pageController;
  late final List<BubbleCarouselItem> _items;

  @override
  void initState() {
    super.initState();
    _items = OnboardingOptions.nightPreferences;
    _pageController = PageController(viewportFraction: _carouselViewportFraction);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (widget.data.nightPreferences.contains(id)) {
        widget.data.nightPreferences.remove(id);
      } else {
        widget.data.nightPreferences.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = widget.data.nightPreferences.isNotEmpty;

    return OnboardingScaffold(
      step: 2,
      totalSteps: OnboardingData.totalSteps,
      footer: NytoPrimaryButton(
        label: 'Continue',
        enabled: canContinue,
        onPressed: canContinue ? widget.onContinue : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingTitle(
            'What sounds like your kind of night?',
            subtitle: 'Pick as many as you like.',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Column(
              children: [
                BubbleCarousel(
                  items: _items,
                  selectedIds: widget.data.nightPreferences,
                  pageController: _pageController,
                  onToggleSelection: _toggle,
                ),
                const SizedBox(height: 10),
                const BubbleCarouselHint(),
                const SizedBox(height: 14),
                BubbleFocusCopySynced(
                  items: _items,
                  pageController: _pageController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
