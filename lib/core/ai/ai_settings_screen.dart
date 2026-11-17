import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_adapters.dart';
import 'ai_controller.dart';
import 'ai_models.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _keyController = TextEditingController();
  final _endpointController = TextEditingController();
  final _customModelController = TextEditingController();

  bool _obscureKey = true;
  bool _testing = false;
  String? _statusMessage;
  bool? _statusSuccess;
  List<AiModelDescriptor> _discoveredModels = const [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(aiSettingsProvider);
    _endpointController.text = state.customEndpoint;
    _customModelController.text = state.customModelId;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _endpointController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _keyController.text = text;
    }
  }

  Future<void> _saveKey() async {
    final raw = _keyController.text.trim();
    if (raw.isEmpty) return;
    await ref.read(aiSettingsProvider.notifier).saveApiKey(raw);
    _keyController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clave guardada en el almacén cifrado del dispositivo.'),
      ),
    );
  }

  Future<void> _deleteKey() async {
    await ref.read(aiSettingsProvider.notifier).deleteApiKey();
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Clave eliminada del dispositivo.';
      _statusSuccess = null;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _statusMessage = null;
    });
    final result = await ref.read(aiSettingsProvider.notifier).testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _statusMessage = result.message;
      _statusSuccess = result.isValid;
      if (result.models.isNotEmpty) {
        _discoveredModels = result.models;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiSettingsProvider);
    final notifier = ref.read(aiSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('IA opcional (BYOK gratuito)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              value: state.enabled,
              onChanged: notifier.setEnabled,
              title: const Text('Activar asistencia IA con tu propia clave'),
              subtitle: const Text(
                'Desactivada por defecto. La app funciona 100 % offline sin IA.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Política de coste cero estricta: nunca se incluyen claves del desarrollador ni se permiten modelos de pago automáticamente. Tu clave se guarda solo en Android Keystore y nunca se exporta.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Proveedor (5 + 1 compatible)',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...AiProviderType.values.map((provider) {
            final selected = state.selectedProvider == provider;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    setState(() {
                      _statusMessage = null;
                      _discoveredModels = const [];
                    });
                    notifier.selectProvider(provider);
                  },
                  title: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(provider.displayName),
                      Chip(
                        label: Text(
                          provider.supportsFreeOnlyMode
                              ? 'Gratis'
                              : 'Solo de pago',
                          style: theme.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  subtitle: Text(provider.subtitle),
                  selected: selected,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (!state.selectedProvider.supportsFreeOnlyMode)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${state.selectedProvider.displayName} está preparado como campo BYOK, pero permanece bloqueado en modo gratuito estricto porque no garantiza catálogo \$0 sin facturación.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else if (state.selectedProvider == AiProviderType.custom)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Servidor local / compatible',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _endpointController,
                      decoration: const InputDecoration(
                        labelText: 'Endpoint base OpenAI-compatible',
                        hintText: 'http://localhost:11434/v1',
                      ),
                      onChanged: (v) => notifier.updateCustomConfig(endpoint: v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customModelController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del modelo',
                        hintText: 'llama3.2',
                      ),
                      onChanged: (v) => notifier.updateCustomConfig(modelId: v),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clave API de ${state.selectedProvider.displayName}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.hasSavedKey
                          ? 'Clave guardada: ${state.keyMaskedPreview}'
                          : 'Ninguna clave guardada todavía.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      obscureText: _obscureKey,
                      decoration: InputDecoration(
                        labelText: 'Pegar clave API',
                        suffixIcon: IconButton(
                          tooltip: _obscureKey ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscureKey = !_obscureKey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Pegar'),
                        ),
                        FilledButton.icon(
                          onPressed: _saveKey,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar'),
                        ),
                        if (state.hasSavedKey)
                          TextButton.icon(
                            onPressed: _deleteKey,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Borrar clave'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Modelo gratuito seleccionado',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _availableModelIds(state).contains(state.selectedModelId)
                          ? state.selectedModelId
                          : _availableModelIds(state).first,
                      isExpanded: true,
                      items: _availableModelModels(state)
                          .map(
                            (m) => DropdownMenuItem<String>(
                              value: m.id,
                              child: Text(
                                '${m.displayName} (${m.id})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) notifier.selectModel(v);
                      },
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _testing ? null : _testConnection,
            icon: _testing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.network_check),
            label: Text(_testing ? 'Comprobando...' : 'Probar conexión gratuita'),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      _statusSuccess == true
                          ? Icons.check_circle_outline
                          : _statusSuccess == false
                              ? Icons.error_outline
                              : Icons.info_outline,
                      color: _statusSuccess == true
                          ? Colors.green
                          : _statusSuccess == false
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_statusMessage!)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<AiModelDescriptor> _availableModelModels(AiSettingsState state) {
    if (_discoveredModels.isNotEmpty) return _discoveredModels;
    if (state.selectedProvider == AiProviderType.gemini) {
      return GeminiAdapter.freeTierModels;
    }
    return const [OpenRouterAdapter.defaultFreeRouter];
  }

  List<String> _availableModelIds(AiSettingsState state) {
    return _availableModelModels(state).map((m) => m.id).toList();
  }
}
