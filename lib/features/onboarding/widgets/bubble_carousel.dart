import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/features/onboarding/models/bubble_carousel_item.dart';

/// Horizontal bubble field — PageView + continuous center scaling (stable on device).
class BubbleCarousel extends StatefulWidget {
  const BubbleCarousel({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onToggleSelection,
    this.pageController,
    this.onFocusedIndexChanged,
    this.initialIndex = 0,
    this.height = 220,
  });

  final List<BubbleCarouselItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final PageController? pageController;
  final ValueChanged<int>? onFocusedIndexChanged;
  final int initialIndex;
  final double height;

  @override
  State<BubbleCarousel> createState() => _BubbleCarouselState();
}

class _BubbleCarouselState extends State<BubbleCarousel> {
  static const _baseSize = 74.0;
  static const _viewportFraction = 0.36;

  late final PageController _pageController;
  late final bool _ownsPageController;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _focusedIndex =
          widget.initialIndex.clamp(0, widget.items.length - 1);
    }
    _ownsPageController = widget.pageController == null;
    _pageController = widget.pageController ??
        PageController(
          viewportFraction: _viewportFraction,
          initialPage: _focusedIndex,
        );
    _pageController.addListener(_onPageMoved);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageMoved);
    if (_ownsPageController) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _onPageMoved() {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return;
    }
    final page = _pageController.page;
    if (page == null) return;
    final next = page.round().clamp(0, widget.items.length - 1);
    if (next != _focusedIndex) {
      _focusedIndex = next;
      widget.onFocusedIndexChanged?.call(next);
    }
  }

  double _currentPage() {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return _focusedIndex.toDouble();
    }
    return _pageController.page ?? _focusedIndex.toDouble();
  }

  int _nearestPageIndex(double page) {
    return page.round().clamp(0, widget.items.length - 1);
  }

  void _onBubbleTap(int index) {
    final page = _currentPage();
    final nearest = _nearestPageIndex(page);

    // Nearest bubble = select immediately (even while scroll is still settling).
    if (index == nearest) {
      HapticFeedback.lightImpact();
      widget.onToggleSelection(widget.items[index].id);
      return;
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: reduceMotion ? 0 : 380),
      curve: Curves.easeOutQuart,
    );
  }

  /// Smoothstep — continuous scale without discrete jumps.
  static double _smoothstep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double scaleForDistance(double distance) {
    final d = distance.clamp(0.0, 2.5);
    if (d <= 1.0) {
      final focus = _smoothstep(1.0 - d);
      return 0.82 + focus * (2.05 - 0.82);
    }
    final far = ((d - 1.0) / 1.5).clamp(0.0, 1.0);
    final focus = _smoothstep(1.0 - far);
    return 0.52 + focus * (0.82 - 0.52);
  }

  static double opacityForDistance(double distance) {
    final d = distance.clamp(0.0, 2.5);
    final focus = _smoothstep(1.0 - (d / 2.5));
    return (0.26 + focus * 0.74).clamp(0.26, 1.0);
  }

  static double focusForDistance(double distance) {
    return _smoothstep(1.0 - distance.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        clipBehavior: Clip.none,
        physics: const PageScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        onPageChanged: (index) {
          _focusedIndex = index;
          widget.onFocusedIndexChanged?.call(index);
        },
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final selected = widget.selectedIds.contains(item.id);

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              final distance = (_currentPage() - index).abs();
              final scale = scaleForDistance(distance);
              final opacity = opacityForDistance(distance);
              final focus = focusForDistance(distance);

              return GestureDetector(
                onTap: () => _onBubbleTap(index),
                behavior: HitTestBehavior.translucent,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, distance * 4.5),
                    child: Transform.scale(
                      scale: scale,
                      filterQuality: FilterQuality.medium,
                      child: Opacity(
                        opacity: opacity,
                        child: SizedBox(
                          width: _baseSize,
                          height: _baseSize,
                          child: RepaintBoundary(
                            child: _BubbleOrb(
                              item: item,
                              selected: selected,
                              focus: focus,
                              iconScale: scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BubbleOrb extends StatelessWidget {
  const _BubbleOrb({
    required this.item,
    required this.selected,
    required this.focus,
    required this.iconScale,
  });

  final BubbleCarouselItem item;
  final bool selected;
  final double focus;
  final double iconScale;

  Color _lerpGradientColor(int index) {
    return Color.lerp(
          BubbleCarouselTokens.unfocusedGradient[index],
          BubbleCarouselTokens.focusedGradient[index],
          focus,
        ) ??
        BubbleCarouselTokens.unfocusedGradient[index];
  }

  @override
  Widget build(BuildContext context) {
    final semanticsSelected = selected ? 'Selected.' : 'Not selected.';
    final borderAlpha = selected
        ? 0.95
        : (0.1 + focus * 0.12);
    final iconAlpha = 0.72 + focus * 0.23;
    final shadowAlpha = focus * (0.22 + focus * 0.18);

    return Semantics(
      label: '${item.title}. ${item.description} $semanticsSelected',
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _lerpGradientColor(0),
              _lerpGradientColor(1),
            ],
          ),
          boxShadow: [
            if (focus > 0.04)
              BoxShadow(
                color: NytoColors.cta.withValues(alpha: shadowAlpha),
                blurRadius: 8 + focus * 12,
                spreadRadius: focus * 0.45,
                offset: Offset(0, 2 + focus * 2.5),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32 + (1 - focus) * 0.1),
              blurRadius: 6 + focus * 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: borderAlpha),
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NytoColors.ctaSoft.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            Icon(
              item.icon,
              color: Colors.white.withValues(alpha: iconAlpha),
              size: 24 * iconScale.clamp(0.75, 1.05),
            ),
            if (selected)
              Positioned(
                right: 5,
                top: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: NytoColors.ctaDeep,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Short affordance line — swipe + tap (kept minimal).
class BubbleCarouselHint extends StatelessWidget {
  const BubbleCarouselHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Swipe to explore · Tap to select',
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        height: 1.35,
        letterSpacing: 0.15,
        color: NytoColors.cream.withValues(alpha: 0.36),
      ),
    );
  }
}

/// Title + description crossfaded to scroll position (same signal as bubbles).
class BubbleFocusCopySynced extends StatelessWidget {
  const BubbleFocusCopySynced({
    super.key,
    required this.items,
    required this.pageController,
    this.height = 96,
  });

  final List<BubbleCarouselItem> items;
  final PageController pageController;
  final double height;

  static double _smoothstep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  double _readPage() {
    if (!pageController.hasClients ||
        !pageController.position.haveDimensions) {
      return pageController.initialPage.toDouble();
    }
    return pageController.page ?? pageController.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: pageController,
        builder: (context, _) {
          if (items.isEmpty) {
            return const SizedBox.shrink();
          }

          if (reduceMotion) {
            final idx = _readPage().round().clamp(0, items.length - 1);
            return Align(
              alignment: Alignment.topCenter,
              child: _BubbleCopyBlock(item: items[idx], opacity: 1),
            );
          }

          final page = _readPage();
          final base = page.floor().clamp(0, items.length - 1);
          final next = (base + 1).clamp(0, items.length - 1);
          final blend = _smoothstep(page - base);

          if (base == next || blend <= 0.001) {
            return Align(
              alignment: Alignment.topCenter,
              child: _BubbleCopyBlock(item: items[base], opacity: 1),
            );
          }

          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              _BubbleCopyBlock(item: items[base], opacity: 1 - blend),
              _BubbleCopyBlock(item: items[next], opacity: blend),
            ],
          );
        },
      ),
    );
  }
}

class _BubbleCopyBlock extends StatelessWidget {
  const _BubbleCopyBlock({
    required this.item,
    required this.opacity,
  });

  final BubbleCarouselItem item;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.2,
                letterSpacing: -0.3,
                color: NytoColors.cream,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                height: 1.45,
                color: NytoColors.cream.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
