import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/platform/app_platform.dart';
import '../../../app/session/app_session_controller.dart';
import '../../../app/session/app_session_scope.dart';
import '../../../shared/widgets/auth_scene_frame.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppSessionController session) async {
    session.dismissError();
    await session.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.watch(context);
    final isBusy = session.phase == AppSessionPhase.signingIn;
    final isCupertino = currentAppPlatform == AppPlatform.cupertino;

    return AuthSceneFrame(
      eyebrow: 'Sign In',
      title: isCupertino ? 'Sign in to Jellyfin' : 'Authenticate with Jellyfin',
      description: isCupertino
          ? 'Enter your username and password to continue.'
          : 'Your server URL is verified. Sign in with your Jellyfin account to persist the session and continue into the app.',
      errorMessage: session.errorMessage,
      secondaryChildren: isCupertino
          ? const []
          : [
              SupportPanel(
                title: session.displayServerName,
                body:
                    'Connected server: ${session.serverUrl ?? 'Not set'}\n\nIf you need a different address, go back and change the server URL first.',
              ),
            ],
      child: switch (currentAppPlatform) {
        AppPlatform.cupertino => _CupertinoLoginForm(
            usernameController: _usernameController,
            passwordController: _passwordController,
            isBusy: isBusy,
            onBack: session.changeServer,
            onSubmit: () => _submit(session),
          ),
        _ => _MaterialLoginForm(
            usernameController: _usernameController,
            passwordController: _passwordController,
            isBusy: isBusy,
            onBack: session.changeServer,
            onSubmit: () => _submit(session),
          ),
      },
    );
  }
}

class _MaterialLoginForm extends StatelessWidget {
  const _MaterialLoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.isBusy,
    required this.onBack,
    required this.onSubmit,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isBusy;
  final Future<void> Function() onBack;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          onSubmitted: (_) {
            if (!isBusy) {
              onSubmit();
            }
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            TextButton(
              onPressed: isBusy ? null : onBack,
              child: const Text('Change Server'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: isBusy ? null : onSubmit,
              child: Text(isBusy ? 'Signing In…' : 'Sign In'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CupertinoLoginForm extends StatelessWidget {
  const _CupertinoLoginForm({
    required this.usernameController,
    required this.passwordController,
    required this.isBusy,
    required this.onBack,
    required this.onSubmit,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isBusy;
  final Future<void> Function() onBack;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          controller: usernameController,
          placeholder: 'Username',
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF222225),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5A5A60)),
          ),
        ),
        const SizedBox(height: 14),
        CupertinoTextField(
          controller: passwordController,
          placeholder: 'Password',
          obscureText: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF222225),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5A5A60)),
          ),
          onSubmitted: (_) {
            if (!isBusy) {
              onSubmit();
            }
          },
        ),
        const SizedBox(height: 14),
        CupertinoButton(
          onPressed: isBusy ? null : onBack,
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
          child: const Text('Change Server'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(12),
            onPressed: isBusy ? null : onSubmit,
            child: Text(isBusy ? 'Signing In…' : 'Continue'),
          ),
        ),
      ],
    );
  }
}
