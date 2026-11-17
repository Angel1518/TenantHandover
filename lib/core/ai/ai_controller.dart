import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'ai_adapters.dart';
import 'ai_models.dart';
import 'ai_provider.dart';

final keyVaultProvider = Provider<KeyVault>((ref) => SecureKeyVault());

final httpClientProvider = Provider<http.Client>((ref) => http.Client());

class AiSettingsController extends Notifier<AiSettingsState> {
  @override
  AiSettingsState build() {
    Future.microtask(_loadSavedKeyMetadata);
    return const AiSettingsState();
  }

  KeyVault get _vault => ref.read(keyVaultProvider);

  Future<void> _loadSavedKeyMetadata() async {
    try {
      final key = await _vault.readKey(state.selectedProvider);
      state = state.copyWith(
        hasSavedKey: key != null && key.trim().isNotEmpty,
        keyMaskedPreview: maskApiKey(key),
      );
    } catch (_) {
      // Safe fallback when secure storage is unavailable in headless tests.
    }
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  Future<void> selectProvider(AiProviderType provider) async {
    String defaultModel;
    switch (provider) {
      case AiProviderType.openRouter:
        defaultModel = 'openrouter/free';
        break;
      case AiProviderType.gemini:
        defaultModel = GeminiAdapter.freeTierModels.first.id;
        break;
      case AiProviderType.custom:
        defaultModel = state.customModelId;
        break;
      case AiProviderType.openAi:
      case AiProviderType.anthropic:
      case AiProviderType.deepSeek:
        defaultModel = '';
        break;
    }

    String? savedKey;
    try {
      savedKey = await _vault.readKey(provider);
    } catch (_) {}

    state = state.copyWith(
      selectedProvider: provider,
      selectedModelId: defaultModel,
      hasSavedKey: savedKey != null && savedKey.trim().isNotEmpty,
      keyMaskedPreview: maskApiKey(savedKey),
    );
  }

  void selectModel(String modelId) {
    state = state.copyWith(selectedModelId: modelId);
  }

  void updateCustomConfig({String? endpoint, String? modelId}) {
    state = state.copyWith(
      customEndpoint: endpoint ?? state.customEndpoint,
      customModelId: modelId ?? state.customModelId,
      selectedModelId: modelId ?? state.selectedModelId,
    );
  }

  Future<void> saveApiKey(String rawKey) async {
    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) return;
    await _vault.saveKey(state.selectedProvider, trimmed);
    state = state.copyWith(
      hasSavedKey: true,
      keyMaskedPreview: maskApiKey(trimmed),
    );
  }

  Future<void> deleteApiKey() async {
    await _vault.deleteKey(state.selectedProvider);
    state = state.copyWith(
      hasSavedKey: false,
      keyMaskedPreview: '',
    );
  }

  Future<AiValidationResult> testConnection() async {
    final adapter = createAiAdapter(
      state.selectedProvider,
      client: ref.read(httpClientProvider),
    );
    final key = await _vault.readKey(state.selectedProvider);
    return adapter.validateConfiguration(
      apiKey: key,
      customEndpoint: state.customEndpoint,
    );
  }

  Future<AiStructuredResponse> runStructured({
    required String taskInstruction,
    required String reviewedText,
    required String jsonSchemaHint,
  }) async {
    if (!state.enabled) {
      throw const AiProviderException(
        'La IA BYOK está desactivada. Actívala en Ajustes > IA (BYOK).',
      );
    }

    final adapter = createAiAdapter(
      state.selectedProvider,
      client: ref.read(httpClientProvider),
    );
    final key = await _vault.readKey(state.selectedProvider);

    final AiModelDescriptor model = AiModelDescriptor(
      id: state.selectedProvider == AiProviderType.custom
          ? state.customModelId
          : state.selectedModelId,
      displayName: state.selectedModelId,
      provider: state.selectedProvider,
      costTier: state.selectedProvider.supportsFreeOnlyMode
          ? AiCostTier.verifiedFree
          : AiCostTier.paidOrUnknown,
      promptPricePerToken: 0.0,
      completionPricePerToken: 0.0,
    );

    return adapter.generateStructured(
      request: AiStructuredRequest(
        taskInstruction: taskInstruction,
        untrustedUserText: reviewedText,
        jsonSchemaHint: jsonSchemaHint,
        modelId: model.id,
      ),
      apiKey: key,
      model: model,
      freeOnlyMode: state.freeOnlyMode,
      customEndpoint: state.customEndpoint,
    );
  }
}

final aiSettingsProvider =
    NotifierProvider<AiSettingsController, AiSettingsState>(
  AiSettingsController.new,
);
