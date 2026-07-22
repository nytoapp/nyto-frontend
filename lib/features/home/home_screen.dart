import 'package:flutter/material.dart';
import 'package:nyto_app/core/theme/app_theme.dart';

/// Placeholder home until auth + booking flows are built feature-by-feature.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NYTO', style: textTheme.displayLarge),
              const SizedBox(height: 12),
              Text(
                'Book a seat. Meet five strangers. Nothing left to figure out.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Text(
                'Coming next',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              const _Step(label: '1', title: 'Sign up (phone OTP / Google)'),
              const _Step(label: '2', title: 'ID + liveness verification'),
              const _Step(label: '3', title: 'Compatibility profile'),
              const _Step(label: '4', title: 'Book a table & pay'),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Auth flow next — we build one feature at a time.'),
                    ),
                  );
                },
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.title});

  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.moss.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.moss,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
