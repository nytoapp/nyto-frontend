import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';

Future<void> showRateAppSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: NytoGlass.panel(
          borderRadius: 28,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(
                    Icons.close_rounded,
                    color: NytoColors.cream.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Icon(
                Icons.star_rounded,
                size: 48,
                color: NytoColors.orange.withValues(alpha: 0.95),
              ),
              const SizedBox(height: 12),
              Text(
                'Do you enjoy NYTO?',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  color: NytoColors.cream,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your feedback helps us make better nights at the table.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.4,
                  color: NytoColors.cream.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _SheetBtn(
                      label: 'Not really',
                      filled: false,
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thanks — we’ll keep improving.'),
                            backgroundColor: NytoColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetBtn(
                      label: 'Yes',
                      filled: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Store rating — coming soon.'),
                            backgroundColor: NytoColors.surface,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.paddingOf(ctx).bottom),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: filled
              ? const LinearGradient(
                  colors: [NytoColors.ctaSoft, NytoColors.cta],
                )
              : null,
          color: filled ? null : Colors.transparent,
          border: filled
              ? null
              : Border.all(color: NytoColors.cream.withValues(alpha: 0.22)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: filled
                      ? Colors.white
                      : NytoColors.cream.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
