import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'ai_models.dart';

abstract class AiProvider {
  AiProviderType get type;

  Future<List<AiModelDescriptor>> discoverModels({
    required String? apiKey,
    String? customEndpoint,
  });

  Future<AiValidationResult> validateConfiguration({
    required String? apiKey,
    String? customEndpoint,
  });

  AiCapabilities describeCapabilities();

  Future<AiStructuredResponse> generateStructured({
    required AiStructuredRequest request,
    required String? apiKey,
    required AiModelDescriptor? model,
    required bool freeOnlyMode,
    String? customEndpoint,
  });

  void cancel();
}

abstract class KeyVault {
  Future<void> saveKey(AiProviderType provider, String apiKey);
  Future<String?> readKey(AiProviderType provider);
  Future<void> deleteKey(AiProviderType provider);
}

class SecureKeyVault implements KeyVault {
  SecureKeyVault({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  String _keyName(AiProviderType provider) => 'byok_api_key_${provider.id}';

  @override
  Future<void> saveKey(AiProviderType provider, String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) return;
    await _storage.write(key: _keyName(provider), value: trimmed);
  }

  @override
  Future<String?> readKey(AiProviderType provider) {
    return _storage.read(key: _keyName(provider));
  }

  @override
  Future<void> deleteKey(AiProviderType provider) {
    return _storage.delete(key: _keyName(provider));
  }
}

class InMemoryKeyVault implements KeyVault {
  final Map<AiProviderType, String> _keys = {};

  @override
  Future<void> deleteKey(AiProviderType provider) async {
    _keys.remove(provider);
  }

  @override
  Future<String?> readKey(AiProviderType provider) async {
    return _keys[provider];
  }

  @override
  Future<void> saveKey(AiProviderType provider, String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isNotEmpty) {
      _keys[provider] = trimmed;
    }
  }
}

String maskApiKey(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final s = raw.trim();
  if (s.length <= 8) return '••••••••';
  return '${s.substring(0, 4)}••••${s.substring(s.length - 4)}';
}
