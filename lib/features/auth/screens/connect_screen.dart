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
    final isLinux = currentAppPlatform == AppPlatform.linux;
    final isCupertino = currentAppPlatform == AppPlatform.cupertino;

    return AuthSceneFrame(
      eyebrow: isLinux ? '' : 'Connect',
      title: isCupertino || isLinux
          ? 'Connect to your server'
          : 'Add your Jellyfin server',
      description: isCupertino
          ? 'Enter your Jellyfin server URL to get started.'
          : isLinux
          ? 'Enter the address of your Jellyfin server to get started. Aetherfin will verify the connection before continuing.'
          : 'Start with the server URL. Aetherfin will ping it first, then move to credentials once the server responds successfully.',
      errorMessage: session.errorMessage,
      secondaryChildren: isCupertino || isLinux
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
        AppPlatform.linux => _LinuxConnectForm(
          controller: _serverController,
          isBusy: isBusy,
          onSubmit: () => _submit(session),
        ),
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

class _LinuxConnectForm extends StatelessWidget {
  const _LinuxConnectForm({
    required this.controller,
    required this.isBusy,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isBusy;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Server address',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the full URL of your Jellyfin server.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://jellyfin.example.com',
            ),
            onSubmitted: (_) {
              if (!isBusy) {
                onSubmit();
              }
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Supports local and remote Jellyfin servers.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isBusy ? null : onSubmit,
            child: Text(isBusy ? 'Connecting…' : 'Connect'),
          ),
        ],
      ),
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
