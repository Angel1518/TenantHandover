import 'dart:convert';

enum AiProviderType {
  openRouter,
  gemini,
  openAi,
  anthropic,
  deepSeek,
  custom,
}

extension AiProviderTypeX on AiProviderType {
  String get id => name;

  String get displayName {
    switch (this) {
      case AiProviderType.openRouter:
        return 'OpenRouter';
      case AiProviderType.gemini:
        return 'Google Gemini';
      case AiProviderType.openAi:
        return 'OpenAI';
      case AiProviderType.anthropic:
        return 'Anthropic';
      case AiProviderType.deepSeek:
        return 'DeepSeek';
      case AiProviderType.custom:
        return 'Servidor compatible (Ollama / Local)';
    }
  }

  String get subtitle {
    switch (this) {
      case AiProviderType.openRouter:
        return 'Enrutador gratuito (openrouter/free y variantes \$0 verificadas)';
      case AiProviderType.gemini:
        return 'Nivel gratuito de Google AI Studio (sin facturación)';
      case AiProviderType.openAi:
        return 'Preparado para clave propia (bloqueado en modo gratuito)';
      case AiProviderType.anthropic:
        return 'Preparado para clave propia (bloqueado en modo gratuito)';
      case AiProviderType.deepSeek:
        return 'Preparado para clave propia (bloqueado en modo gratuito)';
      case AiProviderType.custom:
        return 'Endpoint OpenAI-compatible local o autohospedado';
    }
  }

  bool get requiresApiKey => this != AiProviderType.custom;

  bool get supportsFreeOnlyMode {
    switch (this) {
      case AiProviderType.openRouter:
      case AiProviderType.gemini:
      case AiProviderType.custom:
        return true;
      case AiProviderType.openAi:
      case AiProviderType.anthropic:
      case AiProviderType.deepSeek:
        return false;
    }
  }
}

enum AiCostTier {
  verifiedFree,
  paidOrUnknown,
}

class AiModelDescriptor {
  const AiModelDescriptor({
    required this.id,
    required this.displayName,
    required this.provider,
    required this.costTier,
    this.promptPricePerToken,
    this.completionPricePerToken,
    this.contextLength,
    this.supportsStructuredJson = true,
  });

  final String id;
  final String displayName;
  final AiProviderType provider;
  final AiCostTier costTier;
  final double? promptPricePerToken;
  final double? completionPricePerToken;
  final int? contextLength;
  final bool supportsStructuredJson;

  bool get isStrictlyFree =>
      costTier == AiCostTier.verifiedFree &&
      (promptPricePerToken == null || promptPricePerToken == 0.0) &&
      (completionPricePerToken == null || completionPricePerToken == 0.0);
}

class AiCapabilities {
  const AiCapabilities({
    required this.supportsModelDiscovery,
    required this.supportsStructuredJson,
    required this.supportsFreeTierOnly,
    required this.notes,
  });

  final bool supportsModelDiscovery;
  final bool supportsStructuredJson;
  final bool supportsFreeTierOnly;
  final String notes;
}

class AiValidationResult {
  const AiValidationResult({
    required this.isValid,
    required this.message,
    this.models = const [],
  });

  final bool isValid;
  final String message;
  final List<AiModelDescriptor> models;
}

class AiStructuredRequest {
  const AiStructuredRequest({
    required this.taskInstruction,
    required this.untrustedUserText,
    required this.jsonSchemaHint,
    this.modelId,
  });

  final String taskInstruction;
  final String untrustedUserText;
  final String jsonSchemaHint;
  final String? modelId;
}

class AiStructuredResponse {
  const AiStructuredResponse({
    required this.provider,
    required this.modelId,
    required this.rawText,
    required this.parsedJson,
  });

  final AiProviderType provider;
  final String modelId;
  final String rawText;
  final Map<String, dynamic>? parsedJson;

  String prettyJson() {
    if (parsedJson == null) return rawText;
    return const JsonEncoder.withIndent('  ').convert(parsedJson);
  }
}

class AiSettingsState {
  const AiSettingsState({
    this.enabled = false,
    this.freeOnlyMode = true,
    this.selectedProvider = AiProviderType.openRouter,
    this.selectedModelId = 'openrouter/free',
    this.customEndpoint = 'http://localhost:11434/v1',
    this.customModelId = 'llama3.2',
    this.hasSavedKey = false,
    this.keyMaskedPreview = '',
  });

  final bool enabled;
  final bool freeOnlyMode;
  final AiProviderType selectedProvider;
  final String selectedModelId;
  final String customEndpoint;
  final String customModelId;
  final bool hasSavedKey;
  final String keyMaskedPreview;

  AiSettingsState copyWith({
    bool? enabled,
    bool? freeOnlyMode,
    AiProviderType? selectedProvider,
    String? selectedModelId,
    String? customEndpoint,
    String? customModelId,
    bool? hasSavedKey,
    String? keyMaskedPreview,
  }) {
    return AiSettingsState(
      enabled: enabled ?? this.enabled,
      freeOnlyMode: freeOnlyMode ?? this.freeOnlyMode,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      customEndpoint: customEndpoint ?? this.customEndpoint,
      customModelId: customModelId ?? this.customModelId,
      hasSavedKey: hasSavedKey ?? this.hasSavedKey,
      keyMaskedPreview: keyMaskedPreview ?? this.keyMaskedPreview,
    );
  }
}
