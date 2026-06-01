import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peer_view_2/constants/app_colors.dart';
import 'package:peer_view_2/core/di/injection.dart';
import 'package:peer_view_2/core/settings/stream_settings_store.dart';
import 'package:peer_view_2/presentation/widgets/app_ui.dart';
import 'package:peer_view_2/presentation/widgets/streaming_animations.dart';

/// Lets the user change stream port and WebSocket path; saved via SharedPreferences.
class StreamSettingsScreen extends StatefulWidget {
  const StreamSettingsScreen({super.key});

  @override
  State<StreamSettingsScreen> createState() => _StreamSettingsScreenState();
}

class _StreamSettingsScreenState extends State<StreamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _portController;
  late final TextEditingController _pathController;
  late final StreamSettingsStore _store;

  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _store = sl<StreamSettingsStore>();
    final config = _store.config;
    _portController = TextEditingController(text: '${config.port}');
    _pathController = TextEditingController(text: config.webSocketPath);
  }

  @override
  void dispose() {
    _portController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    final port = int.parse(_portController.text.trim());
    final path = _pathController.text.trim();

    await _store.save(port: port, webSocketPath: path);

    if (!mounted) {
      return;
    }

    final saved = _store.config;
    _portController.text = '${saved.port}';
    _pathController.text = saved.webSocketPath;

    setState(() {
      _saving = false;
      _message =
          'Settings saved. Host and Client will use them next time you open those screens.';
    });
  }

  Future<void> _reset() async {
    setState(() {
      _saving = true;
      _message = null;
    });

    await _store.resetToDefaults();

    if (!mounted) {
      return;
    }

    final saved = _store.config;
    _portController.text = '${saved.port}';
    _pathController.text = saved.webSocketPath;

    setState(() {
      _saving = false;
      _message =
          'Restored defaults (port ${StreamSettingsStore.defaultPort}, path ${StreamSettingsStore.defaultPath}).';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              FadeSlideIn(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stream settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 40),
                child: Text(
                  'Used by both Host (server) and Client (scan/connect). Defaults: port 8080, path /stream.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: AppCard(
                  accentBorder: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Connection',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '8080',
                          helperText: '1 – 65535',
                        ),
                        validator: (value) {
                          final port = int.tryParse(value?.trim() ?? '');
                          if (port == null || port < 1 || port > 65535) {
                            return 'Enter a valid port (1–65535)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pathController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'WebSocket path',
                          hintText: '/stream',
                          helperText: 'Example: /stream or /peer',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Path cannot be empty';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                FadeSlideIn(
                  child: Text(
                    _message!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primarySoft,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: AppPrimaryButton(
                  label: 'Save',
                  icon: Icons.save_rounded,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: AppSecondaryButton(
                  label: 'Reset to defaults',
                  icon: Icons.restart_alt_rounded,
                  onPressed: _saving ? null : _reset,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
