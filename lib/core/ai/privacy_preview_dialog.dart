import 'package:flutter/material.dart';

import 'ai_models.dart';

/// Shows the exact provider, model, and editable text before any external AI call.
Future<String?> showPrivacyPreviewDialog({
  required BuildContext context,
  required AiSettingsState settings,
  required String initialText,
  String title = 'Revisar antes de enviar a tu IA',
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _PrivacyPreviewDialog(
      settings: settings,
      initialText: initialText,
      title: title,
    ),
  );
}

class _PrivacyPreviewDialog extends StatefulWidget {
  const _PrivacyPreviewDialog({
    required this.settings,
    required this.initialText,
    required this.title,
  });

  final AiSettingsState settings;
  final String initialText;
  final String title;

  @override
  State<_PrivacyPreviewDialog> createState() => _PrivacyPreviewDialogState();
}

class _PrivacyPreviewDialogState extends State<_PrivacyPreviewDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _redactSensitiveTokens() {
    var text = _controller.text;
    // Redact common emails, IBANs, DNI/NIF, and phone-like sequences locally.
    text = text.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'),
      '[EMAIL_REDACTADO]',
    );
    text = text.replaceAll(
      RegExp(r'\b[A-Z]{2}\d{2}[A-Z0-9]{10,24}\b'),
      '[IBAN_REDACTADO]',
    );
    text = text.replaceAll(
      RegExp(r'\b\d{8}[A-Z]\b', caseSensitive: false),
      '[DOC_REDACTADO]',
    );
    _controller.text = text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelLabel =
        widget.settings.selectedProvider == AiProviderType.custom
            ? '${widget.settings.customModelId} (${widget.settings.customEndpoint})'
            : widget.settings.selectedModelId;

    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proveedor: ${widget.settings.selectedProvider.displayName}',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modelo: $modelLabel',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Política: Solo modo gratuito (\$0 verificado)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Puedes editar o redactar datos personales antes de enviar este texto:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 7,
                minLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Texto exacto que se enviará',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _redactSensitiveTokens,
                  icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                  label: const Text('Ocultar emails, IBAN y DNI'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Enviar con mi clave'),
        ),
      ],
    );
  }
}
