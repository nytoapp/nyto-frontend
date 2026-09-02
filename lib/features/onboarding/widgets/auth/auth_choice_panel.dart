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
    required this.onFacebook,
    required this.onGoogle,
    required this.onApple,
  });

  final bool isIos;
  final AuthFlowState state;
  final VoidCallback onPhone;
  final VoidCallback onFacebook;
  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    final canInteract = state.canInteract;
    final secondary = isIos ? AuthProviderKind.apple : AuthProviderKind.google;

    // A loader only appears while the app itself is exchanging a credential.
    // During the provider's own sheet the buttons stay visually idle — no
    // stuck loader sitting underneath someone else's UI.
    final exchanging = state.busy == AuthBusy.exchangingCredential
        ? state.exchangingProvider
        : null;

    // Column lives inside OnboardingScaffold's Expanded — bounded height.
    // Do NOT use Spacer inside SingleChildScrollView (unbounded height → layout crash).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        const AuthEditorialHeader(
          eyebrow: 'Almost there',
          title: 'Create your seat',
          subtitle: 'One tap in. Phone, Facebook, or your usual sign-in.',
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
                variant: AuthSocialVariant.facebook,
                loading: exchanging == AuthProviderKind.facebook,
                enabled: canInteract,
                onPressed: canInteract ? onFacebook : null,
              ),
            ),
            const SizedBox(width: AuthTokens.space12),
            Expanded(
              child: AuthSocialButton(
                variant: socialVariant(secondary),
                loading: exchanging == secondary,
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
