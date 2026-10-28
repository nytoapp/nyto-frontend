import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyto_app/core/api/nyto_api.dart';
import 'package:nyto_app/core/theme/app_theme.dart';
import 'package:nyto_app/core/widgets/nyto_glass.dart';
import 'package:nyto_app/features/settings/open_ticket_sheet.dart';

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
                style: GoogleFonts.dmSerifDisplay(
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
                      onTap: () async {
                        Navigator.pop(ctx);
                        await showOpenTicketSheet(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetBtn(
                      label: 'Yes',
                      filled: true,
                      onTap: () async {
                        Navigator.pop(ctx);
                        try {
                          await supportApi.createTicket(
                            subject: 'Positive app feedback',
                            category: 'FEEDBACK',
                            message:
                                'Guest tapped Yes on rate NYTO — enjoying the product.',
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thanks — glad you’re enjoying NYTO.'),
                              backgroundColor: NytoColors.surface,
                            ),
                          );
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thanks for the love.'),
                              backgroundColor: NytoColors.surface,
                            ),
                          );
                        }
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
    return Material(
      color: filled ? NytoColors.cta : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: filled
                ? null
                : Border.all(
                    color: NytoColors.cream.withValues(alpha: 0.22),
                  ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: filled
                  ? Colors.white
                  : NytoColors.cream.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
