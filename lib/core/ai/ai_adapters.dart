import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_models.dart';
import 'ai_provider.dart';
import 'cost_policy_guard.dart';

class AiProviderException implements Exception {
  const AiProviderException(this.message);
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic>? tryParseJsonObject(String raw) {
  final cleaned = raw.trim();
  try {
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // Try extracting fenced JSON block.
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (match != null) {
      try {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
  }
  return null;
}

class OpenRouterAdapter implements AiProvider {
  OpenRouterAdapter({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  bool _cancelled = false;

  static const AiModelDescriptor defaultFreeRouter = AiModelDescriptor(
    id: 'openrouter/free',
    displayName: 'OpenRouter Free Router (automático \$0)',
    provider: AiProviderType.openRouter,
    costTier: AiCostTier.verifiedFree,
    promptPricePerToken: 0.0,
    completionPricePerToken: 0.0,
  );

  @override
  AiProviderType get type => AiProviderType.openRouter;

  @override
  AiCapabilities describeCapabilities() => const AiCapabilities(
        supportsModelDiscovery: true,
        supportsStructuredJson: true,
        supportsFreeTierOnly: true,
        notes:
            'Solo permite openrouter/free y modelos del catálogo oficial con prompt=0 y completion=0.',
      );

  @override
  Future<List<AiModelDescriptor>> discoverModels({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    _cancelled = false;
    final uri = Uri.parse('https://openrouter.ai/api/v1/models');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (apiKey != null && apiKey.trim().isNotEmpty)
        'Authorization': 'Bearer ${apiKey.trim()}',
    };
    final resp = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));
    if (_cancelled) throw const AiProviderException('Operación cancelada.');
    if (resp.statusCode != 200) {
      throw AiProviderException(
        'OpenRouter devolvió HTTP ${resp.statusCode} al consultar el catálogo.',
      );
    }

    final decoded = jsonDecode(resp.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      return const [defaultFreeRouter];
    }

    final freeModels = <AiModelDescriptor>[defaultFreeRouter];
    for (final entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id']?.toString().trim() ?? '';
      if (id.isEmpty || id == 'openrouter/free') continue;
      final pricing = entry['pricing'] is Map<String, dynamic>
          ? entry['pricing'] as Map<String, dynamic>
          : null;
      if (!CostPolicyGuard.isOpenRouterPricingZero(pricing)) continue;

      freeModels.add(
        AiModelDescriptor(
          id: id,
          displayName: entry['name']?.toString() ?? id,
          provider: AiProviderType.openRouter,
          costTier: AiCostTier.verifiedFree,
          promptPricePerToken: 0.0,
          completionPricePerToken: 0.0,
          contextLength: int.tryParse(entry['context_length']?.toString() ?? ''),
        ),
      );
    }
    return freeModels;
  }

  @override
  Future<AiValidationResult> validateConfiguration({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const AiValidationResult(
        isValid: false,
        message: 'Introduce tu clave API de OpenRouter.',
      );
    }
    try {
      final models = await discoverModels(apiKey: apiKey);
      return AiValidationResult(
        isValid: true,
        message:
            'Conexión verificada. ${models.length} opciones gratuitas disponibles.',
        models: models,
      );
    } catch (e) {
      return AiValidationResult(
        isValid: false,
        message: 'No se pudo validar OpenRouter: $e',
      );
    }
  }

  @override
  Future<AiStructuredResponse> generateStructured({
    required AiStructuredRequest request,
    required String? apiKey,
    required AiModelDescriptor? model,
    required bool freeOnlyMode,
    String? customEndpoint,
  }) async {
    _cancelled = false;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const AiProviderException('Falta la clave API de OpenRouter.');
    }
    final targetModel = model ?? defaultFreeRouter;
    CostPolicyGuard.assertExecutionAllowed(
      provider: type,
      model: targetModel,
      freeOnlyMode: freeOnlyMode,
    );

    final prompt = CostPolicyGuard.buildIsolatedPrompt(request);
    final resp = await _client
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${apiKey.trim()}',
            'X-Title': 'DeadlineLens OSS',
          },
          body: jsonEncode({
            'model': targetModel.id,
            'temperature': 0.1,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 35));

    if (_cancelled) throw const AiProviderException('Operación cancelada.');
    if (resp.statusCode != 200) {
      throw AiProviderException(
        'Error de OpenRouter (${resp.statusCode}): no se pudo completar la petición gratuita.',
      );
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>? ?? const [];
    final first = choices.isNotEmpty ? choices.first as Map<String, dynamic> : {};
    final message = first['message'] as Map<String, dynamic>? ?? {};
    final content = message['content']?.toString() ?? '';

    return AiStructuredResponse(
      provider: type,
      modelId: targetModel.id,
      rawText: content,
      parsedJson: tryParseJsonObject(content),
    );
  }

  @override
  void cancel() {
    _cancelled = true;
  }
}

class GeminiAdapter implements AiProvider {
  GeminiAdapter({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  bool _cancelled = false;

  static const List<AiModelDescriptor> freeTierModels = [
    AiModelDescriptor(
      id: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash (Nivel gratuito AI Studio)',
      provider: AiProviderType.gemini,
      costTier: AiCostTier.verifiedFree,
      promptPricePerToken: 0.0,
      completionPricePerToken: 0.0,
    ),
    AiModelDescriptor(
      id: 'gemini-2.0-flash-lite',
      displayName: 'Gemini 2.0 Flash-Lite (Nivel gratuito AI Studio)',
      provider: AiProviderType.gemini,
      costTier: AiCostTier.verifiedFree,
      promptPricePerToken: 0.0,
      completionPricePerToken: 0.0,
    ),
  ];

  @override
  AiProviderType get type => AiProviderType.gemini;

  @override
  AiCapabilities describeCapabilities() => const AiCapabilities(
        supportsModelDiscovery: true,
        supportsStructuredJson: true,
        supportsFreeTierOnly: true,
        notes:
            'Usa modelos del nivel gratuito de Google AI Studio. Verifica que tu clave no tenga facturación activa si quieres coste cero garantizado.',
      );

  @override
  Future<List<AiModelDescriptor>> discoverModels({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    return freeTierModels;
  }

  @override
  Future<AiValidationResult> validateConfiguration({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    if (apiKey == null || apiKey.trim().isEmpty) {
      return const AiValidationResult(
        isValid: false,
        message: 'Introduce tu clave API de Google AI Studio.',
      );
    }
    try {
      final resp = await _client
          .get(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models?key=${Uri.encodeQueryComponent(apiKey.trim())}',
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        return const AiValidationResult(
          isValid: true,
          message: 'Clave de Google AI Studio verificada.',
          models: freeTierModels,
        );
      }
      return AiValidationResult(
        isValid: false,
        message: 'Google Gemini devolvió HTTP ${resp.statusCode}.',
      );
    } catch (e) {
      return AiValidationResult(
        isValid: false,
        message: 'Error de conexión con Gemini: $e',
      );
    }
  }

  @override
  Future<AiStructuredResponse> generateStructured({
    required AiStructuredRequest request,
    required String? apiKey,
    required AiModelDescriptor? model,
    required bool freeOnlyMode,
    String? customEndpoint,
  }) async {
    _cancelled = false;
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const AiProviderException('Falta la clave API de Google Gemini.');
    }
    final targetModel = model ?? freeTierModels.first;
    CostPolicyGuard.assertExecutionAllowed(
      provider: type,
      model: targetModel,
      freeOnlyMode: freeOnlyMode,
    );

    final prompt = CostPolicyGuard.buildIsolatedPrompt(request);
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${targetModel.id}:generateContent?key=${Uri.encodeQueryComponent(apiKey.trim())}',
    );
    final resp = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.1,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(const Duration(seconds: 35));

    if (_cancelled) throw const AiProviderException('Operación cancelada.');
    if (resp.statusCode != 200) {
      throw AiProviderException(
        'Error de Gemini (${resp.statusCode}). Revisa tu cuota gratuita o clave.',
      );
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>? ?? const [];
    final first =
        candidates.isNotEmpty ? candidates.first as Map<String, dynamic> : {};
    final contentMap = first['content'] as Map<String, dynamic>? ?? {};
    final parts = contentMap['parts'] as List<dynamic>? ?? const [];
    final text = parts.isNotEmpty
        ? (parts.first as Map<String, dynamic>)['text']?.toString() ?? ''
        : '';

    return AiStructuredResponse(
      provider: type,
      modelId: targetModel.id,
      rawText: text,
      parsedJson: tryParseJsonObject(text),
    );
  }

  @override
  void cancel() {
    _cancelled = true;
  }
}

class StubPaidAdapter implements AiProvider {
  const StubPaidAdapter(this.type);

  @override
  final AiProviderType type;

  @override
  void cancel() {}

  @override
  AiCapabilities describeCapabilities() => const AiCapabilities(
        supportsModelDiscovery: false,
        supportsStructuredJson: true,
        supportsFreeTierOnly: false,
        notes:
            'No disponible en modo gratuito estricto: este proveedor no ofrece catálogo gratuito verificado sin facturación.',
      );

  @override
  Future<List<AiModelDescriptor>> discoverModels({
    required String? apiKey,
    String? customEndpoint,
  }) async =>
      const [];

  @override
  Future<AiValidationResult> validateConfiguration({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    return AiValidationResult(
      isValid: false,
      message:
          '${type.displayName}: no disponible en modo gratuito estricto (requiere saldo/facturación en la cuenta del proveedor).',
    );
  }

  @override
  Future<AiStructuredResponse> generateStructured({
    required AiStructuredRequest request,
    required String? apiKey,
    required AiModelDescriptor? model,
    required bool freeOnlyMode,
    String? customEndpoint,
  }) async {
    CostPolicyGuard.assertExecutionAllowed(
      provider: type,
      model: model,
      freeOnlyMode: freeOnlyMode,
    );
    throw AiProviderException(
      '${type.displayName} está bloqueado por la política de coste cero.',
    );
  }
}

class CustomCompatibleAdapter implements AiProvider {
  CustomCompatibleAdapter({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  bool _cancelled = false;

  @override
  AiProviderType get type => AiProviderType.custom;

  @override
  AiCapabilities describeCapabilities() => const AiCapabilities(
        supportsModelDiscovery: true,
        supportsStructuredJson: true,
        supportsFreeTierOnly: true,
        notes:
            'Compatible con servidores locales Ollama, LM Studio o endpoints OpenAI-compatible bajo tu control.',
      );

  Uri _buildUri(String endpoint, String suffix) {
    final base = endpoint.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$suffix');
  }

  @override
  Future<List<AiModelDescriptor>> discoverModels({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    final endpoint = (customEndpoint ?? '').trim();
    if (endpoint.isEmpty) return const [];
    final resp = await _client
        .get(
          _buildUri(endpoint, '/models'),
          headers: {
            if (apiKey != null && apiKey.trim().isNotEmpty)
              'Authorization': 'Bearer ${apiKey.trim()}',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return const [];
    final decoded = jsonDecode(resp.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => AiModelDescriptor(
            id: m['id']?.toString() ?? 'local-model',
            displayName: m['id']?.toString() ?? 'Modelo local',
            provider: AiProviderType.custom,
            costTier: AiCostTier.verifiedFree,
            promptPricePerToken: 0.0,
            completionPricePerToken: 0.0,
          ),
        )
        .toList();
  }

  @override
  Future<AiValidationResult> validateConfiguration({
    required String? apiKey,
    String? customEndpoint,
  }) async {
    try {
      CostPolicyGuard.assertExecutionAllowed(
        provider: type,
        model: null,
        freeOnlyMode: true,
        customEndpoint: customEndpoint,
      );
      final models = await discoverModels(
        apiKey: apiKey,
        customEndpoint: customEndpoint,
      );
      return AiValidationResult(
        isValid: true,
        message: models.isEmpty
            ? 'Endpoint accesible. Indica el nombre del modelo local.'
            : 'Endpoint accesible (${models.length} modelos detectados).',
        models: models,
      );
    } catch (e) {
      return AiValidationResult(
        isValid: false,
        message: 'No se pudo conectar al servidor local: $e',
      );
    }
  }

  @override
  Future<AiStructuredResponse> generateStructured({
    required AiStructuredRequest request,
    required String? apiKey,
    required AiModelDescriptor? model,
    required bool freeOnlyMode,
    String? customEndpoint,
  }) async {
    _cancelled = false;
    CostPolicyGuard.assertExecutionAllowed(
      provider: type,
      model: model,
      freeOnlyMode: freeOnlyMode,
      customEndpoint: customEndpoint,
    );
    final modelId = model?.id ?? 'llama3.2';
    final prompt = CostPolicyGuard.buildIsolatedPrompt(request);

    final resp = await _client
        .post(
          _buildUri(customEndpoint!, '/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            if (apiKey != null && apiKey.trim().isNotEmpty)
              'Authorization': 'Bearer ${apiKey.trim()}',
          },
          body: jsonEncode({
            'model': modelId,
            'temperature': 0.1,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 40));

    if (_cancelled) throw const AiProviderException('Operación cancelada.');
    if (resp.statusCode != 200) {
      throw AiProviderException(
        'Error del servidor local (${resp.statusCode}).',
      );
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>? ?? const [];
    final first = choices.isNotEmpty ? choices.first as Map<String, dynamic> : {};
    final message = first['message'] as Map<String, dynamic>? ?? {};
    final content = message['content']?.toString() ?? '';

    return AiStructuredResponse(
      provider: type,
      modelId: modelId,
      rawText: content,
      parsedJson: tryParseJsonObject(content),
    );
  }

  @override
  void cancel() {
    _cancelled = true;
  }
}

AiProvider createAiAdapter(AiProviderType type, {http.Client? client}) {
  switch (type) {
    case AiProviderType.openRouter:
      return OpenRouterAdapter(client: client);
    case AiProviderType.gemini:
      return GeminiAdapter(client: client);
    case AiProviderType.openAi:
      return const StubPaidAdapter(AiProviderType.openAi);
    case AiProviderType.anthropic:
      return const StubPaidAdapter(AiProviderType.anthropic);
    case AiProviderType.deepSeek:
      return const StubPaidAdapter(AiProviderType.deepSeek);
    case AiProviderType.custom:
      return CustomCompatibleAdapter(client: client);
  }
}
