import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../app/platform/app_platform.dart';
import '../../../app/session/app_session_controller.dart';
import '../../../app/session/app_session_scope.dart';
import '../../../shared/widgets/auth_scene_frame.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  late final TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    _serverController = TextEditingController();
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _submit(AppSessionController session) async {
    session.dismissError();
    await session.connectToServer(_serverController.text);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.watch(context);
    final suggestedUrl = session.suggestedServerUrl;
    if (session.phase == AppSessionPhase.enterServer &&
        suggestedUrl.isNotEmpty &&
        suggestedUrl != _serverController.text) {
      _serverController.value = TextEditingValue(
        text: suggestedUrl,
        selection: TextSelection.collapsed(offset: suggestedUrl.length),
      );
    }

    final isBusy = session.phase == AppSessionPhase.checkingServer;
    final isCupertino = currentAppPlatform == AppPlatform.cupertino;

    return AuthSceneFrame(
      eyebrow: 'Connect',
      title: isCupertino ? 'Connect to your server' : 'Add your Jellyfin server',
      description: isCupertino
          ? 'Enter your Jellyfin server URL to get started.'
          : 'Start with the server URL. Aetherfin will ping it first, then move to credentials once the server responds successfully.',
      errorMessage: session.errorMessage,
      secondaryChildren: isCupertino
          ? const []
          : const [
              SupportPanel(
                title: 'Server URL examples',
                body:
                    'Use a full local or remote address such as http://192.168.1.20:8096 or https://media.example.com.',
              ),
              SupportPanel(
                title: 'Validation behavior',
                body:
                    'The app checks Jellyfin public system info before allowing the login step, matching the Streamyfin-style flow.',
              ),
            ],
      child: switch (currentAppPlatform) {
        AppPlatform.cupertino => _CupertinoConnectForm(
            controller: _serverController,
            isBusy: isBusy,
            onSubmit: () => _submit(session),
          ),
        _ => _MaterialConnectForm(
            controller: _serverController,
            isBusy: isBusy,
            onSubmit: () => _submit(session),
          ),
      },
    );
  }
}

class _MaterialConnectForm extends StatelessWidget {
  const _MaterialConnectForm({
    required this.controller,
    required this.isBusy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isBusy;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://192.168.1.20:8096',
          ),
          onSubmitted: (_) {
            if (!isBusy) {
              onSubmit();
            }
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: isBusy ? null : onSubmit,
            child: Text(isBusy ? 'Connecting…' : 'Connect'),
          ),
        ),
      ],
    );
  }
}

class _CupertinoConnectForm extends StatelessWidget {
  const _CupertinoConnectForm({
    required this.controller,
    required this.isBusy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isBusy;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: 'Server URL',
          keyboardType: TextInputType.url,
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
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            borderRadius: BorderRadius.circular(12),
            onPressed: isBusy ? null : onSubmit,
            child: Text(isBusy ? 'Connecting…' : 'Continue'),
          ),
        ),
      ],
    );
  }
}
