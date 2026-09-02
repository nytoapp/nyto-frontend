import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyto_app/core/api/api_client.dart';
import 'package:nyto_app/core/auth/auth_failure.dart';
import 'package:nyto_app/core/auth/auth_repository.dart';
import 'package:nyto_app/core/auth/auth_user.dart';
import 'package:nyto_app/features/onboarding/onboarding_data.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_controller.dart';
import 'package:nyto_app/features/onboarding/widgets/auth/auth_flow_state.dart';

const _user = AuthUser(
  id: 'user_1',
  authProvider: 'phone',
  phone: '+919876543210',
  firstName: 'Asha',
);

/// Counts calls and lets each test decide what the backend does.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(ApiClient());

  int requestCount = 0;
  int verifyCount = 0;
  int googleExchangeCount = 0;
  int facebookExchangeCount = 0;

  Duration requestDelay = Duration.zero;
  Duration verifyDelay = Duration.zero;
  Object? requestError;
  Object? verifyError;
  Object? exchangeError;
  Duration resendAfter = const Duration(seconds: 30);

  @override
  Future<OtpChallengeInfo> requestPhoneCode(String e164) async {
    requestCount++;
    if (requestDelay > Duration.zero) await Future.delayed(requestDelay);
    final error = requestError;
    if (error != null) throw error;
    return OtpChallengeInfo(
      destination: e164,
      maskedDestination: '+9198•••••210',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      resendAfter: resendAfter,
    );
  }

  @override
  Future<AuthUser> verifyPhoneCode({
    required String e164,
    required String code,
  }) async {
    verifyCount++;
    if (verifyDelay > Duration.zero) await Future.delayed(verifyDelay);
    final error = verifyError;
    if (error != null) throw error;
    return _user;
  }

  @override
  Future<AuthUser> signInWithGoogle(String idToken) async {
    googleExchangeCount++;
    final error = exchangeError;
    if (error != null) throw error;
    return _user;
  }

  @override
  Future<AuthUser> signInWithFacebook(String accessToken) async {
    facebookExchangeCount++;
    final error = exchangeError;
    if (error != null) throw error;
    return _user;
  }
}

void main() {
  late FakeAuthRepository repo;
  final india = OnboardingOptions.countries.firstWhere((c) => c.code == 'IN');

  /// Builds a controller with every external dependency stubbed.
  AuthController build({
    Future<String> Function({bool switchAccount})? google,
    Future<String> Function()? facebook,
    Future<String?> Function()? sms,
    Future<String?> Function()? hint,
  }) {
    return AuthController(
      repository: repo,
      initialCountry: india,
      googleCredential: google ?? ({bool switchAccount = false}) async => 'id',
      facebookCredential: facebook ?? () async => 'tok',
      appleCredential: () async => 'apple',
      awaitSmsCode: sms ?? () async => null,
      cancelSmsListener: () async {},
      phoneNumberHint: hint ?? () async => null,
    );
  }

  setUp(() => repo = FakeAuthRepository());

  group('phone input', () {
    test('send is disabled until the number is valid', () {
      final auth = build();
      auth.setPhone('987654321');
      expect(auth.canSubmitPhone, isFalse);

      auth.setPhone('9876543210');
      expect(auth.canSubmitPhone, isTrue);

      addTearDown(auth.dispose);
    });

    test('an 11th digit cannot be entered', () {
      final auth = build();
      auth.setPhone('98765432109');
      expect(auth.phoneRaw, '9876543210');
      addTearDown(auth.dispose);
    });

    test('letters and symbols are stripped', () {
      final auth = build();
      auth.setPhone('98a76*54 32-10');
      expect(auth.phoneRaw, '9876543210');
      addTearDown(auth.dispose);
    });

    test('an OS-suggested number fills the field and country', () async {
      final auth = build(hint: () async => '+14155550123');
      await auth.requestPhoneNumberHint();

      expect(auth.country.code, 'US');
      expect(auth.phoneRaw, '4155550123');
      addTearDown(auth.dispose);
    });

    test('keeps India when digits are valid locally despite a +44 tag', () async {
      final auth = build(hint: () async => '+446302008513');
      await auth.requestPhoneNumberHint();

      expect(auth.country.code, 'IN');
      expect(auth.phoneRaw, '6302008513');
      addTearDown(auth.dispose);
    });

    test('a typed number is never overwritten by a suggestion', () async {
      final auth = build(hint: () async => '+14155550123');
      auth.setPhone('9876543210');
      await auth.requestPhoneNumberHint();

      expect(auth.country.code, 'IN');
      expect(auth.phoneRaw, '9876543210');
      addTearDown(auth.dispose);
    });
  });

  group('send code', () {
    test('a valid number moves to OTP entry', () async {
      final auth = build();
      auth.setPhone('9876543210');

      await auth.sendCode();

      expect(repo.requestCount, 1);
      expect(auth.state.stage, AuthStage.otpVerify);
      expect(auth.state.busy, AuthBusy.none);
      expect(auth.state.maskedDestination, '+9198•••••210');
      addTearDown(auth.dispose);
    });

    test('five taps send one SMS', () async {
      repo.requestDelay = const Duration(milliseconds: 40);
      final auth = build();
      auth.setPhone('9876543210');

      await Future.wait([
        auth.sendCode(),
        auth.sendCode(),
        auth.sendCode(),
        auth.sendCode(),
        auth.sendCode(),
      ]);

      expect(repo.requestCount, 1);
      addTearDown(auth.dispose);
    });

    test('an invalid number is refused even if the intent is called', () async {
      final auth = build();
      auth.setPhone('12345');

      await auth.sendCode();

      expect(repo.requestCount, 0);
      expect(auth.state.stage, AuthStage.choice);
      addTearDown(auth.dispose);
    });

    test(
      'a network failure stays on phone input with a retryable message',
      () async {
        repo.requestError = AuthFailure.offline;
        final auth = build();
        auth.setPhone('9876543210');

        await auth.sendCode();

        expect(auth.state.stage, AuthStage.choice);
        expect(auth.state.busy, AuthBusy.none);
        expect(auth.state.error, contains('internet'));
        addTearDown(auth.dispose);
      },
    );
  });

  group('verify code', () {
    Future<AuthController> atOtp() async {
      final auth = build();
      auth.setPhone('9876543210');
      await auth.sendCode();
      return auth;
    }

    test('a complete code auto-submits', () async {
      final auth = await atOtp();

      auth.setCode('123456');
      await Future<void>.delayed(Duration.zero);

      expect(repo.verifyCount, 1);
      expect(auth.user, isNotNull);
      addTearDown(auth.dispose);
    });

    test('a partial code does not submit', () async {
      final auth = await atOtp();

      auth.setCode('12345');
      await Future<void>.delayed(Duration.zero);

      expect(repo.verifyCount, 0);
      addTearDown(auth.dispose);
    });

    test('auto-submit and a manual tap verify once', () async {
      repo.verifyDelay = const Duration(milliseconds: 40);
      final auth = await atOtp();

      auth.setCode('123456');
      await Future.wait([auth.verifyCode(), auth.verifyCode()]);

      expect(repo.verifyCount, 1);
      addTearDown(auth.dispose);
    });

    test('a wrong code shows an error and clears the field', () async {
      repo.verifyError = const AuthFailure(
        AuthFailureKind.invalidCode,
        'That code is not right.',
      );
      final auth = await atOtp();

      auth.setCode('000000');
      await Future<void>.delayed(Duration.zero);

      expect(auth.state.error, 'That code is not right.');
      expect(auth.code, isEmpty);
      expect(auth.state.stage, AuthStage.otpVerify);
      addTearDown(auth.dispose);
    });

    test('an expired code surfaces the server message', () async {
      repo.verifyError = const AuthFailure(
        AuthFailureKind.expiredCode,
        'That code expired. Request a new one.',
      );
      final auth = await atOtp();

      auth.setCode('123456');
      await Future<void>.delayed(Duration.zero);

      expect(auth.state.error, contains('expired'));
      addTearDown(auth.dispose);
    });

    test('an SMS-retrieved code is verified without user action', () async {
      final auth = build(sms: () async => '654321');
      auth.setPhone('9876543210');

      await auth.sendCode();
      await Future<void>.delayed(Duration.zero);

      expect(repo.verifyCount, 1);
      addTearDown(auth.dispose);
    });
  });

  group('resend', () {
    test('is blocked during the cooldown', () async {
      final auth = build();
      auth.setPhone('9876543210');
      await auth.sendCode();

      expect(auth.state.canResend, isFalse);
      expect(auth.state.resendCountdown.inSeconds, greaterThan(25));

      await auth.resendCode();
      expect(repo.requestCount, 1);
      addTearDown(auth.dispose);
    });

    test('is allowed once the cooldown elapses', () async {
      repo.resendAfter = Duration.zero;
      final auth = build();
      auth.setPhone('9876543210');
      await auth.sendCode();

      expect(auth.state.canResend, isTrue);
      await auth.resendCode();

      expect(repo.requestCount, 2);
      addTearDown(auth.dispose);
    });

    test('a failed resend does not restart the cooldown', () async {
      repo.resendAfter = Duration.zero;
      final auth = build();
      auth.setPhone('9876543210');
      await auth.sendCode();

      repo.requestError = AuthFailure.offline;
      await auth.resendCode();

      expect(auth.state.error, isNotNull);
      expect(auth.state.canResend, isTrue);
      addTearDown(auth.dispose);
    });
  });

  group('navigation', () {
    test('OTP goes back to the choice screen with the phone field', () async {
      final auth = build();
      auth.setPhone('9876543210');
      await auth.sendCode();
      expect(auth.state.stage, AuthStage.otpVerify);

      final handled = auth.goBack();

      expect(handled, isTrue);
      expect(auth.state.stage, AuthStage.choice);
      expect(auth.code, isEmpty);
      expect(auth.phoneRaw, '9876543210');
      addTearDown(auth.dispose);
    });

    test('the choice panel defers back to the screen', () {
      final auth = build();
      expect(auth.goBack(), isFalse);
      addTearDown(auth.dispose);
    });
  });

  group('social providers', () {
    test('no loader is shown while the provider sheet is open', () async {
      final gate = Completer<String>();
      final auth = build(google: ({bool switchAccount = false}) => gate.future);

      final pending = auth.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      // The provider owns the screen: locked, but nothing spinning.
      expect(auth.state.handoffProvider, AuthProviderKind.google);
      expect(auth.state.showsLoader, isFalse);
      expect(auth.state.canInteract, isFalse);

      gate.complete('id-token');
      await pending;

      expect(auth.state.stage, AuthStage.confirm);
      expect(auth.state.showsLoader, isFalse);
      addTearDown(auth.dispose);
    });

    test('a loader appears once the backend is being called', () async {
      final auth = build();

      // Observed between the credential arriving and the exchange resolving.
      AuthFlowState? duringExchange;
      auth.addListener(() {
        if (auth.state.busy == AuthBusy.exchangingCredential) {
          duringExchange = auth.state;
        }
      });

      await auth.signInWithGoogle();

      expect(duringExchange, isNotNull);
      expect(duringExchange!.showsLoader, isTrue);
      expect(duringExchange!.exchangingProvider, AuthProviderKind.google);
      expect(duringExchange!.handoffProvider, isNull);
      expect(repo.googleExchangeCount, 1);
      addTearDown(auth.dispose);
    });

    test('cancelling returns cleanly with no error and no lock', () async {
      final auth = build(
        google: ({bool switchAccount = false}) async =>
            throw AuthFailure.cancelled,
      );

      await auth.signInWithGoogle();

      expect(auth.state.stage, AuthStage.choice);
      expect(auth.state.error, isNull);
      expect(auth.state.canInteract, isTrue);
      expect(auth.state.handoffProvider, isNull);
      addTearDown(auth.dispose);
    });

    test('five taps run one flow', () async {
      var launches = 0;
      final gate = Completer<String>();
      final auth = build(
        google: ({bool switchAccount = false}) {
          launches++;
          return gate.future;
        },
      );

      final flows = [
        auth.signInWithGoogle(),
        auth.signInWithGoogle(),
        auth.signInWithGoogle(),
        auth.signInWithGoogle(),
        auth.signInWithGoogle(),
      ];
      gate.complete('id');
      await Future.wait(flows);

      expect(launches, 1);
      expect(repo.googleExchangeCount, 1);
      addTearDown(auth.dispose);
    });

    test('a provider failure returns cleanly with a message', () async {
      final auth = build(
        google: ({bool switchAccount = false}) async => throw const AuthFailure(
          AuthFailureKind.providerRejected,
          'Google Sign-In failed. Try again.',
        ),
      );

      await auth.signInWithGoogle();

      expect(auth.state.error, 'Google Sign-In failed. Try again.');
      expect(auth.state.canInteract, isTrue);
      addTearDown(auth.dispose);
    });

    test('a backend failure after provider success unlocks the UI', () async {
      repo.exchangeError = AuthFailure.offline;
      final auth = build();

      await auth.signInWithGoogle();

      expect(auth.state.stage, AuthStage.choice);
      expect(auth.state.error, contains('internet'));
      expect(auth.state.canInteract, isTrue);
      expect(auth.state.exchangingProvider, isNull);
      addTearDown(auth.dispose);
    });

    test('phone and Google cannot run at the same time', () async {
      final gate = Completer<String>();
      final auth = build(google: ({bool switchAccount = false}) => gate.future);

      final pending = auth.signInWithGoogle();
      await auth.sendCode();

      expect(repo.requestCount, 0);
      expect(auth.state.stage, AuthStage.choice);

      gate.complete('id');
      await pending;
      addTearDown(auth.dispose);
    });

    test('Facebook signs in through the same session path', () async {
      final auth = build();

      await auth.signInWithFacebook();

      expect(repo.facebookExchangeCount, 1);
      expect(auth.state.stage, AuthStage.confirm);
      expect(auth.state.confirmProvider, 'Facebook');
      addTearDown(auth.dispose);
    });

    test('a result arriving after reset is discarded', () async {
      final gate = Completer<String>();
      final auth = build(google: ({bool switchAccount = false}) => gate.future);

      final pending = auth.signInWithGoogle();
      auth.resetToChoice();
      gate.complete('late-token');
      await pending;

      // The superseded attempt must not authenticate or navigate.
      expect(repo.googleExchangeCount, 0);
      expect(auth.state.stage, AuthStage.choice);
      expect(auth.user, isNull);
      addTearDown(auth.dispose);
    });
  });
}
