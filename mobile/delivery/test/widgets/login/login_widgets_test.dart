import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:courier/presentation/widgets/login/login_widgets.dart';
import 'package:courier/presentation/widgets/login/login_colors.dart';

void main() {
  group('LoginColors', () {
    test('primary color is correct', () {
      expect(LoginColors.primary, const Color(0xFF0D6644));
    });

    test('all colors are defined', () {
      expect(LoginColors.textDark, isA<Color>());
      expect(LoginColors.textMuted, isA<Color>());
      expect(LoginColors.fieldBorder, isA<Color>());
      expect(LoginColors.fieldBg, isA<Color>());
      expect(LoginColors.labelColor, isA<Color>());
      expect(LoginColors.iconColor, isA<Color>());
      expect(LoginColors.segmentBg, isA<Color>());
    });
  });

  group('LoginFormField', () {
    testWidgets('renders with required parameters', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginFormField(
              controller: controller,
              label: 'EMAIL',
              hint: 'Entrez votre email',
              icon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginFormField(
              controller: controller,
              label: 'EMAIL',
              hint: 'Entrez votre email',
              icon: Icons.email,
              error: 'Email invalide',
            ),
          ),
        ),
      );

      expect(find.text('Email invalide'), findsOneWidget);
    });

    testWidgets('shows password visibility toggle for password fields', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginFormField(
              controller: controller,
              label: 'MOT DE PASSE',
              hint: '••••••••',
              icon: Icons.lock,
              isPassword: true,
              onTogglePassword: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes', (tester) async {
      final controller = TextEditingController();
      String? newValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginFormField(
              controller: controller,
              label: 'EMAIL',
              hint: 'Email',
              icon: Icons.email,
              onChanged: (value) => newValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(newValue, 'test@example.com');
    });
  });

  group('LoginSegmentedControl', () {
    testWidgets('renders both segments', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginSegmentedControl(
              isOtpMode: false,
              onEmailTap: () {},
              onOtpTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Code OTP'), findsOneWidget);
    });

    testWidgets('calls onEmailTap when email tab tapped', (tester) async {
      bool emailTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginSegmentedControl(
              isOtpMode: true,
              onEmailTap: () => emailTapped = true,
              onOtpTap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Email'));
      expect(emailTapped, isTrue);
    });

    testWidgets('calls onOtpTap when OTP tab tapped', (tester) async {
      bool otpTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginSegmentedControl(
              isOtpMode: false,
              onEmailTap: () {},
              onOtpTap: () => otpTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Code OTP'));
      expect(otpTapped, isTrue);
    });

    testWidgets('shows email icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginSegmentedControl(
              isOtpMode: false,
              onEmailTap: () {},
              onOtpTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
    });
  });

  group('LoginCtaButton', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginCtaButton(
              label: 'Se connecter',
              isLoading: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginCtaButton(
              label: 'Se connecter',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Se connecter'), findsNothing);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginCtaButton(
              label: 'Connexion',
              isLoading: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Connexion'));
      expect(pressed, isTrue);
    });

    testWidgets('button is disabled when loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginCtaButton(
              label: 'Connexion',
              isLoading: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isFalse);
    });

    testWidgets('shows arrow icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginCtaButton(
              label: 'Continuer',
              isLoading: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });
  });

  group('LoginBiometricButton', () {
    testWidgets('renders with labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginBiometricButton(
              label: 'Connexion biométrique',
              orLabel: 'ou',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Connexion biométrique'), findsOneWidget);
      expect(find.text('ou'), findsOneWidget);
    });

    testWidgets('shows fingerprint icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginBiometricButton(
              label: 'Biométrie',
              orLabel: 'ou',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginBiometricButton(
              label: 'Biométrie',
              orLabel: 'ou',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Biométrie'));
      expect(pressed, isTrue);
    });

    testWidgets('shows divider with or label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginBiometricButton(
              label: 'Biométrie',
              orLabel: 'OU',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.text('OU'), findsOneWidget);
    });
  });

  group('LoginErrorBanner', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginErrorBanner(message: 'Email ou mot de passe incorrect'),
          ),
        ),
      );

      expect(find.text('Email ou mot de passe incorrect'), findsOneWidget);
    });

    testWidgets('shows error icon for general errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginErrorBanner(message: 'Erreur serveur'),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('shows wifi icon for connection errors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginErrorBanner(message: 'Erreur de connexion réseau'),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('handles "connexion" keyword case-insensitively', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoginErrorBanner(message: 'CONNEXION impossible'),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });
  });
}
