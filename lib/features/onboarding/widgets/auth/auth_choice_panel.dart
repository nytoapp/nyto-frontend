import 'package:flutter/material.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_header.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_primary_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_social_button.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_tokens.dart';

class AuthChoicePanel extends StatelessWidget {
  const AuthChoicePanel({
    super.key,
    required this.isIos,
    required this.state,
    required this.onPhone,
    required this.onInstagram,
    required this.onGoogle,
    required this.onApple,
  });

  final bool isIos;
  final AuthFlowState state;
  final VoidCallback onPhone;
  final VoidCallback onInstagram;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final canInteract = state.canInteract;
    final secondary = isIos ? AuthProviderKind.apple : AuthProviderKind.google;

    // Column lives inside OnboardingScaffold's Expanded — bounded height.
    // Do NOT use Spacer inside SingleChildScrollView (unbounded height → layout crash).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        const AuthEditorialHeader(
          eyebrow: 'Almost there',
          title: 'Create your seat',
          subtitle: 'One tap in. Phone, Instagram, or your usual sign-in.',
        ),
        const Spacer(),
        AuthPrimaryButton(
          label: 'Continue with phone',
          icon: Icons.phone_rounded,
          semanticsLabel: 'Continue with phone',
          enabled: canInteract,
          onPressed: canInteract ? onPhone : null,
        ),
        const SizedBox(height: AuthTokens.space24),
        const AuthDivider(),
        const SizedBox(height: AuthTokens.space16),
        Row(
          children: [
            Expanded(
              child: AuthSocialButton(
                variant: AuthSocialVariant.instagram,
                loading: state.busy == AuthBusy.instagram,
                enabled: canInteract,
                onPressed: canInteract ? onInstagram : null,
              ),
            ),
            const SizedBox(width: AuthTokens.space12),
            Expanded(
              child: AuthSocialButton(
                variant: socialVariant(secondary),
                loading: state.busy == busyForProvider(secondary),
                enabled: canInteract,
                onPressed: canInteract ? (isIos ? onApple : onGoogle) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AuthTokens.space24),
        const AuthLegalFooter(),
        if (state.error != null) ...[
          const SizedBox(height: AuthTokens.space16),
          AuthErrorBanner(message: state.error!),
        ],
        const SizedBox(height: AuthTokens.space8),
      ],
    );
  }
}
